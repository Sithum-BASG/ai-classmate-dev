import * as functions from 'firebase-functions';
import { REGION } from './config';
import { initializeAdmin } from './init';

initializeAdmin();

export const health = functions
  .region(REGION)
  .https.onRequest((req, res) => {
    res.status(200).json({ ok: true, ts: new Date().toISOString() });
  });

