import Foundation
import SwiftData
import Testing
@testable import FourteenDayCore

@MainActor
@Suite("Emergency card domain")
struct EmergencyCardDomainTests {
    @Test("string clamps remove whitespace and enforce max length")
    func clampsStrings() {
        let long = String(repeating: "あ", count: 50)
        let snapshot = EmergencyCardSnapshot(
            displayName: "  \(long)  ",
            allergies: "  peanuts  "
        )

        #expect(snapshot.displayName.count == EmergencyCardLimits.maxDisplayNameLength)
        #expect(snapshot.allergies == "peanuts")
    }

    @Test("empty snapshot reports no content")
    func emptySnapshot() {
        #expect(EmergencyCardSnapshot().isEmpty)
        #expect(
            EmergencyCardSnapshot(contacts: [
                EmergencyContactSnapshot(name: "A", phone: "1"),
            ]).hasAnyContent
        )
    }
}

@MainActor
@Suite("Emergency card persistence")
struct EmergencyCardPersistenceTests {
    @Test("load creates a primary card")
    func createsPrimaryCard() throws {
        let container = try makeMemoryContainer()
        let card = try EmergencyCardStore.loadOrCreateCard(in: container.mainContext)
        #expect(card.stableID == EmergencyCardStore.primaryCardID)
        #expect(card.snapshot.isEmpty)
    }

    @Test("updates persist contacts and fields")
    func persistsUpdates() throws {
        let container = try makeMemoryContainer()
        let context = container.mainContext

        let snapshot = EmergencyCardSnapshot(
            displayName: "山田",
            meetingPlace: "公園入口",
            evacuationPlace: "小学校",
            allergies: "卵",
            medications: "常備薬A",
            notes: "ブレーカーは玄関",
            contacts: [
                EmergencyContactSnapshot(id: "c1", name: "花子", phone: "09011112222", relation: "家族", sortOrder: 0),
                EmergencyContactSnapshot(id: "c2", name: "太郎", phone: "09033334444", relation: "友人", sortOrder: 1),
            ]
        )

        _ = try EmergencyCardStore.updateCard(snapshot, in: context)

        let verification = ModelContext(container)
        let loaded = try EmergencyCardStore.loadOrCreateCard(in: verification)
        #expect(loaded.displayName == "山田")
        #expect(loaded.meetingPlace == "公園入口")
        #expect(loaded.contacts.count == 2)
        #expect(loaded.snapshot.contacts.map(\.phone) == ["09011112222", "09033334444"])
    }

    @Test("contact removal persists")
    func removesContacts() throws {
        let container = try makeMemoryContainer()
        let context = container.mainContext
        _ = try EmergencyCardStore.updateCard(
            EmergencyCardSnapshot(
                contacts: [
                    EmergencyContactSnapshot(id: "keep", name: "A", phone: "1"),
                    EmergencyContactSnapshot(id: "drop", name: "B", phone: "2"),
                ]
            ),
            in: context
        )

        _ = try EmergencyCardStore.updateCard(
            EmergencyCardSnapshot(
                contacts: [
                    EmergencyContactSnapshot(id: "keep", name: "A", phone: "1"),
                ]
            ),
            in: context
        )

        let loaded = try EmergencyCardStore.loadOrCreateCard(in: context)
        #expect(loaded.contacts.map(\.stableID) == ["keep"])
    }

    @Test("extra contacts beyond the limit are dropped")
    func dropsExtraContacts() throws {
        let container = try makeMemoryContainer()
        let contacts = (0..<8).map { index in
            EmergencyContactSnapshot(id: "c\(index)", name: "N\(index)", phone: "\(index)")
        }
        let card = try EmergencyCardStore.updateCard(
            EmergencyCardSnapshot(contacts: contacts),
            in: container.mainContext
        )
        #expect(card.contacts.count == EmergencyCardLimits.maxContacts)
    }

