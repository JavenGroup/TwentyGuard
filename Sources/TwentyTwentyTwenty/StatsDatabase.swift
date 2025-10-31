import Foundation
import SQLite3
import AppKit

// MARK: - Data Models

struct SessionRecord {
    let id: Int64
    let type: SessionType
    let startTime: Date
    let endTime: Date?
    let plannedDuration: Int
    let actualDuration: Int?
    let postponeCount: Int
    let postpone1Min: Int
    let postpone2Min: Int
    let postpone5Min: Int
    let totalPostponeDuration: Int
    let status: SessionStatus

    enum SessionType: String {
        case work = "work"
        case breakTime = "break"  // 'break' is reserved keyword
    }

    enum SessionStatus: String {
        case active = "active"
        case completed = "completed"
        case interrupted = "interrupted"
    }
}

struct DailyStats {
    let date: Date
    let workSessions: Int
    let breakSessions: Int
    let totalPostpones: Int
    let postpone1MinCount: Int
    let postpone2MinCount: Int
    let postpone5MinCount: Int
    let totalWorkMinutes: Int
    let totalBreakMinutes: Int
    let longestWorkMinutes: Int
    let avgPostponesPerSession: Double
}

// MARK: - Database Errors

enum DatabaseError: Error {
    case connectionFailed
    case queryFailed(String)
    case transactionFailed
    case invalidState
}

// MARK: - StatsDatabase

class StatsDatabase {
    static let shared = StatsDatabase()

    private var db: OpaquePointer?
    private let dbQueue = DispatchQueue(label: "com.twentytwentytwenty.database", qos: .userInitiated)
    private let fileManager = FileManager.default
    private var isValid = false

    private var databaseURL: URL {
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appFolder = appSupport.appendingPathComponent("com.twentytwentytwenty")
        try? fileManager.createDirectory(at: appFolder, withIntermediateDirectories: true)
        return appFolder.appendingPathComponent("20_20_20_stats.db")
    }

    private init() {
        setupDatabase()
        registerForAppTermination()
    }

    deinit {
        closeDatabase()
    }

    // MARK: - Database Setup

    private func setupDatabase() {
        do {
            try openDatabase()
            try createTables()
            isValid = true
            print("✅ Database setup completed successfully")
        } catch {
            print("❌ Database setup failed: \(error)")
            // Try to recover by creating tables manually
            if db != nil {
                createTablesManually()
            }
        }
    }

    private func createTablesManually() {
        // Direct table creation without error throwing
        let tables = [
            """
            CREATE TABLE IF NOT EXISTS sessions (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                type TEXT CHECK(type IN ('work', 'break')) NOT NULL,
                start_time REAL NOT NULL,
                end_time REAL,
                planned_duration INTEGER NOT NULL,
                actual_duration INTEGER,
                postpone_count INTEGER DEFAULT 0,
                postpone_1min INTEGER DEFAULT 0,
                postpone_2min INTEGER DEFAULT 0,
                postpone_5min INTEGER DEFAULT 0,
                postpone_total_minutes INTEGER DEFAULT 0,
                status TEXT DEFAULT 'active',
                created_at REAL DEFAULT (strftime('%s', 'now'))
            )
            """,
            """
            CREATE TABLE IF NOT EXISTS postpone_events (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                session_id INTEGER NOT NULL,
                postpone_minutes INTEGER NOT NULL,
                timestamp REAL NOT NULL,
                FOREIGN KEY (session_id) REFERENCES sessions(id)
            )
            """,
            """
            CREATE TABLE IF NOT EXISTS daily_summary (
                date TEXT PRIMARY KEY,
                work_sessions INTEGER DEFAULT 0,
                break_sessions INTEGER DEFAULT 0,
                total_work_minutes INTEGER DEFAULT 0,
                total_break_minutes INTEGER DEFAULT 0,
                total_postpones INTEGER DEFAULT 0,
                postpone_1min_count INTEGER DEFAULT 0,
                postpone_2min_count INTEGER DEFAULT 0,
                postpone_5min_count INTEGER DEFAULT 0,
                longest_work_minutes INTEGER DEFAULT 0,
                longest_break_minutes INTEGER DEFAULT 0,
                updated_at REAL DEFAULT (strftime('%s', 'now'))
            )
            """
        ]

        for sql in tables {
            sqlite3_exec(db, sql, nil, nil, nil)
        }

        isValid = true
        print("✅ Database tables created manually, database is now valid")
    }

