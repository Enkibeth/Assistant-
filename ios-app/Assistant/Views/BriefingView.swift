import SwiftUI

struct BriefingView: View {
    let briefing: Briefing

    var body: some View {
        List {
            Section {
                Text(briefing.summary)
                    .font(.headline)
                    .padding(.vertical, 4)
            }

            if briefing.items.isEmpty {
                ContentUnavailableView("Journée libre", systemImage: "sun.max")
            } else {
                Section("Détails") {
                    ForEach(briefing.items) { item in
                        BriefingRow(item: item)
                    }
                }
            }
        }
    }
}

struct BriefingRow: View {
    let item: BriefingItem

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: item.kind.symbolName)
                .foregroundStyle(item.kind.tint)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(item.title).font(.body)
                if let detail = item.detail {
                    Text(detail).font(.caption).foregroundStyle(.secondary)
                }
            }
            Spacer()
        }
        .padding(.vertical, 2)
    }
}

extension BriefingItemKind {
    var symbolName: String {
        switch self {
        case .event: "calendar"
        case .reminder: "checklist"
        case .birthday: "gift"
        case .conflict: "exclamationmark.triangle"
        case .deadline: "clock.badge.exclamationmark"
        case .forgotten: "lightbulb"
        }
    }

    var tint: Color {
        switch self {
        case .event: .blue
        case .reminder: .green
        case .birthday: .pink
        case .conflict: .orange
        case .deadline: .red
        case .forgotten: .yellow
        }
    }
}

#Preview {
    NavigationStack {
        BriefingView(briefing: Briefing(
            userId: "local",
            date: .now,
            summary: "Aujourd'hui, tu as 2 événements, 1 échéance. 🎂 Anniversaire de Paul dans 7 jours.",
            items: [
                BriefingItem(id: "1", kind: .event, title: "Réunion équipe", detail: "10:00 – 11:00", date: .now, priorityScore: 0.6),
                BriefingItem(id: "2", kind: .deadline, title: "Rendre le rapport", detail: "Échéance aujourd'hui", date: .now, priorityScore: 0.9),
                BriefingItem(id: "3", kind: .birthday, title: "🎂 Anniversaire de Paul dans 7 jours", date: .now, priorityScore: 0.6),
            ]
        ))
    }
}
