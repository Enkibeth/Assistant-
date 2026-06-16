import { createServer, type IncomingMessage, type ServerResponse } from "node:http";
import { type ApiRequest } from "./http.js";
import { log } from "./logger.js";
import { dispatch } from "./router.js";

async function readBody(req: IncomingMessage): Promise<unknown> {
  const chunks: Buffer[] = [];
  for await (const chunk of req) chunks.push(chunk as Buffer);
  if (chunks.length === 0) return undefined;
  const raw = Buffer.concat(chunks).toString("utf8");
  if (raw.trim().length === 0) return undefined;
  try {
    return JSON.parse(raw);
  } catch {
    return undefined;
  }
}

function lowerHeaders(req: IncomingMessage): Record<string, string | undefined> {
  const out: Record<string, string | undefined> = {};
  for (const [k, v] of Object.entries(req.headers)) {
    out[k.toLowerCase()] = Array.isArray(v) ? v.join(",") : v;
  }
  return out;
}

export function createApp() {
  return createServer((req: IncomingMessage, res: ServerResponse) => {
    void handle(req, res);
  });
}

async function handle(req: IncomingMessage, res: ServerResponse): Promise<void> {
  const path = (req.url ?? "/").split("?")[0] ?? "/";
  const apiReq: ApiRequest = {
    method: req.method ?? "GET",
    path,
    headers: lowerHeaders(req),
    body: await readBody(req),
  };

  const start = Date.now();
  const apiRes = await dispatch(apiReq);
  res.writeHead(apiRes.status, { "Content-Type": "application/json" });
  res.end(JSON.stringify(apiRes.body));
  log.info("request", {
    method: apiReq.method,
    path: apiReq.path,
    status: apiRes.status,
    ms: Date.now() - start,
  });
}
