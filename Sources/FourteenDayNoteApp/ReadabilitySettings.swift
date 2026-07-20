import Foundation
import Observation
import SwiftUI

/// 高齢の利用者も含め、端末の設定に頼らず本文を読みやすくするための表示設定。
@MainActor
@Observable
final class ReadabilitySettings {
    enum TextSize: String, CaseIterable, Identifiable, Sendable {
        case small
        case standard
        case comfortable
        case large
        case extraLarge

        var id: String { rawValue }

        var title: String {
            switch self {
            case .small: "小さめ"
            case .standard: "標準"
            case .comfortable: "やや大きい"
            case .large: "大きい"
            case .extraLarge: "とても大きい"
            }
        }

        var subtitle: String {
            switch self {
            case .small: "少しコンパクト"
            case .standard: "一般的なサイズ"
            case .comfortable: "少し余裕のある表示"
            case .large: "読みやすさ優先"
            case .extraLarge: "大きな文字で確認"
            }
        }

        /// システム Dynamic Type を基準に、アプリ内で一段ずつ押し上げる。
        var dynamicTypeSize: DynamicTypeSize {
            switch self {
            case .small: .medium
            case .standard: .large
            case .comfortable: .xLarge
            case .large: .xxLarge
            case .extraLarge: .accessibility2
            }
        }

        var lineSpacing: CGFloat {
            switch self {
            case .small: 6
            case .standard: 7
            case .comfortable: 8
            case .large: 10
            case .extraLarge: 12
            }
        }

        var contentMaxWidth: CGFloat {
            switch self {
            case .small: 740
            case .standard: 720
            case .comfortable: 700
            case .large: 680
            case .extraLarge: 640
            }
        }
    }

    private enum Keys {
        static let textSize = "readability.textSize"
        static let boldBody = "readability.boldBody"
        static let generousSpacing = "readability.generousSpacing"
    }

    private let defaults: UserDefaults

    var textSize: TextSize {
        didSet { defaults.set(textSize.rawValue, forKey: Keys.textSize) }
    }

    /// 本文をやや太くしてコントラストを上げる。
    var prefersBoldBody: Bool {
        didSet { defaults.set(prefersBoldBody, forKey: Keys.boldBody) }
    }

    /// 行間と余白をさらに広げる。
    var prefersGenerousSpacing: Bool {
        didSet { defaults.set(prefersGenerousSpacing, forKey: Keys.generousSpacing) }
    }

    init(
        textSize: TextSize? = nil,
        prefersBoldBody: Bool? = nil,
        prefersGenerousSpacing: Bool? = nil,
        defaults: UserDefaults = .standard
    ) {
        self.defaults = defaults
        if let textSize {
            self.textSize = textSize
        } else if let raw = defaults.string(forKey: Keys.textSize),
                  let stored = TextSize(rawValue: raw) {
            self.textSize = stored
        } else {
            self.textSize = .standard
        }

        self.prefersBoldBody = prefersBoldBody
            ?? defaults.object(forKey: Keys.boldBody) as? Bool
            ?? false
        self.prefersGenerousSpacing = prefersGenerousSpacing
            ?? defaults.object(forKey: Keys.generousSpacing) as? Bool
            ?? true
    }

    /// 通常範囲ではアプリ内の選択を使い、端末側が大きな文字なら縮小しない。
    func resolvedDynamicTypeSize(system: DynamicTypeSize) -> DynamicTypeSize {
        if system > .large {
            return max(system, textSize.dynamicTypeSize)
        }
        return textSize.dynamicTypeSize
    }

    var resolvedLineSpacing: CGFloat {
        textSize.lineSpacing + (prefersGenerousSpacing ? 4 : 0)
    }

    var listRowVerticalPadding: CGFloat {
        prefersGenerousSpacing ? 10 : 6
    }

    var sectionSpacing: CGFloat {
        prefersGenerousSpacing ? 24 : 18
    }
}
