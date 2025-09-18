import * as functions from 'firebase-functions';
import { REGION, DATA_PLATFORM } from './config';
import { getFirestore } from './init';
import { timesOverlap } from './utils';
// no-op import removed; we use GoogleAuth dynamically in code

// We will call Vertex AI Endpoint directly via REST
async function getAccessToken(): Promise<string> {
  const { GoogleAuth } = await import('google-auth-library');
  const auth = new GoogleAuth({ scopes: ['https://www.googleapis.com/auth/cloud-platform'] });
  const client = await auth.getClient();
  const tokenResponse = await client.getAccessToken();
  if (!tokenResponse || !tokenResponse.token) throw new Error('Failed to get access token');
  return tokenResponse.token;
}

interface RealtimeRequest {
  studentId: string;
  limit?: number;
  debug?: boolean;
}

function toDistanceBucket(distanceKm: number): string {
  if (distanceKm <= 5) return '0_5km';
  if (distanceKm <= 10) return '5_10km';
  if (distanceKm <= 20) return '10_20km';
  return '20p_km';
}

export const getRecommendationsRealtime = functions
  .region(REGION)
  .https.onCall(async (data: RealtimeRequest, context) => {
    if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'Login required');
    const studentId = data?.studentId || context.auth.uid;
    const limit = Math.min(Math.max(Number(data?.limit || 10), 1), 50);
    const debug = Boolean(data?.debug);

    const db = getFirestore();
    const student = await db.collection('student_profiles').doc(studentId).get();
    if (!student.exists) throw new functions.https.HttpsError('failed-precondition', 'Student profile missing');
    const s = student.data() as any;

    // Candidate generation: published classes matching grade/subjects (simplified)
    const subjects: string[] = (s.subjects_of_interest || s.subjectsOfInterest || []).slice(0, 5);
    const areaCode: string = s.area_code || s.areaCode || null;
    const grade: number = Number(s.grade || 0);

    let query = db.collection('classes').where('status', '==', 'published');
    if (grade) query = query.where('grade', '==', grade);
    const classesSnap = await query.limit(200).get();

    // Build student's existing session schedule from active/pending enrollments
    const myEnrs = await db
      .collection('enrollments')
      .where('studentId', '==', studentId)
      .where('status', 'in', ['active', 'pending'])
      .get();
    const myClassIds = myEnrs.docs.map((d) => (d.data() as any).classId);
    const mySessions: Array<{ date: string; start: string; end: string }> = [];
    for (const cid of myClassIds) {
      const s = await db.collection('classes').doc(cid).collection('sessions').get();
      s.forEach((doc) => {
        const v = doc.data() as any;
        mySessions.push({
          date: v.session_date || v.date,
          start: v.start_time || v.startTime,
          end: v.end_time || v.endTime
        });
      });
    }

    // Pre-compute tutor popularity from Firestore (simple heuristic):
    // popularity = normalized total active enrollments for tutor in last 90d
    const enrollment90dSince = new Date();
    enrollment90dSince.setDate(enrollment90dSince.getDate() - 90);

    const tutors = new Map<string, number>();
    for (const c of classesSnap.docs) {
      const tutorId = (c.data() as any).tutorId;
      tutors.set(tutorId, 0);
    }
    if (tutors.size > 0) {
      const enrSnap = await db
        .collection('enrollments')
        .where('status', 'in', ['active', 'completed'])
        .get();
      // Map enrollment -> class -> tutor
      const classMap = new Map<string, string>();
      for (const c of classesSnap.docs) classMap.set(c.id, (c.data() as any).tutorId);
      enrSnap.forEach((e) => {
        const clzId = (e.data() as any).classId;
        const tutorId = classMap.get(clzId);
        if (tutorId) tutors.set(tutorId, (tutors.get(tutorId) || 0) + 1);
      });
    }
    const maxPop = Math.max(1, ...Array.from(tutors.values()));

    // Build instances for Vertex prediction
    const instances: any[] = [];
    const classIds: string[] = [];
    for (const c of classesSnap.docs) {
      const cl = c.data() as any;
      // subject and area filters (simplified)
      if (subjects.length && cl.subjectCode && !subjects.includes(cl.subjectCode)) continue;
      if (areaCode && cl.areaCode && cl.areaCode !== areaCode) continue;

      const popularity = (tutors.get(cl.tutorId) || 0) / maxPop * 100.0;

      // Compute time_overlap = true if no clash with student's sessions
      let timeOk = true;
      const candSessionsSnap = await db.collection('classes').doc(c.id).collection('sessions').limit(8).get();
      candSessionsSnap.forEach((cs) => {
        const v = cs.data() as any;
        const cDate = v.session_date || v.date;
        const cStart = v.start_time || v.startTime;
        const cEnd = v.end_time || v.endTime;
        for (const mine of mySessions) {
          if (mine.date === cDate && timesOverlap(mine.start, mine.end, cStart, cEnd)) {
            timeOk = false;
            break;
          }
        }
      });

      // Compute distance bucket from area codes
      let distanceBucket = '10_20km';
      if (cl.mode === 'online') distanceBucket = '0_5km';
      else if (areaCode && cl.areaCode) {
        const sCity = String(areaCode).split('-')[0];
        const cCity = String(cl.areaCode).split('-')[0];
        if (areaCode === cl.areaCode) distanceBucket = '0_5km';
        else if (sCity === cCity) distanceBucket = '5_10km';
        else distanceBucket = '10_20km';
      }
      instances.push({
        student_id: studentId,
        class_id: c.id,
        subject_match: subjects.includes(cl.subjectCode || ''),
        grade_match: Number(cl.grade) === grade,
        time_overlap: timeOk,
        distance_bucket: distanceBucket,
        price_band_fit: (cl.priceBand || 'mid') === 'mid',
        tutor_popularity: popularity,
        past_clicks_30d: '0',
        past_enrols_90d: '0'
      });
      classIds.push(c.id);
      if (instances.length >= 200) break;
    }

    if (instances.length === 0) return { results: [] };

    // Call Vertex endpoint
    // Allow override via env or functions config
    const cfg = (functions.config() as any) || {};
    const endpointId = process.env.RECS_ENDPOINT_ID || cfg.recs?.endpoint_id || '941353477190189056';
    const url = `https://asia-south1-aiplatform.googleapis.com/v1/projects/${DATA_PLATFORM.dataProjectId}/locations/asia-south1/endpoints/${endpointId}:predict`;
    const token = await getAccessToken();
    const resp = await fetch(url, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${token}` },
      body: JSON.stringify({ instances })
    });
    if (!resp.ok) {
      const text = await resp.text();
      throw new functions.https.HttpsError('internal', `Vertex error: ${resp.status} ${text}`);
    }
    const payload: any = await resp.json();
    // Expect predictions aligned with instances. Map to class scores.
    const predictions: any[] = (payload && payload.predictions) ? payload.predictions : [];
    const getScore = (p: any): number => {
      if (p == null) return 0;
      if (typeof p === 'number') return p;
      if (typeof p === 'object') {
        if (typeof p.score === 'number') return p.score;
        if (typeof p.predicted_probability === 'number') return p.predicted_probability;
        if (typeof p.predicted_value === 'number') return p.predicted_value;
        if (typeof p.value === 'number') return p.value;
        if (Array.isArray((p as any).scores) && (p as any).scores.length) return Number((p as any).scores[0]);
        if (Array.isArray((p as any).probabilities) && (p as any).probabilities.length) return Number((p as any).probabilities[0]);
      }
      return 0;
    };
    const results = predictions.map((p, i) => ({ classId: classIds[i], score: getScore(p) }));
    results.sort((a, b) => b.score - a.score);
    const trimmed = results.slice(0, limit);
    return debug ? { results: trimmed, debug: { predictions, instancesCount: instances.length } } : { results: trimmed };
  });


