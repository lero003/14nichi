import FourteenDayCore
import Foundation
import SwiftData

/// 備蓄と緊急カードを別 ModelContainer で開く。失敗を個別に扱えるように Result で保持する。
@MainActor
struct AppContainers {
    let stockpile: Result<ModelContainer, any Error>
    let emergencyCard: Result<ModelContainer, any Error>

    static func live() -> AppContainers {
        AppContainers(
            stockpile: Self.openStockpile(),
            emergencyCard: Self.openEmergencyCard()
        )
    }

    private static func openStockpile() -> Result<ModelContainer, any Error> {
        Result {
            let schema = Schema(StockpileSchema.models)
            let configuration = ModelConfiguration(schema: schema)
            return try ModelContainer(
                for: schema,
                migrationPlan: StockpileMigrationPlan.self,
                configurations: [configuration]
            )
        }
    }

    private static func openEmergencyCard() -> Result<ModelContainer, any Error> {
        Result {
            try EmergencyCardStore.makeContainer()
        }
    }
}
