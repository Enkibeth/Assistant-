# Roadmap & backlog

Estimations d'ingénierie (solo, Swift connu) — indicatives.

## Phases

| Phase | Contenu | Effort |
|---|---|---|
| **MVP** | Calendrier, rappels, contacts, briefing, notifications, widget, App Intents | 6–10 sem. |
| **V1** | Backend APNs + e-mail + scoring fin + onboarding permissions | +4–8 sem. |
| **V2** | Agent macOS, automation avancée, rules engine riche, audit logs | +6–12 sem. |
| **V3** | Foundation Models (résumés, tool calling), éval qualité | dépend OS/matériel |

## Backlog MVP — semaine par semaine

### S1 — Fondations
- [x] Monorepo, docs/specs, contrats partagés.
- [ ] Projet Xcode (targets app + widget + tests), capabilities.
- [ ] Couche domaine `Rules/` testable (protocoles `EventProviding`, `ContactProviding`).

### S2 — Accès données système
- [ ] `CalendarService` (EventKit) : autorisation + lecture 7 jours.
- [ ] `RemindersService` : lecture/écriture.
- [ ] `ContactsService` : anniversaires + accès limité iOS 18.
- [ ] Tests du moteur de règles avec fournisseurs *mock*.

### S3 — Moteur de règles & briefing
- [ ] Règles : `birthday` (J-30/J-7/J-1), `conflict`, `deadline`, `forgotten`.
- [ ] Scoring de priorité + génération du `Briefing`.
- [ ] `BriefingRecord` persisté (SwiftData).

### S4 — Notifications & widget
- [ ] Notification locale 7h (Time Sensitive optionnel).
- [ ] Widget (small/medium) alimenté par le dernier `BriefingRecord` via App Group.
- [ ] `BGAppRefreshTask` pour pré-calcul.

### S5 — Actions & Siri
- [ ] App Intents : « Prépare ma journée », « Ajoute un créneau », « Mes alertes ».
- [ ] `AppShortcutsProvider` + phrases.
- [ ] Création d'événement (write-only d'abord).

### S6 — CloudKit & onboarding
- [ ] Pont SwiftData ↔ CloudKit (private DB).
- [ ] Onboarding permissions just-in-time + écran « accès partiel ».
- [ ] Privacy manifest + privacy policy.

### S7–S8 — Finitions / review
- [ ] États vides, erreurs de permission, accessibilité, localisation FR/EN.
- [ ] Plan de test App Store Review (cf. ci-dessous).
- [ ] Beta TestFlight.

## V1 — Backend
- [ ] Déploiement serverless (Cloudflare Workers) du backend `backend/`.
- [ ] Enregistrement device token + mapping user.
- [ ] App Attest sur routes sensibles.
- [ ] Scoring affiné (apprentissage des préférences, fenêtres horaires).

## Coûts (prix publics observés, ~2026)

| Option | Coût d'entrée | Quand |
|---|---|---|
| CloudKit + ~pas de backend | ~0 infra app | Démarrage Apple-centric |
| Cloudflare Workers | dès 5 $/mois | Webhooks, APNs relay |
| AWS Lambda | 0,20 $ / M requêtes (+ compute) | Écosystème AWS |
| Vercel Pro | 20 $/mois | Console web admin |
| Supabase Pro | 25 $/mois | SQL/Auth/Edge Functions |

Le vrai coût est le **temps de dev** (règles, tests permissions, UX, conformité),
pas l'infra.

## Risques & parades

| Risque | Parade |
|---|---|
| Concevoir autour d'accès non publics (Notes/Mail/Messages) | MVP centré EventKit + Contacts + notifications |
| Trop de permissions trop tôt | Demande just-in-time |
| Secrets dans l'app | Tout côté serveur |
| Fiabilité sur background iOS | Règles locales + pré-calcul + APNs |
| Sur-promesse « assistant total » | Positionner clairement les limites |

## Plan de test App Store Review

1. Chaque permission demandée au moment de sa valeur, refus géré proprement.
2. App fonctionnelle même si l'utilisateur refuse contacts/notifications.
3. Aucune API privée (vérifié), privacy manifest complet.
4. Pas de promesse trompeuse dans la description (pas de « lit vos mails »).
5. Démo claire d'au moins une action App Intents pour la review.
