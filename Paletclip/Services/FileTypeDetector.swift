//
//  FileTypeDetector.swift
//  Paletclip
//
//  Created by 凌峰 on 2025/11/7.
//

import Foundation
import SwiftUI
import UniformTypeIdentifiers

// MARK: - 文件类型检测服务
class FileTypeDetector {
    static let shared = FileTypeDetector()
    
    private init() {}
    
    // MARK: - 公开方法
    
    /// 检测数据的文件类型
    func detectFileType(from data: Data) -> DetectedFileType {
        // 1. 尝试通过文件头检测
        if let typeFromHeader = detectFromHeader(data) {
            return typeFromHeader
        }
        
        // 2. 尝试通过内容特征检测
        if let typeFromContent = detectFromContent(data) {
            return typeFromContent
        }
        
        // 3. 默认为未知类型
        return DetectedFileType(
            utType: UTType.data.identifier,
            fileExtension: nil,
            mimeType: "application/octet-stream",
            category: .data,
            confidence: 0.0
        )
    }
    
    /// 从文件扩展名获取类型信息
    func getFileType(from fileExtension: String) -> DetectedFileType? {
        let cleanExtension = fileExtension.lowercased().trimmingCharacters(in: CharacterSet(charactersIn: "."))
        
        guard let utType = UTType(filenameExtension: cleanExtension) else { return nil }
        
        let category = categorizeUTType(utType)
        let mimeType = utType.preferredMIMEType ?? "application/octet-stream"
        
        return DetectedFileType(
            utType: utType.identifier,
            fileExtension: cleanExtension,
            mimeType: mimeType,
            category: category,
            confidence: 0.8
        )
    }
    
    /// 检查是否为支持的文件类型
    func isSupportedType(_ utType: String) -> Bool {
        let supportedTypes: Set<String> = [
            // 图像类型
            UTType.png.identifier,
            UTType.jpeg.identifier,
            UTType.tiff.identifier,
            UTType.gif.identifier,
            UTType.bmp.identifier,
            UTType.webP.identifier,
            UTType.svg.identifier,
            
            // 文本类型
            UTType.utf8PlainText.identifier,
            UTType.plainText.identifier,
            UTType.rtf.identifier,
            UTType.html.identifier,
            UTType.xml.identifier,
            UTType.json.identifier,
            
            // 文档类型
            UTType.pdf.identifier,
            
            // 链接类型
            UTType.url.identifier,
            UTType.fileURL.identifier,
            
            // 其他常用类型
            UTType.data.identifier
        ]
        
        return supportedTypes.contains(utType)
    }
    
    /// 获取文件类型的描述
    func getTypeDescription(for utType: String) -> String {
        guard let type = UTType(utType) else { return "未知格式" }
        
        return type.localizedDescription ?? type.identifier
    }
    
    // MARK: - 私有方法
    
