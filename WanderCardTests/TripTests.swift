import XCTest
@testable import WanderCard

final class TripTests: XCTestCase {
    func testDurationDaysIncludesBothEndpoints() {
        let calendar = Calendar(identifier: .gregorian)
        let start = calendar.date(from: DateComponents(year: 2026, month: 4, day: 1))!
        let end = calendar.date(from: DateComponents(year: 2026, month: 4, day: 5))!
        let trip = Trip(name: "서울", startDate: start, endDate: end)
        XCTAssertEqual(trip.durationDays, 5)
    }
}
