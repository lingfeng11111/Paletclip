//
//  AppDelegate.swift
//  Paletclip
//
//  Created by 凌峰 on 2025/11/7.
//

import AppKit
import Foundation
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusBarController: StatusBarController?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // 设置应用为后台应用（状态栏应用）
        NSApp.setActivationPolicy(.accessory)
        
        // 初始化状态栏控制器
        setupStatusBar()
        
        // 启动剪贴板监控
        ClipboardMonitor.shared.startMonitoring()
        
        // 初始化 Core Data
        _ = CoreDataStack.shared
        
        print("🚀 Paletclip 已启动")
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        // 停止剪贴板监控
        ClipboardMonitor.shared.stopMonitoring()
        
        // 保存 Core Data 变更
        CoreDataStack.shared.save()
        
        print("👋 Paletclip 已退出")
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        // 当应用图标被点击时显示状态栏菜单
        statusBarController?.showPopover()
        return true
    }
    
    // MARK: - 私有方法
    
    private func setupStatusBar() {
        statusBarController = StatusBarController()
    }
}

// MARK: - 状态栏控制器
class StatusBarController {
    private var statusItem: NSStatusItem
    private var popover: NSPopover
    
    init() {
        // 创建状态栏项目
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        // 创建弹出窗口
        popover = NSPopover()
        popover.contentSize = NSSize(width: 420, height: 650)
        popover.behavior = .transient
        popover.animates = true
        
        setupStatusItem()
        setupPopover()
    }
    
    private func setupStatusItem() {
        guard let button = statusItem.button else { return }
        
        // 设置图标
        button.image = NSImage(systemSymbolName: "paintpalette", accessibilityDescription: "Paletclip")
        button.imagePosition = .imageOnly
        
        // 设置工具提示
        button.toolTip = "Paletclip - 剪贴板管理工具"
        
        // 设置点击事件
        button.action = #selector(statusItemClicked(_:))
        button.target = self
    }
    
    private func setupPopover() {
        // 设置内容视图
        let contentView = StatusBarPopoverView()
            .environmentObject(ClipboardManager.shared)
            .environment(\.managedObjectContext, CoreDataStack.shared.viewContext)
        
        popover.contentViewController = NSHostingController(rootView: contentView)
    }
    
    @objc private func statusItemClicked(_ sender: NSStatusBarButton) {
        print("🖱️ 状态栏按钮被点击")
        if popover.isShown {
            print("📋 隐藏 popover")
            hidePopover()
        } else {
            print("📋 显示 popover")
            showPopover()
        }
    }
    
    func showPopover() {
        guard let button = statusItem.button else { 
            print("❌ 无法获取状态栏按钮")
            return 
        }
        
        print("🎭 正在显示 popover...")
        print("📊 ClipboardManager.recentItems 数量: \(ClipboardManager.shared.recentItems.count)")
        
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        
        // 激活应用以确保弹出窗口获得焦点
        NSApp.activate(ignoringOtherApps: true)
        print("✅ popover 已显示并激活")
    }
    
    func hidePopover() {
        print("🎭 隐藏 popover")
        popover.performClose(nil)
    }
}

// MARK: - 状态栏弹出视图
struct StatusBarPopoverView: View {
    @EnvironmentObject private var clipboardManager: ClipboardManager
    @Environment(\.managedObjectContext) private var viewContext
    @State private var selectedTab: TabType = .recent
    @State private var searchText: String = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // 顶部搜索栏
            SearchBarView(searchText: $searchText)
                .padding(.horizontal, 16)
                .padding(.top, 12)
            
            // 标签页选择器
            TabSelectorView(selection: $selectedTab)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            
            Divider()
                .opacity(0.3)
            
            // 主内容区域
            Group {
                switch selectedTab {
                case .recent:
                    RecentClipboardView(searchText: searchText)
                        .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
                case .starred:
                    StarredItemsView(searchText: searchText)
                        .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
                case .folders:
                    CustomFoldersView(searchText: searchText)
                        .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
                }
            }
        }
        .frame(width: 420, height: 650)
        .background(.ultraThinMaterial)
    }
}

// MARK: - 搜索栏视图
struct SearchBarView: View {
    @Binding var searchText: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(PaletclipColors.placeholderText)
            
            TextField("搜索剪贴板内容...", text: $searchText)
                .textFieldStyle(PlainTextFieldStyle())
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(PaletclipColors.inputBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(PaletclipColors.secondaryBorder, lineWidth: 0.5)
                )
        )
    }
}

