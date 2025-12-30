//
//  AppDelegate.swift
//  FinderClip
//
//  Created by Wcowin on 2025/11/29.
//

import Cocoa
import ServiceManagement
import Sparkle

class AppDelegate: NSObject, NSApplicationDelegate {
    static var shared: AppDelegate?
    
    var statusItem: NSStatusItem?
    var finderCutManager: FinderCutPasteManager?
    var accessibilityMenuItem: NSMenuItem?
    
    // Sparkle 更新控制器
    let updaterController = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)
    
    // 开机自启状态
    var launchAtLogin: Bool {
        get {
            if #available(macOS 13.0, *) {
                return SMAppService.mainApp.status == .enabled
            } else {
                return false
            }
        }
        set {
            if #available(macOS 13.0, *) {
                do {
                    if newValue {
                        try SMAppService.mainApp.register()
                    } else {
                        try SMAppService.mainApp.unregister()
                    }
                } catch {
                    print("[FinderClip] 设置开机自启失败: \(error)")
                }
            }
        }
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        print("[FinderClip] 应用启动")
        AppDelegate.shared = self
        
        // 创建菜单栏图标
        setupMenuBar()
        
        // 初始化 Finder 剪切管理器
        finderCutManager = FinderCutPasteManager()
        
        // 默认启用功能
        Task { @MainActor in
            self.finderCutManager?.isEnabled = true
            self.updateAccessibilityStatus()
        }
        
        // 定时检查权限状态
        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            DispatchQueue.main.async {
                self?.updateAccessibilityStatus()
            }
        }
        
        // 监听语言变化
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(languageChanged),
            name: .languageChanged,
            object: nil
        )
    }
    
    // 检查辅助功能权限
    var isAccessibilityEnabled: Bool {
        AXIsProcessTrusted()
    }
    
    func updateAccessibilityStatus() {
        let hasPermission = isAccessibilityEnabled
        let loc = LocalizationManager.shared
        
        // 更新菜单栏图标
        if let button = statusItem?.button {
            if hasPermission {
                button.image = NSImage(systemSymbolName: "scissors", accessibilityDescription: "FinderClip")
            } else {
                button.image = NSImage(systemSymbolName: "exclamationmark.triangle.fill", accessibilityDescription: loc.localized(.menuGrantPermission))
            }
            button.image?.isTemplate = true
        }
        
        // 更新权限菜单项
        if hasPermission {
            accessibilityMenuItem?.title = loc.localized(.menuReady)
            accessibilityMenuItem?.isEnabled = false
        } else {
            accessibilityMenuItem?.title = loc.localized(.menuGrantPermission)
            accessibilityMenuItem?.isEnabled = true
        }
        
        // 发送通知给设置界面
        NotificationCenter.default.post(name: .accessibilityStatusChanged, object: hasPermission)
    }
    
    func setupMenuBar() {
        let loc = LocalizationManager.shared
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "scissors", accessibilityDescription: "FinderClip")
            button.image?.isTemplate = true
        }
        
        let menu = NSMenu()
        
        // 权限状态（可点击）
        accessibilityMenuItem = NSMenuItem(
            title: loc.localized(.menuCheckingPermission),
            action: #selector(openAccessibilitySettings),
            keyEquivalent: ""
        )
        accessibilityMenuItem?.target = self
        menu.addItem(accessibilityMenuItem!)
        
        menu.addItem(NSMenuItem.separator())
        
        // 开机自启
        let launchItem = NSMenuItem(
            title: loc.localized(.menuLaunchAtLogin),
            action: #selector(toggleLaunchAtLogin),
            keyEquivalent: ""
        )
        launchItem.target = self
        launchItem.state = launchAtLogin ? .on : .off
        menu.addItem(launchItem)
        
        // 设置
        menu.addItem(NSMenuItem(
            title: loc.localized(.menuSettings),
            action: #selector(openSettings),
            keyEquivalent: ","
        ))
        
        menu.addItem(NSMenuItem.separator())
        
        // 检查更新
        menu.addItem(NSMenuItem(
            title: loc.localized(.menuCheckForUpdates),
            action: #selector(checkForUpdates),
            keyEquivalent: ""
        ))
        
        // 关于
        menu.addItem(NSMenuItem(
            title: loc.localized(.menuAbout),
            action: #selector(showAbout),
            keyEquivalent: ""
        ))
        
        // 退出
        menu.addItem(NSMenuItem(
            title: loc.localized(.menuQuit),
            action: #selector(quit),
            keyEquivalent: "q"
        ))
        
        statusItem?.menu = menu
    }
    
    @objc func toggleFeature(_ sender: NSMenuItem) {
        let isEnabled = sender.state == .off
        sender.state = isEnabled ? .on : .off
        
        Task { @MainActor in
            self.finderCutManager?.isEnabled = isEnabled
        }
    }
    
    @objc func openAccessibilitySettings() {
        Task { @MainActor in
            self.finderCutManager?.openSystemPreferences()
        }
    }
    
    @objc func showAbout() {
        let loc = LocalizationManager.shared
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.0"
        
        let alert = NSAlert()
        alert.messageText = loc.localized(.appName)
        alert.alertStyle = .informational
        alert.addButton(withTitle: loc.localized(.aboutOK))
        
        // 创建自定义视图以支持可点击链接
        let contentView = NSView(frame: NSRect(x: 0, y: 0, width: 260, height: 160))
        
        // 版本号
        let versionLabel = NSTextField(labelWithString: "\(loc.localized(.aboutVersion)) \(version)")
        versionLabel.frame = NSRect(x: 0, y: 135, width: 260, height: 18)
        versionLabel.alignment = .center
        versionLabel.font = NSFont.systemFont(ofSize: 12)
        versionLabel.textColor = .secondaryLabelColor
        contentView.addSubview(versionLabel)
        
        // 描述
        let descLabel = NSTextField(labelWithString: loc.localized(.aboutDescription))
        descLabel.frame = NSRect(x: 0, y: 105, width: 260, height: 18)
        descLabel.alignment = .center
        descLabel.font = NSFont.systemFont(ofSize: 12)
        contentView.addSubview(descLabel)
        
        // 快捷键
        let shortcutsLabel = NSTextField(labelWithString: loc.localized(.aboutShortcuts))
        shortcutsLabel.frame = NSRect(x: 0, y: 45, width: 260, height: 50)
        shortcutsLabel.alignment = .center
        shortcutsLabel.font = NSFont.systemFont(ofSize: 11)
        shortcutsLabel.textColor = .secondaryLabelColor
        contentView.addSubview(shortcutsLabel)
        
        // 版权信息（可点击链接，居中显示）
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        
        let copyrightText = NSMutableAttributedString(
            string: "© 2025 ",
            attributes: [
                .font: NSFont.systemFont(ofSize: 11),
                .paragraphStyle: paragraphStyle
            ]
        )
        let linkText = NSAttributedString(
            string: "Wcowin",
            attributes: [
                .link: URL(string: "https://wcowin.work/")!,
                .font: NSFont.systemFont(ofSize: 11),
                .paragraphStyle: paragraphStyle
            ]
        )
        copyrightText.append(linkText)
        
        let textView = NSTextView(frame: NSRect(x: 0, y: 5, width: 260, height: 20))
        textView.textStorage?.setAttributedString(copyrightText)
        textView.isEditable = false
        textView.isSelectable = true
        textView.drawsBackground = false
        textView.alignment = .center
        contentView.addSubview(textView)
        
        alert.accessoryView = contentView
        alert.runModal()
    }
    
    @objc func toggleLaunchAtLogin(_ sender: NSMenuItem) {
        launchAtLogin = !launchAtLogin
        sender.state = launchAtLogin ? .on : .off
    }
    
    @objc func openSettings() {
        SettingsWindowController.show()
    }
    
    @objc func checkForUpdates() {
        updaterController.checkForUpdates(nil)
    }
    
    @objc func quit() {
        NSApplication.shared.terminate(nil)
    }
    
    @objc func languageChanged() {
        setupMenuBar()
        updateAccessibilityStatus()
    }
}