    private func openDatabase() throws {
        let dbPath = databaseURL.path

        if sqlite3_open_v2(dbPath, &db, SQLITE_OPEN_CREATE | SQLITE_OPEN_READWRITE | SQLITE_OPEN_FULLMUTEX, nil) != SQLITE_OK {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            print("❌ Unable to open database: \(errorMessage)")
            throw DatabaseError.connectionFailed
        }

        // Enable foreign keys and WAL mode for better concurrency
        try executeSQL("PRAGMA foreign_keys = ON")
        try executeSQL("PRAGMA journal_mode = WAL")

        print("✅ Database opened successfully at \(dbPath)")
    }

    private func closeDatabase() {
        if db != nil {
            sqlite3_close(db)
            db = nil
            isValid = false
            print("📊 Database closed")
        }
    }

    private func registerForAppTermination() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppTermination),
            name: NSApplication.willTerminateNotification,
            object: nil
        )
    }

    @objc private func handleAppTermination() {
        closeDatabase()
    }

    private func createTables() throws {
        let createSessionsTable = """
            CREATE TABLE IF NOT EXISTS sessions (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                type TEXT CHECK(type IN ('work', 'break')) NOT NULL,
                start_time REAL NOT NULL,
                end_time REAL,
                planned_duration INTEGER NOT NULL,
                actual_duration INTEGER,
                postpone_count INTEGER DEFAULT 0,
                postpone_1min INTEGER DEFAULT 0,
                postpone_2min INTEGER DEFAULT 0,
                postpone_5min INTEGER DEFAULT 0,
                total_postpone_duration INTEGER DEFAULT 0,
                status TEXT CHECK(status IN ('active', 'completed', 'interrupted')) DEFAULT 'active',
                created_at REAL DEFAULT (julianday('now'))
            )
        """

        let createPostponeEventsTable = """
            CREATE TABLE IF NOT EXISTS postpone_events (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                session_id INTEGER REFERENCES sessions(id) ON DELETE CASCADE,
                postpone_time REAL NOT NULL,
                postpone_minutes INTEGER NOT NULL,
                created_at REAL DEFAULT (julianday('now'))
            )
        """

        let createDailySummaryTable = """
            CREATE TABLE IF NOT EXISTS daily_summary (
                date TEXT PRIMARY KEY,
                work_sessions INTEGER DEFAULT 0,
                break_sessions INTEGER DEFAULT 0,
                total_postpones INTEGER DEFAULT 0,
                postpone_1min_count INTEGER DEFAULT 0,
                postpone_2min_count INTEGER DEFAULT 0,
                postpone_5min_count INTEGER DEFAULT 0,
                total_work_minutes INTEGER DEFAULT 0,
                total_break_minutes INTEGER DEFAULT 0,
                longest_work_minutes INTEGER DEFAULT 0,
                avg_postpones_per_session REAL DEFAULT 0,
                updated_at REAL DEFAULT (julianday('now'))
            )
        """

        // Create indices
        let indices = [
            "CREATE INDEX IF NOT EXISTS idx_sessions_date ON sessions(date(start_time, 'unixepoch'))",
            "CREATE INDEX IF NOT EXISTS idx_sessions_type ON sessions(type)",
            "CREATE INDEX IF NOT EXISTS idx_sessions_status ON sessions(status)",
            "CREATE INDEX IF NOT EXISTS idx_sessions_start_time ON sessions(start_time)",
            "CREATE INDEX IF NOT EXISTS idx_postpone_session ON postpone_events(session_id)"
        ]

        try dbQueue.sync {
            try executeSQL(createSessionsTable)
            try executeSQL(createPostponeEventsTable)
            try executeSQL(createDailySummaryTable)

            for index in indices {
                try executeSQL(index)
            }
        }
    }

    private func executeSQL(_ sql: String) throws {
        guard isValid else { throw DatabaseError.invalidState }

        if sqlite3_exec(db, sql, nil, nil, nil) != SQLITE_OK {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            print("❌ SQL Error: \(errorMessage)")
            print("   SQL: \(sql)")
            throw DatabaseError.queryFailed(errorMessage)
        }
    }

    // MARK: - Transaction Support

    private func withTransaction<T>(_ block: () throws -> T) throws -> T {
        try executeSQL("BEGIN TRANSACTION")
        do {
            let result = try block()
            try executeSQL("COMMIT")
            return result
        } catch {
            try executeSQL("ROLLBACK")
            throw error
        }
    }

    // MARK: - Core Session Management

    func startWorkSession(plannedDuration: Int, completion: @escaping (Result<Int64, Error>) -> Void) {
        dbQueue.async { [weak self] in
            guard let self = self, self.isValid else {
                completion(.failure(DatabaseError.invalidState))
                return
            }

            do {
                let sessionId = try self.withTransaction {
                    // End any active sessions first
                    try self.endActiveSessionInternal()

                    let sql = """
                        INSERT INTO sessions (type, start_time, planned_duration, status)
                        VALUES ('work', ?, ?, 'active')
                    """

                    var statement: OpaquePointer?
                    defer { sqlite3_finalize(statement) }

                    guard sqlite3_prepare_v2(self.db, sql, -1, &statement, nil) == SQLITE_OK else {
                        throw DatabaseError.queryFailed("Failed to prepare work session insert")
                    }

                    let now = Date().timeIntervalSince1970
                    sqlite3_bind_double(statement, 1, now)
                    sqlite3_bind_int(statement, 2, Int32(plannedDuration))

                    guard sqlite3_step(statement) == SQLITE_DONE else {
                        throw DatabaseError.queryFailed("Failed to insert work session")
                    }

                    let sessionId = sqlite3_last_insert_rowid(self.db)
                    print("📊 Started work session #\(sessionId)")
                    return sessionId
                }
                completion(.success(sessionId))
            } catch {
                completion(.failure(error))
            }
        }
    }

    func startWorkSession(plannedDuration: Int) -> Int64? {
        var result: Int64?
        let semaphore = DispatchSemaphore(value: 0)

        startWorkSession(plannedDuration: plannedDuration) { res in
            switch res {
            case .success(let id):
                result = id
                print("✅ Database: Work session created with id \(id)")
            case .failure(let error):
                print("❌ Database: Failed to create work session - \(error)")
            }
            semaphore.signal()
        }

        semaphore.wait()
        return result
    }

    func startBreakSession(plannedDuration: Int, completion: @escaping (Result<Int64, Error>) -> Void) {
        dbQueue.async { [weak self] in
            guard let self = self, self.isValid else {
                completion(.failure(DatabaseError.invalidState))
                return
            }

            do {
                let sessionId = try self.withTransaction {
                    // End current work session
                    try self.endActiveSessionInternal()

                    let sql = """
                        INSERT INTO sessions (type, start_time, planned_duration, status)
                        VALUES ('break', ?, ?, 'active')
                    """

                    var statement: OpaquePointer?
                    defer { sqlite3_finalize(statement) }

                    guard sqlite3_prepare_v2(self.db, sql, -1, &statement, nil) == SQLITE_OK else {
                        throw DatabaseError.queryFailed("Failed to prepare break session insert")
                    }

                    let now = Date().timeIntervalSince1970
                    sqlite3_bind_double(statement, 1, now)
                    sqlite3_bind_int(statement, 2, Int32(plannedDuration))

                    guard sqlite3_step(statement) == SQLITE_DONE else {
                        throw DatabaseError.queryFailed("Failed to insert break session")
                    }

                    let sessionId = sqlite3_last_insert_rowid(self.db)
                    print("📊 Started break session #\(sessionId)")
                    return sessionId
                }
                completion(.success(sessionId))
            } catch {
                completion(.failure(error))
            }
        }
    }

    func startBreakSession(plannedDuration: Int) -> Int64? {
        var result: Int64?
        let semaphore = DispatchSemaphore(value: 0)

        startBreakSession(plannedDuration: plannedDuration) { res in
            if case .success(let id) = res {
                result = id
            }
            semaphore.signal()
        }

        semaphore.wait()
        return result
    }

    func recordPostpone(minutes: Int) {
        dbQueue.async { [weak self] in
            guard let self = self, self.isValid else { return }

            do {
                try self.withTransaction {
                    // Get active work session
                    guard let sessionId = try self.getActiveWorkSessionIdInternal() else {
                        print("⚠️ No active work session to postpone")
                        return
                    }

                    // Update postpone counts
                    let updateSQL = """
                        UPDATE sessions
                        SET postpone_count = postpone_count + 1,
                            postpone_1min = postpone_1min + ?,
                            postpone_2min = postpone_2min + ?,
                            postpone_5min = postpone_5min + ?,
                            total_postpone_duration = total_postpone_duration + ?
                        WHERE id = ?
                    """

                    var statement: OpaquePointer?
                    defer { sqlite3_finalize(statement) }

                    guard sqlite3_prepare_v2(self.db, updateSQL, -1, &statement, nil) == SQLITE_OK else {
                        throw DatabaseError.queryFailed("Failed to prepare postpone update")
                    }

                    sqlite3_bind_int(statement, 1, minutes == 1 ? 1 : 0)
                    sqlite3_bind_int(statement, 2, minutes == 2 ? 1 : 0)
                    sqlite3_bind_int(statement, 3, minutes == 5 ? 1 : 0)
                    sqlite3_bind_int(statement, 4, Int32(minutes * 60))
                    sqlite3_bind_int64(statement, 5, sessionId)

                    guard sqlite3_step(statement) == SQLITE_DONE else {
                        throw DatabaseError.queryFailed("Failed to update postpone")
                    }

                    print("📊 Recorded \(minutes) minute postpone for session #\(sessionId)")

                    // Record postpone event
                    try self.recordPostponeEventInternal(sessionId: sessionId, minutes: minutes)
                }
            } catch {
                print("❌ Failed to record postpone: \(error)")
            }
        }
    }

    private func recordPostponeEventInternal(sessionId: Int64, minutes: Int) throws {
        let sql = """
            INSERT INTO postpone_events (session_id, postpone_time, postpone_minutes)
            VALUES (?, ?, ?)
        """

        var statement: OpaquePointer?
        defer { sqlite3_finalize(statement) }

        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            throw DatabaseError.queryFailed("Failed to prepare postpone event insert")
        }

        sqlite3_bind_int64(statement, 1, sessionId)
        sqlite3_bind_double(statement, 2, Date().timeIntervalSince1970)
        sqlite3_bind_int(statement, 3, Int32(minutes))

        guard sqlite3_step(statement) == SQLITE_DONE else {
            throw DatabaseError.queryFailed("Failed to insert postpone event")
        }
    }

    func endActiveSession() {
        dbQueue.async { [weak self] in
            guard let self = self, self.isValid else { return }

            do {
                try self.endActiveSessionInternal()
            } catch {
                print("❌ Failed to end active session: \(error)")
            }
        }
    }

    private func endActiveSessionInternal() throws {
        let sql = """
            UPDATE sessions
            SET end_time = ?,
                actual_duration = ? - start_time,
                status = 'completed'
            WHERE status = 'active'
        """

        var statement: OpaquePointer?
        defer { sqlite3_finalize(statement) }

        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            throw DatabaseError.queryFailed("Failed to prepare session end update")
        }

        let now = Date().timeIntervalSince1970
        sqlite3_bind_double(statement, 1, now)
        sqlite3_bind_double(statement, 2, now)

        guard sqlite3_step(statement) == SQLITE_DONE else {
            throw DatabaseError.queryFailed("Failed to end active session")
        }

        let changes = sqlite3_changes(db)
        if changes > 0 {
            print("📊 Ended \(changes) active session(s)")
        }
    }

    private func getActiveWorkSessionIdInternal() throws -> Int64? {
        let sql = """
            SELECT id FROM sessions
            WHERE status = 'active' AND type = 'work'
            ORDER BY start_time DESC
            LIMIT 1
        """

        var statement: OpaquePointer?
        defer { sqlite3_finalize(statement) }

        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            throw DatabaseError.queryFailed("Failed to prepare active session query")
        }

        guard sqlite3_step(statement) == SQLITE_ROW else {
            return nil
        }

        return sqlite3_column_int64(statement, 0)
    }

    // MARK: - Async Query Methods

    func getTodayStats(completion: @escaping (Result<DailyStats, Error>) -> Void) {
        dbQueue.async { [weak self] in
            guard let self = self else {
                print("❌ Database: getTodayStats - self is nil")
                completion(.failure(DatabaseError.invalidState))
                return
            }
            guard self.isValid else {
                print("❌ Database: getTodayStats - database is invalid")
                completion(.failure(DatabaseError.invalidState))
                return
            }
            print("✅ Database: getTodayStats - starting query")

            let sql = """
                SELECT
                    COUNT(CASE WHEN type = 'work' THEN 1 END) as work_sessions,
                    COUNT(CASE WHEN type = 'break' THEN 1 END) as break_sessions,
                    COALESCE(SUM(postpone_count), 0) as total_postpones,
                    COALESCE(SUM(postpone_1min), 0) as postpone_1min,
                    COALESCE(SUM(postpone_2min), 0) as postpone_2min,
                    COALESCE(SUM(postpone_5min), 0) as postpone_5min,
                    COALESCE(SUM(CASE WHEN type = 'work' THEN
                        CASE WHEN status = 'active' THEN strftime('%s', 'now') - start_time
                             ELSE actual_duration END
                    END) / 60, 0) as total_work_minutes,
                    COALESCE(SUM(CASE WHEN type = 'break' THEN
                        CASE WHEN status = 'active' THEN strftime('%s', 'now') - start_time
                             ELSE actual_duration END
                    END) / 60, 0) as total_break_minutes,
                    COALESCE(MAX(CASE WHEN type = 'work' THEN
                        CASE WHEN status = 'active' THEN strftime('%s', 'now') - start_time
                             ELSE actual_duration END
                    END) / 60, 0) as longest_work_minutes,
                    COALESCE(AVG(CASE WHEN type = 'work' THEN postpone_count END), 0) as avg_postpones
                FROM sessions
                WHERE date(start_time, 'unixepoch') = date('now')
            """

            var statement: OpaquePointer?
            defer { sqlite3_finalize(statement) }

            guard sqlite3_prepare_v2(self.db, sql, -1, &statement, nil) == SQLITE_OK else {
                completion(.failure(DatabaseError.queryFailed("Failed to prepare today stats query")))
                return
            }

            let stepResult = sqlite3_step(statement)
            print("📊 Database: getTodayStats step result = \(stepResult) (SQLITE_ROW=\(SQLITE_ROW))")

            guard stepResult == SQLITE_ROW else {
                // For aggregate queries, even with no data, we should return zero stats
                print("⚠️ Database: No row returned, creating empty stats")
                let emptyStats = DailyStats(
                    date: Date(),
                    workSessions: 0,
                    breakSessions: 0,
                    totalPostpones: 0,
                    postpone1MinCount: 0,
                    postpone2MinCount: 0,
                    postpone5MinCount: 0,
                    totalWorkMinutes: 0,
                    totalBreakMinutes: 0,
                    longestWorkMinutes: 0,
                    avgPostponesPerSession: 0
                )
                completion(.success(emptyStats))
                return
            }

            let stats = DailyStats(
                date: Date(),
                workSessions: Int(sqlite3_column_int(statement, 0)),
                breakSessions: Int(sqlite3_column_int(statement, 1)),
                totalPostpones: Int(sqlite3_column_int(statement, 2)),
                postpone1MinCount: Int(sqlite3_column_int(statement, 3)),
                postpone2MinCount: Int(sqlite3_column_int(statement, 4)),
                postpone5MinCount: Int(sqlite3_column_int(statement, 5)),
                totalWorkMinutes: Int(sqlite3_column_int(statement, 6)),
                totalBreakMinutes: Int(sqlite3_column_int(statement, 7)),
                longestWorkMinutes: Int(sqlite3_column_int(statement, 8)),
                avgPostponesPerSession: sqlite3_column_double(statement, 9)
            )

            completion(.success(stats))
        }
    }

    // Synchronous wrapper for backward compatibility
    func getTodayStats() -> DailyStats? {
        var result: DailyStats?
        let semaphore = DispatchSemaphore(value: 0)

        getTodayStats { res in
            switch res {
            case .success(let stats):
                result = stats
                print("📊 Database: getTodayStats success - work:\(stats.workSessions) postpones:\(stats.totalPostpones)")
            case .failure(let error):
                print("❌ Database: getTodayStats failed - \(error)")
            }
            semaphore.signal()
        }

        semaphore.wait()
        return result
    }

    func getWeeklyStats(completion: @escaping (Result<[(Date, DailyStats)], Error>) -> Void) {
        dbQueue.async { [weak self] in
            guard let self = self, self.isValid else {
                completion(.failure(DatabaseError.invalidState))
                return
            }

            var results: [(Date, DailyStats)] = []

            let sql = """
                SELECT
                    date(start_time, 'unixepoch') as day,
                    COUNT(CASE WHEN type = 'work' THEN 1 END) as work_sessions,
                    COUNT(CASE WHEN type = 'break' THEN 1 END) as break_sessions,
                    COALESCE(SUM(postpone_count), 0) as total_postpones,
                    COALESCE(SUM(postpone_1min), 0) as postpone_1min,
                    COALESCE(SUM(postpone_2min), 0) as postpone_2min,
                    COALESCE(SUM(postpone_5min), 0) as postpone_5min,
                    COALESCE(SUM(CASE WHEN type = 'work' THEN
                        CASE WHEN status = 'active' THEN strftime('%s', 'now') - start_time
                             ELSE actual_duration END
                    END) / 60, 0) as total_work_minutes,
                    COALESCE(SUM(CASE WHEN type = 'break' THEN
                        CASE WHEN status = 'active' THEN strftime('%s', 'now') - start_time
                             ELSE actual_duration END
                    END) / 60, 0) as total_break_minutes,
                    COALESCE(MAX(CASE WHEN type = 'work' THEN
                        CASE WHEN status = 'active' THEN strftime('%s', 'now') - start_time
                             ELSE actual_duration END
                    END) / 60, 0) as longest_work_minutes,
                    COALESCE(AVG(CASE WHEN type = 'work' THEN postpone_count END), 0) as avg_postpones
                FROM sessions
                WHERE start_time > ?
                GROUP BY day
                ORDER BY day DESC
            """

            var statement: OpaquePointer?
            defer { sqlite3_finalize(statement) }

            guard sqlite3_prepare_v2(self.db, sql, -1, &statement, nil) == SQLITE_OK else {
                completion(.failure(DatabaseError.queryFailed("Failed to prepare weekly stats query")))
                return
            }

            // Bind the date parameter (7 days ago)
            let sevenDaysAgo = Date().timeIntervalSince1970 - (7 * 24 * 3600)
            sqlite3_bind_double(statement, 1, sevenDaysAgo)

            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)

            while sqlite3_step(statement) == SQLITE_ROW {
                if let dateString = sqlite3_column_text(statement, 0),
                   let date = dateFormatter.date(from: String(cString: dateString)) {

                    let stats = DailyStats(
                        date: date,
                        workSessions: Int(sqlite3_column_int(statement, 1)),
                        breakSessions: Int(sqlite3_column_int(statement, 2)),
                        totalPostpones: Int(sqlite3_column_int(statement, 3)),
                        postpone1MinCount: Int(sqlite3_column_int(statement, 4)),
                        postpone2MinCount: Int(sqlite3_column_int(statement, 5)),
                        postpone5MinCount: Int(sqlite3_column_int(statement, 6)),
                        totalWorkMinutes: Int(sqlite3_column_int(statement, 7)),
                        totalBreakMinutes: Int(sqlite3_column_int(statement, 8)),
                        longestWorkMinutes: Int(sqlite3_column_int(statement, 9)),
                        avgPostponesPerSession: sqlite3_column_double(statement, 10)
                    )

                    results.append((date, stats))
                }
            }

            completion(.success(results))
        }
    }

    // Synchronous wrapper for backward compatibility
    func getWeeklyStats() -> [(Date, DailyStats)] {
        var result: [(Date, DailyStats)] = []
        let semaphore = DispatchSemaphore(value: 0)

        getWeeklyStats { res in
            if case .success(let stats) = res {
                result = stats
            }
            semaphore.signal()
        }

        semaphore.wait()
        return result
    }

    // MARK: - Maintenance

    func updateDailySummary() {
        dbQueue.async { [weak self] in
            guard let self = self, self.isValid else { return }

            let sql = """
                INSERT OR REPLACE INTO daily_summary (
                    date, work_sessions, break_sessions, total_postpones,
                    postpone_1min_count, postpone_2min_count, postpone_5min_count,
                    total_work_minutes, total_break_minutes, longest_work_minutes,
                    avg_postpones_per_session, updated_at
                )
                SELECT
                    date(start_time, 'unixepoch') as day,
                    COUNT(CASE WHEN type = 'work' THEN 1 END),
                    COUNT(CASE WHEN type = 'break' THEN 1 END),
                    COALESCE(SUM(postpone_count), 0),
                    COALESCE(SUM(postpone_1min), 0),
                    COALESCE(SUM(postpone_2min), 0),
                    COALESCE(SUM(postpone_5min), 0),
                    COALESCE(SUM(CASE WHEN type = 'work' THEN actual_duration END) / 60, 0),
                    COALESCE(SUM(CASE WHEN type = 'break' THEN actual_duration END) / 60, 0),
                    COALESCE(MAX(CASE WHEN type = 'work' THEN actual_duration END) / 60, 0),
                    COALESCE(AVG(CASE WHEN type = 'work' THEN postpone_count END), 0),
                    julianday('now')
                FROM sessions
                WHERE date(start_time, 'unixepoch') = date('now')
                GROUP BY day
            """

            do {
                try self.executeSQL(sql)
            } catch {
                print("❌ Failed to update daily summary: \(error)")
            }
        }
    }

    func cleanOldData(keepDays: Int = 90) {
        dbQueue.async { [weak self] in
            guard let self = self, self.isValid else { return }

            let sql = "DELETE FROM sessions WHERE start_time < ?"

            var statement: OpaquePointer?
            defer { sqlite3_finalize(statement) }

            guard sqlite3_prepare_v2(self.db, sql, -1, &statement, nil) == SQLITE_OK else {
                return
            }

            let cutoffTime = Date().timeIntervalSince1970 - Double(keepDays * 24 * 3600)
            sqlite3_bind_double(statement, 1, cutoffTime)

            if sqlite3_step(statement) == SQLITE_DONE {
                let deleted = sqlite3_changes(self.db)
                if deleted > 0 {
                    print("🗑️ Cleaned up \(deleted) old session records")
                }
            }
        }
    }

    // MARK: - Debug Methods

    func exportDatabase() -> URL? {
        let exportURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("stats_export_\(Date().timeIntervalSince1970).db")

        do {
            try FileManager.default.copyItem(at: databaseURL, to: exportURL)
            print("📊 Database exported to: \(exportURL.path)")
            return exportURL
        } catch {
            print("❌ Failed to export database: \(error)")
            return nil
        }
    }

    // MARK: - Health Check

    func isDatabaseHealthy() -> Bool {
        return isValid && db != nil
    }

    func repairDatabaseIfNeeded() {
        if !isDatabaseHealthy() {
            print("🔧 Attempting to repair database...")
            closeDatabase()
            setupDatabase()
        }
    }
}