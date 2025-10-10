import * as functions from 'firebase-functions';
import { REGION, DATA_PLATFORM } from './config';
import { getFirestore } from './init';
import { timesOverlapDate } from './utils';
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
  classIds?: string[];
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
    const providedClassIds: string[] = Array.isArray(data?.classIds) ? (data?.classIds as string[]) : [];

    const db = getFirestore();
    const student = await db.collection('student_profiles').doc(studentId).get();
    if (!student.exists) throw new functions.https.HttpsError('failed-precondition', 'Student profile missing');
    const s = student.data() as any;

    // Candidate generation: published classes matching grade/subjects (simplified)
    const subjects: string[] = (s.subjects_of_interest || s.subjectsOfInterest || []).slice(0, 5);
    const areaCode: string = s.area_code || s.areaCode || null;
    const grade: number = Number(s.grade || 0);

    let classesDocs: FirebaseFirestore.QueryDocumentSnapshot<FirebaseFirestore.DocumentData>[] = [];
    if (providedClassIds.length) {
      const snaps = await Promise.all(providedClassIds.map((id) => db.collection('classes').doc(id).get()));
      classesDocs = snaps.filter((s) => s.exists).map((s) => ({ id: s.id, data: () => s.data()! } as any));
    } else {
      let query = db.collection('classes').where('status', '==', 'published');
      let classesSnap = await (grade ? query.where('grade', '==', grade) : query)
        .limit(200)
        .get();
      classesDocs = classesSnap.docs;
      // Fallback: if nothing matches grade, fetch without grade filter
      if (!classesDocs.length) {
        classesSnap = await query.limit(200).get();
        classesDocs = classesSnap.docs;
      }
    }

    // Build student's existing session schedule from active/pending enrollments
    const myEnrs = await db
      .collection('enrollments')
      .where('studentId', '==', studentId)
      .where('status', 'in', ['active', 'pending'])
      .get();
    const myClassIds = myEnrs.docs.map((d) => (d.data() as any).classId);
    const mySessions: Array<{ start: Date; end: Date }> = [];
    for (const cid of myClassIds) {
      const s = await db.collection('classes').doc(cid).collection('sessions').get();
      s.forEach((doc) => {
        const v = doc.data() as any;
        const sStartRaw = v.start_time || v.startTime;
        const sEndRaw = v.end_time || v.endTime;
        if (!sStartRaw || !sEndRaw) return;
        const sStart: Date = sStartRaw.toDate ? sStartRaw.toDate() : new Date(sStartRaw);
        const sEnd: Date = sEndRaw.toDate ? sEndRaw.toDate() : new Date(sEndRaw);
        mySessions.push({ start: sStart, end: sEnd });
      });
    }

    // Pre-compute tutor popularity from Firestore (simple heuristic):
    // popularity = normalized total active enrollments for tutor in last 90d
    const enrollment90dSince = new Date();
    enrollment90dSince.setDate(enrollment90dSince.getDate() - 90);

    const tutors = new Map<string, number>();
    for (const c of classesDocs) {
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
      for (const c of classesDocs) classMap.set(c.id, (c.data() as any).tutorId);
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
    for (const c of classesDocs) {
      const cl = c.data() as any;
      // Normalize common fields
      const subj = cl.subjectCode || cl.subject_code || '';
      const area = cl.areaCode || cl.area_code || '';
      const modeNorm = String(cl.mode || '').toLowerCase();
      const price = Number(cl.price || cl.fee || 0);
      const priceBand = cl.priceBand || (price <= 3500 ? 'low' : price <= 5500 ? 'mid' : 'high');

      // Loosen filters to avoid empty candidates; we will let the model rank.
      // Previously we filtered out subject/area mismatches which led to empty results.
      const isOnline = modeNorm === 'online';

      const popularity = (tutors.get(cl.tutorId) || 0) / maxPop * 100.0;

      // Compute time_overlap = true if no clash with student's sessions
      let timeOk = true;
      const candSessionsSnap = await db.collection('classes').doc(c.id).collection('sessions').limit(8).get();
      candSessionsSnap.forEach((cs) => {
        const v = cs.data() as any;
        const cStartRaw = v.start_time || v.startTime;
        const cEndRaw = v.end_time || v.endTime;
        if (!cStartRaw || !cEndRaw) return;
        const cStart: Date = cStartRaw.toDate ? cStartRaw.toDate() : new Date(cStartRaw);
        const cEnd: Date = cEndRaw.toDate ? cEndRaw.toDate() : new Date(cEndRaw);
        for (const mine of mySessions) {
          if (mine.start.toDateString() !== cStart.toDateString()) continue;
          if (timesOverlapDate(mine.start, mine.end, cStart, cEnd)) {
            timeOk = false;
            break;
          }
        }
      });

      // Compute distance bucket from area codes
      let distanceBucket = '10_20km';
      if (modeNorm === 'online') distanceBucket = '0_5km';
      else if (areaCode && area) {
        const sCity = String(areaCode).split('-')[0];
        const cArea = area as string;
        const cCity = String(cArea).split('-')[0];
        if (areaCode === cArea) distanceBucket = '0_5km';
        else if (sCity === cCity) distanceBucket = '5_10km';
        else distanceBucket = '10_20km';
      }
      instances.push({
        student_id: studentId,
        class_id: c.id,
        subject_match: subj ? subjects.includes(subj) : false,
        grade_match: Number(cl.grade) === grade,
        time_overlap: timeOk,
        distance_bucket: distanceBucket,
        price_band_fit: (priceBand || 'mid') === 'mid',
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
    // Prefer Functions config; fall back to env only if config is absent
    const endpointId = (cfg.recs?.endpoint_id) || process.env.RECS_ENDPOINT_ID || '8590470054162726912';
    const projectId = (cfg.recs?.project_id) || process.env.RECS_PROJECT_ID || DATA_PLATFORM.dataProjectId;
    const projectNumber = (cfg.recs?.project_number) || process.env.RECS_PROJECT_NUMBER;
    const endpointDomain = (cfg.recs?.endpoint_domain) || process.env.RECS_ENDPOINT_DOMAIN;
    const region = 'us-central1';
    // Dedicated endpoints must be called via dedicated domain:
    //   https://{ENDPOINT_ID}.{region}-{PROJECT_NUMBER}.prediction.vertexai.goog
    let url: string;
    if (endpointDomain) {
      url = `https://${endpointDomain}/v1/projects/${projectId}/locations/${region}/endpoints/${endpointId}:predict`;
    } else if (projectNumber) {
      url = `https://${endpointId}.${region}-${projectNumber}.prediction.vertexai.goog/v1/projects/${projectId}/locations/${region}/endpoints/${endpointId}:predict`;
    } else {
      // Fallback to shared domain (works for non-dedicated endpoints)
      url = `https://${region}-aiplatform.googleapis.com/v1/projects/${projectId}/locations/${region}/endpoints/${endpointId}:predict`;
    }
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
    let results = predictions.map((p, i) => ({ classId: classIds[i], score: getScore(p) }));
    // Fallback heuristic if Vertex returned empty or mismatched
    if (!results.length) {
      results = classIds.map((cid, i) => ({ classId: cid, score: 0 }));
    }
    results.sort((a, b) => b.score - a.score);
    // If specific classIds were requested, return all scored items (no trimming)
    let outResults = providedClassIds.length ? results : results.slice(0, limit);
    // Secondary fallback: if still empty, return top classes by tutor popularity (no model)
    if (!outResults.length) {
      const byPop = classesDocs.map((c) => ({
        classId: c.id,
        pop: (tutors.get((c.data() as any).tutorId) || 0)
      })).sort((a, b) => b.pop - a.pop).slice(0, limit);
      outResults = byPop.map((x) => ({ classId: x.classId, score: x.pop }));
    }
    return debug ? { results: outResults, debug: { predictions, instancesCount: instances.length } } : { results: outResults };
  });


