import XCTest
import TwentyGuardCore
@testable import TwentyGuard

final class CountdownSimulationTests: XCTestCase {
    private final class Ticket: CountdownCancellation {
        let date: Date
        let callback: () -> Void
        var cancelled = false
        var fired = false
        init(_ date: Date, _ callback: @escaping () -> Void) { self.date = date; self.callback = callback }
        func cancel() { cancelled = true }
    }

    private final class Clock {
        var now = Date(timeIntervalSince1970: 10_000)
        var tickets: [Ticket] = []
        func schedule(_ date: Date, _ callback: @escaping () -> Void) -> CountdownCancellation {
            let ticket = Ticket(date, callback); tickets.append(ticket); return ticket
        }
        func advance(by seconds: TimeInterval) {
            let end = now.addingTimeInterval(seconds)
            var iterations = 0
            while let ticket = tickets.filter({ !$0.cancelled && !$0.fired && $0.date <= end }).min(by: { $0.date < $1.date }) {
                iterations += 1
                precondition(iterations < 10_000, "A due timer must not busy-loop")
                now = ticket.date; ticket.fired = true; ticket.callback()
            }
            now = end
        }
    }

    func testTwoOrdinaryMinutesNeedTwoDisplayCallbacksAndNoDeadlinePolling() {
        let clock = Clock()
        let scheduler = CountdownScheduler(makeTimer: clock.schedule)
        let end = clock.now.addingTimeInterval(1_500)
        func plan() -> CountdownPlan {
            CountdownTiming.plan(now: clock.now, phase: .work(until: end), nightTransition: nil, overrideUntil: nil,
                                 showStatusCountdown: true, menuIsOpen: false, displaysAreActive: true)
        }
        scheduler.onDisplay = { scheduler.scheduleDisplay(plan().display) }
        scheduler.schedule(plan())
        clock.advance(by: 120)
        XCTAssertEqual(scheduler.displayFireCount, 2)
        XCTAssertEqual(scheduler.deadlineFireCount, 0)
        XCTAssertEqual(clock.tickets.filter { !$0.cancelled && !$0.fired }.count, 2)
        scheduler.cancel()
    }

    func testFullWorkCycleKeepsExactEndWithMinuteThenSecondPresentation() {
        for visible in [true, false] {
            let clock = Clock()
            let scheduler = CountdownScheduler(makeTimer: clock.schedule)
            let end = clock.now.addingTimeInterval(1_500)
            var actionTimes: [Date] = []
            func plan() -> CountdownPlan {
                CountdownTiming.plan(now: clock.now, phase: .work(until: end), nightTransition: nil, overrideUntil: nil,
                                     showStatusCountdown: visible, menuIsOpen: false, displaysAreActive: true)
            }
            scheduler.onDisplay = { scheduler.scheduleDisplay(plan().display) }
            scheduler.onDeadline = { actionTimes.append(clock.now); scheduler.cancel() }
            scheduler.schedule(plan())
            clock.advance(by: 1_499.9)
            XCTAssertTrue(actionTimes.isEmpty)
            clock.advance(by: 0.1)
            XCTAssertEqual(actionTimes, [end])
            XCTAssertEqual(scheduler.deadlineFireCount, 1)
            XCTAssertTrue(visible ? (83...84).contains(scheduler.displayFireCount) : scheduler.displayFireCount == 0)
        }
    }

    func testOpenMenuGetsSecondsWithoutIntroducingASecondActionTimer() {
        let clock = Clock()
        let scheduler = CountdownScheduler(makeTimer: clock.schedule)
        let end = clock.now.addingTimeInterval(1_500)
        var menuIsOpen = false
        func plan() -> CountdownPlan {
            CountdownTiming.plan(now: clock.now, phase: .work(until: end), nightTransition: nil, overrideUntil: nil,
                                 showStatusCountdown: true, menuIsOpen: menuIsOpen, displaysAreActive: true)
        }
        scheduler.onDisplay = { scheduler.scheduleDisplay(plan().display) }
        scheduler.schedule(plan())
        menuIsOpen = true; scheduler.scheduleDisplay(plan().display)
        clock.advance(by: 30)
        XCTAssertEqual(scheduler.displayFireCount, 30)
        XCTAssertEqual(clock.tickets.filter { $0.date == end }.count, 1)
        menuIsOpen = false; scheduler.scheduleDisplay(plan().display)
        clock.advance(by: 30)
        XCTAssertEqual(scheduler.displayFireCount, 31)
        scheduler.cancel()
    }

    func testRestPostponeAndTemporaryDisableFinishAtFractionalDeadline() {
        let phases: [(Date) -> CountdownPhase] = [{ .rest(until: $0) }, { .postponed(until: $0) }, { .temporarilyDisabled(until: $0) }]
        for makePhase in phases {
            let clock = Clock()
            let scheduler = CountdownScheduler(makeTimer: clock.schedule)
            let end = clock.now.addingTimeInterval(17.25)
            var completedAt: Date?
            let phase = makePhase(end)
            func plan() -> CountdownPlan {
                CountdownTiming.plan(now: clock.now, phase: phase, nightTransition: nil, overrideUntil: nil,
                                     showStatusCountdown: true, menuIsOpen: false, displaysAreActive: true)
            }
            scheduler.onDisplay = { scheduler.scheduleDisplay(plan().display) }
            scheduler.onDeadline = { completedAt = clock.now; scheduler.cancel() }
            scheduler.schedule(plan())
            clock.advance(by: 17)
            XCTAssertNil(completedAt)
            clock.advance(by: 0.25)
            XCTAssertEqual(completedAt, end)
        }
    }
}
