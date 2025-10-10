import * as functions from 'firebase-functions';
import { REGION } from './config';
import { getAuth, getFirestore } from './init';
import { FieldValue } from 'firebase-admin/firestore';
import { isoNow, timesOverlap, timesOverlapDate, addDays } from './utils';

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
    // Allow admins, or class owner with approved tutor profile
    const isAdmin = role === 'admin';
    if (!isAdmin) {
      if (clazz.tutorId !== uid) {
        throw new functions.https.HttpsError('permission-denied', 'Not allowed');
      }
      const prof = await db.collection('tutor_profiles').doc(uid).get();
      const approved = prof.exists && (prof.data() as any)?.status === 'approved';
      if (!approved) {
        throw new functions.https.HttpsError('permission-denied', 'Tutor not approved');
      }
    }
    if (clazz.status === 'published') return { ok: true, status: 'published' };

    // Clash check: verify no overlapping sessions for the tutor across all published classes
    // Read only this class' sessions directly (more robust than collectionGroup for this case)
    const sessions = await db
      .collection('classes')
      .doc(classId)
      .collection('sessions')
      .get();
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
      const aStartRaw = a.start_time || a.startTime;
      const aEndRaw = a.end_time || a.endTime;
      if (!aStartRaw || !aEndRaw) continue;
      const aStart: Date = aStartRaw.toDate ? aStartRaw.toDate() : new Date(aStartRaw);
      const aEnd: Date = aEndRaw.toDate ? aEndRaw.toDate() : new Date(aEndRaw);
      for (const b of otherSessions) {
        const bStartRaw = (b as any).start_time || (b as any).startTime;
        const bEndRaw = (b as any).end_time || (b as any).endTime;
        if (!bStartRaw || !bEndRaw) continue;
        const bStart: Date = bStartRaw.toDate ? bStartRaw.toDate() : new Date(bStartRaw);
        const bEnd: Date = bEndRaw.toDate ? bEndRaw.toDate() : new Date(bEndRaw);
        if (aStart.toDateString() !== bStart.toDateString()) continue;
        if (timesOverlapDate(aStart, aEnd, bStart, bEnd)) {
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
      // Fetch student profile for name/grade snapshot at enrollment time
      const profSnap = await trx.get(db.collection('student_profiles').doc(studentId));
      const prof = profSnap.exists ? (profSnap.data() as any) : undefined;
      trx.set(enrollmentRef, {
        enrollmentId: enrollmentRef.id,
        classId,
        studentId,
        status: 'active',
        enrolledAt: isoNow(),
        studentName: prof?.full_name || null,
        studentGrade: prof?.grade || null,
      });

      // Grant tutor read access to this student's profile via authorizedTutors map
      const authUpdate: any = {};
      authUpdate[`authorizedTutors.${c.tutorId}`] = true;
      trx.set(db.collection('student_profiles').doc(studentId), authUpdate, { merge: true });

      const amount = Number(c.fee || 0);
      const dueDate = addDays(new Date(), 7);
      const invoiceRef = db.collection('invoices').doc();
      trx.set(invoiceRef, {
        invoiceId: invoiceRef.id,
        enrollmentId: enrollmentRef.id,
        studentId, // for Firestore rules read access
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


// unenrollFromClass: student cancels their enrollment
// data: { enrollmentId: string }
export const unenrollFromClass = functions
  .region(REGION)
  .https.onCall(async (data, context) => {
    if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'Login required');
    const studentId = context.auth.uid;
    const role = (context.auth.token as any).role;
    if (role !== 'student') throw new functions.https.HttpsError('permission-denied', 'Student role required');

    const enrollmentId = data?.enrollmentId as string;
    if (!enrollmentId) throw new functions.https.HttpsError('invalid-argument', 'enrollmentId is required');

    const db = getFirestore();
    const enrollRef = db.collection('enrollments').doc(enrollmentId);
    const snap = await enrollRef.get();
    if (!snap.exists) throw new functions.https.HttpsError('not-found', 'Enrollment not found');
    const en = snap.data() as any;
    if (en.studentId !== studentId) throw new functions.https.HttpsError('permission-denied', 'Not your enrollment');
    if (en.status === 'cancelled') return { ok: true, status: 'cancelled' };

    await enrollRef.set({ status: 'cancelled', cancelledAt: isoNow() }, { merge: true });

    // Revoke tutor's read access for this student (best-effort)
    try {
      const db = getFirestore();
      const enrollment = (await enrollRef.get()).data() as any;
      const classSnap = await db.collection('classes').doc(enrollment.classId).get();
      const tutorId = (classSnap.data() as any)?.tutorId as string | undefined;
      if (tutorId) {
        const delUpdate: any = {};
        delUpdate[`authorizedTutors.${tutorId}`] = FieldValue.delete();
        await db.collection('student_profiles').doc(studentId).set(delUpdate, { merge: true });
      }
    } catch (_) {
      // ignore
    }
    return { ok: true };
  });

// createOrUpdateSession: validates overlap and writes a session doc
// data: { classId: string, sessionId?: string, startTime: string, endTime: string, label?: string, venue?: string }
export const createOrUpdateSession = functions
  .region(REGION)
  .https.onCall(async (data, context) => {
    if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'Login required');
    const uid = context.auth.uid;
    const role = (context.auth.token as any).role;

    const classId = data?.classId as string;
    const sessionId = (data?.sessionId as string) || undefined;
    const startTimeIso = data?.startTime as string | undefined;
    const endTimeIso = data?.endTime as string | undefined;
    const startMs = (data?.startMs as number | undefined);
    const endMs = (data?.endMs as number | undefined);
    const label = (data?.label as string) || undefined;
    const venue = (data?.venue as string) || undefined;
    const repeatWeekly = Boolean(data?.repeatWeekly);
    const weekday = (data?.weekday as number | undefined);

    if (!classId || (!startTimeIso && !startMs) || (!endTimeIso && !endMs)) {
      throw new functions.https.HttpsError('invalid-argument', 'classId and start/end time required');
    }
    const start = startMs !== undefined ? new Date(startMs) : new Date(startTimeIso as string);
    const end = endMs !== undefined ? new Date(endMs) : new Date(endTimeIso as string);
    if (!(start instanceof Date) || isNaN(start.getTime()) || !(end instanceof Date) || isNaN(end.getTime())) {
      throw new functions.https.HttpsError('invalid-argument', 'Invalid start/end time');
    }
    if (end <= start) {
      throw new functions.https.HttpsError('invalid-argument', 'End must be after start');
    }

    const db = getFirestore();
    const classSnap = await db.collection('classes').doc(classId).get();
    if (!classSnap.exists) throw new functions.https.HttpsError('not-found', 'Class not found');
    const clazz = classSnap.data() as any;
    const isAdmin = role === 'admin';
    if (!isAdmin) {
      if (clazz.tutorId !== uid) {
        throw new functions.https.HttpsError('permission-denied', 'Not allowed');
      }
      const prof = await db.collection('tutor_profiles').doc(uid).get();
      const approved = prof.exists && (prof.data() as any)?.status === 'approved';
      if (!approved) {
        throw new functions.https.HttpsError('permission-denied', 'Tutor not approved');
      }
    }

    // Overlap check across tutor's all sessions (including drafts and this class)
    const tutorClasses = await db.collection('classes').where('tutorId', '==', clazz.tutorId).get();
    const sessionSnaps = await Promise.all(
      tutorClasses.docs.map((d) => db.collection('classes').doc(d.id).collection('sessions').get())
    );
    const allSessions = sessionSnaps.flatMap((q, idx) => q.docs.map((d) => ({ id: d.id, ...d.data() } as any)));

    for (const s of allSessions) {
      if (sessionId && s.id === sessionId) continue; // ignore self when editing
      const sStart = s.start_time || s.startTime;
      const sEnd = s.end_time || s.endTime;
      if (!sStart || !sEnd) continue;
      const aStart = sStart.toDate ? sStart.toDate() : new Date(sStart);
      const aEnd = sEnd.toDate ? sEnd.toDate() : new Date(sEnd);
      if (aStart.toDateString() !== start.toDateString()) continue; // different date
      if (timesOverlapDate(start, end, aStart, aEnd)) {
        throw new functions.https.HttpsError('failed-precondition', 'Session time clash detected');
      }
    }

    const payload: any = {
      start_time: start,
      end_time: end,
      classId,
    };
    if (label) payload.label = label;
    if (venue) payload.venue = venue;
    if (repeatWeekly) payload.repeatWeekly = true;
    if (repeatWeekly && typeof weekday === 'number') payload.weekday = weekday;

    if (sessionId) {
      await db.collection('classes').doc(classId).collection('sessions').doc(sessionId).set(payload, { merge: true });
      return { ok: true, sessionId };
    }
    const ref = await db.collection('classes').doc(classId).collection('sessions').add({
      ...payload,
      created_at: new Date(),
    });
    return { ok: true, sessionId: ref.id };
  });

// Scheduled job: create next weekly session for sessions with repeatWeekly=true once past
export const rollForwardWeeklySessions = functions
  .region(REGION)
  .pubsub.schedule('every 12 hours')
  .onRun(async () => {
    const db = getFirestore();
    const now = new Date();
    // Admin privileges; read all sessions that are recurring
    const qs = await db.collectionGroup('sessions').where('repeatWeekly', '==', true).get();
    const byClass: Record<string, any[]> = {};
    for (const d of qs.docs) {
      const s = d.data() as any;
      const startRaw = s.start_time || s.startTime;
      const endRaw = s.end_time || s.endTime;
      if (!startRaw || !endRaw) continue;
      const start: Date = startRaw.toDate ? startRaw.toDate() : new Date(startRaw);
      const end: Date = endRaw.toDate ? endRaw.toDate() : new Date(endRaw);
      if (end > now) continue; // only roll forward after session ends
      const parent = (d.ref.parent.parent); // classes/{classId}
      if (!parent) continue;
      const classId = parent.id;
      if (!byClass[classId]) byClass[classId] = [];
      byClass[classId].push({ id: d.id, ref: d.ref, start, end, data: s });
    }

    for (const [classId, sessions] of Object.entries(byClass)) {
      // For each recurring session, attempt to create the immediate next week if not present
      for (const s of sessions) {
        const next = new Date(s.start.getTime());
        next.setDate(next.getDate() + 7);
        const yearEnd = new Date(next.getFullYear(), 11, 31, 23, 59, 59, 999);
        if (next > yearEnd) continue;
        const nextEnd = new Date(s.end.getTime());
        nextEnd.setDate(nextEnd.getDate() + 7);

        const classRef = db.collection('classes').doc(classId);
        const sessionsRef = classRef.collection('sessions');
        // idempotency: check if a session exists on that date with same start hour/min
        const dayStart = new Date(next.getFullYear(), next.getMonth(), next.getDate());
        const dayEnd = new Date(next.getFullYear(), next.getMonth(), next.getDate(), 23, 59, 59, 999);
        const existing = await sessionsRef
          .where('start_time', '>=', dayStart)
          .where('start_time', '<=', dayEnd)
          .get();
        let found = false;
        for (const e of existing.docs) {
          const es = (e.data() as any).start_time;
          if (!es) continue;
          const est = es.toDate ? es.toDate() : new Date(es);
          if (est.getHours() === next.getHours() && est.getMinutes() === next.getMinutes()) {
            found = true;
            break;
          }
        }
        if (found) continue;

        await sessionsRef.add({
          start_time: next,
          end_time: nextEnd,
          classId,
          label: s.data.label || null,
          venue: s.data.venue || null,
          repeatWeekly: true,
          weekday: s.data.weekday || next.getDay(),
          created_at: new Date(),
        });
      }
    }
    return null;
  });


// getOrCreateCurrentMonthInvoice: returns existing invoice for current month or creates one
// data: { enrollmentId: string }
export const getOrCreateCurrentMonthInvoice = functions
  .region(REGION)
  .https.onCall(async (data, context) => {
    if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'Login required');
    const studentId = context.auth.uid;
    const role = (context.auth.token as any).role;
    if (role !== 'student') throw new functions.https.HttpsError('permission-denied', 'Student role required');

    const enrollmentId = data?.enrollmentId as string;
    if (!enrollmentId) throw new functions.https.HttpsError('invalid-argument', 'enrollmentId is required');

    const db = getFirestore();
    const enrollSnap = await db.collection('enrollments').doc(enrollmentId).get();
    if (!enrollSnap.exists) throw new functions.https.HttpsError('not-found', 'Enrollment not found');
    const enrollment = enrollSnap.data() as any;
    if (enrollment.studentId !== studentId) {
      throw new functions.https.HttpsError('permission-denied', 'Not your enrollment');
    }

    const now = new Date();
    const period = `${now.getUTCFullYear()}-${String(now.getUTCMonth() + 1).padStart(2, '0')}`; // e.g., 2025-10
    const invoiceId = `${enrollmentId}_${period}`; // deterministic ID avoids composite index
    const invoiceRef = db.collection('invoices').doc(invoiceId);
    const invSnap = await invoiceRef.get();

    if (!invSnap.exists) {
      const classSnap = await db.collection('classes').doc(enrollment.classId).get();
      if (!classSnap.exists) throw new functions.https.HttpsError('not-found', 'Class not found');
      const c = classSnap.data() as any;
      const amount = Number(c.price ?? c.fee ?? 0);
      const dueDate = addDays(now, 7);
      await invoiceRef.set({
        invoiceId,
        enrollmentId,
        studentId,
        amountDue: amount,
        status: 'awaiting_proof',
        dueDate: dueDate.toISOString().slice(0, 10),
        createdAt: isoNow(),
        period
      });
    }

    const out = await invoiceRef.get();
    return out.data();
  });

// reviewPayment: admin approves or rejects a pending payment proof
// data: { paymentId: string, approve: boolean, reason?: string }
export const reviewPayment = functions
  .region(REGION)
  .https.onCall(async (data, context) => {
    if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'Login required');
    const role = (context.auth.token as any).role;
    const reviewerId = context.auth.uid;
    if (role !== 'admin') throw new functions.https.HttpsError('permission-denied', 'Admin role required');

    const paymentId = data?.paymentId as string;
    const approve = Boolean(data?.approve);
    const reason = (data?.reason as string | undefined) || undefined;
    if (!paymentId) throw new functions.https.HttpsError('invalid-argument', 'paymentId is required');

    const db = getFirestore();
    const payRef = db.collection('payments').doc(paymentId);
    const paySnap = await payRef.get();
    if (!paySnap.exists) throw new functions.https.HttpsError('not-found', 'Payment not found');
    const payment = paySnap.data() as any;
    const invoiceId = payment.invoiceId as string | undefined;
    if (!invoiceId) throw new functions.https.HttpsError('failed-precondition', 'Payment missing invoiceId');

    const invRef = db.collection('invoices').doc(invoiceId);
    const invSnap = await invRef.get();
    if (!invSnap.exists) throw new functions.https.HttpsError('not-found', 'Invoice not found');

    const updates: any = {
      verifyStatus: approve ? 'approved' : 'rejected',
      reviewedBy: reviewerId,
      reviewedAt: isoNow()
    };
    if (!approve && reason) updates.rejectionReason = reason;

    await payRef.set(updates, { merge: true });
    await invRef.set({ status: approve ? 'approved' : 'rejected', reviewedBy: reviewerId, reviewedAt: isoNow() }, { merge: true });

    return { ok: true, status: updates.verifyStatus };
  });


