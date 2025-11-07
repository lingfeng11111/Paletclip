//
//  PaletclipApp.swift
//  Paletclip
//
//  Created by 凌峰 on 2025/11/7.
//

import SwiftUI

@main
struct PaletclipApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            EmptyView() // 隐藏主窗口，使用状态栏界面
        }
    }
}
