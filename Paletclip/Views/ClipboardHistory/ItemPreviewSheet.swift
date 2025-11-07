//
//  ItemPreviewSheet.swift
//  Paletclip
//
//  Created by 凌峰 on 2025/11/7.
//

import SwiftUI
import UniformTypeIdentifiers

// MARK: - 项目预览窗口
struct ItemPreviewSheet: View {
    let item: ClipboardItem
    @Environment(\.dismiss) private var dismiss
    @State private var selectedFormat: ColorFormat = .hex
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // 基本信息
                    basicInfoSection
                    
                    // 主要内容
                    contentSection
                    
                    // 颜色调色板（仅图片类型）
                    if item.contentType.hasPrefix("public.image"),
                       let colors = item.decodedColorPalette, !colors.isEmpty {
                        colorPaletteSection(colors: colors)
                    }
                    
                    // 技术信息
                    technicalInfoSection
                }
                .padding()
            }
            .navigationTitle("项目详情")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    HStack {
                        Button("复制") {
                            copyToPasteboard()
                        }
                        
                        Button(item.isStarred ? "取消星标" : "星标") {
                            toggleStar()
                        }
                    }
                }
            }
        }
        .frame(width: 600, height: 500)
        .interactiveDismissDisabled(false)
    }
    
    // MARK: - 基本信息区域
    private var basicInfoSection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: fileTypeIcon)
                        .font(.title2)
                        .foregroundColor(fileTypeColor)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(contentTypeDisplayName)
                            .font(.title3)
                            .fontWeight(.semibold)
                        
                        Text("创建于 \(formattedDate)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    if item.isStarred {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                    }
                }
                
                // 统计信息
                HStack(spacing: 20) {
                    StatItem(title: "大小", value: formatFileSize(item.content.count))
                    StatItem(title: "类型", value: item.contentType)
                    if let ext = item.fileExtension {
                        StatItem(title: "扩展名", value: ext.uppercased())
                    }
                }
            }
        }
    }
    
    // MARK: - 内容区域
    @ViewBuilder
    private var contentSection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("内容预览")
                    .font(.headline)
                
                switch item.contentType {
                case "public.utf8-plain-text", "public.text":
                    textContentPreview
                    
                case let type where type.hasPrefix("public.image"):
                    imageContentPreview
                    
                case "public.url":
                    urlContentPreview
                    
                case "public.file-url":
                    fileContentPreview
                    
                case "public.rtf":
                    rtfContentPreview
                    
                case "public.html":
                    htmlContentPreview
                    
                default:
                    genericContentPreview
                }
            }
        }
    }
    
    // MARK: - 文本内容预览
    private var textContentPreview: some View {
        let textContent = String(data: item.content, encoding: .utf8) ?? "无法解析文本内容"
        
        return VStack(alignment: .leading, spacing: 8) {
            ScrollView {
                Text(textContent)
                    .font(.system(size: 13, design: .monospaced))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxHeight: 300)
            .background(Color.secondary.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            
            HStack {
                Text("字符数: \(textContent.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button("全选复制") {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(textContent, forType: .string)
                }
                .font(.caption)
                .foregroundColor(PaletclipColors.accentBlue)
            }
        }
    }
    
    // MARK: - 图片内容预览
    private var imageContentPreview: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let image = NSImage(data: item.content) {
                HStack {
                    Spacer()
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: 400, maxHeight: 300)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(radius: 8)
                    Spacer()
                }
                
                // 图片信息
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("尺寸: \(Int(image.size.width)) × \(Int(image.size.height))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("颜色空间: \(getImageColorSpace(image))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button("保存图片") {
                        saveImage(image)
                    }
                    .font(.caption)
                    .foregroundColor(PaletclipColors.accentBlue)
                }
            }
        }
    }
    
    // MARK: - URL 内容预览
    private var urlContentPreview: some View {
        let urlString = String(data: item.content, encoding: .utf8) ?? ""
        
        return VStack(alignment: .leading, spacing: 8) {
            Text(urlString)
                .font(.system(size: 13))
                .textSelection(.enabled)
                .padding()
                .background(Color.secondary.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            
            HStack {
                Button("打开链接") {
                    if let url = URL(string: urlString) {
                        NSWorkspace.shared.open(url)
                    }
                }
                .foregroundColor(PaletclipColors.accentBlue)
                
                Spacer()
                
                if let url = URL(string: urlString) {
                    Text("域名: \(url.host ?? "无")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    // MARK: - 文件内容预览
    private var fileContentPreview: some View {
        let filePath = String(data: item.content, encoding: .utf8) ?? ""
        let fileURL = URL(fileURLWithPath: filePath)
        
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "folder.fill")
                    .font(.title)
                    .foregroundColor(PaletclipColors.paintYellow)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(fileURL.lastPathComponent)
                        .font(.headline)
                    
                    Text(filePath)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .textSelection(.enabled)
                }
                
                Spacer()
            }
            .padding()
            .background(Color.secondary.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            
            HStack {
                Button("在 Finder 中显示") {
                    NSWorkspace.shared.selectFile(filePath, inFileViewerRootedAtPath: fileURL.deletingLastPathComponent().path)
                }
                .foregroundColor(PaletclipColors.accentBlue)
                
                Spacer()
                
                Text(FileManager.default.fileExists(atPath: filePath) ? "文件存在" : "文件不存在")
                    .font(.caption)
                    .foregroundColor(FileManager.default.fileExists(atPath: filePath) ? .green : .red)
            }
        }
    }
    
    // MARK: - RTF 内容预览
    private var rtfContentPreview: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("富文本文档")
                .font(.headline)
            
            Text("包含格式化文本内容，大小: \(formatFileSize(item.content.count))")
                .font(.caption)
                .foregroundColor(.secondary)
            
            // 尝试显示纯文本版本
            if let attributedString = NSAttributedString(rtf: item.content, documentAttributes: nil),
               !attributedString.string.isEmpty {
                ScrollView {
                    Text(attributedString.string)
                        .font(.system(size: 13))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxHeight: 200)
                .background(Color.secondary.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }
    
    // MARK: - HTML 内容预览
    private var htmlContentPreview: some View {
        let htmlContent = String(data: item.content, encoding: .utf8) ?? ""
        
        return VStack(alignment: .leading, spacing: 8) {
            ScrollView {
                Text(htmlContent)
                    .font(.system(size: 11, design: .monospaced))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxHeight: 300)
            .background(Color.secondary.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            
            Button("在浏览器中预览") {
                saveHTMLAndOpen(htmlContent)
            }
            .foregroundColor(PaletclipColors.accentBlue)
        }
    }
    
    // MARK: - 通用内容预览
    private var genericContentPreview: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("二进制数据")
                .font(.headline)
            
            Text("无法预览此类型的内容")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("数据大小: \(formatFileSize(item.content.count))")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - 颜色调色板区域
    private func colorPaletteSection(colors: [ColorInfo]) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("提取的颜色")
                        .font(.headline)
                    
                    Spacer()
                    
                    Picker("格式", selection: $selectedFormat) {
                        ForEach(ColorFormat.allCases, id: \.self) { format in
                            Text(format.displayName).tag(format)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 200)
                }
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 12) {
                    ForEach(colors, id: \.hexValue) { colorInfo in
                        ColorSwatchCard(colorInfo: colorInfo, format: selectedFormat)
                    }
                }
            }
        }
    }
    
    // MARK: - 技术信息区域
    private var technicalInfoSection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("技术信息")
                    .font(.headline)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                    TechnicalInfoRow(title: "ID", value: item.id.uuidString)
                    TechnicalInfoRow(title: "内容类型", value: item.contentType)
                    TechnicalInfoRow(title: "创建时间", value: formattedFullDate)
                    TechnicalInfoRow(title: "最后访问", value: formattedLastAccess)
                    TechnicalInfoRow(title: "数据大小", value: formatFileSize(item.content.count))
                    if let ext = item.fileExtension {
                        TechnicalInfoRow(title: "文件扩展名", value: ext)
                    }
                }
            }
        }
    }
    
    // MARK: - 辅助视图
    private struct StatItem: View {
        let title: String
        let value: String
        
        var body: some View {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.caption)
                    .fontWeight(.medium)
            }
        }
    }
    
    private struct TechnicalInfoRow: View {
        let title: String
        let value: String
        
        var body: some View {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.caption)
                    .textSelection(.enabled)
                    .lineLimit(3)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    // MARK: - 计算属性
    private var fileTypeIcon: String {
        switch item.contentType {
        case "public.utf8-plain-text", "public.text":
            return "doc.text.fill"
        case let type where type.hasPrefix("public.image"):
            return "photo.fill"
        case "public.url":
            return "link"
        case "public.file-url":
            return "folder.fill"
        case "public.rtf":
            return "doc.richtext.fill"
        case "public.html":
            return "globe"
        default:
            return "doc.fill"
        }
    }
    
    private var fileTypeColor: Color {
        switch item.contentType {
        case "public.utf8-plain-text", "public.text":
            return PaletclipColors.paintBlue
        case let type where type.hasPrefix("public.image"):
            return PaletclipColors.paintGreen
        case "public.url":
            return PaletclipColors.paintPurple
        case "public.file-url":
            return PaletclipColors.paintYellow
        case "public.rtf":
            return PaletclipColors.paintRed
        case "public.html":
            return PaletclipColors.accentBlue
        default:
            return Color.secondary
        }
    }
    
    private var contentTypeDisplayName: String {
        switch item.contentType {
        case "public.utf8-plain-text", "public.text":
            return "文本"
        case let type where type.hasPrefix("public.image"):
            return "图片"
        case "public.url":
            return "链接"
        case "public.file-url":
            return "文件"
        case "public.rtf":
            return "富文本"
        case "public.html":
            return "网页"
        default:
            return "未知类型"
        }
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: item.createdAt)
    }
    
    private var formattedFullDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .medium
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: item.createdAt)
    }
    
    private var formattedLastAccess: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: item.lastAccessedAt)
    }
    
    // MARK: - 辅助方法
    private func formatFileSize(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
    
    private func copyToPasteboard() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        
        switch item.contentType {
        case "public.utf8-plain-text", "public.text":
            if let text = String(data: item.content, encoding: .utf8) {
                pasteboard.setString(text, forType: .string)
            }
        case let type where type.hasPrefix("public.image"):
            pasteboard.setData(item.content, forType: .png)
        case "public.url":
            if let urlString = String(data: item.content, encoding: .utf8) {
                pasteboard.setString(urlString, forType: .URL)
            }
        default:
            pasteboard.setData(item.content, forType: .string)
        }
        
        item.lastAccessedAt = Date()
        try? item.managedObjectContext?.save()
    }
    
    private func toggleStar() {
        item.isStarred.toggle()
        item.lastAccessedAt = Date()
        try? item.managedObjectContext?.save()
    }
    
    private func saveImage(_ image: NSImage) {
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.png]
        savePanel.nameFieldStringValue = "剪贴板图片.png"
        
        if savePanel.runModal() == .OK {
            guard let url = savePanel.url,
                  let tiffData = image.tiffRepresentation,
                  let bitmapRep = NSBitmapImageRep(data: tiffData),
                  let pngData = bitmapRep.representation(using: .png, properties: [:]) else {
                return
            }
            
            try? pngData.write(to: url)
        }
    }
    
    private func saveHTMLAndOpen(_ htmlContent: String) {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("preview.html")
        try? htmlContent.write(to: tempURL, atomically: true, encoding: .utf8)
        NSWorkspace.shared.open(tempURL)
    }
    
    // MARK: - 辅助方法
    private func getImageColorSpace(_ image: NSImage) -> String {
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil),
              let colorSpace = cgImage.colorSpace else {
            return "未知"
        }
        
        let model = colorSpace.model
        if model == .unknown {
            return "未知色彩空间"
        } else if model == .monochrome {
            return "灰度"
        } else if model == .rgb {
            return "RGB"
        } else if model == .cmyk {
            return "CMYK"
        } else if model == .lab {
            return "LAB"
        } else if model == .deviceN {
            return "DeviceN"
        } else if model == .indexed {
            return "索引色"
        } else if model == .pattern {
            return "图案"
        } else {
            return "其他"
        }
    }
}

// 使用 ColorInfo.swift 中定义的 ColorFormat

// MARK: - 颜色样本卡片
struct ColorSwatchCard: View {
    let colorInfo: ColorInfo
    let format: ColorFormat
    @State private var copied = false
    
    private var colorValue: String {
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
    
    var body: some View {
        VStack(spacing: 8) {
            // 颜色圆形
            Circle()
                .fill(Color(hex: colorInfo.hexValue) ?? .gray)
                .frame(width: 40, height: 40)
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
                .shadow(radius: 4)
            
            // 颜色值
            VStack(spacing: 2) {
                Text(colorValue)
                    .font(.caption)
                    .fontWeight(.medium)
                    .textSelection(.enabled)
                
                Text("\(Int(colorInfo.percentage * 100))%")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            // 复制状态
            if copied {
                Text("已复制")
                    .font(.caption2)
                    .foregroundColor(.green)
                    .transition(.opacity)
            }
        }
        .padding(8)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .onTapGesture {
            copyColorValue()
        }
    }
    
    private func copyColorValue() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(colorValue, forType: .string)
        
        withAnimation {
            copied = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation {
                copied = false
            }
        }
    }
}
