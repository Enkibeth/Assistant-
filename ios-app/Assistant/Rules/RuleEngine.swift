import Foundation

/// Agrège les règles actives, charge les données via les providers, et produit
/// un `Briefing` trié par priorité. Cœur métier, testable sans frameworks Apple.
struct RuleEngine: Sendable {
    let rules: [BriefingRule]
    let preferences: RulePreferences

    init(rules: [BriefingRule] = RuleEngine.defaultRules, preferences: RulePreferences = .init()) {
        self.rules = rules
        self.preferences = preferences
    }

    static let defaultRules: [BriefingRule] = [
        TodayEventsRule(),
        ConflictRule(),
        DeadlineRule(),
        ForgottenRule(),
        BirthdayRule(),
    ]

    /// Évalue toutes les règles sur un contexte déjà chargé (synchronous, pur).
    func evaluate(context: RuleContext) -> [BriefingItem] {
        rules
            .flatMap { $0.evaluate(context) }
            .sorted { $0.priorityScore > $1.priorityScore }
    }

    /// Charge les données nécessaires puis construit le briefing complet.
    func makeBriefing(
        userId: String,
        referenceDate: Date = Date(),
        events: EventProviding,
        reminders: ReminderProviding,
        birthdays: BirthdayProviding
    ) async throws -> Briefing {
        let horizon = max(preferences.birthdayLeadDays.max() ?? 30, 1)
        let dayStart = preferences.calendar.startOfDay(for: referenceDate)
        let dayEnd = preferences.calendar.date(byAdding: .day, value: 1, to: dayStart) ?? referenceDate

        async let loadedEvents = events.events(in: DateInterval(start: dayStart, end: dayEnd))
        async let loadedReminders = reminders.reminders()
        async let loadedBirthdays = birthdays.birthdays(within: horizon)

        let context = RuleContext(
            referenceDate: referenceDate,
            events: try await loadedEvents,
            reminders: try await loadedReminders,
            birthdays: try await loadedBirthdays,
            preferences: preferences
        )

        let items = evaluate(context: context)
        let summary = BriefingGenerator.summary(for: items)
        return Briefing(userId: userId, date: dayStart, summary: summary, items: items)
    }
}
