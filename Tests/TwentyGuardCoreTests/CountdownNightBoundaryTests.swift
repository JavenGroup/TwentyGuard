import XCTest
@testable import TwentyGuardCore

final class CountdownNightBoundaryTests: XCTestCase {
    private let settings = NightRestrictionSettings(isEnabled: true,
        windDownStart: ClockTime(hour: 19, minute: 30), lockStart: ClockTime(hour: 20, minute: 0),
        unlockTime: ClockTime(hour: 5, minute: 0))

    func testEveryWindDownStageLockAndUnlockHasAnExactDeadline() {
        let policy = NightRestrictionPolicy(calendar: calendar("Asia/Shanghai"))
        let times = ["2026-10-24T11:29:00Z", "2026-10-24T11:30:00Z", "2026-10-24T11:40:00Z", "2026-10-24T11:50:00Z", "2026-10-24T12:00:00Z"]
        let expected = ["2026-10-24T11:30:00Z", "2026-10-24T11:40:00Z", "2026-10-24T11:50:00Z", "2026-10-24T12:00:00Z", "2026-10-24T21:00:00Z"]
        for (time, boundary) in zip(times, expected) {
            let now = date(time)
            let status = policy.status(now: now, baseWorkDurationSeconds: 1_500, settings: settings)
            XCTAssertEqual(policy.nextTransition(after: now, status: status, isEnabled: true), date(boundary))
        }
    }

    func testFreshCalendarAfterTimeZoneChangeChangesTheNextBoundary() {
        let now = date("2026-10-24T00:00:00Z")
        let shanghai = NightRestrictionPolicy(calendar: calendar("Asia/Shanghai"))
        let losAngeles = NightRestrictionPolicy(calendar: calendar("America/Los_Angeles"))
        let oldStatus = shanghai.status(now: now, baseWorkDurationSeconds: 1_500, settings: settings)
        let newStatus = losAngeles.status(now: now, baseWorkDurationSeconds: 1_500, settings: settings)
        XCTAssertEqual(shanghai.nextTransition(after: now, status: oldStatus, isEnabled: true), date("2026-10-24T11:30:00Z"))
        XCTAssertEqual(losAngeles.nextTransition(after: now, status: newStatus, isEnabled: true), date("2026-10-24T02:30:00Z"))
    }

    func testDSTNightUnlockUsesLocalClockInsteadOfAddingTwentyFourHours() {
        let policy = NightRestrictionPolicy(calendar: calendar("America/Los_Angeles"))
        let now = date("2026-11-01T06:59:00Z") // October 31, 23:59, before the fall-back transition.
        let status = policy.status(now: now, baseWorkDurationSeconds: 1_500, settings: settings)
        XCTAssertTrue(status.isLocked)
        XCTAssertEqual(policy.nextTransition(after: now, status: status, isEnabled: true), date("2026-11-01T13:00:00Z"))
    }

    func testOverrideExpiryIsScheduledEvenWhenNightTransitionsAreSuppressed() {
        let policy = NightRestrictionPolicy(calendar: calendar("Asia/Shanghai"))
        let now = date("2026-10-24T12:00:00Z")
        let expiry = now.addingTimeInterval(1_800)
        let status = policy.status(now: now, baseWorkDurationSeconds: 1_500, settings: settings, overrideUntil: expiry)
        XCTAssertNil(policy.nextTransition(after: now, status: status, isEnabled: true))
        let plan = CountdownTiming.plan(now: now, phase: .paused, nightTransition: nil, overrideUntil: expiry,
                                      showStatusCountdown: false, menuIsOpen: false, displaysAreActive: false)
        XCTAssertEqual(plan.deadline, expiry)
        XCTAssertNil(plan.display)
        let after = policy.status(now: expiry, baseWorkDurationSeconds: 1_500, settings: settings)
        XCTAssertTrue(after.isLocked)
    }

    func testClockJumpForwardMakesAnElapsedWorkDeadlineImmediatelyDue() {
        let start = date("2026-10-24T01:00:00Z")
        let deadline = start.addingTimeInterval(1_500)
        let now = deadline.addingTimeInterval(200)
        let plan = CountdownTiming.plan(now: now, phase: .work(until: deadline), nightTransition: nil, overrideUntil: nil,
                                      showStatusCountdown: true, menuIsOpen: false, displaysAreActive: true)
        XCTAssertEqual(plan.deadline, now)
        XCTAssertNil(plan.display)
    }

    private func date(_ text: String) -> Date { ISO8601DateFormatter().date(from: text)! }
    private func calendar(_ zone: String) -> Calendar {
        var result = Calendar(identifier: .gregorian)
        result.timeZone = TimeZone(identifier: zone)!
        return result
    }
}
