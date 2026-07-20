import Foundation

public struct OfficialLinkCatalog: Codable, Equatable, Sendable {
    public var schemaVersion: Int
    public var requiresOnlineNotice: String
    public var categories: [OfficialLinkCategory]

    public init(
        schemaVersion: Int,
        requiresOnlineNotice: String,
        categories: [OfficialLinkCategory]
    ) {
        self.schemaVersion = schemaVersion
        self.requiresOnlineNotice = requiresOnlineNotice
        self.categories = categories
    }

    public var allLinks: [OfficialLink] {
        categories.flatMap(\.links)
    }
}

public struct OfficialLinkCategory: Codable, Equatable, Identifiable, Sendable {
    public var id: String
    public var title: String
    public var links: [OfficialLink]

    public init(id: String, title: String, links: [OfficialLink]) {
        self.id = id
        self.title = title
        self.links = links
    }
}

public struct OfficialLink: Codable, Equatable, Identifiable, Sendable {
    public var id: String
    public var title: String
    public var url: URL
    public var purpose: String

    public init(id: String, title: String, url: URL, purpose: String) {
        self.id = id
        self.title = title
        self.url = url
        self.purpose = purpose
    }

    private enum CodingKeys: String, CodingKey {
        case id, title, url, purpose
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        purpose = try container.decode(String.self, forKey: .purpose)
        let rawURL = try container.decode(String.self, forKey: .url)
        guard let parsed = URL(string: rawURL), parsed.scheme?.lowercased() == "https" else {
            throw OfficialLinkCatalogError.invalidURL(id: id, value: rawURL)
        }
        url = parsed
    }
}

public enum OfficialLinkCatalogError: Error, Equatable, LocalizedError {
    case resourceMissing
    case invalidSchemaVersion(Int)
    case emptyCatalog
    case duplicateCategoryID(String)
    case duplicateLinkID(String)
    case invalidURL(id: String, value: String)
    case emptyField(field: String, id: String)

    public var errorDescription: String? {
        switch self {
        case .resourceMissing:
            "公式リンク集のリソースが見つかりません。"
        case .invalidSchemaVersion(let version):
            "公式リンク集の schemaVersion が未対応です: \(version)"
        case .emptyCatalog:
            "公式リンク集が空です。"
        case .duplicateCategoryID(let id):
            "カテゴリIDが重複しています: \(id)"
        case .duplicateLinkID(let id):
            "リンクIDが重複しています: \(id)"
        case .invalidURL(let id, _):
            "リンク \(id) のURLは https である必要があります。"
        case .emptyField(let field, let id):
            "\(id) の \(field) が空です。"
        }
    }
}

public struct OfficialLinkCatalogLoader: Sendable {
    public static let resourceName = "official-links"
    public static let resourceExtension = "json"
    public static let supportedSchemaVersion = 1

    public init() {}

    public func loadBundledCatalog() throws -> OfficialLinkCatalog {
        guard let url = Bundle.module.url(
            forResource: Self.resourceName,
            withExtension: Self.resourceExtension,
            subdirectory: "OfficialLinks"
        ) ?? Bundle.module.url(
            forResource: Self.resourceName,
            withExtension: Self.resourceExtension
        ) else {
            throw OfficialLinkCatalogError.resourceMissing
        }
        let data = try Data(contentsOf: url)
        return try load(from: data)
    }

    public func load(from data: Data) throws -> OfficialLinkCatalog {
        let decoder = JSONDecoder()
        let catalog = try decoder.decode(OfficialLinkCatalog.self, from: data)
        try validate(catalog)
        return catalog
    }

    public func validate(_ catalog: OfficialLinkCatalog) throws {
        guard catalog.schemaVersion == Self.supportedSchemaVersion else {
            throw OfficialLinkCatalogError.invalidSchemaVersion(catalog.schemaVersion)
        }
        guard catalog.categories.isEmpty == false else {
            throw OfficialLinkCatalogError.emptyCatalog
        }
        if catalog.requiresOnlineNotice.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            throw OfficialLinkCatalogError.emptyField(field: "requiresOnlineNotice", id: "catalog")
        }

        var categoryIDs = Set<String>()
        var linkIDs = Set<String>()

        for category in catalog.categories {
            if category.id.isEmpty {
                throw OfficialLinkCatalogError.emptyField(field: "id", id: "category")
            }
            if category.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                throw OfficialLinkCatalogError.emptyField(field: "title", id: category.id)
            }
            if categoryIDs.contains(category.id) {
                throw OfficialLinkCatalogError.duplicateCategoryID(category.id)
            }
            categoryIDs.insert(category.id)

            for link in category.links {
                if link.id.isEmpty {
                    throw OfficialLinkCatalogError.emptyField(field: "id", id: "link")
                }
                if link.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    throw OfficialLinkCatalogError.emptyField(field: "title", id: link.id)
                }
                if link.purpose.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    throw OfficialLinkCatalogError.emptyField(field: "purpose", id: link.id)
                }
                if link.url.scheme?.lowercased() != "https" {
                    throw OfficialLinkCatalogError.invalidURL(id: link.id, value: link.url.absoluteString)
                }
                if linkIDs.contains(link.id) {
                    throw OfficialLinkCatalogError.duplicateLinkID(link.id)
                }
                linkIDs.insert(link.id)
            }
        }
    }
}
