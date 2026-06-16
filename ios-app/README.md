# Aria — App iOS / iPadOS / macOS

App SwiftUI local-first. Le code est fourni *prêt à intégrer dans un projet
Xcode*. Comme un `.xcodeproj` se génère mieux sur Mac, voici la marche à suivre.

## Arborescence

```
Assistant/
  AssistantApp.swift            # @main
  Models/                       # SharedContracts (miroir backend) + DomainModels neutres
  Rules/                        # Moteur de règles PUR (testable sans frameworks)
  Briefing/BriefingGenerator    # Résumé textuel (miroir de render.ts)
  Services/                     # EventKit · Contacts · UserNotifications
  Persistence/                  # SwiftData + CloudKit + App Group (widget)
  Intents/                      # App Intents + Shortcuts (Siri/Spotlight)
  Views/                        # SwiftUI + BriefingViewModel
AssistantWidget/                # Extension WidgetKit
AssistantTests/                 # Swift Testing (couche domaine)
Config/                         # Info.plist, entitlements, privacy manifest (modèles)
```

## Création du projet Xcode (Mac)

1. Xcode 16+ → **New Project → App** (SwiftUI, Swift), nommer la cible `Assistant`.
2. Supprimer les fichiers générés et **glisser** le dossier `Assistant/` dans la cible.
3. Ajouter une cible **Widget Extension** nommée `AssistantWidget`, y mettre
   `AssistantWidget/AssistantWidget.swift`. Cocher le partage des fichiers
   `Persistence/SharedBriefingStore.swift`, `Persistence/JSONCoding.swift`,
   `Models/SharedContracts.swift`, et `Views/BriefingView.swift` (pour
   `symbolName`/`tint`) avec la cible widget.
4. Ajouter une cible **Unit Testing Bundle** `AssistantTests`, y mettre le dossier
   `AssistantTests/`.
5. Reporter les clés de `Config/Info.plist` dans les *Info* de la cible app.
6. Capabilities (onglet *Signing & Capabilities*) :
   - **iCloud** → CloudKit (container `iCloud.com.example.aria`).
   - **Push Notifications** (si backend).
   - **App Groups** → `group.com.example.aria` (app **et** widget).
   - **Background Modes** → Background fetch (pour `BGAppRefreshTask`).
   - **Time Sensitive Notifications**.
7. Ajouter `Config/PrivacyInfo.xcprivacy` à la cible app.

> Remplacer `com.example.aria` par ton bundle id réel partout (Info.plist,
> entitlements, `SharedBriefingStore.appGroupID`, `PersistenceController`).

## Permissions

Voir [`../docs/permissions.md`](../docs/permissions.md). Principe : demande
**just-in-time**, niveau d'accès minimal, gestion propre du refus et de l'accès
limité contacts (iOS 18).

## Tests

Les tests ciblent la **couche domaine pure** (`Rules/`, `BriefingGenerator`,
`ContactsService.nextOccurrence`) via des providers mock — exécutables sans
appareil ni permissions. `Cmd+U` dans Xcode.

## Lien avec le backend

`Models/SharedContracts.swift` est le miroir Codable de
`backend/src/schemas.ts`. `BriefingGenerator.summary` reproduit
`backend/src/briefing/render.ts`. Garder les deux côtés alignés.
