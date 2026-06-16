import assert from "node:assert/strict";
import { test } from "node:test";
import { dispatch } from "../src/router.js";
import type { ApiRequest } from "../src/http.js";

function req(method: string, path: string, body?: unknown): ApiRequest {
  return { method, path, headers: {}, body };
}

// dedupeKeys uniques par test pour éviter les collisions sur le store partagé.
const uniq = () => `k_${Math.random().toString(36).slice(2)}`;

test("GET /health renvoie ok + dryRun", async () => {
  const res = await dispatch(req("GET", "/health"));
  assert.equal(res.status, 200);
  assert.deepEqual(res.body, { status: "ok", dryRun: true });
});

test("route inconnue → 404", async () => {
  const res = await dispatch(req("GET", "/nope"));
  assert.equal(res.status, 404);
});

test("push valide → 202 dry-run", async () => {
  const res = await dispatch(
    req("POST", "/v1/notifications/push", {
      userId: "u_1",
      deviceToken: "tok",
      title: "Salut",
      body: "Corps",
      dedupeKey: uniq(),
    }),
  );
  assert.equal(res.status, 202);
  assert.equal((res.body as { status: string }).status, "dry-run");
});

test("push invalide → 400 avec issues", async () => {
  const res = await dispatch(req("POST", "/v1/notifications/push", { userId: "u_1" }));
  assert.equal(res.status, 400);
  assert.equal((res.body as { error: string }).error, "validation_error");
});

test("même dedupeKey → 409 au second appel", async () => {
  const key = uniq();
  const payload = {
    userId: "u_1",
    deviceToken: "tok",
    title: "T",
    body: "B",
    dedupeKey: key,
  };
  const first = await dispatch(req("POST", "/v1/notifications/push", payload));
  const second = await dispatch(req("POST", "/v1/notifications/push", payload));
  assert.equal(first.status, 202);
  assert.equal(second.status, 409);
});

test("SMS avec numéro non E.164 → 400", async () => {
  const res = await dispatch(
    req("POST", "/v1/messages/sms/send", {
      userId: "u_1",
      to: "0600000000",
      body: "Rappel",
      dedupeKey: uniq(),
    }),
  );
  assert.equal(res.status, 400);
});

test("briefings/render renvoie un résumé", async () => {
  const res = await dispatch(
    req("POST", "/v1/briefings/render", {
      userId: "u_1",
      date: "2026-06-16",
      summary: "",
      items: [{ id: "1", kind: "event", title: "Réunion", priorityScore: 0.5 }],
    }),
  );
  assert.equal(res.status, 200);
  assert.match((res.body as { summary: string }).summary, /événement/);
});
