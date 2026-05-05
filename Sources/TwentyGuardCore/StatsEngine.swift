import Foundation

public enum StatsRecordStatus: String, Codable, Equatable, Sendable {
    case active
    case completed
    case interrupted
    case unknown
}

public enum StatsSessionStatus: String, Codable, Equatable, Sendable {
    case active
    case completed
    case interrupted
    case unknown
}

public struct StatsPostponeRecord: Equatable, Sendable {
    public let durationSeconds: Int
    public let startTime: Date
    public let endTime: Date?
    public let status: StatsRecordStatus

    public init(durationSeconds: Int, startTime: Date, endTime: Date?, status: StatsRecordStatus) {
        self.durationSeconds = durationSeconds
        self.startTime = startTime
        self.endTime = endTime
        self.status = status
    }
}

public struct StatsBreakRecord: Equatable, Sendable {
    public let plannedDurationSeconds: Int
    public let actualDurationSeconds: Int?
    public let startTime: Date
    public let endTime: Date?
    public let status: StatsRecordStatus

    public init(
        plannedDurationSeconds: Int,
        actualDurationSeconds: Int?,
        startTime: Date,
        endTime: Date?,
        status: StatsRecordStatus
    ) {
        self.plannedDurationSeconds = plannedDurationSeconds
        self.actualDurationSeconds = actualDurationSeconds
        self.startTime = startTime
        self.endTime = endTime
        self.status = status
    }
}

public struct StatsSessionRecord: Equatable, Sendable {
    public let id: Int64
    public let startTime: Date
    public let endTime: Date?
    public let plannedDurationSeconds: Int
    public let actualWorkDurationSeconds: Int?
    public let recordedPostponeCount: Int?
    public let postponeTotalDurationSeconds: Int
    public let postpones: [StatsPostponeRecord]
    public let breakRecord: StatsBreakRecord?
    public let breakCompleted: Bool
    public let status: StatsSessionStatus

    public init(
        id: Int64,
        startTime: Date,
        endTime: Date?,
        plannedDurationSeconds: Int,
        actualWorkDurationSeconds: Int?,
        recordedPostponeCount: Int? = nil,
        postponeTotalDurationSeconds: Int,
        postpones: [StatsPostponeRecord],
        breakRecord: StatsBreakRecord?,
        breakCompleted: Bool,
        status: StatsSessionStatus
    ) {
        self.id = id
        self.startTime = startTime
        self.endTime = endTime
        self.plannedDurationSeconds = plannedDurationSeconds
        self.actualWorkDurationSeconds = actualWorkDurationSeconds
        self.recordedPostponeCount = recordedPostponeCount
        self.postponeTotalDurationSeconds = postponeTotalDurationSeconds
        self.postpones = postpones
        self.breakRecord = breakRecord
        self.breakCompleted = breakCompleted
        self.status = status
    }
}

public struct StatsQualitySummary: Equatable, Sendable {
    public var ignoredShortSessions: Int
    public var excludedStaleSessions: Int
    public var excludedStaleSessionIDs: [Int64]
    public var activeBreakRecords: Int
    public var interruptedBreakRecords: Int
    public var unclosedPostponeRecords: Int

    public init(
        ignoredShortSessions: Int = 0,
        excludedStaleSessions: Int = 0,
        excludedStaleSessionIDs: [Int64] = [],
        activeBreakRecords: Int = 0,
        interruptedBreakRecords: Int = 0,
        unclosedPostponeRecords: Int = 0
    ) {
        self.ignoredShortSessions = ignoredShortSessions
        self.excludedStaleSessions = excludedStaleSessions
        self.excludedStaleSessionIDs = excludedStaleSessionIDs
        self.activeBreakRecords = activeBreakRecords
        self.interruptedBreakRecords = interruptedBreakRecords
        self.unclosedPostponeRecords = unclosedPostponeRecords
    }

    public var hasIssues: Bool {
        ignoredShortSessions > 0 ||
            excludedStaleSessions > 0 ||
            activeBreakRecords > 0 ||
            interruptedBreakRecords > 0 ||
            unclosedPostponeRecords > 0
    }

    public mutating func merge(_ other: StatsQualitySummary) {
        ignoredShortSessions += other.ignoredShortSessions
        excludedStaleSessions += other.excludedStaleSessions
        excludedStaleSessionIDs.append(contentsOf: other.excludedStaleSessionIDs)
        activeBreakRecords += other.activeBreakRecords
        interruptedBreakRecords += other.interruptedBreakRecords
        unclosedPostponeRecords += other.unclosedPostponeRecords
    }
}

