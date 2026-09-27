// Firebase *client* SDK — sign-in only. The browser never reads or writes
// Firestore directly (firestore.rules is write:false for clients and the
// NestJS API is the only data path); the SDK exists here purely to obtain
// an ID token that lib/api.ts forwards as `Authorization: Bearer`.
//
// Config is public by design (it identifies the project; it authorises
// nothing) and comes from NEXT_PUBLIC_FIREBASE_* — see .env.example.

import { getApps, initializeApp, type FirebaseApp } from "firebase/app";
import { connectAuthEmulator, getAuth, GoogleAuthProvider, type Auth } from "firebase/auth";

function readConfig() {
  const apiKey = process.env.NEXT_PUBLIC_FIREBASE_API_KEY;
  const authDomain = process.env.NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN;
  const projectId = process.env.NEXT_PUBLIC_FIREBASE_PROJECT_ID;
  const appId = process.env.NEXT_PUBLIC_FIREBASE_APP_ID;
  if (!apiKey || !authDomain || !projectId || !appId) {
    throw new Error(
      "Firebase web config is missing — set NEXT_PUBLIC_FIREBASE_API_KEY / AUTH_DOMAIN / PROJECT_ID / APP_ID in .env.local (see .env.example).",
    );
  }
  return { apiKey, authDomain, projectId, appId };
}

let app: FirebaseApp | undefined;

function firebaseApp(): FirebaseApp {
  if (!app) app = getApps()[0] ?? initializeApp(readConfig());
  return app;
}

let auth: Auth | undefined;

// Lazy: importing this module on the server (a page's generateMetadata,
// say) must not throw when the env var isn't set there.
export function firebaseAuth(): Auth {
  if (!auth) {
    auth = getAuth(firebaseApp());
    // The local demo world (backend/scripts/demo) signs in against the Auth emulator.
    const emulator = process.env.NEXT_PUBLIC_FIREBASE_AUTH_EMULATOR_HOST;
    // Only ever for the offline "demo-" project, so a stray env var in a real
    // deployment can't silently point sign-in at an arbitrary host.
    if (emulator && process.env.NEXT_PUBLIC_FIREBASE_PROJECT_ID?.startsWith("demo-")) {
      connectAuthEmulator(auth, `http://${emulator}`, { disableWarnings: true });
    }
  }
  return auth;
}

export const googleProvider = new GoogleAuthProvider();

/** Fresh ID token for the signed-in user, or null when nobody is signed in. */
export async function currentIdToken(): Promise<string | null> {
  if (typeof window === "undefined") return null;
  const auth = firebaseAuth();
  // onAuthStateChanged has to settle once after a reload before currentUser
  // is trustworthy; authStateReady() is the SDK's promise for exactly that.
  await auth.authStateReady();
  return auth.currentUser ? auth.currentUser.getIdToken() : null;
}
