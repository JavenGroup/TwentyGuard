import Cocoa

class HealthStatsWindow: NSWindow {
    
    private let analyzer = HealthAnalyzer.shared
    private var contentStackView: NSStackView!
    private var localizer: ((String) -> String)?
    
    override init(contentRect: NSRect, styleMask style: NSWindow.StyleMask, backing backingStoreType: NSWindow.BackingStoreType, defer flag: Bool) {
        super.init(contentRect: NSRect(x: 0, y: 0, width: 380, height: 420), styleMask: [.titled, .closable], backing: .buffered, defer: false)
        
        setupWindow()
        setupContent()
        loadAndDisplayStats()
    }
    
    convenience init() {
        self.init(contentRect: NSRect.zero, styleMask: [.titled, .closable], backing: .buffered, defer: false)
    }
    
    private func setupWindow() {
        title = localizer?("eye_health_report") ?? "👁️ 眼睛健康报告"
        isReleasedWhenClosed = false  // 改为false，让AppDelegate管理
        
        // 设置窗口样式，确保可见性
        self.level = .normal
        self.collectionBehavior = [.canJoinAllSpaces]
        
        // 确保窗口显示在所有空间
        self.isMovableByWindowBackground = true
        
        print("🔧 统计窗口配置完成")
    }
    
    func setLocalizer(_ localizer: @escaping (String) -> String) {
        self.localizer = localizer
        title = localizer("eye_health_report")
    }
    
