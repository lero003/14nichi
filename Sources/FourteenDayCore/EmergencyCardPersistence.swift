import Foundation
import SwiftData

public enum EmergencyCardSchemaV1: VersionedSchema {
    public static var versionIdentifier: Schema.Version {
        Schema.Version(1, 0, 0)
    }

    public static var models: [any PersistentModel.Type] {
        [Card.self, Contact.self]
    }

    @Model
    public final class Card {
        #Unique<Card>([\.stableID])

        public var stableID: String
        public var displayName: String
        public var meetingPlace: String
        public var evacuationPlace: String
        public var allergies: String
        public var medications: String
        public var notes: String
        public var updatedAt: Date

        @Relationship(deleteRule: .cascade, inverse: \Contact.card)
        public var contacts: [Contact]

        public init(
            stableID: String,
            displayName: String = "",
            meetingPlace: String = "",
            evacuationPlace: String = "",
            allergies: String = "",
            medications: String = "",
            notes: String = "",
            updatedAt: Date = .now,
            contacts: [Contact] = []
        ) {
            self.stableID = stableID
            self.displayName = displayName
            self.meetingPlace = meetingPlace
            self.evacuationPlace = evacuationPlace
            self.allergies = allergies
            self.medications = medications
            self.notes = notes
            self.updatedAt = updatedAt
            self.contacts = contacts
        }

        public var snapshot: EmergencyCardSnapshot {
            EmergencyCardSnapshot(
                displayName: displayName,
                meetingPlace: meetingPlace,
                evacuationPlace: evacuationPlace,
                allergies: allergies,
                medications: medications,
                notes: notes,
                contacts: contacts
                    .sorted { lhs, rhs in
                        if lhs.sortOrder == rhs.sortOrder {
                            return lhs.stableID < rhs.stableID
                        }
                        return lhs.sortOrder < rhs.sortOrder
                    }
                    .map(\.snapshot),
                updatedAt: updatedAt
            )
        }

        public func apply(_ snapshot: EmergencyCardSnapshot) {
            displayName = EmergencyCardSnapshot.clamp(
                snapshot.displayName,
                max: EmergencyCardLimits.maxDisplayNameLength
            )
            meetingPlace = EmergencyCardSnapshot.clamp(
                snapshot.meetingPlace,
                max: EmergencyCardLimits.maxPlaceLength
            )
            evacuationPlace = EmergencyCardSnapshot.clamp(
                snapshot.evacuationPlace,
                max: EmergencyCardLimits.maxPlaceLength
            )
            allergies = EmergencyCardSnapshot.clamp(
                snapshot.allergies,
                max: EmergencyCardLimits.maxAllergyLength
            )
            medications = EmergencyCardSnapshot.clamp(
                snapshot.medications,
                max: EmergencyCardLimits.maxMedicationsLength
            )
            notes = EmergencyCardSnapshot.clamp(
                snapshot.notes,
                max: EmergencyCardLimits.maxNotesLength
            )
            updatedAt = snapshot.updatedAt
        }
    }

    @Model
    public final class Contact {
        #Unique<Contact>([\.stableID])
        #Index<Contact>([\.sortOrder])

        public var stableID: String
        public var name: String
        public var phone: String
        public var relation: String
        public var sortOrder: Int
        public var card: Card?

        public init(
            stableID: String,
            name: String = "",
            phone: String = "",
            relation: String = "",
            sortOrder: Int = 0,
            card: Card? = nil
        ) {
            self.stableID = stableID
            self.name = name
            self.phone = phone
            self.relation = relation
            self.sortOrder = sortOrder
            self.card = card
        }

        public var snapshot: EmergencyContactSnapshot {
            EmergencyContactSnapshot(
                id: stableID,
                name: name,
                phone: phone,
                relation: relation,
                sortOrder: sortOrder
            )
        }

        public func apply(_ snapshot: EmergencyContactSnapshot) {
            name = EmergencyCardSnapshot.clamp(
                snapshot.name,
                max: EmergencyCardLimits.maxContactNameLength
            )
            phone = EmergencyCardSnapshot.clamp(
                snapshot.phone,
                max: EmergencyCardLimits.maxContactPhoneLength
            )
            relation = EmergencyCardSnapshot.clamp(
                snapshot.relation,
                max: EmergencyCardLimits.maxContactRelationLength
            )
            sortOrder = snapshot.sortOrder
        }
    }
}

public enum EmergencyCardMigrationPlan: SchemaMigrationPlan {
    public static var schemas: [any VersionedSchema.Type] {
        [EmergencyCardSchemaV1.self]
    }

    public static var stages: [MigrationStage] {
        []
    }
}

public enum EmergencyCardStoreError: Error, Equatable, Sendable {
    case cardNotFound
    case tooManyContacts
    case saveFailed
}

/// 備蓄ストアとはファイルを分離した緊急カード専用境界。
@MainActor
public enum EmergencyCardStore {
    public static let primaryCardID = "primary-emergency-card"
    public static let storeName = "EmergencyCard"
    public static let storeFileName = "EmergencyCard.store"

    public static func makeSchema() -> Schema {
        Schema(EmergencyCardSchemaV1.models)
    }

