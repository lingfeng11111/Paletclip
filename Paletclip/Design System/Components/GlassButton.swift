//
//  GlassButton.swift
//  Paletclip
//
//  Created by 凌峰 on 2025/11/7.
//

import SwiftUI

// MARK: - 玻璃按钮样式
struct GlassButtonStyle: ButtonStyle {
    let cornerRadius: CGFloat
    let horizontalPadding: CGFloat
    let verticalPadding: CGFloat
    let accentColor: Color
    
    init(
        cornerRadius: CGFloat = 8,
        horizontalPadding: CGFloat = 16,
        verticalPadding: CGFloat = 8,
        accentColor: Color = PaletclipColors.accent
    ) {
        self.cornerRadius = cornerRadius
        self.horizontalPadding = horizontalPadding
        self.verticalPadding = verticalPadding
        self.accentColor = accentColor
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        accentColor.opacity(0.3),
                                        accentColor.opacity(0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
            .foregroundColor(PaletclipColors.adaptiveText)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .shadow(
                color: PaletclipColors.lightShadow,
                radius: configuration.isPressed ? 2 : 4,
                x: 0,
                y: configuration.isPressed ? 1 : 2
            )
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - 主要玻璃按钮样式
struct PrimaryGlassButtonStyle: ButtonStyle {
    let cornerRadius: CGFloat
    let horizontalPadding: CGFloat
    let verticalPadding: CGFloat
    
    init(
        cornerRadius: CGFloat = 8,
        horizontalPadding: CGFloat = 20,
        verticalPadding: CGFloat = 12
    ) {
        self.cornerRadius = cornerRadius
        self.horizontalPadding = horizontalPadding
        self.verticalPadding = verticalPadding
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .fontWeight(.medium)
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(
                        LinearGradient(
                            colors: [
                                PaletclipColors.accent.opacity(0.8),
                                PaletclipColors.accent.opacity(0.6)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(
                                PaletclipColors.accent.opacity(0.4),
                                lineWidth: 1
                            )
                    )
            )
            .foregroundColor(.white)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .shadow(
                color: PaletclipColors.accent.opacity(0.3),
                radius: configuration.isPressed ? 4 : 8,
                x: 0,
                y: configuration.isPressed ? 2 : 4
            )
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - 图标按钮样式
struct IconGlassButtonStyle: ButtonStyle {
    let size: CGFloat
    let accentColor: Color
    
    init(size: CGFloat = 32, accentColor: Color = PaletclipColors.accent) {
        self.size = size
        self.accentColor = accentColor
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(width: size, height: size)
            .background(
                Circle()
                    .fill(.ultraThinMaterial)
                    .overlay(
                        Circle()
                            .stroke(
                                accentColor.opacity(0.3),
                                lineWidth: 0.5
                            )
                    )
            )
            .foregroundColor(accentColor)
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .shadow(
                color: PaletclipColors.lightShadow,
                radius: configuration.isPressed ? 2 : 4,
                x: 0,
                y: configuration.isPressed ? 1 : 2
            )
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - 玻璃按钮组件
struct GlassButton: View {
    let title: String
    let icon: String?
    let action: () -> Void
    let style: GlassButtonVariant
    
    enum GlassButtonVariant {
        case secondary
        case primary
        case icon(size: CGFloat = 32)
        case compact
        case large
    }
    
    init(
        _ title: String,
        icon: String? = nil,
        style: GlassButtonVariant = .secondary,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.style = style
        self.action = action
    }
    
    var body: some View {
        let button = Button(action: action) {
            HStack(spacing: 6) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.caption)
                }
                
                if case .icon = style {
                    // 图标按钮只显示图标
                    if let icon = icon {
                        Image(systemName: icon)
                            .font(.system(size: 14))
                    }
                } else {
                    Text(title)
                        .font(fontForStyle)
                }
            }
        }
        
        switch style {
        case .secondary:
            button.buttonStyle(GlassButtonStyle())
        case .primary:
            button.buttonStyle(PrimaryGlassButtonStyle())
        case .icon(let size):
            button.buttonStyle(IconGlassButtonStyle(size: size))
        case .compact:
            button.buttonStyle(GlassButtonStyle(
                cornerRadius: 6,
                horizontalPadding: 12,
                verticalPadding: 6
            ))
        case .large:
            button.buttonStyle(GlassButtonStyle(
                cornerRadius: 12,
                horizontalPadding: 24,
                verticalPadding: 16
            ))
        }
    }
    
    private var fontForStyle: Font {
        switch style {
        case .compact:
            return .caption
        case .large:
            return .body
        case .primary:
            return .body
        default:
            return .caption
        }
    }
    
}

// MARK: - 切换按钮
struct GlassToggle: View {
    @Binding var isOn: Bool
    let title: String
    let icon: String?
    
    var body: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                isOn.toggle()
            }
        } label: {
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: icon)
                        .foregroundColor(isOn ? .white : PaletclipColors.adaptiveText)
                }
                
                Text(title)
                    .foregroundColor(isOn ? .white : PaletclipColors.adaptiveText)
            }
            .font(.caption)
            .fontWeight(.medium)
        }
        .buttonStyle(ToggleGlassButtonStyle(isOn: isOn))
    }
}

struct ToggleGlassButtonStyle: ButtonStyle {
    let isOn: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        isOn ? PaletclipColors.accentGradient : 
                        LinearGradient(colors: [.clear], startPoint: .top, endPoint: .bottom)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(.ultraThinMaterial)
                            .opacity(isOn ? 0 : 1)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(
                                isOn ? PaletclipColors.accent : PaletclipColors.primaryBorder,
                                lineWidth: isOn ? 1.5 : 0.5
                            )
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
            .animation(.easeInOut(duration: 0.2), value: isOn)
    }
}

// MARK: - 预览
#Preview {
    VStack(spacing: 20) {
        HStack(spacing: 12) {
            GlassButton("取消", style: .secondary) {}
            GlassButton("确定", style: .primary) {}
        }
        
        HStack(spacing: 12) {
            GlassButton("复制", icon: "doc.on.doc", style: .compact) {}
            GlassButton("星标收藏", icon: "star", style: .large) {}
        }
        
        HStack(spacing: 12) {
            GlassButton("", icon: "heart", style: .icon()) {}
            GlassButton("", icon: "trash", style: .icon(size: 28)) {}
        }
        
        GlassToggle(
            isOn: .constant(false),
            title: "自动清理",
            icon: "trash"
        )
        
        GlassToggle(
            isOn: .constant(true),
            title: "已启用",
            icon: "checkmark.circle"
        )
    }
    .padding()
    .background(Color.gray.opacity(0.1))
}
