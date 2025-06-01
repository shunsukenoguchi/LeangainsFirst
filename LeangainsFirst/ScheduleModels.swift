//
//  ScheduleModels.swift
//  LeangainsFirst
//
//  Created by 野口隼輔 on 2025/06/01.
//

import Foundation

// MARK: - 基本データ構造

struct TimeOfDay: Codable, Equatable {
    let hour: Int      // 0-23
    let minute: Int    // 0-59
    
    init(hour: Int, minute: Int) {
        self.hour = max(0, min(23, hour))
        self.minute = max(0, min(59, minute))
    }
    
    init(from date: Date) {
        let calendar = Calendar.current
        self.hour = calendar.component(.hour, from: date)
        self.minute = calendar.component(.minute, from: date)
    }
    
    var timeString: String {
        return String(format: "%02d:%02d", hour, minute)
    }
    
    var totalMinutes: Int {
        return hour * 60 + minute
    }
    
    func toDate(on date: Date = Date()) -> Date {
        let calendar = Calendar.current
        return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: date) ?? date
    }
}

enum DayOfWeek: Int, CaseIterable, Codable {
    case sunday = 0, monday, tuesday, wednesday, thursday, friday, saturday
    
    var displayName: String {
        switch self {
        case .sunday: return "日曜日"
        case .monday: return "月曜日"
        case .tuesday: return "火曜日"
        case .wednesday: return "水曜日"
        case .thursday: return "木曜日"
        case .friday: return "金曜日"
        case .saturday: return "土曜日"
        }
    }
    
    var shortName: String {
        switch self {
        case .sunday: return "日"
        case .monday: return "月"
        case .tuesday: return "火"
        case .wednesday: return "水"
        case .thursday: return "木"
        case .friday: return "金"
        case .saturday: return "土"
        }
    }
    
    static var current: DayOfWeek {
        let weekday = Calendar.current.component(.weekday, from: Date())
        return DayOfWeek(rawValue: weekday - 1) ?? .sunday
    }
}

// MARK: - スケジュール構造

struct DailySchedule: Codable, Identifiable {
    let id = UUID()
    let dayOfWeek: DayOfWeek
    var fastingStartTime: TimeOfDay
    var fastingEndTime: TimeOfDay
    var isEnabled: Bool
    
    init(dayOfWeek: DayOfWeek, fastingStartTime: TimeOfDay, fastingEndTime: TimeOfDay, isEnabled: Bool = true) {
        self.dayOfWeek = dayOfWeek
        self.fastingStartTime = fastingStartTime
        self.fastingEndTime = fastingEndTime
        self.isEnabled = isEnabled
    }
    
    var fastingDurationHours: Double {
        let startMinutes = fastingStartTime.totalMinutes
        var endMinutes = fastingEndTime.totalMinutes
        
        // 翌日にまたがる場合の処理
        if endMinutes <= startMinutes {
            endMinutes += 24 * 60
        }
        
        return Double(endMinutes - startMinutes) / 60.0
    }
    
    var eatingDurationHours: Double {
        return 24.0 - fastingDurationHours
    }
    
    var fastingStartDate: Date {
        return fastingStartTime.toDate()
    }
    
    var fastingEndDate: Date {
        let baseDate = fastingStartTime.toDate()
        let endDate = fastingEndTime.toDate(on: baseDate)
        
        // 翌日にまたがる場合
        if fastingEndTime.totalMinutes <= fastingStartTime.totalMinutes {
            return Calendar.current.date(byAdding: .day, value: 1, to: endDate) ?? endDate
        }
        
        return endDate
    }
}

struct WeeklySchedulePattern: Codable, Identifiable {
    let id = UUID()
    var name: String
    var schedules: [DayOfWeek: DailySchedule]
    var isActive: Bool
    
    init(name: String, schedules: [DayOfWeek: DailySchedule] = [:], isActive: Bool = true) {
        self.name = name
        self.schedules = schedules
        self.isActive = isActive
        
        // デフォルトスケジュールを設定
        if schedules.isEmpty {
            self.schedules = Self.createDefaultSchedules()
        }
    }
    
    static func createDefaultSchedules() -> [DayOfWeek: DailySchedule] {
        var schedules: [DayOfWeek: DailySchedule] = [:]
        
        for day in DayOfWeek.allCases {
            let schedule = DailySchedule(
                dayOfWeek: day,
                fastingStartTime: TimeOfDay(hour: 20, minute: 0),
                fastingEndTime: TimeOfDay(hour: 12, minute: 0),
                isEnabled: true
            )
            schedules[day] = schedule
        }
        
        return schedules
    }
    