    /// 通过文件头检测文件类型
    private func detectFromHeader(_ data: Data) -> DetectedFileType? {
        guard data.count >= 4 else { return nil }
        
        let headerBytes = data.prefix(16)
        let header = headerBytes.map { $0 }
        
        // PNG 文件头: 89 50 4E 47
        if header.starts(with: [0x89, 0x50, 0x4E, 0x47]) {
            return DetectedFileType(
                utType: UTType.png.identifier,
                fileExtension: "png",
                mimeType: "image/png",
                category: .image,
                confidence: 1.0
            )
        }
        
        // JPEG 文件头: FF D8
        if header.starts(with: [0xFF, 0xD8]) {
            return DetectedFileType(
                utType: UTType.jpeg.identifier,
                fileExtension: "jpg",
                mimeType: "image/jpeg",
                category: .image,
                confidence: 1.0
            )
        }
        
        // GIF 文件头: 47 49 46 38
        if header.starts(with: [0x47, 0x49, 0x46, 0x38]) {
            return DetectedFileType(
                utType: UTType.gif.identifier,
                fileExtension: "gif",
                mimeType: "image/gif",
                category: .image,
                confidence: 1.0
            )
        }
        
        // PDF 文件头: 25 50 44 46
        if header.starts(with: [0x25, 0x50, 0x44, 0x46]) {
            return DetectedFileType(
                utType: UTType.pdf.identifier,
                fileExtension: "pdf",
                mimeType: "application/pdf",
                category: .document,
                confidence: 1.0
            )
        }
        
        // BMP 文件头: 42 4D
        if header.starts(with: [0x42, 0x4D]) {
            return DetectedFileType(
                utType: UTType.bmp.identifier,
                fileExtension: "bmp",
                mimeType: "image/bmp",
                category: .image,
                confidence: 1.0
            )
        }
        
        // TIFF 文件头: 49 49 2A 00 或 4D 4D 00 2A
        if header.starts(with: [0x49, 0x49, 0x2A, 0x00]) || header.starts(with: [0x4D, 0x4D, 0x00, 0x2A]) {
            return DetectedFileType(
                utType: UTType.tiff.identifier,
                fileExtension: "tiff",
                mimeType: "image/tiff",
                category: .image,
                confidence: 1.0
            )
        }
        
        // WebP 文件头: 52 49 46 46 ... 57 45 42 50
        if header.starts(with: [0x52, 0x49, 0x46, 0x46]) && header.count >= 12 {
            let webpSignature = Array(header[8..<12])
            if webpSignature == [0x57, 0x45, 0x42, 0x50] {
                return DetectedFileType(
                    utType: UTType.webP.identifier,
                    fileExtension: "webp",
                    mimeType: "image/webp",
                    category: .image,
                    confidence: 1.0
                )
            }
        }
        
        return nil
    }
    
    /// 通过内容特征检测文件类型
    private func detectFromContent(_ data: Data) -> DetectedFileType? {
        // 尝试将数据解析为文本
        if let text = String(data: data, encoding: .utf8) {
            return detectTextType(text)
        }
        
        // 尝试其他编码
        let encodings: [String.Encoding] = [.utf16, .ascii, .isoLatin1]
        for encoding in encodings {
            if let text = String(data: data, encoding: encoding) {
                return detectTextType(text)
            }
        }
        
        return nil
    }
    
    /// 检测文本类型
    private func detectTextType(_ text: String) -> DetectedFileType? {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // HTML 检测
        if trimmedText.lowercased().contains("<html") || 
           trimmedText.lowercased().contains("<!doctype html") ||
           (trimmedText.contains("<") && trimmedText.contains(">")) {
            return DetectedFileType(
                utType: UTType.html.identifier,
                fileExtension: "html",
                mimeType: "text/html",
                category: .text,
                confidence: 0.8
            )
        }
        
        // XML 检测
        if trimmedText.hasPrefix("<?xml") || 
           (trimmedText.contains("<") && trimmedText.contains("/>")) {
            return DetectedFileType(
                utType: UTType.xml.identifier,
                fileExtension: "xml",
                mimeType: "application/xml",
                category: .text,
                confidence: 0.8
            )
        }
        
        // JSON 检测
        if (trimmedText.hasPrefix("{") && trimmedText.hasSuffix("}")) ||
           (trimmedText.hasPrefix("[") && trimmedText.hasSuffix("]")) {
            // 尝试解析 JSON
            if let _ = try? JSONSerialization.jsonObject(with: Data(trimmedText.utf8), options: []) {
                return DetectedFileType(
                    utType: UTType.json.identifier,
                    fileExtension: "json",
                    mimeType: "application/json",
                    category: .text,
                    confidence: 0.9
                )
            }
        }
        
        // URL 检测
        if isValidURL(trimmedText) {
            return DetectedFileType(
                utType: UTType.url.identifier,
                fileExtension: nil,
                mimeType: "text/uri-list",
                category: .url,
                confidence: 0.9
            )
        }
        
        // 文件路径检测
        if isFilePath(trimmedText) {
            return DetectedFileType(
                utType: UTType.fileURL.identifier,
                fileExtension: nil,
                mimeType: "text/uri-list",
                category: .url,
                confidence: 0.7
            )
        }
        
        // 默认为纯文本
        return DetectedFileType(
            utType: UTType.utf8PlainText.identifier,
            fileExtension: "txt",
            mimeType: "text/plain",
            category: .text,
            confidence: 0.6
        )
    }
    
