//
//  ClipboardItem.swift
//  Paletclip
//
//  Created by 凌峰 on 2025/11/7.
//

import CoreData
import Foundation
import SwiftUI

@objc(ClipboardItem)
public class ClipboardItem: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var content: Data
    @NSManaged public var contentType: String
    @NSManaged public var fileExtension: String?
    @NSManaged public var thumbnail: Data?
    @NSManaged public var thumbnailQuality: Int16
    @NSManaged public var colorPalette: Data? // JSON encoded ColorInfo array
    @NSManaged public var isStarred: Bool
    @NSManaged public var createdAt: Date
    @NSManaged public var lastAccessedAt: Date
    @NSManaged public var folder: Folder?
    @NSManaged public var tags: Set<Tag>
}

// MARK: - Core Data Properties
extension ClipboardItem {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<ClipboardItem> {
        return NSFetchRequest<ClipboardItem>(entityName: "ClipboardItem")
    }
    
    // 获取解码后的颜色调色板
    var decodedColorPalette: [ColorInfo]? {
        guard let colorPalette = colorPalette else { return nil }
        return try? JSONDecoder().decode([ColorInfo].self, from: colorPalette)
    }
    
    // 设置颜色调色板
    func setColorPalette(_ colors: [ColorInfo]) {
        self.colorPalette = try? JSONEncoder().encode(colors)
    }
    
    // 获取内容预览
    var contentPreview: String {
        switch contentType {
        case "public.utf8-plain-text", "public.text":
            return String(data: content, encoding: .utf8) ?? "无法预览文本内容"
        case "public.png", "public.jpeg", "public.tiff":
            return "图像文件"
        case "public.url":
            return String(data: content, encoding: .utf8) ?? "URL"
        default:
            return "未知格式"
        }
    }
    
    // 获取缩略图
    var thumbnailImage: NSImage? {
        guard let thumbnail = thumbnail else { return nil }
        return NSImage(data: thumbnail)
    }
    
    // 设置缩略图
    func setThumbnail(_ image: NSImage, quality: Float = 0.8) {
        guard let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData) else { return }
        
        self.thumbnail = bitmap.representation(using: .jpeg, properties: [
            .compressionFactor: quality
        ])
        self.thumbnailQuality = Int16(quality * 100)
    }
}

// MARK: - Identifiable
extension ClipboardItem: Identifiable {
    
}

// MARK: - 便利初始化
extension ClipboardItem {
    static func create(
        content: Data,
        contentType: String,
        in context: NSManagedObjectContext,
        fileExtension: String? = nil
    ) -> ClipboardItem {
        let item = ClipboardItem(context: context)
        item.id = UUID()
        item.content = content
        item.contentType = contentType
        item.fileExtension = fileExtension
        item.isStarred = false
        item.createdAt = Date()
        item.lastAccessedAt = Date()
        return item
    }
}
