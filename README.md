# Paletclip

> Paletclip 是一个面向 macOS 设计师的全能剪贴板工具，采用液体玻璃设计风格，集成了剪贴板历史管理和颜色调色板提取功能,第一次使用swift开发macos应用,有点难以驾驭,目前还是demo版,不过对我自己使用已经刚好,虽然还有很多不完善的地方，但对于个人使用已经基本满足需求,未来会继续完善功能和优化体验.

## 主要内容

### 核心功能
- **实时剪贴板监控** - 自动捕获并保存剪贴板内容
- **状态栏集成** - 便捷的状态栏弹窗界面
- **全格式图像支持** - PNG, JPEG, SVG, GIF, BMP, WebP
- **智能颜色提取** - 从图像中提取主色调色板
- **星标管理系统** - 收藏重要的剪贴板内容

### 设计特色
- **调色板导出** - 支持JSON格式导出颜色信息
- **缩略图生成** - 自动为图像和文本生成预览缩略图
- **颜色格式转换** - HEX, RGB, CMYK, HSB多种格式支持
- **智能文件类型识别** - 自动检测和分类不同的内容类型

### 技术栈

- **框架**: SwiftUI + AppKit
- **数据持久化**: Core Data
- **图像处理**: Core Image + Vision
- **颜色分析**: K-means聚类算法
- **UI设计**: 自定义玻璃态组件库

## 项目结构

```
Paletclip/
├── App/
│   ├── PaletclipApp.swift          # 应用入口
│   └── AppDelegate.swift           # 状态栏和主要UI逻辑
├── Models/
│   ├── ClipboardItem.swift         # 剪贴板项目数据模型
│   ├── ColorInfo.swift             # 颜色信息数据模型
│   ├── Folder.swift                # 文件夹数据模型
│   └── CoreDataStack.swift         # Core Data配置
├── Services/
│   ├── ClipboardMonitor.swift      # 剪贴板监控服务
│   ├── ClipboardManager.swift      # 剪贴板管理器
│   ├── ColorExtractor.swift        # 颜色提取算法
│   ├── ThumbnailGenerator.swift    # 缩略图生成
│   └── FileTypeDetector.swift      # 文件类型检测
├── Views/
│   ├── ClipboardHistory/           # 剪贴板历史视图
│   └── ColorPalette/               # 颜色调色板视图
└── Design System/
    ├── Components/                 # 可复用UI组件
    └── Colors/                     # 色彩系统定义
```

## 系统要求

- macOS 13.0 或更高版本
- Xcode 15.0 或更高版本
- Swift 5.9 或更高版本

## 安装和运行

1. 克隆项目到本地
```bash
git clone https://github.com/lingfeng11111/Paletclip.git
cd Paletclip
```

2. 使用 Xcode 打开项目
```bash
open Paletclip.xcodeproj
```

3. 选择目标设备并运行
   - 选择 "My Mac" 作为运行目标
   - 按 `Cmd+R` 编译并运行

## 使用说明

1. **启动应用** - 运行后会在状态栏显示 Paletclip 图标
2. **复制内容** - 正常使用 `Cmd+C` 复制，内容会自动被捕获
3. **查看历史** - 点击状态栏图标打开弹窗查看剪贴板历史
4. **管理内容** - 使用悬停按钮进行快速操作，右键查看完整菜单
5. **预览详情** - 点击眼睛图标查看内容详细信息和颜色分析

## 技术特色

### 智能颜色提取
基于K-means聚类算法，从图像中提取主要颜色，支持：
- 自动色彩分布分析
- 多种颜色格式转换
- 调色板JSON导出

### 液体玻璃设计
自主设计的玻璃态UI组件库，包含：
- 自适应毛玻璃效果
- 流畅的动画过渡
- 现代化的交互反馈

### 高性能架构
- 异步图像处理
- Core Data优化
- 内存缓存策略
- 后台任务管理

**注**: 此项目仍在开发中，功能和API可能会有变化。