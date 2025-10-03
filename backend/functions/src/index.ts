import * as functions from 'firebase-functions';
import { REGION } from './config';
import { initializeAdmin } from './init';
export { onUserCreate } from './auth_triggers';
export { setUserRole, approveTutor, revokeTutor } from './roles';
export { publishClass, enrollInClass, submitPaymentProof, unenrollFromClass, createOrUpdateSession, getOrCreateCurrentMonthInvoice, reviewPayment } from './core';
export { seedTestData } from './seed';
export { registerFcmToken } from './fcm';
export { getRecommendations, getSubjectForecast, getClassDemandForecast, getMyClassDemandForecast } from './ai';
export { getRecommendationsRealtime } from './recs_realtime';
export { initMaterialUpload } from './materials';
export { sendMessage, onMessageCreate } from './messaging';

initializeAdmin();

export const health = functions
  .region(REGION)
  .https.onRequest((req, res) => {
    res.status(200).json({ ok: true, ts: new Date().toISOString() });
  });