// MARK: - 标签页选择器
struct TabSelectorView: View {
    @Binding var selection: TabType
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(TabType.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selection = tab
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: tab.iconName)
                            .font(.caption)
                        Text(tab.displayName)
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(selection == tab ? .white : PaletclipColors.adaptiveText)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(selection == tab ? 
                                LinearGradient(
                                    colors: [PaletclipColors.accentBlue.opacity(0.8), PaletclipColors.accentBlue.opacity(0.6)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ) : 
                                LinearGradient(colors: [.clear], startPoint: .top, endPoint: .bottom)
                            )
                    }
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            Spacer()
            
            // 设置按钮
            GlassButton("", icon: "gearshape", style: .icon(size: 28)) {
                // TODO: 打开设置界面
            }
        }
    }
}

// MARK: - 标签页类型
enum TabType: String, CaseIterable {
    case recent = "recent"
    case starred = "starred"
    case folders = "folders"
    
    var displayName: String {
        switch self {
        case .recent:
            return "最近"
        case .starred:
            return "星标"
        case .folders:
            return "文件夹"
        }
    }
    
    var iconName: String {
        switch self {
        case .recent:
            return "clock"
        case .starred:
            return "star"
        case .folders:
            return "folder"
        }
    }
}

// MARK: - 最近剪贴板视图
struct RecentClipboardView: View {
    let searchText: String
    @EnvironmentObject private var clipboardManager: ClipboardManager
    @State private var searchResults: [ClipboardItem] = []
    
    var displayItems: [ClipboardItem] {
        let items = searchText.isEmpty ? clipboardManager.recentItems : searchResults
        print("🎭 RecentClipboardView.displayItems: \(items.count) 个项目")
        return items
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                if displayItems.isEmpty {
                    EmptyStateView(
                        icon: "clock.arrow.circlepath",
                        title: searchText.isEmpty ? "暂无剪贴板内容" : "未找到匹配结果",
                        subtitle: searchText.isEmpty ? "复制一些内容开始使用 Paletclip" : "尝试其他搜索关键词"
                    )
                    .padding(.top, 50)
                    .onAppear {
                        print("📋 显示空状态视图 - recentItems: \(clipboardManager.recentItems.count), searchText: '\(searchText)'")
                    }
                } else {
                    ForEach(displayItems, id: \.id) { item in
                        ClipboardItemRow(item: item)
                            .onTapGesture {
                                copyToPasteboard(item)
                            }
                    }
                    .onAppear {
                        print("📋 显示 \(displayItems.count) 个剪贴板项目")
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.top, 8)
        }
        .onChange(of: searchText) { _, newValue in
            if !newValue.isEmpty {
                Task {
                    searchResults = await clipboardManager.searchItems(query: newValue)
                }
            }
        }
        .refreshable {
            clipboardManager.refreshData()
        }
    }
    
    private func copyToPasteboard(_ item: ClipboardItem) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        
        switch item.contentType {
        case "public.utf8-plain-text", "public.text":
            if let text = String(data: item.content, encoding: .utf8) {
                pasteboard.setString(text, forType: .string)
            }
        default:
            pasteboard.setData(item.content, forType: NSPasteboard.PasteboardType(item.contentType))
        }
        
        // 更新访问时间
        item.lastAccessedAt = Date()
        CoreDataStack.shared.save()
    }
}

struct StarredItemsView: View {
    let searchText: String
    @EnvironmentObject private var clipboardManager: ClipboardManager
    @State private var sortOption: StarredSortOption = .dateAdded
    @State private var viewMode: ViewMode = .waterfall
    
