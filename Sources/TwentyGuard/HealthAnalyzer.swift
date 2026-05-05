import Foundation

// MARK: - Health Statistics Data Models

struct DailyHealthStats {
    let date: Date
    let averageRestInterval: TimeInterval  // 平均休息间隔（秒）
    let longestContinuousWork: TimeInterval  // 最长连续用眼时间
    let completedBreaks: Int  // 完整休息次数
    let postponedBreaks: Int  // 推迟休息次数
    let totalPostponeTime: TimeInterval  // 推迟总时长
    let workSessions: Int  // 工作会话数
    
    var postponeRate: Double {
        guard (completedBreaks + postponedBreaks) > 0 else { return 0.0 }
        return Double(postponedBreaks) / Double(completedBreaks + postponedBreaks)
    }
    
    var isHealthyDay: Bool {
        // 定义健康日标准：至少休息3次，推迟率<50%，平均间隔<35分钟
        return completedBreaks >= 3 && postponeRate < 0.5 && averageRestInterval < 35 * 60
    }
}

struct WeeklyHealthTrend {
    let currentWeek: WeeklyStats
    let previousWeek: WeeklyStats
    let consecutiveHealthyDays: Int
    let totalUsageDays: Int
    
    var postponeRateImprovement: Double {
        return previousWeek.averagePostponeRate - currentWeek.averagePostponeRate
    }
    
    var restIntervalImprovement: TimeInterval {
        return previousWeek.averageRestInterval - currentWeek.averageRestInterval
    }
}

struct WeeklyStats {
    let healthyDays: Int
    let totalDays: Int
    let averageRestInterval: TimeInterval
    let averagePostponeRate: Double
    let totalBreaks: Int
    
    var healthyDayRate: Double {
        guard totalDays > 0 else { return 0.0 }
        return Double(healthyDays) / Double(totalDays)
    }
}

struct IntensiveWorkPeriod {
    let startTime: Date
    let endTime: Date
    let duration: TimeInterval
    
    var hourRange: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.timeZone = TimeZone.current
        return "\(formatter.string(from: startTime))-\(formatter.string(from: endTime))"
    }
    
    var durationHours: Double {
        return duration / 3600.0
    }
}

// MARK: - Health Analyzer

class HealthAnalyzer {
    static let shared = HealthAnalyzer()
    
    private let logManager = LogManager.shared
    private let calendar = Calendar.current
    private let fileManager = FileManager.default
    
    private init() {}
    
    // MARK: - Public Analysis Methods
    
    /// 获取今日健康统计
    func getTodayHealthStats() -> DailyHealthStats? {
        let today = Date()
        return getDailyHealthStats(for: today)
    }
    
    /// 获取指定日期的健康统计
    func getDailyHealthStats(for date: Date) -> DailyHealthStats? {
        guard let events = loadDayEvents(for: date) else {
            return nil
        }
        
        return calculateDailyStats(from: events, date: date)
    }
    
    /// 获取本周健康趋势
    func getWeeklyHealthTrend() -> WeeklyHealthTrend? {
        let today = Date()
        guard let currentWeekStats = getWeeklyStats(endDate: today),
              let previousWeekStats = getWeeklyStats(endDate: calendar.date(byAdding: .weekOfYear, value: -1, to: today)!) else {
            return nil
        }
        
        let consecutiveDays = getConsecutiveHealthyDays()
        let totalDays = getTotalUsageDays()
        
        return WeeklyHealthTrend(
            currentWeek: currentWeekStats,
            previousWeek: previousWeekStats,
            consecutiveHealthyDays: consecutiveDays,
            totalUsageDays: totalDays
        )
    }
    
    /// 获取今日高强度工作时段
    func getTodayIntensiveWorkPeriods() -> [IntensiveWorkPeriod] {
        let today = Date()
        guard let events = loadDayEvents(for: today) else {
            return []
        }
        
        return findIntensiveWorkPeriods(from: events)
    }
    
    // MARK: - Private Helper Methods
    
    private func loadDayEvents(for date: Date) -> [LogEvent]? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone.current
        let dateString = formatter.string(from: date)
        
        let logFileURL = logManager.getTodayLogFileURL().deletingLastPathComponent()
            .appendingPathComponent("\(dateString).jsonl")
        
        guard fileManager.fileExists(atPath: logFileURL.path) else {
            return nil
        }
        
