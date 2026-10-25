import XCTest
@testable import PULSE21

final class ScoringTests: XCTestCase {
    func testStrainReturnsNilWhenNoData() {
        let result = StrainEngine.score(workouts: [], heartRateSamples: [], rpeOverride: nil)
        XCTAssertNil(result.score)
    }
    func testStrainIsNormalizedToOneThroughTwentyOne() {
        let record = WorkoutRecord(title: "Carrera", start: Date(), durationMinutes: 120, rpe: 10, source: "test", energyKcal: nil, isManual: true)
        let score = StrainEngine.score(workouts: [record]).score
        XCTAssertNotNil(score)
        XCTAssertGreaterThanOrEqual(score!, 1)
        XCTAssertLessThanOrEqual(score!, 21)
    }
    func testRecoveryCalibratesWithoutHistory() {
        let result = RecoveryEngine.score(hrv: 50, baselineHRV: nil, restingHR: 55, baselineRestingHR: nil, sleepHours: 8, sleepGoal: 8, recentLoad: nil, calibrationDays: 2)
        XCTAssertNil(result.score)
    }
}
