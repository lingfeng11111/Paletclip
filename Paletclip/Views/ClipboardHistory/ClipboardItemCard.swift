//
//  ClipboardItemCard.swift
//  Paletclip
//
//  Created by 凌峰 on 2025/11/7.
//

import SwiftUI
import CoreData

// MARK: - 剪贴板项目卡片
struct ClipboardItemCard: View {
    let item: ClipboardItem
    @State private var isHovered = false
    @State private var showingPreview = false
    
    var body: some View {
        GlassCard(
            cornerRadius: 12,
            padding: EdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12)
        ) {
            VStack(alignment: .leading, spacing: 8) {
                // 头部信息
                HStack {
                    // 文件类型图标
                    Image(systemName: fileTypeIcon)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(fileTypeColor)
                    
                    Text(contentTypeDisplayName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    // 星标指示器
                    if item.isStarred {
                        Image(systemName: "star.fill")
                            .font(.caption2)
                            .foregroundColor(PaletclipColors.paintYellow)
                    }
                    
                    Spacer()
                    
                    // 时间戳
                    Text(timeAgo)
                        .font(.caption2)
                        .foregroundColor(Color.secondary)
                }
                
                // 主要内容区域
                contentView
                
                // 颜色调色板（仅图片类型）
                if item.contentType.hasPrefix("public.image"), 
                   let colors = item.decodedColorPalette, !colors.isEmpty {
                    ColorPalettePreview(colors: colors)
                }
                
                // 底部操作区域
                if isHovered {
                    bottomActions
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }
        }
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
        .onTapGesture {
            copyToPasteboard()
        }
        .contextMenu {
            contextMenuItems
        }
        .sheet(isPresented: $showingPreview) {
            ItemPreviewSheet(item: item)
        }
    }
    
    // MARK: - 内容视图
    @ViewBuilder
    private var contentView: some View {
        switch item.contentType {
        case "public.utf8-plain-text", "public.text":
            TextContentView(item: item)
                
        case let type where type.hasPrefix("public.image"):
            ImageContentView(item: item)
                
        case "public.url":
            URLContentView(item: item)
                
        case "public.file-url":
            FileContentView(item: item)
            
        case "public.rtf":
            RTFContentView(item: item)
            
        case "public.html":
            HTMLContentView(item: item)
            
        default:
            GenericContentView(item: item)
        }
    }
    
    // MARK: - 底部操作按钮
    private var bottomActions: some View {
        HStack(spacing: 8) {
            // 快速预览
            GlassButton(
                "",
                icon: "eye.fill",
                style: .icon()
            ) {
                showingPreview = true
            }
            
            // 复制按钮
            GlassButton(
                "",
                icon: "doc.on.doc.fill",
                style: .icon()
            ) {
                copyToPasteboard()
            }
            
            Spacer()
            
            // 星标按钮
            GlassButton(
                "",
                icon: item.isStarred ? "star.fill" : "star",
                style: .icon()
            ) {
                toggleStar()
            }
            
            // 删除按钮
            GlassButton(
                "",
                icon: "trash.fill",
                style: .icon()
            ) {
                deleteItem()
            }
        }
        .padding(.top, 4)
    }
    
    // MARK: - 右键菜单
    private var contextMenuItems: some View {
        Group {
            Button("复制") {
                copyToPasteboard()
            }
            
            Button("快速预览") {
                showingPreview = true
            }
            
            Divider()
            
            Button(item.isStarred ? "取消星标" : "添加星标") {
                toggleStar()
            }
            
            Button("添加到文件夹...") {
                // TODO: 实现添加到文件夹功能
            }
            
            Divider()
            
            Button("删除", role: .destructive) {
                deleteItem()
            }
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
        case "public.pdf":
            return "doc.fill"
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
        case "public.pdf":
            return "PDF"
        default:
            return "未知"
        }
    }
    
    private var timeAgo: String {
        let now = Date()
        let interval = now.timeIntervalSince(item.createdAt)
        
        if interval < 60 {
            return "刚刚"
        } else if interval < 3600 {
            return "\(Int(interval / 60))分钟前"
        } else if interval < 86400 {
            return "\(Int(interval / 3600))小时前"
        } else {
            let days = Int(interval / 86400)
            return "\(days)天前"
        }
    }
    
    // MARK: - 操作方法
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
        
        // 更新最后访问时间
        item.lastAccessedAt = Date()
        try? item.managedObjectContext?.save()
    }
    
    private func toggleStar() {
        item.isStarred.toggle()
        item.lastAccessedAt = Date()
        try? item.managedObjectContext?.save()
    }
    
    private func deleteItem() {
        guard let context = item.managedObjectContext else { return }
        context.delete(item)
        try? context.save()
    }
}

// MARK: - 颜色调色板预览
struct ColorPalettePreview: View {
    let colors: [ColorInfo]
    
    var body: some View {
        HStack(spacing: 4) {
            Text("色彩")
                .font(.caption2)
                .foregroundColor(.secondary)
            
            HStack(spacing: 2) {
                ForEach(colors.prefix(6), id: \.hexValue) { colorInfo in
                    Circle()
                        .fill(Color(hex: colorInfo.hexValue) ?? .gray)
                        .frame(width: 12, height: 12)
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.3), lineWidth: 0.5)
                        )
                }
            }
            
            Spacer()
        }
    }
}

// Color.init(hex:) 扩展已在 ColorInfo.swift 中定义

// MARK: - 预览
#Preview {
    VStack {
        // Text item preview
        ClipboardItemCard(item: {
            let item = ClipboardItem(context: CoreDataStack.shared.viewContext)
            item.id = UUID()
            item.content = "Hello, World! This is a sample text content.".data(using: .utf8)!
            item.contentType = "public.utf8-plain-text"
            item.createdAt = Date()
            item.lastAccessedAt = Date()
            item.isStarred = false
            return item
        }())
        
        Spacer()
    }
    .padding()
    .background(.ultraThinMaterial)
}
