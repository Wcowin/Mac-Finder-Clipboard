#!/bin/bash

# ============================================================
# FinderClip 构建与发布脚本
# ============================================================
# 用法:
#   ./scripts/build.sh              # 仅构建
#   ./scripts/build.sh --run        # 构建并运行
#   ./scripts/build.sh --release    # 构建发布版本
#   ./scripts/build.sh --release 1.0.1  # 发布指定版本
#   ./scripts/build.sh --clean      # 清理构建
#   ./scripts/build.sh --help       # 显示帮助
# ============================================================

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# 项目配置
APP_NAME="FinderClip"
BUNDLE_ID="com.wcowin.FinderClip"
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$PROJECT_DIR/build"
RELEASE_DIR="$PROJECT_DIR/releases"
DERIVED_DATA="$BUILD_DIR/DerivedData"

# Sparkle 配置
SPARKLE_BIN="$PROJECT_DIR/tools/sparkle/bin"
SPARKLE_KEYS="$PROJECT_DIR/tools/sparkle/keys"

# GitHub 配置
GITHUB_REPO="Wcowin/Mac-Finder-Clipboard"
APPCAST_URL="https://raw.githubusercontent.com/$GITHUB_REPO/main/appcast.xml"

# ============================================================
# 辅助函数
# ============================================================

