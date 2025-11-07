//
//  ClipboardManager.swift
//  Paletclip
//
//  Created by 凌峰 on 2025/11/7.
//

import Combine
import CoreData
import Foundation
import SwiftUI

// MARK: - 剪贴板管理器（UI 数据源）
class ClipboardManager: ObservableObject {
    static let shared = ClipboardManager()
    
    @Published var recentItems: [ClipboardItem] = []
    @Published var starredItems: [ClipboardItem] = []
    @Published var folders: [Folder] = []
    @Published var isLoading: Bool = false
    @Published var latestItem: ClipboardItem?
    
    private let coreDataStack = CoreDataStack.shared
    private let clipboardMonitor = ClipboardMonitor.shared
    
    private init() {
        setupObservers()
        loadInitialData()
    }
    
    // MARK: - 公开方法
    
    /// 刷新数据
    func refreshData() {
        Task { @MainActor in
            isLoading = true
            await loadRecentItems()
            await loadStarredItems() 
            await loadFolders()
            isLoading = false
        }
    }
    
    /// 切换星标状态
    func toggleStar(for item: ClipboardItem) {
        item.isStarred.toggle()
        item.lastAccessedAt = Date()
        
        coreDataStack.save()
        
        Task { @MainActor in
            await loadRecentItems()
            await loadStarredItems()
        }
    }
    
    /// 删除项目
    func deleteItem(_ item: ClipboardItem) {
        let context = coreDataStack.viewContext
        context.delete(item)
        coreDataStack.save()
        
        Task { @MainActor in
            await loadRecentItems()
            await loadStarredItems()
        }
    }
    
    /// 创建文件夹
    func createFolder(name: String, colorTheme: String = "blue") {
        let context = coreDataStack.viewContext
        let _ = Folder.create(name: name, colorTheme: colorTheme, in: context)
        coreDataStack.save()
        
        Task { @MainActor in
            await loadFolders()
        }
    }
    
    /// 移动项目到文件夹
    func moveItem(_ item: ClipboardItem, to folder: Folder?) {
        item.folder = folder
        item.lastAccessedAt = Date()
        coreDataStack.save()
        
        Task { @MainActor in
            await loadRecentItems()
        }
    }
    
    // MARK: - 私有方法
    
    private func setupObservers() {
        // 监听剪贴板变化
        clipboardMonitor.onNewItem = { [weak self] newItem in
            print("🔔 ClipboardManager 收到新项目通知: \(newItem.contentType)")
            DispatchQueue.main.async {
                self?.latestItem = newItem
                Task {
                    await self?.loadRecentItems()
                    print("📱 UI 数据已刷新")
                }
            }
        }
        
        // 启动剪贴板监控
        clipboardMonitor.startMonitoring()
        print("▶️ 剪贴板监控已启动")
        
        // 监听 Core Data 变化
        NotificationCenter.default.addObserver(
            forName: .NSManagedObjectContextDidSave,
            object: coreDataStack.viewContext,
            queue: .main
        ) { [weak self] _ in
            Task {
                await self?.refreshData()
            }
        }
    }
    
    @MainActor
    private func loadInitialData() {
        Task {
            await loadRecentItems()
            await loadStarredItems()
            await loadFolders()
        }
    }
    
    @MainActor
    private func loadRecentItems() async {
        print("🔄 ClipboardManager 开始加载最近项目...")
        
        let viewContext = coreDataStack.viewContext
        let request: NSFetchRequest<ClipboardItem> = ClipboardItem.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        request.fetchLimit = 50
        
        do {
            let items = try viewContext.fetch(request)
            print("📊 ClipboardManager 获取到 \(items.count) 个最近项目")
            for (index, item) in items.prefix(3).enumerated() {
                print("  \(index + 1). \(item.contentType) - \(item.createdAt)")
            }
            
            let oldCount = self.recentItems.count
            self.recentItems = items
            print("✅ ClipboardManager recentItems 已更新: \(oldCount) → \(items.count)")
            print("📋 @Published 属性应该触发 UI 更新")
            
        } catch {
            print("❌ ClipboardManager 加载最近项目失败: \(error)")
        }
    }
    
    @MainActor
    private func loadStarredItems() async {
        let request: NSFetchRequest<ClipboardItem> = ClipboardItem.fetchRequest()
        request.predicate = NSPredicate(format: "isStarred == YES")
        request.sortDescriptors = [NSSortDescriptor(key: "lastAccessedAt", ascending: false)]
        
        do {
            let items = try coreDataStack.viewContext.fetch(request)
            self.starredItems = items
        } catch {
            print("加载星标项目失败: \(error)")
        }
    }
    
    @MainActor
    private func loadFolders() async {
        let request: NSFetchRequest<Folder> = Folder.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(key: "sortOrder", ascending: true),
            NSSortDescriptor(key: "createdAt", ascending: false)
        ]
        
        do {
            let fetchedFolders = try coreDataStack.viewContext.fetch(request)
            self.folders = fetchedFolders
        } catch {
            print("加载文件夹失败: \(error)")
        }
    }
}

// MARK: - 搜索功能扩展
extension ClipboardManager {
    
    /// 搜索项目
    @MainActor
    func searchItems(query: String) async -> [ClipboardItem] {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return recentItems
        }
        
        let request: NSFetchRequest<ClipboardItem> = ClipboardItem.fetchRequest()
        
        // 构建搜索谓词 - 搜索内容类型和预览文本
        let predicates = [
            NSPredicate(format: "contentType CONTAINS[cd] %@", query),
            NSPredicate(format: "fileExtension CONTAINS[cd] %@", query)
        ]
        
        request.predicate = NSCompoundPredicate(orPredicateWithSubpredicates: predicates)
        request.sortDescriptors = [NSSortDescriptor(key: "lastAccessedAt", ascending: false)]
        request.fetchLimit = 30
        
        do {
            return try coreDataStack.viewContext.fetch(request)
        } catch {
            print("搜索失败: \(error)")
            return []
        }
    }
}
