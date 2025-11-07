//
//  ColorInfo.swift
//  Paletclip
//
//  Created by 凌峰 on 2025/11/7.
//

import Foundation
import SwiftUI

// MARK: - RGB 值结构
struct RGBValues: Codable, Hashable {
    let r: Double // 0.0-1.0
    let g: Double // 0.0-1.0
    let b: Double // 0.0-1.0
    
    var description: String {
        return "rgb(\(Int(r * 255)), \(Int(g * 255)), \(Int(b * 255)))"
    }
    
    var color: Color {
        return Color(red: r, green: g, blue: b)
    }
    
    var nsColor: NSColor {
        return NSColor(red: r, green: g, blue: b, alpha: 1.0)
    }
}

// MARK: - CMYK 值结构
struct CMYKValues: Codable, Hashable {
    let c: Double // 0.0-1.0 (青色)
    let m: Double // 0.0-1.0 (洋红)
    let y: Double // 0.0-1.0 (黄色)
    let k: Double // 0.0-1.0 (黑色)
    
    var description: String {
        return "cmyk(\(Int(c * 100))%, \(Int(m * 100))%, \(Int(y * 100))%, \(Int(k * 100))%)"
    }
}

// MARK: - HSB 值结构
struct HSBValues: Codable, Hashable {
    let h: Double // 0.0-1.0 (色相)
    let s: Double // 0.0-1.0 (饱和度)
    let b: Double // 0.0-1.0 (亮度)
    
    var description: String {
        return "hsb(\(Int(h * 360))°, \(Int(s * 100))%, \(Int(b * 100))%)"
    }
    
    var color: Color {
        return Color(hue: h, saturation: s, brightness: b)
    }
}

// MARK: - 颜色信息模型
struct ColorInfo: Codable, Identifiable, Hashable {
    let id = UUID()
    let hexValue: String
    let rgbValues: RGBValues
    let cmykValues: CMYKValues
    let hsbValues: HSBValues
    let percentage: Double
    let name: String? // 颜色名称（可选）
    
    enum CodingKeys: String, CodingKey {
        case hexValue, rgbValues, cmykValues, hsbValues, percentage, name
    }
    
    // 兼容性属性
    var hex: String { hexValue }
    var rgb: RGBValues { rgbValues }
    var cmyk: CMYKValues { cmykValues }
    var hsb: HSBValues { hsbValues }
}

// MARK: - ColorInfo 扩展
extension ColorInfo {
    
    // 从 NSColor 创建 ColorInfo
    static func from(_ nsColor: NSColor, percentage: Double = 0.0, name: String? = nil) -> ColorInfo {
        let rgbColor = nsColor.usingColorSpace(.sRGB) ?? nsColor
        
        let r = rgbColor.redComponent
        let g = rgbColor.greenComponent
        let b = rgbColor.blueComponent
        
        let rgb = RGBValues(r: r, g: g, b: b)
        let hex = String(format: "#%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255))
        
        // 转换为 HSB
        let h = rgbColor.hueComponent
        let s = rgbColor.saturationComponent
        let brightness = rgbColor.brightnessComponent
        let hsb = HSBValues(h: h, s: s, b: brightness)
        
        // 转换为 CMYK
        let cmyk = rgbToCMYK(r: r, g: g, b: b)
        
        return ColorInfo(
            hexValue: hex,
            rgbValues: rgb,
            cmykValues: cmyk,
            hsbValues: hsb,
            percentage: percentage,
            name: name
        )
    }
    
    // 从十六进制创建 ColorInfo
    static func fromHex(_ hex: String, percentage: Double = 0.0, name: String? = nil) -> ColorInfo? {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        
        let r = Double((int >> 16) & 0xFF) / 255.0
        let g = Double((int >> 8) & 0xFF) / 255.0
        let b = Double(int & 0xFF) / 255.0
        
        let rgb = RGBValues(r: r, g: g, b: b)
        let nsColor = rgb.nsColor
        
        let h = nsColor.hueComponent
        let s = nsColor.saturationComponent
        let brightness = nsColor.brightnessComponent
        let hsb = HSBValues(h: h, s: s, b: brightness)
        
        let cmyk = rgbToCMYK(r: r, g: g, b: b)
        
        return ColorInfo(
            hexValue: "#" + hex.uppercased(),
            rgbValues: rgb,
            cmykValues: cmyk,
            hsbValues: hsb,
            percentage: percentage,
            name: name
        )
    }
    
    // SwiftUI Color
    var color: Color {
        return rgbValues.color
    }
    
    // NSColor
    var nsColor: NSColor {
        return rgbValues.nsColor
    }
}

// MARK: - 颜色格式枚举
enum ColorFormat: String, CaseIterable, Identifiable {
    case hex = "HEX"
    case rgb = "RGB"
    case cmyk = "CMYK"
    case hsb = "HSB"
    
    var id: String { rawValue }
    
    var displayName: String {
        return rawValue
    }
}

// MARK: - 颜色转换工具函数
private func rgbToCMYK(r: Double, g: Double, b: Double) -> CMYKValues {
    let k = 1.0 - max(r, max(g, b))
    let c = k < 1.0 ? (1.0 - r - k) / (1.0 - k) : 0.0
    let m = k < 1.0 ? (1.0 - g - k) / (1.0 - k) : 0.0
    let y = k < 1.0 ? (1.0 - b - k) / (1.0 - k) : 0.0
    
    return CMYKValues(c: c, m: m, y: y, k: k)
}

// MARK: - 颜色聚类结构（用于 K-means 算法）
struct ColorCluster {
    var centroid: RGBValues
    var points: [RGBValues]
    
    init(centroid: RGBValues) {
        self.centroid = centroid
        self.points = []
    }
}

// MARK: - Color 扩展，支持从十六进制创建
extension Color {
    init?(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            return nil
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
