import assert from "node:assert/strict";
import { test } from "node:test";
import { DedupeStore } from "../src/dedupe.js";

test("claim retourne true la première fois, false ensuite", () => {
  const store = new DedupeStore(1000);
  assert.equal(store.claim("k1"), true);
  assert.equal(store.claim("k1"), false);
  assert.equal(store.claim("k2"), true);
});

test("la clé expire après le TTL", () => {
  const store = new DedupeStore(1000);
  assert.equal(store.claim("k", 0), true);
  assert.equal(store.claim("k", 500), false);
  assert.equal(store.claim("k", 1500), true); // expirée → réclamable
});

test("le sweep purge les entrées expirées", () => {
  const store = new DedupeStore(100);
  store.claim("a", 0);
  store.claim("b", 0);
  assert.equal(store.size, 2);
  store.claim("c", 1000); // déclenche le sweep
  assert.equal(store.size, 1);
});