    public static func makeConfiguration(
        isStoredInMemoryOnly: Bool = false,
        storeURL: URL? = nil
    ) throws -> ModelConfiguration {
        if isStoredInMemoryOnly {
            return ModelConfiguration(
                storeName,
                schema: makeSchema(),
                isStoredInMemoryOnly: true
            )
        }

        let url = try storeURL ?? defaultStoreURL()
        return ModelConfiguration(
            storeName,
            schema: makeSchema(),
            url: url,
            cloudKitDatabase: .none
        )
    }

    public static func makeContainer(
        isStoredInMemoryOnly: Bool = false,
        storeURL: URL? = nil
    ) throws -> ModelContainer {
        let schema = makeSchema()
        let configuration = try makeConfiguration(
            isStoredInMemoryOnly: isStoredInMemoryOnly,
            storeURL: storeURL
        )
        return try ModelContainer(
            for: schema,
            migrationPlan: EmergencyCardMigrationPlan.self,
            configurations: [configuration]
        )
    }

    public static func defaultStoreURL() throws -> URL {
        let root = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let directory = root
            .appendingPathComponent("FourteenDayNote", isDirectory: true)
            .appendingPathComponent("Personal", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory.appendingPathComponent(storeFileName, isDirectory: false)
    }

    @discardableResult
    public static func loadOrCreateCard(in context: ModelContext) throws -> EmergencyCardSchemaV1.Card {
        let cardID = primaryCardID
        var descriptor = FetchDescriptor<EmergencyCardSchemaV1.Card>(
            predicate: #Predicate { $0.stableID == cardID }
        )
        descriptor.fetchLimit = 1

        if let card = try context.fetch(descriptor).first {
            return card
        }

        let card = EmergencyCardSchemaV1.Card(stableID: cardID)
        context.insert(card)
        try context.save()
        return card
    }

    public static func save(_ context: ModelContext) throws {
        try context.save()
    }

    public static func updateCard(
        _ snapshot: EmergencyCardSnapshot,
        in context: ModelContext
    ) throws -> EmergencyCardSchemaV1.Card {
        let card = try loadOrCreateCard(in: context)
        var normalized = snapshot
        // 上限超過は切り捨て（長大データ保存を防ぐ）。呼び出し側UIでも追加を止める。
        normalized.contacts = Array(snapshot.contacts.prefix(EmergencyCardLimits.maxContacts))

        card.apply(normalized)

        let incomingIDs = Set(normalized.contacts.map(\.id))
        for contact in card.contacts where incomingIDs.contains(contact.stableID) == false {
            context.delete(contact)
        }

        for (index, contactSnapshot) in normalized.contacts.enumerated() {
            if let existing = card.contacts.first(where: { $0.stableID == contactSnapshot.id }) {
                var ordered = contactSnapshot
                ordered.sortOrder = index
                existing.apply(ordered)
            } else {
                let contact = EmergencyCardSchemaV1.Contact(
                    stableID: contactSnapshot.id,
                    name: contactSnapshot.name,
                    phone: contactSnapshot.phone,
                    relation: contactSnapshot.relation,
                    sortOrder: index,
                    card: card
                )
                context.insert(contact)
                card.contacts.append(contact)
            }
        }

        card.updatedAt = .now
        try context.save()
        return card
    }

    /// カードと連絡先をすべて削除する。備蓄ストアには触れない。
    public static func deleteAll(in context: ModelContext) throws {
        let cards = try context.fetch(FetchDescriptor<EmergencyCardSchemaV1.Card>())
        for card in cards {
            context.delete(card)
        }
        let orphanContacts = try context.fetch(FetchDescriptor<EmergencyCardSchemaV1.Contact>())
        for contact in orphanContacts {
            context.delete(contact)
        }
        try context.save()
    }

    /// 永続ファイルごと消し、再オープンしてもデータが戻らないようにする。
    public static func destroyPersistentStore(at storeURL: URL) throws {
        let fm = FileManager.default
        let candidates = [
            storeURL,
            URL(fileURLWithPath: storeURL.path + "-shm"),
            URL(fileURLWithPath: storeURL.path + "-wal"),
        ]
        for url in candidates where fm.fileExists(atPath: url.path) {
            try fm.removeItem(at: url)
        }
    }
}

/// アプリ内ロック設定の永続化。カード本文とは別キーに置き、値そのものは個人情報を含まない。
public struct EmergencyCardProtectionStore: @unchecked Sendable {
    public static let defaultKey = "emergencyCard.requiresAuthenticationToReveal"

    private let defaults: UserDefaults
    private let key: String

    public init(
        defaults: UserDefaults = .standard,
        key: String = EmergencyCardProtectionStore.defaultKey
    ) {
        self.defaults = defaults
        self.key = key
    }

    public func load() -> EmergencyCardProtectionSettings {
        EmergencyCardProtectionSettings(
            requiresAuthenticationToReveal: defaults.bool(forKey: key)
        )
    }

    public func save(_ settings: EmergencyCardProtectionSettings) {
        defaults.set(settings.requiresAuthenticationToReveal, forKey: key)
    }
}
