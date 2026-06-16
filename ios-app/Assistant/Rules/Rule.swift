import Foundation

// Abstractions de fourniture de données : le moteur de règles ne connaît pas
// EventKit/Contacts, seulement ces protocoles. Permet de tester avec des mocks.

protocol EventProviding: Sendable {
    func events(in interval: DateInterval) async throws -> [DomainEvent]
}

protocol ReminderProviding: Sendable {
    func reminders() async throws -> [DomainReminder]
}

protocol BirthdayProviding: Sendable {
    func birthdays(within days: Int) async throws -> [DomainBirthday]
}

/// Préférences influençant l'évaluation des règles.
struct RulePreferences: Sendable {
    var birthdayLeadDays: [Int] = [30, 7, 1]
    var calendar: Calendar = .current
}

/// Données d'entrée d'une évaluation, déjà chargées et normalisées.
struct RuleContext: Sendable {
    let referenceDate: Date
    let events: [DomainEvent]
    let reminders: [DomainReminder]
    let birthdays: [DomainBirthday]
    var preferences: RulePreferences = .init()

    var startOfDay: Date { preferences.calendar.startOfDay(for: referenceDate) }
    var endOfDay: Date {
        preferences.calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? referenceDate
    }
}

/// Une règle transforme un contexte en éléments de briefing.
protocol BriefingRule: Sendable {
    var id: String { get }
    func evaluate(_ context: RuleContext) -> [BriefingItem]
}