    @Test("deleteAll removes card data from the store")
    func deleteAllClearsData() throws {
        let container = try makeMemoryContainer()
        let context = container.mainContext
        _ = try EmergencyCardStore.updateCard(
            EmergencyCardSnapshot(displayName: "消す", contacts: [
                EmergencyContactSnapshot(name: "A", phone: "1"),
            ]),
            in: context
        )

        try EmergencyCardStore.deleteAll(in: context)

        let cards = try context.fetch(FetchDescriptor<EmergencyCardSchemaV1.Card>())
        let contacts = try context.fetch(FetchDescriptor<EmergencyCardSchemaV1.Contact>())
        #expect(cards.isEmpty)
        #expect(contacts.isEmpty)
    }

    @Test("on-disk store survives container recreation and destroy removes files")
    func onDiskRoundTripAndDestroy() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("EmergencyCardTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let storeURL = directory.appendingPathComponent("EmergencyCard.store")
        defer { try? FileManager.default.removeItem(at: directory) }

        do {
            let container = try EmergencyCardStore.makeContainer(storeURL: storeURL)
            _ = try EmergencyCardStore.updateCard(
                EmergencyCardSnapshot(displayName: "永続", allergies: "小麦"),
                in: container.mainContext
            )
        }

        do {
            let reopened = try EmergencyCardStore.makeContainer(storeURL: storeURL)
            let card = try EmergencyCardStore.loadOrCreateCard(in: reopened.mainContext)
            #expect(card.displayName == "永続")
            #expect(card.allergies == "小麦")
            try EmergencyCardStore.deleteAll(in: reopened.mainContext)
        }

        try EmergencyCardStore.destroyPersistentStore(at: storeURL)

        let fresh = try EmergencyCardStore.makeContainer(storeURL: storeURL)
        let empty = try EmergencyCardStore.loadOrCreateCard(in: fresh.mainContext)
        #expect(empty.displayName.isEmpty)
        #expect(empty.allergies.isEmpty)
    }

    @Test("protection settings persist as a boolean only")
    func protectionSettings() {
        let defaults = UserDefaults(suiteName: "EmergencyCardProtectionTests-\(UUID().uuidString)")!
        defer { defaults.removePersistentDomain(forName: defaults.dictionaryRepresentation().keys.first ?? "") }

        let store = EmergencyCardProtectionStore(defaults: defaults)
        #expect(store.load().requiresAuthenticationToReveal == false)
        store.save(EmergencyCardProtectionSettings(requiresAuthenticationToReveal: true))
        #expect(store.load().requiresAuthenticationToReveal)
    }

    private func makeMemoryContainer() throws -> ModelContainer {
        try EmergencyCardStore.makeContainer(isStoredInMemoryOnly: true)
    }
}

@Suite("Export selection and PDF")
struct ExportDocumentTests {
    @Test("privacy-safe default excludes personal fields")
    func privacyDefault() {
        let selection = ExportSelection.privacySafeDefault
        #expect(selection.includesPersonalInformation == false)
        #expect(selection.hasAnySelection == false)
    }

    @Test("sanitized emergency card drops unselected fields")
    func sanitizesCard() {
        let card = EmergencyCardSnapshot(
            displayName: "名前",
            meetingPlace: "公園",
            allergies: "そば",
            contacts: [EmergencyContactSnapshot(name: "A", phone: "090")]
        )
        let document = ExportDocument(
            selection: ExportSelection(includeAllergies: true),
            emergencyCard: card
        )
        let sanitized = document.sanitizedEmergencyCard()
        #expect(sanitized?.displayName.isEmpty == true)
        #expect(sanitized?.meetingPlace.isEmpty == true)
        #expect(sanitized?.allergies == "そば")
        #expect(sanitized?.contacts.isEmpty == true)

        let text = document.plainTextPreview()
        #expect(text.contains("そば"))
        #expect(text.contains("名前") == false)
        #expect(text.contains("090") == false)
    }

