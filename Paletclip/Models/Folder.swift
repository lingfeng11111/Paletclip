//
//  Folder.swift
//  Paletclip
//
//  Created by 凌峰 on 2025/11/7.
//

import CoreData
import Foundation
import SwiftUI

@objc(Folder)
public class Folder: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var name: String
    @NSManaged public var colorTheme: String
    @NSManaged public var createdAt: Date
    @NSManaged public var items: Set<ClipboardItem>
    @NSManaged public var sortOrder: Int16
}

// MARK: - Core Data Properties
extension Folder {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Folder> {
        return NSFetchRequest<Folder>(entityName: "Folder")
    }
    
    // 获取主题颜色
    var themeColor: Color {
        return PaletclipColors.color(named: colorTheme)
    }
    
    // 项目数量
    var itemCount: Int {
        return items.count
    }
    
    // 排序后的项目
    var sortedItems: [ClipboardItem] {
        return items.sorted { $0.createdAt > $1.createdAt }
    }
}

// MARK: - Identifiable
extension Folder: Identifiable {
    
}

// MARK: - 便利初始化
extension Folder {
    static func create(
        name: String,
        colorTheme: String = "blue",
        in context: NSManagedObjectContext
    ) -> Folder {
        let folder = Folder(context: context)
        folder.id = UUID()
        folder.name = name
        folder.colorTheme = colorTheme
        folder.createdAt = Date()
        folder.sortOrder = 0
        folder.items = Set<ClipboardItem>()
        return folder
    }
}

// MARK: - Tag 模型
@objc(Tag)
public class Tag: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var name: String
    @NSManaged public var color: String
    @NSManaged public var createdAt: Date
    @NSManaged public var items: Set<ClipboardItem>
}

extension Tag {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Tag> {
        return NSFetchRequest<Tag>(entityName: "Tag")
    }
    
    var tagColor: Color {
        return PaletclipColors.color(named: color)
    }
}

extension Tag: Identifiable {
    
}
