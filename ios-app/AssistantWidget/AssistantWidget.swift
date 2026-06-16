import WidgetKit
import SwiftUI

/// Le widget lit le dernier briefing partagé (App Group) — aucune dépendance à
/// EventKit ni aux permissions côté extension.
struct BriefingEntry: TimelineEntry {
    let date: Date
    let summary: String
    let topItems: [BriefingItem]
}

struct BriefingProvider: TimelineProvider {
    func placeholder(in context: Context) -> BriefingEntry {
        BriefingEntry(date: .now, summary: "Ta journée en un coup d'œil.", topItems: [])
    }

    func getSnapshot(in context: Context, completion: @escaping (BriefingEntry) -> Void) {
        completion(makeEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<BriefingEntry>) -> Void) {
        let entry = makeEntry()
        // Rafraîchit en début d'heure suivante (l'app pré-calcule via BGTask).
        let next = Calendar.current.date(byAdding: .hour, value: 1, to: .now) ?? .now
        completion(Timeline(entries: [entry], policy: .after(next)))
    }

    private func makeEntry() -> BriefingEntry {
        guard let briefing = SharedBriefingStore.load() else {
            return BriefingEntry(date: .now, summary: "Ouvre Aria pour préparer ta journée.", topItems: [])
        }
        return BriefingEntry(
            date: briefing.date,
            summary: briefing.summary,
            topItems: Array(briefing.items.prefix(3))
        )
    }
}

struct AssistantWidgetView: View {
    var entry: BriefingEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("Aria", systemImage: "sparkles")
                .font(.caption2.bold())
                .foregroundStyle(.secondary)
            Text(entry.summary)
                .font(.caption)
                .lineLimit(family == .systemSmall ? 4 : 3)
            if family != .systemSmall {
                ForEach(entry.topItems) { item in
                    HStack(spacing: 6) {
                        Image(systemName: item.kind.symbolName)
                            .foregroundStyle(item.kind.tint)
                        Text(item.title).font(.caption2).lineLimit(1)
                    }
                }
            }
            Spacer(minLength: 0)
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

struct AssistantWidget: Widget {
    let kind = "AssistantWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: BriefingProvider()) { entry in
            AssistantWidgetView(entry: entry)
        }
        .configurationDisplayName("Briefing Aria")
        .description("Ta journée en un coup d'œil.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

@main
struct AssistantWidgetBundle: WidgetBundle {
    var body: some Widget {
        AssistantWidget()
    }
}
