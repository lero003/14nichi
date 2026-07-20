import Foundation
import Testing
@testable import FourteenDayCore

@Suite("Favorite article storage")
struct FavoriteArticleStoreTests {
    @Test("article IDs round-trip through isolated defaults")
    func savesAndLoadsFavorites() throws {
        let context = try makeContext()
        defer { context.defaults.removePersistentDomain(forName: context.suiteName) }

        context.store.save(["water", "blackout"])

        #expect(context.store.load() == ["blackout", "water"])
        #expect(
            context.defaults.stringArray(forKey: FavoriteArticleStore.defaultKey)
                == ["blackout", "water"]
        )
    }

    @Test("duplicate stored IDs are normalized into a set")
    func removesDuplicateIDs() throws {
        let context = try makeContext()
        defer { context.defaults.removePersistentDomain(forName: context.suiteName) }
        context.defaults.set(
            ["blackout", "blackout"],
            forKey: FavoriteArticleStore.defaultKey
        )

        #expect(context.store.load() == ["blackout"])
    }

    @Test("missing storage starts empty")
    func startsEmpty() throws {
        let context = try makeContext()
        defer { context.defaults.removePersistentDomain(forName: context.suiteName) }

        #expect(context.store.load().isEmpty)
    }

    private func makeContext() throws -> (
        suiteName: String,
        defaults: UserDefaults,
        store: FavoriteArticleStore
    ) {
        let suiteName = "FavoriteArticleStoreTests-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        return (
            suiteName,
            defaults,
            FavoriteArticleStore(defaults: defaults)
        )
    }
}
