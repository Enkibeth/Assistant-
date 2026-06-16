import AppIntents
import Foundation

/// « Prépare ma journée » — génère et renvoie le résumé du briefing.
struct BuildDailyBriefingIntent: AppIntent {
    static var title: LocalizedStringResource = "Préparer ma journée"
    static var description = IntentDescription(
        "Génère un briefing à partir du calendrier, des rappels et des contacts autorisés."
    )
    static var openAppWhenRun: Bool = false

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<String> & ProvidesDialog {
        let engine = RuleEngine()
        let briefing = try await engine.makeBriefing(
            userId: "local",
            events: CalendarService(),
            reminders: RemindersService(),
            birthdays: ContactsService()
        )
        SharedBriefingStore.save(briefing)
        return .result(value: briefing.summary, dialog: IntentDialog(stringLiteral: briefing.summary))
    }
}

/// « Ajoute un créneau » — crée un événement dans le calendrier.
struct AddEventIntent: AppIntent {
    static var title: LocalizedStringResource = "Ajouter un créneau"
    static var description = IntentDescription("Crée un événement dans ton calendrier.")

    @Parameter(title: "Titre") var title: String
    @Parameter(title: "Début") var start: Date
    @Parameter(title: "Durée (minutes)", default: 60) var durationMinutes: Int

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let service = CalendarService()
        guard try await service.requestAccess() else {
            throw AssistantIntentError.calendarAccessDenied
        }
        let end = start.addingTimeInterval(TimeInterval(durationMinutes * 60))
        try service.createEvent(title: title, start: start, end: end)
        return .result(dialog: "C'est noté : « \(title) » a été ajouté à ton agenda.")
    }
}

enum AssistantIntentError: Error, CustomLocalizedStringResourceConvertible {
    case calendarAccessDenied

    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .calendarAccessDenied:
            "Accès au calendrier refusé. Autorise-le dans Réglages."
        }
    }
}

/// Expose les intents à Siri / Spotlight / Shortcuts.
struct AssistantShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: BuildDailyBriefingIntent(),
            phrases: [
                "Prépare ma journée avec \(.applicationName)",
                "Montre mon briefing avec \(.applicationName)",
            ],
            shortTitle: "Briefing du jour",
            systemImageName: "calendar.badge.clock"
        )
        AppShortcut(
            intent: AddEventIntent(),
            phrases: ["Ajoute un créneau avec \(.applicationName)"],
            shortTitle: "Ajouter un créneau",
            systemImageName: "calendar.badge.plus"
        )
    }
}
