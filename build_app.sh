#!/bin/bash

set -e

echo "🔨 构建 FinderClip.app..."

# 清理
rm -rf FinderClip.app

# 创建应用包结构
mkdir -p FinderClip.app/Contents/MacOS
mkdir -p FinderClip.app/Contents/Resources

# 编译
swiftc -o FinderClip.app/Contents/MacOS/FinderClip \
    -framework Cocoa \
    -framework UserNotifications \
    -target arm64-apple-macos12.0 \
    main.swift \
    AppDelegate.swift \
    FinderCutPasteManager.swift

# 复制 Info.plist
cp Info.plist FinderClip.app/Contents/Info.plist

# 修复 Info.plist 中的变量
/usr/libexec/PlistBuddy -c "Set :CFBundleExecutable FinderClip" FinderClip.app/Contents/Info.plist
/usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier com.wcowin.FinderClip" FinderClip.app/Contents/Info.plist
/usr/libexec/PlistBuddy -c "Set :CFBundleName FinderClip" FinderClip.app/Contents/Info.plist
/usr/libexec/PlistBuddy -c "Set :CFBundleIconFile AppIcon" FinderClip.app/Contents/Info.plist

# 复制应用图标
if [ -f "AppIcon.icns" ]; then
    cp AppIcon.icns FinderClip.app/Contents/Resources/
    echo "✅ 已添加应用图标"
elif [ -f "icon-256.png" ]; then
    echo "📝 从 PNG 生成图标..."
    ./create_icon_from_png.sh
    cp AppIcon.icns FinderClip.app/Contents/Resources/
    echo "✅ 已生成并添加应用图标"
else
    echo "⚠️  未找到图标文件，跳过图标"
fi

# 设置可执行权限
chmod +x FinderClip.app/Contents/MacOS/FinderClip

echo "✅ 构建完成！"
echo "📍 应用位置: FinderClip.app"
echo ""
echo "🚀 运行: open FinderClip.app"
