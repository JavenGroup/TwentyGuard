import Cocoa

protocol BreakOverlayDelegate: AnyObject {
    func didRequestPostpone(minutes: Int)
}

class BreakOverlayWindow: NSWindow {
    weak var breakDelegate: BreakOverlayDelegate?
    
    private var countdownLabel: NSTextField!
    private var leftLabels: [NSTextField]!
    private var colonLabels: [NSTextField]!
    private var rightLabels: [NSTextField]!
    private var postpone1Button: NSButton!
    private var postpone2Button: NSButton!
    private var postpone5Button: NSButton!
    
    // Localization closure
    private var localizer: ((String) -> String)?
    
    // Global keyboard monitor
    private var keyboardMonitor: Any?
    
    // Postpone count tracking (only for 5-minute postpone)
    private var remainingPostpone5Count: Int = 2
    
    override init(contentRect: NSRect, styleMask style: NSWindow.StyleMask, backing backingStoreType: NSWindow.BackingStoreType, defer flag: Bool) {
        super.init(contentRect: contentRect, styleMask: [.borderless], backing: .buffered, defer: false)
        
        setupWindow()
        setupUI()
    }
    
    convenience init(screen: NSScreen) {
        self.init(contentRect: screen.frame, styleMask: [.borderless], backing: .buffered, defer: false)
        // 设置窗口到指定屏幕
        self.setFrameOrigin(screen.frame.origin)
    }
    
