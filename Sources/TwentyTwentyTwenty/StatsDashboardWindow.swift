import Cocoa
import TwentyTwentyTwentyCore

final class StatsDashboardWindow: NSWindow {
    private let statsDB = StatsDatabase.shared
    private var localizer: ((String) -> String)?
    private let contentStack = NSStackView()
    private let scrollView = NSScrollView()
    private let documentView = NSView()
    private let footerView = NSView()
    private let closeButton = NSButton()
    private let refreshButton = NSButton()

    override init(contentRect: NSRect, styleMask style: NSWindow.StyleMask, backing backingStoreType: NSWindow.BackingStoreType, defer flag: Bool) {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 560, height: 680),
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

    private func setupWindow() {
        title = "眼睛健康报告"
        minSize = NSSize(width: 520, height: 560)
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
        contentStack.alignment = .width
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

        refreshButton.translatesAutoresizingMaskIntoConstraints = false
        refreshButton.title = "刷新"
        refreshButton.bezelStyle = .rounded
        refreshButton.target = self
        refreshButton.action = #selector(refreshSnapshot)

        let separator = NSBox()
        separator.translatesAutoresizingMaskIntoConstraints = false
        separator.boxType = .separator

        rootView.addSubview(scrollView)
        rootView.addSubview(footerView)
        footerView.addSubview(separator)
        footerView.addSubview(refreshButton)
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

            refreshButton.centerYAnchor.constraint(equalTo: footerView.centerYAnchor),
            refreshButton.trailingAnchor.constraint(equalTo: closeButton.leadingAnchor, constant: -10),

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
        contentStack.addArrangedSubview(label)
    }

    private func render(_ snapshot: StatsDashboardSnapshot) {
        clearContent()
        contentStack.addArrangedSubview(makeHeader(snapshot))
        contentStack.addArrangedSubview(makeTodayMetrics(snapshot.today))
        contentStack.addArrangedSubview(makeTodayDetails(snapshot.today))
        contentStack.addArrangedSubview(makeWeekSection(snapshot.week))
        contentStack.addArrangedSubview(makeQualitySection(snapshot.week.quality))
    }

    private func renderError() {
        clearContent()
        contentStack.addArrangedSubview(makeHeader(nil))
        let panel = makePanel()
        let stack = makeVerticalStack(spacing: 8, inset: 16)
        panel.addSubview(stack)
        pin(stack, to: panel)
        stack.addArrangedSubview(makeLabel("统计数据暂时无法读取", size: 15, weight: .semibold))
        stack.addArrangedSubview(makeLabel("可以稍后刷新；当前计时功能不受影响。", size: 13, color: .secondaryLabelColor))
        contentStack.addArrangedSubview(panel)
    }

