//
//  PaletclipColors.swift
//  Paletclip
//
//  Created by 凌峰 on 2025/11/7.
//

import SwiftUI

// MARK: - Paletclip 颜色系统
struct PaletclipColors {
    
    // MARK: - 主要色彩 - 颜料淡五彩系列
    
    /// 淡朱砂
    static let paintRed = Color(red: 1.0, green: 0.85, blue: 0.85)
    
    /// 淡群青
    static let paintBlue = Color(red: 0.85, green: 0.92, blue: 1.0)
    
    /// 淡藤黄
    static let paintYellow = Color(red: 1.0, green: 0.95, blue: 0.8)
    
    /// 淡花青
    static let paintGreen = Color(red: 0.88, green: 0.95, blue: 0.85)
    
    /// 淡紫罗兰
    static let paintPurple = Color(red: 0.92, green: 0.85, blue: 0.95)
    
    // MARK: - 中性色系
    
    /// 玻璃白
    static let glassWhite = Color(white: 0.98, opacity: 0.85)
    
    /// 玻璃灰
    static let glassGray = Color(white: 0.5, opacity: 0.1)
    
    /// 玻璃深色
    static let glassDark = Color(white: 0.2, opacity: 0.8)
    
    // MARK: - 功能色彩
    
    /// 主色调
    static let accent = paintBlue
    
    /// 强调蓝色
    static let accentBlue = Color(red: 0.2, green: 0.6, blue: 1.0)
    
    /// 成功色
    static let success = paintGreen
    
    /// 警告色
    static let warning = paintYellow
    
    /// 错误色
    static let error = paintRed
    
    // MARK: - 背景色系
    
    /// 主背景
    static let primaryBackground = Color(white: 1.0, opacity: 0.15)
    
    /// 卡片背景
    static let cardBackground = Color(white: 1.0, opacity: 0.20)
    
    /// 输入框背景
    static let inputBackground = Color(white: 0.95, opacity: 0.8)
    
    // MARK: - 文本色系
    
    /// 主文本
    static let primaryText = Color.primary
    
    /// 次要文本
    static let secondaryText = Color.secondary
    
    /// 占位符文本
    static let placeholderText = Color(white: 0.6)
    
    // MARK: - 边框色系
    
    /// 主边框
    static let primaryBorder = Color(white: 1.0, opacity: 0.3)
    
    /// 次要边框
    static let secondaryBorder = Color(white: 1.0, opacity: 0.1)
    
    /// 聚焦边框
    static let focusBorder = accent
    
    // MARK: - 阴影色系
    
    /// 浅阴影
    static let lightShadow = glassDark.opacity(0.05)
    
    /// 深阴影
    static let deepShadow = glassDark.opacity(0.1)
    
    /// 强阴影
    static let strongShadow = glassDark.opacity(0.2)
}

// MARK: - 颜色扩展
extension PaletclipColors {
    
    /// 获取所有颜料色彩
    static var allPaintColors: [Color] {
        return [paintRed, paintBlue, paintYellow, paintGreen, paintPurple]
    }
    
    /// 获取所有玻璃色彩
    static var allGlassColors: [Color] {
        return [glassWhite, glassGray, glassDark]
    }
    
    /// 获取所有功能色彩
    static var allFunctionalColors: [Color] {
        return [accent, accentBlue, success, warning, error]
    }
    
    /// 根据名称获取颜色
    static func color(named name: String) -> Color {
        switch name.lowercased() {
        case "paintred": return paintRed
        case "paintblue": return paintBlue
        case "paintyellow": return paintYellow
        case "paintgreen": return paintGreen
        case "paintpurple": return paintPurple
        case "glasswhite": return glassWhite
        case "glassgray": return glassGray
        case "glassdark": return glassDark
        case "accent": return accent
        case "accentblue": return accentBlue
        case "success": return success
        case "warning": return warning
        case "error": return error
        default: return accent
        }
    }
}

// MARK: - 动态颜色支持
extension PaletclipColors {
    
    /// 自适应背景色（根据系统外观）
    static var adaptiveBackground: Color {
        return Color(NSColor.controlBackgroundColor).opacity(0.15)
    }
    
    /// 自适应文本色
    static var adaptiveText: Color {
        return Color(NSColor.labelColor)
    }
    
    /// 自适应次要文本色
    static var adaptiveSecondaryText: Color {
        return Color(NSColor.secondaryLabelColor)
    }
}

// MARK: - 渐变色
extension PaletclipColors {
    
    /// 玻璃渐变
    static var glassGradient: LinearGradient {
        return LinearGradient(
            colors: [
                glassWhite.opacity(0.3),
                glassGray.opacity(0.1)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    /// 主色调渐变
    static var accentGradient: LinearGradient {
        return LinearGradient(
            colors: [
                accent.opacity(0.8),
                accent.opacity(0.6)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    /// 彩虹渐变
    static var rainbowGradient: LinearGradient {
        return LinearGradient(
            colors: allPaintColors,
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}
