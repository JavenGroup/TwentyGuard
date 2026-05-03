import Cocoa

protocol NightRestrictionOverlayDelegate: AnyObject {
    func didRequestNightTestingExit()
}

final class NightRestrictionOverlayWindow: NSWindow {
    weak var nightDelegate: NightRestrictionOverlayDelegate?

    private var titleLabel: NSTextField!
    private var subtitleLabel: NSTextField!
    private var countdownLabel: NSTextField!
    private var recoveryLabel: NSTextField!
    private var scheduleLabel: NSTextField!
    private var testingExitButton: NSButton!
    private var confirmationTimer: Timer?
    private var isConfirmingTestingExit = false

    override init(contentRect: NSRect, styleMask style: NSWindow.StyleMask, backing backingStoreType: NSWindow.BackingStoreType, defer flag: Bool) {
        super.init(contentRect: contentRect, styleMask: [.borderless], backing: .buffered, defer: false)
        setupWindow()
        setupUI()
    }

    convenience init(screen: NSScreen) {
        self.init(contentRect: screen.frame, styleMask: [.borderless], backing: .buffered, defer: false)
        setFrameOrigin(screen.frame.origin)
    }

    private func setupWindow() {
        level = .screenSaver
        backgroundColor = NSColor.black.withAlphaComponent(0.92)
        isOpaque = false
        ignoresMouseEvents = false
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        acceptsMouseMovedEvents = true
        hidesOnDeactivate = false
    }

    private func setupUI() {
        guard let contentView else { return }

        let container = NSView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.wantsLayer = true
        container.layer?.backgroundColor = NSColor.windowBackgroundColor.withAlphaComponent(0.96).cgColor
        container.layer?.cornerRadius = 18
        contentView.addSubview(container)

        titleLabel = makeLabel("夜间屏幕禁用中", size: 34, weight: .semibold, color: .labelColor)
        subtitleLabel = makeLabel("现在不建议继续使用屏幕。", size: 18, weight: .regular, color: .secondaryLabelColor)
        countdownLabel = makeLabel("00:00:00", size: 62, weight: .bold, color: .systemIndigo, monospaced: true)
        recoveryLabel = makeLabel("", size: 20, weight: .medium, color: .labelColor)
        scheduleLabel = makeLabel("", size: 14, weight: .regular, color: .secondaryLabelColor)

        testingExitButton = NSButton(title: "测试退出", target: self, action: #selector(testingExitClicked))
        testingExitButton.font = NSFont.systemFont(ofSize: 12, weight: .medium)
        testingExitButton.bezelStyle = .rounded
        testingExitButton.translatesAutoresizingMaskIntoConstraints = false

        for view in [titleLabel!, subtitleLabel!, countdownLabel!, recoveryLabel!, scheduleLabel!] {
            container.addSubview(view)
        }
        contentView.addSubview(testingExitButton)

        NSLayoutConstraint.activate([
            container.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            container.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            container.widthAnchor.constraint(equalToConstant: 560),
            container.heightAnchor.constraint(equalToConstant: 360),

            titleLabel.topAnchor.constraint(equalTo: container.topAnchor, constant: 40),
            titleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 36),
            titleLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -36),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            subtitleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 36),
            subtitleLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -36),

            countdownLabel.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 32),
            countdownLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 36),
            countdownLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -36),

            recoveryLabel.topAnchor.constraint(equalTo: countdownLabel.bottomAnchor, constant: 28),
            recoveryLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 36),
            recoveryLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -36),

            scheduleLabel.topAnchor.constraint(equalTo: recoveryLabel.bottomAnchor, constant: 14),
            scheduleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 36),
            scheduleLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -36),

            testingExitButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            testingExitButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -24),
            testingExitButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 76),
            testingExitButton.heightAnchor.constraint(equalToConstant: 30)
        ])
    }

    private func makeLabel(_ text: String, size: CGFloat, weight: NSFont.Weight, color: NSColor, monospaced: Bool = false) -> NSTextField {
        let label = NSTextField(labelWithString: text)
        label.font = monospaced ? NSFont.monospacedDigitSystemFont(ofSize: size, weight: weight) : NSFont.systemFont(ofSize: size, weight: weight)
        label.textColor = color
        label.alignment = .center
        label.lineBreakMode = .byWordWrapping
        label.maximumNumberOfLines = 0
        label.backgroundColor = .clear
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }

    func configure(unlockTime: Date, scheduleText: String, testingExitEnabled: Bool) {
        scheduleLabel.stringValue = scheduleText
        testingExitButton.isHidden = !testingExitEnabled
        resetTestingExitConfirmation()
        update(unlockTime: unlockTime, now: Date())
    }

    func update(unlockTime: Date, now: Date) {
        let remaining = max(0, Int(unlockTime.timeIntervalSince(now)))
        countdownLabel.stringValue = formatRemaining(remaining)
        recoveryLabel.stringValue = "\(formatClock(unlockTime)) 自动恢复"
    }

    func showOverlay() {
        makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        makeKey()
    }

    func hideOverlay() {
        confirmationTimer?.invalidate()
        confirmationTimer = nil
        orderOut(nil)
    }

    private func formatRemaining(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let secs = seconds % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, secs)
    }

    private func formatClock(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }

    @objc private func testingExitClicked() {
        guard !isConfirmingTestingExit else {
            nightDelegate?.didRequestNightTestingExit()
            return
        }

        isConfirmingTestingExit = true
        testingExitButton.title = "再次点击确认"
        confirmationTimer?.invalidate()
        confirmationTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { [weak self] _ in
            self?.resetTestingExitConfirmation()
        }
    }

    private func resetTestingExitConfirmation() {
        isConfirmingTestingExit = false
        testingExitButton?.title = "测试退出"
        confirmationTimer?.invalidate()
        confirmationTimer = nil
    }

    override var canBecomeKey: Bool {
        true
    }
}
