// Seed Firestore Emulator with sample students, tutors, classes, and enrollments
// Usage (from backend/):
//   firebase emulators:exec --project ai-classmate-dev "node .\\functions\\scripts\\seed.js" --import .\.emulator-data --export-on-exit
// Or if emulators are already running:
//   $env:FIRESTORE_EMULATOR_HOST="127.0.0.1:8080"; $env:GCLOUD_PROJECT="ai-classmate-dev"; node .\functions\scripts\seed.js

const admin = require('firebase-admin');

if (!admin.apps.length) {
  admin.initializeApp({ projectId: process.env.GCLOUD_PROJECT || 'ai-classmate-dev' });
}

const db = admin.firestore();

async function upsertDoc(col, id, data) {
  await db.collection(col).doc(id).set(data, { merge: true });
}

async function seed() {
  const now = new Date().toISOString();

  // Students
  await upsertDoc('student_profiles', 'studentA', {
    user_id: 'studentA',
    grade: 11,
    area_code: 'CMB-01',
    subjects_of_interest: ['OL_MATH', 'OL_SCI']
  });

  // Tutors (approved)
  await upsertDoc('tutor_profiles', 'tutorA', { status: 'approved', area_code: 'CMB-01', subjects_taught: ['OL_MATH'] });
  await upsertDoc('tutor_profiles', 'tutorB', { status: 'approved', area_code: 'CMB-01', subjects_taught: ['OL_MATH'] });
  await upsertDoc('tutor_profiles', 'tutorC', { status: 'approved', area_code: 'CMB-01', subjects_taught: ['OL_MATH'] });

  // Classes (published)
  const classes = [
    { id: 'classA1', tutorId: 'tutorA', subjectCode: 'OL_MATH', grade: 11, areaCode: 'CMB-01', priceBand: 'mid', mode: 'online', fee: 5000, capacitySeats: 30, status: 'published', createdAt: now },
    { id: 'classA2', tutorId: 'tutorA', subjectCode: 'OL_MATH', grade: 11, areaCode: 'CMB-01', priceBand: 'high', mode: 'physical', fee: 7000, capacitySeats: 25, status: 'published', createdAt: now },
    { id: 'classB1', tutorId: 'tutorB', subjectCode: 'OL_MATH', grade: 11, areaCode: 'CMB-01', priceBand: 'low', mode: 'online', fee: 3500, capacitySeats: 35, status: 'published', createdAt: now },
    { id: 'classC1', tutorId: 'tutorC', subjectCode: 'OL_MATH', grade: 11, areaCode: 'CMB-01', priceBand: 'mid', mode: 'online', fee: 4500, capacitySeats: 30, status: 'published', createdAt: now }
  ];

  for (const c of classes) {
    await upsertDoc('classes', c.id, c);
  }

  // Enrollment popularity (tutorA most, tutorB mid, tutorC low)
  const enr = [];
  for (let i = 0; i < 10; i++) enr.push({ classId: 'classA1', studentId: `sA_${i}`, status: 'active', enrolledAt: now });
  for (let i = 0; i < 5; i++) enr.push({ classId: 'classB1', studentId: `sB_${i}`, status: 'active', enrolledAt: now });
  for (let i = 0; i < 1; i++) enr.push({ classId: 'classC1', studentId: `sC_${i}`, status: 'active', enrolledAt: now });

  for (const e of enr) {
    const ref = db.collection('enrollments').doc();
    await ref.set({ enrollmentId: ref.id, ...e });
  }

  console.log('Seed complete. Created:', {
    students: ['studentA'],
    tutors: ['tutorA', 'tutorB', 'tutorC'],
    classes: classes.map((x) => x.id),
    enrollments: enr.length
  });
}

seed().then(() => process.exit(0)).catch((e) => { console.error(e); process.exit(1); });


