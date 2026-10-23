import XCTest
import TwentyGuardCore
@testable import TwentyGuard

final class CountdownSchedulerTests: XCTestCase {
    private final class Ticket: CountdownCancellation {
        let date: Date
        let fire: () -> Void
        var cancelled = false
        init(date: Date, fire: @escaping () -> Void) { self.date = date; self.fire = fire }
        func cancel() { cancelled = true }
    }

    func testDisplayCallbacksCannotRunDeadlineActions() {
        var tickets: [Ticket] = []
        let scheduler = CountdownScheduler { date, callback in
            let ticket = Ticket(date: date, fire: callback); tickets.append(ticket); return ticket
        }
        var actions = 0, displays = 0
        scheduler.onDeadline = { actions += 1 }
        scheduler.onDisplay = { displays += 1 }
        scheduler.schedule(CountdownPlan(deadline: Date(timeIntervalSince1970: 100), display: Date(timeIntervalSince1970: 50)))
        tickets[1].fire()
        XCTAssertEqual(displays, 1)
        XCTAssertEqual(actions, 0)
        tickets[0].fire()
        XCTAssertEqual(actions, 1)
    }

    func testRepeatedRestorationNeverAccumulatesTimersAndIgnoresStaleCallbacks() {
        var tickets: [Ticket] = []
        let scheduler = CountdownScheduler { date, callback in
            let ticket = Ticket(date: date, fire: callback); tickets.append(ticket); return ticket
        }
        var actions = 0
        scheduler.onDeadline = { actions += 1 }
        for i in 1...10 {
            scheduler.schedule(CountdownPlan(deadline: Date(timeIntervalSince1970: Double(i)), display: Date(timeIntervalSince1970: Double(i) + 0.5)))
        }
        XCTAssertEqual(tickets.filter { !$0.cancelled }.count, 2)
        for ticket in tickets.dropLast(2) { ticket.fire() }
        XCTAssertEqual(actions, 0)
        tickets[tickets.count - 2].fire()
        XCTAssertEqual(actions, 1)
        scheduler.cancel()
        tickets.last!.fire()
        XCTAssertEqual(actions, 1)
    }

    func testRenderingDoesNotReplaceAnUnchangedDeadline() {
        var tickets: [Ticket] = []
        let scheduler = CountdownScheduler { date, callback in
            let ticket = Ticket(date: date, fire: callback); tickets.append(ticket); return ticket
        }
        let deadline = Date(timeIntervalSince1970: 100)
        for i in 1...60 {
            scheduler.schedule(CountdownPlan(deadline: deadline, display: Date(timeIntervalSince1970: Double(i))))
        }
        XCTAssertEqual(tickets.filter { $0.date == deadline }.count, 1)
        XCTAssertFalse(tickets[0].cancelled)
        XCTAssertEqual(tickets.filter { !$0.cancelled }.count, 2)
    }

    func testActualTimerFiresInMenuTrackingMode() {
        let scheduler = CountdownScheduler()
        var fired = false
        scheduler.onDeadline = { fired = true }
        scheduler.schedule(CountdownPlan(deadline: Date().addingTimeInterval(0.01), display: nil))
        let limit = Date().addingTimeInterval(0.5)
        while !fired && Date() < limit {
            RunLoop.main.run(mode: .eventTracking, before: limit)
        }
        XCTAssertTrue(fired, "A deadline must not wait for an open menu to close")
        scheduler.cancel()
    }

    func testDisplayReschedulingCannotCancelASimultaneouslyDueDeadline() {
        var tickets: [Ticket] = []
        let scheduler = CountdownScheduler { date, callback in
            let ticket = Ticket(date: date, fire: callback); tickets.append(ticket); return ticket
        }
        var actions = 0
        let date = Date(timeIntervalSince1970: 100)
        scheduler.onDeadline = { actions += 1 }
        scheduler.onDisplay = { scheduler.scheduleDisplay(nil) }
        scheduler.schedule(CountdownPlan(deadline: date, display: date))
        tickets[1].fire()
        XCTAssertFalse(tickets[0].cancelled)
        tickets[0].fire()
        XCTAssertEqual(actions, 1)
    }

    func testClockChangeCancelsOldTimersEvenWhenAbsoluteDeadlineIsUnchanged() {
        var tickets: [Ticket] = []
        let scheduler = CountdownScheduler { date, callback in
            let ticket = Ticket(date: date, fire: callback); tickets.append(ticket); return ticket
        }
        var actions = 0
        scheduler.onDeadline = { actions += 1 }
        let plan = CountdownPlan(deadline: Date(timeIntervalSince1970: 100), display: nil)
        scheduler.schedule(plan)
        scheduler.cancel()
        scheduler.schedule(plan)
        tickets[0].fire()
        XCTAssertEqual(actions, 0)
        tickets[1].fire()
        XCTAssertEqual(actions, 1)
    }

    func testDisplayAlsoFiresInMenuTrackingMode() {
        let scheduler = CountdownScheduler()
        var fired = false
        scheduler.onDisplay = { fired = true }
        scheduler.schedule(CountdownPlan(deadline: nil, display: Date().addingTimeInterval(0.01)))
        let limit = Date().addingTimeInterval(0.5)
        while !fired && Date() < limit { RunLoop.main.run(mode: .eventTracking, before: limit) }
        XCTAssertTrue(fired)
        scheduler.cancel()
    }
}