    @Test("PDF generation rejects empty selection")
    func emptySelectionFails() throws {
        let service = PDFExportService()
        #expect(throws: PDFExportError.emptySelection) {
            _ = try service.makePDFData(
                document: ExportDocument(selection: .privacySafeDefault)
            )
        }
    }

    @Test("PDF write and temporary file cleanup leave no residual file")
    func writesAndCleansTemporaryFile() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("PDFExportTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let file = try TemporaryExportFile.makePDFURL(in: directory)
        #expect(file.url.lastPathComponent.contains("@") == false)
        #expect(file.url.path.contains("山田") == false)

        let document = ExportDocument(
            selection: ExportSelection(includeStockpileChecklist: true),
            stockpile: ExportStockpileSnapshot(
                adultCount: 1,
                childCount: 0,
                seniorCount: 0,
                targetDays: 7,
                items: [
                    ExportStockpileItem(
                        id: "water",
                        name: "飲料水",
                        unit: "L",
                        requiredAmount: 21,
                        currentAmount: 5,
                        shortageAmount: 16,
                        isPrepared: false
                    ),
                ]
            )
        )

        let service = PDFExportService()
        try service.writePDF(document: document, to: file)
        #expect(FileManager.default.fileExists(atPath: file.url.path))

        let data = try Data(contentsOf: file.url)
        #expect(data.count > 100)
        // PDFバイナリに個人情報フィールド名の誤混入がないことを、未選択の電話などで緩く確認
        let asString = String(decoding: data, as: UTF8.self)
        #expect(asString.contains("09011112222") == false)

        #expect(try file.removeIfExists())
        #expect(FileManager.default.fileExists(atPath: file.url.path) == false)
        #expect(try file.removeIfExists() == false)
    }

    @Test("export file name constant has no personal placeholders")
    func exportFileName() {
        #expect(ExportFileName.pdf == "14nichi-export.pdf")
    }
}

@Suite("Official link catalog")
struct OfficialLinkCatalogTests {
    @Test("bundled catalog loads with https-only public links")
    func loadsBundled() throws {
        let catalog = try OfficialLinkCatalogLoader().loadBundledCatalog()
        #expect(catalog.schemaVersion == 1)
        #expect(catalog.requiresOnlineNotice.isEmpty == false)
        #expect(catalog.categories.isEmpty == false)
        #expect(catalog.allLinks.count >= 5)
        #expect(catalog.allLinks.allSatisfy { $0.url.scheme?.lowercased() == "https" })
    }

    @Test("rejects http urls")
    func rejectsHTTP() throws {
        let json = """
        {
          "schemaVersion": 1,
          "requiresOnlineNotice": "online",
          "categories": [
            {
              "id": "c",
              "title": "Cat",
              "links": [
                {
                  "id": "bad",
                  "title": "Bad",
                  "url": "http://example.com",
                  "purpose": "test"
                }
              ]
            }
          ]
        }
        """.data(using: .utf8)!

        #expect(throws: OfficialLinkCatalogError.self) {
            _ = try OfficialLinkCatalogLoader().load(from: json)
        }
    }

    @Test("rejects duplicate link ids")
    func rejectsDuplicates() throws {
        let json = """
        {
          "schemaVersion": 1,
          "requiresOnlineNotice": "online",
          "categories": [
            {
              "id": "c",
              "title": "Cat",
              "links": [
                {
                  "id": "same",
                  "title": "A",
                  "url": "https://example.com/a",
                  "purpose": "a"
                },
                {
                  "id": "same",
                  "title": "B",
                  "url": "https://example.com/b",
                  "purpose": "b"
                }
              ]
            }
          ]
        }
        """.data(using: .utf8)!

        #expect(throws: OfficialLinkCatalogError.duplicateLinkID("same")) {
            _ = try OfficialLinkCatalogLoader().load(from: json)
        }
    }
}
