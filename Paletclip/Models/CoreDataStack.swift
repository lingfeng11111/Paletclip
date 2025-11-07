//
//  CoreDataStack.swift
//  Paletclip
//
//  Created by 凌峰 on 2025/11/7.
//

import CoreData
import Foundation

class CoreDataStack {
    static let shared = CoreDataStack()
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "Paletclip")
        
        // 设置存储位置到应用支持目录
        let applicationSupportURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let paletclipURL = applicationSupportURL.appendingPathComponent("Paletclip")
        
        // 创建目录（如果不存在）
        try? FileManager.default.createDirectory(at: paletclipURL, withIntermediateDirectories: true, attributes: nil)
        
        let storeURL = paletclipURL.appendingPathComponent("Paletclip.sqlite")
        let storeDescription = NSPersistentStoreDescription(url: storeURL)
        storeDescription.shouldInferMappingModelAutomatically = true
        storeDescription.shouldMigrateStoreAutomatically = true
        
        container.persistentStoreDescriptions = [storeDescription]
        
        container.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                print("⚠️ Core Data 加载失败: \(error), \(error.userInfo)")
                print("📁 尝试的存储路径: \(storeDescription.url?.path ?? "未知")")
                
                // 尝试删除损坏的存储文件重新创建
                if let storeURL = storeDescription.url {
                    try? FileManager.default.removeItem(at: storeURL)
                    
                    // 重新加载
                    container.loadPersistentStores { _, retryError in
                        if let retryError = retryError {
                            print("💥 Core Data 重试失败: \(retryError)")
                        } else {
                            print("✅ Core Data 重新创建成功")
                        }
                    }
                }
            } else {
                print("✅ Core Data 加载成功: \(storeDescription.url?.path ?? "未知路径")")
            }
        }
        
        // 配置 viewContext
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        // 设置通知合并策略
        container.viewContext.name = "MainViewContext"
        
        return container
    }()
    
    var viewContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    var backgroundContext: NSManagedObjectContext {
        return persistentContainer.newBackgroundContext()
    }
    
    func save() {
        let context = persistentContainer.viewContext
        
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nsError = error as NSError
                fatalError("Core Data save error: \(nsError), \(nsError.userInfo)")
            }
        }
    }
    
    func saveContext(_ context: NSManagedObjectContext) {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nsError = error as NSError
                print("Core Data save error: \(nsError), \(nsError.userInfo)")
            }
        }
    }
}
