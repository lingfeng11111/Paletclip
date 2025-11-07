//
//  ThumbnailGenerator.swift
//  Paletclip
//
//  Created by 凌峰 on 2025/11/7.
//

import AppKit
import Foundation
import SwiftUI
import UniformTypeIdentifiers

// MARK: - 缩略图生成服务
class ThumbnailGenerator {
    static let shared = ThumbnailGenerator()
    
    private let thumbnailCache = NSCache<NSString, NSImage>()
    private let processingQueue = DispatchQueue(label: "thumbnail.processing", qos: .utility)
    
    // 默认缩略图尺寸
    private let defaultThumbnailSize = CGSize(width: 200, height: 200)
    private let maxThumbnailSize = CGSize(width: 500, height: 500)
    
    init() {
        setupCache()
    }
    
    // MARK: - 公开方法
    
    /// 为剪贴板项目生成缩略图
    func generateThumbnail(for item: ClipboardItem, size: CGSize? = nil) async -> NSImage? {
        let thumbnailSize = size ?? defaultThumbnailSize
        let cacheKeyString = "\(item.id.uuidString)_\(thumbnailSize.width)x\(thumbnailSize.height)"
        let cacheKey = cacheKeyString as NSString
        
        // 检查缓存
        if let cachedThumbnail = thumbnailCache.object(forKey: cacheKey) {
            return cachedThumbnail
        }
        
        // 提取需要的数据，避免在闭包中捕获 ClipboardItem
        let itemContent = item.content
        let itemContentType = item.contentType
        
        return await withCheckedContinuation { continuation in
            // 使用 String 类型避免 Sendable 问题
            let cacheKeyStringForClosure = cacheKeyString
            processingQueue.async {
                let thumbnail = self.createThumbnailFromData(itemContent, contentType: itemContentType, size: thumbnailSize)
                if let thumbnail = thumbnail {
                    // 在需要时转换为 NSString
                    self.thumbnailCache.setObject(thumbnail, forKey: cacheKeyStringForClosure as NSString)
                }
                continuation.resume(returning: thumbnail)
            }
        }
    }
    
    /// 从数据生成缩略图
    func generateThumbnail(from data: Data, contentType: String, size: CGSize? = nil) async -> NSImage? {
        let thumbnailSize = size ?? defaultThumbnailSize
        
        return await withCheckedContinuation { continuation in
            processingQueue.async {
                let thumbnail = self.createThumbnailFromData(data, contentType: contentType, size: thumbnailSize)
                continuation.resume(returning: thumbnail)
            }
        }
    }
    
    /// 清除缓存
    func clearCache() {
        thumbnailCache.removeAllObjects()
    }
    
    /// 获取缓存统计信息
    func getCacheInfo() -> (count: Int, size: String) {
        let count = thumbnailCache.countLimit
        let size = ByteCountFormatter().string(fromByteCount: Int64(thumbnailCache.totalCostLimit))
        return (count, size)
    }
    
    // MARK: - 私有方法
    
    /// 创建缩略图
    private func createThumbnail(for item: ClipboardItem, size: CGSize) -> NSImage? {
        return createThumbnailFromData(item.content, contentType: item.contentType, size: size)
    }
    
    /// 从数据创建缩略图
    private func createThumbnailFromData(_ data: Data, contentType: String, size: CGSize) -> NSImage? {
        switch contentType {
        case let type where type.hasPrefix("public.image"):
            return createImageThumbnail(from: data, size: size)
            
        case "public.utf8-plain-text", "public.text":
            return createTextThumbnail(from: data, size: size)
            
        case "public.url":
            return createURLThumbnail(from: data, size: size)
            
        case "public.rtf":
            return createRTFThumbnail(from: data, size: size)
            
        case "public.html":
            return createHTMLThumbnail(from: data, size: size)
            
        case "public.pdf":
            return createPDFThumbnail(from: data, size: size)
            
        case "public.file-url":
            return createFileThumbnail(from: data, size: size)
            
        default:
            return createGenericThumbnail(contentType: contentType, size: size)
        }
    }
    
    /// 创建图像缩略图
    private func createImageThumbnail(from data: Data, size: CGSize) -> NSImage? {
        guard let originalImage = NSImage(data: data) else { return nil }
        
        let thumbnailSize = calculateThumbnailSize(original: originalImage.size, target: size)
        
        let thumbnail = NSImage(size: thumbnailSize)
        thumbnail.lockFocus()
        
        // 设置高质量的插值
        NSGraphicsContext.current?.imageInterpolation = .high
        
        // 绘制图像
        let imageRect = NSRect(origin: .zero, size: thumbnailSize)
        originalImage.draw(in: imageRect, from: NSRect(origin: .zero, size: originalImage.size), operation: .sourceOver, fraction: 1.0)
        
        thumbnail.unlockFocus()
        
        return thumbnail
    }
    