    private func setupContent() {
        let mainContainer = NSView()
        mainContainer.wantsLayer = true
        
        contentStackView = NSStackView()
        contentStackView.orientation = .vertical
        contentStackView.spacing = 16
        contentStackView.edgeInsets = NSEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        
        mainContainer.addSubview(contentStackView)
        contentStackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            contentStackView.topAnchor.constraint(equalTo: mainContainer.topAnchor),
            contentStackView.leadingAnchor.constraint(equalTo: mainContainer.leadingAnchor),
            contentStackView.trailingAnchor.constraint(equalTo: mainContainer.trailingAnchor),
            contentStackView.bottomAnchor.constraint(equalTo: mainContainer.bottomAnchor)
        ])
        
        contentView = mainContainer
        
        // 点击空白区域关闭窗口 - 暂时移除，避免干扰
        // let clickGesture = NSClickGestureRecognizer(target: self, action: #selector(handleBackgroundClick))
        // mainContainer.addGestureRecognizer(clickGesture)
    }
    
    private func loadAndDisplayStats() {
        // 清空现有内容
        contentStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        // 显示加载状态
        showLoadingState()
        
        // 在后台线程加载数据
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            // 获取数据（在后台线程）
            let todayStats = self.analyzer.getTodayHealthStats()
            let weeklyTrend = self.analyzer.getWeeklyHealthTrend()
            let intensivePeriods = self.analyzer.getTodayIntensiveWorkPeriods()
            
            // 回到主线程更新UI
            DispatchQueue.main.async {
                self.contentStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
                
                // 添加各个部分
                self.addTodaySection(todayStats)
                self.addIntensivePeriodsSection(intensivePeriods)
                self.addWeeklyTrendSection(weeklyTrend)
                self.addCloseButton()
            }
        }
    }
    
    private func showLoadingState() {
        let loadingLabel = NSTextField(labelWithString: "正在加载统计数据...")
        loadingLabel.font = NSFont.systemFont(ofSize: 14)
        loadingLabel.textColor = .secondaryLabelColor
        loadingLabel.alignment = .center
        
        let container = NSView()
        container.addSubview(loadingLabel)
        loadingLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            loadingLabel.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            loadingLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            container.heightAnchor.constraint(equalToConstant: 100)
        ])
        
        contentStackView.addArrangedSubview(container)
        addCloseButton()
    }
    
    private func addTodaySection(_ stats: DailyHealthStats?) {
        let section = createSectionContainer(
            title: "📊 今日用眼状况",
            emoji: "📊"
        )
        
        guard let stats = stats else {
            let noDataLabel = createDataLabel("暂无今日数据", color: .secondaryLabelColor)
            section.addArrangedSubview(noDataLabel)
            contentStackView.addArrangedSubview(section)
            return
        }
        
        // 平均休息间隔
        let intervalMinutes = Int(stats.averageRestInterval / 60)
        let intervalColor: NSColor = intervalMinutes <= 30 ? .systemGreen : .systemOrange
        let intervalRecommendation = intervalMinutes <= 30 ? "👀 达标" : "⚠️ 需改善"
        
        let intervalRow = createDataRow(
            label: "平均休息间隔",
            value: "\(intervalMinutes) 分钟",
            suffix: intervalRecommendation,
            valueColor: intervalColor
        )
        section.addArrangedSubview(intervalRow)
        
        // 最长连续用眼
        let longestHours = stats.longestContinuousWork / 3600
        let longestColor: NSColor = longestHours <= 1.5 ? .systemGreen : .systemRed
        let longestSuffix = longestHours > 2.0 ? "⚠️ 过长" : longestHours > 1.5 ? "🟡 偏长" : "✅ 良好"
        
        let longestRow = createDataRow(
            label: "最长连续用眼",
            value: String(format: "%.1f 小时", longestHours),
            suffix: longestSuffix,
            valueColor: longestColor
        )
        section.addArrangedSubview(longestRow)
        
        // 完整休息次数
        let completedRow = createDataRow(
            label: "完整休息次数",
            value: "\(stats.completedBreaks) 次",
            suffix: "",
            valueColor: .labelColor
        )
        section.addArrangedSubview(completedRow)
        
        // 推迟次数和比率
        let postponeRate = Int(stats.postponeRate * 100)
        let postponeColor: NSColor = postponeRate <= 20 ? .systemGreen : postponeRate <= 40 ? .systemOrange : .systemRed
        let postponeTrend = "📈 需改善" // 简化版，可以添加与昨日对比逻辑
        
        let postponeRow = createDataRow(
            label: "推迟次数",
            value: "\(stats.postponedBreaks) 次 (\(postponeRate)%)",
            suffix: postponeTrend,
            valueColor: postponeColor
        )
        section.addArrangedSubview(postponeRow)
        
        contentStackView.addArrangedSubview(section)
    }
    
    private func addIntensivePeriodsSection(_ periods: [IntensiveWorkPeriod]) {
        let section = createSectionContainer(
            title: "⏰ 高强度时段分析",
            emoji: "⏰"
        )
        
        if periods.isEmpty {
            let noIntensiveLabel = createDataLabel("✅ 今日无超长连续用眼时段", color: .systemGreen)
            section.addArrangedSubview(noIntensiveLabel)
        } else {
            for period in periods {
                let riskLevel = period.durationHours > 2.5 ? "🔴" : "🟡"
                let periodRow = createDataRow(
                    label: "\(riskLevel) \(period.hourRange)",
                    value: String(format: "连续 %.1fh", period.durationHours),
                    suffix: "",
                    valueColor: period.durationHours > 2.5 ? .systemRed : .systemOrange
                )
                section.addArrangedSubview(periodRow)
            }
            
            let suggestionLabel = createDataLabel("💡 建议：在这些时段增加主动休息", color: .secondaryLabelColor)
            suggestionLabel.font = NSFont.systemFont(ofSize: 12)
            section.addArrangedSubview(suggestionLabel)
        }
        
        contentStackView.addArrangedSubview(section)
    }
    
    private func addWeeklyTrendSection(_ trend: WeeklyHealthTrend?) {
        let section = createSectionContainer(
            title: "📈 本周改善趋势",
            emoji: "📈"
        )
        
        guard let trend = trend else {
            let noDataLabel = createDataLabel("暂无本周趋势数据", color: .secondaryLabelColor)
            section.addArrangedSubview(noDataLabel)
            contentStackView.addArrangedSubview(section)
            return
        }
        
        // 推迟率改善
        let postponeImprovement = trend.postponeRateImprovement
        let postponeImprovementPercent = Int(postponeImprovement * 100)
        let postponeColor: NSColor = postponeImprovement > 0 ? .systemGreen : .systemRed
        let postponeArrow = postponeImprovement > 0 ? "✅" : "📉"
        let postponeText = postponeImprovement > 0 ? "改善\(abs(postponeImprovementPercent))%" : "退步\(abs(postponeImprovementPercent))%"
        
        let currentPostponeRate = Int(trend.currentWeek.averagePostponeRate * 100)
        let previousPostponeRate = Int(trend.previousWeek.averagePostponeRate * 100)
        
        let postponeRow = createDataRow(
            label: "推迟率",
            value: "\(previousPostponeRate)% → \(currentPostponeRate)%",
            suffix: "\(postponeArrow) \(postponeText)",
            valueColor: postponeColor
        )
        section.addArrangedSubview(postponeRow)
        
        // 休息间隔改善
        let intervalImprovement = trend.restIntervalImprovement / 60 // 转为分钟
        let intervalColor: NSColor = intervalImprovement > 0 ? .systemGreen : .systemRed
        let intervalArrow = intervalImprovement > 0 ? "✅" : "📉"
        let intervalText = intervalImprovement > 0 ? "缩短\(Int(abs(intervalImprovement)))分钟" : "延长\(Int(abs(intervalImprovement)))分钟"
        
        let currentInterval = Int(trend.currentWeek.averageRestInterval / 60)
        let previousInterval = Int(trend.previousWeek.averageRestInterval / 60)
        
        let intervalRow = createDataRow(
            label: "休息间隔",
            value: "\(previousInterval)min → \(currentInterval)min",
            suffix: "\(intervalArrow) \(intervalText)",
            valueColor: intervalColor
        )
        section.addArrangedSubview(intervalRow)
        
        // 健康天数
        let healthyDays = trend.currentWeek.healthyDays
        let totalDays = trend.currentWeek.totalDays
        let healthyRate = totalDays > 0 ? Int(Double(healthyDays) / Double(totalDays) * 100) : 0
        
        let healthyRow = createDataRow(
            label: "健康天数",
            value: "本周 \(healthyDays)/\(totalDays)天 (\(healthyRate)%)",
            suffix: "🔥 连续\(trend.consecutiveHealthyDays)天",
            valueColor: .systemGreen
        )
        section.addArrangedSubview(healthyRow)
        
        contentStackView.addArrangedSubview(section)
    }
    
    private func addCloseButton() {
        let closeButton = NSButton(title: localizer?("close") ?? "关闭", target: self, action: #selector(closeWindow))
        closeButton.bezelStyle = .rounded
        closeButton.keyEquivalent = "\u{1b}" // ESC key
        
        // 确保按钮可以正确响应点击
        closeButton.isEnabled = true
        
        let buttonContainer = NSView()
        buttonContainer.addSubview(closeButton)
        
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            closeButton.trailingAnchor.constraint(equalTo: buttonContainer.trailingAnchor),
            closeButton.centerYAnchor.constraint(equalTo: buttonContainer.centerYAnchor),
            buttonContainer.heightAnchor.constraint(equalToConstant: 40)
        ])
        
        contentStackView.addArrangedSubview(buttonContainer)
    }
    
    // MARK: - Helper Methods
    
    private func createSectionContainer(title: String, emoji: String) -> NSStackView {
        let container = NSStackView()
        container.orientation = .vertical
        container.spacing = 8
        
        // 标题
        let titleLabel = NSTextField(labelWithString: title)
        titleLabel.font = NSFont.systemFont(ofSize: 14, weight: .semibold)
        titleLabel.textColor = .labelColor
        
        // 分割线
        let separator = createSeparator()
        
        container.addArrangedSubview(titleLabel)
        container.addArrangedSubview(separator)
        
        return container
    }
    
    private func createDataRow(label: String, value: String, suffix: String, valueColor: NSColor) -> NSView {
        let container = NSView()
        
        let labelField = NSTextField(labelWithString: label)
        labelField.font = NSFont.systemFont(ofSize: 12)
        labelField.textColor = .labelColor
        
        let valueField = NSTextField(labelWithString: value)
        valueField.font = NSFont.systemFont(ofSize: 12, weight: .medium)
        valueField.textColor = valueColor
        valueField.alignment = .center
        
        let suffixField = NSTextField(labelWithString: suffix)
        suffixField.font = NSFont.systemFont(ofSize: 11)
        suffixField.textColor = .secondaryLabelColor
        
        container.addSubview(labelField)
        container.addSubview(valueField)
        container.addSubview(suffixField)
        
        labelField.translatesAutoresizingMaskIntoConstraints = false
        valueField.translatesAutoresizingMaskIntoConstraints = false
        suffixField.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            labelField.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            labelField.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            
            valueField.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            valueField.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            
            suffixField.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            suffixField.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            
            container.heightAnchor.constraint(equalToConstant: 20)
        ])
        
        return container
    }
    
    private func createDataLabel(_ text: String, color: NSColor) -> NSTextField {
        let label = NSTextField(labelWithString: text)
        label.font = NSFont.systemFont(ofSize: 12)
        label.textColor = color
        label.alignment = .center
        return label
    }
    
    private func createSeparator() -> NSView {
        let separator = NSView()
        separator.wantsLayer = true
        separator.layer?.backgroundColor = NSColor.separatorColor.cgColor
        
        NSLayoutConstraint.activate([
            separator.heightAnchor.constraint(equalToConstant: 1)
        ])
        
        return separator
    }
    
    // MARK: - Actions
    
    @objc private func closeWindow() {
        print("🔒 关闭统计窗口")
        self.orderOut(nil)  // 先隐藏窗口
        self.close()        // 然后关闭
    }
    
    @objc private func handleBackgroundClick(_ gesture: NSClickGestureRecognizer) {
        // 仅在点击空白区域时关闭，不在控件上
        let location = gesture.location(in: contentView)
        let hitView = contentView?.hitTest(location)
        
        if hitView == contentView {
            closeWindow()
        }
    }
    
    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 { // ESC key
            closeWindow()
            return
        }
        super.keyDown(with: event)
    }
    
    override var canBecomeKey: Bool {
        return true
    }
    
    override var canBecomeMain: Bool {
        return true
    }
}

// MARK: - Window Delegate

extension HealthStatsWindow: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        print("🔴 统计窗口即将关闭")
        // 窗口关闭时的清理工作会由AppDelegate处理
    }
    
    func windowDidBecomeKey(_ notification: Notification) {
        print("🔑 统计窗口获得焦点")
        // 窗口激活时刷新数据
        loadAndDisplayStats()
    }
    
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        print("🤔 统计窗口请求关闭")
        return true  // 允许关闭
    }
}