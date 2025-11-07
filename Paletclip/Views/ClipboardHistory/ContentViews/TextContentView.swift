//
//  TextContentView.swift
//  Paletclip
//
//  Created by 凌峰 on 2025/11/7.
//

import SwiftUI

// MARK: - 文本内容视图
struct TextContentView: View {
    let item: ClipboardItem
    @State private var isExpanded = false
    
    private var textContent: String {
        String(data: item.content, encoding: .utf8) ?? "无法解析文本内容"
    }
    
    private var previewText: String {
        let maxLength = 120
        return textContent.count > maxLength ? 
            String(textContent.prefix(maxLength)) + "..." : 
            textContent
    }
    
    private var wordCount: Int {
        textContent.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }.count
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 文本内容
            VStack(alignment: .leading, spacing: 4) {
                Text(isExpanded ? textContent : previewText)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(.primary)
                    .lineLimit(isExpanded ? nil : 4)
                    .fixedSize(horizontal: false, vertical: true)
                    .textSelection(.enabled)
                
                // 展开/收起按钮
                if textContent.count > 120 {
                    Button(isExpanded ? "收起" : "展开") {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isExpanded.toggle()
                        }
                    }
                    .font(.caption)
                    .foregroundColor(PaletclipColors.accentBlue)
                    .buttonStyle(.plain)
                }
            }
            
            // 文本统计信息
            HStack {
                Label("\(textContent.count) 字符", systemImage: "textformat.abc")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                if wordCount > 0 {
                    Label("\(wordCount) 词", systemImage: "textformat.123")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // 文本类型检测
                if let detectedType = detectTextType() {
                    Text(detectedType)
                        .font(.caption2)
                        .foregroundColor(PaletclipColors.paintPurple)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(PaletclipColors.paintPurple.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
            }
        }
    }
    
    // MARK: - 文本类型检测
    private func detectTextType() -> String? {
        let content = textContent.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 检测 JSON
        if content.hasPrefix("{") && content.hasSuffix("}") ||
           content.hasPrefix("[") && content.hasSuffix("]") {
            return "JSON"
        }
        
        // 检测 XML/HTML
        if content.hasPrefix("<") && content.hasSuffix(">") {
            return content.contains("<!DOCTYPE html") ? "HTML" : "XML"
        }
        
        // 检测 Markdown
        if content.contains("# ") || content.contains("## ") || 
           content.contains("**") || content.contains("* ") {
            return "Markdown"
        }
        
        // 检测代码
        if content.contains("func ") || content.contains("class ") ||
           content.contains("def ") || content.contains("var ") {
            return "代码"
        }
        
        // 检测邮箱
        if content.range(of: #"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}"#, 
                        options: .regularExpression) != nil {
            return "邮箱"
        }
        
        // 检测电话号码
        if content.range(of: #"(\+?\d{1,3}[-.\s]?)?\(?\d{3}\)?[-.\s]?\d{3}[-.\s]?\d{4}"#,
                        options: .regularExpression) != nil {
            return "电话"
        }
        
        return nil
    }
}

