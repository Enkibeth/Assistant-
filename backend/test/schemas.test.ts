import assert from "node:assert/strict";
import { test } from "node:test";
import { emailRequest, pushRequest, smsRequest } from "../src/schemas.js";

test("pushRequest applique le niveau d'interruption par défaut", () => {
  const parsed = pushRequest.parse({
    userId: "u",
    deviceToken: "t",
    title: "x",
    body: "y",
    dedupeKey: "k",
  });
  assert.equal(parsed.interruptionLevel, "active");
});

test("emailRequest rejette une adresse invalide", () => {
  const r = emailRequest.safeParse({
    userId: "u",
    to: "pas-un-email",
    subject: "s",
    text: "t",
    dedupeKey: "k",
  });
  assert.equal(r.success, false);
});

test("smsRequest accepte un numéro E.164", () => {
  const r = smsRequest.safeParse({
    userId: "u",
    to: "+33600000000",
    body: "b",
    dedupeKey: "k",
  });
  assert.equal(r.success, true);
});
