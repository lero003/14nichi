import CoreGraphics
import CoreText
import Foundation

/// PDF / 印刷に含める項目。既定では個人情報カテゴリはすべてオフ。
public struct ExportSelection: Equatable, Sendable {
    public var includeDisplayName: Bool
    public var includeContacts: Bool
    public var includeMeetingPlace: Bool
    public var includeEvacuationPlace: Bool
    public var includeAllergies: Bool
    public var includeMedications: Bool
    public var includeNotes: Bool
    public var includeStockpileHousehold: Bool
    public var includeStockpileChecklist: Bool

    public init(
        includeDisplayName: Bool = false,
        includeContacts: Bool = false,
        includeMeetingPlace: Bool = false,
        includeEvacuationPlace: Bool = false,
        includeAllergies: Bool = false,
        includeMedications: Bool = false,
        includeNotes: Bool = false,
        includeStockpileHousehold: Bool = false,
        includeStockpileChecklist: Bool = false
    ) {
        self.includeDisplayName = includeDisplayName
        self.includeContacts = includeContacts
        self.includeMeetingPlace = includeMeetingPlace
        self.includeEvacuationPlace = includeEvacuationPlace
        self.includeAllergies = includeAllergies
        self.includeMedications = includeMedications
        self.includeNotes = includeNotes
        self.includeStockpileHousehold = includeStockpileHousehold
        self.includeStockpileChecklist = includeStockpileChecklist
    }

    public var includesPersonalInformation: Bool {
        includeDisplayName
            || includeContacts
            || includeMeetingPlace
            || includeEvacuationPlace
            || includeAllergies
            || includeMedications
            || includeNotes
    }

    public var hasAnySelection: Bool {
        includesPersonalInformation
            || includeStockpileHousehold
            || includeStockpileChecklist
    }

    public static let privacySafeDefault = ExportSelection()
}

public struct ExportStockpileItem: Equatable, Sendable, Identifiable {
    public var id: String
    public var name: String
    public var unit: String
    public var requiredAmount: Double
    public var currentAmount: Double
    public var shortageAmount: Double
    public var isPrepared: Bool
    public var expirationText: String?
    /// 数量自動計算のないチェックリスト品目。PDFでは数量0と誤解されない文言にする。
    public var isChecklistOnly: Bool

    public init(
        id: String,
        name: String,
        unit: String,
        requiredAmount: Double,
        currentAmount: Double,
        shortageAmount: Double,
        isPrepared: Bool,
        expirationText: String? = nil,
        isChecklistOnly: Bool = false
    ) {
        self.id = id
        self.name = name
        self.unit = unit
        self.requiredAmount = requiredAmount
        self.currentAmount = currentAmount
        self.shortageAmount = shortageAmount
        self.isPrepared = isPrepared
        self.expirationText = expirationText
        self.isChecklistOnly = isChecklistOnly
    }
}

public struct ExportStockpileSnapshot: Equatable, Sendable {
    public var adultCount: Int
    public var childCount: Int
    public var seniorCount: Int
    public var targetDays: Int
    public var items: [ExportStockpileItem]

    public init(
        adultCount: Int,
        childCount: Int,
        seniorCount: Int,
        targetDays: Int,
        items: [ExportStockpileItem]
    ) {
        self.adultCount = adultCount
        self.childCount = childCount
        self.seniorCount = seniorCount
        self.targetDays = targetDays
        self.items = items
    }
}

public struct ExportDocument: Equatable, Sendable {
    public var title: String
    public var generatedAt: Date
    public var selection: ExportSelection
    public var emergencyCard: EmergencyCardSnapshot?
    public var stockpile: ExportStockpileSnapshot?
    public var disclaimer: String

    public init(
        title: String = "14日ノート 出力",
        generatedAt: Date = .now,
        selection: ExportSelection,
        emergencyCard: EmergencyCardSnapshot? = nil,
        stockpile: ExportStockpileSnapshot? = nil,
        disclaimer: String = ExportDocument.defaultDisclaimer
    ) {
        self.title = title
        self.generatedAt = generatedAt
        self.selection = selection
        self.emergencyCard = emergencyCard
        self.stockpile = stockpile
        self.disclaimer = disclaimer
    }

    public static let defaultDisclaimer = """
    この文書は利用者が端末内で選択した情報の控えです。緊急時は消防・救急・自治体・現場の指示を優先してください。アプリ同梱記事は一般的な目安であり、状況や情報更新によって不正確または古くなる可能性があります。
    """

