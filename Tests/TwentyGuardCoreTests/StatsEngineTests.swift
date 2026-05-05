import XCTest
@testable import TwentyGuardCore

final class StatsEngineTests: XCTestCase {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    private func date(_ value: String) -> Date {
        let formatter = ISO8601DateFormatter()
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter.date(from: value)!
    }

    private func session(
        id: Int64,
        start: String,
        duration: Int,
        planned: Int = 20 * 60,
        status: StatsSessionStatus = .completed,
        postpones: [StatsPostponeRecord] = [],
        breakRecord: StatsBreakRecord? = nil,
        breakCompleted: Bool = false
    ) -> StatsSessionRecord {
        let startDate = date(start)
        return StatsSessionRecord(
            id: id,
            startTime: startDate,
            endTime: startDate.addingTimeInterval(TimeInterval(duration)),
            plannedDurationSeconds: planned,
            actualWorkDurationSeconds: duration,
            postponeTotalDurationSeconds: postpones.reduce(0) { $0 + $1.durationSeconds },
            postpones: postpones,
            breakRecord: breakRecord,
            breakCompleted: breakCompleted,
            status: status
        )
    }

    func testIgnoresShortRestartFragments() {
        let engine = StatsEngine(calendar: calendar, now: date("2026-04-26T12:00:00Z"))
        let snapshot = engine.dashboard(from: [
            session(id: 1, start: "2026-04-26T09:00:00Z", duration: 1),
            session(id: 2, start: "2026-04-26T09:05:00Z", duration: 20 * 60)
        ])

        XCTAssertEqual(snapshot.today.workSessions, 1)
        XCTAssertEqual(snapshot.today.quality.ignoredShortSessions, 1)
        XCTAssertEqual(snapshot.today.totalWorkSeconds, 20 * 60)
    }

    func testSeparatesPostponedSessionsFromTotalPostponeActions() {
        let engine = StatsEngine(calendar: calendar, now: date("2026-04-26T12:00:00Z"))
        let p1 = StatsPostponeRecord(durationSeconds: 60, startTime: date("2026-04-26T09:20:00Z"), endTime: nil, status: .active)
        let p2 = StatsPostponeRecord(durationSeconds: 300, startTime: date("2026-04-26T09:21:00Z"), endTime: nil, status: .active)
        let snapshot = engine.dashboard(from: [
            session(id: 1, start: "2026-04-26T09:00:00Z", duration: 26 * 60, postpones: [p1, p2])
        ])

        XCTAssertEqual(snapshot.today.postponedSessions, 1)
        XCTAssertEqual(snapshot.today.totalPostpones, 2)
        XCTAssertEqual(snapshot.today.postponesByMinutes[1], 1)
        XCTAssertEqual(snapshot.today.postponesByMinutes[5], 1)
        XCTAssertEqual(snapshot.today.quality.unclosedPostponeRecords, 2)
    }

    func testUsesSevenCalendarDaysIncludingToday() {
        let engine = StatsEngine(calendar: calendar, now: date("2026-04-26T12:00:00Z"))
        let snapshot = engine.dashboard(from: [
            session(id: 1, start: "2026-04-20T09:00:00Z", duration: 20 * 60),
            session(id: 2, start: "2026-04-19T23:59:00Z", duration: 20 * 60),
            session(id: 3, start: "2026-04-26T09:00:00Z", duration: 20 * 60)
        ])

        XCTAssertEqual(snapshot.week.days.count, 7)
        XCTAssertEqual(snapshot.week.totalWorkSeconds, 40 * 60)
        XCTAssertFalse(snapshot.week.days.contains { calendar.isDate($0.date, inSameDayAs: date("2026-04-19T00:00:00Z")) })
    }

    func testExcludesStaleLongSessionsAndReportsQualityIssue() {
        let engine = StatsEngine(calendar: calendar, now: date("2026-04-26T12:00:00Z"))
        let snapshot = engine.dashboard(from: [
            session(id: 1, start: "2026-04-26T02:00:00Z", duration: 10 * 60 * 60),
            session(id: 2, start: "2026-04-26T09:00:00Z", duration: 20 * 60)
        ])

        XCTAssertEqual(snapshot.today.workSessions, 1)
        XCTAssertEqual(snapshot.today.totalWorkSeconds, 20 * 60)
        XCTAssertEqual(snapshot.today.quality.excludedStaleSessions, 1)
        XCTAssertEqual(snapshot.today.quality.excludedStaleSessionIDs, [1])
    }

    func testCompletionRateUsesBreakOpportunities() {
        let engine = StatsEngine(calendar: calendar, now: date("2026-04-26T12:00:00Z"))
        let completedBreak = StatsBreakRecord(
            plannedDurationSeconds: 20,
            actualDurationSeconds: 22,
            startTime: date("2026-04-26T09:20:00Z"),
            endTime: date("2026-04-26T09:20:22Z"),
            status: .completed
        )
        let activeBreak = StatsBreakRecord(
            plannedDurationSeconds: 20,
            actualDurationSeconds: nil,
            startTime: date("2026-04-26T10:20:00Z"),
            endTime: nil,
            status: .active
        )

        let snapshot = engine.dashboard(from: [
            session(id: 1, start: "2026-04-26T09:00:00Z", duration: 20 * 60, breakRecord: completedBreak, breakCompleted: true),
            session(id: 2, start: "2026-04-26T10:00:00Z", duration: 20 * 60, breakRecord: activeBreak, breakCompleted: false)
        ])

        XCTAssertEqual(snapshot.today.breakOpportunities, 2)
        XCTAssertEqual(snapshot.today.completedBreaks, 1)
        XCTAssertEqual(snapshot.today.breakCompletionRate, 0.5)
        XCTAssertEqual(snapshot.today.quality.activeBreakRecords, 1)
    }
}
