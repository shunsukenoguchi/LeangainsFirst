//
//  LeangainsFirstApp.swift
//  LeangainsFirst
//
//  Created by 野口隼輔 on 2025/06/01.
//

import SwiftUI

@main
struct LeangainsFirstApp: App {
    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
    }
}

struct MainTabView: View {
    var body: some View {
        TabView {
            FastingTimerView()
                .tabItem {
                    Image(systemName: "timer")
                    Text("タイマー")
                }
            
            ScheduleSettingsView()
                .tabItem {
                    Image(systemName: "calendar")
                    Text("スケジュール")
                }
        }
    }
}