print_header() {
    echo ""
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${NC}  ${BOLD}$1${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
}

print_step() {
    echo -e "${CYAN}▶${NC} $1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

show_help() {
    cat << EOF
${BOLD}FinderClip 构建脚本${NC}

${YELLOW}用法:${NC}
  ./scripts/build.sh [选项] [参数]

${YELLOW}选项:${NC}
  ${GREEN}(无参数)${NC}        构建 Debug 版本
  ${GREEN}--run, -r${NC}       构建并运行应用
  ${GREEN}--release${NC}       构建 Release 版本
  ${GREEN}--release VER${NC}   发布指定版本 (如: --release 1.0.1)
  ${GREEN}--clean, -c${NC}     清理所有构建文件
  ${GREEN}--status, -s${NC}    显示项目状态
  ${GREEN}--help, -h${NC}      显示此帮助信息

${YELLOW}示例:${NC}
  ./scripts/build.sh                 # 快速构建
  ./scripts/build.sh -r              # 构建并运行
  ./scripts/build.sh --release       # 构建发布版本
  ./scripts/build.sh --release 1.0.1 # 发布 v1.0.1
  ./scripts/build.sh -c              # 清理构建

${YELLOW}发布流程:${NC}
  1. ./scripts/build.sh --release 1.0.1
  2. 编辑 releases/appcast_item_1.0.1.xml 填写更新说明
  3. 将条目添加到 appcast.xml
  4. git tag v1.0.1 && git push origin v1.0.1
  5. 上传 ZIP 到 GitHub Release
  6. git add . && git commit && git push

EOF
}

# ============================================================
# 核心功能
# ============================================================

do_clean() {
    print_header "清理构建文件"
    
    print_step "删除 build 目录..."
    rm -rf "$BUILD_DIR"
    
    print_step "删除 Xcode DerivedData..."
    rm -rf ~/Library/Developer/Xcode/DerivedData/${APP_NAME}-*
    
    print_step "删除本地 .app..."
    rm -rf "$PROJECT_DIR/$APP_NAME.app"
    
    print_success "清理完成"
}

do_build() {
    local CONFIG="${1:-Debug}"
    
    print_header "构建 $APP_NAME ($CONFIG)"
    
    mkdir -p "$BUILD_DIR"
    
    print_step "编译中..."
    
    xcodebuild -project "$PROJECT_DIR/FinderClip.xcodeproj" \
        -scheme FinderClip \
        -configuration "$CONFIG" \
        -derivedDataPath "$DERIVED_DATA" \
        CONFIGURATION_BUILD_DIR="$BUILD_DIR" \
        build 2>&1 | while read line; do
            if [[ "$line" == *"error:"* ]]; then
                print_error "$line"
            elif [[ "$line" == *"warning:"* ]]; then
                print_warning "$line"
            elif [[ "$line" == *"BUILD SUCCEEDED"* ]]; then
                print_success "编译成功"
            elif [[ "$line" == *"BUILD FAILED"* ]]; then
                print_error "编译失败"
                exit 1
            fi
        done
    
    if [ -d "$BUILD_DIR/$APP_NAME.app" ]; then
        local APP_SIZE=$(du -sh "$BUILD_DIR/$APP_NAME.app" | cut -f1)
        print_success "输出: $BUILD_DIR/$APP_NAME.app ($APP_SIZE)"
    else
        print_error "构建失败：未找到 .app"
        exit 1
    fi
}

do_run() {
    print_header "运行 $APP_NAME"
    
    # 先构建
    do_build "Debug"
    
    # 关闭已运行的实例
    print_step "关闭已运行的实例..."
    pkill -x "$APP_NAME" 2>/dev/null || true
    sleep 0.5
    
    # 运行
    print_step "启动应用..."
    open "$BUILD_DIR/$APP_NAME.app"
    
    print_success "应用已启动"
}

do_release() {
    local VERSION="$1"
    
    print_header "发布 $APP_NAME"
    
    # 如果没有指定版本，从 Info.plist 读取
    if [ -z "$VERSION" ]; then
        VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$PROJECT_DIR/Info.plist")
        print_warning "未指定版本号，使用当前版本: $VERSION"
        echo ""
        read -p "是否继续? (y/N) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 0
        fi
    fi
    
    local BUILD_NUMBER=$(date +%Y%m%d%H%M)
    local ZIP_NAME="${APP_NAME}-${VERSION}.zip"
    local ZIP_PATH="$RELEASE_DIR/$ZIP_NAME"
    
    mkdir -p "$RELEASE_DIR"
    
    # 步骤 1: 更新版本号
    print_step "[1/6] 更新版本号..."
    /usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION" "$PROJECT_DIR/Info.plist"
    /usr/libexec/PlistBuddy -c "Set :CFBundleVersion $BUILD_NUMBER" "$PROJECT_DIR/Info.plist"
    print_success "版本: $VERSION (Build $BUILD_NUMBER)"
    
    # 步骤 2: 构建 Release
    print_step "[2/6] 构建 Release 版本..."
    do_build "Release"
    
    # 步骤 3: 创建 ZIP
    print_step "[3/6] 创建发布包..."
    rm -f "$ZIP_PATH"
    cd "$BUILD_DIR"
    ditto -c -k --keepParent "$APP_NAME.app" "$ZIP_PATH"
    local ZIP_SIZE=$(stat -f%z "$ZIP_PATH")
    print_success "创建: $ZIP_NAME ($ZIP_SIZE bytes)"
    
    # 步骤 4: 签名
    print_step "[4/6] 签名更新包..."
    local SIGNATURE=""
    if [ -f "$SPARKLE_BIN/sign_update" ] && [ -f "$SPARKLE_KEYS/private.ed25519" ]; then
        SIGNATURE=$("$SPARKLE_BIN/sign_update" "$ZIP_PATH" --ed-key-file "$SPARKLE_KEYS/private.ed25519" 2>&1 | grep "sparkle:edSignature" | sed 's/.*sparkle:edSignature="\([^"]*\)".*/\1/')
        
        if [ -z "$SIGNATURE" ]; then
            SIGNATURE=$("$SPARKLE_BIN/sign_update" "$ZIP_PATH" --ed-key-file "$SPARKLE_KEYS/private.ed25519" 2>&1 | tail -1)
        fi
        
        if [ -n "$SIGNATURE" ]; then
            print_success "签名: ${SIGNATURE:0:30}..."
        else
            print_warning "签名获取失败，请手动签名"
            SIGNATURE="SIGNATURE_PLACEHOLDER"
        fi
    else
        print_warning "找不到签名工具或密钥"
        SIGNATURE="SIGNATURE_PLACEHOLDER"
    fi
    
    # 步骤 5: 自动更新 appcast.xml
    print_step "[5/6] 更新 appcast.xml..."
    local PUB_DATE=$(date -R)
    local DOWNLOAD_URL="https://github.com/$GITHUB_REPO/releases/download/${VERSION}/${ZIP_NAME}"
    local APPCAST_FILE="$PROJECT_DIR/appcast.xml"
    
    # 生成新的 appcast.xml（新版本在前）
    cat > "$APPCAST_FILE" << EOF
<?xml version="1.0" standalone="yes"?>
<rss xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle" version="2.0">
    <channel>
        <title>FinderClip</title>
        <item>
            <title>$VERSION</title>
            <pubDate>$PUB_DATE</pubDate>
            <sparkle:version>$BUILD_NUMBER</sparkle:version>
            <sparkle:shortVersionString>$VERSION</sparkle:shortVersionString>
            <sparkle:minimumSystemVersion>12.0</sparkle:minimumSystemVersion>
            <enclosure url="$DOWNLOAD_URL" length="$ZIP_SIZE" type="application/octet-stream" sparkle:edSignature="$SIGNATURE"/>
            <description><![CDATA[
                <h2>FinderClip $VERSION</h2>
                <p>更新内容请查看 GitHub Release</p>
            ]]></description>
        </item>
    </channel>
</rss>
EOF
    print_success "appcast.xml 已更新"
    
    # 步骤 6: 输出发布信息
    print_step "[6/6] 完成"
    
    echo ""
    print_header "发布准备完成 ✅"
    echo ""
    echo -e "  ${BOLD}版本:${NC}     $VERSION (Build $BUILD_NUMBER)"
    echo -e "  ${BOLD}发布包:${NC}   $ZIP_PATH"
    echo -e "  ${BOLD}大小:${NC}     $ZIP_SIZE bytes"
    echo -e "  ${BOLD}签名:${NC}     ${SIGNATURE:0:20}..."
    echo ""
    echo -e "${YELLOW}下一步操作:${NC}"
    echo ""
    echo "  1. 创建 GitHub Release 并上传 ZIP:"
    echo "     ${CYAN}https://github.com/$GITHUB_REPO/releases/new${NC}"
    echo "     Tag: ${CYAN}${VERSION}${NC}"
    echo "     上传: ${CYAN}$ZIP_PATH${NC}"
    echo ""
    echo "  2. 提交并推送更新:"
    echo "     ${CYAN}git add .${NC}"
    echo "     ${CYAN}git commit -m \"Release v${VERSION}\"${NC}"
    echo "     ${CYAN}git push${NC}"
    echo ""
}

do_status() {
    print_header "项目状态"
    
    # 版本信息
    local VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$PROJECT_DIR/Info.plist" 2>/dev/null || echo "未知")
    local BUILD=$(/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" "$PROJECT_DIR/Info.plist" 2>/dev/null || echo "未知")
    
    echo ""
    echo -e "  ${BOLD}应用名称:${NC}   $APP_NAME"
    echo -e "  ${BOLD}Bundle ID:${NC}  $BUNDLE_ID"
    echo -e "  ${BOLD}版本:${NC}       $VERSION (Build $BUILD)"
    echo ""
    
    # 文件统计
    local SWIFT_FILES=$(find "$PROJECT_DIR" -maxdepth 1 -name "*.swift" | wc -l | tr -d ' ')
    echo -e "  ${BOLD}Swift 文件:${NC} $SWIFT_FILES 个"
    
    # Sparkle 状态
    if [ -f "$SPARKLE_KEYS/private.ed25519" ]; then
        echo -e "  ${BOLD}Sparkle:${NC}    ${GREEN}已配置${NC}"
    else
        echo -e "  ${BOLD}Sparkle:${NC}    ${RED}未配置${NC}"
    fi
    
    # Git 状态
    echo ""
    echo -e "  ${BOLD}Git 状态:${NC}"
    local CHANGES=$(git status --short 2>/dev/null | wc -l | tr -d ' ')
    if [ "$CHANGES" -gt 0 ]; then
        echo -e "    ${YELLOW}$CHANGES 个文件有更改${NC}"
    else
        echo -e "    ${GREEN}工作区干净${NC}"
    fi
    
    echo ""
}

# ============================================================
# 主程序
# ============================================================

cd "$PROJECT_DIR"

case "${1:-}" in
    --help|-h)
        show_help
        ;;
    --clean|-c)
        do_clean
        ;;
    --run|-r)
        do_run
        ;;
    --release)
        do_release "$2"
        ;;
    --status|-s)
        do_status
        ;;
    "")
        do_build "Debug"
        ;;
    *)
        print_error "未知选项: $1"
        echo "使用 --help 查看帮助"
        exit 1
        ;;
esac
