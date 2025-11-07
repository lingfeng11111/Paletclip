//
//  ClipboardMonitor.swift
//  Paletclip
//
//  Created by 凌峰 on 2025/11/7.
//

import AppKit
import Foundation
import SwiftUI
import UniformTypeIdentifiers

// MARK: - 剪贴板监控服务
class ClipboardMonitor {
    static let shared = ClipboardMonitor()
    
    var latestItem: ClipboardItem?
    var isMonitoring: Bool = false
    var onNewItem: ((ClipboardItem) -> Void)?
    
    private let pasteboard = NSPasteboard.general
    private var changeCount: Int = 0
    private var monitorTimer: Timer?
    private let coreDataStack = CoreDataStack.shared
    
    // 支持的文件类型
    private let supportedTypes: [NSPasteboard.PasteboardType] = [
        .string,
        .png,
        .tiff,
        .pdf,
        .rtf,
        .html,
        .URL,
        .fileURL,
        // 添加更多图像格式支持
        NSPasteboard.PasteboardType("public.jpeg"),
        NSPasteboard.PasteboardType("public.svg-image"), 
        NSPasteboard.PasteboardType("com.compuserve.gif"),
        NSPasteboard.PasteboardType("com.microsoft.bmp"),
        NSPasteboard.PasteboardType("public.webp")
    ]
    
    // 监控间隔（秒）
    private let monitoringInterval: TimeInterval = 0.3
    
    // 最大存储数量
    private let maxStorageCount: Int = 1000
    
    private init() {}
    
    // MARK: - 公开方法
    
    /// 开始监控剪贴板
    func startMonitoring() {
        guard !isMonitoring else { return }
        
        isMonitoring = true
        changeCount = pasteboard.changeCount
        
        monitorTimer = Timer.scheduledTimer(withTimeInterval: monitoringInterval, repeats: true) { [weak self] _ in
            self?.checkForChanges()
        }
        
        print("📋 剪贴板监控已启动")
    }
    
    /// 停止监控剪贴板
    func stopMonitoring() {
        guard isMonitoring else { return }
        
        isMonitoring = false
        monitorTimer?.invalidate()
        monitorTimer = nil
        
        print("📋 剪贴板监控已停止")
    }
    
    /// 手动检查剪贴板变化
    func checkClipboard() {
        checkForChanges()
    }
    
    // MARK: - 私有方法
    
    /// 检查剪贴板变化
    private func checkForChanges() {
        let currentCount = pasteboard.changeCount
        
        if currentCount != changeCount {
            let previousCount = changeCount
            changeCount = currentCount
            
            print("📋 检测到剪贴板变化: \(previousCount) → \(currentCount)")
            
            Task {
                await processNewClipboardContent()
            }
        } else {
            // 偶尔打印状态
            if currentCount % 100 == 0 {
                print("📋 剪贴板监控运行中 (changeCount: \(currentCount))")
            }
        }
    }
    
    /// 处理新的剪贴板内容
    @MainActor
    private func processNewClipboardContent() async {
        print("🔄 开始处理剪贴板内容...")
        
        do {
            let clipboardItem = try await createClipboardItem()
            
            if let item = clipboardItem {
                print("📝 创建剪贴板项目成功: \(item.contentType)")
                print("📏 内容大小: \(item.content.count) 字节")
                
                // 保存到 Core Data
                await saveClipboardItem(item)
                print("💾 保存到 Core Data 完成")
                
                // 更新最新项目
                self.latestItem = item
                
                // 通知回调
                self.onNewItem?(item)
                print("🔔 通知回调完成")
                
                // 触发颜色提取（如果是图像）
                if item.contentType.hasPrefix("public.image") {
                    print("🎨 开始提取图像颜色...")
                    await extractColors(for: item)
                }
                
                // 清理旧数据
                await cleanupOldItems()
                print("✅ 剪贴板内容处理完成")
            } else {
                print("⚠️ 无法创建剪贴板项目 - 可能是重复内容或不支持的格式")
            }
        } catch {
            print("❌ 处理剪贴板内容时出错: \(error)")
        }
    }
    
