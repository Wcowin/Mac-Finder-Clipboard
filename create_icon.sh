#!/bin/bash

# 创建 FinderClip 应用图标
# 使用 SF Symbols 的剪刀图标

set -e

echo "🎨 创建应用图标..."

# 创建临时目录
ICONSET_DIR="AppIcon.iconset"
rm -rf "$ICONSET_DIR"
mkdir -p "$ICONSET_DIR"

# 使用 SF Symbols 创建不同尺寸的图标
# 剪刀图标：scissors

# 创建一个临时的 Swift 脚本来生成图标
cat > generate_icon.swift << 'SWIFT'
import Cocoa

// 创建简洁的剪刀图标
func createScissorsIcon(size: CGFloat) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))
    
    image.lockFocus()
    
    let rect = NSRect(x: 0, y: 0, width: size, height: size)
    
    // 简洁的圆角矩形背景 - 使用 OneClip 风格的蓝色
    let backgroundColor = NSColor(red: 0.0, green: 0.48, blue: 1.0, alpha: 1.0) // 系统蓝色
    backgroundColor.setFill()
    let backgroundPath = NSBezierPath(roundedRect: rect, xRadius: size * 0.22, yRadius: size * 0.22)
    backgroundPath.fill()
    
    // 绘制剪刀符号 - 更大更清晰
    if let scissorsImage = NSImage(systemSymbolName: "scissors", accessibilityDescription: nil) {
        let symbolConfig = NSImage.SymbolConfiguration(pointSize: size * 0.55, weight: .medium)
        let configuredImage = scissorsImage.withSymbolConfiguration(symbolConfig)
        
        // 白色剪刀，居中显示
        NSColor.white.set()
        let symbolRect = NSRect(
            x: size * 0.225, 
            y: size * 0.225, 
            width: size * 0.55, 
            height: size * 0.55
        )
        configuredImage?.draw(in: symbolRect)
    }
    
    image.unlockFocus()
    
    return image
}

// 保存图标
func saveIcon(image: NSImage, path: String) {
    guard let tiffData = image.tiffRepresentation,
          let bitmapImage = NSBitmapImageRep(data: tiffData),
          let pngData = bitmapImage.representation(using: .png, properties: [:]) else {
        print("❌ 无法生成 PNG 数据")
        return
    }
    
    do {
        try pngData.write(to: URL(fileURLWithPath: path))
        print("✅ 已生成: \(path)")
    } catch {
        print("❌ 保存失败: \(error)")
    }
}

// 生成所有尺寸的图标
let sizes: [(size: Int, scale: Int)] = [
    (16, 1), (16, 2),
    (32, 1), (32, 2),
    (128, 1), (128, 2),
    (256, 1), (256, 2),
    (512, 1), (512, 2)
]

for (size, scale) in sizes {
    let actualSize = CGFloat(size * scale)
    let image = createScissorsIcon(size: actualSize)
    let filename = scale == 1 ? "icon_\(size)x\(size).png" : "icon_\(size)x\(size)@\(scale)x.png"
    saveIcon(image: image, path: "AppIcon.iconset/\(filename)")
}

print("🎉 所有图标已生成")
SWIFT

# 编译并运行图标生成脚本
echo "📝 生成图标文件..."
swiftc -o generate_icon generate_icon.swift
./generate_icon

# 使用 iconutil 创建 .icns 文件
echo "🔨 创建 .icns 文件..."
iconutil -c icns "$ICONSET_DIR" -o AppIcon.icns

# 清理临时文件
rm -rf "$ICONSET_DIR" generate_icon.swift generate_icon

echo "✅ 图标创建完成: AppIcon.icns"
