import Testing
@testable import FourteenDayCore

@Suite("Stockpile calculator")
struct StockpileCalculatorTests {
    @Test("seven-day requirement and shortage use the whole household")
    func calculatesSevenDays() {
        let result = calculate(
            targetDays: .seven,
            dailyAmount: 1.5,
            currentAmount: 10,
            household: HouseholdProfile(adultCount: 2, childCount: 0, seniorCount: 0)
        )

        #expect(result.requiredAmount == 21)
        #expect(result.shortageAmount == 11)
        #expect(abs((result.coveredDays ?? 0) - 3.333_333) < 0.001)
        #expect(result.hasShortage)
    }

    @Test("fourteen-day preset doubles a seven-day requirement")
    func calculatesFourteenDays() {
        let household = HouseholdProfile(adultCount: 1, childCount: 1, seniorCount: 1)
        let sevenDays = calculate(
            targetDays: .seven,
            dailyAmount: 2,
            currentAmount: 0,
            household: household
        )
        let fourteenDays = calculate(
            targetDays: .fourteen,
            dailyAmount: 2,
            currentAmount: 0,
            household: household
        )

        #expect(sevenDays.requiredAmount == 42)
        #expect(fourteenDays.requiredAmount == 84)
    }

    @Test("enough current stock never produces a negative shortage")
    func clampsSurplusToZero() {
        let result = calculate(
            targetDays: .seven,
            dailyAmount: 1,
            currentAmount: 20,
            household: HouseholdProfile(adultCount: 2, childCount: 0, seniorCount: 0)
        )

        #expect(result.requiredAmount == 14)
        #expect(result.shortageAmount == 0)
        #expect(result.hasShortage == false)
    }

    @Test("missing household members leaves an item unconfigured")
    func requiresHouseholdMember() {
        let result = calculate(
            targetDays: .seven,
            dailyAmount: 1,
            currentAmount: 5,
            household: HouseholdProfile(adultCount: 0, childCount: 0, seniorCount: 0)
        )

        #expect(result.isConfigured == false)
        #expect(result.requiredAmount == 0)
        #expect(result.coveredDays == nil)
    }

    @Test(
        "invalid quantities are treated as zero",
        arguments: [Double(0), -1, .nan, .infinity]
    )
    func sanitizesInvalidQuantities(_ quantity: Double) {
        let result = calculate(
            targetDays: .seven,
            dailyAmount: quantity,
            currentAmount: quantity,
            household: HouseholdProfile(adultCount: 1, childCount: 0, seniorCount: 0)
        )

        #expect(result.isConfigured == false)
        #expect(result.requiredAmount == 0)
        #expect(result.currentAmount == 0)
        #expect(result.shortageAmount == 0)
    }

    @Test("negative household counts are clamped")
    func sanitizesHouseholdCounts() {
        let household = HouseholdProfile(adultCount: -1, childCount: 2, seniorCount: -3)

        #expect(household.adultCount == 0)
        #expect(household.childCount == 2)
        #expect(household.seniorCount == 0)
        #expect(household.totalPeople == 2)
    }

    @Test("shopping list includes only configured items with a shortage")
    func buildsShoppingList() {
        let entries = [
            StockpileEntry(
                id: "shortage",
                name: "不足品",
                unit: "個",
                dailyAmountPerPerson: 2,
                currentAmount: 3
            ),
            StockpileEntry(
                id: "enough",
                name: "十分な品",
                unit: "個",
                dailyAmountPerPerson: 1,
                currentAmount: 7
            ),
            StockpileEntry(id: "unconfigured", name: "未入力", unit: "個"),
        ]

        let shoppingList = StockpileShoppingList.shortages(
            entries: entries,
            household: HouseholdProfile(adultCount: 1, childCount: 0, seniorCount: 0),
            targetDays: .seven
        )

        #expect(shoppingList.map(\.id) == ["shortage"])
        #expect(shoppingList.first?.shortageAmount == 11)
    }

    @Test("shopping list is empty when the household is missing")
    func shoppingListRequiresHousehold() {
        let shoppingList = StockpileShoppingList.shortages(
            entries: [
                StockpileEntry(
                    id: "item",
                    name: "品目",
                    unit: "個",
                    dailyAmountPerPerson: 1,
                    currentAmount: 0
                ),
            ],
            household: HouseholdProfile(adultCount: 0, childCount: 0, seniorCount: 0),
            targetDays: .fourteen
        )

        #expect(shoppingList.isEmpty)
    }

    private func calculate(
        targetDays: StockpileTargetDays,
        dailyAmount: Double,
        currentAmount: Double,
        household: HouseholdProfile
    ) -> StockpileResult {
        StockpileCalculator.calculate(
            entry: StockpileEntry(
                id: "fixture",
                name: "テスト品目",
                unit: "個",
                dailyAmountPerPerson: dailyAmount,
                currentAmount: currentAmount
            ),
            household: household,
            targetDays: targetDays
        )
    }
}
