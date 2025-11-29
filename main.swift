//
//  main.swift
//  FinderClip
//
//  Created by Wcowin on 2025/11/29.
//

import Cocoa
import AppKit

// 创建应用
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate

// 隐藏 Dock 图标
app.setActivationPolicy(.accessory)

// 运行应用
app.run()
