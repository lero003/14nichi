import Foundation
import FourteenDayCore

@main
struct ContentLint {
    static func main() {
        let arguments = Array(CommandLine.arguments.dropFirst())
        let distributionMode = arguments.contains("--distribution")
        let pathArguments = arguments.filter { $0 != "--distribution" }

        do {
            let catalog: ContentCatalog
            if let path = pathArguments.first {
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

            var nonApproved: [GuideArticle] = []
            for article in catalog.articles {
                let badge = article.reviewStatus.rawValue
                if article.reviewStatus != .approved {
                    nonApproved.append(article)
                }
                let sourceCount = article.sources.count
                print("  · \(article.id) [\(badge)] \(article.priority.rawValue) sources=\(sourceCount)")
                for source in article.sources {
                    print("      - \(source.id) (\(source.usage.rawValue)) \(source.publisher)")
                }
            }

            if distributionMode {
                if nonApproved.isEmpty {
                    print("DISTRIBUTION GATE: all articles are approved.")
                    exit(0)
                } else {
                    fputs(
                        "DISTRIBUTION GATE FAILED: \(nonApproved.count) article(s) are not approved:\n",
                        stderr
                    )
                    for article in nonApproved {
                        fputs(
                            "  - \(article.id) (\(article.reviewStatus.rawValue))\n",
                            stderr
                        )
                    }
                    fputs(
                        "App Store 提出用ビルドでは approved 以外を製品コンテンツに含めないでください。\n",
                        stderr
                    )
                    exit(2)
                }
            }

            if nonApproved.isEmpty == false {
                print(
                    "NOTE: \(nonApproved.count) article(s) are not approved (expected for internal TestFlight fixtures)."
                )
            }
            exit(0)
        } catch {
            fputs("ERROR: \(error.localizedDescription)\n", stderr)
            exit(1)
        }
    }
}
