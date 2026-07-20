import Foundation

/// お気に入りの記事IDだけを端末内へ保存する小さな永続化境界。
public struct FavoriteArticleStore {
    public static let defaultKey = "favorites.articleIDs"

    private let defaults: UserDefaults
    private let key: String

    public init(
        defaults: UserDefaults = .standard,
        key: String = FavoriteArticleStore.defaultKey
    ) {
        self.defaults = defaults
        self.key = key
    }

    public func load() -> Set<GuideArticle.ID> {
        Set(defaults.stringArray(forKey: key) ?? [])
    }

    public func save(_ articleIDs: Set<GuideArticle.ID>) {
        defaults.set(articleIDs.sorted(), forKey: key)
    }
}
