import Cocoa

class ModernHealthStatsWindow: NSWindow {
    
    private let analyzer = HealthAnalyzer.shared
    private var mainContentView: NSView!
    private var localizer: ((String) -> String)?
    
    override init(contentRect: NSRect, styleMask style: NSWindow.StyleMask, backing backingStoreType: NSWindow.BackingStoreType, defer flag: Bool) {
        super.init(contentRect: NSRect(x: 0, y: 0, width: 480, height: 560), 
                   styleMask: [.titled, .closable, .miniaturizable], 
                   backing: .buffered, 
                   defer: false)
        
        setupWindow()
        setupContent()
        loadAndDisplayStats()
    }
    
    convenience init() {
        self.init(contentRect: NSRect.zero, styleMask: [.titled, .closable, .miniaturizable], backing: .buffered, defer: false)
    }
    
    private func setupWindow() {
        title = localizer?("eye_health_report") ?? "👁️ 眼睛健康报告"
        isReleasedWhenClosed = false
        titlebarAppearsTransparent = true
        
        // 设置窗口样式
        self.level = .normal
        self.backgroundColor = NSColor(calibratedWhite: 0.95, alpha: 1.0)
        
        // 设置内容视图边距
        self.contentView?.wantsLayer = true
        self.contentView?.layer?.backgroundColor = NSColor(calibratedWhite: 0.95, alpha: 1.0).cgColor
    }
    
    func setLocalizer(_ localizer: @escaping (String) -> String) {
        self.localizer = localizer
        title = localizer("eye_health_report")
    }
    
    private func setupContent() {
        mainContentView = NSView(frame: NSRect(x: 0, y: 0, width: 480, height: 560))
        mainContentView.wantsLayer = true
        self.contentView = mainContentView
    }
    
