import Foundation
import SwiftData

/// Construit le `ModelContainer` SwiftData, synchronisé sur la base privée
/// CloudKit en production. En tests/preview, conteneur en mémoire.
enum PersistenceController {
    static let schema = Schema([
        UserPreferences.self,
        BriefingRecord.self,
        RuleConfig.self,
        OutboundLog.self,
    ])

    /// Conteneur de production (CloudKit privé automatique).
    static func makeContainer() -> ModelContainer {
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .automatic
        )
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Échec d'initialisation du ModelContainer : \(error)")
        }
    }

    /// Conteneur volatil pour previews et tests.
    static func makeInMemoryContainer() -> ModelContainer {
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        // swiftlint:disable:next force_try
        return try! ModelContainer(for: schema, configurations: [config])
    }
}
