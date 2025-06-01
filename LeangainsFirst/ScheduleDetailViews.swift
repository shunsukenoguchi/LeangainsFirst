//
//  ScheduleDetailViews.swift
//  LeangainsFirst
//
//  Created by 野口隼輔 on 2025/06/01.
//

import SwiftUI

// MARK: - 週間カレンダービュー

struct WeeklyCalendarView: View {
    @Binding var pattern: WeeklySchedulePattern
    @Binding var selectedDay: DayOfWeek
    
    var body: some View {
        VStack(spacing: 12) {
            // 曜日ヘッダー
            HStack {
                ForEach(DayOfWeek.allCases, id: \.self) { day in
                    Text(day.shortName)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            
            // 断食時間バー
            HStack(spacing: 4) {
                ForEach(DayOfWeek.allCases, id: \.self) { day in
                    DayProgressBar(
                        day: day,
                        schedule: pattern.schedule(for: day),
                        isSelected: selectedDay == day
                    )
                    .onTapGesture {
                        selectedDay = day
                    }
                }
            }
            
            // 時間表示
            HStack {
                ForEach(DayOfWeek.allCases, id: \.self) { day in
                    VStack(spacing: 2) {
                        if let schedule = pattern.schedule(for: day), schedule.isEnabled {
                            Text("\(Int(schedule.fastingDurationHours))h")
                                .font(.caption2)
                                .fontWeight(.medium)
                            Text(schedule.fastingStartTime.timeString)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        } else {
                            Text("OFF")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct DayProgressBar: View {
    let day: DayOfWeek
    let schedule: DailySchedule?
    let isSelected: Bool
    
    var body: some View {
        VStack(spacing: 4) {
            // プログレスバー
            RoundedRectangle(cornerRadius: 4)
                .fill(progressColor)
                .frame(height: progressHeight)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
                )
            
            // 有効/無効インジケーター
            Circle()
                .fill(schedule?.isEnabled == true ? Color.green : Color.gray)
                .frame(width: 6, height: 6)
        }
        .frame(maxWidth: .infinity)
    }
    
    private var progressColor: Color {
        guard let schedule = schedule, schedule.isEnabled else {
            return Color.gray.opacity(0.3)
        }
        
        let hours = schedule.fastingDurationHours
        if hours >= 16 {
            return Color.orange
        } else if hours >= 14 {
            return Color.yellow
        } else {
            return Color.green
        }
    }
    
    private var progressHeight: CGFloat {
        guard let schedule = schedule, schedule.isEnabled else {
            return 20
        }
        
        let minHeight: CGFloat = 20
        let maxHeight: CGFloat = 60
        let hours = schedule.fastingDurationHours
        let normalizedHeight = CGFloat(hours / 24.0) * (maxHeight - minHeight) + minHeight
        
        return normalizedHeight
    }
}

// MARK: - 日別詳細設定ビュー

struct DayDetailView: View {
    @Binding var schedule: DailySchedule
    let onScheduleChange: (DailySchedule) -> Void
    
    @State private var isEditingStartTime = false
    @State private var isEditingEndTime = false
    @State private var tempStartTime: Date = Date()
    @State private var tempEndTime: Date = Date()
    
    var body: some View {
        VStack(spacing: 16) {
            // 有効/無効スイッチ
            HStack {
                Text("このスケジュールを有効にする")
                    .font(.subheadline)
                Spacer()
                Toggle("", isOn: Binding(
                    get: { schedule.isEnabled },
                    set: { newValue in
                        var updatedSchedule = schedule
                        updatedSchedule.isEnabled = newValue
                        schedule = updatedSchedule
                        onScheduleChange(updatedSchedule)
                    }
                ))
            }
            
            if schedule.isEnabled {
                // 断食開始時間
                timeSettingRow(
                    title: "断食開始",
                    time: schedule.fastingStartTime,
                    isEditing: $isEditingStartTime,
                    tempTime: $tempStartTime
                ) { newTime in
                    updateStartTime(newTime)
                }
                
                // 断食終了時間
                timeSettingRow(
                    title: "断食終了",
                    time: schedule.fastingEndTime,
                    isEditing: $isEditingEndTime,
                    tempTime: $tempEndTime
                ) { newTime in
                    updateEndTime(newTime)
                }
                
                // 時間情報表示
                scheduleInfoSection
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .onAppear {
            tempStartTime = schedule.fastingStartTime.toDate()
            tempEndTime = schedule.fastingEndTime.toDate()
        }
    }
    
    private func timeSettingRow(
        title: String,
        time: TimeOfDay,
        isEditing: Binding<Bool>,
        tempTime: Binding<Date>,
        onTimeChange: @escaping (TimeOfDay) -> Void
    ) -> some View {
        VStack {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
                Button(time.timeString) {
                    isEditing.wrappedValue = true
                }
                .foregroundColor(.blue)
            }
            
            if isEditing.wrappedValue {
                DatePicker(
                    "",
                    selection: tempTime,
                    displayedComponents: .hourAndMinute
                )
                .datePickerStyle(WheelDatePickerStyle())
                .labelsHidden()
                
                HStack {
                    Button("キャンセル") {
                        isEditing.wrappedValue = false
                    }
                    .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Button("完了") {
                        onTimeChange(TimeOfDay(from: tempTime.wrappedValue))
                        isEditing.wrappedValue = false
                    }
                    .foregroundColor(.blue)
                    .fontWeight(.medium)
                }
                .padding(.top, 8)
            }
        }
    }
    
    private var scheduleInfoSection: some View {
        VStack(spacing: 8) {
            Divider()
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("断食時間")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(String(format: "%.1f", schedule.fastingDurationHours))時間")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("食事時間")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(String(format: "%.1f", schedule.eatingDurationHours))時間")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
            }
        }
    }
    
    private func updateStartTime(_ newTime: TimeOfDay) {
        var updatedSchedule = schedule
        updatedSchedule.fastingStartTime = newTime
        schedule = updatedSchedule
        onScheduleChange(updatedSchedule)
    }
    
    private func updateEndTime(_ newTime: TimeOfDay) {
        var updatedSchedule = schedule
        updatedSchedule.fastingEndTime = newTime
        schedule = updatedSchedule
        onScheduleChange(updatedSchedule)
    }
}

#Preview {
    VStack {
        WeeklyCalendarView(
            pattern: .constant(.standardPattern),
            selectedDay: .constant(.monday)
        )
        
        DayDetailView(
            schedule: .constant(DailySchedule(
                dayOfWeek: .monday,
                fastingStartTime: TimeOfDay(hour: 20, minute: 0),
                fastingEndTime: TimeOfDay(hour: 12, minute: 0)
            )),
            onScheduleChange: { _ in }
        )
    }
    .padding()
} 