    private func clearContent() {
        for view in contentStack.arrangedSubviews {
            contentStack.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
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

    private func makeTodayMetrics(_ today: StatsDaySnapshot) -> NSView {
        let container = makeVerticalStack(spacing: 12, inset: 0)
        container.alignment = .width

        container.addArrangedSubview(makeSectionTitle("今日概览"))

        let firstRow = makeHorizontalStack(distribution: .fillEqually)
        firstRow.addArrangedSubview(makeMetricCard(
            title: "有效工作",
            value: "\(today.workSessions) 次",
            detail: "不足 1 分钟不计入",
            accent: .systemBlue
        ))
        firstRow.addArrangedSubview(makeMetricCard(
            title: "休息完成",
            value: "\(today.completedBreaks)/\(today.breakOpportunities)",
            detail: "完成率 \(formatPercent(today.breakCompletionRate))",
            accent: completionColor(today.breakCompletionRate)
        ))

        let secondRow = makeHorizontalStack(distribution: .fillEqually)
        secondRow.addArrangedSubview(makeMetricCard(
            title: "最长连续",
            value: formatDuration(today.longestWorkSeconds),
            detail: longestWorkDetail(today.longestWorkSeconds),
            accent: today.longestWorkSeconds > 90 * 60 ? .systemRed : .systemGreen
        ))
        secondRow.addArrangedSubview(makeMetricCard(
            title: "推迟",
            value: "\(today.postponedSessions) 会话 / \(today.totalPostpones) 次",
            detail: "推迟率 \(formatPercent(today.postponeSessionRate))",
            accent: today.postponeSessionRate > 0.3 ? .systemOrange : .systemGreen
        ))

        container.addArrangedSubview(firstRow)
        container.addArrangedSubview(secondRow)
        firstRow.widthAnchor.constraint(equalTo: container.widthAnchor).isActive = true
        secondRow.widthAnchor.constraint(equalTo: container.widthAnchor).isActive = true
        return container
    }

    private func makeTodayDetails(_ today: StatsDaySnapshot) -> NSView {
        let panel = makePanel()
        let stack = makeVerticalStack(spacing: 12, inset: 16)
        stack.alignment = .width
        panel.addSubview(stack)
        pin(stack, to: panel)

        stack.addArrangedSubview(makeSectionTitle("今日明细"))
        stack.addArrangedSubview(makeInfoRow(title: "累计工作时长", value: formatDuration(today.totalWorkSeconds)))
        stack.addArrangedSubview(makeInfoRow(title: "休息机会", value: "\(today.breakOpportunities) 次"))
        stack.addArrangedSubview(makeInfoRow(title: "完成休息", value: "\(today.completedBreaks) 次"))
        stack.addArrangedSubview(makeInfoRow(title: "推迟分布", value: postponeBreakdown(today.postponesByMinutes)))

        return panel
    }

    private func makeWeekSection(_ week: StatsWeekSnapshot) -> NSView {
        let panel = makePanel()
        let stack = makeVerticalStack(spacing: 12, inset: 16)
        stack.alignment = .width
        panel.addSubview(stack)
        pin(stack, to: panel)

        stack.addArrangedSubview(makeSectionTitle("近 7 天"))
        stack.addArrangedSubview(makeInfoRow(title: "累计工作时长", value: formatDuration(week.totalWorkSeconds)))
        stack.addArrangedSubview(makeInfoRow(title: "健康天数", value: "\(week.healthyDays)/7 天"))
        stack.addArrangedSubview(makeInfoRow(title: "休息完成率", value: formatPercent(week.breakCompletionRate)))
        stack.addArrangedSubview(makeInfoRow(title: "活跃天数", value: "\(week.activeDays)/7 天"))

        let dayList = makeVerticalStack(spacing: 6, inset: 0)
        for day in week.days.reversed() {
            dayList.addArrangedSubview(makeDayRow(day))
        }
        stack.addArrangedSubview(dayList)

        return panel
    }

    private func makeQualitySection(_ quality: StatsQualitySummary) -> NSView {
        let panel = makePanel()
        let stack = makeVerticalStack(spacing: 10, inset: 16)
        stack.alignment = .width
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
        let row = makeHorizontalStack(spacing: 8)
        row.alignment = .centerY

        let dateLabel = makeLabel(formatShortDate(day.date), size: 12, weight: .medium)
        dateLabel.widthAnchor.constraint(equalToConstant: 56).isActive = true

        let workLabel = makeLabel(formatDuration(day.totalWorkSeconds), size: 12, color: .secondaryLabelColor)
        workLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)

        let completionLabel = makeBadge(formatPercent(day.breakCompletionRate), color: completionColor(day.breakCompletionRate))
        completionLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 54).isActive = true

        row.addArrangedSubview(dateLabel)
        row.addArrangedSubview(workLabel)
        row.addArrangedSubview(completionLabel)
        return row
    }

    private func makeMetricCard(title: String, value: String, detail: String, accent: NSColor) -> NSView {
        let card = makePanel()
        card.heightAnchor.constraint(greaterThanOrEqualToConstant: 96).isActive = true

        let stack = makeVerticalStack(spacing: 6, inset: 14)
        card.addSubview(stack)
        pin(stack, to: card)

        let titleLabel = makeLabel(title, size: 12, color: .secondaryLabelColor)
        let valueLabel = makeLabel(value, size: 22, weight: .bold)
        valueLabel.font = .monospacedDigitSystemFont(ofSize: 22, weight: .bold)
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

    @objc private func refreshSnapshot() {
        loadSnapshot()
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
