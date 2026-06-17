import { config } from "../config.js";
import { log, redact } from "../logger.js";
import type { EmailRequest } from "../schemas.js";
import { newOutboundId, ProviderError, type DeliveryResult } from "./types.js";

const SENDGRID_URL_GLOBAL = "https://api.sendgrid.com/v3/mail/send";
const SENDGRID_URL_EU = "https://api.eu.sendgrid.com/v3/mail/send";

/** Envoie un e-mail via SendGrid. Dry-run si la clé est absente. */
export async function sendEmail(req: EmailRequest): Promise<DeliveryResult> {
  const id = newOutboundId("mail");

  if (!config.sendgrid.configured) {
    log.info("sendgrid.dry-run", { id, to: redact(req.to, 4), subject: redact(req.subject) });
    return { status: "dry-run", id, provider: "sendgrid" };
  }

  const url = config.sendgrid.euResidency ? SENDGRID_URL_EU : SENDGRID_URL_GLOBAL;
  const res = await fetch(url, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${config.sendgrid.apiKey}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      personalizations: [{ to: [{ email: req.to }] }],
      from: { email: config.sendgrid.fromEmail },
      subject: req.subject,
      content: [{ type: "text/plain", value: req.text }],
    }),
  });

  if (!res.ok) {
    log.error("sendgrid.error", { id, status: res.status });
    throw new ProviderError("sendgrid", res.status);
  }
  log.info("sendgrid.send", { id, to: redact(req.to, 4) });
  return { status: "sent", id, provider: "sendgrid" };
}
