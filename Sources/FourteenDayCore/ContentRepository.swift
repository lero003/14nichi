import Foundation

public struct ContentRepository: Sendable {
    /// 短文引用の上限。これを超える転載は権利上避ける。
    public static let maxShortQuoteLength = 120

    public enum RepositoryError: Error, Equatable, LocalizedError {
        case missingManifest
        case unsupportedSchemaVersion(Int)
        case duplicateSituationID(String)
        case duplicateArticleID(String)
        case unknownSituation(articleID: String, situationID: String)
        case missingArticle(String)
        case invalidRelativePath(String)
        case missingFrontMatter(String)
        case frontMatterIDMismatch(articleID: String, documentID: String?)
        case frontMatterReviewStatusMismatch(articleID: String, documentStatus: String?)
        case incompleteApprovedReview(String)
        case invalidSource(articleID: String, sourceID: String, reason: String)
        case duplicateSourceID(articleID: String, sourceID: String)

        public var errorDescription: String? {
            switch self {
            case .missingManifest:
                "manifest.json が見つかりません"
            case .unsupportedSchemaVersion(let version):
                "未対応の schemaVersion: \(version)"
            case .duplicateSituationID(let id):
                "状況IDが重複しています: \(id)"
            case .duplicateArticleID(let id):
                "記事IDが重複しています: \(id)"
            case .unknownSituation(let articleID, let situationID):
                "記事 \(articleID) が未知の状況 \(situationID) を参照しています"
            case .missingArticle(let path):
                "Markdownが見つかりません: \(path)"
            case .invalidRelativePath(let path):
                "不正な相対パスです: \(path)"
            case .missingFrontMatter(let path):
                "front matter がありません: \(path)"
            case .frontMatterIDMismatch(let articleID, let documentID):
                "記事IDが一致しません: manifest=\(articleID), front matter=\(documentID ?? "nil")"
            case .frontMatterReviewStatusMismatch(let articleID, let documentStatus):
                "review_status が一致しません: \(articleID), front matter=\(documentStatus ?? "nil")"
            case .incompleteApprovedReview(let id):
                "approved 記事に監修情報または出典が不足しています: \(id)"
            case .invalidSource(let articleID, let sourceID, let reason):
                "記事 \(articleID) の出典 \(sourceID): \(reason)"
            case .duplicateSourceID(let articleID, let sourceID):
                "記事 \(articleID) で出典IDが重複しています: \(sourceID)"
            }
        }
    }

    public init() {}

    /// Loads the catalog packaged with FourteenDayCore.
    public func loadBundledCatalog() throws -> ContentCatalog {
        guard let manifestURL = Bundle.module.url(
            forResource: "manifest",
            withExtension: "json",
            subdirectory: "Content"
        ) else {
            throw RepositoryError.missingManifest
        }
        return try loadCatalog(from: manifestURL)
    }

    /// Loads a catalog from a content directory that contains `manifest.json`.
    public func loadCatalog(contentRoot: URL) throws -> ContentCatalog {
        let manifestURL = contentRoot.appendingPathComponent("manifest.json")
        guard FileManager.default.fileExists(atPath: manifestURL.path) else {
            throw RepositoryError.missingManifest
        }
        return try loadCatalog(from: manifestURL)
    }

    private func loadCatalog(from manifestURL: URL) throws -> ContentCatalog {
        let manifestData = try Data(contentsOf: manifestURL)
        let manifest = try JSONDecoder().decode(Manifest.self, from: manifestData)
        let contentRoot = manifestURL.deletingLastPathComponent().standardizedFileURL
        try Self.validate(manifest: manifest)

        let articles = try manifest.articles.map { metadata in
            guard Self.isValidRelativeMarkdownPath(metadata.path) else {
                throw RepositoryError.invalidRelativePath(metadata.path)
            }
            let articleURL = contentRoot.appendingPathComponent(metadata.path).standardizedFileURL
            guard articleURL.path.hasPrefix(contentRoot.path + "/") else {
                throw RepositoryError.invalidRelativePath(metadata.path)
            }
            guard FileManager.default.fileExists(atPath: articleURL.path) else {
                throw RepositoryError.missingArticle(metadata.path)
            }

            let source = try String(contentsOf: articleURL, encoding: .utf8)
            let document = try Self.parseDocument(source, path: metadata.path)
            guard document.frontMatter["id"] == metadata.id else {
                throw RepositoryError.frontMatterIDMismatch(
                    articleID: metadata.id,
                    documentID: document.frontMatter["id"]
                )
            }
            guard document.frontMatter["review_status"] == metadata.reviewStatus.rawValue else {
                throw RepositoryError.frontMatterReviewStatusMismatch(
                    articleID: metadata.id,
                    documentStatus: document.frontMatter["review_status"]
                )
            }

            return GuideArticle(
                metadata: metadata,
                bodyMarkdown: document.body
            )
        }

        return ContentCatalog(
            situations: manifest.situations.sorted { $0.sortOrder < $1.sortOrder },
            articles: articles
        )
    }

    static func removingFrontMatter(from source: String) -> String {
        (try? parseDocument(source, path: "<memory>").body) ?? source
    }

