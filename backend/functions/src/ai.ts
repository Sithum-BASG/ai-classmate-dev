import * as functions from 'firebase-functions';
import { REGION, DATA_PLATFORM } from './config';
import { getFirestore } from './init';

// Use BigQuery REST via @google-cloud/bigquery only in production; for emulator, skip requiring GOOGLE_APPLICATION_CREDENTIALS.
// We'll lazy import to avoid bundling issues in emulator.
async function getBigQuery() {
  const { BigQuery } = await import('@google-cloud/bigquery');
  return new BigQuery({ projectId: DATA_PLATFORM.dataProjectId });
}

// Shared compute from Firestore classes/enrollments + BQ subject forecast
async function computeClassDemandFromFirestoreAndBQ(classId: string, horizon: number) {
  const bq = await getBigQuery();
  const db = getFirestore();

  const classSnap = await db.collection('classes').doc(classId).get();
  if (!classSnap.exists) throw new Error('Class not found in Firestore');
  const clazz = classSnap.data() as any;
  const subjectCode = clazz.subjectCode;
  if (!subjectCode) throw new Error('Class missing subjectCode');

  const since = new Date();
  since.setDate(since.getDate() - 90);

  const peerSnap = await db
    .collection('classes')
    .where('subjectCode', '==', subjectCode)
    .where('status', '==', 'published')
    .limit(50)
    .get();
  const peerIds = peerSnap.docs.map((d) => d.id);

  async function countEnr(cid: string): Promise<number> {
    const q = await db
      .collection('enrollments')
      .where('classId', '==', cid)
      .where('status', 'in', ['active', 'completed'])
      .get();
    let n = 0;
    q.forEach((doc) => {
      const e = doc.data() as any;
      if (!e.enrolledAt || new Date(e.enrolledAt) >= since) n++;
    });
    return n;
  }

  let total = 0;
  let mine = 0;
  for (const pid of peerIds) {
    const c = await countEnr(pid);
    total += c;
    if (pid === classId) mine = c;
  }
  const nClasses = Math.max(1, peerIds.length);
  const classShare = (mine + 1) / (total + nClasses);

  const sql = `
    SELECT f.week_start, f.clicks_pred, f.pred_lo, f.pred_hi
    FROM ` + '`' + `${DATA_PLATFORM.dataProjectId}.${DATA_PLATFORM.bigQueryDataset}.v_subject_clicks_forecast` + '`' + ` f
    WHERE f.subject_code = @subjectCode AND f.week_start >= CURRENT_DATE()
    ORDER BY f.week_start
    LIMIT @horizon`;
  const [rows] = await bq.query({ query: sql, params: { subjectCode, horizon } });
  const results = rows.map((r: any) => ({
    week_start: r.week_start,
    demand_pred: Number(r.clicks_pred) * classShare,
    demand_lo: Number(r.pred_lo) * classShare,
    demand_hi: Number(r.pred_hi) * classShare
  }));

  return { classId, subjectCode, classShare, results };
}

export const getRecommendations = functions
  .region(REGION)
  .https.onRequest(async (req, res) => {
    try {
      const studentId = (req.query.student_id as string) || '';
      const limit = Number(req.query.limit || 10);
      if (!studentId) {
        res.status(400).json({ error: 'student_id required' });
        return;
      }

      const bq = await getBigQuery();
      // Assumption: batch prediction writes a table named recs_predictions with columns: student_id, class_id, score
      const dataset = DATA_PLATFORM.bigQueryDataset;
      const sql = `
        SELECT class_id, score
        FROM \`${DATA_PLATFORM.dataProjectId}.${dataset}.recs_predictions\`
        WHERE student_id = @studentId
        ORDER BY score DESC
        LIMIT @limit
      `;
      const [rows] = await bq.query({
        query: sql,
        params: { studentId, limit }
      });
      res.status(200).json({ studentId, results: rows });
    } catch (e: any) {
      res.status(500).json({ error: e.message || 'Internal error' });
    }
  });

export const getSubjectForecast = functions
  .region(REGION)
  .https.onRequest(async (req, res) => {
    try {
      const dataset = DATA_PLATFORM.bigQueryDataset;
      const bq = await getBigQuery();
      const sql = `
        SELECT subject_code, subject_name, week_start, clicks_pred, pred_lo, pred_hi
        FROM \`${DATA_PLATFORM.dataProjectId}.${dataset}.v_subject_clicks_forecast\`
        ORDER BY subject_code, week_start
        LIMIT 500
      `;
      const [rows] = await bq.query({ query: sql });
      res.status(200).json({ results: rows });
    } catch (e: any) {
      res.status(500).json({ error: e.message || 'Internal error' });
    }
  });

export const getClassDemandForecast = functions
  .region(REGION)
  .https.onRequest(async (req, res) => {
    try {
      const classId = (req.query.class_id as string) || '';
      const horizon = Number(req.query.horizon || 8);
      if (!classId) {
        res.status(400).json({ error: 'class_id required' });
        return;
      }
      const out = await computeClassDemandFromFirestoreAndBQ(classId, horizon);
      res.status(200).json(out);
    } catch (e: any) {
      res.status(500).json({ error: e.message || 'Internal error' });
    }
  });

export const getMyClassDemandForecast = functions
  .region(REGION)
  .https.onCall(async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'Login required');
    }
    const role = (context.auth.token as any)?.role;
    if (role !== 'tutor' && role !== 'admin') {
      throw new functions.https.HttpsError('permission-denied', 'Tutor or admin required');
    }
    const classId = data?.classId as string;
    const horizon = Number(data?.horizon || 8);
    if (!classId) {
      throw new functions.https.HttpsError('invalid-argument', 'classId is required');
    }

    // Verify ownership unless admin
    const db = getFirestore();
    const snap = await db.collection('classes').doc(classId).get();
    if (!snap.exists) throw new functions.https.HttpsError('not-found', 'Class not found');
    const clazz = snap.data() as any;
    if (role !== 'admin' && clazz.tutorId !== context.auth.uid) {
      throw new functions.https.HttpsError('permission-denied', 'Not your class');
    }

    const out = await computeClassDemandFromFirestoreAndBQ(classId, horizon);
    return out;
  });
