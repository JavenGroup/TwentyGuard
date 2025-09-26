import Cocoa

class SimpleStatsWindow: NSWindow {
    
    private let analyzer = HealthAnalyzer.shared
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
        
        // 异步加载数据
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            let todayStats = self.analyzer.getTodayHealthStats()
            let weeklyTrend = self.analyzer.getWeeklyHealthTrend()
            let intensivePeriods = self.analyzer.getTodayIntensiveWorkPeriods()
            
            DispatchQueue.main.async {
                containerView.subviews.forEach { $0.removeFromSuperview() }
                self.displayContent(in: containerView, todayStats: todayStats, weeklyTrend: weeklyTrend, intensivePeriods: intensivePeriods)
            }
        }
    }
    
    private func displayContent(in containerView: NSView, todayStats: DailyHealthStats?, weeklyTrend: WeeklyHealthTrend?, intensivePeriods: [IntensiveWorkPeriod]) {
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
            // 平均休息间隔
            let intervalMinutes = Int(stats.averageRestInterval / 60)
            let intervalStatus = intervalMinutes <= 30 ? "✅" : "⚠️"
            let intervalLabel = createDataRow(
                label: "平均休息间隔：",
                value: "\(intervalMinutes) 分钟",
                status: intervalStatus
            )
            intervalLabel.frame = NSRect(x: 30, y: yPos, width: 360, height: 20)
            containerView.addSubview(intervalLabel)
            
            yPos -= 24
            
            // 最长连续用眼
            let longestHours = stats.longestContinuousWork / 3600
            let longestStatus = longestHours <= 1.5 ? "✅" : "🔴"
            let longestLabel = createDataRow(
                label: "最长连续用眼：",
                value: String(format: "%.1f 小时", longestHours),
                status: longestStatus
            )
            longestLabel.frame = NSRect(x: 30, y: yPos, width: 360, height: 20)
            containerView.addSubview(longestLabel)
            
            yPos -= 24
            
            // 完整休息次数
            let breaksLabel = createDataRow(
                label: "完整休息次数：",
                value: "\(stats.completedBreaks) 次",
                status: ""
            )
            breaksLabel.frame = NSRect(x: 30, y: yPos, width: 360, height: 20)
            containerView.addSubview(breaksLabel)
            
            yPos -= 24
            
            // 推迟率
            let postponeRate = Int(stats.postponeRate * 100)
            let postponeStatus = postponeRate <= 30 ? "✅" : "⚠️"
            let postponeLabel = createDataRow(
                label: "推迟率：",
                value: "\(postponeRate)%",
                status: postponeStatus
            )
            postponeLabel.frame = NSRect(x: 30, y: yPos, width: 360, height: 20)
            containerView.addSubview(postponeLabel)
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
        
        // 高强度时段标题
        let intensiveTitle = createLabel("⏰ 高强度用眼时段", fontSize: 15, weight: .semibold)
        intensiveTitle.frame = NSRect(x: 20, y: yPos, width: 360, height: 20)
        containerView.addSubview(intensiveTitle)
        
        yPos -= 30
        
        if intensivePeriods.isEmpty {
            let goodLabel = createLabel("✅ 今日无超长连续用眼", fontSize: 14, color: .systemGreen)
            goodLabel.frame = NSRect(x: 30, y: yPos, width: 340, height: 20)
            containerView.addSubview(goodLabel)
            yPos -= 25
        } else {
            for period in intensivePeriods.prefix(2) {
                let periodStatus = period.durationHours > 2.5 ? "🔴" : "🟡"
                let periodLabel = createDataRow(
                    label: "\(periodStatus) \(period.hourRange)",
                    value: String(format: "连续 %.1f 小时", period.durationHours),
                    status: ""
                )
                periodLabel.frame = NSRect(x: 30, y: yPos, width: 360, height: 20)
                containerView.addSubview(periodLabel)
                yPos -= 24
            }
        }
        
        yPos -= 10
        
        // 分割线
        let separator3 = createSeparator()
        separator3.frame = NSRect(x: 20, y: yPos, width: 380, height: 1)
        containerView.addSubview(separator3)
        
        yPos -= 25
        
        // 本周趋势标题
        let trendTitle = createLabel("📈 本周改善趋势", fontSize: 15, weight: .semibold)
        trendTitle.frame = NSRect(x: 20, y: yPos, width: 360, height: 20)
        containerView.addSubview(trendTitle)
        
        yPos -= 30
        
        if let trend = weeklyTrend {
            // 推迟率对比
            let currentPostpone = Int(trend.currentWeek.averagePostponeRate * 100)
            let previousPostpone = Int(trend.previousWeek.averagePostponeRate * 100)
            let postponeImproved = currentPostpone < previousPostpone
            let postponeArrow = postponeImproved ? "✅" : "📉"
            
            let postponeTrend = createDataRow(
                label: "推迟率：",
                value: "\(previousPostpone)% → \(currentPostpone)%",
                status: postponeArrow
            )
            postponeTrend.frame = NSRect(x: 30, y: yPos, width: 360, height: 20)
            containerView.addSubview(postponeTrend)
            
            yPos -= 24
            
            // 休息间隔对比
            let currentInterval = Int(trend.currentWeek.averageRestInterval / 60)
            let previousInterval = Int(trend.previousWeek.averageRestInterval / 60)
            let intervalImproved = currentInterval < previousInterval
            let intervalArrow = intervalImproved ? "✅" : "📉"
            
            let intervalTrend = createDataRow(
                label: "休息间隔：",
                value: "\(previousInterval)分 → \(currentInterval)分",
                status: intervalArrow
            )
            intervalTrend.frame = NSRect(x: 30, y: yPos, width: 360, height: 20)
            containerView.addSubview(intervalTrend)
            
            yPos -= 24
            
            // 连续天数
            let consecutiveLabel = createLabel(
                "🔥 连续健康使用 \(trend.consecutiveHealthyDays) 天",
                fontSize: 14,
                color: .systemOrange
            )
            consecutiveLabel.frame = NSRect(x: 30, y: yPos, width: 360, height: 20)
            containerView.addSubview(consecutiveLabel)
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