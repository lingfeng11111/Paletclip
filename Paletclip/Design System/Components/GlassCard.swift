//
//  GlassCard.swift
//  Paletclip
//
//  Created by 凌峰 on 2025/11/7.
//

import SwiftUI

// MARK: - 玻璃卡片组件
struct GlassCard<Content: View>: View {
    let content: () -> Content
    let cornerRadius: CGFloat
    let padding: EdgeInsets
    let shadowRadius: CGFloat
    let shadowOffset: CGSize
    
    init(
        cornerRadius: CGFloat = 12,
        padding: EdgeInsets = EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16),
        shadowRadius: CGFloat = 8,
        shadowOffset: CGSize = CGSize(width: 0, height: 2),
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.content = content
        self.cornerRadius = cornerRadius
        self.padding = padding
        self.shadowRadius = shadowRadius
        self.shadowOffset = shadowOffset
    }
    
    var body: some View {
        content()
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(
                                PaletclipColors.glassGradient,
                                lineWidth: 0.5
                            )
                    )
            )
            .shadow(
                color: PaletclipColors.lightShadow,
                radius: shadowRadius,
                x: shadowOffset.width,
                y: shadowOffset.height
            )
            .shadow(
                color: PaletclipColors.deepShadow,
                radius: shadowRadius * 2.5,
                x: shadowOffset.width,
                y: shadowOffset.height * 4
            )
    }
}

// MARK: - 玻璃卡片预设样式常量
extension GlassCard {
    // 删除所有静态方法，避免泛型冲突
    // 使用直接构造器调用替代
}

// ColorSwatchCard 移动到 ColorSwatchView.swift 文件中

// MARK: - 预览
#Preview {
    VStack(spacing: 20) {
        GlassCard(
            cornerRadius: 12,
            padding: EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16),
            shadowRadius: 8,
            shadowOffset: CGSize(width: 0, height: 2)
        ) {
            VStack {
                Text("标准玻璃卡片")
                    .font(.headline)
                Text("这是一个带有玻璃质感的卡片组件")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        
        GlassCard(
            cornerRadius: 8,
            padding: EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12),
            shadowRadius: 4,
            shadowOffset: CGSize(width: 0, height: 1)
        ) {
            Text("紧凑样式")
                .font(.caption)
        }
        
        GlassCard(
            cornerRadius: 16,
            padding: EdgeInsets(top: 24, leading: 24, bottom: 24, trailing: 24),
            shadowRadius: 12,
            shadowOffset: CGSize(width: 0, height: 4)
        ) {
            VStack(spacing: 12) {
                Text("大尺寸样式")
                    .font(.title2)
                    .fontWeight(.semibold)
                Text("更大的内边距和阴影效果")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
        }
        
        // ColorSwatchCard 示例已移动到 ColorSwatchView.swift
    }
    .padding()
    .background(Color.gray.opacity(0.1))
}