    /// 创建剪贴板项目
    @MainActor
    private func createClipboardItem() async throws -> ClipboardItem? {
        // 直接在主线程的 viewContext 中创建，避免跨上下文同步问题
        let context = coreDataStack.viewContext
        var clipboardItem: ClipboardItem?
        
        print("📋 检查剪贴板支持的类型...")
        for pasteboardType in supportedTypes {
            print("🔍 检查类型: \(pasteboardType.rawValue)")
        }
        
        // 检查剪贴板中实际可用的类型
        let availableTypes = pasteboard.types ?? []
        print("📋 剪贴板中可用的类型: \(availableTypes.map { $0.rawValue })")
        
        // 检查每种支持的类型
        for pasteboardType in supportedTypes {
            if let data = pasteboard.data(forType: pasteboardType) {
                let contentType = getUTType(for: pasteboardType)
                let fileExtension = getFileExtension(for: contentType)
                
                print("📝 创建剪贴板项目: \(contentType), 大小: \(data.count) 字节")
                print("📝 剪贴板类型: \(pasteboardType.rawValue) -> UT类型: \(contentType)")
                
                clipboardItem = ClipboardItem.create(
                    content: data,
                    contentType: contentType,
                    in: context,
                    fileExtension: fileExtension
                )
                
                // 生成缩略图
                generateThumbnail(for: clipboardItem!, contentType: contentType, data: data)
                
                break
            }
        }
        
        return clipboardItem
    }
    
    /// 保存剪贴板项目
    @MainActor
    private func saveClipboardItem(_ item: ClipboardItem) async {
        // 直接在主线程保存 viewContext，无需跨上下文同步
        do {
            coreDataStack.save()
            print("💾 viewContext 保存成功")
            
            // 立即测试查询验证
            let request: NSFetchRequest<ClipboardItem> = ClipboardItem.fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
            request.fetchLimit = 5
            
            let testItems = try coreDataStack.viewContext.fetch(request)
            print("🧪 保存后立即查询结果: \(testItems.count) 个项目")
            for (index, testItem) in testItems.enumerated() {
                print("  \(index + 1). \(testItem.contentType) - \(testItem.createdAt)")
            }
            
        } catch {
            print("❌ viewContext 保存失败: \(error)")
        }
    }
    
    /// 生成缩略图
    private func generateThumbnail(for item: ClipboardItem, contentType: String, data: Data) {
        switch contentType {
        case let type where type.hasPrefix("public.image"):
            print("🖼️ 尝试为图像生成缩略图，类型: \(type)，数据大小: \(data.count)")
            if let image = NSImage(data: data) {
                print("✅ 成功创建NSImage，尺寸: \(image.size)")
                let thumbnailSize = CGSize(width: 200, height: 200)
                let thumbnail = resizeImage(image, to: thumbnailSize)
                item.setThumbnail(thumbnail, quality: 0.8)
                print("✅ 缩略图生成完成")
            } else {
                print("❌ 无法从数据创建NSImage，可能是不支持的图像格式")
            }
            
        case "public.utf8-plain-text", "public.text":
            // 为文本生成文本预览缩略图
            if let text = String(data: data, encoding: .utf8) {
                let thumbnail = generateTextThumbnail(text: text)
                item.setThumbnail(thumbnail, quality: 0.9)
            }
            
        case "public.url":
            // 为 URL 生成链接预览缩略图
            if let urlString = String(data: data, encoding: .utf8) {
                let thumbnail = generateURLThumbnail(urlString: urlString)
                item.setThumbnail(thumbnail, quality: 0.9)
            }
            
        default:
            break
        }
    }
    
    /// 提取颜色信息
    @MainActor
    private func extractColors(for item: ClipboardItem) async {
        guard item.contentType.hasPrefix("public.image") else { return }
        
        // content 是非可选的 Data，但 NSImage(data:) 返回可选的 NSImage?
        guard let image = NSImage(data: item.content) else { return }
        
        let colorExtractor = ColorExtractor()
        let colors = await colorExtractor.extractDominantColors(from: image, maxColors: 6)
        
        item.setColorPalette(colors)
        coreDataStack.save()
        print("🎨 颜色提取完成，保存了 \(colors.count) 种颜色")
    }
    
