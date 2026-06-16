import Foundation

/// Rappels arrivant à échéance aujourd'hui (deadline) et rappels en retard
/// (forgotten). Un rappel complété est ignoré.
struct DeadlineRule: BriefingRule {
    let id = "deadline"

    func evaluate(_ context: RuleContext) -> [BriefingItem] {
        context.reminders.compactMap { reminder in
            guard !reminder.isCompleted, let due = reminder.dueDate else { return nil }
            let cal = context.preferences.calendar

            if cal.isDate(due, inSameDayAs: context.referenceDate) {
                return BriefingItem(
                    id: "deadline:\(reminder.id)",
                    kind: .deadline,
                    title: reminder.title,
                    detail: "Échéance aujourd'hui",
                    date: due,
                    priorityScore: 0.9
                )
            }
            return nil
        }
    }
}

/// Rappels dont l'échéance est passée et qui ne sont pas complétés.
struct ForgottenRule: BriefingRule {
    let id = "forgotten"

    func evaluate(_ context: RuleContext) -> [BriefingItem] {
        context.reminders.compactMap { reminder in
            guard !reminder.isCompleted, let due = reminder.dueDate else { return nil }
            guard due < context.startOfDay else { return nil }
            let days = context.preferences.calendar
                .dateComponents([.day], from: due, to: context.startOfDay).day ?? 0
            return BriefingItem(
                id: "forgotten:\(reminder.id)",
                kind: .forgotten,
                title: reminder.title,
                detail: "En retard de \(days) jour\(days > 1 ? "s" : "")",
                date: due,
                // Plus c'est ancien, plus c'est prioritaire (plafonné).
                priorityScore: min(0.95, 0.7 + Double(days) * 0.02)
            )
        }
    }
}
