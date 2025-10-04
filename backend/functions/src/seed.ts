import * as functions from 'firebase-functions';
import { REGION } from './config';
import { getAuth, getFirestore } from './init';
import { isoNow } from './utils';

interface SeedUserDef {
  email: string;
  password: string;
  fullName: string;
  role: 'student' | 'tutor';
  grade?: number;
  areaCode?: string;
  subjects?: string[];
}

async function getOrCreateUser(def: SeedUserDef) {
  const auth = getAuth();
  try {
    const user = await auth.getUserByEmail(def.email);
    return user;
  } catch (_) {
    const user = await auth.createUser({ email: def.email, password: def.password, displayName: def.fullName });
    return user;
  }
}

export const seedTestData = functions
  .region(REGION)
  .https.onCall(async (_data, context) => {
    if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'Login required');
    const role = (context.auth.token as any).role;
    if (role !== 'admin') throw new functions.https.HttpsError('permission-denied', 'Admin role required');

    const db = getFirestore();
    const now = new Date();

    // Wipe previous seeded data safely (by our known emails and by labels)
    const seedTutorEmails = [
      'nimal.tutor1+dev@ai-classmate.dev',
      'shalini.tutor2+dev@ai-classmate.dev'
    ];
    const seedStudentEmails = [
      'anushka.student1+dev@ai-classmate.dev',
      'kavindu.student2+dev@ai-classmate.dev',
      'isuri.student3+dev@ai-classmate.dev',
      'pasindu.student4+dev@ai-classmate.dev'
    ];

    // Delete previous classes created by seed (tagged with seeded: true)
    const oldClasses = await db.collection('classes').where('seeded', '==', true).get();
    await Promise.all(oldClasses.docs.map(async (d) => {
      const sess = await d.ref.collection('sessions').get();
      await Promise.all(sess.docs.map((s) => s.ref.delete()));
      await d.ref.delete();
    }));
    // Delete enrollments linked to seed synthetic students
    const oldEnrs = await db.collection('enrollments').where('studentId', '>=', 'seed_pop_').where('studentId', '<', 'seed_pop_~').get();
    await Promise.all(oldEnrs.docs.map((d) => d.ref.delete()));

    const tutors: SeedUserDef[] = [
      {
        email: 'nimal.tutor1+dev@ai-classmate.dev',
        password: 'Tutor123!',
        fullName: 'Nimal Perera',
        role: 'tutor',
        areaCode: 'CMB-05',
        subjects: ['OL_MATH', 'OL_ENG']
      },
      {
        email: 'shalini.tutor2+dev@ai-classmate.dev',
        password: 'Tutor123!',
        fullName: 'Shalini Silva',
        role: 'tutor',
        areaCode: 'CMB-06',
        subjects: ['OL_SCI', 'AL_PHYS']
      }
    ];

    const students: SeedUserDef[] = [
      {
        email: 'anushka.student1+dev@ai-classmate.dev',
        password: 'Student123!',
        fullName: 'Anushka Fernando',
        role: 'student',
        grade: 11,
        areaCode: 'CMB-05',
        subjects: ['OL_MATH', 'OL_SCI']
      },
      {
        email: 'kavindu.student2+dev@ai-classmate.dev',
        password: 'Student123!',
        fullName: 'Kavindu Jayasinghe',
        role: 'student',
        grade: 10,
        areaCode: 'CMB-06',
        subjects: ['OL_MATH']
      },
      {
        email: 'isuri.student3+dev@ai-classmate.dev',
        password: 'Student123!',
        fullName: 'Isuri Peries',
        role: 'student',
        grade: 11,
        areaCode: 'CMB-06',
        subjects: ['OL_SCI']
      },
      {
        email: 'pasindu.student4+dev@ai-classmate.dev',
        password: 'Student123!',
        fullName: 'Pasindu Weerasinghe',
        role: 'student',
        grade: 11,
        areaCode: 'CMB-05',
        subjects: ['OL_MATH']
      }
    ];

    // Create/ensure users and base profiles
    const createdTutors = [] as any[];
    for (const t of tutors) {
      const u = await getOrCreateUser(t);
      await getAuth().setCustomUserClaims(u.uid, { role: 'tutor', tutorApproved: true });
      await db.collection('users').doc(u.uid).set({ role: 'tutor' }, { merge: true });
      // Create tutor profile as pending then approve
      await db.collection('tutor_profiles').doc(u.uid).set({
        full_name: t.fullName,
        status: 'pending',
        area_code: t.areaCode,
        subjects_taught: t.subjects || [],
        created_at: isoNow(),
      }, { merge: true });
      await db.collection('tutor_profiles').doc(u.uid).set({
        status: 'approved',
        reviewed_by: context.auth!.uid,
        reviewed_at: isoNow(),
      }, { merge: true });
      createdTutors.push({ uid: u.uid, email: t.email, password: t.password, fullName: t.fullName });
    }

    const createdStudents = [] as any[];
    for (const s of students) {
      const u = await getOrCreateUser(s);
      await getAuth().setCustomUserClaims(u.uid, { role: 'student' });
      await db.collection('users').doc(u.uid).set({ role: 'student' }, { merge: true });
      await db.collection('student_profiles').doc(u.uid).set({
        full_name: s.fullName,
        grade: s.grade,
        area_code: s.areaCode,
        subjects_of_interest: s.subjects || [],
        created_at: isoNow(),
      }, { merge: true });
      createdStudents.push({ uid: u.uid, email: s.email, password: s.password, fullName: s.fullName });
    }

    // Helper to create sessions in the future without clashes
    function buildSession(dayOffset: number, startHour: number, durationMinutes: number) {
      const start = new Date(now.getTime());
      start.setDate(start.getDate() + dayOffset);
      start.setHours(startHour, 0, 0, 0);
      const end = new Date(start.getTime() + durationMinutes * 60 * 1000);
      return { start, end };
    }

    // Create draft classes for each tutor, add sessions, then publish
    for (const t of createdTutors) {
      const tutorId = t.uid as string;
      const classes = [
        {
          name: 'OL Mathematics - Group (Havelock)',
          subject_code: 'OL_MATH',
          subjectCode: 'OL_MATH',
          type: 'Group',
          mode: 'In-person',
          modeRaw: 'physical',
          grade: 11,
          area_code: 'CMB-05',
          areaCode: 'CMB-05',
          price: 5000,
          priceBand: 'mid',
          max_students: 30,
          capacitySeats: 30,
          description: 'Weekly OL Mathematics group class',
        },
        {
          name: 'OL Science - Individual (Online)',
          subject_code: 'OL_SCI',
          subjectCode: 'OL_SCI',
          type: 'Individual',
          mode: 'Online',
          modeRaw: 'online',
          grade: 11,
          area_code: 'CMB-06',
          areaCode: 'CMB-06',
          price: 3500,
          priceBand: 'low',
          max_students: 1,
          capacitySeats: 1,
          description: 'One-to-one OL Science online class',
        },
        {
          name: 'OL English - Group (Kollupitiya)',
          subject_code: 'OL_ENG',
          subjectCode: 'OL_ENG',
          type: 'Group',
          mode: 'In-person',
          modeRaw: 'physical',
          grade: 10,
          area_code: 'CMB-03',
          areaCode: 'CMB-03',
          price: 3000,
          priceBand: 'low',
          max_students: 25,
          capacitySeats: 25,
          description: 'OL English weekly group',
        },
        {
          name: 'A/L Physics - Hybrid',
          subject_code: 'AL_PHYS',
          subjectCode: 'AL_PHYS',
          type: 'Group',
          mode: 'Hybrid',
          modeRaw: 'hybrid',
          grade: 12,
          area_code: 'CMB-07',
          areaCode: 'CMB-07',
          price: 6500,
          priceBand: 'high',
          max_students: 40,
          capacitySeats: 40,
          description: 'Advanced Physics hybrid class',
        }
      ];

      let dayOffset = 3; // start a few days from now
      for (const c of classes) {
        const classRef = db.collection('classes').doc();
        await classRef.set({
          classId: classRef.id,
          tutorId,
          ...c,
          enrolled_count: 0,
          total_income: 0,
          status: 'draft',
          seeded: true,
          created_at: new Date(),
        });

        // two sessions not overlapping per tutor
        const s1 = buildSession(dayOffset, 10, 120);
        const s2 = buildSession(dayOffset + 7, 10, 120);
        await classRef.collection('sessions').add({ start_time: s1.start, end_time: s1.end, label: 'Weekly Session' });
        await classRef.collection('sessions').add({ start_time: s2.start, end_time: s2.end, label: 'Weekly Session' });

        await classRef.set({ status: 'published', publishedAt: isoNow() }, { merge: true });
        dayOffset += 1; // next class starts next day to avoid clash
      }
    }

    // Create popularity signal via enrollments across tutors
    const allClasses = await getFirestore().collection('classes').where('status', '==', 'published').get();
    const classIdsByTutor = new Map<string, string[]>();
    allClasses.docs.forEach((d) => {
      const tutorId = (d.data() as any).tutorId as string;
      if (!classIdsByTutor.has(tutorId)) classIdsByTutor.set(tutorId, []);
      classIdsByTutor.get(tutorId)!.push(d.id);
    });

    async function createEnrollment(studentId: string, classId: string) {
      const ref = getFirestore().collection('enrollments').doc();
      await ref.set({ enrollmentId: ref.id, studentId, classId, status: 'active', enrolledAt: isoNow() });
    }

    const [t1, t2] = createdTutors.map((x) => x.uid as string);
    const t1Classes = classIdsByTutor.get(t1 || '') || [];
    const t2Classes = classIdsByTutor.get(t2 || '') || [];

    // More enrollments for tutor1 to boost popularity
    for (let i = 0; i < 10; i++) {
      const sid = `seed_pop_s1_${i}`;
      if (t1Classes[0]) await createEnrollment(sid, t1Classes[0]);
    }
    for (let i = 0; i < 4; i++) {
      const sid = `seed_pop_s2_${i}`;
      if (t2Classes[0]) await createEnrollment(sid, t2Classes[0]);
    }

    // Enroll real seeded students to create personal schedule and more variance
    if (createdStudents.length >= 2 && t1Classes[0]) {
      await createEnrollment(createdStudents[0].uid, t1Classes[0]);
    }
    if (createdStudents.length >= 3 && t2Classes[0]) {
      await createEnrollment(createdStudents[2].uid, t2Classes[0]);
    }

    return {
      ok: true,
      students: createdStudents,
      tutors: createdTutors,
    };
  });


