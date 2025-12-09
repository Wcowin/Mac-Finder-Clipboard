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
    }
    
    // 检查辅助功能权限
    var isAccessibilityEnabled: Bool {
        AXIsProcessTrusted()
    }
    
    func updateAccessibilityStatus() {
        let hasPermission = isAccessibilityEnabled
        
        // 更新菜单栏图标
        if let button = statusItem?.button {
            if hasPermission {
                button.image = NSImage(systemSymbolName: "scissors", accessibilityDescription: "FinderClip")
            } else {
                button.image = NSImage(systemSymbolName: "exclamationmark.triangle.fill", accessibilityDescription: "需要权限")
            }
            button.image?.isTemplate = true
        }
        
        // 更新权限菜单项
        if hasPermission {
            accessibilityMenuItem?.title = "✓ 已就绪"
            accessibilityMenuItem?.isEnabled = false
        } else {
            accessibilityMenuItem?.title = "⚠ 点击授予权限..."
            accessibilityMenuItem?.isEnabled = true
        }
        
        // 发送通知给设置界面
        NotificationCenter.default.post(name: .accessibilityStatusChanged, object: hasPermission)
    }
    
    func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "scissors", accessibilityDescription: "FinderClip")
            button.image?.isTemplate = true
        }
        
        let menu = NSMenu()
        
        // 权限状态（可点击）
        accessibilityMenuItem = NSMenuItem(
            title: "检查权限中...",
            action: #selector(openAccessibilitySettings),
            keyEquivalent: ""
        )
        accessibilityMenuItem?.target = self
        menu.addItem(accessibilityMenuItem!)
        
        menu.addItem(NSMenuItem.separator())
        
        // 开机自启
        let launchItem = NSMenuItem(
            title: "开机自动启动",
            action: #selector(toggleLaunchAtLogin),
            keyEquivalent: ""
        )
        launchItem.target = self
        launchItem.state = launchAtLogin ? .on : .off
        menu.addItem(launchItem)
        
        // 设置
        menu.addItem(NSMenuItem(
            title: "设置...",
            action: #selector(openSettings),
            keyEquivalent: ","
        ))
        
        menu.addItem(NSMenuItem.separator())
        
        // 关于
        menu.addItem(NSMenuItem(
            title: "关于 FinderClip",
            action: #selector(showAbout),
            keyEquivalent: ""
        ))
        
        // 退出
        menu.addItem(NSMenuItem(
            title: "退出",
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
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.0"
        
        let alert = NSAlert()
        alert.messageText = "FinderClip"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "确定")
        
        // 创建自定义视图以支持可点击链接
        let contentView = NSView(frame: NSRect(x: 0, y: 0, width: 260, height: 160))
        
        // 版本号
        let versionLabel = NSTextField(labelWithString: "版本 \(version)")
        versionLabel.frame = NSRect(x: 0, y: 135, width: 260, height: 18)
        versionLabel.alignment = .center
        versionLabel.font = NSFont.systemFont(ofSize: 12)
        versionLabel.textColor = .secondaryLabelColor
        contentView.addSubview(versionLabel)
        
        // 描述
        let descLabel = NSTextField(labelWithString: "为 Finder 提供直观的剪切粘贴体验")
        descLabel.frame = NSRect(x: 0, y: 105, width: 260, height: 18)
        descLabel.alignment = .center
        descLabel.font = NSFont.systemFont(ofSize: 12)
        contentView.addSubview(descLabel)
        
        // 快捷键
        let shortcutsLabel = NSTextField(labelWithString: "⌘X - 剪切文件\n⌘V - 移动文件\nEsc - 取消剪切")
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
}
