import Testing
import Foundation
@testable import Assistant

struct RuleEngineTests {
    private var prefs: RulePreferences {
        RulePreferences(birthdayLeadDays: [30, 7, 1], calendar: Fixtures.calendar)
    }

    @Test func detectsConflictBetweenOverlappingEvents() {
        let events = [
            DomainEvent(id: "a", title: "Réunion A", start: Fixtures.time(10), end: Fixtures.time(11), isAllDay: false),
            DomainEvent(id: "b", title: "Réunion B", start: Fixtures.time(10, 30), end: Fixtures.time(11, 30), isAllDay: false),
        ]
        let context = RuleContext(referenceDate: Fixtures.reference, events: events, reminders: [], birthdays: [], preferences: prefs)
        let items = RuleEngine(preferences: prefs).evaluate(context: context)
        #expect(items.contains { $0.kind == .conflict })
    }

    @Test func noConflictForSequentialEvents() {
        let events = [
            DomainEvent(id: "a", title: "A", start: Fixtures.time(10), end: Fixtures.time(11), isAllDay: false),
            DomainEvent(id: "b", title: "B", start: Fixtures.time(11), end: Fixtures.time(12), isAllDay: false),
        ]
        let context = RuleContext(referenceDate: Fixtures.reference, events: events, reminders: [], birthdays: [], preferences: prefs)
        let items = RuleEngine(preferences: prefs).evaluate(context: context)
        #expect(!items.contains { $0.kind == .conflict })
    }

    @Test func deadlineTodayProducesDeadlineItem() {
        let reminders = [
            DomainReminder(id: "r1", title: "Rapport", dueDate: Fixtures.time(18), isCompleted: false, priority: 1),
        ]
        let context = RuleContext(referenceDate: Fixtures.reference, events: [], reminders: reminders, birthdays: [], preferences: prefs)
        let items = RuleEngine(preferences: prefs).evaluate(context: context)
        #expect(items.contains { $0.kind == .deadline && $0.title == "Rapport" })
    }

    @Test func overdueReminderProducesForgottenItem() {
        let yesterday = Fixtures.calendar.date(byAdding: .day, value: -3, to: Fixtures.reference)!
        let reminders = [
            DomainReminder(id: "r2", title: "Payer facture", dueDate: yesterday, isCompleted: false, priority: 1),
        ]
        let context = RuleContext(referenceDate: Fixtures.reference, events: [], reminders: reminders, birthdays: [], preferences: prefs)
        let items = RuleEngine(preferences: prefs).evaluate(context: context)
        #expect(items.contains { $0.kind == .forgotten })
    }

    @Test func completedReminderIsIgnored() {
        let reminders = [
            DomainReminder(id: "r3", title: "Fait", dueDate: Fixtures.time(18), isCompleted: true, priority: 1),
        ]
        let context = RuleContext(referenceDate: Fixtures.reference, events: [], reminders: reminders, birthdays: [], preferences: prefs)
        let items = RuleEngine(preferences: prefs).evaluate(context: context)
        #expect(items.isEmpty)
    }

    @Test func birthdayRespectsLeadDays() {
        let next = Fixtures.calendar.date(byAdding: .day, value: 7, to: Fixtures.reference)!
        let birthdays = [DomainBirthday(id: "c1", name: "Paul", nextOccurrence: next, daysUntil: 7)]
        let context = RuleContext(referenceDate: Fixtures.reference, events: [], reminders: [], birthdays: birthdays, preferences: prefs)
        let items = RuleEngine(preferences: prefs).evaluate(context: context)
        #expect(items.contains { $0.kind == .birthday && $0.title.contains("Paul") })
    }

    @Test func birthdayOutsideLeadDaysIsSkipped() {
        let next = Fixtures.calendar.date(byAdding: .day, value: 5, to: Fixtures.reference)!
        let birthdays = [DomainBirthday(id: "c2", name: "Lina", nextOccurrence: next, daysUntil: 5)]
        let context = RuleContext(referenceDate: Fixtures.reference, events: [], reminders: [], birthdays: birthdays, preferences: prefs)
        let items = RuleEngine(preferences: prefs).evaluate(context: context)
        #expect(!items.contains { $0.kind == .birthday })
    }

    @Test func itemsAreSortedByPriorityDescending() {
        let events = [DomainEvent(id: "e", title: "Tard", start: Fixtures.time(20), end: Fixtures.time(21), isAllDay: false)]
        let reminders = [DomainReminder(id: "r", title: "Deadline", dueDate: Fixtures.time(18), isCompleted: false, priority: 1)]
        let context = RuleContext(referenceDate: Fixtures.reference, events: events, reminders: reminders, birthdays: [], preferences: prefs)
        let items = RuleEngine(preferences: prefs).evaluate(context: context)
        let scores = items.map(\.priorityScore)
        #expect(scores == scores.sorted(by: >))
    }

    @Test func makeBriefingAssemblesEverything() async throws {
        let engine = RuleEngine(preferences: prefs)
        let briefing = try await engine.makeBriefing(
            userId: "test",
            referenceDate: Fixtures.reference,
            events: MockEventProvider(events: [
                DomainEvent(id: "e", title: "Réunion", start: Fixtures.time(10), end: Fixtures.time(11), isAllDay: false),
            ]),
            reminders: MockReminderProvider(reminders: []),
            birthdays: MockBirthdayProvider(birthdays: [])
        )
        #expect(briefing.userId == "test")
        #expect(briefing.items.contains { $0.kind == .event })
        #expect(!briefing.summary.isEmpty)
    }
}
