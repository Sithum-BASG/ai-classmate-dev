import * as admin from 'firebase-admin';

let app: admin.app.App | null = null;

export function initializeAdmin(): admin.app.App {
  if (!app) {
    app = admin.initializeApp();
  }
  return app;
}

export function getFirestore(): admin.firestore.Firestore {
  return initializeAdmin().firestore();
}

export function getAuth(): admin.auth.Auth {
  return initializeAdmin().auth();
}

export function getMessaging(): admin.messaging.Messaging {
  return initializeAdmin().messaging();
}

