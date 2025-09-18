import * as functions from 'firebase-functions';
import { getAuth, getFirestore } from './init';
import { REGION } from './config';

type Role = 'student' | 'tutor' | 'admin';

interface SetUserRoleRequestBody {
  targetUid: string;
  role: Role;
  tutorApproved?: boolean;
}

function assertAdminContext(context: functions.https.CallableContext) {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Authentication required.');
  }
  if (context.auth.token.role !== 'admin') {
    throw new functions.https.HttpsError('permission-denied', 'Admin role required.');
  }
}

export const setUserRole = functions
  .region(REGION)
  .https.onCall(async (data: SetUserRoleRequestBody, context) => {
    assertAdminContext(context);

    const { targetUid, role, tutorApproved } = data || {};
    if (!targetUid || !role) {
      throw new functions.https.HttpsError('invalid-argument', 'targetUid and role are required.');
    }
    if (!['student', 'tutor', 'admin'].includes(role)) {
      throw new functions.https.HttpsError('invalid-argument', 'Invalid role value.');
    }

    await getAuth().setCustomUserClaims(targetUid, {
      role,
      tutorApproved: role === 'tutor' ? Boolean(tutorApproved) : undefined
    });

    await getFirestore()
      .collection('users')
      .doc(targetUid)
      .set({ role }, { merge: true });

    return { ok: true };
  });

async function requireAdminFromRequest(req: functions.https.Request) {
  const authHeader = req.headers.authorization || '';
  const match = authHeader.match(/^Bearer (.*)$/i);
  if (!match) {
    throw new functions.https.HttpsError('unauthenticated', 'Missing Bearer token.');
  }
  const idToken = match[1];
  const decoded = await getAuth().verifyIdToken(idToken);
  if (decoded.role !== 'admin') {
    throw new functions.https.HttpsError('permission-denied', 'Admin role required.');
  }
  return decoded;
}

export const approveTutor = functions
  .region(REGION)
  .https.onRequest(async (req, res) => {
    try {
      if (req.method !== 'POST') {
        res.status(405).json({ error: 'Method Not Allowed' });
        return;
      }
      const adminUser = await requireAdminFromRequest(req);
      const { tutorUid } = (req.body || {}) as { tutorUid?: string };
      if (!tutorUid) {
        res.status(400).json({ error: 'tutorUid is required' });
        return;
      }

      const db = getFirestore();
      const now = new Date().toISOString();

      await db
        .collection('tutor_profiles')
        .doc(tutorUid)
        .set(
          {
            status: 'approved',
            reviewed_by: adminUser.uid,
            reviewed_at: now
          },
          { merge: true }
        );

      await getAuth().setCustomUserClaims(tutorUid, { role: 'tutor', tutorApproved: true });
      await db.collection('users').doc(tutorUid).set({ role: 'tutor' }, { merge: true });

      res.status(200).json({ ok: true, tutorUid });
    } catch (err: any) {
      const code = err instanceof functions.https.HttpsError ? 403 : 500;
      res.status(code).json({ error: err.message || 'Internal error' });
    }
  });

export const revokeTutor = functions
  .region(REGION)
  .https.onRequest(async (req, res) => {
    try {
      if (req.method !== 'POST') {
        res.status(405).json({ error: 'Method Not Allowed' });
        return;
      }
      await requireAdminFromRequest(req);
      const { tutorUid } = (req.body || {}) as { tutorUid?: string };
      if (!tutorUid) {
        res.status(400).json({ error: 'tutorUid is required' });
        return;
      }

      const db = getFirestore();
      await db.collection('tutor_profiles').doc(tutorUid).set({ status: 'rejected' }, { merge: true });
      await getAuth().setCustomUserClaims(tutorUid, { role: 'student', tutorApproved: false });
      await db.collection('users').doc(tutorUid).set({ role: 'student' }, { merge: true });

      res.status(200).json({ ok: true, tutorUid });
    } catch (err: any) {
      const code = err instanceof functions.https.HttpsError ? 403 : 500;
      res.status(code).json({ error: err.message || 'Internal error' });
    }
  });


