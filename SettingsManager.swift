//
//  SettingsManager.swift
//  FinderClip
//
//  Created by Wcowin on 2025/12/09.
//

import Foundation

class SettingsManager {
    static let shared = SettingsManager()
    
    private let defaults = UserDefaults.standard
    
    // Keys
    private enum Keys {
        static let cutTimeout = "cutTimeout"
        static let showNotifications = "showNotifications"
        static let showCutCount = "showCutCount"
        static let soundEnabled = "soundEnabled"
    }
    
    // 剪切超时时间（秒）
    var cutTimeout: Int {
        get {
            let value = defaults.integer(forKey: Keys.cutTimeout)
            return value > 0 ? value : 300 // 默认5分钟
        }
        set {
            defaults.set(newValue, forKey: Keys.cutTimeout)
            NotificationCenter.default.post(name: .settingsChanged, object: nil)
        }
    }
    
    // 是否显示通知
    var showNotifications: Bool {
        get {
            if defaults.object(forKey: Keys.showNotifications) == nil {
                return true // 默认开启
            }
            return defaults.bool(forKey: Keys.showNotifications)
        }
        set {
            defaults.set(newValue, forKey: Keys.showNotifications)
            NotificationCenter.default.post(name: .settingsChanged, object: nil)
        }
    }
    
    // 是否在菜单栏显示剪切数量
    var showCutCount: Bool {
        get {
            if defaults.object(forKey: Keys.showCutCount) == nil {
                return true // 默认开启
            }
            return defaults.bool(forKey: Keys.showCutCount)
        }
        set {
            defaults.set(newValue, forKey: Keys.showCutCount)
            NotificationCenter.default.post(name: .settingsChanged, object: nil)
        }
    }
    
    // 是否启用声音
    var soundEnabled: Bool {
        get {
            if defaults.object(forKey: Keys.soundEnabled) == nil {
                return true // 默认开启
            }
            return defaults.bool(forKey: Keys.soundEnabled)
        }
        set {
            defaults.set(newValue, forKey: Keys.soundEnabled)
            NotificationCenter.default.post(name: .settingsChanged, object: nil)
        }
    }
    
    private init() {}
}

extension Notification.Name {
    static let settingsChanged = Notification.Name("settingsChanged")
    static let accessibilityStatusChanged = Notification.Name("accessibilityStatusChanged")
}