    /// 選択に含まれない個人情報フィールドを確実に空にしたスナップショットを返す。
    public func sanitizedEmergencyCard() -> EmergencyCardSnapshot? {
        guard let emergencyCard else { return nil }
        guard selection.includesPersonalInformation else { return nil }

        return EmergencyCardSnapshot(
            displayName: selection.includeDisplayName ? emergencyCard.displayName : "",
            meetingPlace: selection.includeMeetingPlace ? emergencyCard.meetingPlace : "",
            evacuationPlace: selection.includeEvacuationPlace ? emergencyCard.evacuationPlace : "",
            allergies: selection.includeAllergies ? emergencyCard.allergies : "",
            medications: selection.includeMedications ? emergencyCard.medications : "",
            notes: selection.includeNotes ? emergencyCard.notes : "",
            contacts: selection.includeContacts ? emergencyCard.contacts : [],
            updatedAt: emergencyCard.updatedAt
        )
    }

    public func sanitizedStockpile() -> ExportStockpileSnapshot? {
        guard let stockpile else { return nil }
        if selection.includeStockpileHousehold == false && selection.includeStockpileChecklist == false {
            return nil
        }

        return ExportStockpileSnapshot(
            adultCount: selection.includeStockpileHousehold ? stockpile.adultCount : 0,
            childCount: selection.includeStockpileHousehold ? stockpile.childCount : 0,
            seniorCount: selection.includeStockpileHousehold ? stockpile.seniorCount : 0,
            targetDays: selection.includeStockpileHousehold || selection.includeStockpileChecklist
                ? stockpile.targetDays
                : 0,
            items: selection.includeStockpileChecklist ? stockpile.items : []
        )
    }