    var weeklyAverageFastingHours: Double {
        let enabledSchedules = schedules.values.filter { $0.isEnabled }
        guard !enabledSchedules.isEmpty else { return 0.0 }
        
        let totalHours = enabledSchedules.reduce(0.0) { $0 + $1.fastingDurationHours }
        return totalHours / Double(enabledSchedules.count)
    }
    
    func schedule(for day: DayOfWeek) -> DailySchedule? {
        return schedules[day]
    }
    
    func todaysSchedule() -> DailySchedule? {
        return schedule(for: DayOfWeek.current)
    }
}

// MARK: - スケジュール提案

struct ScheduleSuggestion: Identifiable {
    let id = UUID()
    let title: String
    let reason: String
    let confidence: Double // 0.0-1.0
    let adjustedSchedule: DailySchedule?
    
    init(title: String, reason: String, confidence: Double = 0.5, adjustedSchedule: DailySchedule? = nil) {
        self.title = title
        self.reason = reason
        self.confidence = max(0.0, min(1.0, confidence))
        self.adjustedSchedule = adjustedSchedule
    }
}

// MARK: - プリセットパターン

extension WeeklySchedulePattern {
    static var presetPatterns: [WeeklySchedulePattern] {
        return [
            standardPattern,
            weekdayIntensivePattern,
            weekendRelaxedPattern,
            flexiblePattern
        ]
    }
    
    static var standardPattern: WeeklySchedulePattern {
        return WeeklySchedulePattern(name: "標準パターン (16:8)")
    }
    
    static var weekdayIntensivePattern: WeeklySchedulePattern {
        var schedules: [DayOfWeek: DailySchedule] = [:]
        
        // 平日: 16時間断食
        for day in [DayOfWeek.monday, .tuesday, .wednesday, .thursday, .friday] {
            schedules[day] = DailySchedule(
                dayOfWeek: day,
                fastingStartTime: TimeOfDay(hour: 20, minute: 0),
                fastingEndTime: TimeOfDay(hour: 12, minute: 0)
            )
        }
        
        // 週末: 14時間断食
        schedules[.saturday] = DailySchedule(
            dayOfWeek: .saturday,
            fastingStartTime: TimeOfDay(hour: 21, minute: 0),
            fastingEndTime: TimeOfDay(hour: 11, minute: 0)
        )
        
        schedules[.sunday] = DailySchedule(
            dayOfWeek: .sunday,
            fastingStartTime: TimeOfDay(hour: 19, minute: 0),
            fastingEndTime: TimeOfDay(hour: 11, minute: 0)
        )
        
        return WeeklySchedulePattern(name: "平日集中型", schedules: schedules)
    }
    
    static var weekendRelaxedPattern: WeeklySchedulePattern {
        var schedules: [DayOfWeek: DailySchedule] = [:]
        
        // 平日: 14時間断食
        for day in [DayOfWeek.monday, .tuesday, .wednesday, .thursday, .friday] {
            schedules[day] = DailySchedule(
                dayOfWeek: day,
                fastingStartTime: TimeOfDay(hour: 21, minute: 0),
                fastingEndTime: TimeOfDay(hour: 11, minute: 0)
            )
        }
        
        // 週末: 12時間断食
        for day in [DayOfWeek.saturday, .sunday] {
            schedules[day] = DailySchedule(
                dayOfWeek: day,
                fastingStartTime: TimeOfDay(hour: 22, minute: 0),
                fastingEndTime: TimeOfDay(hour: 10, minute: 0)
            )
        }
        
        return WeeklySchedulePattern(name: "週末リラックス型", schedules: schedules)
    }
    
    static var flexiblePattern: WeeklySchedulePattern {
        var schedules: [DayOfWeek: DailySchedule] = [:]
        
        let times: [(start: (Int, Int), end: (Int, Int))] = [
            ((20, 0), (12, 0)),  // 月: 16h
            ((19, 30), (11, 30)), // 火: 16h
            ((20, 30), (12, 30)), // 水: 16h
            ((19, 0), (12, 0)),   // 木: 17h
            ((21, 0), (11, 0)),   // 金: 14h
            ((22, 0), (10, 0)),   // 土: 12h
            ((20, 0), (13, 0))    // 日: 17h
        ]
        
        for (index, day) in DayOfWeek.allCases.enumerated() {
            let (start, end) = times[index]
            schedules[day] = DailySchedule(
                dayOfWeek: day,
                fastingStartTime: TimeOfDay(hour: start.0, minute: start.1),
                fastingEndTime: TimeOfDay(hour: end.0, minute: end.1)
            )
        }
        
        return WeeklySchedulePattern(name: "フレキシブル型", schedules: schedules)
    }
} 