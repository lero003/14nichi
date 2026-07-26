import Foundation
import Testing
@testable import FourteenDayCore

struct PreparednessChecklistTests {
    @Test("new stores begin with all three items unreviewed")
    func initialState() {
        withStore { store in
            let state = store.load()
            #expect(state.reviewedCount == 0)
            #expect(state.householdReviewedAt == nil)
            #expect(state.stockpileReviewedAt == nil)
            #expect(state.emergencyCardChoice == .notReviewed)
        }
    }

    @Test("reviewed steps persist without storing card content")
    func persistsReviewState() {
        withStore { store in
            let householdDate = Date(timeIntervalSince1970: 100)
            let stockpileDate = Date(timeIntervalSince1970: 200)

            _ = store.markHouseholdReviewed(at: householdDate)
            _ = store.markStockpileReviewed(at: stockpileDate)
            let state = store.setEmergencyCardChoice(.prepared)

            #expect(state.reviewedCount == 3)
            #expect(state.householdReviewedAt == householdDate)
            #expect(state.stockpileReviewedAt == stockpileDate)
            #expect(state.emergencyCardChoice == .prepared)
        }
    }

    @Test("skipping the optional card still counts as a reviewed decision")
    func optionalCardCanBeSkipped() {
        withStore { store in
            let state = store.setEmergencyCardChoice(.skipped)
            #expect(state.reviewedCount == 1)
            #expect(state.emergencyCardChoice.isReviewed)

            let reset = store.setEmergencyCardChoice(.notReviewed)
            #expect(reset.reviewedCount == 0)
        }
    }

    @Test("saving an emptied card removes the prepared review state")
    func emptyCardSaveResetsPreparedState() {
        #expect(EmergencyCardPreparationChoice.afterSavingCard(hasContent: true) == .prepared)
        #expect(EmergencyCardPreparationChoice.afterSavingCard(hasContent: false) == .notReviewed)
    }

    private func withStore(_ body: (PreparednessChecklistStore) -> Void) {
        let suiteName = "PreparednessChecklistTests-\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            Issue.record("Unable to create isolated UserDefaults.")
            return
        }
        defer { defaults.removePersistentDomain(forName: suiteName) }
        body(PreparednessChecklistStore(defaults: defaults, keyPrefix: "test"))
    }
}
