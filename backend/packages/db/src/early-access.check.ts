// Run: node --experimental-strip-types packages/db/src/early-access.check.ts
// Six months free for an artist, a year if their email is on the survey list,
// nothing for any other role, and the list takes emails in any case, once.

import assert from "node:assert/strict";
import type { Firestore } from "firebase-admin/firestore";
import { addSurveyRespondents, freeAccessFor } from "./early-access.ts";

// Just enough Firestore: a set of listed document ids.
const listed = new Set<string>();
const db = {
  collection: () => ({ doc: (id: string) => ({ id, get: async () => ({ exists: listed.has(id) }) }) }),
  getAll: async (...refs: { id: string }[]) => refs.map((ref) => ({ exists: listed.has(ref.id) })),
  batch: () => {
    const pending: string[] = [];
    return { set: (ref: { id: string }) => pending.push(ref.id), commit: async () => pending.forEach((id) => listed.add(id)) };
  },
} as unknown as Firestore;

const joinedAt = new Date("2026-10-01T09:30:00.000Z");
const meera = { email: "Meera@Example.in", role: "artist", joinedAt };

const six = await freeAccessFor(db, meera, new Date("2026-12-01T00:00:00.000Z"));
assert.deepEqual(six, { until: "2027-04-01T09:30:00.000Z", months: 6, surveyRespondent: false, active: true });

assert.deepEqual(await addSurveyRespondents(db, ["meera@example.in", " MEERA@example.in ", "ravi@example.in"]), { added: 2, alreadyListed: 0 }, "duplicates in any case count once");
assert.deepEqual(await addSurveyRespondents(db, ["Ravi@Example.in"]), { added: 0, alreadyListed: 1 }, "adding again changes nothing");

const year = await freeAccessFor(db, meera, new Date("2026-12-01T00:00:00.000Z"));
assert.deepEqual(year, { until: "2027-10-01T09:30:00.000Z", months: 12, surveyRespondent: true, active: true }, "an account that already existed is upgraded the moment its email is listed");

assert.equal((await freeAccessFor(db, meera, new Date("2027-10-01T09:30:00.000Z")))?.active, false, "free access ends at the end date");
assert.equal(await freeAccessFor(db, { ...meera, role: "aggregator" }), null, "only artists have a free-access period");
assert.equal(await freeAccessFor(db, { ...meera, role: "customer" }), null);

console.log("packages/db/early-access.ts: 6 months, a year for survey respondents, artists only");
