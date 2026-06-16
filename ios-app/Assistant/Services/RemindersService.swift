import Foundation
import EventKit

/// Accès aux rappels via EventKit.
final class RemindersService: ReminderProviding {
    private let store: EKEventStore

    init(store: EKEventStore = EKEventStore()) {
        self.store = store
    }

    func requestAccess() async throws -> Bool {
        if #available(iOS 17.0, macOS 14.0, *) {
            return try await store.requestFullAccessToReminders()
        } else {
            return try await withCheckedThrowingContinuation { cont in
                store.requestAccess(to: .reminder) { granted, error in
                    if let error { cont.resume(throwing: error) }
                    else { cont.resume(returning: granted) }
                }
            }
        }
    }

    func reminders() async throws -> [DomainReminder] {
        let predicate = store.predicateForReminders(in: nil)
        let ekReminders: [EKReminder] = try await withCheckedThrowingContinuation { cont in
            store.fetchReminders(matching: predicate) { reminders in
                cont.resume(returning: reminders ?? [])
            }
        }
        return ekReminders.map { ek in
            DomainReminder(
                id: ek.calendarItemIdentifier,
                title: ek.title ?? "(Sans titre)",
                dueDate: ek.dueDateComponents?.date,
                isCompleted: ek.isCompleted,
                priority: ek.priority
            )
        }
    }

    @discardableResult
    func createReminder(title: String, due: Date?) throws -> String {
        let reminder = EKReminder(eventStore: store)
        reminder.title = title
        reminder.calendar = store.defaultCalendarForNewReminders()
        if let due {
            reminder.dueDateComponents = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute], from: due
            )
        }
        try store.save(reminder, commit: true)
        return reminder.calendarItemIdentifier
    }
}

private extension DateComponents {
    var date: Date? { Calendar.current.date(from: self) }
}
