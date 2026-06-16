# Architecture

Aria suit une architecture **hybride local-first**. Tout ce qui peut être
résolu sur l'appareil l'est (lecture calendrier/rappels/contacts, calcul des
conflits, scoring de priorité, génération du briefing, UI widget + App Intents).
Le backend ne fait que les **sorties distantes** (push APNs, e-mail, SMS) et un
peu d'orchestration cross-device.

## Schéma cible

```mermaid
flowchart LR
    A[App SwiftUI<br/>iPhone / iPad / Mac] --> B[Services locaux<br/>EventKit · Contacts · Notifications]
    B --> C[Moteur de règles local<br/>anniversaire · conflit · échéance · oubli]
    C --> D[SwiftData]
    D <--> E[CloudKit private DB]
    C --> F[WidgetKit · App Intents · Shortcuts]
    E <--> G[Backend léger]
    G --> H[APNs]
    G --> I[SendGrid]
    G --> J[Twilio]
```

## Flux du briefing quotidien

```mermaid
flowchart TD
    A[BGTask / ouverture app] --> B[Lecture calendrier · rappels · contacts autorisés]
    B --> C[Normalisation locale]
    C --> D[Moteur de règles]
    D --> E[Résumé du jour]
    E --> F[Widget]
    E --> G[Notification locale 7h]
    D --> H{Sortie distante ?}
    H -- non --> F
    H -- oui --> I[Backend]
    I --> J[Push APNs / e-mail / SMS]
```

## Couches

| Couche | Responsabilité | Technologies |
|---|---|---|
| Présentation | UI, widget, raccourcis | SwiftUI, WidgetKit, App Intents |
| Domaine | Règles, scoring, briefing | Swift pur (testable, sans dépendance framework) |
| Données système | Calendrier, rappels, contacts | EventKit, Contacts |
| Persistance | État, préférences, règles, logs légers | SwiftData + CloudKit (private DB) |
| Backend | Sorties distantes + orchestration | TypeScript serverless |

La **couche domaine est volontairement découplée** d'EventKit/Contacts via des
protocoles (`EventProviding`, `ContactProviding`) pour être testable sans
appareil. Voir `ios-app/Assistant/Rules/`.

## Matrice de faisabilité (résumé)

| Fonction | Faisable | Voie | Limite |
|---|---|---|---|
| Lire calendriers | ✅ | EventKit (`requestFullAccessToEvents`) | Consentement + purpose string |
| Lire/écrire rappels | ✅ | EventKit reminders | Idem |
| Contacts + anniversaires | ✅ | Contacts / ContactsUI | Accès limité possible (iOS 18) |
| Rappels J-30/J-7 | ✅ | Règles locales + notifications + APNs | Background iOS ≠ cron exact |
| Briefing quotidien | ✅ | Widget + notification locale | Qualité = logique métier |
| Créer / déplacer événements | ✅ | EventKit + App Intents | — |
| Rédiger e-mail | ✅ | `MFMailComposeViewController` (interactif) ou backend SMTP | Envoi auto = backend |
| Lire Apple Mail natif | ⚠️ | MailKit (macOS) / IMAP | Pas d'API iOS générale |
| Envoyer SMS sans interaction | ❌→⚠️ | Pas via Messages ; Twilio (numéro tiers) | — |
| Lire historique Messages | ❌ | À éviter | Non exposé iOS public |
| Automatiser Messages sur Mac | ⚠️ | Apple Events / AppleScript (agent macOS) | Sandbox, friction App Store |
| Accès direct Apple Notes | ❌ | Notes internes à l'app ou Shortcuts | Pas de NotesKit public |

**Règle d'or** : aucune API privée, aucune lecture de SQLite système, aucun
détournement de notifications. On reste dans le périmètre des API publiques et
du sandbox.

## Décisions d'architecture (ADR courts)

- **ADR-001 — SwiftData plutôt que Core Data brut.** Moins de boilerplate, pont
  CloudKit natif, suffisant pour des modèles simples. Repli Core Data possible
  si besoin de migrations fines.
- **ADR-002 — Backend stateless en dry-run par défaut.** Pas de secret = pas
  d'appel réseau réel. Facilite tests et CI sans fuite de clés.
- **ADR-003 — Contrats JSON validés par Zod côté backend** et structures
  `Codable` miroir côté Swift (`docs/backend-api.md`).
- **ADR-004 — Hébergement de départ : CloudKit + une fonction serverless**
  (Cloudflare Workers ou équivalent). Voir `docs/roadmap.md` §coûts.