    /// 清理旧项目
    @MainActor
    private func cleanupOldItems() async {
        let context = coreDataStack.viewContext
        let request: NSFetchRequest<ClipboardItem> = ClipboardItem.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        
        do {
            let items = try context.fetch(request)
            
            // 如果超过最大数量，删除最旧的项目
            if items.count > maxStorageCount {
                let itemsToDelete = Array(items.dropFirst(maxStorageCount))
                
                for item in itemsToDelete {
                    // 只删除非星标项目
                    if !item.isStarred {
                        context.delete(item)
                    }
                }
                
                coreDataStack.save()
                print("🧹 清理完成，删除了 \(itemsToDelete.count) 个旧项目")
            }
        } catch {
            print("❌ 清理旧项目时出错: \(error)")
        }
    }
    
    // MARK: - 工具方法
    
    /// 获取 UTType
    private func getUTType(for pasteboardType: NSPasteboard.PasteboardType) -> String {
        switch pasteboardType {
        case .string:
            return UTType.utf8PlainText.identifier
        case .png:
            return UTType.png.identifier
        case .tiff:
            return UTType.tiff.identifier
        case .pdf:
            return UTType.pdf.identifier
        case .rtf:
            return UTType.rtf.identifier
        case .html:
            return UTType.html.identifier
        case .URL:
            return UTType.url.identifier
        case .fileURL:
            return UTType.fileURL.identifier
        default:
            return UTType.data.identifier
        }
    }
    
    /// 获取文件扩展名
    private func getFileExtension(for utType: String) -> String? {
        if let type = UTType(utType) {
            return type.preferredFilenameExtension
        }
        return nil
    }
    
    /// 调整图像尺寸
    private func resizeImage(_ image: NSImage, to size: CGSize) -> NSImage {
        let newImage = NSImage(size: size)
        
        newImage.lockFocus()
        let imageRect = NSRect(origin: .zero, size: size)
        image.draw(in: imageRect, from: NSRect(origin: .zero, size: image.size), operation: .sourceOver, fraction: 1.0)
        newImage.unlockFocus()
        
        return newImage
    }
    
    /// 生成文本缩略图
    private func generateTextThumbnail(text: String) -> NSImage {
        let maxLength = 100
        let displayText = text.count > maxLength ? String(text.prefix(maxLength)) + "..." : text
        
        let size = CGSize(width: 200, height: 100)
        let image = NSImage(size: size)
        
        image.lockFocus()
        
        // 背景
        NSColor.controlBackgroundColor.set()
        NSRect(origin: .zero, size: size).fill()
        
        // 文本
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 12),
            .foregroundColor: NSColor.labelColor
        ]
        
        let attributedText = NSAttributedString(string: displayText, attributes: attributes)
        let textRect = NSRect(x: 8, y: 8, width: size.width - 16, height: size.height - 16)
        attributedText.draw(in: textRect)
        
        image.unlockFocus()
        
        return image
    }
    
    /// 生成 URL 缩略图
    private func generateURLThumbnail(urlString: String) -> NSImage {
        let size = CGSize(width: 200, height: 100)
        let image = NSImage(size: size)
        
        image.lockFocus()
        
        // 背景
        NSColor.controlBackgroundColor.set()
        NSRect(origin: .zero, size: size).fill()
        
        // URL 图标
        let linkIcon = NSImage(systemSymbolName: "link", accessibilityDescription: nil) ?? NSImage()
        let iconRect = NSRect(x: 8, y: size.height - 32, width: 24, height: 24)
        linkIcon.draw(in: iconRect)
        
        // URL 文本
        let displayURL = urlString.count > 30 ? String(urlString.prefix(30)) + "..." : urlString
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 10),
            .foregroundColor: NSColor.secondaryLabelColor
        ]
        
        let attributedText = NSAttributedString(string: displayURL, attributes: attributes)
        let textRect = NSRect(x: 8, y: 8, width: size.width - 16, height: 20)
        attributedText.draw(in: textRect)
        
        image.unlockFocus()
        
        return image
    }
}

// MARK: - 错误类型
enum ClipboardError: Error {
    case noSupportedContent
    case dataProcessingFailed
    case coreDataError(Error)
}

extension ClipboardError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .noSupportedContent:
            return "剪贴板中没有支持的内容类型"
        case .dataProcessingFailed:
            return "数据处理失败"
        case .coreDataError(let error):
            return "数据保存失败: \(error.localizedDescription)"
        }
    }
}
