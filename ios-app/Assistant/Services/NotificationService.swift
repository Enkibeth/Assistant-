import Foundation
import UserNotifications

/// Planification des notifications locales : briefing quotidien et alertes.
final class NotificationService {
    private let center: UNUserNotificationCenter

    init(center: UNUserNotificationCenter = .current()) {
        self.center = center
    }

    func requestAuthorization() async throws -> Bool {
        try await center.requestAuthorization(options: [.alert, .badge, .sound])
    }

    /// Programme le briefing répété chaque jour à l'heure configurée.
    func scheduleDailyBriefing(text: String, hour: Int, minute: Int, timeSensitive: Bool) async throws {
        let content = UNMutableNotificationContent()
        content.title = "Point de journée"
        content.body = text
        content.sound = .default
        content.interruptionLevel = timeSensitive ? .timeSensitive : .active

        var components = DateComponents()
        components.hour = hour
        components.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(
            identifier: "daily-briefing", content: content, trigger: trigger
        )
        try await center.add(request)
    }

    /// Alerte ponctuelle (ex. échéance imminente) avec dédup par identifiant.
    func scheduleAlert(
        id: String, title: String, body: String, at date: Date, timeSensitive: Bool
    ) async throws {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.interruptionLevel = timeSensitive ? .timeSensitive : .active

        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute], from: date
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        try await center.add(
            UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        )
    }

    func cancelAll() {
        center.removeAllPendingNotificationRequests()
    }
}
