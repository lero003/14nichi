import Foundation

/// 緊急カードのドメイン上限制約。脅威モデルの「長大な生活史を保存しない」に対応する。
public enum EmergencyCardLimits: Sendable {
    public static let maxDisplayNameLength = 40
    public static let maxContactNameLength = 40
    public static let maxContactPhoneLength = 30
    public static let maxContactRelationLength = 20
    public static let maxContacts = 5
    public static let maxPlaceLength = 120
    public static let maxAllergyLength = 200
    public static let maxMedicationsLength = 200
    public static let maxNotesLength = 280
}

/// 画面・PDF・テストで共有する値オブジェクト。SwiftDataモデルとは分離する。
public struct EmergencyCardSnapshot: Equatable, Sendable {
    public var displayName: String
    public var meetingPlace: String
    public var evacuationPlace: String
    public var allergies: String
    public var medications: String
    public var notes: String
    public var contacts: [EmergencyContactSnapshot]
    public var updatedAt: Date

    public init(
        displayName: String = "",
        meetingPlace: String = "",
        evacuationPlace: String = "",
        allergies: String = "",
        medications: String = "",
        notes: String = "",
        contacts: [EmergencyContactSnapshot] = [],
        updatedAt: Date = .now
    ) {
        self.displayName = Self.clamp(displayName, max: EmergencyCardLimits.maxDisplayNameLength)
        self.meetingPlace = Self.clamp(meetingPlace, max: EmergencyCardLimits.maxPlaceLength)
        self.evacuationPlace = Self.clamp(evacuationPlace, max: EmergencyCardLimits.maxPlaceLength)
        self.allergies = Self.clamp(allergies, max: EmergencyCardLimits.maxAllergyLength)
        self.medications = Self.clamp(medications, max: EmergencyCardLimits.maxMedicationsLength)
        self.notes = Self.clamp(notes, max: EmergencyCardLimits.maxNotesLength)
        self.contacts = Array(contacts.prefix(EmergencyCardLimits.maxContacts))
        self.updatedAt = updatedAt
    }

    public var isEmpty: Bool {
        displayName.isEmpty
            && meetingPlace.isEmpty
            && evacuationPlace.isEmpty
            && allergies.isEmpty
            && medications.isEmpty
            && notes.isEmpty
            && contacts.allSatisfy(\.isEmpty)
    }

    public var hasAnyContent: Bool { !isEmpty }

    public static func clamp(_ value: String, max: Int) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count > max else { return trimmed }
        let end = trimmed.index(trimmed.startIndex, offsetBy: max)
        return String(trimmed[..<end])
    }
}

public struct EmergencyContactSnapshot: Equatable, Identifiable, Sendable {
    public var id: String
    public var name: String
    public var phone: String
    public var relation: String
    public var sortOrder: Int

    public init(
        id: String = UUID().uuidString,
        name: String = "",
        phone: String = "",
        relation: String = "",
        sortOrder: Int = 0
    ) {
        self.id = id
        self.name = EmergencyCardSnapshot.clamp(name, max: EmergencyCardLimits.maxContactNameLength)
        self.phone = EmergencyCardSnapshot.clamp(phone, max: EmergencyCardLimits.maxContactPhoneLength)
        self.relation = EmergencyCardSnapshot.clamp(relation, max: EmergencyCardLimits.maxContactRelationLength)
        self.sortOrder = sortOrder
    }

    public var isEmpty: Bool {
        name.isEmpty && phone.isEmpty && relation.isEmpty
    }

    public var isCallable: Bool {
        !phone.isEmpty
    }
}

/// アプリ内ロック設定。既定はオフ（脅威モデル §6）。
public struct EmergencyCardProtectionSettings: Equatable, Sendable {
    public var requiresAuthenticationToReveal: Bool

    public init(requiresAuthenticationToReveal: Bool = false) {
        self.requiresAuthenticationToReveal = requiresAuthenticationToReveal
    }
}

public enum EmergencyCardAuthenticationResult: Equatable, Sendable {
    case success
    case cancelled
    case failed
    case notAvailable
}
