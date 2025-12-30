//
//  LocalizationManager.swift
//  FinderClip
//
//  Created by Wcowin on 2025/12/30.
//

import Foundation

enum AppLanguage: String, CaseIterable {
    case chinese = "zh-Hans"
    case english = "en"
    
    var displayName: String {
        switch self {
        case .chinese: return "中文"
        case .english: return "English"
        }
    }
}

class LocalizationManager {
    static let shared = LocalizationManager()
    
    private var currentLanguage: AppLanguage = .chinese
    
    private init() {
        if let savedLang = UserDefaults.standard.string(forKey: "appLanguage"),
           let lang = AppLanguage(rawValue: savedLang) {
            currentLanguage = lang
        } else {
            let systemLang = Locale.preferredLanguages.first ?? "en"
            currentLanguage = systemLang.hasPrefix("zh") ? .chinese : .english
        }
    }
    
    var language: AppLanguage {
        get { currentLanguage }
        set {
            currentLanguage = newValue
            UserDefaults.standard.set(newValue.rawValue, forKey: "appLanguage")
            NotificationCenter.default.post(name: .languageChanged, object: nil)
        }
    }
    
    func localized(_ key: LocalizedKey) -> String {
        return key.localized(for: currentLanguage)
    }
}

enum LocalizedKey {
    case appName
    case appDescription
    case appSubtitle
    
    case menuReady
    case menuGrantPermission
    case menuCheckingPermission
    case menuLaunchAtLogin
    case menuSettings
    case menuAbout
    case menuQuit
    
    case settingsTitle
    case settingsAccessibilityReady
    case settingsAccessibilityNeeded
    case settingsOpenSettings
    case settingsCutTimeout
    case settingsShowNotification
    case settingsLanguage
    case settingsDone
    
    case timeoutOneMinute
    case timeoutThreeMinutes
    case timeoutFiveMinutes
    case timeoutTenMinutes
    case timeoutThirtyMinutes
    case timeoutNever
    
    case shortcutCut
    case shortcutPaste
    case shortcutCancel
    
    case aboutVersion
    case aboutDescription
    case aboutShortcuts
    case aboutOK
    
    case notificationCutSuccess
    case notificationPasteSuccess
    case notificationCutCancelled
    case notificationError
    
    func localized(for language: AppLanguage) -> String {
        switch language {
        case .chinese:
            return chineseString
        case .english:
            return englishString
        }
    }
    
    private var chineseString: String {
        switch self {
        case .appName: return "FinderClip"
        case .appDescription: return "为 Finder 提供直观的剪切粘贴体验"
        case .appSubtitle: return "为 Finder 带来真正的剪切粘贴"
            
        case .menuReady: return "✓ 已就绪"
        case .menuGrantPermission: return "⚠ 点击授予权限..."
        case .menuCheckingPermission: return "检查权限中..."
        case .menuLaunchAtLogin: return "开机自动启动"
        case .menuSettings: return "设置..."
        case .menuAbout: return "关于 FinderClip"
        case .menuQuit: return "退出"
            
        case .settingsTitle: return "设置"
        case .settingsAccessibilityReady: return "已就绪"
        case .settingsAccessibilityNeeded: return "需要辅助功能权限"
        case .settingsOpenSettings: return "打开设置"
        case .settingsCutTimeout: return "剪切超时"
        case .settingsShowNotification: return "显示通知"
        case .settingsLanguage: return "语言"
        case .settingsDone: return "完成"
            
        case .timeoutOneMinute: return "1 分钟"
        case .timeoutThreeMinutes: return "3 分钟"
        case .timeoutFiveMinutes: return "5 分钟"
        case .timeoutTenMinutes: return "10 分钟"
        case .timeoutThirtyMinutes: return "30 分钟"
        case .timeoutNever: return "永不"
            
        case .shortcutCut: return "剪切"
        case .shortcutPaste: return "粘贴移动"
        case .shortcutCancel: return "取消"
            
        case .aboutVersion: return "版本"
        case .aboutDescription: return "为 Finder 提供直观的剪切粘贴体验"
        case .aboutShortcuts: return "⌘X - 剪切文件\n⌘V - 移动文件\nEsc - 取消剪切"
        case .aboutOK: return "确定"
            
        case .notificationCutSuccess: return "已剪切"
        case .notificationPasteSuccess: return "已移动"
        case .notificationCutCancelled: return "已取消剪切"
        case .notificationError: return "操作失败"
        }
    }
    
    private var englishString: String {
        switch self {
        case .appName: return "FinderClip"
        case .appDescription: return "Intuitive cut and paste experience for Finder"
        case .appSubtitle: return "True cut and paste for Finder"
            
        case .menuReady: return "✓ Ready"
        case .menuGrantPermission: return "⚠ Click to grant permission..."
        case .menuCheckingPermission: return "Checking permission..."
        case .menuLaunchAtLogin: return "Launch at Login"
        case .menuSettings: return "Settings..."
        case .menuAbout: return "About FinderClip"
        case .menuQuit: return "Quit"
            
        case .settingsTitle: return "Settings"
        case .settingsAccessibilityReady: return "Ready"
        case .settingsAccessibilityNeeded: return "Accessibility Permission Required"
        case .settingsOpenSettings: return "Open Settings"
        case .settingsCutTimeout: return "Cut Timeout"
        case .settingsShowNotification: return "Show Notifications"
        case .settingsLanguage: return "Language"
        case .settingsDone: return "Done"
            
        case .timeoutOneMinute: return "1 Minute"
        case .timeoutThreeMinutes: return "3 Minutes"
        case .timeoutFiveMinutes: return "5 Minutes"
        case .timeoutTenMinutes: return "10 Minutes"
        case .timeoutThirtyMinutes: return "30 Minutes"
        case .timeoutNever: return "Never"
            
        case .shortcutCut: return "Cut"
        case .shortcutPaste: return "Paste & Move"
        case .shortcutCancel: return "Cancel"
            
        case .aboutVersion: return "Version"
        case .aboutDescription: return "Intuitive cut and paste experience for Finder"
        case .aboutShortcuts: return "⌘X - Cut files\n⌘V - Move files\nEsc - Cancel cut"
        case .aboutOK: return "OK"
            
        case .notificationCutSuccess: return "Cut"
        case .notificationPasteSuccess: return "Moved"
        case .notificationCutCancelled: return "Cut Cancelled"
        case .notificationError: return "Operation Failed"
        }
    }
}

extension Notification.Name {
    static let languageChanged = Notification.Name("languageChanged")
}
