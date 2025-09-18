import * as functions from 'firebase-functions';
import { REGION } from './config';
import { getAuth, getFirestore } from './init';
import { isoNow, timesOverlap, addDays } from './utils';

// publishClass: tutor/admin publishes a draft class after clash checks
// data: { classId: string }
export const publishClass = functions
  .region(REGION)
  .https.onCall(async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'Login required');
    }
    const uid = context.auth.uid;
    const role = (context.auth.token as any).role;
    const classId = data?.classId as string;
    if (!classId) {
      throw new functions.https.HttpsError('invalid-argument', 'classId is required');
    }

    const db = getFirestore();
    const snap = await db.collection('classes').doc(classId).get();
    if (!snap.exists) throw new functions.https.HttpsError('not-found', 'Class not found');
    const clazz = snap.data() as any;
    if (role !== 'admin' && !(role === 'tutor' && clazz.tutorId === uid)) {
      throw new functions.https.HttpsError('permission-denied', 'Not allowed');
    }
    if (clazz.status === 'published') return { ok: true, status: 'published' };

    // Clash check: verify no overlapping sessions for the tutor across all published classes
    const sessionsRef = db.collectionGroup('sessions').where('classId', '==', classId);
    const sessions = await sessionsRef.get();
    const tutorClasses = await db
      .collection('classes')
      .where('tutorId', '==', clazz.tutorId)
      .where('status', '==', 'published')
      .get();

    const otherSessionSnaps = await Promise.all(
      tutorClasses.docs.map((d) => db.collection('classes').doc(d.id).collection('sessions').get())
    );
    const otherSessions = otherSessionSnaps.flatMap((q) => q.docs.map((d) => ({ id: d.id, ...d.data() } as any)));

    for (const s of sessions.docs) {
      const a = s.data() as any;
      for (const b of otherSessions) {
        if (a.session_date === b.session_date && timesOverlap(a.start_time || a.startTime, a.end_time || a.endTime, b.start_time || b.startTime, b.end_time || b.endTime)) {
          throw new functions.https.HttpsError('failed-precondition', 'Session time clash detected');
        }
      }
    }

    await snap.ref.set({ status: 'published', publishedAt: isoNow() }, { merge: true });
    return { ok: true };
  });

// enrollInClass: student enrolls, seat check, create enrollment + invoice
// data: { classId: string }
export const enrollInClass = functions
  .region(REGION)
  .https.onCall(async (data, context) => {
    if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'Login required');
    const studentId = context.auth.uid;
    const role = (context.auth.token as any).role;
    if (role !== 'student') throw new functions.https.HttpsError('permission-denied', 'Student role required');
    const classId = data?.classId as string;
    if (!classId) throw new functions.https.HttpsError('invalid-argument', 'classId is required');

    const db = getFirestore();
    const classRef = db.collection('classes').doc(classId);
    await db.runTransaction(async (trx) => {
      const classSnap = await trx.get(classRef);
      if (!classSnap.exists) throw new functions.https.HttpsError('not-found', 'Class not found');
      const c = classSnap.data() as any;
      if (c.status !== 'published') throw new functions.https.HttpsError('failed-precondition', 'Class not published');

      const enrollmentsSnap = await trx.get(
        db.collection('enrollments').where('classId', '==', classId).where('status', 'in', ['active', 'pending'])
      );
      const taken = enrollmentsSnap.size;
      if (taken >= (c.capacitySeats || c.capacity_seats)) {
        throw new functions.https.HttpsError('resource-exhausted', 'No seats available');
      }

      const enrollmentRef = db.collection('enrollments').doc();
      trx.set(enrollmentRef, {
        enrollmentId: enrollmentRef.id,
        classId,
        studentId,
        status: 'active',
        enrolledAt: isoNow()
      });

      const amount = Number(c.fee || 0);
      const dueDate = addDays(new Date(), 7);
      const invoiceRef = db.collection('invoices').doc();
      trx.set(invoiceRef, {
        invoiceId: invoiceRef.id,
        enrollmentId: enrollmentRef.id,
        amountDue: amount,
        status: 'awaiting_proof',
        dueDate: dueDate.toISOString().slice(0, 10),
        createdAt: isoNow()
      });
    });
    return { ok: true };
  });

// submitPaymentProof: student submits payment proof url
// data: { invoiceId: string, proofUrl: string, method?: string }
export const submitPaymentProof = functions
  .region(REGION)
  .https.onCall(async (data, context) => {
    if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'Login required');
    const studentId = context.auth.uid;
    const role = (context.auth.token as any).role;
    if (role !== 'student') throw new functions.https.HttpsError('permission-denied', 'Student role required');

    const invoiceId = data?.invoiceId as string;
    const proofUrl = data?.proofUrl as string;
    const method = (data?.method as string) || 'bank_transfer';
    if (!invoiceId || !proofUrl) throw new functions.https.HttpsError('invalid-argument', 'invoiceId and proofUrl are required');

    const db = getFirestore();
    const invoiceSnap = await db.collection('invoices').doc(invoiceId).get();
    if (!invoiceSnap.exists) throw new functions.https.HttpsError('not-found', 'Invoice not found');
    const invoice = invoiceSnap.data() as any;

    // Optional: ensure the invoice belongs to the student
    const enrollment = await db.collection('enrollments').doc(invoice.enrollmentId).get();
    if (!enrollment.exists) throw new functions.https.HttpsError('not-found', 'Enrollment not found');
    if ((enrollment.data() as any).studentId !== studentId) {
      throw new functions.https.HttpsError('permission-denied', 'Not your invoice');
    }

    const paymentRef = db.collection('payments').doc();
    await paymentRef.set({
      paymentId: paymentRef.id,
      invoiceId,
      paidAmount: Number(invoice.amountDue || 0),
      paidAt: isoNow(),
      method,
      proofUrl,
      verifyStatus: 'pending'
    });

    await invoiceSnap.ref.set({ status: 'under_review' }, { merge: true });
    return { ok: true };
  });


