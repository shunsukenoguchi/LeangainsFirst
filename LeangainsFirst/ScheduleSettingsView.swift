//
//  ScheduleSettingsView.swift
//  LeangainsFirst
//
//  Created by 野口隼輔 on 2025/06/01.
//

import SwiftUI

struct ScheduleSettingsView: View {
    @State private var weeklyPattern: WeeklySchedulePattern = .standardPattern
    @State private var selectedDay: DayOfWeek = .monday
    @State private var isEditingTime = false
    @State private var showingPatternPicker = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // パターン選択セクション
                    patternSelectionSection
                    
                    // 週間カレンダービュー
                    weeklyCalendarSection
                    
                    // 選択日の詳細設定
                    selectedDayDetailSection
                    
                    // クイック設定ボタン
                    quickSettingsSection
                }
                .padding()
            }
            .navigationTitle("スケジュール管理")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingPatternPicker) {
                PatternPickerView(selectedPattern: $weeklyPattern)
            }
        }
    }
    
    // MARK: - UI Sections
    
    private var patternSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("現在のパターン")
                .font(.headline)
                .foregroundColor(.primary)
            
            Button(action: {
                showingPatternPicker = true
            }) {
                HStack {
                    VStack(alignment: .leading) {
                        Text(weeklyPattern.name)
                            .font(.title3)
                            .fontWeight(.medium)
                        Text("週平均: \(String(format: "%.1f", weeklyPattern.weeklyAverageFastingHours))時間")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    private var weeklyCalendarSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("今週のスケジュール")
                .font(.headline)
                .foregroundColor(.primary)
            
            WeeklyCalendarView(
                pattern: $weeklyPattern,
                selectedDay: $selectedDay
            )
        }
    }
    
    private var selectedDayDetailSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("\(selectedDay.displayName)の詳細")
                .font(.headline)
                .foregroundColor(.primary)
            
            if let schedule = weeklyPattern.schedule(for: selectedDay) {
                DayDetailView(
                    schedule: binding(for: selectedDay),
                    onScheduleChange: { updatedSchedule in
                        weeklyPattern.schedules[selectedDay] = updatedSchedule
                    }
                )
            }
        }
    }
    
    private var quickSettingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("クイック設定")
                .font(.headline)
                .foregroundColor(.primary)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                QuickSettingButton(
                    title: "全日コピー",
                    subtitle: "選択日を全日に適用",
                    icon: "doc.on.doc"
                ) {
                    copySelectedDayToAll()
                }
                
                QuickSettingButton(
                    title: "平日設定",
                    subtitle: "平日を統一設定",
                    icon: "calendar.badge.clock"
                ) {
                    setWeekdaySchedule()
                }
                
                QuickSettingButton(
                    title: "週末設定",
                    subtitle: "週末を統一設定",
                    icon: "moon.zzz"
                ) {
                    setWeekendSchedule()
                }
                
                QuickSettingButton(
                    title: "リセット",
                    subtitle: "デフォルトに戻す",
                    icon: "arrow.clockwise"
                ) {
                    resetToDefault()
                }
            }
        }
    }
    
    // MARK: - Helper Functions
    
    private func binding(for day: DayOfWeek) -> Binding<DailySchedule> {
        return Binding(
            get: {
                weeklyPattern.schedule(for: day) ?? DailySchedule(
                    dayOfWeek: day,
                    fastingStartTime: TimeOfDay(hour: 20, minute: 0),
                    fastingEndTime: TimeOfDay(hour: 12, minute: 0)
                )
            },
            set: { newSchedule in
                weeklyPattern.schedules[day] = newSchedule
            }
        )
    }
    
    private func copySelectedDayToAll() {
        guard let selectedSchedule = weeklyPattern.schedule(for: selectedDay) else { return }
        
        for day in DayOfWeek.allCases {
            var newSchedule = selectedSchedule
            newSchedule = DailySchedule(
                dayOfWeek: day,
                fastingStartTime: selectedSchedule.fastingStartTime,
                fastingEndTime: selectedSchedule.fastingEndTime,
                isEnabled: selectedSchedule.isEnabled
            )
            weeklyPattern.schedules[day] = newSchedule
        }
    }
    
    private func setWeekdaySchedule() {
        let weekdays: [DayOfWeek] = [.monday, .tuesday, .wednesday, .thursday, .friday]
        let weekdaySchedule = DailySchedule(
            dayOfWeek: .monday,
            fastingStartTime: TimeOfDay(hour: 20, minute: 0),
            fastingEndTime: TimeOfDay(hour: 12, minute: 0)
        )
        
        for day in weekdays {
            var schedule = weekdaySchedule
            schedule = DailySchedule(
                dayOfWeek: day,
                fastingStartTime: weekdaySchedule.fastingStartTime,
                fastingEndTime: weekdaySchedule.fastingEndTime,
                isEnabled: weekdaySchedule.isEnabled
            )
            weeklyPattern.schedules[day] = schedule
        }
    }
    
    private func setWeekendSchedule() {
        let weekends: [DayOfWeek] = [.saturday, .sunday]
        let weekendSchedule = DailySchedule(
            dayOfWeek: .saturday,
            fastingStartTime: TimeOfDay(hour: 21, minute: 0),
            fastingEndTime: TimeOfDay(hour: 11, minute: 0)
        )
        
        for day in weekends {
            var schedule = weekendSchedule
            schedule = DailySchedule(
                dayOfWeek: day,
                fastingStartTime: weekendSchedule.fastingStartTime,
                fastingEndTime: weekendSchedule.fastingEndTime,
                isEnabled: weekendSchedule.isEnabled
            )
            weeklyPattern.schedules[day] = schedule
        }
    }
    
    private func resetToDefault() {
        weeklyPattern = .standardPattern
    }
}

// MARK: - Supporting Views

struct QuickSettingButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.blue)
                
                VStack(spacing: 2) {
                    Text(title)
                        .font(.caption)
                        .fontWeight(.medium)
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .frame(height: 80)
            .frame(maxWidth: .infinity)
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct PatternPickerView: View {
    @Binding var selectedPattern: WeeklySchedulePattern
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            List(WeeklySchedulePattern.presetPatterns, id: \.id) { pattern in
                Button(action: {
                    selectedPattern = pattern
                    presentationMode.wrappedValue.dismiss()
                }) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(pattern.name)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text("平均 \(String(format: "%.1f", pattern.weeklyAverageFastingHours))時間/日")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .navigationTitle("パターン選択")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("キャンセル") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

#Preview {
    ScheduleSettingsView()
} 