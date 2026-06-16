# API Backend — contrats

Le backend est un **orchestrateur de sorties** stateless. Il valide chaque
requête (Zod), applique une déduplication, puis délègue au fournisseur (APNs /
SendGrid / Twilio). Sans clés configurées, il répond en **dry-run** (validé,
non envoyé).

Base URL locale : `http://localhost:8787`

## Authentification

Toutes les routes `/v1/*` (sauf `/health`) exigent un en-tête
`Authorization: Bearer <ARIA_API_TOKEN>`. En production, ajouter **App Attest**
pour vérifier que l'appel vient d'une instance légitime de l'app (cf.
`docs/permissions.md`).

## Types partagés

Ces types sont la **source de vérité** ; ils ont un miroir `Codable` côté Swift
(`ios-app/Assistant/Models/SharedContracts.swift`) et Zod côté backend
(`backend/src/schemas/`).

```ts
type InterruptionLevel = "passive" | "active" | "time-sensitive";

type BriefingItemKind =
  | "event" | "reminder" | "birthday" | "conflict" | "deadline" | "forgotten";

interface BriefingItem {
  id: string;
  kind: BriefingItemKind;
  title: string;
  detail?: string;
  date?: string;            // ISO-8601
  priorityScore: number;    // 0…1
}

interface Briefing {
  userId: string;
  date: string;             // ISO-8601 (jour)
  summary: string;
  items: BriefingItem[];
}
```

## Endpoints

### `GET /health`
Sonde de vivacité. `200 { "status": "ok", "dryRun": boolean }`.

### `POST /v1/notifications/push`
Envoie un push APNs.

```json
{
  "userId": "u_123",
  "deviceToken": "apns-hex-token",
  "title": "Attention",
  "body": "Train dans 1 h, aucun trajet planifié.",
  "interruptionLevel": "time-sensitive",
  "dedupeKey": "evt_987:T-60",
  "context": { "eventId": "evt_987", "priorityScore": 0.92 }
}
```
Réponse : `202 { "status": "queued" | "dry-run", "id": "<outboundId>" }`.

### `POST /v1/messages/email/send`
Envoie un e-mail via SendGrid.

```json
{
  "userId": "u_123",
  "to": "paul@example.com",
  "subject": "Anniversaire",
  "text": "Pense à souhaiter l'anniversaire de Paul demain.",
  "dedupeKey": "birthday:paul:2026-06-17"
}
```

### `POST /v1/messages/sms/send`
Envoie un SMS via Twilio (numéro tiers — pas Messages natif).

```json
{
  "userId": "u_123",
  "to": "+33600000000",
  "body": "Rappel : RDV dentiste à 15 h.",
  "dedupeKey": "reminder:dentist:2026-06-16"
}
```

### `POST /v1/briefings/render`
Reçoit un `Briefing` brut et renvoie un texte de résumé normalisé (utile si on
veut centraliser la formulation côté serveur ; le rendu local reste le défaut).

```json
{ "userId": "u_123", "date": "2026-06-16", "summary": "", "items": [ /* … */ ] }
```
Réponse : `200 { "summary": "Tu as 3 événements, 1 deadline ce soir…" }`.

### `POST /v1/webhooks/calendar-refresh`
Webhook d'orchestration (déclenche un recalcul côté device via push silencieux).

## Codes d'erreur

| Code | Sens |
|---|---|
| 400 | Contrat invalide (détail Zod dans `error.issues`) |
| 401 | Token manquant/invalide |
| 409 | `dedupeKey` déjà traité (idempotence) |
| 502 | Échec fournisseur en amont |

## Idempotence & dédup

Chaque envoi porte un `dedupeKey`. Le backend mémorise les clés récentes (TTL
configurable, en mémoire pour le MVP, à remplacer par KV/Redis en prod) et
renvoie `409` si la clé a déjà été traitée. Évite les doublons quand plusieurs
appareils déclenchent la même alerte.

## Sécurité

- Secrets (Twilio/SendGrid/APNs) **uniquement côté serveur**, via variables
  d'environnement. Jamais dans l'app.
- Résidence des données EU disponible : SendGrid EU, Twilio région IE1.
- Pas de log de contenu sensible (corps des messages tronqué/omis).
