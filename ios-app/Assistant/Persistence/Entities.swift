import Foundation
import SwiftData

// Entités SwiftData (voir docs/data-model.md). Tous les attributs ont une valeur
// par défaut → contrainte du pont CloudKit. On ne stocke QUE les données propres
// de l'app, jamais une copie brute du calendrier ou des contacts.

@Model
final class UserPreferences {
    var id: UUID = UUID()
    var briefingHour: Int = 7
    var briefingMinute: Int = 0
    var birthdayLeadDays: [Int] = [30, 7, 1]
    var enableTimeSensitive: Bool = false
    var enabledRuleIDs: [String] = ["event", "conflict", "deadline", "forgotten", "birthday"]
    var updatedAt: Date = Date()

    init() {}
}

@Model
final class BriefingRecord {
    var id: UUID = UUID()
    var date: Date = Date()
    var summary: String = ""
    var itemCount: Int = 0
    var payloadJSON: String = "[]"
    var generatedAt: Date = Date()

    init(date: Date, summary: String, items: [BriefingItem]) {
        self.date = date
        self.summary = summary
        self.itemCount = items.count
        self.generatedAt = Date()
        self.payloadJSON = (try? JSONCoding.encodeToString(items)) ?? "[]"
    }

    var items: [BriefingItem] {
        (try? JSONCoding.decode([BriefingItem].self, from: payloadJSON)) ?? []
    }
}

@Model
final class RuleConfig {
    var id: UUID = UUID()
    var ruleID: String = ""
    var enabled: Bool = true
    var priorityWeight: Double = 1.0
    var paramsJSON: String = "{}"

    init(ruleID: String, enabled: Bool = true, priorityWeight: Double = 1.0) {
        self.ruleID = ruleID
        self.enabled = enabled
        self.priorityWeight = priorityWeight
    }
}

@Model
final class OutboundLog {
    var id: UUID = UUID()
    var kind: String = ""        // push · email · sms · local-notification
    var status: String = ""      // queued · sent · failed · dry-run
    var dedupeKey: String = ""
    var createdAt: Date = Date()
    var detail: String?

    init(kind: String, status: String, dedupeKey: String, detail: String? = nil) {
        self.kind = kind
        self.status = status
        self.dedupeKey = dedupeKey
        self.detail = detail
        self.createdAt = Date()
    }
}
