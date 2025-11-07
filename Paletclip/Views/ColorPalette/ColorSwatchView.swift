//
//  ColorSwatchView.swift
//  Paletclip
//
//  Created by 凌峰 on 2025/11/7.
//

import SwiftUI

// MARK: - 颜色样本视图
struct ColorSwatchView: View {
    let colorInfo: ColorInfo
    let format: ColorFormat
    let isExpanded: Bool
    @Binding var copiedColor: String?
    
    @State private var isHovered = false
    @State private var showingColorAnalysis = false
    
    private var displayColor: Color {
        Color(hex: colorInfo.hexValue) ?? .gray
    }
    
    private var formattedColorValue: String {
        switch format {
        case .hex:
            return colorInfo.hexValue
        case .rgb:
            let rgb = colorInfo.rgbValues
            return "rgb(\(Int(rgb.r * 255)), \(Int(rgb.g * 255)), \(Int(rgb.b * 255)))"
        case .cmyk:
            let cmyk = colorInfo.cmykValues
            return "cmyk(\(Int(cmyk.c * 100))%, \(Int(cmyk.m * 100))%, \(Int(cmyk.y * 100))%, \(Int(cmyk.k * 100))%)"
        case .hsb:
            let hsb = colorInfo.hsbValues
            return "hsb(\(Int(hsb.h * 360))°, \(Int(hsb.s * 100))%, \(Int(hsb.b * 100))%)"
        }
    }
    
    private var isLightColor: Bool {
        let rgb = colorInfo.rgbValues
        let luminance = 0.299 * rgb.r + 0.587 * rgb.g + 0.114 * rgb.b
        return luminance > 0.5
    }
    
    private var textColor: Color {
        isLightColor ? .black : .white
    }
    