    /// 检查是否为有效 URL
    private func isValidURL(_ text: String) -> Bool {
        guard let url = URL(string: text.trimmingCharacters(in: .whitespacesAndNewlines)) else { return false }
        
        // 检查是否有有效的协议
        let validSchemes = ["http", "https", "ftp", "ftps", "file"]
        if let scheme = url.scheme?.lowercased(), validSchemes.contains(scheme) {
            return true
        }
        
        // 检查是否看起来像 URL（包含域名模式）
        let urlPattern = "^(https?://)?(www\\.)?[a-zA-Z0-9-]+\\.[a-zA-Z]{2,}(/.*)?$"
        let regex = try? NSRegularExpression(pattern: urlPattern, options: .caseInsensitive)
        let range = NSRange(location: 0, length: text.count)
        return regex?.firstMatch(in: text, options: [], range: range) != nil
    }
    
    /// 检查是否为文件路径
    private func isFilePath(_ text: String) -> Bool {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 绝对路径
        if trimmedText.hasPrefix("/") || trimmedText.hasPrefix("~") {
            return true
        }
        
        // Windows 路径
        if trimmedText.count > 2 && trimmedText[trimmedText.index(trimmedText.startIndex, offsetBy: 1)] == ":" {
            return true
        }
        
        // 包含路径分隔符且看起来像文件名
        if trimmedText.contains("/") || trimmedText.contains("\\") {
            let components = trimmedText.components(separatedBy: CharacterSet(charactersIn: "/\\"))
            if let lastComponent = components.last, lastComponent.contains(".") {
                return true
            }
        }
        
        return false
    }
    
    /// 分类 UTType
    private func categorizeUTType(_ utType: UTType) -> FileTypeCategory {
        if utType.conforms(to: .image) {
            return .image
        } else if utType.conforms(to: .text) {
            return .text
        } else if utType.conforms(to: .pdf) {
            return .document
        } else if utType.conforms(to: .audio) {
            return .audio
        } else if utType.conforms(to: .video) {
            return .video
        } else if utType.conforms(to: .archive) {
            return .archive
        } else if utType == .url || utType == .fileURL {
            return .url
        } else {
            return .data
        }
    }
}

// MARK: - 检测到的文件类型
struct DetectedFileType {
    let utType: String
    let fileExtension: String?
    let mimeType: String
    let category: FileTypeCategory
    let confidence: Double // 0.0 - 1.0
    
    /// 是否为高可信度检测
    var isHighConfidence: Bool {
        return confidence >= 0.8
    }
    
    /// 类型描述
    var description: String {
        if let ext = fileExtension {
            return ext.uppercased()
        }
        return category.displayName
    }
    
    /// 详细描述
    var detailedDescription: String {
        let typeDescription = FileTypeDetector.shared.getTypeDescription(for: utType)
        if let ext = fileExtension {
            return "\(typeDescription) (.\(ext))"
        }
        return typeDescription
    }
}

// MARK: - 文件类型分类
enum FileTypeCategory: String, CaseIterable {
    case image = "image"
    case text = "text"
    case document = "document"
    case audio = "audio"
    case video = "video"
    case archive = "archive"
    case url = "url"
    case data = "data"
    
    var displayName: String {
        switch self {
        case .image:
            return "图像"
        case .text:
            return "文本"
        case .document:
            return "文档"
        case .audio:
            return "音频"
        case .video:
            return "视频"
        case .archive:
            return "压缩包"
        case .url:
            return "链接"
        case .data:
            return "数据"
        }
    }
    
    var iconName: String {
        switch self {
        case .image:
            return "photo"
        case .text:
            return "doc.text"
        case .document:
            return "doc"
        case .audio:
            return "music.note"
        case .video:
            return "video"
        case .archive:
            return "archivebox"
        case .url:
            return "link"
        case .data:
            return "doc.badge.gearshape"
        }
    }
    
    var color: Color {
        switch self {
        case .image:
            return PaletclipColors.paintBlue
        case .text:
            return PaletclipColors.paintGreen
        case .document:
            return PaletclipColors.paintRed
        case .audio:
            return PaletclipColors.paintYellow
        case .video:
            return PaletclipColors.paintPurple
        case .archive:
            return PaletclipColors.glassDark
        case .url:
            return PaletclipColors.accent
        case .data:
            return PaletclipColors.glassDark
        }
    }
}
