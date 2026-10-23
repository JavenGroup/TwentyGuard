import XCTest
@testable import TwentyGuardCore

final class CountdownTimingTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 1_000)

    func testMinuteDisplayUsesNextRemainingMinuteBoundary() {
        let result = plan(remaining: 1_499.5)
        XCTAssertEqual(result.deadline, now.addingTimeInterval(1_499.5))
        XCTAssertEqual(result.display, now.addingTimeInterval(59.5))
        XCTAssertEqual(CountdownTiming.minutesRemaining(until: result.deadline!, now: now), 25)
    }

    func testLastMinuteSwitchesAtSixtySecondsAndUsesSeconds() {
        XCTAssertEqual(plan(remaining: 60.1).display!.timeIntervalSince(now), 0.1, accuracy: 0.00001)
        XCTAssertEqual(plan(remaining: 60).display, now.addingTimeInterval(1))
        XCTAssertEqual(plan(remaining: 59.2).display!.timeIntervalSince(now), 0.2, accuracy: 0.00001)
        XCTAssertEqual(CountdownTiming.secondsRemaining(until: now.addingTimeInterval(0.2), now: now), 1)
    }

    func testHidingCountdownRemovesDisplayButKeepsExactDeadline() {
        let result = plan(remaining: 1_500, visible: false)
        XCTAssertNil(result.display)
        XCTAssertEqual(result.deadline, now.addingTimeInterval(1_500))
    }

    func testMenuGetsSecondsEvenWithHiddenStatusCountdown() {
        let result = plan(remaining: 1_499.5, visible: false, menu: true)
        XCTAssertEqual(result.display, now.addingTimeInterval(0.5))
        XCTAssertEqual(result.deadline, now.addingTimeInterval(1_499.5))
    }

    func testNightBoundaryAndOverrideTakePriorityOverLaterWorkDeadline() {
        let result = plan(remaining: 1_500, transition: now.addingTimeInterval(17.25), override: now.addingTimeInterval(25))
        XCTAssertEqual(result.deadline, now.addingTimeInterval(17.25))
        XCTAssertEqual(result.display, now.addingTimeInterval(1))
    }

    func testOtherVisiblePhasesKeepSecondsAndIndependentDeadlines() {
        for phase in [CountdownPhase.rest(until: now.addingTimeInterval(17.5)), .postponed(until: now.addingTimeInterval(17.5)), .temporarilyDisabled(until: now.addingTimeInterval(17.5)), .nightLocked(until: now.addingTimeInterval(17.5))] {
            let result = CountdownTiming.plan(now: now, phase: phase, nightTransition: nil, overrideUntil: nil, showStatusCountdown: true, menuIsOpen: false, displaysAreActive: true)
            XCTAssertEqual(result.deadline, now.addingTimeInterval(17.5))
            XCTAssertEqual(result.display, now.addingTimeInterval(0.5))
        }
    }

    func testDisplaySleepRetainsNightAndTemporaryDisableDeadlines() {
        let result = CountdownTiming.plan(now: now, phase: .temporarilyDisabled(until: now.addingTimeInterval(300)), nightTransition: now.addingTimeInterval(20), overrideUntil: nil, showStatusCountdown: true, menuIsOpen: false, displaysAreActive: false)
        XCTAssertNil(result.display)
        XCTAssertEqual(result.deadline, now.addingTimeInterval(20))
    }

    func testPastDeadlineIsImmediatelyDueAndNeverUsedAsDisplayTick() {
        let result = plan(remaining: -1)
        XCTAssertEqual(result.deadline, now)
        XCTAssertNil(result.display)
    }

    private func plan(remaining: TimeInterval, visible: Bool = true, menu: Bool = false, transition: Date? = nil, override: Date? = nil) -> CountdownPlan {
        CountdownTiming.plan(now: now, phase: .work(until: now.addingTimeInterval(remaining)), nightTransition: transition, overrideUntil: override, showStatusCountdown: visible, menuIsOpen: menu, displaysAreActive: true)
    }
}
