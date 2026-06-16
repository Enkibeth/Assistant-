import Foundation

/// Liste les événements de la journée. Score croissant à mesure que l'heure
/// approche (les événements imminents remontent en haut du briefing).
struct TodayEventsRule: BriefingRule {
    let id = "event"

    func evaluate(_ context: RuleContext) -> [BriefingItem] {
        let dayInterval = DateInterval(start: context.startOfDay, end: context.endOfDay)
        return context.events
            .filter { dayInterval.intersects($0.interval) }
            .map { event in
                BriefingItem(
                    id: "event:\(event.id)",
                    kind: .event,
                    title: event.title,
                    detail: Self.timeDetail(event, calendar: context.preferences.calendar),
                    date: event.start,
                    priorityScore: Self.score(event, now: context.referenceDate)
                )
            }
    }

    private static func score(_ event: DomainEvent, now: Date) -> Double {
        let hoursUntil = event.start.timeIntervalSince(now) / 3600
        if hoursUntil < 0 { return 0.3 }           // en cours / passé
        if hoursUntil < 2 { return 0.85 }          // imminent
        if hoursUntil < 6 { return 0.6 }
        return 0.45
    }

    private static func timeDetail(_ event: DomainEvent, calendar: Calendar) -> String {
        if event.isAllDay { return "Toute la journée" }
        let f = DateFormatter()
        f.calendar = calendar
        f.timeStyle = .short
        f.dateStyle = .none
        return "\(f.string(from: event.start)) – \(f.string(from: event.end))"
    }
}
