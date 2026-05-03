import Cocoa
import TwentyTwentyTwentyCore

final class StatsDashboardWindow: NSWindow {
    private let statsDB = StatsDatabase.shared
    private let verdictEvaluator = StatsHealthVerdictEvaluator()
    private var localizer: ((String) -> String)?
    private let contentStack = NSStackView()
    private let scrollView = NSScrollView()
    private let documentView = FlippedDocumentView()
    private let footerView = NSView()
    private let closeButton = NSButton()

    override init(contentRect: NSRect, styleMask style: NSWindow.StyleMask, backing backingStoreType: NSWindow.BackingStoreType, defer flag: Bool) {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 620, height: 700),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )

        setupWindow()
        setupLayout()
        centerOnMainScreen()
        loadSnapshot()
    }

    convenience init() {
        self.init(contentRect: .zero, styleMask: [.titled, .closable, .miniaturizable, .resizable], backing: .buffered, defer: false)
    }

    func setLocalizer(_ localizer: @escaping (String) -> String) {
        self.localizer = localizer
        title = localizer("eye_health_report")
        closeButton.title = localizer("close")
    }

    func reloadData() {
        loadSnapshot()
    }

    private func setupWindow() {
        title = "眼睛健康报告"
        minSize = NSSize(width: 560, height: 560)
        isReleasedWhenClosed = false
        backgroundColor = .controlBackgroundColor
    }

    private func setupLayout() {
        let rootView = NSView()
        rootView.wantsLayer = true
        rootView.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
        contentView = rootView

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.hasVerticalScroller = true
        scrollView.drawsBackground = false
        scrollView.borderType = .noBorder

        documentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.documentView = documentView

        contentStack.translatesAutoresizingMaskIntoConstraints = false
        contentStack.orientation = .vertical
        contentStack.alignment = .leading
        contentStack.spacing = 18
        documentView.addSubview(contentStack)

        footerView.translatesAutoresizingMaskIntoConstraints = false
        footerView.wantsLayer = true
        footerView.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor

        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.title = localizer?("close") ?? "关闭"
        closeButton.bezelStyle = .rounded
        closeButton.target = self
        closeButton.action = #selector(closeWindow)

        let separator = NSBox()
        separator.translatesAutoresizingMaskIntoConstraints = false
        separator.boxType = .separator

        rootView.addSubview(scrollView)
        rootView.addSubview(footerView)
        footerView.addSubview(separator)
        footerView.addSubview(closeButton)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: rootView.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: rootView.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: rootView.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: footerView.topAnchor),

            footerView.leadingAnchor.constraint(equalTo: rootView.leadingAnchor),
            footerView.trailingAnchor.constraint(equalTo: rootView.trailingAnchor),
            footerView.bottomAnchor.constraint(equalTo: rootView.bottomAnchor),
            footerView.heightAnchor.constraint(equalToConstant: 58),

            separator.leadingAnchor.constraint(equalTo: footerView.leadingAnchor),
            separator.trailingAnchor.constraint(equalTo: footerView.trailingAnchor),
            separator.topAnchor.constraint(equalTo: footerView.topAnchor),

            closeButton.centerYAnchor.constraint(equalTo: footerView.centerYAnchor),
            closeButton.trailingAnchor.constraint(equalTo: footerView.trailingAnchor, constant: -22),
            closeButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 82),

            documentView.widthAnchor.constraint(equalTo: scrollView.contentView.widthAnchor),
            contentStack.topAnchor.constraint(equalTo: documentView.topAnchor, constant: 24),
            contentStack.leadingAnchor.constraint(equalTo: documentView.leadingAnchor, constant: 24),
            contentStack.trailingAnchor.constraint(equalTo: documentView.trailingAnchor, constant: -24),
            contentStack.bottomAnchor.constraint(equalTo: documentView.bottomAnchor, constant: -24)
        ])
    }

    private func centerOnMainScreen() {
        guard let screen = NSScreen.main else {
            center()
            return
        }

        let screenFrame = screen.visibleFrame
        setFrameOrigin(NSPoint(
            x: screenFrame.midX - frame.width / 2,
            y: screenFrame.midY - frame.height / 2
        ))
    }

    private func loadSnapshot() {
        showLoading()

        statsDB.getDashboardSnapshot { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }

                switch result {
                case .success(let snapshot):
                    self.render(snapshot)
                case .failure:
                    self.renderError()
                }
            }
        }
    }

    private func showLoading() {
        clearContent()
        let label = makeLabel("正在加载统计...", size: 14, color: .secondaryLabelColor)
        label.alignment = .center
        addContentSection(label)
    }

    private func render(_ snapshot: StatsDashboardSnapshot) {
        clearContent()
        addContentSection(makeHeader(snapshot))
        addContentSection(makeVerdictPanel(snapshot.today))
        addContentSection(makeKeyMetrics(snapshot.today))
        addContentSection(makeWeekTableSection(snapshot.week))
        if snapshot.week.quality.hasIssues {
            addContentSection(makeQualitySection(snapshot.week.quality))
        }
        scrollToTop()
    }

    private func renderError() {
        clearContent()
        addContentSection(makeHeader(nil))
        let panel = makePanel()
        let stack = makeVerticalStack(spacing: 8, inset: 16)
        panel.addSubview(stack)
        pin(stack, to: panel)
        stack.addArrangedSubview(makeLabel("统计数据暂时无法读取", size: 15, weight: .semibold))
        stack.addArrangedSubview(makeLabel("可以稍后刷新；当前计时功能不受影响。", size: 13, color: .secondaryLabelColor))
        addContentSection(panel)
        scrollToTop()
    }

    private func clearContent() {
        for view in contentStack.arrangedSubviews {
            contentStack.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
    }

    private func addContentSection(_ view: NSView) {
        contentStack.addArrangedSubview(view)
        view.widthAnchor.constraint(equalTo: contentStack.widthAnchor).isActive = true
    }

    private func makeHeader(_ snapshot: StatsDashboardSnapshot?) -> NSView {
        let container = NSView()
        container.translatesAutoresizingMaskIntoConstraints = false

        let stack = makeVerticalStack(spacing: 6, inset: 0)
        container.addSubview(stack)
        pin(stack, to: container)

        stack.addArrangedSubview(makeLabel("眼睛健康报告", size: 24, weight: .bold))

        let subtitle: String
        if let snapshot {
            subtitle = "更新于 \(formatDateTime(snapshot.generatedAt))"
        } else {
            subtitle = "统计加载中"
        }
        stack.addArrangedSubview(makeLabel(subtitle, size: 12, color: .secondaryLabelColor))

        return container
    }

    private func makeVerdictPanel(_ today: StatsDaySnapshot) -> NSView {
        let panel = makePanel()
        panel.heightAnchor.constraint(greaterThanOrEqualToConstant: 142).isActive = true

        let stack = makeVerticalStack(spacing: 10, inset: 18)
        panel.addSubview(stack)
        pin(stack, to: panel)

        let verdict = verdictEvaluator.verdict(for: today)
        stack.addArrangedSubview(makeLabel("今日判断", size: 13, weight: .medium, color: .secondaryLabelColor))

        let titleLabel = makeLabel(verdict.title, size: 32, weight: .bold, color: verdictColor(verdict.severity))
        titleLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        stack.addArrangedSubview(titleLabel)

        let reasonLabel = makeLabel(verdict.reason, size: 14, weight: .medium, color: .secondaryLabelColor)
        stack.addArrangedSubview(reasonLabel)

        if today.totalWorkSeconds > 0 {
            stack.addArrangedSubview(makeLabel(
                "累计 \(formatDuration(today.totalWorkSeconds))，最长连续 \(formatDuration(today.longestWorkSeconds))",
                size: 12,
                color: .tertiaryLabelColor
            ))
        }

        return panel
    }

    private func makeKeyMetrics(_ today: StatsDaySnapshot) -> NSView {
        let container = makeVerticalStack(spacing: 12, inset: 0)

        container.addArrangedSubview(makeSectionTitle("关键指标"))

        let row = makeHorizontalStack(distribution: .fillEqually)
        row.addArrangedSubview(makeMetricCard(
            title: "完成率",
            value: formatPercent(today.breakCompletionRate),
            detail: "\(today.completedBreaks)/\(today.breakOpportunities) 次休息",
            accent: completionColor(today.breakCompletionRate)
        ))
        row.addArrangedSubview(makeMetricCard(
            title: "推迟",
            value: "\(today.totalPostpones) 次",
            detail: "\(today.postponedSessions) 个会话",
            accent: today.postponeSessionRate > 0.3 ? .systemOrange : .systemGreen
        ))
        row.addArrangedSubview(makeMetricCard(
            title: "夜间",
            value: nightRestrictionEnabled() ? "已启用" : "未启用",
            detail: "晚间收紧与禁用",
            accent: nightRestrictionEnabled() ? .systemGreen : .secondaryLabelColor,
            monospacedValue: false
        ))

        container.addArrangedSubview(row)
        row.widthAnchor.constraint(equalTo: container.widthAnchor).isActive = true
        return container
    }

    private func makeTodayDetails(_ today: StatsDaySnapshot) -> NSView {
        let panel = makePanel()
        let stack = makeVerticalStack(spacing: 12, inset: 16)
        panel.addSubview(stack)
        pin(stack, to: panel)

        stack.addArrangedSubview(makeSectionTitle("今日明细"))
        stack.addArrangedSubview(makeInfoRow(title: "累计工作时长", value: formatDuration(today.totalWorkSeconds)))
        stack.addArrangedSubview(makeInfoRow(title: "休息机会", value: "\(today.breakOpportunities) 次"))
        stack.addArrangedSubview(makeInfoRow(title: "完成休息", value: "\(today.completedBreaks) 次"))
        stack.addArrangedSubview(makeInfoRow(title: "推迟分布", value: postponeBreakdown(today.postponesByMinutes)))

        return panel
    }

    private func makeWeekTableSection(_ week: StatsWeekSnapshot) -> NSView {
        let panel = makePanel()
        let stack = makeVerticalStack(spacing: 14, inset: 16)
        panel.addSubview(stack)
        pin(stack, to: panel)

        stack.addArrangedSubview(makeSectionTitle("近 7 天"))
        stack.addArrangedSubview(makeLabel(
            "累计 \(formatDuration(week.totalWorkSeconds)) · 健康 \(week.healthyDays)/7 天 · 完成率 \(formatPercent(week.breakCompletionRate))",
            size: 12,
            color: .secondaryLabelColor
        ))

        let dayList = makeVerticalStack(spacing: 8, inset: 0)
        dayList.addArrangedSubview(makeWeekHeaderRow())
        for day in week.days.reversed() {
            dayList.addArrangedSubview(makeDayRow(day))
        }
        stack.addArrangedSubview(dayList)

        return panel
    }

    private func makeQualitySection(_ quality: StatsQualitySummary) -> NSView {
        let panel = makePanel()
        let stack = makeVerticalStack(spacing: 10, inset: 16)
        panel.addSubview(stack)
        pin(stack, to: panel)

        stack.addArrangedSubview(makeSectionTitle("数据质量"))

        let messages = qualityMessages(quality)
        if messages.isEmpty {
            stack.addArrangedSubview(makeLabel("没有发现会影响统计口径的异常记录。", size: 13, color: .secondaryLabelColor))
        } else {
            for message in messages {
                stack.addArrangedSubview(makeLabel(message, size: 13, color: .secondaryLabelColor))
            }
        }

        return panel
    }

    private func makeDayRow(_ day: StatsDaySnapshot) -> NSView {
        let row = makeHorizontalStack(spacing: 14)
        row.alignment = .centerY

        let dateLabel = makeLabel(formatShortDate(day.date), size: 12, weight: .medium)
        dateLabel.font = .monospacedDigitSystemFont(ofSize: 12, weight: .semibold)
        dateLabel.widthAnchor.constraint(equalToConstant: 68).isActive = true

        let workLabel = makeLabel(formatDuration(day.totalWorkSeconds), size: 12, color: .secondaryLabelColor)
        workLabel.font = .monospacedDigitSystemFont(ofSize: 12, weight: .medium)
        workLabel.widthAnchor.constraint(equalToConstant: 178).isActive = true

        let completionLabel = makeBadge(formatPercent(day.breakCompletionRate), color: completionColor(day.breakCompletionRate))
        completionLabel.font = .monospacedDigitSystemFont(ofSize: 12, weight: .semibold)
        completionLabel.alignment = .right
        completionLabel.widthAnchor.constraint(equalToConstant: 74).isActive = true

        let postponeLabel = makeLabel("\(day.totalPostpones)", size: 12, weight: .semibold, color: day.totalPostpones > 0 ? .systemOrange : .secondaryLabelColor)
        postponeLabel.font = .monospacedDigitSystemFont(ofSize: 12, weight: .semibold)
        postponeLabel.alignment = .right
        postponeLabel.widthAnchor.constraint(equalToConstant: 56).isActive = true

        row.addArrangedSubview(dateLabel)
        row.addArrangedSubview(workLabel)
        row.addArrangedSubview(completionLabel)
        row.addArrangedSubview(postponeLabel)
        return row
    }

    private func makeWeekHeaderRow() -> NSView {
        let row = makeHorizontalStack(spacing: 14)
        row.alignment = .centerY

        let dateLabel = makeColumnHeader("日期", width: 68, alignment: .left)
        let workLabel = makeColumnHeader("工作", width: 178, alignment: .left)
        let completionLabel = makeColumnHeader("完成", width: 74, alignment: .right)
        let postponeLabel = makeColumnHeader("推迟", width: 56, alignment: .right)

        row.addArrangedSubview(dateLabel)
        row.addArrangedSubview(workLabel)
        row.addArrangedSubview(completionLabel)
        row.addArrangedSubview(postponeLabel)
        return row
    }

    private func makeColumnHeader(_ text: String, width: CGFloat, alignment: NSTextAlignment) -> NSTextField {
        let label = makeLabel(text, size: 11, weight: .medium, color: .secondaryLabelColor)
        label.alignment = alignment
        label.widthAnchor.constraint(equalToConstant: width).isActive = true
        return label
    }

    private func makeMetricCard(title: String, value: String, detail: String, accent: NSColor, monospacedValue: Bool = true) -> NSView {
        let card = makePanel()
        card.heightAnchor.constraint(greaterThanOrEqualToConstant: 96).isActive = true

        let stack = makeVerticalStack(spacing: 6, inset: 14)
        card.addSubview(stack)
        pin(stack, to: card)

        let titleLabel = makeLabel(title, size: 12, color: .secondaryLabelColor)
        let valueLabel = makeLabel(value, size: 22, weight: .bold)
        valueLabel.font = monospacedValue ? .monospacedDigitSystemFont(ofSize: 22, weight: .bold) : .systemFont(ofSize: 22, weight: .bold)
        valueLabel.textColor = accent
        let detailLabel = makeLabel(detail, size: 11, color: .secondaryLabelColor)

        stack.addArrangedSubview(titleLabel)
        stack.addArrangedSubview(valueLabel)
        stack.addArrangedSubview(detailLabel)

        return card
    }

    private func makeInfoRow(title: String, value: String) -> NSView {
        let row = makeHorizontalStack(spacing: 12)
        row.alignment = .firstBaseline

        let titleLabel = makeLabel(title, size: 13, color: .secondaryLabelColor)
        titleLabel.widthAnchor.constraint(equalToConstant: 112).isActive = true

        let valueLabel = makeLabel(value, size: 13, weight: .medium)
        valueLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)

        row.addArrangedSubview(titleLabel)
        row.addArrangedSubview(valueLabel)
        return row
    }

    private func makeSectionTitle(_ text: String) -> NSTextField {
        makeLabel(text, size: 16, weight: .semibold)
    }

    private func makePanel() -> NSView {
        let view = NSView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.wantsLayer = true
        view.layer?.cornerRadius = 8
        view.layer?.borderWidth = 1
        view.layer?.borderColor = NSColor.separatorColor.withAlphaComponent(0.65).cgColor
        view.layer?.backgroundColor = NSColor.textBackgroundColor.withAlphaComponent(0.64).cgColor
        return view
    }

    private func makeVerticalStack(spacing: CGFloat, inset: CGFloat) -> NSStackView {
        let stack = NSStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = spacing
        stack.edgeInsets = NSEdgeInsets(top: inset, left: inset, bottom: inset, right: inset)
        return stack
    }

    private func makeHorizontalStack(spacing: CGFloat = 12, distribution: NSStackView.Distribution = .fill) -> NSStackView {
        let stack = NSStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.orientation = .horizontal
        stack.alignment = .top
        stack.distribution = distribution
        stack.spacing = spacing
        return stack
    }

    private func makeLabel(_ text: String, size: CGFloat, weight: NSFont.Weight = .regular, color: NSColor = .labelColor) -> NSTextField {
        let label = NSTextField(labelWithString: text)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: size, weight: weight)
        label.textColor = color
        label.lineBreakMode = .byWordWrapping
        label.maximumNumberOfLines = 0
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return label
    }

    private func makeBadge(_ text: String, color: NSColor) -> NSTextField {
        let label = makeLabel(text, size: 12, weight: .semibold, color: color)
        label.alignment = .right
        return label
    }

    private func pin(_ child: NSView, to parent: NSView) {
        NSLayoutConstraint.activate([
            child.topAnchor.constraint(equalTo: parent.topAnchor),
            child.leadingAnchor.constraint(equalTo: parent.leadingAnchor),
            child.trailingAnchor.constraint(equalTo: parent.trailingAnchor),
            child.bottomAnchor.constraint(equalTo: parent.bottomAnchor)
        ])
    }

    private func scrollToTop() {
        documentView.layoutSubtreeIfNeeded()
        scrollView.contentView.scroll(to: .zero)
        scrollView.reflectScrolledClipView(scrollView.contentView)
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

    private func formatPercent(_ value: Double) -> String {
        "\(Int((value * 100).rounded()))%"
    }

    private func formatDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter.string(from: date)
    }

    private func formatShortDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd"
        return formatter.string(from: date)
    }

    private func postponeBreakdown(_ values: [Int: Int]) -> String {
        let one = values[1] ?? 0
        let two = values[2] ?? 0
        let five = values[5] ?? 0
        let other = values.filter { ![1, 2, 5].contains($0.key) }.reduce(0) { $0 + $1.value }
        if other > 0 {
            return "1 分钟 \(one) 次，2 分钟 \(two) 次，5 分钟 \(five) 次，其他 \(other) 次"
        }
        return "1 分钟 \(one) 次，2 分钟 \(two) 次，5 分钟 \(five) 次"
    }

    private func longestWorkDetail(_ seconds: Int) -> String {
        if seconds == 0 { return "今天暂无有效会话" }
        if seconds > 90 * 60 { return "明显偏长" }
        if seconds > 60 * 60 { return "需要留意" }
        return "节奏正常"
    }

    private func verdictColor(_ severity: StatsHealthVerdictSeverity) -> NSColor {
        switch severity {
        case .good:
            return .systemGreen
        case .warning:
            return .systemOrange
        case .neutral:
            return .labelColor
        }
    }

    private func nightRestrictionEnabled() -> Bool {
        UserDefaults.standard.bool(forKey: "nightRestrictionEnabled")
    }

    private func completionColor(_ rate: Double) -> NSColor {
        if rate >= 0.8 { return .systemGreen }
        if rate >= 0.5 { return .systemOrange }
        return .systemRed
    }

    private func qualityMessages(_ quality: StatsQualitySummary) -> [String] {
        var messages: [String] = []

        if quality.excludedStaleSessions > 0 {
            messages.append("已排除 \(quality.excludedStaleSessions) 个异常超长会话，不再污染工作时长和健康天数。")
        }
        if quality.ignoredShortSessions > 0 {
            messages.append("已忽略 \(quality.ignoredShortSessions) 个不足 1 分钟的启动碎片。")
        }
        if quality.activeBreakRecords > 0 {
            messages.append("发现 \(quality.activeBreakRecords) 个未结束休息记录，未计入完成休息。")
        }
        if quality.interruptedBreakRecords > 0 {
            messages.append("发现 \(quality.interruptedBreakRecords) 个被中断的休息记录。")
        }
        if quality.unclosedPostponeRecords > 0 {
            messages.append("发现 \(quality.unclosedPostponeRecords) 条推迟记录缺少结束标记；它们仍计入推迟次数。")
        }

        return messages
    }

    @objc private func closeWindow() {
        close()
    }

    override var canBecomeKey: Bool {
        true
    }

    override var canBecomeMain: Bool {
        true
    }
}

private final class FlippedDocumentView: NSView {
    override var isFlipped: Bool {
        true
    }
}