    /// 创建文本缩略图
    private func createTextThumbnail(from data: Data, size: CGSize) -> NSImage? {
        guard let text = String(data: data, encoding: .utf8) else { return nil }
        
        let thumbnail = NSImage(size: size)
        thumbnail.lockFocus()
        
        // 背景
        PaletclipColors.cardBackground.nsColor.set()
        NSRect(origin: .zero, size: size).fill()
        
        // 文本图标
        let iconSize: CGFloat = 24
        let iconRect = NSRect(x: 12, y: size.height - iconSize - 12, width: iconSize, height: iconSize)
        if let textIcon = NSImage(systemSymbolName: "doc.text", accessibilityDescription: nil) {
            textIcon.draw(in: iconRect, from: .zero, operation: .sourceOver, fraction: 0.7)
        }
        
        // 文本内容
        let maxLength = 150
        let displayText = text.count > maxLength ? String(text.prefix(maxLength)) + "..." : text
        
        let textAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 11),
            .foregroundColor: NSColor.labelColor,
            .paragraphStyle: {
                let style = NSMutableParagraphStyle()
                style.lineSpacing = 2
                style.lineBreakMode = .byWordWrapping
                return style
            }()
        ]
        
        let attributedText = NSAttributedString(string: displayText, attributes: textAttributes)
        let textRect = NSRect(x: 12, y: 12, width: size.width - 24, height: size.height - iconSize - 36)
        attributedText.draw(in: textRect)
        
        thumbnail.unlockFocus()
        
        return thumbnail
    }
    
    /// 创建 URL 缩略图
    private func createURLThumbnail(from data: Data, size: CGSize) -> NSImage? {
        guard let urlString = String(data: data, encoding: .utf8) else { return nil }
        
        let thumbnail = NSImage(size: size)
        thumbnail.lockFocus()
        
        // 背景渐变
        let gradient = NSGradient(colors: [
            PaletclipColors.paintBlue.nsColor.withAlphaComponent(0.1),
            PaletclipColors.paintBlue.nsColor.withAlphaComponent(0.05)
        ])
        gradient?.draw(in: NSRect(origin: .zero, size: size), angle: 45)
        
        // 链接图标
        let iconSize: CGFloat = 32
        let iconRect = NSRect(x: 12, y: size.height - iconSize - 12, width: iconSize, height: iconSize)
        if let linkIcon = NSImage(systemSymbolName: "link.circle.fill", accessibilityDescription: nil) {
            PaletclipColors.accent.nsColor.set()
            linkIcon.draw(in: iconRect, from: .zero, operation: .sourceOver, fraction: 1.0)
        }
        
        // URL 文本
        let displayURL = urlString.count > 40 ? String(urlString.prefix(40)) + "..." : urlString
        
        let urlAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 10, weight: .medium),
            .foregroundColor: PaletclipColors.accent.nsColor
        ]
        
        let attributedURL = NSAttributedString(string: displayURL, attributes: urlAttributes)
        let urlRect = NSRect(x: 12, y: size.height - iconSize - 36, width: size.width - 24, height: 20)
        attributedURL.draw(in: urlRect)
        
        // 域名提取
        if let url = URL(string: urlString), let host = url.host {
            let hostAttributes: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: 14, weight: .semibold),
                .foregroundColor: NSColor.labelColor
            ]
            
            let attributedHost = NSAttributedString(string: host, attributes: hostAttributes)
            let hostRect = NSRect(x: 12, y: 20, width: size.width - 24, height: 20)
            attributedHost.draw(in: hostRect)
        }
        
        thumbnail.unlockFocus()
        
        return thumbnail
    }
    
    /// 创建 RTF 缩略图
    private func createRTFThumbnail(from data: Data, size: CGSize) -> NSImage? {
        let thumbnail = NSImage(size: size)
        thumbnail.lockFocus()
        
        // 背景
        PaletclipColors.cardBackground.nsColor.set()
        NSRect(origin: .zero, size: size).fill()
        
        // RTF 图标
        let iconSize: CGFloat = 28
        let iconRect = NSRect(x: 12, y: size.height - iconSize - 12, width: iconSize, height: iconSize)
        if let rtfIcon = NSImage(systemSymbolName: "doc.richtext", accessibilityDescription: nil) {
            PaletclipColors.paintYellow.nsColor.set()
            rtfIcon.draw(in: iconRect, from: .zero, operation: .sourceOver, fraction: 1.0)
        }
        
        // 标签
        let labelAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 12, weight: .medium),
            .foregroundColor: NSColor.secondaryLabelColor
        ]
        
        let label = NSAttributedString(string: "富文本文档", attributes: labelAttributes)
        let labelRect = NSRect(x: 12, y: size.height - 60, width: size.width - 24, height: 20)
        label.draw(in: labelRect)
        
        thumbnail.unlockFocus()
        
        return thumbnail
    }
    
    /// 创建 HTML 缩略图
    private func createHTMLThumbnail(from data: Data, size: CGSize) -> NSImage? {
        let thumbnail = NSImage(size: size)
        thumbnail.lockFocus()
        
        // 背景
        NSColor.controlBackgroundColor.set()
        NSRect(origin: .zero, size: size).fill()
        
        // HTML 标签样式背景
        PaletclipColors.paintRed.nsColor.withAlphaComponent(0.1).set()
        let tagRect = NSRect(x: 8, y: size.height - 40, width: size.width - 16, height: 32)
        NSBezierPath(roundedRect: tagRect, xRadius: 4, yRadius: 4).fill()
        
        // HTML 图标
        let iconSize: CGFloat = 20
        let iconRect = NSRect(x: 12, y: size.height - 32, width: iconSize, height: iconSize)
        if let htmlIcon = NSImage(systemSymbolName: "safari", accessibilityDescription: nil) {
            PaletclipColors.paintRed.nsColor.set()
            htmlIcon.draw(in: iconRect, from: .zero, operation: .sourceOver, fraction: 1.0)
        }
        
        // HTML 标签
        let tagAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedSystemFont(ofSize: 10, weight: .medium),
            .foregroundColor: PaletclipColors.paintRed.nsColor
        ]
        
        let tagText = NSAttributedString(string: "<HTML>", attributes: tagAttributes)
        let textRect = NSRect(x: 40, y: size.height - 28, width: 60, height: 20)
        tagText.draw(in: textRect)
        
        thumbnail.unlockFocus()
        
        return thumbnail
    }
    
    /// 创建 PDF 缩略图
    private func createPDFThumbnail(from data: Data, size: CGSize) -> NSImage? {
        // 尝试从 PDF 数据创建预览
        if let pdfRep = NSPDFImageRep(data: data) {
            let thumbnail = NSImage(size: size)
            thumbnail.lockFocus()
            
            let thumbnailSize = calculateThumbnailSize(original: pdfRep.size, target: size)
            let drawRect = NSRect(
                x: (size.width - thumbnailSize.width) / 2,
                y: (size.height - thumbnailSize.height) / 2,
                width: thumbnailSize.width,
                height: thumbnailSize.height
            )
            
            pdfRep.draw(in: drawRect)
            
            thumbnail.unlockFocus()
            return thumbnail
        }
        
        // 创建通用 PDF 图标
        return createGenericThumbnail(contentType: "PDF 文档", size: size, icon: "doc.fill", color: PaletclipColors.paintRed)
    }
    
    /// 创建文件缩略图
    private func createFileThumbnail(from data: Data, size: CGSize) -> NSImage? {
        guard let urlString = String(data: data, encoding: .utf8),
              let fileURL = URL(string: urlString) else { return nil }
        
        let thumbnail = NSImage(size: size)
        thumbnail.lockFocus()
        
        // 背景
        PaletclipColors.cardBackground.nsColor.set()
        NSRect(origin: .zero, size: size).fill()
        
        // 文件图标
        let iconSize: CGFloat = 40
        let iconRect = NSRect(x: (size.width - iconSize) / 2, y: size.height - iconSize - 20, width: iconSize, height: iconSize)
        
        // 根据文件扩展名选择图标
        let fileExtension = fileURL.pathExtension.lowercased()
        let (iconName, iconColor) = getFileIcon(for: fileExtension)
        
        if let fileIcon = NSImage(systemSymbolName: iconName, accessibilityDescription: nil) {
            iconColor.nsColor.set()
            fileIcon.draw(in: iconRect, from: .zero, operation: .sourceOver, fraction: 1.0)
        }
        
        // 文件名
        let fileName = fileURL.lastPathComponent
        let displayName = fileName.count > 20 ? String(fileName.prefix(17)) + "..." : fileName
        
        let nameAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 11, weight: .medium),
            .foregroundColor: NSColor.labelColor,
            .paragraphStyle: {
                let style = NSMutableParagraphStyle()
                style.alignment = .center
                return style
            }()
        ]
        
        let attributedName = NSAttributedString(string: displayName, attributes: nameAttributes)
        let nameRect = NSRect(x: 8, y: 20, width: size.width - 16, height: 40)
        attributedName.draw(in: nameRect)
        
        thumbnail.unlockFocus()
        
        return thumbnail
    }
    
    /// 创建通用缩略图
    private func createGenericThumbnail(contentType: String, size: CGSize, icon: String = "doc", color: Color = PaletclipColors.glassDark) -> NSImage {
        let thumbnail = NSImage(size: size)
        thumbnail.lockFocus()
        
        // 背景
        PaletclipColors.cardBackground.nsColor.set()
        NSRect(origin: .zero, size: size).fill()
        
        // 图标
        let iconSize: CGFloat = 32
        let iconRect = NSRect(x: (size.width - iconSize) / 2, y: size.height - iconSize - 20, width: iconSize, height: iconSize)
        if let genericIcon = NSImage(systemSymbolName: icon, accessibilityDescription: nil) {
            color.nsColor.set()
            genericIcon.draw(in: iconRect, from: .zero, operation: .sourceOver, fraction: 1.0)
        }
        
        // 类型标签
        let typeAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 10, weight: .medium),
            .foregroundColor: NSColor.secondaryLabelColor,
            .paragraphStyle: {
                let style = NSMutableParagraphStyle()
                style.alignment = .center
                return style
            }()
        ]
        
        let typeLabel = NSAttributedString(string: contentType, attributes: typeAttributes)
        let typeRect = NSRect(x: 8, y: 20, width: size.width - 16, height: 20)
        typeLabel.draw(in: typeRect)
        
        thumbnail.unlockFocus()
        
        return thumbnail
    }
    
    /// 计算缩略图尺寸
    private func calculateThumbnailSize(original: CGSize, target: CGSize) -> CGSize {
        let aspectRatio = original.width / original.height
        
        var thumbnailSize: CGSize
        
        if aspectRatio > 1 {
            // 宽度更大
            thumbnailSize = CGSize(width: target.width, height: target.width / aspectRatio)
        } else {
            // 高度更大或正方形
            thumbnailSize = CGSize(width: target.height * aspectRatio, height: target.height)
        }
        
        // 确保不超过最大尺寸
        if thumbnailSize.width > maxThumbnailSize.width || thumbnailSize.height > maxThumbnailSize.height {
            let scale = min(maxThumbnailSize.width / thumbnailSize.width, maxThumbnailSize.height / thumbnailSize.height)
            thumbnailSize = CGSize(width: thumbnailSize.width * scale, height: thumbnailSize.height * scale)
        }
        
        return thumbnailSize
    }
    
    /// 获取文件图标
    private func getFileIcon(for fileExtension: String) -> (iconName: String, color: Color) {
        switch fileExtension {
        case "jpg", "jpeg", "png", "gif", "bmp", "tiff":
            return ("photo", PaletclipColors.paintBlue)
        case "mp4", "mov", "avi", "mkv":
            return ("video", PaletclipColors.paintPurple)
        case "mp3", "wav", "aac", "flac":
            return ("music.note", PaletclipColors.paintYellow)
        case "pdf":
            return ("doc.fill", PaletclipColors.paintRed)
        case "doc", "docx":
            return ("doc.text", PaletclipColors.paintBlue)
        case "xls", "xlsx":
            return ("tablecells", PaletclipColors.paintGreen)
        case "ppt", "pptx":
            return ("rectangle.on.rectangle", PaletclipColors.paintRed)
        case "zip", "rar", "7z":
            return ("archivebox", PaletclipColors.glassDark)
        case "txt":
            return ("doc.plaintext", PaletclipColors.glassDark)
        default:
            return ("doc", PaletclipColors.glassDark)
        }
    }
    
    /// 设置缓存配置
    private func setupCache() {
        thumbnailCache.countLimit = 200 // 最多缓存200个缩略图
        thumbnailCache.totalCostLimit = 100 * 1024 * 1024 // 100MB
    }
}

// MARK: - Color 扩展
extension Color {
    var nsColor: NSColor {
        return NSColor(self)
    }
}
