import * as functions from 'firebase-functions';
import { REGION, DATA_PLATFORM } from './config';
import { getFirestore } from './init';

async function getAccessToken(): Promise<string> {
  const { GoogleAuth } = await import('google-auth-library');
  const auth = new GoogleAuth({ scopes: ['https://www.googleapis.com/auth/cloud-platform'] });
  const client = await auth.getClient();
  const token = await client.getAccessToken();
  if (!token || !token.token) throw new Error('Failed to get access token');
  return token.token;
}

export const chatbotReply = functions
  .region(REGION)
  .https.onCall(async (data, context) => {
    try {
      if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'Login required');
      }
      const prompt = (data?.prompt as string | undefined)?.trim() || '';
      const debug = Boolean(data?.debug);
      if (!prompt) {
        throw new functions.https.HttpsError('invalid-argument', 'prompt is required');
      }

      const system = `You are AI ClassMate Assistant for a Flutter app using go_router.
Speak with short, step-by-step guidance that matches these exact screens/terms:
- Enroll flow: Search (/search) → open class (/class/:id) → Enroll (creates invoice) → Upload payment proof in Enrollment details (/enrollment/:id). Invoice statuses: awaiting_proof, under_review, approved, rejected.
- See invoices/payment: open Enrollment details (/enrollment/:id). Do not claim to take payments.
- Messages: Student chats are in /messages; tutor messages: quick message icon or class messages. Suggest opening /messages for replies.
- Announcements: /announcements shows global announcements to students.
- Classes: Published classes are visible; Available seats filter hides full classes; students don’t see classes they’re already enrolled in.
Rules:
- Be concise and actionable with numbered steps.
- Use exact route labels above; don’t invent routes.
- Never invent Firestore data or internal states; point to the correct screen to check.
- If unsure, say what screen to use rather than guessing.`;

      // Optional grounding from Firestore (ai_guidance/app.snippets)
      let guidanceExtra = '';
      try {
        const db = getFirestore();
        const g = await db.collection('ai_guidance').doc('app').get();
        const snippets = (g.exists ? ((g.data() as any)?.snippets as string | undefined) : undefined) || '';
        if (snippets && typeof snippets === 'string') guidanceExtra = `\n\nApp notes:\n${snippets}`;
      } catch (_) {
        // ignore and use default system only
      }

      const genRegion = process.env.GENAI_REGION || 'us-central1';
      const token = await getAccessToken();
      const body = {
        contents: [
          { role: 'user', parts: [{ text: prompt }] }
        ],
        systemInstruction: { role: 'system', parts: [{ text: system + guidanceExtra }] },
        generationConfig: {
          temperature: 0.3,
          maxOutputTokens: 512,
        }
      } as any;

      // Simple rate limit: min 2s between calls per user
      try {
        const db = getFirestore();
        const uref = db.collection('ai_usage').doc(context.auth.uid);
        const u = await uref.get();
        const now = Date.now();
        const last = (u.exists ? Number((u.data() as any)?.lastMs) : 0) || 0;
        if (now - last < 2000) {
          return { error: 'Too many requests. Please wait a moment and try again.' };
        }
        await uref.set({ lastMs: now }, { merge: true });
      } catch (_) { /* ignore */ }

      const preferred = (process.env.GENAI_MODEL || '').trim();
      const candidatesModels = [
        ...(preferred ? [preferred] : []),
        'gemini-2.5-flash',
        'gemini-2.0-flash-001'
      ];

      let last404 = '';
      for (const model of candidatesModels) {
        const url = `https://${genRegion}-aiplatform.googleapis.com/v1/projects/${DATA_PLATFORM.dataProjectId}/locations/${genRegion}/publishers/google/models/${model}:generateContent`;
        const resp = await fetch(url, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            Authorization: `Bearer ${token}`,
          },
          body: JSON.stringify(body),
        });
        if (!resp.ok) {
          const text = await resp.text();
          if (resp.status === 404) {
            last404 = model;
            console.warn('chatbotReply model_not_found', { model, region: genRegion });
            continue;
          }
          const errMsg = `Vertex error: ${resp.status} ${text}`;
          console.error('chatbotReply vertex_error', { project: DATA_PLATFORM.dataProjectId, err: errMsg, model });
          return { error: errMsg };
        }
        const dataJson: any = await resp.json();
        const cands = dataJson?.candidates || [];
        const first = cands[0];
        const content = first?.content?.parts?.map((p: any) => p.text).join('\n') || 'Sorry, I could not respond.';
        // Heuristic hints to open relevant routes
        const lc = prompt.toLowerCase();
        const hints: Array<{ label: string; route: string }> = [];
        if (lc.includes('enroll') || lc.includes('join') || lc.includes('class')) hints.push({ label: 'Browse classes', route: '/search' });
        if (lc.includes('invoice') || lc.includes('payment')) hints.push({ label: 'Open messages', route: '/messages' });
        hints.push({ label: 'Announcements', route: '/announcements' });

        // Fire-and-forget analytics
        try {
          const db = getFirestore();
          await db.collection('ai_logs').add({
            uid: context.auth.uid,
            ts: new Date().toISOString(),
            promptLen: prompt.length,
            replyLen: content.length,
            model,
          });
        } catch (_) { /* ignore */ }

        return debug ? { reply: content, raw: dataJson, model, hints } : { reply: content, model, hints };
      }

      const errMsg = `No accessible Gemini model in ${genRegion}. Tried: ${candidatesModels.join(', ')}. Last 404 on: ${last404}`;
      console.error('chatbotReply models_exhausted', errMsg);
      return { error: errMsg };
    } catch (e: any) {
      const msg = e?.message || String(e);
      console.error('chatbotReply_error', msg);
      // Return error payload instead of throwing, so client can show friendly message
      return { error: msg };
    }
  });

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
