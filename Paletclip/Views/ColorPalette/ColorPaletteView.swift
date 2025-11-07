//
//  ColorPaletteView.swift
//  Paletclip
//
//  Created by 凌峰 on 2025/11/7.
//

import SwiftUI
import UniformTypeIdentifiers

// MARK: - 颜色调色板视图
struct ColorPaletteView: View {
    let colors: [ColorInfo]
    let title: String
    @State private var selectedFormat: ColorFormat = .hex
    @State private var expandedSwatch: String? = nil
    @State private var copiedColor: String? = nil
    
    private var adaptiveColumns: [GridItem] {
        [GridItem(.adaptive(minimum: 100, maximum: 150), spacing: 12)]
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 头部控制区域
            headerSection
            
            // 颜色网格
            colorGrid
            
            // 导出选项
            if !colors.isEmpty {
                exportSection
            }
        }
    }
    
    // MARK: - 头部区域
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text("\(colors.count) 种颜色")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // 格式选择器
            Picker("格式", selection: $selectedFormat) {
                ForEach(ColorFormat.allCases, id: \.self) { format in
                    Text(format.displayName).tag(format)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 200)
        }
    }
    
    // MARK: - 颜色网格
    private var colorGrid: some View {
        LazyVGrid(columns: adaptiveColumns, spacing: 12) {
            ForEach(colors, id: \.hexValue) { colorInfo in
                ColorSwatchView(
                    colorInfo: colorInfo,
                    format: selectedFormat,
                    isExpanded: expandedSwatch == colorInfo.hexValue,
                    copiedColor: $copiedColor
                )
                .onTapGesture {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        if expandedSwatch == colorInfo.hexValue {
                            expandedSwatch = nil
                        } else {
                            expandedSwatch = colorInfo.hexValue
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - 导出区域
    private var exportSection: some View {
        GlassCard(
            cornerRadius: 12,
            padding: EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16)
        ) {
            HStack(spacing: 12) {
                Image(systemName: "square.and.arrow.up")
                    .font(.title3)
                    .foregroundColor(PaletclipColors.accentBlue)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("导出调色板")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text("保存为多种格式")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                HStack(spacing: 8) {
                    exportButton(title: "CSS", action: exportCSS)
                    exportButton(title: "JSON", action: exportJSON)
                    exportButton(title: "ASE", action: exportASE)
                }
            }
        }
    }
    
    private func exportButton(title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(PaletclipColors.accentBlue)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(PaletclipColors.accentBlue.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - 导出方法
    private func exportCSS() {
        let cssContent = generateCSSContent()
        saveToFile(content: cssContent, fileName: "palette.css", contentType: .plainText)
    }
    
    private func exportJSON() {
        let jsonContent = generateJSONContent()
        saveToFile(content: jsonContent, fileName: "palette.json", contentType: .json)
    }
    
    private func exportASE() {
        // Adobe Swatch Exchange format
        let aseData = generateASEData()
        saveDataToFile(data: aseData, fileName: "palette.ase")
    }
    
    private func generateCSSContent() -> String {
        var css = ":root {\n"
        for (index, color) in colors.enumerated() {
            css += "  --color-\(index + 1): \(color.hexValue);\n"
        }
        css += "}\n\n"
        
        css += "/* Color Classes */\n"
        for (index, color) in colors.enumerated() {
            css += ".color-\(index + 1) { color: \(color.hexValue); }\n"
            css += ".bg-color-\(index + 1) { background-color: \(color.hexValue); }\n"
        }
        
        return css
    }
    
    private func generateJSONContent() -> String {
        let palette = PaletteExport(
            name: title,
            colors: colors.map { colorInfo in
                ColorExport(
                    name: "Color \(colors.firstIndex(where: { $0.hexValue == colorInfo.hexValue }) ?? 0 + 1)",
                    hex: colorInfo.hexValue,
                    rgb: colorInfo.rgbValues,
                    cmyk: colorInfo.cmykValues,
                    hsb: colorInfo.hsbValues,
                    percentage: colorInfo.percentage
                )
            }
        )
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        
        if let data = try? encoder.encode(palette),
           let jsonString = String(data: data, encoding: .utf8) {
            return jsonString
        }
        
        return "{}"
    }
    
    private func generateASEData() -> Data {
        // 简化的 ASE 格式实现
        var data = Data()
        
        // ASE Header
        data.append("ASEF".data(using: .ascii)!)
        data.append(Data([0x00, 0x01, 0x00, 0x00])) // Version
        data.append(withUnsafeBytes(of: UInt32(colors.count).bigEndian) { Data($0) })
        
        // Colors
        for color in colors {
            let rgb = color.rgbValues
            data.append(Data([0x00, 0x01])) // Color entry
            data.append(withUnsafeBytes(of: UInt32(22).bigEndian) { Data($0) }) // Length
            data.append(Data([0x00, 0x00])) // Name length
            data.append("RGB ".data(using: .ascii)!)
            data.append(withUnsafeBytes(of: Float32(rgb.r).bitPattern.bigEndian) { Data($0) })
            data.append(withUnsafeBytes(of: Float32(rgb.g).bitPattern.bigEndian) { Data($0) })
            data.append(withUnsafeBytes(of: Float32(rgb.b).bitPattern.bigEndian) { Data($0) })
            data.append(Data([0x00, 0x02])) // Color type (spot)
        }
        
        return data
    }
    
    private func saveToFile(content: String, fileName: String, contentType: UTType) {
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [contentType]
        savePanel.nameFieldStringValue = fileName
        
        if savePanel.runModal() == .OK {
            guard let url = savePanel.url else { return }
            try? content.write(to: url, atomically: true, encoding: .utf8)
        }
    }
    
    private func saveDataToFile(data: Data, fileName: String) {
        let savePanel = NSSavePanel()
        savePanel.nameFieldStringValue = fileName
        
        if savePanel.runModal() == .OK {
            guard let url = savePanel.url else { return }
            try? data.write(to: url)
        }
    }
}

// 使用 ColorInfo.swift 中定义的 ColorFormat

// MARK: - 导出数据模型
struct PaletteExport: Codable {
    let name: String
    let colors: [ColorExport]
    let createdAt: String
    let version: String
    
    init(name: String, colors: [ColorExport]) {
        self.name = name
        self.colors = colors
        self.createdAt = ISO8601DateFormatter().string(from: Date())
        self.version = "1.0"
    }
}

struct ColorExport: Codable {
    let name: String
    let hex: String
    let rgb: RGBValues
    let cmyk: CMYKValues
    let hsb: HSBValues
    let percentage: Double
    
    init(name: String, hex: String, rgb: RGBValues, cmyk: CMYKValues, hsb: HSBValues, percentage: Double) {
        self.name = name
        self.hex = hex
        self.rgb = rgb
        self.cmyk = cmyk
        self.hsb = hsb
        self.percentage = percentage
    }
}

#Preview {
    ColorPaletteView(
        colors: [
            ColorInfo(
                hexValue: "#FF6B6B",
                rgbValues: RGBValues(r: 1.0, g: 0.42, b: 0.42),
                cmykValues: CMYKValues(c: 0.0, m: 0.58, y: 0.58, k: 0.0),
                hsbValues: HSBValues(h: 0.0, s: 0.58, b: 1.0),
                percentage: 0.25,
                name: nil
            ),
            ColorInfo(
                hexValue: "#4ECDC4",
                rgbValues: RGBValues(r: 0.31, g: 0.80, b: 0.77),
                cmykValues: CMYKValues(c: 0.61, m: 0.0, y: 0.04, k: 0.2),
                hsbValues: HSBValues(h: 0.49, s: 0.61, b: 0.80),
                percentage: 0.35,
                name: nil
            ),
            ColorInfo(
                hexValue: "#45B7D1",
                rgbValues: RGBValues(r: 0.27, g: 0.72, b: 0.82),
                cmykValues: CMYKValues(c: 0.67, m: 0.12, y: 0.0, k: 0.18),
                hsbValues: HSBValues(h: 0.55, s: 0.67, b: 0.82),
                percentage: 0.20,
                name: nil
            )
        ],
        title: "主调色板"
    )
    .padding()
    .background(.ultraThinMaterial)
}
