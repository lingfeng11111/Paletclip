//
//  WaterfallLayout.swift
//  Paletclip
//
//  Created by 凌峰 on 2025/11/7.
//

import SwiftUI

// MARK: - 瀑布流布局
@available(macOS 13.0, *)
struct WaterfallLayout: Layout {
    let columns: Int
    let spacing: CGFloat
    let alignment: HorizontalAlignment
    
    init(columns: Int = 2, spacing: CGFloat = 12, alignment: HorizontalAlignment = .center) {
        self.columns = max(1, columns) // 至少要有1列
        self.spacing = spacing
        self.alignment = alignment
    }
    
    // MARK: - Layout Protocol 实现
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout CacheData) -> CGSize {
        guard !subviews.isEmpty else { return .zero }
        
        let width = proposal.width ?? 400
        let columnWidth = (width - CGFloat(columns - 1) * spacing) / CGFloat(columns)
        
        // 计算每列的高度
        var columnHeights = Array(repeating: 0.0, count: columns)
        
        for subview in subviews {
            let subviewSize = subview.sizeThatFits(ProposedViewSize(width: columnWidth, height: nil))
            let shortestColumnIndex = columnHeights.enumerated().min(by: { $0.element < $1.element })!.offset
            columnHeights[shortestColumnIndex] += subviewSize.height + spacing
        }
        
        // 移除最后一行的间距
        for i in 0..<columnHeights.count {
            columnHeights[i] = max(0, columnHeights[i] - spacing)
        }
        
        let totalHeight = columnHeights.max() ?? 0
        return CGSize(width: width, height: totalHeight)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout CacheData) {
        guard !subviews.isEmpty else { return }
        
        let columnWidth = (bounds.width - CGFloat(columns - 1) * spacing) / CGFloat(columns)
        var columnHeights = Array(repeating: bounds.minY, count: columns)
        
        for subview in subviews {
            // 找到最短的列
            let shortestColumnIndex = columnHeights.enumerated().min(by: { $0.element < $1.element })!.offset
            
            // 计算位置
            let x = bounds.minX + CGFloat(shortestColumnIndex) * (columnWidth + spacing)
            let y = columnHeights[shortestColumnIndex]
            
            // 获取子视图大小
            let subviewSize = subview.sizeThatFits(ProposedViewSize(width: columnWidth, height: nil))
            
            // 根据对齐方式调整 x 位置
            let adjustedX: CGFloat
            switch alignment {
            case .leading:
                adjustedX = x
            case .trailing:
                adjustedX = x + columnWidth - subviewSize.width
            default: // .center
                adjustedX = x + (columnWidth - subviewSize.width) / 2
            }
            
            // 放置子视图
            subview.place(
                at: CGPoint(x: adjustedX, y: y),
                proposal: ProposedViewSize(width: columnWidth, height: subviewSize.height)
            )
            
            // 更新列高度
            columnHeights[shortestColumnIndex] += subviewSize.height + spacing
        }
    }
    
    // MARK: - 缓存类型
    struct CacheData {
        var columnHeights: [CGFloat] = []
        var itemPositions: [CGPoint] = []
    }
    
    func makeCache(subviews: Subviews) -> CacheData {
        return CacheData()
    }
}

// MARK: - 瀑布流容器视图
struct WaterfallGrid<Content: View>: View {
    let columns: Int
    let spacing: CGFloat
    let alignment: HorizontalAlignment
    let content: Content
    
    init(
        columns: Int = 2,
        spacing: CGFloat = 12,
        alignment: HorizontalAlignment = .center,
        @ViewBuilder content: () -> Content
    ) {
        self.columns = columns
        self.spacing = spacing
        self.alignment = alignment
        self.content = content()
    }
    
    var body: some View {
        if #available(macOS 13.0, *) {
            WaterfallLayout(columns: columns, spacing: spacing, alignment: alignment) {
                content
            }
        } else {
            // 降级方案：使用 LazyVGrid
            let gridColumns = Array(repeating: GridItem(.flexible(), spacing: spacing), count: columns)
            LazyVGrid(columns: gridColumns, spacing: spacing) {
                content
            }
        }
    }
}

// MARK: - 响应式瀑布流
struct ResponsiveWaterfallGrid<Content: View>: View {
    let minItemWidth: CGFloat
    let spacing: CGFloat
    let alignment: HorizontalAlignment
    let content: Content
    
    @State private var containerWidth: CGFloat = 0
    
    private var adaptiveColumns: Int {
        guard containerWidth > 0 else { return 2 }
        let availableWidth = containerWidth - spacing
        let itemWidthWithSpacing = minItemWidth + spacing
        return max(1, Int(availableWidth / itemWidthWithSpacing))
    }
    
