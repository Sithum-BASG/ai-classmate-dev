import * as functions from 'firebase-functions';
import { REGION } from './config';
import { initializeAdmin } from './init';
export { onUserCreate } from './auth_triggers';
export { setUserRole, approveTutor, revokeTutor } from './roles';
export { publishClass, enrollInClass, submitPaymentProof } from './core';
export { registerFcmToken } from './fcm';
export { getRecommendations, getSubjectForecast, getClassDemandForecast, getMyClassDemandForecast } from './ai';
export { getRecommendationsRealtime } from './recs_realtime';

initializeAdmin();

export const health = functions
  .region(REGION)
  .https.onRequest((req, res) => {
    res.status(200).json({ ok: true, ts: new Date().toISOString() });
  });

