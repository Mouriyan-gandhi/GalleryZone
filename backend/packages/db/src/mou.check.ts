// Run: node --experimental-strip-types packages/db/src/mou.check.ts
// The MOU's blanks are filled from the profile by mouPartyDetails — the same
// function for the preview and the signed record. This pins what goes in each
// blank and what counts as missing.

import assert from "node:assert/strict";
import { describeMissingMouDetails, mouPartyDetails } from "./mou.ts";

const complete = {
  fullName: " Meera Kulkarni ",
  email: "meera@example.in",
  phone: "9876543210",
  pan: "ABCDE1234F",
  aadhaarMasked: null,
  gstin: "36ABCDE1234F1Z5",
  companyName: "Kulkarni Fine Art",
  pickupLine1: "12 Banjara Hills Road",
  pickupLine2: null,
  pickupCity: "Hyderabad",
  pickupState: "Telangana",
  pickupPincode: "500034",
};

// Artist: every blank filled, business/GST are not artist fields.
const artist = mouPartyDetails(complete, "artist");
assert.deepEqual(artist.missing, []);
assert.equal(artist.details.name, "Meera Kulkarni");
assert.equal(artist.details.address, "12 Banjara Hills Road, Hyderabad, Telangana 500034");
assert.equal(artist.details.mobile, "+91 98765 43210");
assert.equal(artist.details.governmentId, "PAN ABCDE1234F");
assert.equal(artist.details.businessName, null);
assert.equal(artist.details.gstNo, null);

// Aggregator: business name and GST are theirs; no government ID blank.
const aggregator = mouPartyDetails(complete, "aggregator");
assert.deepEqual(aggregator.missing, []);
assert.equal(aggregator.details.businessName, "Kulkarni Fine Art");
assert.equal(aggregator.details.gstNo, "36ABCDE1234F1Z5");
assert.equal(aggregator.details.governmentId, null);

// No PAN: a masked Aadhaar identifies the artist; with neither, it is missing.
assert.equal(mouPartyDetails({ ...complete, pan: null, aadhaarMasked: "XXXX XXXX 4821" }, "artist").details.governmentId, "Aadhaar XXXX XXXX 4821");
assert.deepEqual(mouPartyDetails({ ...complete, pan: null }, "artist").missing, ["governmentId"]);

// An address without a pincode is not an address; blanks count as missing.
const partial = mouPartyDetails({ ...complete, pickupPincode: " ", phone: null, companyName: null }, "aggregator");
assert.deepEqual(partial.missing, ["businessName", "address", "mobile"]);
assert.equal(partial.details.address, null);

// GST is optional for an aggregator — an unregistered one can still sign.
assert.deepEqual(mouPartyDetails({ ...complete, gstin: null }, "aggregator").missing, []);

assert.equal(describeMissingMouDetails(["mobile"]), "Add your mobile number to your profile before signing");
assert.equal(
  describeMissingMouDetails(["businessName", "address", "mobile"]),
  "Add your business name, address (line 1, city, state and pincode) and mobile number to your profile before signing",
);

console.log("packages/db/mou.ts: MOU blanks filled from the profile, required ones reported, Aadhaar only masked");
