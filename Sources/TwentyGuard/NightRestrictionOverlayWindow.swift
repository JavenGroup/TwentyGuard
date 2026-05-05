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

        titleLabel = makeLabel("夜间禁用", size: 18, weight: .medium, color: .secondaryLabelColor)
        subtitleLabel = makeLabel("屏幕已禁用", size: 44, weight: .semibold, color: .labelColor)
        countdownLabel = makeLabel("00:00:00", size: 86, weight: .bold, color: .labelColor, monospaced: true)
        recoveryLabel = makeLabel("", size: 22, weight: .semibold, color: .labelColor)
        scheduleLabel = makeLabel("", size: 15, weight: .regular, color: .secondaryLabelColor)

        testingExitButton = NSButton(title: "测试出口", target: self, action: #selector(testingExitClicked))
        testingExitButton.font = NSFont.systemFont(ofSize: 11, weight: .regular)
        testingExitButton.bezelStyle = .inline
        testingExitButton.translatesAutoresizingMaskIntoConstraints = false
        testingExitButton.contentTintColor = .secondaryLabelColor

        for view in [titleLabel!, subtitleLabel!, countdownLabel!, recoveryLabel!, scheduleLabel!] {
            contentView.addSubview(view)
        }
        contentView.addSubview(testingExitButton)

        NSLayoutConstraint.activate([
            countdownLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            countdownLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor, constant: -10),
            countdownLabel.leadingAnchor.constraint(greaterThanOrEqualTo: contentView.leadingAnchor, constant: 56),
            countdownLabel.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -56),

            subtitleLabel.bottomAnchor.constraint(equalTo: countdownLabel.topAnchor, constant: -34),
            subtitleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: contentView.leadingAnchor, constant: 56),
            subtitleLabel.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -56),
            subtitleLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),

            titleLabel.bottomAnchor.constraint(equalTo: subtitleLabel.topAnchor, constant: -12),
            titleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: contentView.leadingAnchor, constant: 56),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -56),
            titleLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),

            recoveryLabel.topAnchor.constraint(equalTo: countdownLabel.bottomAnchor, constant: 38),
            recoveryLabel.leadingAnchor.constraint(greaterThanOrEqualTo: contentView.leadingAnchor, constant: 56),
            recoveryLabel.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -56),
            recoveryLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),

            scheduleLabel.topAnchor.constraint(equalTo: recoveryLabel.bottomAnchor, constant: 18),
            scheduleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: contentView.leadingAnchor, constant: 56),
            scheduleLabel.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -56),
            scheduleLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),

            testingExitButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -22),
            testingExitButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -18),
            testingExitButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 68),
            testingExitButton.heightAnchor.constraint(equalToConstant: 24)
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
        recoveryLabel.stringValue = "\(formatClock(unlockTime)) 恢复使用"
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
        testingExitButton?.title = "测试出口"
        confirmationTimer?.invalidate()
        confirmationTimer = nil
    }

    override var canBecomeKey: Bool {
        true
    }
}
