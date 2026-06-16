# Aria — Assistante personnelle Apple-native (local-first)

Aria est une assistante personnelle pensée pour l'écosystème Apple. Elle agrège
**calendrier, rappels, contacts/anniversaires**, en déduit des **briefings
quotidiens** et des **rappels proactifs** (J-30 / J-7 / J-1, conflits,
oublis), et les pousse via **notifications, widgets et App Intents**. Un
**backend serverless léger** orchestre uniquement les sorties que l'appareil ne
peut pas faire seul de façon fiable : push APNs, e-mail (SendGrid) et SMS
(Twilio).

> Philosophie : **local-first**. Les données sensibles restent sur l'appareil
> (EventKit, Contacts) et dans la base privée CloudKit de l'utilisateur. Le
> backend est un *orchestrateur de sorties*, pas le cerveau du produit.

## Structure du monorepo

```
.
├── docs/                  # Source de vérité : architecture, data-model, API, permissions, roadmap
├── ios-app/               # App SwiftUI (iOS/iPadOS/macOS) + widget — à ouvrir dans Xcode
│   ├── Assistant/         # Code de l'app (Services, Rules, Briefing, Intents, Views, Persistence)
│   └── AssistantWidget/   # Extension WidgetKit
└── backend/               # API TypeScript serverless (APNs / SendGrid / Twilio / webhooks)
```

## Périmètre MVP

Volontairement strict (cf. `docs/roadmap.md`) :

- Lecture calendrier + rappels (EventKit) et contacts/anniversaires (Contacts)
- Moteur de règles local (anniversaires, conflits, échéances, oublis)
- Briefing quotidien (notification locale 7h + widget)
- Création d'événements via App Intents / Shortcuts / Siri
- Synchro des données *propres* de l'app via SwiftData + CloudKit

Hors MVP : lecture d'Apple Mail/Messages/Notes natifs (non exposés par les API
publiques iOS), envoi SMS silencieux, agent macOS d'automatisation. Voir la
matrice de faisabilité dans `docs/architecture.md`.

## Démarrage rapide

### Backend (Node 20+)

```bash
cd backend
npm install
npm test          # tests unitaires (moteur d'orchestration, validation des contrats)
npm run dev       # serveur local sur http://localhost:8787
```

En l'absence de clés (`.env`), le backend tourne en **mode dry-run** : il valide
les contrats et journalise les sorties sans appeler APNs/SendGrid/Twilio.

### App iOS

Ouvrir `ios-app/` dans Xcode 16+ (voir `ios-app/README.md` pour générer le
projet et configurer les capabilities CloudKit / Push / les *purpose strings*).

## Statut

Première fondation du monorepo. Voir `docs/roadmap.md` pour le backlog détaillé.