    private var borderColor: Color {
        isLightColor ? Color.black.opacity(0.1) : Color.white.opacity(0.3)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 主要色块区域
            colorSwatchArea
            
            // 展开的详细信息
            if isExpanded {
                expandedDetails
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .top)),
                        removal: .opacity.combined(with: .move(edge: .bottom))
                    ))
            }
        }
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(borderColor, lineWidth: 0.5)
        )
        .scaleEffect(isHovered ? 1.05 : 1.0)
        .shadow(
            color: displayColor.opacity(0.3),
            radius: isHovered ? 12 : 6,
            x: 0,
            y: isHovered ? 6 : 3
        )
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isHovered)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isExpanded)
        .onHover { hovering in
            isHovered = hovering
        }
        .contextMenu {
            contextMenuItems
        }
    }
    
    // MARK: - 主要色块区域
    private var colorSwatchArea: some View {
        VStack(spacing: 8) {
            // 颜色圆形
            ZStack {
                Circle()
                    .fill(displayColor)
                    .frame(width: 60, height: 60)
                    .overlay(
                        Circle()
                            .stroke(borderColor, lineWidth: 1)
                    )
                
                // 复制状态指示
                if copiedColor == colorInfo.hexValue {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 60, height: 60)
                        .overlay(
                            Image(systemName: "checkmark")
                                .font(.title2)
                                .foregroundColor(.green)
                        )
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .onTapGesture {
                copyColorValue()
            }
            
            // 颜色值
            VStack(spacing: 4) {
                Text(formattedColorValue)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .textSelection(.enabled)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                
                // 占比信息
                Text("\(Int(colorInfo.percentage * 100))%")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                // 颜色亮度指示
                HStack(spacing: 4) {
                    Circle()
                        .fill(isLightColor ? .black : .white)
                        .frame(width: 4, height: 4)
                    
                    Text(isLightColor ? "亮色" : "暗色")
                        .font(.caption2)
                        .foregroundColor(Color.secondary)
                }
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
    }
    
    // MARK: - 展开的详细信息
    private var expandedDetails: some View {
        VStack(alignment: .leading, spacing: 12) {
            Divider()
                .opacity(0.3)
            
            VStack(alignment: .leading, spacing: 8) {
                // 所有格式的颜色值
                colorFormatsSection
                
                // 颜色分析
                colorAnalysisSection
                
                // 操作按钮
                actionButtonsSection
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
        }
    }
    
    // MARK: - 颜色格式区域
    private var colorFormatsSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("颜色格式")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
            
            VStack(alignment: .leading, spacing: 4) {
                colorFormatRow("HEX", value: colorInfo.hexValue)
                colorFormatRow("RGB", value: "rgb(\(Int(colorInfo.rgbValues.r * 255)), \(Int(colorInfo.rgbValues.g * 255)), \(Int(colorInfo.rgbValues.b * 255)))")
                colorFormatRow("HSL", value: "hsl(\(Int(rgbToHSL(colorInfo.rgbValues).h * 360))°, \(Int(rgbToHSL(colorInfo.rgbValues).s * 100))%, \(Int(rgbToHSL(colorInfo.rgbValues).l * 100))%)")
                colorFormatRow("CMYK", value: "cmyk(\(Int(colorInfo.cmykValues.c * 100))%, \(Int(colorInfo.cmykValues.m * 100))%, \(Int(colorInfo.cmykValues.y * 100))%, \(Int(colorInfo.cmykValues.k * 100))%)")
                colorFormatRow("HSB", value: "hsb(\(Int(colorInfo.hsbValues.h * 360))°, \(Int(colorInfo.hsbValues.s * 100))%, \(Int(colorInfo.hsbValues.b * 100))%)")
            }
        }
    }
    
    private func colorFormatRow(_ format: String, value: String) -> some View {
        HStack {
            Text(format)
                .font(.caption2)
                .foregroundColor(.secondary)
                .frame(width: 40, alignment: .leading)
            
            Text(value)
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(.primary)
                .textSelection(.enabled)
            
            Spacer()
            
            Button {
                copyValue(value)
            } label: {
                Image(systemName: "doc.on.doc")
                    .font(.caption2)
                    .foregroundColor(PaletclipColors.accentBlue)
            }
            .buttonStyle(.plain)
        }
    }
    
    // MARK: - 颜色分析区域
    private var colorAnalysisSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("颜色分析")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button("详细分析") {
                    showingColorAnalysis = true
                }
                .font(.caption2)
                .foregroundColor(PaletclipColors.accentBlue)
            }
            
            HStack(spacing: 12) {
                colorPropertyItem("亮度", value: "\(Int(getLuminance() * 100))%")
                colorPropertyItem("饱和度", value: "\(Int(colorInfo.hsbValues.s * 100))%")
                colorPropertyItem("色相", value: "\(Int(colorInfo.hsbValues.h * 360))°")
            }
        }
        .sheet(isPresented: $showingColorAnalysis) {
            ColorAnalysisSheet(colorInfo: colorInfo)
        }
    }
    
    private func colorPropertyItem(_ title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
            Text(value)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(.primary)
        }
    }
    
    // MARK: - 操作按钮区域
    private var actionButtonsSection: some View {
        HStack(spacing: 8) {
            GlassButton(
                "复制",
                icon: "doc.on.doc",
                style: .secondary
            ) {
                copyColorValue()
            }
            
            GlassButton(
                "相似色",
                icon: "eyedropper.halffull",
                style: .secondary
            ) {
                findSimilarColors()
            }
            
            Spacer()
            
            GlassButton(
                "收藏",
                icon: "heart",
                style: .secondary
            ) {
                favoriteColor()
            }
        }
    }
    
    // MARK: - 右键菜单
    private var contextMenuItems: some View {
        Group {
            Button("复制 HEX") {
                copyValue(colorInfo.hexValue)
            }
            
            Button("复制 RGB") {
                let rgb = colorInfo.rgbValues
                copyValue("rgb(\(Int(rgb.r * 255)), \(Int(rgb.g * 255)), \(Int(rgb.b * 255)))")
            }
            
            Button("复制 HSL") {
                let hsl = rgbToHSL(colorInfo.rgbValues)
                copyValue("hsl(\(Int(hsl.h * 360))°, \(Int(hsl.s * 100))%, \(Int(hsl.l * 100))%)")
            }
            
            Divider()
            
            Button("颜色分析") {
                showingColorAnalysis = true
            }
            
            Button("查找相似色") {
                findSimilarColors()
            }
            
            Button("添加到收藏") {
                favoriteColor()
            }
        }
    }
    
    // MARK: - 辅助方法
    private func copyColorValue() {
        copyValue(formattedColorValue)
    }
    
    private func copyValue(_ value: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(value, forType: .string)
        
        withAnimation(.easeInOut(duration: 0.3)) {
            copiedColor = colorInfo.hexValue
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.easeInOut(duration: 0.3)) {
                if copiedColor == colorInfo.hexValue {
                    copiedColor = nil
                }
            }
        }
    }
    
    private func getLuminance() -> Double {
        let rgb = colorInfo.rgbValues
        return 0.299 * rgb.r + 0.587 * rgb.g + 0.114 * rgb.b
    }
    
    private func rgbToHSL(_ rgb: RGBValues) -> (h: Double, s: Double, l: Double) {
        let max = Swift.max(rgb.r, rgb.g, rgb.b)
        let min = Swift.min(rgb.r, rgb.g, rgb.b)
        let delta = max - min
        
        let lightness = (max + min) / 2
        
        if delta == 0 {
            return (0, 0, lightness)
        }
        
        let saturation = lightness > 0.5 ? delta / (2 - max - min) : delta / (max + min)
        
        var hue: Double
        switch max {
        case rgb.r:
            hue = (rgb.g - rgb.b) / delta + (rgb.g < rgb.b ? 6 : 0)
        case rgb.g:
            hue = (rgb.b - rgb.r) / delta + 2
        default:
            hue = (rgb.r - rgb.g) / delta + 4
        }
        hue /= 6
        
        return (hue, saturation, lightness)
    }
    
    private func findSimilarColors() {
        // TODO: 实现相似颜色查找功能
        print("查找相似颜色: \(colorInfo.hexValue)")
    }
    
    private func favoriteColor() {
        // TODO: 实现颜色收藏功能
        print("收藏颜色: \(colorInfo.hexValue)")
    }
}

