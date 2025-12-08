//
//  FinderCutPasteManager.swift
//  FinderClip
//
//  Created by Wcowin on 2025/11/29.
//

import Foundation
import AppKit
import UserNotifications

@MainActor
class FinderCutPasteManager {
    var isEnabled: Bool = false {
        didSet {
            print("[FinderClip] 功能状态: \(isEnabled ? "已启用" : "已禁用")")
            if isEnabled {
                startMonitoring()
            } else {
                stopMonitoring()
            }
        }
    }
    
    // 使用 nonisolated(unsafe) 允许在回调中访问
    nonisolated(unsafe) private var isCutMode: Bool = false
    nonisolated(unsafe) private var cutTimestamp: Date?
    
    private var cutTimeout: TimeInterval {
        TimeInterval(SettingsManager.shared.cutTimeout)
    }
    
    nonisolated(unsafe) private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    
    init() {
        print("[FinderClip] 管理器已初始化")
        requestNotificationPermission()
        setupPermissionObserver()
    }
    
    private func setupPermissionObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppActivated),
            name: NSApplication.didBecomeActiveNotification,
            object: nil
        )
    }
    
    @objc private func handleAppActivated() {
        guard isEnabled else { return }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self = self else { return }
            
            let hasPermission = AXIsProcessTrusted()
            print("[FinderClip] 应用激活，权限状态: \(hasPermission)")
            
            if hasPermission && self.eventTap == nil {
                print("[FinderClip] 检测到权限已授予，重启监听...")
                Task { @MainActor in
                    self.startMonitoring()
                }
            }
        }
    }
    
    private func requestNotificationPermission() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound]) { granted, error in
            if granted {
                print("[FinderClip] 通知权限已授予")
            }
        }
    }
    
    func startMonitoring() {
        guard eventTap == nil else { return }
        
        print("[FinderClip] 启动监听...")
        
        let eventMask = (1 << CGEventType.keyDown.rawValue)
        
        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
                guard let refcon = refcon else {
                    return Unmanaged.passUnretained(event)
                }
                let manager = Unmanaged<FinderCutPasteManager>.fromOpaque(refcon).takeUnretainedValue()
                return manager.handleEventTap(proxy: proxy, type: type, event: event)
            },
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            print("[FinderClip] ⚠️ Event Tap 创建失败（需要辅助功能权限）")
            showPermissionAlert()
            return
        }
        
        eventTap = tap
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        
        print("[FinderClip] ✅ 监听已启动")
    }
    
    func stopMonitoring() {
        guard let tap = eventTap else { return }
        
        CGEvent.tapEnable(tap: tap, enable: false)
        
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
            runLoopSource = nil
        }
        
        eventTap = nil
        clearCutMode()
    }
    
    // 关键：使用 nonisolated 避免 MainActor 隔离问题
    private nonisolated func handleEventTap(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        guard type == .keyDown else {
            return Unmanaged.passUnretained(event)
        }
        
        // 检查是否是 Finder（内联检查，避免调用 MainActor 方法）
        guard let frontApp = NSWorkspace.shared.frontmostApplication,
              frontApp.bundleIdentifier == "com.apple.finder" else {
            return Unmanaged.passUnretained(event)
        }
        
        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
        let flags = event.flags
        
        // ⌘X - 剪切
        if keyCode == 7 && flags.contains(.maskCommand) && !flags.contains(.maskShift) && !flags.contains(.maskAlternate) {
            // 检查是否在文本编辑模式（内联检查）
            if isInTextEditingMode(pid: frontApp.processIdentifier) {
                return Unmanaged.passUnretained(event)
            }
            
            // 模拟 ⌘C
            simulateKeyPress(keyCode: 8, flags: .maskCommand)
            
            // 标记剪切模式
            isCutMode = true
            cutTimestamp = Date()
            
            // 显示通知（异步）
            Task { @MainActor in
                self.showNotification("剪切模式", subtitle: "按 ⌘V 移动文件，按 Esc 取消")
            }
            
            return nil  // 阻止原始事件
        }
        
        // ⌘V - 粘贴（移动）
        if keyCode == 9 && flags.contains(.maskCommand) && !flags.contains(.maskShift) && !flags.contains(.maskAlternate) {
            if isCutMode {
                // 模拟 ⌘⌥V（系统的移动操作）
                simulateKeyPress(keyCode: 9, flags: [.maskCommand, .maskAlternate])
                
                isCutMode = false
                cutTimestamp = nil
                
                return nil  // 阻止原始事件
            }
        }
        
        // Escape - 取消剪切
        if keyCode == 53 && isCutMode {
            isCutMode = false
            cutTimestamp = nil
            
            Task { @MainActor in
                self.showNotification("已取消剪切", subtitle: "文件保持原位")
            }
            
            return nil
        }
        
        // 检查超时
        if let timestamp = cutTimestamp {
            let timeout = SettingsManager.shared.cutTimeout
            if Date().timeIntervalSince(timestamp) > TimeInterval(timeout) {
                isCutMode = false
                cutTimestamp = nil
                Task { @MainActor in
                    self.showNotification("剪切已超时", subtitle: "文件保持原位")
                }
            }
        }
        
        return Unmanaged.passUnretained(event)
    }
    
    // 内联的文本编辑检测
    private nonisolated func isInTextEditingMode(pid: pid_t) -> Bool {
        let finderApp = AXUIElementCreateApplication(pid)
        
        var focusedElement: CFTypeRef?
        guard AXUIElementCopyAttributeValue(finderApp, kAXFocusedUIElementAttribute as CFString, &focusedElement) == .success,
              let element = focusedElement else {
            return false
        }
        
        guard CFGetTypeID(element) == AXUIElementGetTypeID() else {
            return false
        }
        
        let axElement = unsafeBitCast(element, to: AXUIElement.self)
        
        var selectedText: CFTypeRef?
        return AXUIElementCopyAttributeValue(axElement, kAXSelectedTextAttribute as CFString, &selectedText) == .success
    }
    
    // 模拟按键
    private nonisolated func simulateKeyPress(keyCode: CGKeyCode, flags: CGEventFlags) {
        guard let keyDown = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: true),
              let keyUp = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: false) else {
            return
        }
        
        keyDown.flags = flags
        keyUp.flags = flags
        
        keyDown.post(tap: .cghidEventTap)
        keyUp.post(tap: .cghidEventTap)
    }
    
    private nonisolated func clearCutMode() {
        isCutMode = false
        cutTimestamp = nil
    }
    
    private func showNotification(_ title: String, subtitle: String) {
        guard SettingsManager.shared.showNotifications else { return }
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.subtitle = subtitle
        
        if SettingsManager.shared.soundEnabled {
            content.sound = .default
        }
        
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
    
    private func showPermissionAlert() {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "需要辅助功能权限"
            alert.informativeText = "FinderClip 需要辅助功能权限才能拦截键盘事件。\n\n请在系统设置中授予权限。"
            alert.alertStyle = .warning
            alert.addButton(withTitle: "打开系统设置")
            alert.addButton(withTitle: "取消")
            
            if alert.runModal() == .alertFirstButtonReturn {
                self.openSystemPreferences()
            }
        }
    }
    
    func openSystemPreferences() {
        let url = "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
        
        if let settingsURL = URL(string: url) {
            NSWorkspace.shared.open(settingsURL)
        }
    }
}
