import { cert, getApps, initializeApp } from 'firebase-admin/app';
import { getMessaging } from 'firebase-admin/messaging';

type FirebaseServiceAccount = {
  projectId: string;
  clientEmail: string;
  privateKey: string;
};

function readFirebaseServiceAccount(): FirebaseServiceAccount {
  const jsonValue = process.env.FIREBASE_SERVICE_ACCOUNT_JSON;

  if (jsonValue) {
    const raw = JSON.parse(jsonValue) as {
      projectId?: string;
      project_id?: string;
      clientEmail?: string;
      client_email?: string;
      privateKey?: string;
      private_key?: string;
    };

    const projectId = raw.projectId ?? raw.project_id;
    const clientEmail = raw.clientEmail ?? raw.client_email;
    const privateKey = raw.privateKey ?? raw.private_key;

    if (!projectId || !clientEmail || !privateKey) {
      throw new Error('FIREBASE_SERVICE_ACCOUNT_JSON is incomplete');
    }

    return {
      projectId,
      clientEmail,
      privateKey: privateKey.replace(/\\n/g, '\n'),
    };
  }

  const projectId = process.env.FIREBASE_PROJECT_ID;
  const clientEmail = process.env.FIREBASE_CLIENT_EMAIL;
  const privateKey = process.env.FIREBASE_PRIVATE_KEY;

  if (!projectId || !clientEmail || !privateKey) {
    throw new Error('Firebase Admin credentials are not configured');
  }

  return {
    projectId,
    clientEmail,
    privateKey: privateKey.replace(/\\n/g, '\n'),
  };
}

function getFirebaseApp() {
  const existing = getApps()[0];

  if (existing) {
    return existing;
  }

  const credentials = readFirebaseServiceAccount();

  return initializeApp({
    credential: cert({
      projectId: credentials.projectId,
      clientEmail: credentials.clientEmail,
      privateKey: credentials.privateKey,
    }),
  });
}

export function isFirebaseConfigured() {
  try {
    readFirebaseServiceAccount();
    return true;
  } catch {
    return false;
  }
}

export function getFirebaseMessaging() {
  return getMessaging(getFirebaseApp());
}
