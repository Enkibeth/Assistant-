/**
 * Routeur pur : (ApiRequest) -> Promise<ApiResponse>. Aucune dépendance au
 * transport, ce qui le rend directement testable.
 */
import { requireAuth } from "./auth.js";
import { isGlobalDryRun } from "./config.js";
import { renderSummary, sortByPriority } from "./briefing/render.js";
import { dedupe } from "./dedupe.js";
import { type ApiRequest, type ApiResponse, HttpError, json, parse } from "./http.js";
import { log } from "./logger.js";
import {
  briefing as briefingSchema,
  emailRequest,
  pushRequest,
  smsRequest,
} from "./schemas.js";
import { sendPush } from "./services/apns.js";
import { sendEmail, ProviderError } from "./services/sendgrid.js";
import { sendSms } from "./services/twilio.js";

/** Garde d'idempotence : lève 409 si la clé a déjà été traitée. */
function claimOrConflict(dedupeKey: string): void {
  if (!dedupe.claim(dedupeKey)) {
    throw new HttpError(409, "duplicate", { dedupeKey });
  }
}

export async function dispatch(req: ApiRequest): Promise<ApiResponse> {
  const route = `${req.method} ${req.path}`;

  try {
    switch (route) {
      case "GET /health":
        return json(200, { status: "ok", dryRun: isGlobalDryRun() });

      case "POST /v1/notifications/push": {
        requireAuth(req);
        const data = parse(pushRequest, req.body);
        claimOrConflict(data.dedupeKey);
        const result = await sendPush(data);
        return json(202, { status: result.status, id: result.id });
      }

      case "POST /v1/messages/email/send": {
        requireAuth(req);
        const data = parse(emailRequest, req.body);
        claimOrConflict(data.dedupeKey);
        const result = await sendEmail(data);
        return json(202, { status: result.status, id: result.id });
      }

      case "POST /v1/messages/sms/send": {
        requireAuth(req);
        const data = parse(smsRequest, req.body);
        claimOrConflict(data.dedupeKey);
        const result = await sendSms(data);
        return json(202, { status: result.status, id: result.id });
      }

      case "POST /v1/briefings/render": {
        requireAuth(req);
        const data = parse(briefingSchema, req.body);
        const summary = renderSummary({ ...data, items: sortByPriority(data.items) });
        return json(200, { summary });
      }

      case "POST /v1/webhooks/calendar-refresh": {
        requireAuth(req);
        // Orchestration : déclencherait un push silencieux de recalcul.
        log.info("webhook.calendar-refresh");
        return json(202, { status: "accepted" });
      }

      default:
        return json(404, { error: "not_found", route });
    }
  } catch (err) {
    return toErrorResponse(err);
  }
}

function toErrorResponse(err: unknown): ApiResponse {
  if (err instanceof HttpError) {
    return json(err.status, { error: err.message, ...(err.extra ? { detail: err.extra } : {}) });
  }
  if (err instanceof ProviderError) {
    return json(502, { error: "provider_error", provider: err.provider, upstream: err.upstreamStatus });
  }
  log.error("unhandled", { message: err instanceof Error ? err.message : String(err) });
  return json(500, { error: "internal_error" });
}
