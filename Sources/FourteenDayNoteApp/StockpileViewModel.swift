import FourteenDayCore
import Observation

@MainActor
@Observable
final class StockpileViewModel {
    var adultCount = 1
    var childCount = 0
    var seniorCount = 0
    var targetDays: StockpileTargetDays = .seven
    var entries: [StockpileEntry] = [
        StockpileEntry(id: "drinking-water", name: "飲料水", unit: "L"),
        StockpileEntry(id: "meals", name: "食事", unit: "食"),
        StockpileEntry(id: "portable-toilet", name: "簡易トイレ", unit: "回分"),
    ]

    var household: HouseholdProfile {
        HouseholdProfile(
            adultCount: adultCount,
            childCount: childCount,
            seniorCount: seniorCount
        )
    }

    var results: [StockpileResult] {
        entries.map {
            StockpileCalculator.calculate(
                entry: $0,
                household: household,
                targetDays: targetDays
            )
        }
    }

    var configuredItemCount: Int {
        results.count(where: \.isConfigured)
    }

    var shortageItemCount: Int {
        results.count(where: \.hasShortage)
    }
}
