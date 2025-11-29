<div align="center">

# FinderClip

<img src="https://img.shields.io/badge/macOS-12.0+-blue.svg" alt="macOS">
<img src="https://img.shields.io/badge/Swift-5.9-orange.svg" alt="Swift">
<img src="https://img.shields.io/badge/license-MIT-green.svg" alt="License">

**为 macOS Finder 提供直观的剪切粘贴体验**

[English](README_EN.md) | 简体中文

</div>

---

## ✨ 简介

FinderClip 是一个轻量级的 macOS 菜单栏应用，让你可以在 Finder 中使用熟悉的 **⌘X** 和 **⌘V** 快捷键来剪切和移动文件，就像在 Windows 中一样自然。

## 🎯 功能特点

| 功能 | 说明 |
|------|------|
| ✂️ **真正的剪切** | 在 Finder 中使用 ⌘X 剪切文件 |
| 📋 **智能粘贴** | 使用 ⌘V 移动文件到目标位置 |
| 🎯 **场景识别** | 自动区分文件选择和文本编辑状态 |
| 🔔 **可视化反馈** | 剪切/粘贴操作提供清晰的通知提示 |
| ⏱️ **超时保护** | 剪切状态 5 分钟自动清除 |
| ⌨️ **快捷取消** | 按 Esc 取消剪切操作 |
| 🚀 **开机自启** | 支持开机自动启动 |

## 📖 使用方法

### 基本操作

```
1. ⌘X  - 在 Finder 中选择文件后按 ⌘X 剪切
2. ⌘V  - 导航到目标文件夹后按 ⌘V 移动
3. Esc - 按 Esc 键取消剪切状态
```

### 演示

<div align="center">
  <img src="docs/demo.gif" alt="演示" width="600">
</div>

## 🚀 快速开始

### 系统要求

- macOS 12.0 或更高版本
- Xcode Command Line Tools

### 从源码构建

```bash
# 克隆仓库
git clone https://github.com/Wcowin/Mac-Finder-Clipboard.git
cd Mac-Finder-Clipboard

# 生成应用图标（首次构建）
./create_icon.sh

# 构建应用
./build_app.sh

# 运行应用
open FinderClip.app
```

### 首次使用

1. 运行应用后，菜单栏会出现剪刀图标 ✂️
2. 点击图标 → "打开辅助功能设置"
3. 在系统设置中勾选 FinderClip
4. 完成！现在可以在 Finder 中使用 ⌘X 剪切文件了

## 🛠 技术实现

### 核心技术

- **CGEvent API** - 拦截全局键盘事件
- **Accessibility API** - 检测焦点元素状态
- **UserNotifications** - 现代化的通知系统
- **ServiceManagement** - 开机自启支持

### 工作原理

```
用户按下 ⌘X
    ↓
检测是否在 Finder
    ↓
检测是否在文本编辑状态
    ↓
模拟 ⌘C 复制文件
    ↓
标记剪切模式
    ↓
用户按下 ⌘V
    ↓
转换为 ⌘⌥V（系统剪切粘贴）
    ↓
文件移动完成
```

## 📁 项目结构

```
Mac-Finder-Clipboard/
├── main.swift                    # 应用入口
├── AppDelegate.swift             # 应用代理和菜单栏
├── FinderCutPasteManager.swift   # 核心功能实现
├── Info.plist                    # 应用配置
├── FinderClip.entitlements       # 权限配置
├── build_app.sh                  # 构建脚本
├── create_icon.sh                # 图标生成脚本
├── AppIcon.icns                  # 应用图标
├── LICENSE                       # MIT 许可证
├── .gitignore                    # Git 忽略文件
└── README.md                     # 说明文档
```

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

## 📄 许可证

本项目采用 [MIT License](LICENSE) 开源。

## 👨‍💻 作者

**Wcowin** - [GitHub](https://github.com/Wcowin)

## ⭐ Star History

如果这个项目对你有帮助，请给它一个 Star ⭐

---

<div align="center">
  Made with ❤️ by Wcowin
</div>
