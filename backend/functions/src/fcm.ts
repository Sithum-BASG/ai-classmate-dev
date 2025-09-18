import * as functions from 'firebase-functions';
import { getFirestore, getMessaging } from './init';
import { REGION } from './config';

export const registerFcmToken = functions
  .region(REGION)
  .https.onCall(async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'Login required');
    }
    const token = data?.token as string;
    if (!token) throw new functions.https.HttpsError('invalid-argument', 'token required');
    const db = getFirestore();
    await db.collection('users').doc(context.auth.uid).set({ fcmToken: token }, { merge: true });
    return { ok: true };
  });

export async function sendToUser(userId: string, title: string, body: string) {
  const db = getFirestore();
  const userDoc = await db.collection('users').doc(userId).get();
  const token = (userDoc.data() as any)?.fcmToken;
  if (!token) return;
  await getMessaging().send({ token, notification: { title, body } });
}


