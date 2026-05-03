import Foundation

public enum StatsHealthVerdictSeverity: Equatable, Sendable {
    case good
    case warning
    case neutral
}

public struct StatsHealthVerdict: Equatable, Sendable {
    public let title: String
    public let reason: String
    public let severity: StatsHealthVerdictSeverity

    public init(title: String, reason: String, severity: StatsHealthVerdictSeverity) {
        self.title = title
        self.reason = reason
        self.severity = severity
    }
}

public struct StatsHealthVerdictEvaluator: Sendable {
    public init() {}

    public func verdict(for day: StatsDaySnapshot) -> StatsHealthVerdict {
        if day.workSessions == 0 && day.totalWorkSeconds == 0 {
            return StatsHealthVerdict(
                title: "暂无记录",
                reason: "今天还没有有效工作会话",
                severity: .neutral
            )
        }

        if day.longestWorkSeconds > 90 * 60 {
            return StatsHealthVerdict(
                title: "工作过长",
                reason: "最长连续工作 \(formatDuration(day.longestWorkSeconds))，超过建议上限",
                severity: .warning
            )
        }

        if day.breakOpportunities > 0 && day.breakCompletionRate < 0.8 {
            return StatsHealthVerdict(
                title: "休息不足",
                reason: "休息完成率 \(formatPercent(day.breakCompletionRate))，低于 80%",
                severity: .warning
            )
        }

        if day.breakOpportunities > 0 && day.postponeSessionRate > 0.3 {
            return StatsHealthVerdict(
                title: "推迟过多",
                reason: "推迟会话占比 \(formatPercent(day.postponeSessionRate))，高于 30%",
                severity: .warning
            )
        }

        if day.isHealthyDay {
            return StatsHealthVerdict(
                title: "节奏正常",
                reason: "休息完成率达标，连续工作没有明显超长",
                severity: .good
            )
        }

        return StatsHealthVerdict(
            title: "需要留意",
            reason: "今天有记录，但还不足以判断为健康节奏",
            severity: .neutral
        )
    }

    private func formatPercent(_ value: Double) -> String {
        "\(Int((value * 100).rounded()))%"
    }

    private func formatDuration(_ seconds: Int) -> String {
        guard seconds > 0 else { return "0 分钟" }
        let minutes = max(1, seconds / 60)
        let hours = minutes / 60
        let remainingMinutes = minutes % 60

        if hours > 0 && remainingMinutes > 0 {
            return "\(hours) 小时 \(remainingMinutes) 分钟"
        }
        if hours > 0 {
            return "\(hours) 小时"
        }
        return "\(minutes) 分钟"
    }
}
