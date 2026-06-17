import Foundation

/// Prévient à l'avance des anniversaires selon les jalons configurés
/// (par défaut J-30 / J-7 / J-1) ainsi que le jour J.
struct BirthdayRule: BriefingRule {
    let id = "birthday"

    func evaluate(_ context: RuleContext) -> [BriefingItem] {
        let leadDays = Set(context.preferences.birthdayLeadDays + [0])
        // Formatter alloué une seule fois par évaluation, pas par contact.
        let formatter = DateFormatter()
        formatter.calendar = context.preferences.calendar
        formatter.dateStyle = .long
        formatter.timeStyle = .none

        return context.birthdays.compactMap { birthday in
            guard leadDays.contains(birthday.daysUntil) else { return nil }
            return BriefingItem(
                id: "birthday:\(birthday.id):\(birthday.daysUntil)",
                kind: .birthday,
                title: Self.title(for: birthday),
                detail: formatter.string(from: birthday.nextOccurrence),
                date: birthday.nextOccurrence,
                priorityScore: Self.score(daysUntil: birthday.daysUntil)
            )
        }
    }

    private static func title(for b: DomainBirthday) -> String {
        switch b.daysUntil {
        case 0: return "🎂 Anniversaire de \(b.name) aujourd'hui"
        case 1: return "🎂 Anniversaire de \(b.name) demain"
        default: return "🎂 Anniversaire de \(b.name) dans \(b.daysUntil) jours"
        }
    }

    /// Plus l'anniversaire est proche, plus le score est élevé.
    private static func score(daysUntil: Int) -> Double {
        switch daysUntil {
        case 0: return 0.9
        case 1: return 0.75
        case ...7: return 0.6
        default: return 0.4
        }
    }
}