    init(
        minItemWidth: CGFloat = 200,
        spacing: CGFloat = 12,
        alignment: HorizontalAlignment = .center,
        @ViewBuilder content: () -> Content
    ) {
        self.minItemWidth = minItemWidth
        self.spacing = spacing
        self.alignment = alignment
        self.content = content()
    }
    
    var body: some View {
        WaterfallGrid(
            columns: adaptiveColumns,
            spacing: spacing,
            alignment: alignment
        ) {
            content
        }
        .background(
            GeometryReader { geometry in
                Color.clear
                    .onAppear {
                        containerWidth = geometry.size.width
                    }
                    .onChange(of: geometry.size.width) { _, newWidth in
                        containerWidth = newWidth
                    }
            }
        )
    }
}

// MARK: - 瀑布流动画容器
struct AnimatedWaterfallGrid<Content: View>: View {
    let columns: Int
    let spacing: CGFloat
    let alignment: HorizontalAlignment
    let animation: Animation
    let content: Content
    
    init(
        columns: Int = 2,
        spacing: CGFloat = 12,
        alignment: HorizontalAlignment = .center,
        animation: Animation = .spring(response: 0.6, dampingFraction: 0.8),
        @ViewBuilder content: () -> Content
    ) {
        self.columns = columns
        self.spacing = spacing
        self.alignment = alignment
        self.animation = animation
        self.content = content()
    }
    
    var body: some View {
        WaterfallGrid(
            columns: columns,
            spacing: spacing,
            alignment: alignment
        ) {
            content
        }
        .animation(animation, value: columns)
    }
}

// MARK: - 瀑布流卡片包装器
struct WaterfallCard<Content: View>: View {
    let content: Content
    @State private var isVisible = false
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .opacity(isVisible ? 1 : 0)
            .scaleEffect(isVisible ? 1 : 0.8)
            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: isVisible)
            .onAppear {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(Double.random(in: 0...0.3))) {
                    isVisible = true
                }
            }
    }
}

// MARK: - 瀑布流项目协议
protocol WaterfallItem: Identifiable {
    var aspectRatio: CGFloat { get }
}

// MARK: - 瀑布流性能优化视图
struct VirtualizedWaterfallGrid<Item: WaterfallItem, Content: View>: View {
    let items: [Item]
    let columns: Int
    let spacing: CGFloat
    let itemContent: (Item) -> Content
    
    @State private var visibleRange: Range<Int> = 0..<0
    @State private var containerHeight: CGFloat = 0
    @State private var scrollOffset: CGFloat = 0
    
    init(
        items: [Item],
        columns: Int = 2,
        spacing: CGFloat = 12,
        @ViewBuilder itemContent: @escaping (Item) -> Content
    ) {
        self.items = items
        self.columns = columns
        self.spacing = spacing
        self.itemContent = itemContent
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                WaterfallGrid(columns: columns, spacing: spacing) {
                    ForEach(items) { item in
                        itemContent(item)
                            .id(item.id)
                    }
                }
            }
        }
        .background(
            GeometryReader { geometry in
                Color.clear
                    .onAppear {
                        containerHeight = geometry.size.height
                    }
                    .onChange(of: geometry.size.height) { _, newHeight in
                        containerHeight = newHeight
                    }
            }
        )
    }
}

// MARK: - 示例用法和预览
struct WaterfallExampleItem: WaterfallItem {
    let id = UUID()
    let title: String
    let color: Color
    let height: CGFloat
    
    var aspectRatio: CGFloat {
        return 200 / height
    }
}

#Preview {
    let sampleItems = [
        WaterfallExampleItem(title: "Item 1", color: .red, height: 120),
        WaterfallExampleItem(title: "Item 2", color: .blue, height: 200),
        WaterfallExampleItem(title: "Item 3", color: .green, height: 80),
        WaterfallExampleItem(title: "Item 4", color: .orange, height: 160),
        WaterfallExampleItem(title: "Item 5", color: .purple, height: 100),
        WaterfallExampleItem(title: "Item 6", color: .pink, height: 180),
        WaterfallExampleItem(title: "Item 7", color: .cyan, height: 140),
        WaterfallExampleItem(title: "Item 8", color: .yellow, height: 90),
    ]
    
    return ScrollView {
        VStack(spacing: 20) {
            Text("瀑布流布局示例")
                .font(.title)
                .padding()
            
            ResponsiveWaterfallGrid(minItemWidth: 150, spacing: 16) {
                ForEach(sampleItems) { item in
                    WaterfallCard {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(item.color.gradient)
                            .frame(height: item.height)
                            .overlay(
                                Text(item.title)
                                    .foregroundColor(.white)
                                    .fontWeight(.semibold)
                            )
                            .shadow(radius: 4)
                    }
                }
            }
            .padding()
        }
    }
    .background(.ultraThinMaterial)
}
