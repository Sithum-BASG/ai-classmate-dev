import * as functions from 'firebase-functions';
import { REGION } from './config';
import { getFirestore } from './init';

// Callable: initMaterialUpload – creates a metadata doc under classes/{classId}/materials/{materialId}
// Returns a target storage path to upload to: class_materials/{classId}/{materialId}/{fileName}
export const initMaterialUpload = functions
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
    const fileName = (data?.fileName as string) || 'material.pdf';
    if (!classId) {
      throw new functions.https.HttpsError('invalid-argument', 'classId is required');
    }
    const db = getFirestore();
    const classSnap = await db.collection('classes').doc(classId).get();
    if (!classSnap.exists) throw new functions.https.HttpsError('not-found', 'Class not found');
    const clazz = classSnap.data() as any;
    if (role !== 'admin' && clazz.tutorId !== context.auth.uid) {
      throw new functions.https.HttpsError('permission-denied', 'Not your class');
    }
    const matRef = db.collection('classes').doc(classId).collection('materials').doc();
    const materialId = matRef.id;
    await matRef.set({
      materialId,
      fileName,
      uploadedBy: context.auth.uid,
      uploadedAt: new Date().toISOString()
    }, { merge: true });

    const storagePath = `class_materials/${classId}/${materialId}/${fileName}`;
    return { materialId, storagePath };
  });


