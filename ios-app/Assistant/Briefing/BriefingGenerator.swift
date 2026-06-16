import Foundation

/// Génère le résumé textuel d'un briefing. Pur et déterministe — miroir Swift
/// de backend/src/briefing/render.ts. Le rendu local est le défaut.
enum BriefingGenerator {

    static func summary(for items: [BriefingItem]) -> String {
        guard !items.isEmpty else {
            return "Rien de prévu aujourd'hui. Journée libre 🎉"
        }

        func count(_ kind: BriefingItemKind) -> Int { items.filter { $0.kind == kind }.count }

        let events = count(.event)
        let deadlines = count(.deadline)
        let reminders = count(.reminder)
        let conflicts = count(.conflict)
        let birthdays = count(.birthday)
        let forgotten = count(.forgotten)

        var parts: [String] = []
        if events > 0 { parts.append("tu as \(plural(events, "événement"))") }
        if deadlines > 0 { parts.append(plural(deadlines, "échéance")) }
        if reminders > 0 { parts.append(plural(reminders, "rappel")) }

        var summary = parts.isEmpty ? "Aujourd'hui :" : "Aujourd'hui, \(parts.joined(separator: ", "))."

        if conflicts > 0 {
            summary += " ⚠️ \(plural(conflicts, "conflit d'agenda")) à arbitrer."
        }
        if birthdays > 0, let next = items.first(where: { $0.kind == .birthday }) {
            summary += " \(next.title)."
        }
        if forgotten > 0 {
            summary += " 💡 \(plural(forgotten, "oubli probable")) à vérifier."
        }
        return summary
    }

    /// Accord pluriel simple en français (ajout d'un « s »).
    private static func plural(_ n: Int, _ word: String) -> String {
        "\(n) \(word)\(n > 1 ? "s" : "")"
    }
}
