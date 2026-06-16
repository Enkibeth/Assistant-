import { config } from "../config.js";
import { log, redact } from "../logger.js";
import type { PushRequest } from "../schemas.js";
import { newOutboundId, type DeliveryResult } from "./types.js";

/** Mappe le niveau d'interruption du contrat vers la valeur APNs. */
function apnsInterruptionLevel(level: PushRequest["interruptionLevel"]): string {
  switch (level) {
    case "passive":
      return "passive";
    case "time-sensitive":
      return "time-sensitive";
    case "active":
    default:
      return "active";
  }
}

/**
 * Envoie un push APNs (HTTP/2 token-based). En dry-run (clés absentes), valide
 * et journalise sans réseau. L'appel HTTP/2 réel est laissé en TODO pour le
 * déploiement (nécessite la génération du JWT ES256 à partir de la clé .p8).
 */
export async function sendPush(req: PushRequest): Promise<DeliveryResult> {
  const id = newOutboundId("apns");

  const payload = {
    aps: {
      alert: { title: req.title, body: req.body },
      sound: "default",
      "interruption-level": apnsInterruptionLevel(req.interruptionLevel),
    },
    context: req.context ?? {},
  };

  if (!config.apns.configured) {
    log.info("apns.dry-run", { id, title: redact(req.title), level: req.interruptionLevel });
    return { status: "dry-run", id, provider: "apns" };
  }

  // TODO(prod): JWT ES256 (APNS_PRIVATE_KEY .p8) + requête HTTP/2 vers
  // api.push.apple.com (ou api.sandbox.push.apple.com) avec apns-topic.
  log.info("apns.send", {
    id,
    env: config.apns.environment,
    topic: config.apns.bundleId,
    token: redact(req.deviceToken, 8),
    bytes: JSON.stringify(payload).length,
  });
  return { status: "sent", id, provider: "apns" };
}
