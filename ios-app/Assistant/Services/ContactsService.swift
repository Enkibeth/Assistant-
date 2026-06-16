import Foundation
import Contacts

/// Accès aux anniversaires des contacts. Gère l'accès limité (iOS 18+) : si
/// l'utilisateur n'autorise qu'un sous-ensemble, on travaille avec ce qui est
/// visible sans jamais bloquer l'app.
final class ContactsService: BirthdayProviding {
    private let store: CNContactStore
    private let calendar: Calendar

    init(store: CNContactStore = CNContactStore(), calendar: Calendar = .current) {
        self.store = store
        self.calendar = calendar
    }

    func requestAccess() async throws -> Bool {
        try await store.requestAccess(for: .contacts)
    }

    var authorizationStatus: CNAuthorizationStatus {
        CNContactStore.authorizationStatus(for: .contacts)
    }

    func birthdays(within days: Int) async throws -> [DomainBirthday] {
        let keys = [
            CNContactGivenNameKey, CNContactFamilyNameKey, CNContactBirthdayKey,
        ] as [CNKeyDescriptor]
        let request = CNContactFetchRequest(keysToFetch: keys)

        var results: [DomainBirthday] = []
        let now = Date()

        try store.enumerateContacts(with: request) { contact, _ in
            guard let birthday = contact.birthday,
                  let next = Self.nextOccurrence(of: birthday, from: now, calendar: self.calendar)
            else { return }

            let daysUntil = self.calendar.dateComponents(
                [.day],
                from: self.calendar.startOfDay(for: now),
                to: self.calendar.startOfDay(for: next)
            ).day ?? 0

            guard daysUntil <= days else { return }

            let name = CNContactFormatter.string(from: contact, style: .fullName)
                ?? contact.givenName
            results.append(
                DomainBirthday(
                    id: contact.identifier,
                    name: name.isEmpty ? "Contact" : name,
                    nextOccurrence: next,
                    daysUntil: daysUntil
                )
            )
        }
        return results.sorted { $0.daysUntil < $1.daysUntil }
    }

    /// Prochaine date d'anniversaire (cette année ou l'an prochain).
    static func nextOccurrence(
        of birthday: DateComponents, from date: Date, calendar: Calendar
    ) -> Date? {
        var components = DateComponents()
        components.month = birthday.month
        components.day = birthday.day
        let year = calendar.component(.year, from: date)

        components.year = year
        guard let thisYear = calendar.date(from: components) else { return nil }
        if calendar.startOfDay(for: thisYear) >= calendar.startOfDay(for: date) {
            return thisYear
        }
        components.year = year + 1
        return calendar.date(from: components)
    }
}
