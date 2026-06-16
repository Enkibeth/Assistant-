import Foundation

/// Pont app ↔ widget via App Group. Le widget ne touche pas EventKit : il lit
/// le dernier briefing écrit par l'app dans les UserDefaults partagés.
enum SharedBriefingStore {
    /// À aligner avec l'App Group configuré dans les entitlements des deux cibles.
    static let appGroupID = "group.com.example.aria"
    private static let key = "latestBriefing"

    private static var defaults: UserDefaults? {
        UserDefaults(suiteName: appGroupID)
    }

    static func save(_ briefing: Briefing) {
        guard let data = try? JSONCoding.encoder.encode(briefing) else { return }
        defaults?.set(data, forKey: key)
    }

    static func load() -> Briefing? {
        guard let data = defaults?.data(forKey: key) else { return nil }
        return try? JSONCoding.decoder.decode(Briefing.self, from: data)
    }
}
