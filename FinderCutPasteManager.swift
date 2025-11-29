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
    
    private var isCutMode: Bool = false
    private var cutTimestamp: Date?
    private let cutTimeout: TimeInterval = 300
    
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    
    init() {
        print("[FinderClip] 管理器已初始化")
        requestNotificationPermission()
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
    
    private func handleEventTap(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        guard type == .keyDown else {
            return Unmanaged.passUnretained(event)
        }
        
        guard isFinderActive() else {
            if isCutMode {
                clearCutMode()
            }
            return Unmanaged.passUnretained(event)
        }
        
        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
        let flags = event.flags
        
        // ⌘X
        if keyCode == 7 && flags.contains(.maskCommand) && !flags.contains(.maskShift) && !flags.contains(.maskAlternate) {
            if isFinderInTextEditingMode() {
                return Unmanaged.passUnretained(event)
            }
            
            simulateCmdC()
            handleCutFiles()
            return nil
        }
        
        // ⌘V
        if keyCode == 9 && flags.contains(.maskCommand) && !flags.contains(.maskShift) && !flags.contains(.maskAlternate) {
            if isCutMode {
                simulateCmdOptionV()
                clearCutMode()
                return nil
            }
        }
        
        // Escape
        if keyCode == 53 && isCutMode {
            clearCutMode()
            showNotification("已取消剪切", subtitle: "文件保持原位")
            return nil
        }
        
        checkCutTimeout()
        return Unmanaged.passUnretained(event)
    }
    
    private func handleCutFiles() {
        isCutMode = true
        cutTimestamp = Date()
        showNotification("剪切模式", subtitle: "按 ⌘V 移动文件，按 Esc 取消")
    }
    
    private func simulateCmdC() {
        guard let cKeyDown = CGEvent(keyboardEventSource: nil, virtualKey: 8, keyDown: true),
              let cKeyUp = CGEvent(keyboardEventSource: nil, virtualKey: 8, keyDown: false) else {
            return
        }
        
        let flags: CGEventFlags = .maskCommand
        cKeyDown.flags = flags
        cKeyUp.flags = flags
        
        cKeyDown.post(tap: .cghidEventTap)
        cKeyUp.post(tap: .cghidEventTap)
    }
    
    private func simulateCmdOptionV() {
        guard let vKeyDown = CGEvent(keyboardEventSource: nil, virtualKey: 9, keyDown: true),
              let vKeyUp = CGEvent(keyboardEventSource: nil, virtualKey: 9, keyDown: false) else {
            return
        }
        
        let flags: CGEventFlags = [.maskCommand, .maskAlternate]
        vKeyDown.flags = flags
        vKeyUp.flags = flags
        
        vKeyDown.post(tap: .cghidEventTap)
        vKeyUp.post(tap: .cghidEventTap)
    }
    
    private func isFinderActive() -> Bool {
        guard let frontApp = NSWorkspace.shared.frontmostApplication else {
            return false
        }
        return frontApp.bundleIdentifier == "com.apple.finder"
    }
    
    private func isFinderInTextEditingMode() -> Bool {
        guard let frontApp = NSWorkspace.shared.frontmostApplication,
              frontApp.bundleIdentifier == "com.apple.finder" else {
            return false
        }
        
        let finderApp = AXUIElementCreateApplication(frontApp.processIdentifier)
        
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
    
    private func clearCutMode() {
        isCutMode = false
        cutTimestamp = nil
    }
    
    private func checkCutTimeout() {
        guard let timestamp = cutTimestamp else { return }
        
        if Date().timeIntervalSince(timestamp) > cutTimeout {
            clearCutMode()
            showNotification("剪切已超时", subtitle: "文件保持原位")
        }
    }
    
    private func showNotification(_ title: String, subtitle: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.subtitle = subtitle
        content.sound = .default
        
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
