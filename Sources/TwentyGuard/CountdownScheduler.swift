import AppKit
import TwentyGuardCore

protocol CountdownCancellation: AnyObject {
    func cancel()
}

private final class CountdownTimer: CountdownCancellation {
    private let timer: Timer

    init(date: Date, fire: @escaping () -> Void) {
        timer = Timer(fire: date, interval: 0, repeats: false) { _ in fire() }
        // Menu tracking runs outside the default mode. Deadlines must still fire there.
        RunLoop.main.add(timer, forMode: .common)
        RunLoop.main.add(timer, forMode: .eventTracking)
    }

    func cancel() { timer.invalidate() }
}

/// Owns at most one action deadline and one presentation timer, including after restoration.
final class CountdownScheduler {
    typealias TimerFactory = (Date, @escaping () -> Void) -> CountdownCancellation
    private let makeTimer: TimerFactory
    private var deadlineTimer: CountdownCancellation?
    private var displayTimer: CountdownCancellation?
    private var deadlineGeneration = 0
    private var displayGeneration = 0
    private var deadlineDate: Date?
    private var displayDate: Date?

    var onDeadline: (() -> Void)?
    var onDisplay: (() -> Void)?
    private(set) var deadlineFireCount = 0
    private(set) var displayFireCount = 0
    private(set) var lastFiredDeadline: Date?
    var scheduledPlan: CountdownPlan { CountdownPlan(deadline: deadlineDate, display: displayDate) }

    init(makeTimer: @escaping TimerFactory = { CountdownTimer(date: $0, fire: $1) }) {
        self.makeTimer = makeTimer
    }

    func schedule(_ plan: CountdownPlan) {
        // An unchanged deadline should not be recreated at each visible second.
        if deadlineDate != plan.deadline {
            deadlineTimer?.cancel()
            deadlineTimer = nil
            deadlineGeneration += 1
            deadlineDate = plan.deadline
            if let date = plan.deadline {
                let generation = deadlineGeneration
                deadlineTimer = makeTimer(date) { [weak self] in
                    guard let self, generation == self.deadlineGeneration else { return }
                    self.deadlineTimer = nil
                    self.deadlineDate = nil
                    self.deadlineFireCount += 1
                    self.lastFiredDeadline = date
                    self.onDeadline?()
                }
            }
        }
        scheduleDisplay(plan.display)
    }

    /// A render callback must never cancel an action that is already due.
    func scheduleDisplay(_ date: Date?) {
        if displayDate != date {
            displayTimer?.cancel()
            displayTimer = nil
            displayGeneration += 1
            displayDate = date
            if let date {
                let generation = displayGeneration
                displayTimer = makeTimer(date) { [weak self] in
                    guard let self, generation == self.displayGeneration else { return }
                    self.displayTimer = nil
                    self.displayDate = nil
                    self.displayFireCount += 1
                    self.onDisplay?()
                }
            }
        }
    }

    func cancel() {
        schedule(CountdownPlan(deadline: nil, display: nil))
    }

    deinit {
        deadlineTimer?.cancel()
        displayTimer?.cancel()
    }
}