    private func loadAndDisplayStats() {
        showLoadingState()
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            let todayStats = self.analyzer.getTodayHealthStats()
            let weeklyTrend = self.analyzer.getWeeklyHealthTrend()
            let intensivePeriods = self.analyzer.getTodayIntensiveWorkPeriods()
            
            DispatchQueue.main.async {
                self.displayStats(todayStats: todayStats, weeklyTrend: weeklyTrend, intensivePeriods: intensivePeriods)
            }
        }
    }
    
    private func showLoadingState() {
        let loadingView = createLoadingView()
        mainContentView.addSubview(loadingView)
        
        loadingView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            loadingView.centerXAnchor.constraint(equalTo: mainContentView.centerXAnchor),
            loadingView.centerYAnchor.constraint(equalTo: mainContentView.centerYAnchor)
        ])
    }
    
    private func createLoadingView() -> NSView {
        let container = NSView()
        container.wantsLayer = true
        
        let spinner = NSProgressIndicator()
        spinner.style = .spinning
        spinner.startAnimation(nil)
        
        let label = NSTextField(labelWithString: "正在加载统计数据...")
        label.font = NSFont.systemFont(ofSize: 14)
        label.textColor = .secondaryLabelColor
        
        container.addSubview(spinner)
        container.addSubview(label)
        
        spinner.translatesAutoresizingMaskIntoConstraints = false
        label.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            spinner.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            spinner.topAnchor.constraint(equalTo: container.topAnchor),
            
            label.topAnchor.constraint(equalTo: spinner.bottomAnchor, constant: 10),
            label.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            label.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            
            container.widthAnchor.constraint(equalToConstant: 200),
            container.heightAnchor.constraint(equalToConstant: 60)
        ])
        
        return container
    }
    
    private func displayStats(todayStats: DailyHealthStats?, weeklyTrend: WeeklyHealthTrend?, intensivePeriods: [IntensiveWorkPeriod]) {
        // 清空现有内容
        mainContentView.subviews.forEach { $0.removeFromSuperview() }
        
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.borderType = .noBorder
        scrollView.backgroundColor = NSColor(calibratedWhite: 0.95, alpha: 1.0)
        
        let containerView = NSView()
        containerView.wantsLayer = true
        
        var yOffset: CGFloat = 20
        
        // 添加标题卡片
        let titleCard = createTitleCard()
        containerView.addSubview(titleCard)
        titleCard.frame = NSRect(x: 20, y: mainContentView.frame.height - 80, width: 440, height: 60)
        
        // 今日统计卡片
        yOffset = mainContentView.frame.height - 110
        let todayCard = createTodayStatsCard(stats: todayStats)
        containerView.addSubview(todayCard)
        todayCard.frame = NSRect(x: 20, y: yOffset - 150, width: 440, height: 140)
        
        // 高强度时段卡片
        yOffset -= 170
        let intensiveCard = createIntensivePeriodsCard(periods: intensivePeriods)
        containerView.addSubview(intensiveCard)
        intensiveCard.frame = NSRect(x: 20, y: yOffset - 120, width: 440, height: 110)
        
        // 本周趋势卡片
        yOffset -= 140
        let trendCard = createWeeklyTrendCard(trend: weeklyTrend)
        containerView.addSubview(trendCard)
        trendCard.frame = NSRect(x: 20, y: 20, width: 440, height: 140)
        
        scrollView.documentView = containerView
        containerView.frame = NSRect(x: 0, y: 0, width: 480, height: 560)
        
        mainContentView.addSubview(scrollView)
        scrollView.frame = mainContentView.bounds
    }
    
    // MARK: - Card Creation Methods
    
    private func createTitleCard() -> NSView {
        let card = createCard()
        
        let titleLabel = NSTextField(labelWithString: "👁️ 眼睛健康报告")
        titleLabel.font = NSFont.systemFont(ofSize: 22, weight: .semibold)
        titleLabel.textColor = .labelColor
        
        let dateLabel = NSTextField(labelWithString: getCurrentDateString())
        dateLabel.font = NSFont.systemFont(ofSize: 14)
        dateLabel.textColor = .secondaryLabelColor
        
        card.addSubview(titleLabel)
        card.addSubview(dateLabel)
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 20),
            titleLabel.centerYAnchor.constraint(equalTo: card.centerYAnchor, constant: -10),
            
            dateLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 20),
            dateLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 2)
        ])
        
        return card
    }
    
    private func createTodayStatsCard(stats: DailyHealthStats?) -> NSView {
        let card = createCard()
        
        let titleLabel = createSectionTitle("📊 今日用眼状况")
        card.addSubview(titleLabel)
        titleLabel.frame = NSRect(x: 20, y: card.frame.height - 35, width: 200, height: 20)
        
        guard let stats = stats else {
            let noDataLabel = NSTextField(labelWithString: "暂无今日数据")
            noDataLabel.font = NSFont.systemFont(ofSize: 14)
            noDataLabel.textColor = .tertiaryLabelColor
            card.addSubview(noDataLabel)
            noDataLabel.frame = NSRect(x: 20, y: 50, width: 400, height: 20)
            return card
        }
        
        // 创建统计项
        let items = [
            createStatItem(
                label: "平均休息间隔",
                value: "\(Int(stats.averageRestInterval / 60)) 分钟",
                status: stats.averageRestInterval <= 30 * 60 ? .good : .warning
            ),
            createStatItem(
                label: "最长连续用眼",
                value: String(format: "%.1f 小时", stats.longestContinuousWork / 3600),
                status: stats.longestContinuousWork <= 90 * 60 ? .good : .bad
            ),
            createStatItem(
                label: "完整休息次数",
                value: "\(stats.completedBreaks) 次",
                status: .neutral
            ),
            createStatItem(
                label: "推迟率",
                value: "\(Int(stats.postponeRate * 100))%",
                status: stats.postponeRate <= 0.3 ? .good : .warning
            )
        ]
        
        var xOffset: CGFloat = 20
        let yOffset: CGFloat = 40
        let itemWidth: CGFloat = 100
        
        for item in items {
            card.addSubview(item)
            item.frame = NSRect(x: xOffset, y: yOffset, width: itemWidth, height: 60)
            xOffset += itemWidth + 10
        }
        
        return card
    }
    
    private func createIntensivePeriodsCard(periods: [IntensiveWorkPeriod]) -> NSView {
        let card = createCard()
        
        let titleLabel = createSectionTitle("⏰ 高强度时段分析")
        card.addSubview(titleLabel)
        titleLabel.frame = NSRect(x: 20, y: card.frame.height - 35, width: 200, height: 20)
        
        if periods.isEmpty {
            let goodLabel = NSTextField(labelWithString: "✅ 今日无超长连续用眼时段")
            goodLabel.font = NSFont.systemFont(ofSize: 14, weight: .medium)
            goodLabel.textColor = NSColor.systemGreen
            card.addSubview(goodLabel)
            goodLabel.frame = NSRect(x: 20, y: 40, width: 400, height: 20)
        } else {
            var yPos: CGFloat = 60
            for period in periods.prefix(2) {
                let periodView = createPeriodView(period: period)
                card.addSubview(periodView)
                periodView.frame = NSRect(x: 20, y: yPos, width: 400, height: 25)
                yPos -= 30
            }
        }
        
        return card
    }
    
    private func createWeeklyTrendCard(trend: WeeklyHealthTrend?) -> NSView {
        let card = createCard()
        
        let titleLabel = createSectionTitle("📈 本周改善趋势")
        card.addSubview(titleLabel)
        titleLabel.frame = NSRect(x: 20, y: card.frame.height - 35, width: 200, height: 20)
        
        guard let trend = trend else {
            let noDataLabel = NSTextField(labelWithString: "暂无趋势数据")
            noDataLabel.font = NSFont.systemFont(ofSize: 14)
            noDataLabel.textColor = .tertiaryLabelColor
            card.addSubview(noDataLabel)
            noDataLabel.frame = NSRect(x: 20, y: 50, width: 400, height: 20)
            return card
        }
        
        // 创建趋势指标
        let items = [
            createTrendItem(
                label: "推迟率",
                current: Int(trend.currentWeek.averagePostponeRate * 100),
                previous: Int(trend.previousWeek.averagePostponeRate * 100),
                unit: "%"
            ),
            createTrendItem(
                label: "休息间隔",
                current: Int(trend.currentWeek.averageRestInterval / 60),
                previous: Int(trend.previousWeek.averageRestInterval / 60),
                unit: "分钟"
            ),
            createTrendItem(
                label: "健康天数",
                current: trend.currentWeek.healthyDays,
                previous: trend.previousWeek.healthyDays,
                unit: "天"
            )
        ]
        
        var yPos: CGFloat = 60
        for item in items {
            card.addSubview(item)
            item.frame = NSRect(x: 20, y: yPos, width: 400, height: 25)
            yPos -= 30
        }
        
        // 连续天数标签
        let consecutiveLabel = NSTextField(labelWithString: "🔥 连续健康使用 \(trend.consecutiveHealthyDays) 天")
        consecutiveLabel.font = NSFont.systemFont(ofSize: 13, weight: .medium)
        consecutiveLabel.textColor = .systemOrange
        card.addSubview(consecutiveLabel)
        consecutiveLabel.frame = NSRect(x: 20, y: 10, width: 200, height: 20)
        
        return card
    }
    
    // MARK: - Helper Methods
    
    private func createCard() -> NSView {
        let card = NSView()
        card.wantsLayer = true
        card.layer?.backgroundColor = NSColor.white.cgColor
        card.layer?.cornerRadius = 10
        card.layer?.shadowColor = NSColor.black.cgColor
        card.layer?.shadowOpacity = 0.05
        card.layer?.shadowOffset = CGSize(width: 0, height: 2)
        card.layer?.shadowRadius = 4
        return card
    }
    
    private func createSectionTitle(_ text: String) -> NSTextField {
        let label = NSTextField(labelWithString: text)
        label.font = NSFont.systemFont(ofSize: 16, weight: .semibold)
        label.textColor = .labelColor
        return label
    }
    
    private func createStatItem(label: String, value: String, status: StatStatus) -> NSView {
        let container = NSView()
        
        let valueLabel = NSTextField(labelWithString: value)
        valueLabel.font = NSFont.systemFont(ofSize: 20, weight: .medium)
        valueLabel.textColor = status.color
        valueLabel.alignment = .center
        
        let titleLabel = NSTextField(labelWithString: label)
        titleLabel.font = NSFont.systemFont(ofSize: 11)
        titleLabel.textColor = .secondaryLabelColor
        titleLabel.alignment = .center
        
        container.addSubview(valueLabel)
        container.addSubview(titleLabel)
        
        valueLabel.frame = NSRect(x: 0, y: 25, width: 100, height: 25)
        titleLabel.frame = NSRect(x: 0, y: 5, width: 100, height: 15)
        
        return container
    }
    
    private func createPeriodView(period: IntensiveWorkPeriod) -> NSView {
        let container = NSView()
        
        let icon = NSTextField(labelWithString: period.durationHours > 2.5 ? "🔴" : "🟡")
        let timeLabel = NSTextField(labelWithString: period.hourRange)
        timeLabel.font = NSFont.systemFont(ofSize: 13, weight: .medium)
        timeLabel.textColor = .labelColor
        
        let durationLabel = NSTextField(labelWithString: String(format: "连续 %.1f 小时", period.durationHours))
        durationLabel.font = NSFont.systemFont(ofSize: 13)
        durationLabel.textColor = period.durationHours > 2.5 ? .systemRed : .systemOrange
        
        container.addSubview(icon)
        container.addSubview(timeLabel)
        container.addSubview(durationLabel)
        
        icon.frame = NSRect(x: 0, y: 2, width: 20, height: 20)
        timeLabel.frame = NSRect(x: 25, y: 2, width: 100, height: 20)
        durationLabel.frame = NSRect(x: 130, y: 2, width: 150, height: 20)
        
        return container
    }
    
    private func createTrendItem(label: String, current: Int, previous: Int, unit: String) -> NSView {
        let container = NSView()
        
        let titleLabel = NSTextField(labelWithString: label)
        titleLabel.font = NSFont.systemFont(ofSize: 13)
        titleLabel.textColor = .secondaryLabelColor
        
        let trendLabel = NSTextField(labelWithString: "\(previous) → \(current) \(unit)")
        trendLabel.font = NSFont.systemFont(ofSize: 13, weight: .medium)
        trendLabel.textColor = .labelColor
        
        let improvement = current - previous
        let isImproved = (label == "推迟率" || label == "休息间隔") ? improvement < 0 : improvement > 0
        
        let changeLabel = NSTextField(labelWithString: isImproved ? "✅ 改善" : "⚠️ 需改进")
        changeLabel.font = NSFont.systemFont(ofSize: 12)
        changeLabel.textColor = isImproved ? .systemGreen : .systemOrange
        
        container.addSubview(titleLabel)
        container.addSubview(trendLabel)
        container.addSubview(changeLabel)
        
        titleLabel.frame = NSRect(x: 0, y: 2, width: 80, height: 20)
        trendLabel.frame = NSRect(x: 85, y: 2, width: 150, height: 20)
        changeLabel.frame = NSRect(x: 240, y: 2, width: 100, height: 20)
        
        return container
    }
    
    private func getCurrentDateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年MM月dd日"
        return formatter.string(from: Date())
    }
    
    enum StatStatus {
        case good, warning, bad, neutral
        
        var color: NSColor {
            switch self {
            case .good: return .systemGreen
            case .warning: return .systemOrange
            case .bad: return .systemRed
            case .neutral: return .labelColor
            }
        }
    }
    
    // MARK: - Window Properties
    
    override var canBecomeKey: Bool {
        return true
    }
    
    override var canBecomeMain: Bool {
        return true
    }
}

// MARK: - Window Delegate

extension ModernHealthStatsWindow: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        print("🔴 统计窗口即将关闭")
    }
    
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        return true
    }
}