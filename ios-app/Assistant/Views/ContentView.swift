import SwiftUI

struct ContentView: View {
    @State private var model = BriefingViewModel()

    var body: some View {
        NavigationStack {
            Group {
                switch model.state {
                case .idle, .loading:
                    ProgressView("Préparation de ta journée…")
                case let .ready(briefing):
                    BriefingView(briefing: briefing)
                case .denied:
                    PermissionDeniedView()
                case let .failed(message):
                    ContentUnavailableView(
                        "Oups", systemImage: "exclamationmark.triangle", description: Text(message)
                    )
                }
            }
            .navigationTitle("Aria")
            .toolbar {
                Button {
                    Task { await model.refresh() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
            }
        }
        .task {
            if case .idle = model.state {
                await model.refresh()
                await model.scheduleBriefingNotification(hour: 7, minute: 0, timeSensitive: false)
            }
        }
    }
}

private struct PermissionDeniedView: View {
    var body: some View {
        ContentUnavailableView {
            Label("Accès calendrier requis", systemImage: "calendar.badge.exclamationmark")
        } description: {
            Text("Aria a besoin d'accéder à ton agenda pour préparer le briefing. Tu peux l'autoriser dans Réglages.")
        } actions: {
            #if os(iOS)
            Button("Ouvrir Réglages") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            #endif
        }
    }
}

#Preview {
    ContentView()
}
