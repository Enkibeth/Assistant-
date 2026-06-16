import Foundation

// Miroir Codable des contrats backend (docs/backend-api.md).
// La source de vérité est backend/src/schemas.ts — garder les deux alignés.

enum InterruptionLevel: String, Codable, Sendable {
    case passive
    case active
    case timeSensitive = "time-sensitive"
}

enum BriefingItemKind: String, Codable, Sendable, CaseIterable {
    case event
    case reminder
    case birthday
    case conflict
    case deadline
    case forgotten
}

/// Élément atomique d'un briefing. Partagé app ↔ widget ↔ backend.
struct BriefingItem: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let kind: BriefingItemKind
    let title: String
    var detail: String?
    var date: Date?
    /// Score de priorité 0…1 (utilisé pour le tri et le seuil d'alerte).
    var priorityScore: Double
}

/// Briefing complet pour une journée.
struct Briefing: Codable, Hashable, Sendable {
    let userId: String
    let date: Date
    var summary: String
    var items: [BriefingItem]
}

// MARK: - Requêtes backend

struct PushRequest: Codable, Sendable {
    let userId: String
    let deviceToken: String
    let title: String
    let body: String
    var interruptionLevel: InterruptionLevel = .active
    let dedupeKey: String
}

struct EmailRequest: Codable, Sendable {
    let userId: String
    let to: String
    let subject: String
    let text: String
    let dedupeKey: String
}

struct SmsRequest: Codable, Sendable {
    let userId: String
    let to: String
    let body: String
    let dedupeKey: String
}