// getEnrollmentPaymentStatus: returns invoice status for an enrollment to tutors/admins
// data: { enrollmentId: string }
export const getEnrollmentPaymentStatus = functions
  .region(REGION)
  .https.onCall(async (data, context) => {
    if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'Login required');
    const uid = context.auth.uid;
    const role = (context.auth.token as any).role;
    const enrollmentId = data?.enrollmentId as string;
    if (!enrollmentId) throw new functions.https.HttpsError('invalid-argument', 'enrollmentId is required');

    const db = getFirestore();
    const enrSnap = await db.collection('enrollments').doc(enrollmentId).get();
    if (!enrSnap.exists) throw new functions.https.HttpsError('not-found', 'Enrollment not found');
    const enr = enrSnap.data() as any;
    const classSnap = await db.collection('classes').doc(enr.classId).get();
    if (!classSnap.exists) throw new functions.https.HttpsError('not-found', 'Class not found');
    const clazz = classSnap.data() as any;
    const isAdmin = role === 'admin';
    if (!isAdmin && clazz.tutorId !== uid) {
      throw new functions.https.HttpsError('permission-denied', 'Not allowed');
    }

    const invSnap = await db
      .collection('invoices')
      .where('enrollmentId', '==', enrollmentId)
      .get();
    if (invSnap.empty) return { status: 'awaiting_proof' };
    let resolved: 'approved' | 'under_review' | 'rejected' | 'awaiting_proof' = 'awaiting_proof';
    let hasUnderReview = false;
    let hasRejected = false;
    for (const d of invSnap.docs) {
      const s = (d.data() as any).status as string | undefined;
      if (s === 'approved') { resolved = 'approved'; break; }
      if (s === 'under_review') hasUnderReview = true;
      if (s === 'rejected') hasRejected = true;
    }
    if (resolved !== 'approved') {
      if (hasUnderReview) resolved = 'under_review';
      else if (hasRejected) resolved = 'rejected';
    }
    return { status: resolved };
  });

