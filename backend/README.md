# Aria Backend

Orchestrateur de sorties **stateless** : push APNs, e-mail (SendGrid), SMS
(Twilio). Sans secrets configurés, il tourne en **dry-run** (validation +
journalisation, aucun appel réseau). Voir les contrats dans
[`../docs/backend-api.md`](../docs/backend-api.md).

## Prérequis

Node 20+ (testé sur Node 22).

## Installation & exécution

```bash
npm install
npm test          # tests unitaires (node:test via tsx)
npm run typecheck # vérification TypeScript stricte
npm run dev       # serveur local http://localhost:8787 (watch)
```

## Configuration

Copier `.env.example` en `.env`. Tant qu'un fournisseur n'a pas ses clés, ses
envois restent en dry-run. `ARIA_API_TOKEN` active le bearer auth sur `/v1/*`.

## Routes

| Méthode | Route | Rôle |
|---|---|---|
| GET | `/health` | Sonde + état dry-run |
| POST | `/v1/notifications/push` | Push APNs |
| POST | `/v1/messages/email/send` | E-mail SendGrid |
| POST | `/v1/messages/sms/send` | SMS Twilio |
| POST | `/v1/briefings/render` | Résumé textuel d'un briefing |
| POST | `/v1/webhooks/calendar-refresh` | Orchestration recalcul |

## Architecture

```
src/
  config.ts      # env + détection dry-run par fournisseur
  schemas.ts     # contrats Zod (source de vérité)
  http.ts        # primitives (parse, HttpError, json)
  auth.ts        # bearer token (+ App Attest en prod)
  dedupe.ts      # idempotence in-memory (TTL)
  router.ts      # dispatch pur, testable
  server.ts      # adaptateur node:http
  briefing/render.ts  # génération du résumé (pure, miroir Swift)
  services/      # apns · sendgrid · twilio (dry-run si non configurés)
```

Le **routeur est une fonction pure** `dispatch(ApiRequest) → ApiResponse`,
testée sans ouvrir de socket.

## Prod (TODO de déploiement)

- APNs : générer le JWT ES256 depuis la clé `.p8` et faire la requête HTTP/2.
- Dedupe : remplacer le store mémoire par un KV/Redis (multi-instance).
- Auth : ajouter la vérification App Attest.
- Déployer en serverless (Cloudflare Workers recommandé — cf. `../docs/roadmap.md`).
