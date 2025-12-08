//
//  SettingsWindowController.swift
//  FinderClip
//
//  Created by Wcowin on 2025/12/09.
//

import Cocoa

class SettingsWindowController: NSWindowController {
    
    static var shared: SettingsWindowController?
    
    private var timeoutPopup: NSPopUpButton!
    private var notificationSwitch: NSSwitch!
    private var soundSwitch: NSSwitch!
    private var cutCountSwitch: NSSwitch!
    private var accessibilityStatusView: NSView?
    private var accessibilityLabel: NSTextField?
    private var accessibilityIcon: NSImageView?
    
    convenience init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 420, height: 520),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.title = ""
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.isMovableByWindowBackground = true
        window.center()
        window.isReleasedWhenClosed = false
        
        // 使用毛玻璃效果背景
        let visualEffect = NSVisualEffectView()
        visualEffect.blendingMode = .behindWindow
        visualEffect.state = .active
        visualEffect.material = .sidebar
        window.contentView = visualEffect
        
        self.init(window: window)
        setupUI()
        loadSettings()
        
        // 监听权限状态变化
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updateAccessibilityUI),
            name: .accessibilityStatusChanged,
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func setupUI() {
        guard let window = window, let contentView = window.contentView else { return }
        
        // 主容器
        let container = NSStackView()
        container.orientation = .vertical
        container.spacing = 16
        container.translatesAutoresizingMaskIntoConstraints = false
        container.edgeInsets = NSEdgeInsets(top: 24, left: 28, bottom: 24, right: 28)
        contentView.addSubview(container)
        
        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: contentView.topAnchor),
            container.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            container.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
        
        // 头部
        let headerView = createHeaderView()
        container.addArrangedSubview(headerView)
        
        // 所有设置合并到一个卡片
        let settingsCard = createMainSettingsCard()
        container.addArrangedSubview(settingsCard)
        
        // 辅助功能权限状态
        let accessibilityCard = createAccessibilityStatusCard()
        container.addArrangedSubview(accessibilityCard)
        
        // 快捷键提示
        let shortcutHint = createShortcutHint()
        container.addArrangedSubview(shortcutHint)
        
        // 底部按钮
        let footerView = createFooterView()
        container.addArrangedSubview(footerView)
        
        container.setCustomSpacing(12, after: headerView)
        container.setCustomSpacing(12, after: settingsCard)
        container.setCustomSpacing(12, after: accessibilityCard)
        
        // 初始化权限状态
        updateAccessibilityUI()
    }
    
    // MARK: - Accessibility Status Card
    private func createAccessibilityStatusCard() -> NSView {
        let card = NSView()
        card.translatesAutoresizingMaskIntoConstraints = false
        card.wantsLayer = true
        card.layer?.cornerRadius = 10
        card.heightAnchor.constraint(equalToConstant: 44).isActive = true
        accessibilityStatusView = card
        
        // 图标
        let iconView = NSImageView()
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.symbolConfiguration = NSImage.SymbolConfiguration(pointSize: 14, weight: .medium)
        card.addSubview(iconView)
        accessibilityIcon = iconView
        
        // 标签
        let label = NSTextField(labelWithString: "检查权限中...")
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = NSFont.systemFont(ofSize: 13, weight: .medium)
        card.addSubview(label)
        accessibilityLabel = label
        
        // 按钮
        let actionButton = NSButton(title: "打开设置", target: self, action: #selector(openAccessibilitySettings))
        actionButton.translatesAutoresizingMaskIntoConstraints = false
        actionButton.bezelStyle = .rounded
        actionButton.controlSize = .small
        card.addSubview(actionButton)
        
        NSLayoutConstraint.activate([
            iconView.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 14),
            iconView.centerYAnchor.constraint(equalTo: card.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 20),
            iconView.heightAnchor.constraint(equalToConstant: 20),
            
            label.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 10),
            label.centerYAnchor.constraint(equalTo: card.centerYAnchor),
            
            actionButton.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -14),
            actionButton.centerYAnchor.constraint(equalTo: card.centerYAnchor)
        ])
        
        return card
    }
    
    @objc private func updateAccessibilityUI() {
        let hasPermission = AXIsProcessTrusted()
        
        if hasPermission {
            accessibilityStatusView?.layer?.backgroundColor = NSColor.systemGreen.withAlphaComponent(0.15).cgColor
            accessibilityIcon?.image = NSImage(systemSymbolName: "checkmark.shield.fill", accessibilityDescription: nil)
            accessibilityIcon?.contentTintColor = .systemGreen
            accessibilityLabel?.stringValue = "辅助功能权限已授予"
            accessibilityLabel?.textColor = .systemGreen
        } else {
            accessibilityStatusView?.layer?.backgroundColor = NSColor.systemOrange.withAlphaComponent(0.15).cgColor
            accessibilityIcon?.image = NSImage(systemSymbolName: "exclamationmark.shield.fill", accessibilityDescription: nil)
            accessibilityIcon?.contentTintColor = .systemOrange
            accessibilityLabel?.stringValue = "需要辅助功能权限"
            accessibilityLabel?.textColor = .systemOrange
        }
    }
    
    @objc private func openAccessibilitySettings() {
        let url = "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
        if let settingsURL = URL(string: url) {
            NSWorkspace.shared.open(settingsURL)
        }
    }
    
    // MARK: - Header
    private func createHeaderView() -> NSView {
        let view = NSView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.heightAnchor.constraint(equalToConstant: 80).isActive = true
        
        // 应用图标
        let iconView = NSImageView()
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.image = NSApp.applicationIconImage
        iconView.imageScaling = .scaleProportionallyUpOrDown
        view.addSubview(iconView)
        
        // 标题
        let titleLabel = NSTextField(labelWithString: "FinderClip")
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = NSFont.systemFont(ofSize: 20, weight: .semibold)
        titleLabel.textColor = .labelColor
        view.addSubview(titleLabel)
        
        // 副标题
        let subtitleLabel = NSTextField(labelWithString: "为 Finder 带来真正的剪切粘贴")
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.font = NSFont.systemFont(ofSize: 12)
        subtitleLabel.textColor = .secondaryLabelColor
        view.addSubview(subtitleLabel)
        
        // 版本号
        let versionLabel = NSTextField(labelWithString: "v1.0.0")
        versionLabel.translatesAutoresizingMaskIntoConstraints = false
        versionLabel.font = NSFont.monospacedSystemFont(ofSize: 10, weight: .regular)
        versionLabel.textColor = .tertiaryLabelColor
        view.addSubview(versionLabel)
        
        NSLayoutConstraint.activate([
            iconView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 4),
            iconView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 56),
            iconView.heightAnchor.constraint(equalToConstant: 56),
            
            titleLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 14),
            titleLabel.topAnchor.constraint(equalTo: iconView.topAnchor, constant: 6),
            
            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 2),
            
            versionLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -4),
            versionLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 8)
        ])
        
        return view
    }
    
    // MARK: - Main Settings Card
    private func createMainSettingsCard() -> NSView {
        let card = NSView()
        card.translatesAutoresizingMaskIntoConstraints = false
        card.wantsLayer = true
        card.layer?.backgroundColor = NSColor.controlBackgroundColor.withAlphaComponent(0.6).cgColor
        card.layer?.cornerRadius = 12
        
        let stack = NSStackView()
        stack.orientation = .vertical
        stack.spacing = 0
        stack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(stack)
        
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: card.topAnchor, constant: 4),
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -4)
        ])
        
        // 超时设置
        stack.addArrangedSubview(createTimeoutSection())
        stack.addArrangedSubview(createDivider())
        
        // 通知设置
        stack.addArrangedSubview(createNotificationSection())
        stack.addArrangedSubview(createDivider())
        
        // 显示设置
        stack.addArrangedSubview(createDisplaySection())
        
        return card
    }
    
    // MARK: - Shortcut Hint
    private func createShortcutHint() -> NSView {
        let container = NSView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.wantsLayer = true
        container.layer?.backgroundColor = NSColor.controlAccentColor.withAlphaComponent(0.08).cgColor
        container.layer?.cornerRadius = 8
        container.heightAnchor.constraint(equalToConstant: 60).isActive = true
        
        let stack = NSStackView()
        stack.orientation = .horizontal
        stack.spacing = 24
        stack.alignment = .centerY
        stack.distribution = .fillEqually
        stack.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(stack)
        
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: container.centerYAnchor)
        ])
        
        stack.addArrangedSubview(createShortcutItem(key: "⌘X", label: "剪切"))
        stack.addArrangedSubview(createShortcutItem(key: "⌘V", label: "粘贴"))
        stack.addArrangedSubview(createShortcutItem(key: "Esc", label: "取消"))
        
        return container
    }
    
    private func createShortcutItem(key: String, label: String) -> NSView {
        let stack = NSStackView()
        stack.orientation = .vertical
        stack.spacing = 4
        stack.alignment = .centerX
        
        let keyLabel = NSTextField(labelWithString: key)
        keyLabel.font = NSFont.monospacedSystemFont(ofSize: 14, weight: .medium)
        keyLabel.textColor = .controlAccentColor
        
        let descLabel = NSTextField(labelWithString: label)
        descLabel.font = NSFont.systemFont(ofSize: 11)
        descLabel.textColor = .secondaryLabelColor
        
        stack.addArrangedSubview(keyLabel)
        stack.addArrangedSubview(descLabel)
        
        return stack
    }
    
    // MARK: - Timeout Section
    private func createTimeoutSection() -> NSView {
        let container = NSView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.heightAnchor.constraint(equalToConstant: 48).isActive = true
        
        let iconView = createSettingIcon("clock.fill", color: .systemOrange)
        container.addSubview(iconView)
        
        let titleLabel = NSTextField(labelWithString: "剪切超时")
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = NSFont.systemFont(ofSize: 13)
        titleLabel.textColor = .labelColor
        container.addSubview(titleLabel)
        
        timeoutPopup = NSPopUpButton()
        timeoutPopup.translatesAutoresizingMaskIntoConstraints = false
        timeoutPopup.controlSize = .small
        timeoutPopup.font = NSFont.systemFont(ofSize: 12)
        timeoutPopup.addItems(withTitles: ["1 分钟", "3 分钟", "5 分钟", "10 分钟", "30 分钟", "永不"])
        timeoutPopup.target = self
        timeoutPopup.action = #selector(timeoutChanged)
        container.addSubview(timeoutPopup)
        
        NSLayoutConstraint.activate([
            iconView.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 14),
            iconView.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            
            titleLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 10),
            titleLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            
            timeoutPopup.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -14),
            timeoutPopup.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            timeoutPopup.widthAnchor.constraint(equalToConstant: 90)
        ])
        
        return container
    }
    
    private func createSettingIcon(_ name: String, color: NSColor) -> NSView {
        let container = NSView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.wantsLayer = true
        container.layer?.backgroundColor = color.withAlphaComponent(0.15).cgColor
        container.layer?.cornerRadius = 6
        
        let iconView = NSImageView()
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.image = NSImage(systemSymbolName: name, accessibilityDescription: nil)
        iconView.contentTintColor = color
        iconView.symbolConfiguration = NSImage.SymbolConfiguration(pointSize: 12, weight: .medium)
        container.addSubview(iconView)
        
        NSLayoutConstraint.activate([
            container.widthAnchor.constraint(equalToConstant: 26),
            container.heightAnchor.constraint(equalToConstant: 26),
            iconView.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            iconView.centerYAnchor.constraint(equalTo: container.centerYAnchor)
        ])
        
        return container
    }
    
    // MARK: - Notification Section
    private func createNotificationSection() -> NSView {
        let stack = NSStackView()
        stack.orientation = .vertical
        stack.spacing = 0
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        // 显示通知
        let notifRow = createIconSwitchRow(
            icon: "bell.fill",
            iconColor: .systemRed,
            title: "显示通知"
        ) { [weak self] sw in
            self?.notificationSwitch = sw
            sw.target = self
            sw.action = #selector(self?.notificationChanged)
        }
        stack.addArrangedSubview(notifRow)
        
        stack.addArrangedSubview(createDivider())
        
        // 播放声音
        let soundRow = createIconSwitchRow(
            icon: "speaker.wave.2.fill",
            iconColor: .systemPink,
            title: "提示音"
        ) { [weak self] sw in
            self?.soundSwitch = sw
            sw.target = self
            sw.action = #selector(self?.soundChanged)
        }
        stack.addArrangedSubview(soundRow)
        
        return stack
    }
    
    // MARK: - Display Section
    private func createDisplaySection() -> NSView {
        let container = createIconSwitchRow(
            icon: "number.circle.fill",
            iconColor: .systemBlue,
            title: "显示数量角标"
        ) { [weak self] sw in
            self?.cutCountSwitch = sw
            sw.target = self
            sw.action = #selector(self?.cutCountChanged)
        }
        return container
    }
    
    // MARK: - Helpers
    private func createIconSwitchRow(icon: String, iconColor: NSColor, title: String, configure: (NSSwitch) -> Void) -> NSView {
        let container = NSView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.heightAnchor.constraint(equalToConstant: 48).isActive = true
        
        let iconView = createSettingIcon(icon, color: iconColor)
        container.addSubview(iconView)
        
        let titleLabel = NSTextField(labelWithString: title)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = NSFont.systemFont(ofSize: 13)
        titleLabel.textColor = .labelColor
        container.addSubview(titleLabel)
        
        let toggle = NSSwitch()
        toggle.translatesAutoresizingMaskIntoConstraints = false
        toggle.controlSize = .small
        configure(toggle)
        container.addSubview(toggle)
        
        NSLayoutConstraint.activate([
            iconView.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 14),
            iconView.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            
            titleLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 10),
            titleLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            
            toggle.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -14),
            toggle.centerYAnchor.constraint(equalTo: container.centerYAnchor)
        ])
        
        return container
    }
    
    private func createDivider() -> NSView {
        let container = NSView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.heightAnchor.constraint(equalToConstant: 1).isActive = true
        
        let line = NSView()
        line.translatesAutoresizingMaskIntoConstraints = false
        line.wantsLayer = true
        line.layer?.backgroundColor = NSColor.separatorColor.withAlphaComponent(0.5).cgColor
        container.addSubview(line)
        
        NSLayoutConstraint.activate([
            line.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 50),
            line.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -14),
            line.heightAnchor.constraint(equalToConstant: 0.5),
            line.centerYAnchor.constraint(equalTo: container.centerYAnchor)
        ])
        
        return container
    }
    
    // MARK: - Footer
    private func createFooterView() -> NSView {
        let view = NSView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.heightAnchor.constraint(equalToConstant: 36).isActive = true
        
        let resetButton = NSButton(title: "恢复默认", target: self, action: #selector(resetToDefaults))
        resetButton.translatesAutoresizingMaskIntoConstraints = false
        resetButton.bezelStyle = .accessoryBarAction
        resetButton.controlSize = .regular
        resetButton.isBordered = false
        resetButton.contentTintColor = .secondaryLabelColor
        view.addSubview(resetButton)
        
        let doneButton = NSButton(title: "完成", target: self, action: #selector(closeWindow))
        doneButton.translatesAutoresizingMaskIntoConstraints = false
        doneButton.bezelStyle = .rounded
        doneButton.controlSize = .regular
        doneButton.keyEquivalent = "\r"
        view.addSubview(doneButton)
        
        NSLayoutConstraint.activate([
            resetButton.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            resetButton.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            
            doneButton.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            doneButton.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            doneButton.widthAnchor.constraint(equalToConstant: 70)
        ])
        
        return view
    }
    
    // MARK: - Settings
    private func loadSettings() {
        let settings = SettingsManager.shared
        
        switch settings.cutTimeout {
        case 60: timeoutPopup.selectItem(at: 0)
        case 180: timeoutPopup.selectItem(at: 1)
        case 300: timeoutPopup.selectItem(at: 2)
        case 600: timeoutPopup.selectItem(at: 3)
        case 1800: timeoutPopup.selectItem(at: 4)
        default: timeoutPopup.selectItem(at: 5)
        }
        
        notificationSwitch.state = settings.showNotifications ? .on : .off
        soundSwitch.state = settings.soundEnabled ? .on : .off
        cutCountSwitch.state = settings.showCutCount ? .on : .off
    }
    
    @objc private func timeoutChanged() {
        let timeouts = [60, 180, 300, 600, 1800, Int.max]
        let index = timeoutPopup.indexOfSelectedItem
        if index >= 0 && index < timeouts.count {
            SettingsManager.shared.cutTimeout = timeouts[index]
        }
    }
    
    @objc private func notificationChanged() {
        SettingsManager.shared.showNotifications = notificationSwitch.state == .on
    }
    
    @objc private func soundChanged() {
        SettingsManager.shared.soundEnabled = soundSwitch.state == .on
    }
    
    @objc private func cutCountChanged() {
        SettingsManager.shared.showCutCount = cutCountSwitch.state == .on
    }
    
    @objc private func resetToDefaults() {
        SettingsManager.shared.cutTimeout = 300
        SettingsManager.shared.showNotifications = true
        SettingsManager.shared.showCutCount = true
        SettingsManager.shared.soundEnabled = true
        loadSettings()
    }
    
    @objc private func closeWindow() {
        window?.close()
    }
    
    static func show() {
        if shared == nil {
            shared = SettingsWindowController()
        }
        shared?.showWindow(nil)
        shared?.window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
