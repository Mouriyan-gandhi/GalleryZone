// One-shot cleanup for the NFC rollout (NFC_IMPLEMENTATION.md §3, §9.6).
//
// Before real chips, the artist dialog "simulated" a tag and stored a made-up
// string such as "NFC-abc12345" in artworks.nfcTagId. Those are not chips, and
// the field is gone: this script removes it from every artwork and gives each
// one the new, unlinked state (nfcLinkedAt and nfcLockedAt null).
//
//   node --experimental-strip-types scripts/migrate-legacy-nfc-ids.ts            # dry run: lists what it would change
//   node --experimental-strip-types scripts/migrate-legacy-nfc-ids.ts --apply    # does it
//
// Run once per environment, before the apps that read the new fields go out.
// Safe to run again: an artwork that is already migrated is left alone. It never
// touches an artwork that has a real link (nfcLinkedAt set) apart from deleting
// the retired field, and it writes one summary entry to the audit log.
//
// Reads FIREBASE_PROJECT_ID and the service-account credential the same way the
// API does, from ../.env at the repo root or apps/api/.env. Point it at staging
// first.

import { readFileSync, existsSync } from "node:fs";
import { resolve, dirname } from "node:path";
import { fileURLToPath } from "node:url";
import { FieldValue } from "firebase-admin/firestore";
import { createDb, Collections } from "../packages/db/src/index.ts";

const root = resolve(dirname(fileURLToPath(import.meta.url)), "..");

function loadDotEnv(path: string): void {
  if (!existsSync(path)) return;
  for (const line of readFileSync(path, "utf8").split(/\r?\n/)) {
    const m = /^([A-Z_]+)=(.*)$/.exec(line.trim());
    if (m && process.env[m[1]!] === undefined) process.env[m[1]!] = m[2]!.replace(/^"|"$/g, "");
  }
}
loadDotEnv(resolve(root, "..", ".env"));
loadDotEnv(resolve(root, "apps", "api", ".env"));

const apply = process.argv.includes("--apply");
const projectId = process.env.FIREBASE_PROJECT_ID;
if (!projectId) {
  console.error("FIREBASE_PROJECT_ID must be set");
  process.exit(1);
}

const { db } = createDb(projectId);
console.log(`${apply ? "APPLYING to" : "dry run against"} project ${projectId}`);

const snap = await db.collection(Collections.artworks).select("nfcTagId", "nfcLinkedAt", "nfcLockedAt", "title").get();

let cleared = 0;
let initialised = 0;
let untouched = 0;
const writes: { id: string; patch: Record<string, unknown> }[] = [];

for (const doc of snap.docs) {
  const data = doc.data() as { nfcTagId?: unknown; nfcLinkedAt?: unknown; nfcLockedAt?: unknown; title?: string };
  const patch: Record<string, unknown> = {};

  if ("nfcTagId" in data) {
    if (data.nfcTagId !== null && data.nfcTagId !== undefined && data.nfcTagId !== "") {
      console.log(`clearing legacy nfcTagId=${String(data.nfcTagId)} on ${doc.id} (${data.title ?? "untitled"})`);
      cleared += 1;
    }
    patch.nfcTagId = FieldValue.delete();
  }
  if (data.nfcLinkedAt === undefined) patch.nfcLinkedAt = null;
  if (data.nfcLockedAt === undefined) patch.nfcLockedAt = null;

  if (Object.keys(patch).length === 0) {
    untouched += 1;
    continue;
  }
  if (data.nfcLinkedAt === undefined) initialised += 1;
  writes.push({ id: doc.id, patch });
}

console.log(`${snap.size} artworks: ${cleared} with a legacy tag id, ${initialised} to give the new fields, ${untouched} already migrated`);

if (!apply) {
  console.log("dry run only: nothing was written. Re-run with --apply to migrate.");
  process.exit(0);
}

// Firestore batches hold 500 writes; stay well under.
for (let i = 0; i < writes.length; i += 400) {
  const batch = db.batch();
  for (const { id, patch } of writes.slice(i, i + 400)) batch.update(db.collection(Collections.artworks).doc(id), patch);
  await batch.commit();
  console.log(`  wrote ${Math.min(i + 400, writes.length)} / ${writes.length}`);
}

await db.collection(Collections.auditLog).add({
  adminId: "system",
  action: "nfc.legacy_tags_cleared",
  entityType: "artwork",
  entityId: "*",
  entityLabel: null,
  detail: { artworksChanged: writes.length, legacyTagIdsCleared: cleared },
  createdAt: FieldValue.serverTimestamp(),
});
console.log(`done: ${writes.length} artworks migrated, ${cleared} legacy tag ids cleared.`);
