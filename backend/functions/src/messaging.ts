import * as functions from 'firebase-functions';
import { REGION } from './config';
import { getFirestore } from './init';
import { sendToUser } from './fcm';

// Callable: sendMessage – student/tutor sends a message to another user; stores under users/{uid}/messages
export const sendMessage = functions
  .region(REGION)
  .https.onCall(async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'Login required');
    }
    const toUserId = data?.toUserId as string;
    const text = (data?.text as string) || '';
    if (!toUserId || !text) {
      throw new functions.https.HttpsError('invalid-argument', 'toUserId and text required');
    }
    const db = getFirestore();
    const msgRef = db.collection('users').doc(toUserId).collection('messages').doc();
    await msgRef.set({
      messageId: msgRef.id,
      from: context.auth.uid,
      text,
      sentAt: new Date().toISOString(),
      read: false
    });
    // Fire-and-forget FCM notification; ignore errors
    sendToUser(toUserId, 'New message', text).catch(() => undefined);
    return { ok: true };
  });

// Firestore trigger: on new message, also mirror a notification (optional)
export const onMessageCreate = functions
  .region(REGION)
  .firestore.document('users/{userId}/messages/{messageId}')
  .onCreate(async (snap, ctx) => {
    const db = getFirestore();
    const { userId } = ctx.params as any;
    const data = snap.data() as any;
    await db.collection('users').doc(userId).collection('notifications').doc().set({
      type: 'message',
      title: 'New message',
      body: data.text,
      createdAt: new Date().toISOString(),
      read: false
    });
  });


