import Foundation

/// Détecte les chevauchements entre événements (hors all-day) sur la journée.
struct ConflictRule: BriefingRule {
    let id = "conflict"

    func evaluate(_ context: RuleContext) -> [BriefingItem] {
        let dayInterval = DateInterval(start: context.startOfDay, end: context.endOfDay)
        let timed = context.events
            .filter { !$0.isAllDay && dayInterval.intersects($0.interval) }
            .sorted { $0.start < $1.start }

        var items: [BriefingItem] = []
        for i in timed.indices {
            for j in timed.index(after: i)..<timed.endIndex {
                guard timed[i].interval.intersects(timed[j].interval) else { continue }
                // Les événements sont triés : si pas de chevauchement avec j,
                // les suivants ne chevaucheront pas non plus avec i.
                if timed[j].start >= timed[i].end { break }
                items.append(
                    BriefingItem(
                        id: "conflict:\(timed[i].id):\(timed[j].id)",
                        kind: .conflict,
                        title: "Conflit : « \(timed[i].title) » et « \(timed[j].title) »",
                        detail: "Ces deux événements se chevauchent.",
                        date: timed[i].start,
                        priorityScore: 0.8
                    )
                )
            }
        }
        return items
    }
}
