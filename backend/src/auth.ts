import { config } from "./config.js";
import { type ApiRequest, HttpError } from "./http.js";

/**
 * Vérifie le bearer token sur les routes protégées. Si ARIA_API_TOKEN n'est pas
 * configuré, l'auth est désactivée (dev local). En prod, compléter avec App
 * Attest (cf. docs/permissions.md).
 */
export function requireAuth(req: ApiRequest): void {
  if (!config.apiToken) return; // auth désactivée en dev
  const header = req.headers["authorization"] ?? req.headers["Authorization"];
  const expected = `Bearer ${config.apiToken}`;
  if (header !== expected) {
    throw new HttpError(401, "unauthorized");
  }
}