    convenience init() {
        let screenFrame = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 1920, height: 1080)
        self.init(contentRect: screenFrame, styleMask: [.borderless], backing: .buffered, defer: false)
    }
    
    func setLocalizer(_ localizer: @escaping (String) -> String) {
        self.localizer = localizer
        updateTexts()
    }
    
    private func setupWindow() {
        level = .screenSaver
        backgroundColor = NSColor.black.withAlphaComponent(0.85)
        isOpaque = false
        ignoresMouseEvents = false
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        
        // Enable mouse events
        acceptsMouseMovedEvents = true
        
        // Keep borderless but ensure keyboard events
        hidesOnDeactivate = false
    }
    
    private func setupUI() {
        guard let contentView = contentView else { return }
        
        // Main container with rounded background
        let mainContainer = NSView()
        mainContainer.translatesAutoresizingMaskIntoConstraints = false
        mainContainer.wantsLayer = true
        mainContainer.layer?.backgroundColor = NSColor.controlBackgroundColor.withAlphaComponent(0.95).cgColor
        mainContainer.layer?.cornerRadius = 20
        contentView.addSubview(mainContainer)
        
        // Title label
        let titleLabel = NSTextField(labelWithString: "20-20-20 Eye Protection")
        titleLabel.font = NSFont.systemFont(ofSize: 28, weight: .medium)
        titleLabel.textColor = NSColor.labelColor
        titleLabel.alignment = .center
        titleLabel.isEditable = false
        titleLabel.isBordered = false
        titleLabel.backgroundColor = NSColor.clear
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Countdown container (simple, no circular border)
        let countdownContainer = NSView()
        countdownContainer.translatesAutoresizingMaskIntoConstraints = false
        
        countdownLabel = NSTextField(labelWithString: "")
        countdownLabel.font = NSFont.monospacedDigitSystemFont(ofSize: 80, weight: .bold)
        countdownLabel.textColor = NSColor.systemBlue
        countdownLabel.alignment = .center
        countdownLabel.isEditable = false
        countdownLabel.isBordered = false
        countdownLabel.backgroundColor = NSColor.clear
        countdownLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Rule text with proper colon alignment - create grid layout
        let ruleContainer = NSView()
        ruleContainer.translatesAutoresizingMaskIntoConstraints = false
        
        // Create labels for each row: left text, colon, right text
        let leftLabels = [NSTextField(labelWithString: ""), NSTextField(labelWithString: ""), NSTextField(labelWithString: "")]
        let colonLabels = [NSTextField(labelWithString: ":"), NSTextField(labelWithString: ":"), NSTextField(labelWithString: ":")]
        let rightLabels = [NSTextField(labelWithString: ""), NSTextField(labelWithString: ""), NSTextField(labelWithString: "")]
        
        // Style all labels
        for (i, labels) in [leftLabels, colonLabels, rightLabels].enumerated() {
            for label in labels {
                label.font = NSFont.systemFont(ofSize: 18)
                label.textColor = NSColor.secondaryLabelColor
                label.isEditable = false
                label.isBordered = false
                label.backgroundColor = NSColor.clear
                label.translatesAutoresizingMaskIntoConstraints = false
                
                // Set alignment
                if i == 0 { // Left labels - right aligned
                    label.alignment = .right
                } else if i == 1 { // Colon labels - center aligned
                    label.alignment = .center
                } else { // Right labels - left aligned
                    label.alignment = .left
                }
                
                ruleContainer.addSubview(label)
            }
        }
        
        // Store references for updating
        self.leftLabels = leftLabels
        self.colonLabels = colonLabels 
        self.rightLabels = rightLabels
        
        // Set up constraints for grid layout - center colons with countdown
        NSLayoutConstraint.activate([
            // Center the colon column with the container
            colonLabels[0].centerXAnchor.constraint(equalTo: ruleContainer.centerXAnchor),
            colonLabels[1].centerXAnchor.constraint(equalTo: ruleContainer.centerXAnchor),
            colonLabels[2].centerXAnchor.constraint(equalTo: ruleContainer.centerXAnchor),
            
            // Row 1
            leftLabels[0].topAnchor.constraint(equalTo: ruleContainer.topAnchor),
            leftLabels[0].trailingAnchor.constraint(equalTo: colonLabels[0].leadingAnchor, constant: -5),
            leftLabels[0].leadingAnchor.constraint(greaterThanOrEqualTo: ruleContainer.leadingAnchor),
            
            colonLabels[0].topAnchor.constraint(equalTo: ruleContainer.topAnchor),
            colonLabels[0].widthAnchor.constraint(equalToConstant: 20),
            
            rightLabels[0].topAnchor.constraint(equalTo: ruleContainer.topAnchor),
            rightLabels[0].leadingAnchor.constraint(equalTo: colonLabels[0].trailingAnchor, constant: 5),
            rightLabels[0].trailingAnchor.constraint(lessThanOrEqualTo: ruleContainer.trailingAnchor),
            
            // Row 2
            leftLabels[1].topAnchor.constraint(equalTo: leftLabels[0].bottomAnchor, constant: 8),
            leftLabels[1].trailingAnchor.constraint(equalTo: colonLabels[1].leadingAnchor, constant: -5),
            leftLabels[1].leadingAnchor.constraint(greaterThanOrEqualTo: ruleContainer.leadingAnchor),
            
            colonLabels[1].topAnchor.constraint(equalTo: colonLabels[0].bottomAnchor, constant: 8),
            colonLabels[1].widthAnchor.constraint(equalToConstant: 20),
            
            rightLabels[1].topAnchor.constraint(equalTo: rightLabels[0].bottomAnchor, constant: 8),
            rightLabels[1].leadingAnchor.constraint(equalTo: colonLabels[1].trailingAnchor, constant: 5),
            rightLabels[1].trailingAnchor.constraint(lessThanOrEqualTo: ruleContainer.trailingAnchor),
            
            // Row 3
            leftLabels[2].topAnchor.constraint(equalTo: leftLabels[1].bottomAnchor, constant: 8),
            leftLabels[2].trailingAnchor.constraint(equalTo: colonLabels[2].leadingAnchor, constant: -5),
            leftLabels[2].leadingAnchor.constraint(greaterThanOrEqualTo: ruleContainer.leadingAnchor),
            leftLabels[2].bottomAnchor.constraint(equalTo: ruleContainer.bottomAnchor),
            
            colonLabels[2].topAnchor.constraint(equalTo: colonLabels[1].bottomAnchor, constant: 8),
            colonLabels[2].widthAnchor.constraint(equalToConstant: 20),
            colonLabels[2].bottomAnchor.constraint(equalTo: ruleContainer.bottomAnchor),
            
            rightLabels[2].topAnchor.constraint(equalTo: rightLabels[1].bottomAnchor, constant: 8),
            rightLabels[2].leadingAnchor.constraint(equalTo: colonLabels[2].trailingAnchor, constant: 5),
            rightLabels[2].trailingAnchor.constraint(lessThanOrEqualTo: ruleContainer.trailingAnchor),
            rightLabels[2].bottomAnchor.constraint(equalTo: ruleContainer.bottomAnchor)
        ])
        
        // Modern button style
        postpone1Button = createStyledButton(title: "", action: #selector(postpone1ButtonClicked))
        postpone1Button.keyEquivalent = "1"
        postpone1Button.keyEquivalentModifierMask = .command
        
        postpone2Button = createStyledButton(title: "", action: #selector(postpone2ButtonClicked))
        postpone2Button.keyEquivalent = "2"
        postpone2Button.keyEquivalentModifierMask = .command
        
        postpone5Button = createStyledButton(title: "", action: #selector(postpone5ButtonClicked))
        postpone5Button.keyEquivalent = "5"
        postpone5Button.keyEquivalentModifierMask = .command
        
        // Add views to containers
        countdownContainer.addSubview(countdownLabel)
        mainContainer.addSubview(titleLabel)
        mainContainer.addSubview(countdownContainer)
        mainContainer.addSubview(ruleContainer)
        contentView.addSubview(postpone1Button)
        contentView.addSubview(postpone2Button)
        contentView.addSubview(postpone5Button)
        
        NSLayoutConstraint.activate([
            // Main container constraints
            mainContainer.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            mainContainer.centerYAnchor.constraint(equalTo: contentView.centerYAnchor, constant: -50),
            mainContainer.widthAnchor.constraint(equalToConstant: 500),
            mainContainer.heightAnchor.constraint(equalToConstant: 400),
            
            // Title constraints
            titleLabel.topAnchor.constraint(equalTo: mainContainer.topAnchor, constant: 30),
            titleLabel.centerXAnchor.constraint(equalTo: mainContainer.centerXAnchor),
            
            // Countdown container constraints
            countdownContainer.centerXAnchor.constraint(equalTo: mainContainer.centerXAnchor),
            countdownContainer.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 40),
            countdownContainer.widthAnchor.constraint(equalToConstant: 160),
            countdownContainer.heightAnchor.constraint(equalToConstant: 160),
            
            // Countdown label constraints
            countdownLabel.centerXAnchor.constraint(equalTo: countdownContainer.centerXAnchor),
            countdownLabel.centerYAnchor.constraint(equalTo: countdownContainer.centerYAnchor),
            
            // Rule container constraints
            ruleContainer.centerXAnchor.constraint(equalTo: mainContainer.centerXAnchor),
            ruleContainer.topAnchor.constraint(equalTo: countdownContainer.bottomAnchor, constant: 30),
            ruleContainer.leadingAnchor.constraint(equalTo: mainContainer.leadingAnchor, constant: 40),
            ruleContainer.trailingAnchor.constraint(equalTo: mainContainer.trailingAnchor, constant: -40),
            
            // Button constraints - auto-sizing for multi-language support
            postpone1Button.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -150),
            postpone1Button.heightAnchor.constraint(equalToConstant: 44),
            postpone1Button.widthAnchor.constraint(greaterThanOrEqualToConstant: 80),
            
            postpone2Button.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -150),
            postpone2Button.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            postpone2Button.heightAnchor.constraint(equalToConstant: 44),
            postpone2Button.widthAnchor.constraint(greaterThanOrEqualToConstant: 80),
            
            postpone5Button.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -150),
            postpone5Button.heightAnchor.constraint(equalToConstant: 44),
            postpone5Button.widthAnchor.constraint(greaterThanOrEqualToConstant: 80),
            
            // Horizontal spacing between buttons
            postpone2Button.leadingAnchor.constraint(greaterThanOrEqualTo: postpone1Button.trailingAnchor, constant: 20),
            postpone5Button.leadingAnchor.constraint(greaterThanOrEqualTo: postpone2Button.trailingAnchor, constant: 20),
            
            // Center the button group
            postpone1Button.trailingAnchor.constraint(equalTo: postpone2Button.leadingAnchor, constant: -20),
            postpone2Button.trailingAnchor.constraint(equalTo: postpone5Button.leadingAnchor, constant: -20)
        ])
    }
    
    private func createStyledButton(title: String, action: Selector) -> NSButton {
        let button = NSButton(title: title, target: self, action: action)
        button.font = NSFont.systemFont(ofSize: 16, weight: .medium)
        button.bezelStyle = .rounded
        button.wantsLayer = true
        button.layer?.backgroundColor = NSColor.controlAccentColor.withAlphaComponent(0.1).cgColor
        button.layer?.cornerRadius = 8
        button.translatesAutoresizingMaskIntoConstraints = false
        
        // 确保按钮能接收事件
        button.isEnabled = true
        
        // Enable content size calculation for auto-sizing
        button.setContentHuggingPriority(.required, for: .horizontal)
        button.setContentCompressionResistancePriority(.required, for: .horizontal)
        
        return button
    }
    
    func showOverlay() {
        print("🎭 显示休息覆盖窗口")
        
        // 确保按钮启用
        postpone1Button.isEnabled = true
        postpone2Button.isEnabled = true
        postpone5Button.isEnabled = true
        
        // Make window key and front
        makeKeyAndOrderFront(nil)
        
        // Force the application and window to become active
        NSApp.activate(ignoringOtherApps: true)
        makeKey()
        makeFirstResponder(self)
        
        print("🎭 窗口焦点状态: isKeyWindow=\(isKeyWindow), canBecomeKey=\(canBecomeKey)")
        
        // Set up global keyboard monitoring for shortcuts
        setupKeyboardMonitoring()
        
        // Additional attempts to ensure keyboard focus
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            NSApp.activate(ignoringOtherApps: true)
            self.makeKey()
            print("🎭 延迟后窗口焦点状态: isKeyWindow=\(self.isKeyWindow)")
            self.makeFirstResponder(self)
        }
    }
    
    private func setupKeyboardMonitoring() {
        // Remove existing monitor if any
        if let monitor = keyboardMonitor {
            NSEvent.removeMonitor(monitor)
        }
        
        // Set up global key monitor for Command+1, Command+2, Command+5
        keyboardMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            let modifierFlags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            if modifierFlags == .command {
                switch event.charactersIgnoringModifiers {
                case "1":
                    self?.postpone1ButtonClicked()
                case "2":
                    self?.postpone2ButtonClicked()
                case "5":
                    self?.postpone5ButtonClicked()
                default:
                    break
                }
            }
        }
    }
    
    func hideOverlay() {
        // Remove keyboard monitoring
        if let monitor = keyboardMonitor {
            NSEvent.removeMonitor(monitor)
            keyboardMonitor = nil
        }
        orderOut(nil)
    }
    
    func updateCountdown(_ seconds: Int) {
        countdownLabel.stringValue = "\(seconds)"
    }
    
    func setRemainingPostpone5Count(_ count: Int) {
        remainingPostpone5Count = count
        updatePostponeButtons()
    }
    
    private func updatePostponeButtons() {
        // 推迟1分钟和2分钟按钮始终启用
        postpone1Button.isEnabled = true
        postpone2Button.isEnabled = true
        
        // 推迟5分钟按钮根据剩余次数启用/禁用
        postpone5Button.isEnabled = remainingPostpone5Count > 0
        
        // 更新按钮标题
        if let localizer = localizer {
            // 推迟1分钟和2分钟按钮正常显示
            postpone1Button.title = localizer("postpone1")
            postpone2Button.title = localizer("postpone2")
            
            // 推迟5分钟按钮显示剩余次数
            if remainingPostpone5Count > 0 {
                postpone5Button.title = "\(localizer("postpone5")) (\(remainingPostpone5Count))"
            } else {
                postpone5Button.title = localizer("postpone5")
            }
        }
    }
    
    private func updateTexts() {
        guard let localizer = localizer else { return }
        
        // Find and update title label if it exists
        if let mainContainer = contentView?.subviews.first(where: { $0.layer?.cornerRadius == 20 }) {
            if let titleLabel = mainContainer.subviews.first(where: { $0 is NSTextField }) as? NSTextField {
                titleLabel.stringValue = localizer("breakOverlayTitle")
            }
        }
        
        // Parse the rule text and populate grid labels
        let ruleText = localizer("breakOverlayRule")
        let lines = ruleText.components(separatedBy: "\n")
        
        for (index, line) in lines.enumerated() {
            if index < leftLabels.count {
                let parts = line.components(separatedBy: " : ")
                if parts.count >= 2 {
                    leftLabels[index].stringValue = parts[0]
                    rightLabels[index].stringValue = parts[1]
                } else {
                    // Fallback if no colon separator found
                    leftLabels[index].stringValue = line
                    rightLabels[index].stringValue = ""
                }
            }
        }
        
        // 更新按钮文本时也要显示剩余次数
        updatePostponeButtons()
    }
    
    @objc private func postpone1ButtonClicked() {
        print("🔘 推迟1分钟按钮被点击")
        performPostpone(minutes: 1)
    }
    
    @objc private func postpone2ButtonClicked() {
        print("🔘 推迟2分钟按钮被点击") 
        performPostpone(minutes: 2)
    }
    
    @objc private func postpone5ButtonClicked() {
        print("🔘 推迟5分钟按钮被点击")
        performPostpone(minutes: 5)
    }
    
    private func performPostpone(minutes: Int) {
        // 记录哪个屏幕的窗口被点击
        let screenInfo = self.screen?.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] ?? "unknown"
        print("🔘 推迟 \(minutes) 分钟按钮被点击 - 屏幕: \(screenInfo)")
        print("  - 窗口状态: isVisible=\(self.isVisible), level=\(self.level.rawValue)")
        
        // 直接同步调用 delegate，让它统一清理所有窗口
        // 不要提前 hideOverlay()，不要异步调用
        breakDelegate?.didRequestPostpone(minutes: minutes)
    }
    
    // Override keyboard event handling for shortcuts
    override func keyDown(with event: NSEvent) {
        let modifierFlags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        let _ = event.keyCode
        
        // Check for Command key modifier
        if modifierFlags == .command {
            switch event.charactersIgnoringModifiers {
            case "1":
                postpone1ButtonClicked()
                return
            case "2":
                postpone2ButtonClicked()
                return
            case "5":
                postpone5ButtonClicked()
                return
            default:
                break
            }
        }
        
        super.keyDown(with: event)
    }
    
    // Ensure window can become key window and accept first responder
    override var canBecomeKey: Bool {
        return true
    }
    
    override var acceptsFirstResponder: Bool {
        return true
    }
    
    override func becomeFirstResponder() -> Bool {
        return true
    }
}