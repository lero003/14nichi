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
            app.navigationBars["地震が起きた"]
                .waitForExistence(timeout: 5)
        )
        XCTAssertTrue(app.staticTexts["地震：最初の数分ですること"].exists)
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

    func testGuideSearchFindsArticleByBodyText() {
        let app = XCUIApplication()
        app.launch()
        app.tabBars.buttons["ガイド"].tap()

        let search = app.searchFields.firstMatch
        XCTAssertTrue(search.waitForExistence(timeout: 5))
        search.tap()
        search.typeText("AED")

        XCTAssertTrue(app.staticTexts["検索結果"].waitForExistence(timeout: 5))
        let result = app.buttons["guide.article.first-aid-call-119"]
        XCTAssertTrue(result.waitForExistence(timeout: 5))
        result.tap()

        XCTAssertTrue(app.navigationBars["ケガ・体調不良"].waitForExistence(timeout: 5))
    }

    func testArticleSectionJumpScrollsToHeading() {
        let app = XCUIApplication()
        app.launch()
        app.buttons["home.emergency.earthquake"].tap()

        XCTAssertTrue(app.navigationBars["地震が起きた"].waitForExistence(timeout: 5))

        let jump = app.buttons["今日中にすること"]
        XCTAssertTrue(jump.waitForExistence(timeout: 5))
        jump.tap()

        let heading = app.staticTexts["今日中にすること"]
        XCTAssertTrue(heading.waitForExistence(timeout: 2))
        expectation(for: NSPredicate(format: "isHittable == true"), evaluatedWith: heading)
        waitForExpectations(timeout: 2)
    }

    func testArticleKeepsReadingToolsAvailable() {
        let app = XCUIApplication()
        app.launch()
        app.buttons["home.emergency.earthquake"].tap()

        XCTAssertTrue(app.navigationBars["地震が起きた"].waitForExistence(timeout: 5))
        let readability = app.buttons["読みやすさ"]
        XCTAssertTrue(readability.waitForExistence(timeout: 3))
        readability.tap()

        XCTAssertTrue(app.navigationBars["読みやすさ"].waitForExistence(timeout: 5))
    }

    func testGuideSituationKeepsFilterAndReadingTools() {
        let app = XCUIApplication()
        app.launch()
        app.tabBars.buttons["ガイド"].tap()

        let situation = app.buttons["guide.situation.earthquake"]
        XCTAssertTrue(situation.waitForExistence(timeout: 5))
        situation.tap()

        XCTAssertTrue(app.navigationBars["地震が起きた"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["記事を絞り込む"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["読みやすさ"].exists)
    }

    func testEvacuationShortcutOpensDecisionArticle() {
        let app = XCUIApplication()
        app.launch()

        let shortcut = app.buttons["home.emergency.evacuation"]
        for _ in 0..<4 where !shortcut.isHittable {
            app.swipeUp()
        }
        XCTAssertTrue(shortcut.isHittable)
        shortcut.tap()

        XCTAssertTrue(app.navigationBars["避難を考える"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["避難する・留まるの判断"].waitForExistence(timeout: 5))
    }

    func testAdaptiveGuideKeepsArticleAndReadingPosition() throws {
        let app = XCUIApplication()
        app.launchArguments = [
            "--ui-testing-adaptive-guide",
            "--screenshot-route=article/earthquake-first-actions",
        ]
        app.launch()
        try XCTSkipUnless(app.frame.width > 700, "幅の往復確認はiPad Simulatorで実行")

        let jump = app.buttons["今日中にすること"]
        XCTAssertTrue(jump.waitForExistence(timeout: 5))
        jump.tap()
        let heading = app.staticTexts["今日中にすること"]
        assertHittable(heading)

        let toggle = app.buttons["testing.toggleGuideWidth"]
        toggle.tap()
        assertHittable(heading)
        toggle.tap()
        assertHittable(heading)
        XCTAssertTrue(app.navigationBars["地震が起きた"].exists)
    }

    func testAdaptiveGuideKeepsSearchAndSelectedResult() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing-adaptive-guide", "--screenshot-route=guide"]
        app.launch()
        try XCTSkipUnless(app.frame.width > 700, "幅の往復確認はiPad Simulatorで実行")

        let search = app.searchFields.firstMatch
        XCTAssertTrue(search.waitForExistence(timeout: 5))
        search.tap()
        search.typeText("AED")
        let result = app.buttons["guide.article.first-aid-call-119"]
        XCTAssertTrue(result.waitForExistence(timeout: 5))
        result.tap()
        XCTAssertTrue(app.staticTexts["救急を呼ぶ判断の目安"].waitForExistence(timeout: 5))

        let toggle = app.buttons["testing.toggleGuideWidth"]
        toggle.tap()
        XCTAssertEqual(app.searchFields.firstMatch.value as? String, "AED")
        XCTAssertTrue(result.exists)
        toggle.tap()
        XCTAssertTrue(app.staticTexts["救急を呼ぶ判断の目安"].waitForExistence(timeout: 5))
        let back = app.navigationBars["ケガ・体調不良"].buttons["防災ガイド"]
        XCTAssertTrue(back.waitForExistence(timeout: 3))
        back.tap()
        XCTAssertTrue(app.searchFields.firstMatch.waitForExistence(timeout: 3))
        XCTAssertEqual(app.searchFields.firstMatch.value as? String, "AED")
        XCTAssertTrue(result.waitForExistence(timeout: 5))
    }

    func testAdaptiveGuideKeepsManualReadingPosition() throws {
        let app = XCUIApplication()
        app.launchArguments = [
            "--ui-testing-adaptive-guide", "--screenshot-route=article/earthquake-first-actions",
        ]
        app.launch()
        try XCTSkipUnless(app.frame.width > 700, "幅の往復確認はiPad Simulatorで実行")
        let content = app.scrollViews["article.readingContent"]
        XCTAssertTrue(content.waitForExistence(timeout: 5))
        content.swipeUp()
        content.swipeUp()
        let title = app.staticTexts["地震：最初の数分ですること"]
        XCTAssertFalse(title.isHittable)
        let toggle = app.buttons["testing.toggleGuideWidth"]
        toggle.tap()
        toggle.tap()
        XCTAssertFalse(title.isHittable)
        XCTAssertTrue(app.navigationBars["地震が起きた"].exists)
    }

    private func assertHittable(_ element: XCUIElement, file: StaticString = #filePath, line: UInt = #line) {
        let visible = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "isHittable == true"), object: element
        )
        let result = XCTWaiter.wait(for: [visible], timeout: 5)
        if result != .completed {
            let screenshot = XCTAttachment(screenshot: XCUIApplication().screenshot())
            screenshot.lifetime = .keepAlways
            add(screenshot)
            let hierarchy = XCTAttachment(string: XCUIApplication().debugDescription)
            hierarchy.lifetime = .keepAlways
            add(hierarchy)
        }
        XCTAssertEqual(result, .completed, file: file, line: line)
    }
}