    /// プレーンテキストのプレビュー（PDF描画・テスト共用）。個人情報は選択分のみ。
    public func plainTextPreview() -> String {
        var lines: [String] = []
        lines.append(title)
        lines.append(Self.dateFormatter.string(from: generatedAt))
        lines.append("")
        lines.append(disclaimer)
        lines.append("")

        if let card = sanitizedEmergencyCard(), card.hasAnyContent || selection.includeContacts {
            lines.append("■ 緊急カード")
            if selection.includeDisplayName, card.displayName.isEmpty == false {
                lines.append("表示名: \(card.displayName)")
            }
            if selection.includeMeetingPlace, card.meetingPlace.isEmpty == false {
                lines.append("集合場所: \(card.meetingPlace)")
            }
            if selection.includeEvacuationPlace, card.evacuationPlace.isEmpty == false {
                lines.append("避難予定場所: \(card.evacuationPlace)")
            }
            if selection.includeAllergies, card.allergies.isEmpty == false {
                lines.append("アレルギー: \(card.allergies)")
            }
            if selection.includeMedications, card.medications.isEmpty == false {
                lines.append("常用薬: \(card.medications)")
            }
            if selection.includeNotes, card.notes.isEmpty == false {
                lines.append("注意メモ: \(card.notes)")
            }
            if selection.includeContacts {
                lines.append("緊急連絡先:")
                if card.contacts.isEmpty {
                    lines.append("（未登録）")
                } else {
                    for contact in card.contacts {
                        let relation = contact.relation.isEmpty ? "" : "（\(contact.relation)）"
                        lines.append("- \(contact.name)\(relation) \(contact.phone)".trimmingCharacters(in: .whitespaces))
                    }
                }
            }
            lines.append("")
        }

        if let stockpile = sanitizedStockpile() {
            lines.append("■ 備蓄")
            if selection.includeStockpileHousehold {
                lines.append("人数: \(stockpile.adultCount + stockpile.childCount + stockpile.seniorCount)人")
                lines.append("計画日数: \(stockpile.targetDays)日")
            }
            if selection.includeStockpileChecklist {
                lines.append("チェックリスト:")
                if stockpile.items.isEmpty {
                    lines.append("（品目なし）")
                } else {
                    for item in stockpile.items {
                        let prepared = item.isPrepared ? "購入済/準備済" : "不足・要用意"
                        var line: String
                        if item.isChecklistOnly {
                            line = "- \(item.name): \(prepared)（数量は家庭で調整）"
                        } else {
                            line =
                                "- \(item.name): 目安 \(format(item.requiredAmount))\(item.unit) / 状態 \(prepared)"
                        }
                        if let expirationText = item.expirationText, expirationText.isEmpty == false {
                            line += " 期限: \(expirationText)"
                        }
                        lines.append(line)
                    }
                }
            }
            lines.append("")
        }

        return lines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func format(_ value: Double) -> String {
        if value.rounded() == value {
            return String(Int(value))
        }
        return String(format: "%.1f", value)
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
}

public enum ExportFileName {
    /// 個人情報をファイル名に含めない固定名。
    public static let pdf = "14nichi-export.pdf"
}

/// 一時PDFの寿命管理。値やパスに個人情報を埋め込まない。
public struct TemporaryExportFile: Sendable {
    public let url: URL
    private let cleanupDirectory: URL?

    public init(url: URL, cleanupDirectory: URL? = nil) {
        self.url = url
        self.cleanupDirectory = cleanupDirectory
    }

    public static func makePDFURL(
        in directory: URL? = nil,
        fileManager: FileManager = .default
    ) throws -> TemporaryExportFile {
        let base = directory ?? fileManager.temporaryDirectory
            .appendingPathComponent("FourteenDayNoteExports", isDirectory: true)
        try fileManager.createDirectory(at: base, withIntermediateDirectories: true)
        // 共有時の表示名は固定し、衝突回避用UUIDは専用ディレクトリ側だけに置く。
        let exportDirectory = base.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try fileManager.createDirectory(at: exportDirectory, withIntermediateDirectories: true)
        let url = exportDirectory.appendingPathComponent(ExportFileName.pdf, isDirectory: false)
        return TemporaryExportFile(url: url, cleanupDirectory: exportDirectory)
    }

    @discardableResult
    public func removeIfExists(fileManager: FileManager = .default) throws -> Bool {
        let removedFile = fileManager.fileExists(atPath: url.path)
        if removedFile {
            try fileManager.removeItem(at: url)
        }
        if let cleanupDirectory, fileManager.fileExists(atPath: cleanupDirectory.path) {
            try fileManager.removeItem(at: cleanupDirectory)
        }
        return removedFile
    }
}

public enum PDFExportError: Error, Equatable, LocalizedError {
    case emptySelection
    case cancelled
    case writeFailed

    public var errorDescription: String? {
        switch self {
        case .emptySelection:
            "出力する項目が選択されていません。"
        case .cancelled:
            "出力をキャンセルしました。"
        case .writeFailed:
            "PDFを書き出せませんでした。"
        }
    }
}

public struct PDFExportService: Sendable {
    public init() {}

    /// 選択内容からPDFデータを生成する。失敗時に個人情報をエラーへ載せない。
    public func makePDFData(document: ExportDocument) throws -> Data {
        guard document.selection.hasAnySelection else {
            throw PDFExportError.emptySelection
        }

        let text = document.plainTextPreview()
        let pageWidth: CGFloat = 595.2
        let pageHeight: CGFloat = 841.8
        let margin: CGFloat = 48
        let data = NSMutableData()

        guard let consumer = CGDataConsumer(data: data as CFMutableData) else {
            throw PDFExportError.writeFailed
        }

        var mediaBox = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        guard let context = CGContext(consumer: consumer, mediaBox: &mediaBox, nil) else {
            throw PDFExportError.writeFailed
        }

        let attributed = NSMutableAttributedString(string: text)
        attributed.addAttributes(
            [
                NSAttributedString.Key(kCTFontAttributeName as String): font(ofSize: 11),
                NSAttributedString.Key(kCTForegroundColorAttributeName as String): textColor,
            ],
            range: NSRange(location: 0, length: attributed.length)
        )
        let framesetter = CTFramesetterCreateWithAttributedString(attributed as CFAttributedString)

        var textPosition = 0
        let fullLength = (text as NSString).length

        while textPosition < fullLength {
            context.beginPage(mediaBox: &mediaBox)
            context.setFillColor(CGColor(gray: 1, alpha: 1))
            context.fill(mediaBox)

            let frameRect = CGRect(
                x: margin,
                y: margin,
                width: pageWidth - margin * 2,
                height: pageHeight - margin * 2
            )
            let path = CGPath(rect: frameRect, transform: nil)
            let frame = CTFramesetterCreateFrame(
                framesetter,
                CFRange(location: textPosition, length: 0),
                path,
                nil
            )
            CTFrameDraw(frame, context)

            let visible = CTFrameGetVisibleStringRange(frame)
            if visible.length == 0 {
                break
            }
            textPosition += visible.length
            context.endPage()
        }

        context.closePDF()
        return data as Data
    }

    public func writePDF(document: ExportDocument, to file: TemporaryExportFile) throws {
        let data = try makePDFData(document: document)
        do {
            try data.write(to: file.url, options: .atomic)
        } catch {
            throw PDFExportError.writeFailed
        }
    }

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
    private func font(ofSize size: CGFloat) -> CTFont {
        CTFontCreateWithName("Hiragino Sans" as CFString, size, nil)
    }

    private var textColor: CGColor {
        CGColor(gray: 0.1, alpha: 1)
    }
#elseif canImport(UIKit)
    private func font(ofSize size: CGFloat) -> CTFont {
        CTFontCreateWithName("Hiragino Sans" as CFString, size, nil)
    }

    private var textColor: CGColor {
        CGColor(gray: 0.1, alpha: 1)
    }
#else
    private func font(ofSize size: CGFloat) -> CTFont {
        CTFontCreateWithName("Helvetica" as CFString, size, nil)
    }

    private var textColor: CGColor {
        CGColor(gray: 0.1, alpha: 1)
    }
#endif
}