public struct StatsDaySnapshot: Equatable, Sendable {
    public let date: Date
    public let workSessions: Int
    public let breakOpportunities: Int
    public let completedBreaks: Int
    public let postponedSessions: Int
    public let totalPostpones: Int
    public let postponesByMinutes: [Int: Int]
    public let totalWorkSeconds: Int
    public let longestWorkSeconds: Int
    public let quality: StatsQualitySummary

    public init(
        date: Date,
        workSessions: Int,
        breakOpportunities: Int,
        completedBreaks: Int,
        postponedSessions: Int,
        totalPostpones: Int,
        postponesByMinutes: [Int: Int],
        totalWorkSeconds: Int,
        longestWorkSeconds: Int,
        quality: StatsQualitySummary
    ) {
        self.date = date
        self.workSessions = workSessions
        self.breakOpportunities = breakOpportunities
        self.completedBreaks = completedBreaks
        self.postponedSessions = postponedSessions
        self.totalPostpones = totalPostpones
        self.postponesByMinutes = postponesByMinutes
        self.totalWorkSeconds = totalWorkSeconds
        self.longestWorkSeconds = longestWorkSeconds
        self.quality = quality
    }

    public var breakCompletionRate: Double {
        guard breakOpportunities > 0 else { return 0 }
        return Double(completedBreaks) / Double(breakOpportunities)
    }

    public var postponeSessionRate: Double {
        guard breakOpportunities > 0 else { return 0 }
        return Double(postponedSessions) / Double(breakOpportunities)
    }

    public var isHealthyDay: Bool {
        breakOpportunities > 0 &&
            breakCompletionRate >= 0.8 &&
            postponeSessionRate <= 0.3 &&
            longestWorkSeconds <= 90 * 60 &&
            quality.excludedStaleSessions == 0
    }
}

public struct StatsWeekSnapshot: Equatable, Sendable {
    public let days: [StatsDaySnapshot]

    public init(days: [StatsDaySnapshot]) {
        self.days = days
    }

    public var totalWorkSeconds: Int {
        days.reduce(0) { $0 + $1.totalWorkSeconds }
    }

    public var totalWorkSessions: Int {
        days.reduce(0) { $0 + $1.workSessions }
    }

    public var totalBreakOpportunities: Int {
        days.reduce(0) { $0 + $1.breakOpportunities }
    }

    public var totalCompletedBreaks: Int {
        days.reduce(0) { $0 + $1.completedBreaks }
    }

    public var totalPostponedSessions: Int {
        days.reduce(0) { $0 + $1.postponedSessions }
    }

    public var totalPostpones: Int {
        days.reduce(0) { $0 + $1.totalPostpones }
    }

    public var activeDays: Int {
        days.filter { $0.workSessions > 0 || $0.breakOpportunities > 0 }.count
    }

    public var healthyDays: Int {
        days.filter(\.isHealthyDay).count
    }

    public var breakCompletionRate: Double {
        guard totalBreakOpportunities > 0 else { return 0 }
        return Double(totalCompletedBreaks) / Double(totalBreakOpportunities)
    }

    public var quality: StatsQualitySummary {
        days.reduce(into: StatsQualitySummary()) { result, day in
            result.merge(day.quality)
        }
    }
}

public struct StatsDashboardSnapshot: Equatable, Sendable {
    public let generatedAt: Date
    public let today: StatsDaySnapshot
    public let week: StatsWeekSnapshot

    public init(generatedAt: Date, today: StatsDaySnapshot, week: StatsWeekSnapshot) {
        self.generatedAt = generatedAt
        self.today = today
        self.week = week
    }
}

public struct StatsEngine: Sendable {
    private let calendar: Calendar
    private let now: Date
    private let minimumSessionDurationSeconds: Int
    private let staleSessionDurationSeconds: Int
    private let staleSessionGraceSeconds: Int

    public init(
        calendar: Calendar = .current,
        now: Date = Date(),
        minimumSessionDurationSeconds: Int = 60,
        staleSessionDurationSeconds: Int = 4 * 60 * 60,
        staleSessionGraceSeconds: Int = 30 * 60
    ) {
        self.calendar = calendar
        self.now = now
        self.minimumSessionDurationSeconds = minimumSessionDurationSeconds
        self.staleSessionDurationSeconds = staleSessionDurationSeconds
        self.staleSessionGraceSeconds = staleSessionGraceSeconds
    }

    public func dashboard(from records: [StatsSessionRecord]) -> StatsDashboardSnapshot {
        let todayStart = calendar.startOfDay(for: now)
        let weekDays = (0..<7).reversed().compactMap { offset in
            calendar.date(byAdding: .day, value: -offset, to: todayStart)
        }
        let days = weekDays.map { daySnapshot(for: $0, from: records) }
        let today = days.last ?? daySnapshot(for: todayStart, from: records)

        return StatsDashboardSnapshot(
            generatedAt: now,
            today: today,
            week: StatsWeekSnapshot(days: days)
        )
    }

