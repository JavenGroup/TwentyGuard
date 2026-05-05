import Cocoa

class SimpleStatsWindow: NSWindow {

    private let eventRecorder = EventRecorder.shared
    private let statsDB = StatsDatabase.shared
    private var localizer: ((String) -> String)?
    
    override init(contentRect: NSRect, styleMask style: NSWindow.StyleMask, backing backingStoreType: NSWindow.BackingStoreType, defer flag: Bool) {
        super.init(contentRect: NSRect(x: 0, y: 0, width: 420, height: 480), 
                   styleMask: [.titled, .closable, .miniaturizable], 
                   backing: .buffered, 
                   defer: false)
        
        setupWindow()
        setupContent()
        centerOnMainScreen()
    }
    
    convenience init() {
        self.init(contentRect: NSRect.zero, styleMask: [.titled, .closable, .miniaturizable], backing: .buffered, defer: false)
    }
    
    private func setupWindow() {
        title = "👁️ 眼睛健康报告"
        isReleasedWhenClosed = false
        backgroundColor = NSColor.controlBackgroundColor
    }
    
    private func centerOnMainScreen() {
        // Ensure window appears on the main screen (where menu bar is)
        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            let windowFrame = self.frame
            let x = screenFrame.midX - windowFrame.width / 2
            let y = screenFrame.midY - windowFrame.height / 2
            self.setFrameOrigin(NSPoint(x: x, y: y))
        } else {
            // Fallback to center() if main screen not available
            self.center()
        }
    }
    
    func setLocalizer(_ localizer: @escaping (String) -> String) {
        self.localizer = localizer
        title = localizer("eye_health_report")
    }
    
    private func setupContent() {
        let contentView = NSView(frame: NSRect(x: 0, y: 0, width: 420, height: 480))
        contentView.wantsLayer = true
        contentView.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
        
        // 加载数据并显示
        loadDataAndDisplay(in: contentView)
        
        self.contentView = contentView
    }
    
    private func loadDataAndDisplay(in containerView: NSView) {
        // 显示加载中
        let loadingLabel = createLabel("正在加载...", fontSize: 14, color: .secondaryLabelColor)
        loadingLabel.frame = NSRect(x: 150, y: 250, width: 100, height: 20)
        containerView.addSubview(loadingLabel)

        // 异步加载数据（使用新的数据库查询）
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }

            let todayStats = self.eventRecorder.getTodayStats()
            let weeklyStats = self.eventRecorder.getWeeklyStats()

            DispatchQueue.main.async {
                containerView.subviews.forEach { $0.removeFromSuperview() }
                self.displayContent(in: containerView, todayStats: todayStats, weeklyStats: weeklyStats)
            }
        }
    }
    
    private func displayContent(in containerView: NSView, todayStats: DailyStats?, weeklyStats: [(Date, DailyStats)]) {
        var yPos: CGFloat = 440
        
        // 标题
        let titleLabel = createLabel("👁️ 眼睛健康报告", fontSize: 18, weight: .bold)
        titleLabel.frame = NSRect(x: 20, y: yPos, width: 380, height: 25)
        containerView.addSubview(titleLabel)
        
        // 日期
        let dateLabel = createLabel(getCurrentDateString(), fontSize: 12, color: .secondaryLabelColor)
        dateLabel.frame = NSRect(x: 20, y: yPos - 22, width: 360, height: 20)
        containerView.addSubview(dateLabel)
        
        yPos -= 55
        
        // 分割线
        let separator1 = createSeparator()
        separator1.frame = NSRect(x: 20, y: yPos, width: 380, height: 1)
        containerView.addSubview(separator1)
        
        yPos -= 25
        
        // 今日统计标题
        let todayTitle = createLabel("📊 今日用眼状况", fontSize: 15, weight: .semibold)
        todayTitle.frame = NSRect(x: 20, y: yPos, width: 360, height: 20)
        containerView.addSubview(todayTitle)
        
        yPos -= 30
        
        if let stats = todayStats {
            // 工作会话数
            let workSessionsLabel = createDataRow(
                label: "工作会话：",
                value: "\(stats.workSessions) 次",
                status: ""
            )
            workSessionsLabel.frame = NSRect(x: 30, y: yPos, width: 360, height: 20)
            containerView.addSubview(workSessionsLabel)

            yPos -= 24

            // 最长连续工作
            let longestMinutes = stats.longestWorkMinutes
            let longestStatus = longestMinutes <= 90 ? "✅" : "🔴"
            let longestLabel = createDataRow(
                label: "最长连续工作：",
                value: "\(longestMinutes) 分钟",
                status: longestStatus
            )
            longestLabel.frame = NSRect(x: 30, y: yPos, width: 360, height: 20)
            containerView.addSubview(longestLabel)

            yPos -= 24

            // 完成休息次数
            let breaksLabel = createDataRow(
                label: "完成休息次数：",
                value: "\(stats.breakSessions) 次",
                status: ""
            )
            breaksLabel.frame = NSRect(x: 30, y: yPos, width: 360, height: 20)
            containerView.addSubview(breaksLabel)

            yPos -= 24

            // 推迟情况
            let postponeRate = stats.totalPostpones > 0 ? Double(stats.totalPostpones) / Double(stats.workSessions) * 100 : 0
            let postponeStatus = postponeRate <= 30 ? "✅" : "⚠️"
            let postponeLabel = createDataRow(
                label: "推迟次数：",
                value: "\(stats.totalPostpones) 次 (\(Int(postponeRate))%)",
                status: postponeStatus
            )
            postponeLabel.frame = NSRect(x: 30, y: yPos, width: 360, height: 20)
            containerView.addSubview(postponeLabel)

            yPos -= 24

            // 推迟细节
            if stats.totalPostpones > 0 {
                let detailText = "1分钟:\(stats.postpone1MinCount)次 2分钟:\(stats.postpone2MinCount)次 5分钟:\(stats.postpone5MinCount)次"
                let detailLabel = createLabel(detailText, fontSize: 11, color: .secondaryLabelColor)
                detailLabel.frame = NSRect(x: 50, y: yPos, width: 340, height: 18)
                containerView.addSubview(detailLabel)
                yPos -= 22
            }
        } else {
            let noDataLabel = createLabel("暂无今日数据", fontSize: 14, color: .tertiaryLabelColor)
            noDataLabel.frame = NSRect(x: 30, y: yPos, width: 340, height: 20)
            containerView.addSubview(noDataLabel)
        }
        
        yPos -= 35
        
        // 分割线
        let separator2 = createSeparator()
        separator2.frame = NSRect(x: 20, y: yPos, width: 380, height: 1)
        containerView.addSubview(separator2)
        
        yPos -= 25
        
        // 高强度时段标题（基于数据库的最长工作时长）
        let intensiveTitle = createLabel("⏰ 今日最长工作时段", fontSize: 15, weight: .semibold)
        intensiveTitle.frame = NSRect(x: 20, y: yPos, width: 360, height: 20)
        containerView.addSubview(intensiveTitle)

        yPos -= 30

        if let stats = todayStats, stats.longestWorkMinutes > 0 {
            let hours = stats.longestWorkMinutes / 60
            let minutes = stats.longestWorkMinutes % 60
            let timeText = hours > 0 ? String(format: "%d小时%d分钟", hours, minutes) : "\(minutes)分钟"
            let status = stats.longestWorkMinutes > 90 ? "🔴" : stats.longestWorkMinutes > 60 ? "🟡" : "✅"

            let periodLabel = createDataRow(
                label: "最长连续：",
                value: timeText,
                status: status
            )
            periodLabel.frame = NSRect(x: 30, y: yPos, width: 360, height: 20)
            containerView.addSubview(periodLabel)
            yPos -= 25
        } else {
            let goodLabel = createLabel("✅ 今日无超长连续工作", fontSize: 14, color: .systemGreen)
            goodLabel.frame = NSRect(x: 30, y: yPos, width: 340, height: 20)
            containerView.addSubview(goodLabel)
            yPos -= 25
        }
        
        yPos -= 10
        
        // 分割线
        let separator3 = createSeparator()
        separator3.frame = NSRect(x: 20, y: yPos, width: 380, height: 1)
        containerView.addSubview(separator3)
        
        yPos -= 25
        
        // 本周趋势标题
        let trendTitle = createLabel("📈 本周统计", fontSize: 15, weight: .semibold)
        trendTitle.frame = NSRect(x: 20, y: yPos, width: 360, height: 20)
        containerView.addSubview(trendTitle)

        yPos -= 30

        if !weeklyStats.isEmpty {
            // 计算本周汇总数据
            var totalWorkSessions = 0
            var totalBreakSessions = 0
            var totalPostpones = 0
            var healthyDays = 0

            for (_, dayStats) in weeklyStats {
                totalWorkSessions += dayStats.workSessions
                totalBreakSessions += dayStats.breakSessions
                totalPostpones += dayStats.totalPostpones

                // 定义健康日标准：至少休息3次，推迟率<50%
                let postponeRate = dayStats.workSessions > 0 ? Double(dayStats.totalPostpones) / Double(dayStats.workSessions) : 0
                if dayStats.breakSessions >= 3 && postponeRate < 0.5 {
                    healthyDays += 1
                }
            }

            // 工作总时长
            let totalWorkMinutes = weeklyStats.reduce(0) { $0 + $1.1.totalWorkMinutes }
            let workHours = totalWorkMinutes / 60
            let workLabel = createDataRow(
                label: "总工作时长：",
                value: "\(workHours) 小时",
                status: ""
            )
            workLabel.frame = NSRect(x: 30, y: yPos, width: 360, height: 20)
            containerView.addSubview(workLabel)

            yPos -= 24

            // 健康天数
            let healthyDaysLabel = createDataRow(
                label: "健康天数：",
                value: "\(healthyDays)/\(weeklyStats.count) 天",
                status: healthyDays >= 5 ? "🎉" : ""
            )
            healthyDaysLabel.frame = NSRect(x: 30, y: yPos, width: 360, height: 20)
            containerView.addSubview(healthyDaysLabel)

            yPos -= 24

            // 周推迟统计
            let avgPostponeRate = totalWorkSessions > 0 ? Double(totalPostpones) / Double(totalWorkSessions) * 100 : 0
            let postponeLabel = createDataRow(
                label: "周推迟率：",
                value: String(format: "%.0f%%", avgPostponeRate),
                status: avgPostponeRate <= 30 ? "✅" : "⚠️"
            )
            postponeLabel.frame = NSRect(x: 30, y: yPos, width: 360, height: 20)
            containerView.addSubview(postponeLabel)
        } else {
            let noDataLabel = createLabel("暂无趋势数据", fontSize: 14, color: .tertiaryLabelColor)
            noDataLabel.frame = NSRect(x: 30, y: yPos, width: 340, height: 20)
            containerView.addSubview(noDataLabel)
        }
        
        // 关闭按钮
        let closeButton = NSButton(title: "关闭", target: self, action: #selector(closeWindow))
        closeButton.bezelStyle = .rounded
        closeButton.frame = NSRect(x: 160, y: 20, width: 80, height: 30)
        containerView.addSubview(closeButton)
    }
    
    // MARK: - Helper Methods
    
    private func createLabel(_ text: String, fontSize: CGFloat, weight: NSFont.Weight = .regular, color: NSColor = .labelColor) -> NSTextField {
        let label = NSTextField(labelWithString: text)
        label.font = NSFont.systemFont(ofSize: fontSize, weight: weight)
        label.textColor = color
        label.isEditable = false
        label.isBordered = false
        label.backgroundColor = .clear
        return label
    }
    
    private func createDataRow(label: String, value: String, status: String) -> NSView {
        let container = NSView()
        
        let labelField = createLabel(label, fontSize: 13, color: .secondaryLabelColor)
        labelField.frame = NSRect(x: 0, y: 0, width: 130, height: 20)
        container.addSubview(labelField)
        
        let valueField = createLabel(value, fontSize: 13, weight: .medium)
        valueField.frame = NSRect(x: 130, y: 0, width: 180, height: 20)
        container.addSubview(valueField)
        
        if !status.isEmpty {
            let statusField = createLabel(status, fontSize: 13)
            statusField.frame = NSRect(x: 310, y: 0, width: 30, height: 20)
            container.addSubview(statusField)
        }
        
        return container
    }
    
    private func createSeparator() -> NSView {
        let separator = NSBox()
        separator.boxType = .separator
        return separator
    }
    
    private func getCurrentDateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年MM月dd日"
        return formatter.string(from: Date())
    }
    
    @objc private func closeWindow() {
        self.close()
    }
    
    // MARK: - Window Properties
    
    override var canBecomeKey: Bool {
        return true
    }
    
    override var canBecomeMain: Bool {
        return true
    }
}