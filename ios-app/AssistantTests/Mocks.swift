import Foundation
@testable import Assistant

// Providers en mémoire pour tester le moteur de règles sans EventKit/Contacts.

struct MockEventProvider: EventProviding {
    var events: [DomainEvent]
    func events(in interval: DateInterval) async throws -> [DomainEvent] {
        events.filter { interval.intersects($0.interval) }
    }
}

struct MockReminderProvider: ReminderProviding {
    var reminders: [DomainReminder]
    func reminders() async throws -> [DomainReminder] { reminders }
}

struct MockBirthdayProvider: BirthdayProviding {
    var birthdays: [DomainBirthday]
    func birthdays(within days: Int) async throws -> [DomainBirthday] {
        birthdays.filter { $0.daysUntil <= days }
    }
}

enum Fixtures {
    static var calendar: Calendar {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "Europe/Paris")!
        return c
    }

    /// 2026-06-16 09:00 Europe/Paris.
    static var reference: Date {
        calendar.date(from: DateComponents(year: 2026, month: 6, day: 16, hour: 9))!
    }

    static func time(_ hour: Int, _ minute: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 6, day: 16, hour: hour, minute: minute))!
    }
}