    static func validate(manifest: Manifest) throws {
        guard manifest.schemaVersion == 1 else {
            throw RepositoryError.unsupportedSchemaVersion(manifest.schemaVersion)
        }

        var situationIDs = Set<String>()
        for situation in manifest.situations {
            guard situationIDs.insert(situation.id).inserted else {
                throw RepositoryError.duplicateSituationID(situation.id)
            }
        }

        var articleIDs = Set<String>()
        for article in manifest.articles {
            guard articleIDs.insert(article.id).inserted else {
                throw RepositoryError.duplicateArticleID(article.id)
            }
            for situationID in article.situations where !situationIDs.contains(situationID) {
                throw RepositoryError.unknownSituation(
                    articleID: article.id,
                    situationID: situationID
                )
            }

            try validateSources(article.sources, articleID: article.id)

            if article.reviewStatus == .approved {
                let hasReviewDate = article.reviewedAt?.isEmpty == false
                let hasReviewer = article.reviewedBy?.isEmpty == false
                guard hasReviewDate, hasReviewer, !article.sources.isEmpty else {
                    throw RepositoryError.incompleteApprovedReview(article.id)
                }
            }
        }
    }

    static func validateSources(_ sources: [GuideArticle.Source], articleID: String) throws {
        var sourceIDs = Set<String>()
        for source in sources {
            guard sourceIDs.insert(source.id).inserted else {
                throw RepositoryError.duplicateSourceID(articleID: articleID, sourceID: source.id)
            }
            try validateSource(source, articleID: articleID)
        }
    }

    static func validateSource(_ source: GuideArticle.Source, articleID: String) throws {
        func fail(_ reason: String) -> RepositoryError {
            .invalidSource(articleID: articleID, sourceID: source.id, reason: reason)
        }

        guard !source.id.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw fail("id が空です")
        }
        guard !source.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw fail("title が空です")
        }
        guard !source.publisher.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw fail("publisher が空です")
        }
        guard !source.rightsNote.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw fail("rightsNote が空です")
        }
        guard isValidAccessDate(source.accessedAt) else {
            throw fail("accessedAt は実在する YYYY-MM-DD の日付である必要があります")
        }
        guard let scheme = source.url.scheme?.lowercased(), scheme == "https" else {
            throw fail("url は https である必要があります")
        }

        let excerpt = source.excerpt?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        switch source.usage {
        case .linkOnly, .paraphrase:
            guard excerpt.isEmpty else {
                throw fail("\(source.usage.rawValue) では excerpt を置かないでください（転載を避けるため）")
            }
        case .shortQuote:
            guard !excerpt.isEmpty else {
                throw fail("shortQuote には excerpt が必要です")
            }
            guard excerpt.count <= maxShortQuoteLength else {
                throw fail("excerpt が \(maxShortQuoteLength) 文字を超えています（長い転載は禁止）")
            }
        }
    }

    static func isValidRelativeMarkdownPath(_ path: String) -> Bool {
        guard !path.isEmpty, !path.hasPrefix("/"), path.hasSuffix(".md") else {
            return false
        }
        return !path.split(separator: "/", omittingEmptySubsequences: false).contains("..")
    }

    static func isValidAccessDate(_ value: String) -> Bool {
        let parts = value.split(separator: "-")
        guard parts.count == 3,
              parts[0].count == 4,
              parts[1].count == 2,
              parts[2].count == 2,
              parts.allSatisfy({ $0.allSatisfy(\.isNumber) })
        else {
            return false
        }

        guard let year = Int(parts[0]),
              let month = Int(parts[1]),
              let day = Int(parts[2]),
              year >= 1
        else {
            return false
        }

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let components = DateComponents(
            calendar: calendar,
            timeZone: calendar.timeZone,
            year: year,
            month: month,
            day: day
        )
        guard let date = calendar.date(from: components) else { return false }
        let resolved = calendar.dateComponents([.year, .month, .day], from: date)
        return resolved.year == year && resolved.month == month && resolved.day == day
    }

    private static func parseDocument(_ source: String, path: String) throws -> ParsedDocument {
        guard source.hasPrefix("---\n") else {
            throw RepositoryError.missingFrontMatter(path)
        }
        let headerStart = source.index(source.startIndex, offsetBy: 4)
        guard let closingRange = source.range(
            of: "\n---\n",
            range: headerStart..<source.endIndex
        ) else {
            throw RepositoryError.missingFrontMatter(path)
        }

        let header = source[headerStart..<closingRange.lowerBound]
        let frontMatter = header.split(separator: "\n").reduce(into: [String: String]()) { values, line in
            let parts = line.split(separator: ":", maxSplits: 1)
            guard parts.count == 2 else { return }
            values[String(parts[0]).trimmingCharacters(in: .whitespaces)] =
                String(parts[1]).trimmingCharacters(in: .whitespaces)
        }
        return ParsedDocument(
            frontMatter: frontMatter,
            body: String(source[closingRange.upperBound...])
        )
    }
}

struct Manifest: Codable {
    let schemaVersion: Int
    let situations: [GuideSituation]
    let articles: [GuideArticle.Metadata]
}

private struct ParsedDocument {
    let frontMatter: [String: String]
    let body: String
}
