//
//  AppDelegate.swift
//  FinderClip
//
//  Created by Wcowin on 2025/11/29.
//

import Cocoa
import ServiceManagement

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var finderCutManager: FinderCutPasteManager?
    
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
        
        // 创建菜单栏图标
        setupMenuBar()
        
        // 初始化 Finder 剪切管理器
        finderCutManager = FinderCutPasteManager()
        
        // 默认启用功能
        Task { @MainActor in
            self.finderCutManager?.isEnabled = true
        }
    }
    
    func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "scissors", accessibilityDescription: "FinderClip")
            button.image?.isTemplate = true
        }
        
        let menu = NSMenu()
        
        // 状态显示
        let statusMenuItem = NSMenuItem(title: "FinderClip - 已启用", action: nil, keyEquivalent: "")
        statusMenuItem.isEnabled = false
        menu.addItem(statusMenuItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // 使用说明
        let helpItem = NSMenuItem(title: "使用说明", action: nil, keyEquivalent: "")
        let helpMenu = NSMenu()
        helpMenu.addItem(NSMenuItem(title: "⌘X - 剪切文件", action: nil, keyEquivalent: ""))
        helpMenu.addItem(NSMenuItem(title: "⌘V - 移动文件", action: nil, keyEquivalent: ""))
        helpMenu.addItem(NSMenuItem(title: "Esc - 取消剪切", action: nil, keyEquivalent: ""))
        helpItem.submenu = helpMenu
        menu.addItem(helpItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // 开关功能
        let toggleItem = NSMenuItem(
            title: "启用功能",
            action: #selector(toggleFeature),
            keyEquivalent: ""
        )
        toggleItem.target = self
        toggleItem.state = .on
        menu.addItem(toggleItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // 打开辅助功能设置
        menu.addItem(NSMenuItem(
            title: "打开辅助功能设置",
            action: #selector(openAccessibilitySettings),
            keyEquivalent: ""
        ))
        
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
            
            // 更新状态显示
            if let menu = self.statusItem?.menu,
               let statusItem = menu.items.first {
                statusItem.title = isEnabled ? "FinderClip - 已启用" : "FinderClip - 已禁用"
            }
        }
    }
    
    @objc func openAccessibilitySettings() {
        Task { @MainActor in
            self.finderCutManager?.openSystemPreferences()
        }
    }
    
    @objc func showAbout() {
        let alert = NSAlert()
        alert.messageText = "FinderClip"
        alert.informativeText = """
        版本 1.0.0
        
        为 Finder 提供直观的剪切粘贴体验
        
        ⌘X - 剪切文件
        ⌘V - 移动文件
        Esc - 取消剪切
        
        © 2025 Wcowin
        """
        alert.alertStyle = .informational
        alert.addButton(withTitle: "确定")
        alert.runModal()
    }
    
    @objc func toggleLaunchAtLogin(_ sender: NSMenuItem) {
        launchAtLogin = !launchAtLogin
        sender.state = launchAtLogin ? .on : .off
    }
    
    @objc func quit() {
        NSApplication.shared.terminate(nil)
    }
}
