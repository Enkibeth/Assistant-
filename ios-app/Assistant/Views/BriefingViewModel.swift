import Foundation
import Observation

/// Coordonne services + moteur de règles pour produire le briefing du jour et le
/// pousser vers le widget et la notification. Le `userId` reste local (compte
/// optionnel Sign in with Apple en V1).
@MainActor
@Observable
final class BriefingViewModel {
    enum State: Equatable {
        case idle
        case loading
        case ready(Briefing)
        case denied
        case failed(String)
    }

    private(set) var state: State = .idle

    private let userId: String
    private let calendar: CalendarService
    private let reminders: RemindersService
    private let contacts: ContactsService
    private let notifications: NotificationService
    private let engine: RuleEngine

    init(
        userId: String = "local",
        calendar: CalendarService = .init(),
        reminders: RemindersService = .init(),
        contacts: ContactsService = .init(),
        notifications: NotificationService = .init(),
        engine: RuleEngine = .init()
    ) {
        self.userId = userId
        self.calendar = calendar
        self.reminders = reminders
        self.contacts = contacts
        self.notifications = notifications
        self.engine = engine
    }

    /// Demande les permissions just-in-time puis charge le briefing.
    func refresh() async {
        state = .loading
        do {
            // Demandes indépendantes : on les lance en parallèle.
            async let calOK = calendar.requestAccess()
            async let remOK = reminders.requestAccess()
            async let contactsOK = contacts.requestAccess()
            _ = try await (remOK, contactsOK)
            guard try await calOK else { state = .denied; return }

            let briefing = try await engine.makeBriefing(
                userId: userId,
                events: calendar,
                reminders: reminders,
                birthdays: contacts
            )
            SharedBriefingStore.save(briefing)
            state = .ready(briefing)
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    /// Programme la notification quotidienne avec le texte du briefing courant.
    func scheduleBriefingNotification(hour: Int, minute: Int, timeSensitive: Bool) async {
        guard case let .ready(briefing) = state else { return }
        _ = try? await notifications.requestAuthorization()
        try? await notifications.scheduleDailyBriefing(
            text: briefing.summary, hour: hour, minute: minute, timeSensitive: timeSensitive
        )
    }
}
