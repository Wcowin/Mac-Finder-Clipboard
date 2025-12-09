#!/bin/bash

# FinderClip DMG 打包脚本
# 依赖：brew install create-dmg
# 用法：
#   ./scripts/create_dmg.sh              # 使用默认 build 目录的 app
#   ./scripts/create_dmg.sh 1.0.2        # 指定版本号
#   ./scripts/create_dmg.sh -p /path/to/FinderClip.app  # 指定 app 路径

set -e

APP_NAME="FinderClip"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# 默认路径
APP_PATH="$ROOT_DIR/build/FinderClip.app"
OUTPUT_DIR="$ROOT_DIR/releases"

# 从 Info.plist 读取版本号
get_version_from_plist() {
    /usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" "$ROOT_DIR/Info.plist" 2>/dev/null || echo "1.0.0"
}

VERSION=""

# 解析参数
while [[ $# -gt 0 ]]; do
  case "$1" in
    -p|--app-path)
      APP_PATH="$2"; shift 2
      ;;
    -o|--output)
      OUTPUT_DIR="$2"; shift 2
      ;;
    -h|--help)
      echo "用法: $0 [版本号] [-p app路径] [-o 输出目录]"
      echo ""
      echo "示例:"
      echo "  $0                    # 使用 Info.plist 中的版本号"
      echo "  $0 1.0.2              # 指定版本号"
      echo "  $0 -p /path/to/app    # 指定 app 路径"
      exit 0
      ;;
    -*)
      echo "未知参数: $1"; exit 1
      ;;
    *)
      VERSION="$1"; shift
      ;;
  esac
done

# 如果未指定版本，从 plist 读取
if [[ -z "$VERSION" ]]; then
    VERSION=$(get_version_from_plist)
fi

# 检查 app 是否存在
if [[ ! -d "$APP_PATH" ]]; then
  echo "❌ 未找到应用：$APP_PATH"
  echo "请先运行 ./scripts/build.sh --release 构建应用"
  exit 1
fi

# 检查 create-dmg 是否安装
if ! command -v create-dmg &> /dev/null; then
  echo "❌ 未安装 create-dmg"
  echo "请运行: brew install create-dmg"
  exit 1
fi

# 创建输出目录
mkdir -p "$OUTPUT_DIR"

DMG_NAME="$APP_NAME-$VERSION.dmg"
OUTPUT_DMG="$OUTPUT_DIR/$DMG_NAME"

# 使用应用内 icns 作为卷标图标
VOLICON="$APP_PATH/Contents/Resources/AppIcon.icns"
[ -f "$VOLICON" ] || VOLICON=""

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║  创建 $APP_NAME DMG"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "  版本:   $VERSION"
echo "  应用:   $APP_PATH"
echo "  输出:   $OUTPUT_DMG"
echo ""

# 准备临时打包目录
STAGE_DIR="$(mktemp -d)"
trap 'rm -rf "$STAGE_DIR"' EXIT

# 清理已有的同名 DMG
if [[ -f "$OUTPUT_DMG" ]]; then
  echo "🧹 移除已存在的 DMG..."
  rm -f "$OUTPUT_DMG"
fi

# 清理临时文件
rm -f "$OUTPUT_DIR"/rw.*.dmg 2>/dev/null || true

echo "� 准备打包内容..."
cp -R "$APP_PATH" "$STAGE_DIR/"

# create-dmg 参数
CREATE_DMG_OPTS=(
  "--volname" "$APP_NAME"
  "--window-pos" "200" "120"
  "--window-size" "600" "400"
  "--icon-size" "100"
  "--text-size" "12"
  "--icon" "$APP_NAME.app" "150" "180"
  "--app-drop-link" "450" "180"
)

# 添加卷标图标
if [[ -n "$VOLICON" && -f "$VOLICON" ]]; then
  CREATE_DMG_OPTS+=("--volicon" "$VOLICON")
fi

echo "📀 生成 DMG..."

# 执行 create-dmg
create-dmg \
  "${CREATE_DMG_OPTS[@]}" \
  "$OUTPUT_DMG" \
  "$STAGE_DIR"

# 获取文件大小
DMG_SIZE=$(ls -lh "$OUTPUT_DMG" | awk '{print $5}')

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║  DMG 创建完成 ✅"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "  文件:   $OUTPUT_DMG"
echo "  大小:   $DMG_SIZE"
echo ""
echo "下一步: 上传到 GitHub Release"