    public func daySnapshot(for day: Date, from records: [StatsSessionRecord]) -> StatsDaySnapshot {
        let dayStart = calendar.startOfDay(for: day)
        guard let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) else {
            return emptyDay(date: dayStart)
        }

        var quality = StatsQualitySummary()
        var workSessions = 0
        var breakOpportunities = 0
        var completedBreaks = 0
        var postponedSessions = 0
        var totalPostpones = 0
        var postponesByMinutes: [Int: Int] = [:]
        var totalWorkSeconds = 0
        var longestWorkSeconds = 0

        for record in records where record.startTime >= dayStart && record.startTime < dayEnd {
            collectQualitySignals(from: record, into: &quality)

            let duration = effectiveDuration(for: record)
            if shouldIgnoreShort(record: record, duration: duration) {
                quality.ignoredShortSessions += 1
                continue
            }

            if isStale(record: record, duration: duration) {
                quality.excludedStaleSessions += 1
                quality.excludedStaleSessionIDs.append(record.id)
                continue
            }

            guard duration >= minimumSessionDurationSeconds else {
                continue
            }

            workSessions += 1
            totalWorkSeconds += duration
            longestWorkSeconds = max(longestWorkSeconds, duration)

            let postponeActions = max(record.postpones.count, record.recordedPostponeCount ?? 0)
            if postponeActions > 0 || record.postponeTotalDurationSeconds > 0 {
                postponedSessions += 1
            }
            totalPostpones += postponeActions

            for postpone in record.postpones {
                let minutes = max(1, postpone.durationSeconds / 60)
                postponesByMinutes[minutes, default: 0] += 1
            }

            if isBreakOpportunity(record: record, duration: duration) {
                breakOpportunities += 1
            }

            if isCompletedBreak(record) {
                completedBreaks += 1
            }
        }

        return StatsDaySnapshot(
            date: dayStart,
            workSessions: workSessions,
            breakOpportunities: breakOpportunities,
            completedBreaks: completedBreaks,
            postponedSessions: postponedSessions,
            totalPostpones: totalPostpones,
            postponesByMinutes: postponesByMinutes,
            totalWorkSeconds: totalWorkSeconds,
            longestWorkSeconds: longestWorkSeconds,
            quality: quality
        )
    }

    private func emptyDay(date: Date) -> StatsDaySnapshot {
        StatsDaySnapshot(
            date: date,
            workSessions: 0,
            breakOpportunities: 0,
            completedBreaks: 0,
            postponedSessions: 0,
            totalPostpones: 0,
            postponesByMinutes: [:],
            totalWorkSeconds: 0,
            longestWorkSeconds: 0,
            quality: StatsQualitySummary()
        )
    }

    private func effectiveDuration(for record: StatsSessionRecord) -> Int {
        if let actual = record.actualWorkDurationSeconds, actual > 0 {
            return actual
        }
        if let endTime = record.endTime {
            return max(0, Int(endTime.timeIntervalSince(record.startTime)))
        }
        if record.status == .active {
            return max(0, Int(now.timeIntervalSince(record.startTime)))
        }
        return 0
    }

    private func shouldIgnoreShort(record: StatsSessionRecord, duration: Int) -> Bool {
        duration > 0 &&
            duration < minimumSessionDurationSeconds &&
            record.status != .active
    }

    private func isStale(record: StatsSessionRecord, duration: Int) -> Bool {
        let expectedCeiling = record.plannedDurationSeconds +
            record.postponeTotalDurationSeconds +
            staleSessionGraceSeconds
        let threshold = max(staleSessionDurationSeconds, expectedCeiling)
        return duration > threshold
    }

    private func isBreakOpportunity(record: StatsSessionRecord, duration: Int) -> Bool {
        duration >= record.plannedDurationSeconds ||
            record.breakRecord != nil ||
            !record.postpones.isEmpty ||
            (record.recordedPostponeCount ?? 0) > 0 ||
            record.postponeTotalDurationSeconds > 0
    }

    private func isCompletedBreak(_ record: StatsSessionRecord) -> Bool {
        guard record.breakCompleted else { return false }
        guard let breakRecord = record.breakRecord else { return true }
        return breakRecord.status == .completed
    }

    private func collectQualitySignals(from record: StatsSessionRecord, into quality: inout StatsQualitySummary) {
        if let breakRecord = record.breakRecord {
            switch breakRecord.status {
            case .active:
                quality.activeBreakRecords += 1
            case .interrupted:
                quality.interruptedBreakRecords += 1
            case .completed, .unknown:
                break
            }
        }

        quality.unclosedPostponeRecords += record.postpones.filter { postpone in
            postpone.status == .active || postpone.endTime == nil
        }.count
    }
}
