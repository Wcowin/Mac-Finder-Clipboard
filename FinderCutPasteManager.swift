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
        // 监听应用激活
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppActivated),
            name: NSApplication.didBecomeActiveNotification,
            object: nil
        )
        
        // 监听权限状态变化（来自设置界面的授权）
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handlePermissionChanged),
            name: .accessibilityStatusChanged,
            object: nil
        )
    }
    
    @objc private func handlePermissionChanged(_ notification: Notification) {
        guard isEnabled else { return }
        
        let hasPermission = AXIsProcessTrusted()
        print("[FinderClip] 收到权限变化通知，当前状态: \(hasPermission)")
        
        if hasPermission && eventTap == nil {
            print("[FinderClip] 权限已授予，立即启动监听...")
            Task { @MainActor in
                self.startMonitoring()
            }
        }
    }
    

    @objc private func handleAppActivated() {
        guard isEnabled else { return }
        Task { @MainActor in
            // Retry for up to ~4 seconds to allow System Settings to apply changes
            for attempt in 0..<8 {
                let hasPermission = AXIsProcessTrusted()
                print("[FinderClip] 应用激活重检(\(attempt))，权限状态: \(hasPermission)")
                if hasPermission {
                    if self.eventTap == nil {
                        self.startMonitoring()
                    }
                    break
                }
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s
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

        func attemptCreateTap() -> CFMachPort? {
            return CGEvent.tapCreate(
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
            )
        }

        guard let tap = attemptCreateTap() else {
            print("[FinderClip] Event Tap 创建失败（需要辅助功能权限或等待系统应用更改）")
            // Prompt once if not trusted
            if !AXIsProcessTrusted() {
                showPermissionAlert()
            }
            // Retry once after a short delay in case System Settings just applied the toggle
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
                guard let self = self, self.eventTap == nil else { return }
                if let retryTap = attemptCreateTap() {
                    self.eventTap = retryTap
                    self.runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, retryTap, 0)
                    CFRunLoopAddSource(CFRunLoopGetMain(), self.runLoopSource, .commonModes)
                    CGEvent.tapEnable(tap: retryTap, enable: true)
                    print("[FinderClip] 监听已启动(重试)")
                } else {
                    print("[FinderClip] 监听仍无法启动，等待用户在系统设置中授权或重启应用后重试")
                }
            }
            return
        }

        eventTap = tap
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)

        print("[FinderClip] 监听已启动")
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
            
            // 显示通知
            Task { @MainActor in
                let loc = LocalizationManager.shared
                self.showNotification(loc.localized(.notificationCutSuccess), subtitle: "⌘V / Esc")
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
                let loc = LocalizationManager.shared
                self.showNotification(loc.localized(.notificationCutCancelled), subtitle: "")
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
                    let loc = LocalizationManager.shared
                    self.showNotification(loc.localized(.notificationCutCancelled), subtitle: "")
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
        
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
    
    private func showPermissionAlert() {
        // 使用系统原生弹窗请求权限（不再显示自定义弹窗）
        DispatchQueue.main.async {
            let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary
            AXIsProcessTrustedWithOptions(options)
        }
    }
    
    func openSystemPreferences() {
        // Trigger the native permission prompt if not already trusted
        if !AXIsProcessTrusted() {
            let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary
            AXIsProcessTrustedWithOptions(options)
        }

        // Open System Settings
        let url = "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
        if let settingsURL = URL(string: url) {
            NSWorkspace.shared.open(settingsURL)
        }
    }
}

