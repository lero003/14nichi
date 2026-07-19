import Foundation
import FourteenDayCore

@main
struct ContentLint {
    static func main() {
        let arguments = Array(CommandLine.arguments.dropFirst())
        do {
            let catalog: ContentCatalog
            if let path = arguments.first {
                let root = URL(fileURLWithPath: path, isDirectory: true)
                catalog = try ContentRepository().loadCatalog(contentRoot: root)
            } else {
                catalog = try ContentRepository().loadBundledCatalog()
            }

            print("OK: situations=\(catalog.situations.count) articles=\(catalog.articles.count)")
            for situation in catalog.situations {
                let count = catalog.articles(for: situation.id).count
                print("- [\(situation.id)] \(situation.title) (\(count)件)")
            }
            for article in catalog.articles {
                let badge = article.isDraftFixture ? "draft" : "approved"
                let sourceCount = article.sources.count
                print("  · \(article.id) [\(badge)] \(article.priority.rawValue) sources=\(sourceCount)")
                for source in article.sources {
                    print("      - \(source.id) (\(source.usage.rawValue)) \(source.publisher)")
                }
            }
            exit(0)
        } catch {
            fputs("ERROR: \(error.localizedDescription)\n", stderr)
            exit(1)
        }
    }
}