// MARK: - 颜色分析详情窗口
struct ColorAnalysisSheet: View {
    let colorInfo: ColorInfo
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // 颜色预览
                    colorPreviewSection
                    
                    // 详细数值
                    detailedValuesSection
                    
                    // 颜色关系
                    colorRelationshipsSection
                    
                    // 可访问性信息
                    accessibilitySection
                }
                .padding()
            }
            .navigationTitle("颜色分析")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
        .frame(minWidth: 500, minHeight: 400)
    }
    
    private var colorPreviewSection: some View {
        HStack {
            Circle()
                .fill(Color(hex: colorInfo.hexValue) ?? .gray)
                .frame(width: 100, height: 100)
                .shadow(radius: 8)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(colorInfo.hexValue)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("在图像中占比 \(Int(colorInfo.percentage * 100))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
    
    private var detailedValuesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("详细数值")
                .font(.headline)
            
            // RGB 详情
            colorDetailCard("RGB", values: [
                ("红色", "\(Int(colorInfo.rgbValues.r * 255))", Color.red),
                ("绿色", "\(Int(colorInfo.rgbValues.g * 255))", Color.green),
                ("蓝色", "\(Int(colorInfo.rgbValues.b * 255))", Color.blue)
            ])
            
            // HSB 详情
            colorDetailCard("HSB", values: [
                ("色相", "\(Int(colorInfo.hsbValues.h * 360))°", Color.orange),
                ("饱和度", "\(Int(colorInfo.hsbValues.s * 100))%", Color.purple),
                ("亮度", "\(Int(colorInfo.hsbValues.b * 100))%", Color.yellow)
            ])
            
            // CMYK 详情
            colorDetailCard("CMYK", values: [
                ("青色", "\(Int(colorInfo.cmykValues.c * 100))%", Color.cyan),
                ("洋红", "\(Int(colorInfo.cmykValues.m * 100))%", Color.pink),
                ("黄色", "\(Int(colorInfo.cmykValues.y * 100))%", Color.yellow),
                ("黑色", "\(Int(colorInfo.cmykValues.k * 100))%", Color.black)
            ])
        }
    }
    
    private func colorDetailCard(_ title: String, values: [(String, String, Color)]) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                HStack(spacing: 16) {
                    ForEach(values, id: \.0) { name, value, color in
                        VStack(spacing: 4) {
                            Circle()
                                .fill(color)
                                .frame(width: 24, height: 24)
                            
                            Text(name)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            
                            Text(value)
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                    }
                    
                    Spacer()
                }
            }
        }
    }
    
    private var colorRelationshipsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("颜色关系")
                .font(.headline)
            
            // TODO: 实现补色、类似色、三角色等关系
            Text("补色、类似色分析正在开发中...")
                .font(.caption)
                .foregroundColor(.secondary)
                .italic()
        }
    }
    
    private var accessibilitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("可访问性")
                .font(.headline)
            
            // TODO: 实现WCAG对比度分析
            Text("WCAG 对比度分析正在开发中...")
                .font(.caption)
                .foregroundColor(.secondary)
                .italic()
        }
    }
}

#Preview {
    ColorSwatchView(
        colorInfo: ColorInfo(
            hexValue: "#FF6B6B",
            rgbValues: RGBValues(r: 1.0, g: 0.42, b: 0.42),
            cmykValues: CMYKValues(c: 0.0, m: 0.58, y: 0.58, k: 0.0),
            hsbValues: HSBValues(h: 0.0, s: 0.58, b: 1.0),
            percentage: 0.25,
            name: nil
        ),
        format: .hex,
        isExpanded: true,
        copiedColor: .constant(nil)
    )
    .padding()
    .background(.ultraThinMaterial)
}
