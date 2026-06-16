# Permissions, entitlements & confidentialité

Principe : **minimisation et demande *just-in-time***. On ne demande une
permission qu'au moment où sa valeur est évidente pour l'utilisateur, avec une
*purpose string* claire. Modèle = prompts système Apple (pas OAuth) pour les
stores locaux ; OAuth seulement pour des services tiers externes.

## Purpose strings (Info.plist)

| Clé | Quand | Texte proposé (FR) |
|---|---|---|
| `NSCalendarsFullAccessUsageDescription` | Au 1er briefing / création d'événement | « Aria lit votre agenda pour préparer votre briefing et détecter les conflits, et crée des événements à votre demande. » |
| `NSRemindersFullAccessUsageDescription` | À l'activation des relances | « Aria lit et crée des rappels pour vos échéances et relances. » |
| `NSContactsUsageDescription` | À l'activation des anniversaires | « Aria utilise les anniversaires de vos contacts pour vous prévenir à l'avance. » |
| `NSUserNotificationsUsageDescription` | À l'onboarding notifications | « Aria vous envoie le briefing du matin et les alertes importantes. » |

> iOS 18 : `NSContactsUsageDescription` couvre aussi l'**accès limité** (l'utilisateur
> choisit un sous-ensemble de contacts). Gérer le cas « accès partiel » dans l'UI.

## Niveaux d'accès EventKit

Demander le **minimum** :
- Création d'événement seule → `requestWriteOnlyAccessToEvents`.
- Analyse du planning (briefing, conflits) → `requestFullAccessToEvents`.
- Rappels → `requestFullAccessToReminders`.

## Entitlements

| Entitlement | Nécessaire ? | Pour quoi |
|---|---|---|
| `com.apple.developer.icloud-services` (CloudKit) | ✅ | Synchro données app |
| `aps-environment` (Push) | ✅ (si backend) | Alertes cross-device |
| App Groups | ✅ | Partage app ↔ widget |
| `com.apple.developer.usernotifications.time-sensitive` | ✅ | Alertes Time Sensitive |
| `com.apple.developer.usernotifications.critical-alerts` | ❌ | Réservé à des cas vitaux — non justifiable ici |
| `com.apple.developer.devicecheck.appattest` | ⏳ (V1) | Intégrité d'app côté backend |
| `com.apple.security.automation.apple-events` | ❌ (MVP) | Agent macOS uniquement (hors MVP) |

## Niveaux d'interruption notifications

| Niveau | Usage |
|---|---|
| `passive` | Infos non urgentes |
| `active` (défaut) | Briefing standard |
| `time-sensitive` | Vraies alertes (train, deadline imminente) — **plafond réaliste** |
| `critical` | ❌ Non utilisé |

## Secrets & stockage

| Élément | Où | Pourquoi |
|---|---|---|
| Token APNs device | Keychain local (+ mapping backend) | Identifiant sensible |
| Clés Twilio / SendGrid / APNs auth key | **Serveur uniquement** (env vars) | Jamais embarquées dans l'app |
| Préférences / règles / briefings | SwiftData + CloudKit privé | Local-first, isolé par container |
| Secrets locaux sensibles | Keychain + LocalAuthentication | Protection biométrique |

## Conformité

- **Privacy manifest** (`PrivacyInfo.xcprivacy`) : déclarer les *required reason
  APIs* utilisées, aucune collecte de tracking.
- Privacy policy claire (conservation, suppression, export).
- Pas de SDK tiers superflu (chaque SDK = dette conformité héritée).
- Pas d'analytics invasive. Privacy by design (aligné CNIL).

## Anti-patterns (interdits)

- API privées, lecture de bases SQLite système.
- Détournement des push pour du marketing.
- Demande anticipée de permissions non exploitées.
- Sur-promesse d'un « assistant total » qui lirait Mail/Messages/Notes natifs.
