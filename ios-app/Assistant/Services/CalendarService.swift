import Foundation
import EventKit

/// Accès au calendrier via EventKit. Demande le niveau minimal d'accès et
/// convertit les `EKEvent` en `DomainEvent` neutres pour le moteur de règles.
final class CalendarService: EventProviding {
    private let store: EKEventStore

    init(store: EKEventStore = EKEventStore()) {
        self.store = store
    }

    /// Accès complet (nécessaire pour analyser le planning et détecter les conflits).
    func requestAccess() async throws -> Bool {
        if #available(iOS 17.0, macOS 14.0, *) {
            return try await store.requestFullAccessToEvents()
        } else {
            return try await withCheckedThrowingContinuation { cont in
                store.requestAccess(to: .event) { granted, error in
                    if let error { cont.resume(throwing: error) }
                    else { cont.resume(returning: granted) }
                }
            }
        }
    }

    /// Accès en écriture seule (suffit si on veut juste créer des événements).
    @available(iOS 17.0, macOS 14.0, *)
    func requestWriteOnlyAccess() async throws -> Bool {
        try await store.requestWriteOnlyAccessToEvents()
    }

    func events(in interval: DateInterval) async throws -> [DomainEvent] {
        let predicate = store.predicateForEvents(
            withStart: interval.start, end: interval.end, calendars: nil
        )
        return store.events(matching: predicate).map { ek in
            DomainEvent(
                id: ek.eventIdentifier ?? UUID().uuidString,
                title: ek.title ?? "(Sans titre)",
                start: ek.startDate,
                end: ek.endDate,
                isAllDay: ek.isAllDay,
                location: ek.location
            )
        }
    }

    /// Crée un événement à partir d'une suggestion de l'assistant.
    @discardableResult
    func createEvent(title: String, start: Date, end: Date, notes: String? = nil) throws -> String {
        let event = EKEvent(eventStore: store)
        event.title = title
        event.startDate = start
        event.endDate = end
        event.notes = notes
        event.calendar = store.defaultCalendarForNewEvents
        try store.save(event, span: .thisEvent)
        return event.eventIdentifier ?? ""
    }
}
