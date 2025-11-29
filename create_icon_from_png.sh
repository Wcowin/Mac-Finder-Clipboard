#!/bin/bash

# 从 icon-256.png 创建 FinderClip 应用图标

set -e

echo "🎨 从 PNG 创建应用图标..."

# 检查源文件
if [ ! -f "icon-256.png" ]; then
    echo "❌ 错误：找不到 icon-256.png"
    exit 1
fi

# 创建临时目录
ICONSET_DIR="AppIcon.iconset"
rm -rf "$ICONSET_DIR"
mkdir -p "$ICONSET_DIR"

echo "📝 生成不同尺寸的图标..."

# 使用 sips 命令生成不同尺寸的图标
sips -z 16 16 icon-256.png --out "$ICONSET_DIR/icon_16x16.png" > /dev/null
sips -z 32 32 icon-256.png --out "$ICONSET_DIR/icon_16x16@2x.png" > /dev/null
sips -z 32 32 icon-256.png --out "$ICONSET_DIR/icon_32x32.png" > /dev/null
sips -z 64 64 icon-256.png --out "$ICONSET_DIR/icon_32x32@2x.png" > /dev/null
sips -z 128 128 icon-256.png --out "$ICONSET_DIR/icon_128x128.png" > /dev/null
sips -z 256 256 icon-256.png --out "$ICONSET_DIR/icon_128x128@2x.png" > /dev/null
sips -z 256 256 icon-256.png --out "$ICONSET_DIR/icon_256x256.png" > /dev/null
sips -z 512 512 icon-256.png --out "$ICONSET_DIR/icon_256x256@2x.png" > /dev/null
sips -z 512 512 icon-256.png --out "$ICONSET_DIR/icon_512x512.png" > /dev/null
sips -z 1024 1024 icon-256.png --out "$ICONSET_DIR/icon_512x512@2x.png" > /dev/null

echo "✅ 所有尺寸已生成"

# 使用 iconutil 创建 .icns 文件
echo "🔨 创建 .icns 文件..."
iconutil -c icns "$ICONSET_DIR" -o AppIcon.icns

# 清理临时文件
rm -rf "$ICONSET_DIR"

echo "✅ 图标创建完成: AppIcon.icns"
