import { config } from "../config.js";
import { log, redact } from "../logger.js";
import type { SmsRequest } from "../schemas.js";
import { newOutboundId, ProviderError, type DeliveryResult } from "./types.js";

function twilioBaseUrl(): string {
  const region = config.twilio.region;
  const host = region ? `api.${region}.twilio.com` : "api.twilio.com";
  return `https://${host}/2010-04-01/Accounts/${config.twilio.accountSid}/Messages.json`;
}

/** Envoie un SMS via Twilio (numéro tiers — pas Messages natif). Dry-run sinon. */
export async function sendSms(req: SmsRequest): Promise<DeliveryResult> {
  const id = newOutboundId("sms");

  if (!config.twilio.configured) {
    log.info("twilio.dry-run", { id, to: redact(req.to, 4), body: redact(req.body) });
    return { status: "dry-run", id, provider: "twilio" };
  }

  const auth = Buffer.from(`${config.twilio.accountSid}:${config.twilio.authToken}`).toString("base64");
  const params = new URLSearchParams({
    To: req.to,
    From: config.twilio.fromNumber!,
    Body: req.body,
  });

  const res = await fetch(twilioBaseUrl(), {
    method: "POST",
    headers: {
      Authorization: `Basic ${auth}`,
      "Content-Type": "application/x-www-form-urlencoded",
    },
    body: params.toString(),
  });

  if (!res.ok) {
    log.error("twilio.error", { id, status: res.status });
    throw new ProviderError("twilio", res.status);
  }
  log.info("twilio.send", { id, to: redact(req.to, 4) });
  return { status: "sent", id, provider: "twilio" };
}
