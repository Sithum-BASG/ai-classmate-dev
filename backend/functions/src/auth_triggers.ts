import * as functions from 'firebase-functions';
import { getAuth, getFirestore } from './init';
import { REGION } from './config';

export const onUserCreate = functions
  .region(REGION)
  .auth.user()
  .onCreate(async (user) => {
    const db = getFirestore();
    const role = 'student';
    await db.collection('users').doc(user.uid).set(
      {
        email: user.email || null,
        phone: user.phoneNumber || null,
        role,
        status: 'active',
        created_at: new Date().toISOString()
      },
      { merge: true }
    );

    const existing = await getAuth().getUser(user.uid);
    const tokenRole = (existing.customClaims as any)?.role;
    if (!tokenRole) {
      await getAuth().setCustomUserClaims(user.uid, { role });
    }
  });


