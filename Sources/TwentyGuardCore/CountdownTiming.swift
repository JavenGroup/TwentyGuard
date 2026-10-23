import Foundation

public enum CountdownPhase: Equatable {
    case work(until: Date)
    case rest(until: Date)
    case postponed(until: Date)
    case temporarilyDisabled(until: Date)
    case nightLocked(until: Date)
    case paused

    public var deadline: Date? {
        switch self {
        case .work(let date), .rest(let date), .postponed(let date),
             .temporarilyDisabled(let date), .nightLocked(let date): return date
        case .paused: return nil
        }
    }
}

public struct CountdownPlan: Equatable {
    public let deadline: Date?
    public let display: Date?

    public init(deadline: Date?, display: Date?) {
        self.deadline = deadline
        self.display = display
    }
}

/// Presentation cadence never determines when a work/break/night boundary takes effect.
public enum CountdownTiming {
    public static func secondsRemaining(until date: Date, now: Date) -> Int {
        Int(ceil(max(0, date.timeIntervalSince(now))))
    }

    public static func minutesRemaining(until date: Date, now: Date) -> Int {
        Int(ceil(max(0, date.timeIntervalSince(now)) / 60))
    }

    public static func plan(
        now: Date,
        phase: CountdownPhase,
        nightTransition: Date?,
        overrideUntil: Date?,
        showStatusCountdown: Bool,
        menuIsOpen: Bool,
        displaysAreActive: Bool
    ) -> CountdownPlan {
        let deadline = [phase.deadline, nightTransition, overrideUntil].compactMap { $0 }.min()
        return CountdownPlan(
            deadline: deadline.map { max(now, $0) },
            display: displaysAreActive ? nextDisplay(now: now, phase: phase, overrideUntil: overrideUntil,
                                                    showStatusCountdown: showStatusCountdown, menuIsOpen: menuIsOpen) : nil
        )
    }

    private static func nextDisplay(now: Date, phase: CountdownPhase, overrideUntil: Date?,
                                    showStatusCountdown: Bool, menuIsOpen: Bool) -> Date? {
        if let overrideUntil, overrideUntil > now {
            return nextChange(until: overrideUntil, now: now, unit: 1)
        }
        if menuIsOpen {
            return phase.deadline.flatMap { nextChange(until: $0, now: now, unit: 1) }
                ?? Date(timeIntervalSinceReferenceDate: floor(now.timeIntervalSinceReferenceDate) + 1)
        }
        switch phase {
        case .work(let until):
            guard showStatusCountdown else { return nil }
            return nextChange(until: until, now: now, unit: until.timeIntervalSince(now) > 60 ? 60 : 1)
        case .postponed(let until):
            return showStatusCountdown ? nextChange(until: until, now: now, unit: 1) : nil
        case .rest(let until), .temporarilyDisabled(let until), .nightLocked(let until):
            return nextChange(until: until, now: now, unit: 1)
        case .paused:
            return nil
        }
    }

    private static func nextChange(until date: Date, now: Date, unit: TimeInterval) -> Date? {
        let remaining = date.timeIntervalSince(now)
        guard remaining > 0 else { return nil }
        return date.addingTimeInterval(-(ceil(remaining / unit) - 1) * unit)
    }
}