    var displayItems: [ClipboardItem] {
        let items = clipboardManager.starredItems
        let filteredItems = searchText.isEmpty ? items : items.filter { item in
            item.contentPreview.localizedCaseInsensitiveContains(searchText) ||
            item.contentType.localizedCaseInsensitiveContains(searchText)
        }
        return sortItems(filteredItems)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 顶部控制栏
            if !displayItems.isEmpty {
                topControlBar
                    .padding(.horizontal, 12)
                    .padding(.bottom, 8)
            }
            
            // 主内容区域
            Group {
                if displayItems.isEmpty {
                    emptyStateView
                } else {
                    switch viewMode {
                    case .waterfall:
                        waterfallView
                    case .list:
                        listView
                    case .grid:
                        gridView
                    }
                }
            }
        }
        .refreshable {
            clipboardManager.refreshData()
        }
    }
    
    // MARK: - 顶部控制栏
    private var topControlBar: some View {
        HStack(spacing: 12) {
            // 排序选择器
            Menu {
                ForEach(StarredSortOption.allCases, id: \.self) { option in
                    Button(action: { sortOption = option }) {
                        HStack {
                            Text(option.displayName)
                            if sortOption == option {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.up.arrow.down")
                        .font(.caption)
                    Text(sortOption.displayName)
                        .font(.caption)
                }
                .foregroundColor(PaletclipColors.accentBlue)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(PaletclipColors.accentBlue.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            .menuStyle(.borderlessButton)
            
            Spacer()
            
            // 视图模式切换
            HStack(spacing: 2) {
                ForEach(ViewMode.allCases, id: \.self) { mode in
                    Button(action: { viewMode = mode }) {
                        Image(systemName: mode.iconName)
                            .font(.caption)
                            .foregroundColor(viewMode == mode ? .white : PaletclipColors.accentBlue)
                            .frame(width: 24, height: 24)
                            .background(viewMode == mode ? PaletclipColors.accentBlue : Color.clear)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(2)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 6))
        }
    }
    
    // MARK: - 空状态视图
    private var emptyStateView: some View {
        EmptyStateView(
            icon: "star.circle",
            title: searchText.isEmpty ? "暂无星标内容" : "未找到匹配结果",
            subtitle: searchText.isEmpty ? "点击项目右侧的星标按钮收藏重要内容" : "尝试其他搜索关键词"
        )
        .padding(.top, 50)
    }
    
    // MARK: - 瀑布流视图
    private var waterfallView: some View {
        ScrollView {
            ResponsiveWaterfallGrid(minItemWidth: 180, spacing: 12) {
                ForEach(displayItems, id: \.id) { item in
                    WaterfallCard {
                        StarredItemCard(item: item)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.top, 8)
        }
    }
    
    // MARK: - 列表视图
    private var listView: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(displayItems, id: \.id) { item in
                    ClipboardItemRow(item: item)
                }
            }
            .padding(.horizontal, 12)
            .padding(.top, 8)
        }
    }
    
    // MARK: - 网格视图
    private var gridView: some View {
        ScrollView {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 12) {
                ForEach(displayItems, id: \.id) { item in
                    StarredItemCard(item: item)
                        .aspectRatio(1.2, contentMode: .fit)
                }
            }
            .padding(.horizontal, 12)
            .padding(.top, 8)
        }
    }
    
    // MARK: - 辅助方法
    private func sortItems(_ items: [ClipboardItem]) -> [ClipboardItem] {
        switch sortOption {
        case .dateAdded:
            return items.sorted { $0.createdAt > $1.createdAt }
        case .lastAccessed:
            return items.sorted { $0.lastAccessedAt > $1.lastAccessedAt }
        case .contentType:
            return items.sorted { $0.contentType < $1.contentType }
        case .size:
            return items.sorted { $0.content.count > $1.content.count }
        }
    }
}

struct CustomFoldersView: View {
    let searchText: String
    @EnvironmentObject private var clipboardManager: ClipboardManager
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                if clipboardManager.folders.isEmpty {
                    EmptyStateView(
                        icon: "folder.circle",
                        title: "暂无文件夹",
                        subtitle: "创建文件夹来整理您的剪贴板内容"
                    )
                    .padding(.top, 50)
                } else {
                    ForEach(clipboardManager.folders, id: \.id) { folder in
                        FolderCard(folder: folder)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.top, 8)
        }
    }
}

// MARK: - 辅助视图组件

struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(PaletclipColors.placeholderText)
            
            VStack(spacing: 8) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(PaletclipColors.secondaryText)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(PaletclipColors.placeholderText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
        }
    }
}

struct ClipboardItemRow: View {
    let item: ClipboardItem
    
    var body: some View {
        ClipboardItemCard(item: item)
    }
}

struct FolderCard: View {
    let folder: Folder
    
    var body: some View {
        GlassCard(
            cornerRadius: 12,
            padding: EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16),
            shadowRadius: 8,
            shadowOffset: CGSize(width: 0, height: 2)
        ) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "folder.fill")
                        .foregroundColor(folder.themeColor)
                    
                    Text(folder.name)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(PaletclipColors.primaryText)
                    
                    Spacer()
                    
                    Text("\(folder.itemCount)")
                        .font(.caption2)
                        .foregroundColor(PaletclipColors.placeholderText)
                }
            }
        }
    }
}