// MARK: - 图片内容视图
struct ImageContentView: View {
    let item: ClipboardItem
    @State private var thumbnailImage: NSImage?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 图片缩略图
            if let thumbnailImage = thumbnailImage {
                Image(nsImage: thumbnailImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.white.opacity(0.3), lineWidth: 0.5)
                    )
            } else {
                // 加载占位符
                RoundedRectangle(cornerRadius: 8)
                    .fill(PaletclipColors.glassGray)
                    .frame(height: 80)
                    .overlay(
                        VStack {
                            Image(systemName: "photo")
                                .font(.title2)
                                .foregroundColor(.secondary)
                            Text("加载中...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    )
            }
            
            // 图片信息
            if let image = NSImage(data: item.content) {
                HStack {
                    Label("\(Int(image.size.width))×\(Int(image.size.height))", 
                          systemImage: "rectangle.and.text.magnifyingglass")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Label(formatFileSize(item.content.count), systemImage: "internaldrive")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(getImageFormat())
                        .font(.caption2)
                        .foregroundColor(PaletclipColors.paintGreen)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(PaletclipColors.paintGreen.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
            }
        }
        .onAppear {
            loadThumbnail()
        }
    }
    
    private func loadThumbnail() {
        if let existingThumbnail = item.thumbnailImage {
            thumbnailImage = existingThumbnail
        } else if let image = NSImage(data: item.content) {
            // 生成缩略图
            let thumbnailSize = CGSize(width: 200, height: 200)
            let thumbnail = image.resized(to: thumbnailSize)
            thumbnailImage = thumbnail
        }
    }
    
    private func getImageFormat() -> String {
        switch item.contentType {
        case "public.png":
            return "PNG"
        case "public.jpeg":
            return "JPEG"
        case "public.tiff":
            return "TIFF"
        case "public.gif":
            return "GIF"
        default:
            return "图片"
        }
    }
    
    private func formatFileSize(_ bytes: Int) -> String {
        let kb = Double(bytes) / 1024
        if kb < 1024 {
            return String(format: "%.1f KB", kb)
        } else {
            let mb = kb / 1024
            return String(format: "%.1f MB", mb)
        }
    }
}

// MARK: - URL 内容视图
struct URLContentView: View {
    let item: ClipboardItem
    
    private var urlString: String {
        String(data: item.content, encoding: .utf8) ?? ""
    }
    
    private var displayURL: String {
        if let url = URL(string: urlString) {
            return url.host ?? urlString
        }
        return urlString
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // URL 显示
            HStack {
                Image(systemName: "link")
                    .foregroundColor(PaletclipColors.paintPurple)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(displayURL)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    if displayURL != urlString {
                        Text(urlString)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }
                
                Spacer()
                
                Button("打开") {
                    if let url = URL(string: urlString) {
                        NSWorkspace.shared.open(url)
                    }
                }
                .font(.caption)
                .foregroundColor(PaletclipColors.accentBlue)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(PaletclipColors.accentBlue.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            
            // URL 类型和长度信息
            HStack {
                if let urlType = detectURLType() {
                    Text(urlType)
                        .font(.caption2)
                        .foregroundColor(PaletclipColors.paintPurple)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(PaletclipColors.paintPurple.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
                
                Spacer()
                
                Text("\(urlString.count) 字符")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private func detectURLType() -> String? {
        guard let url = URL(string: urlString) else { return nil }
        
        if let scheme = url.scheme?.lowercased() {
            switch scheme {
            case "https":
                return "安全链接"
            case "http":
                return "网页链接"
            case "mailto":
                return "邮箱链接"
            case "tel":
                return "电话链接"
            case "ftp":
                return "FTP"
            default:
                return scheme.uppercased()
            }
        }
        
        return nil
    }
}

// MARK: - 文件内容视图
struct FileContentView: View {
    let item: ClipboardItem
    
    private var filePath: String {
        String(data: item.content, encoding: .utf8) ?? ""
    }
    
    private var fileName: String {
        URL(fileURLWithPath: filePath).lastPathComponent
    }
    
    private var fileExtension: String {
        URL(fileURLWithPath: filePath).pathExtension.uppercased()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "folder.fill")
                    .foregroundColor(PaletclipColors.paintYellow)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(fileName)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Text(filePath)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                Button("显示") {
                    let url = URL(fileURLWithPath: filePath)
                    NSWorkspace.shared.selectFile(filePath, inFileViewerRootedAtPath: url.deletingLastPathComponent().path)
                }
                .font(.caption)
                .foregroundColor(PaletclipColors.accentBlue)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(PaletclipColors.accentBlue.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            
            HStack {
                if !fileExtension.isEmpty {
                    Text(fileExtension)
                        .font(.caption2)
                        .foregroundColor(PaletclipColors.paintYellow)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(PaletclipColors.paintYellow.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
                
                Spacer()
                
                if FileManager.default.fileExists(atPath: filePath) {
                    Text("文件存在")
                        .font(.caption2)
                        .foregroundColor(.green)
                } else {
                    Text("文件不存在")
                        .font(.caption2)
                        .foregroundColor(.red)
                }
            }
        }
    }
}

// MARK: - RTF 内容视图
struct RTFContentView: View {
    let item: ClipboardItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "doc.richtext.fill")
                    .foregroundColor(PaletclipColors.paintRed)
                
                Text("富文本文档")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("RTF")
                    .font(.caption2)
                    .foregroundColor(PaletclipColors.paintRed)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(PaletclipColors.paintRed.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }
            
            Text("富文本内容，\(item.content.count) 字节")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - HTML 内容视图
struct HTMLContentView: View {
    let item: ClipboardItem
    
    private var htmlContent: String {
        String(data: item.content, encoding: .utf8) ?? ""
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "globe")
                    .foregroundColor(PaletclipColors.accentBlue)
                
                Text("HTML 内容")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("HTML")
                    .font(.caption2)
                    .foregroundColor(PaletclipColors.accentBlue)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(PaletclipColors.accentBlue.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }
            
            Text(htmlContent.prefix(100) + (htmlContent.count > 100 ? "..." : ""))
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(.secondary)
                .lineLimit(3)
        }
    }
}

// MARK: - 通用内容视图
struct GenericContentView: View {
    let item: ClipboardItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "doc.fill")
                    .foregroundColor(.secondary)
                
                Text("未知格式")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text(item.contentType)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.secondary.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }
            
            Text("数据大小：\(item.content.count) 字节")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - NSImage 扩展
extension NSImage {
    func resized(to size: CGSize) -> NSImage {
        let newImage = NSImage(size: size)
        newImage.lockFocus()
        defer { newImage.unlockFocus() }
        
        let imageRect = NSRect(origin: .zero, size: size)
        self.draw(in: imageRect, from: NSRect(origin: .zero, size: self.size), operation: .sourceOver, fraction: 1.0)
        
        return newImage
    }
}
