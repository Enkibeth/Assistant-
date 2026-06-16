import Testing
import Foundation
@testable import Assistant

struct BriefingGeneratorTests {
    @Test func emptyDayMessage() {
        #expect(BriefingGenerator.summary(for: []).contains("Journée libre"))
    }

    @Test func countsEventsAndDeadlines() {
        let items = [
            BriefingItem(id: "1", kind: .event, title: "A", priorityScore: 0.5),
            BriefingItem(id: "2", kind: .event, title: "B", priorityScore: 0.4),
            BriefingItem(id: "3", kind: .deadline, title: "C", priorityScore: 0.9),
        ]
        let summary = BriefingGenerator.summary(for: items)
        #expect(summary.contains("2 événements"))
        #expect(summary.contains("1 échéance"))
    }

    @Test func mentionsConflict() {
        let items = [BriefingItem(id: "c", kind: .conflict, title: "X", priorityScore: 0.8)]
        #expect(BriefingGenerator.summary(for: items).contains("conflit"))
    }

    @Test func includesBirthdayTitle() {
        let items = [BriefingItem(id: "b", kind: .birthday, title: "🎂 Anniversaire de Paul demain", priorityScore: 0.75)]
        #expect(BriefingGenerator.summary(for: items).contains("Paul"))
    }
}

struct ContactsBirthdayMathTests {
    @Test func nextOccurrenceThisYearWhenUpcoming() {
        let cal = Fixtures.calendar
        let from = cal.date(from: DateComponents(year: 2026, month: 6, day: 16))!
        let bday = DateComponents(month: 8, day: 1)
        let next = ContactsService.nextOccurrence(of: bday, from: from, calendar: cal)
        #expect(cal.component(.year, from: next!) == 2026)
        #expect(cal.component(.month, from: next!) == 8)
    }

    @Test func nextOccurrenceRollsToNextYearWhenPassed() {
        let cal = Fixtures.calendar
        let from = cal.date(from: DateComponents(year: 2026, month: 6, day: 16))!
        let bday = DateComponents(month: 3, day: 1)
        let next = ContactsService.nextOccurrence(of: bday, from: from, calendar: cal)
        #expect(cal.component(.year, from: next!) == 2027)
    }

    @Test func todayCountsAsCurrentYear() {
        let cal = Fixtures.calendar
        let from = cal.date(from: DateComponents(year: 2026, month: 6, day: 16))!
        let bday = DateComponents(month: 6, day: 16)
        let next = ContactsService.nextOccurrence(of: bday, from: from, calendar: cal)
        #expect(cal.component(.year, from: next!) == 2026)
    }
}