// MARK: - 星标项目卡片
struct StarredItemCard: View {
    let item: ClipboardItem
    @State private var isHovered = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 内容预览
            contentPreview
            
            // 项目信息
            itemInfo
            
            // 底部操作栏
            if isHovered {
                bottomActions
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .padding(12)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(PaletclipColors.glassWhite.opacity(0.3), lineWidth: 0.5)
        )
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .shadow(
            color: Color.black.opacity(0.1),
            radius: isHovered ? 12 : 6,
            x: 0,
            y: isHovered ? 6 : 3
        )
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
        .onTapGesture {
            copyToPasteboard()
        }
    }
    
    private var contentPreview: some View {
        Group {
            switch item.contentType {
            case let type where type.hasPrefix("public.image"):
                if let thumbnailImage = item.thumbnailImage {
                    Image(nsImage: thumbnailImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 120)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(PaletclipColors.paintGreen.opacity(0.3))
                        .frame(height: 120)
                        .overlay(
                            Image(systemName: "photo.fill")
                                .font(.title)
                                .foregroundColor(PaletclipColors.paintGreen)
                        )
                }
                
            case "public.utf8-plain-text", "public.text":
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.contentPreview)
                        .font(.caption)
                        .lineLimit(4)
                        .foregroundColor(.primary)
                    
                    Spacer()
                }
                .frame(height: 80)
                .frame(maxWidth: .infinity, alignment: .leading)
                
            case "public.url":
                VStack(alignment: .leading, spacing: 8) {
                    Image(systemName: "link")
                        .font(.title2)
                        .foregroundColor(PaletclipColors.paintPurple)
                    
                    Text(item.contentPreview)
                        .font(.caption)
                        .lineLimit(3)
                        .foregroundColor(.primary)
                    
                    Spacer()
                }
                .frame(height: 80)
                .frame(maxWidth: .infinity, alignment: .leading)
                
            default:
                VStack {
                    Image(systemName: "doc.fill")
                        .font(.title)
                        .foregroundColor(.secondary)
                    
                    Text("未知格式")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(height: 80)
            }
        }
    }
    
    private var itemInfo: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: "star.fill")
                    .font(.caption2)
                    .foregroundColor(.yellow)
                
                Text(getTypeDescription())
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(formatDate(item.lastAccessedAt))
                    .font(.caption2)
                    .foregroundColor(Color.secondary)
            }
            
            // 颜色调色板（仅图片类型）
            if item.contentType.hasPrefix("public.image"),
               let colors = item.decodedColorPalette, !colors.isEmpty {
                HStack(spacing: 2) {
                    ForEach(colors.prefix(5), id: \.hexValue) { colorInfo in
                        Circle()
                            .fill(Color(hex: colorInfo.hexValue) ?? .gray)
                            .frame(width: 8, height: 8)
                    }
                    Spacer()
                }
            }
        }
    }
    
    private var bottomActions: some View {
        HStack(spacing: 8) {
            Button("复制") {
                copyToPasteboard()
            }
            .font(.caption2)
            .foregroundColor(PaletclipColors.accentBlue)
            
            Spacer()
            
            Button("取消星标") {
                toggleStar()
            }
            .font(.caption2)
            .foregroundColor(.orange)
        }
    }
    
    private func getTypeDescription() -> String {
        switch item.contentType {
        case "public.utf8-plain-text", "public.text":
            return "文本"
        case let type where type.hasPrefix("public.image"):
            return "图片"
        case "public.url":
            return "链接"
        default:
            return "文件"
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
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
}

// MARK: - 排序选项
enum StarredSortOption: CaseIterable {
    case dateAdded, lastAccessed, contentType, size
    
    var displayName: String {
        switch self {
        case .dateAdded: return "添加时间"
        case .lastAccessed: return "访问时间"
        case .contentType: return "内容类型"
        case .size: return "文件大小"
        }
    }
}

// MARK: - 视图模式
enum ViewMode: CaseIterable {
    case waterfall, list, grid
    
    var iconName: String {
        switch self {
        case .waterfall: return "rectangle.split.2x1"
        case .list: return "list.bullet"
        case .grid: return "square.grid.2x2"
        }
    }
}
