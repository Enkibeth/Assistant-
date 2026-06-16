import Foundation

// Modèles de domaine *framework-agnostiques* : aucune dépendance à EventKit ou
// Contacts. Les services convertissent les types Apple vers ces structures, ce
// qui rend le moteur de règles testable sans appareil ni permissions.

/// Événement de calendrier normalisé.
struct DomainEvent: Identifiable, Hashable, Sendable {
    let id: String
    let title: String
    let start: Date
    let end: Date
    let isAllDay: Bool
    var location: String?

    var interval: DateInterval { DateInterval(start: start, end: max(start, end)) }
}

/// Rappel / tâche normalisé.
struct DomainReminder: Identifiable, Hashable, Sendable {
    let id: String
    let title: String
    var dueDate: Date?
    var isCompleted: Bool
    /// Priorité EventKit 0 (aucune) … 1 (haute) … 9 (basse). On la normalise.
    var priority: Int
}

/// Anniversaire normalisé issu d'un contact.
struct DomainBirthday: Identifiable, Hashable, Sendable {
    let id: String          // identifiant contact
    let name: String
    /// Prochaine occurrence de l'anniversaire (année courante ou suivante).
    let nextOccurrence: Date
    /// Nombre de jours d'ici l'anniversaire (0 = aujourd'hui).
    let daysUntil: Int
}
