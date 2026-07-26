import XCTest

@MainActor
final class FourteenDayNoteUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testHomeOpensEarthquakeFirstActionsDirectly() {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.navigationBars["ホーム"].waitForExistence(timeout: 5))
        app.buttons["home.emergency.earthquake"].tap()

        XCTAssertTrue(
            app.navigationBars["地震：最初の数分ですること"]
                .waitForExistence(timeout: 5)
        )
        XCTAssertTrue(app.staticTexts["最初の5分ですること"].exists)
    }

    func testPreparednessOpensShoppingAsNestedRoute() {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing-shortage=drinking-water"]
        app.launch()

        app.tabBars.buttons["備え"].tap()
        XCTAssertTrue(app.navigationBars["備え"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.tabBars.buttons["買い物"].exists)

        let shortageToggle = app.switches["stockpile.shortage.drinking-water"]
        for _ in 0..<6 where shortageToggle.exists == false {
            app.swipeUp()
        }
        XCTAssertTrue(shortageToggle.exists)
        let shoppingButton = app.buttons["買い物リストを見る"]
        XCTAssertTrue(shoppingButton.waitForExistence(timeout: 3))
        shoppingButton.tap()

        XCTAssertTrue(app.navigationBars["買い物リスト"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["不足品を見直す"].exists)
    }

    func testAllSituationsReturnsToGuideRoot() {
        let app = XCUIApplication()
        app.launch()

        app.buttons["home.allSituations"].tap()

        XCTAssertTrue(app.navigationBars["防災ガイド"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.tabBars.buttons["ガイド"].isSelected)
    }
}