        do {
            let content = try String(contentsOf: logFileURL)
            let lines = content.components(separatedBy: .newlines).filter { !$0.isEmpty }
            
            var events: [LogEvent] = []
            let decoder = JSONDecoder()
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
            dateFormatter.timeZone = TimeZone.current
            decoder.dateDecodingStrategy = .formatted(dateFormatter)
            
            // 只解析我们需要的事件类型，提高性能
            let relevantEventTypes: Set<String> = [
                "work_started", "work_completed", "work_paused",
                "break_started", "break_completed", "break_postponed"
            ]
            
            for line in lines {
                // 快速检查是否包含相关事件类型
                var isRelevant = false
                for eventType in relevantEventTypes {
                    if line.contains("\"\(eventType)\"") {
                        isRelevant = true
                        break
                    }
                }
                
                if isRelevant,
                   let data = line.data(using: .utf8),
                   let event = try? decoder.decode(LogEvent.self, from: data) {
                    events.append(event)
                }
            }
            
            return events.sorted { $0.timestamp < $1.timestamp }
        } catch {
            print("❌ Failed to load events for \(dateString): \(error)")
            return nil
        }
    }
    
    private func calculateDailyStats(from events: [LogEvent], date: Date) -> DailyHealthStats {
        var workStartTimes: [Date] = []
        var breakStartTimes: [Date] = []
        var completedBreaks = 0
        var postponedBreaks = 0
        var totalPostponeTime: TimeInterval = 0
        var workIntervals: [TimeInterval] = []
        
        for event in events {
            switch event.eventType {
            case .workStarted:
                workStartTimes.append(event.timestamp)
                
            case .breakStarted:
                breakStartTimes.append(event.timestamp)
                // 计算工作间隔
                if let lastWorkStart = workStartTimes.last {
                    let workDuration = event.timestamp.timeIntervalSince(lastWorkStart)
                    if workDuration > 0 && workDuration < 4 * 3600 { // 过滤异常值
                        workIntervals.append(workDuration)
                    }
                }
                
            case .breakCompleted:
                completedBreaks += 1
                
            case .breakPostponed:
                postponedBreaks += 1
                if let partialDuration = event.duration {
                    totalPostponeTime += partialDuration
                }
                
            default:
                break
            }
        }
        
        // 计算统计数据
        let averageRestInterval = workIntervals.isEmpty ? 0 : workIntervals.reduce(0, +) / Double(workIntervals.count)
        let longestContinuousWork = workIntervals.max() ?? 0
        let workSessions = workStartTimes.count
        
        return DailyHealthStats(
            date: date,
            averageRestInterval: averageRestInterval,
            longestContinuousWork: longestContinuousWork,
            completedBreaks: completedBreaks,
            postponedBreaks: postponedBreaks,
            totalPostponeTime: totalPostponeTime,
            workSessions: workSessions
        )
    }
    
    private func getWeeklyStats(endDate: Date) -> WeeklyStats? {
        let startDate = calendar.date(byAdding: .day, value: -6, to: endDate)!
        var healthyDays = 0
        var totalDays = 0
        var allRestIntervals: [TimeInterval] = []
        var allPostponeRates: [Double] = []
        var totalBreaks = 0
        
        for i in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: i, to: startDate),
                  let dayStats = getDailyHealthStats(for: date) else {
                continue
            }
            
            totalDays += 1
            totalBreaks += dayStats.completedBreaks + dayStats.postponedBreaks
            
            if dayStats.isHealthyDay {
                healthyDays += 1
            }
            
            if dayStats.averageRestInterval > 0 {
                allRestIntervals.append(dayStats.averageRestInterval)
            }
            
            allPostponeRates.append(dayStats.postponeRate)
        }
        
        let averageRestInterval = allRestIntervals.isEmpty ? 0 : allRestIntervals.reduce(0, +) / Double(allRestIntervals.count)
        let averagePostponeRate = allPostponeRates.isEmpty ? 0 : allPostponeRates.reduce(0, +) / Double(allPostponeRates.count)
        
        return WeeklyStats(
            healthyDays: healthyDays,
            totalDays: totalDays,
            averageRestInterval: averageRestInterval,
            averagePostponeRate: averagePostponeRate,
            totalBreaks: totalBreaks
        )
    }
    
    private func getConsecutiveHealthyDays() -> Int {
        let today = Date()
        var consecutiveDays = 0
        
        // 限制检查范围到最多7天，避免过度计算
        for i in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: -i, to: today),
                  let dayStats = getDailyHealthStats(for: date) else {
                break
            }
            
            if dayStats.isHealthyDay {
                consecutiveDays += 1
            } else {
                break
            }
        }
        
        return consecutiveDays
    }
    
    private func getTotalUsageDays() -> Int {
        // 简化实现：只检查过去7天，避免性能问题
        let today = Date()
        var usageDays = 0
        
        for i in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: -i, to: today) else {
                break
            }
            
            // 只检查文件是否存在，不加载完整数据
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            formatter.timeZone = TimeZone.current
            let dateString = formatter.string(from: date)
            let logFileURL = logManager.getTodayLogFileURL().deletingLastPathComponent()
                .appendingPathComponent("\(dateString).jsonl")
            
            if fileManager.fileExists(atPath: logFileURL.path) {
                usageDays += 1
            }
        }
        
        return usageDays
    }
    
    private func findIntensiveWorkPeriods(from events: [LogEvent]) -> [IntensiveWorkPeriod] {
        var periods: [IntensiveWorkPeriod] = []
        var currentWorkStart: Date?
        
        for event in events {
            switch event.eventType {
            case .workStarted:
                currentWorkStart = event.timestamp
                
            case .breakStarted:
                if let workStart = currentWorkStart {
                    let duration = event.timestamp.timeIntervalSince(workStart)
                    // 连续工作超过90分钟定义为高强度
                    if duration > 90 * 60 {
                        let period = IntensiveWorkPeriod(
                            startTime: workStart,
                            endTime: event.timestamp,
                            duration: duration
                        )
                        periods.append(period)
                    }
                }
                currentWorkStart = nil
                
            case .workPaused, .workCompleted:
                currentWorkStart = nil
                
            default:
                break
            }
        }
        
        return periods
    }
}

// MARK: - Formatting Extensions

extension TimeInterval {
    var minutesString: String {
        let minutes = Int(self / 60)
        return "\(minutes) 分钟"
    }
    
    var hoursString: String {
        let hours = self / 3600
        return String(format: "%.1f 小时", hours)
    }
}

extension Double {
    var percentageString: String {
        return String(format: "%.0f%%", self * 100)
    }
}