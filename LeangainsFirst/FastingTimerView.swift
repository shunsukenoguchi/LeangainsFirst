//
//  FastingTimerView.swift
//  LeangainsFirst
//
//  Created by 野口隼輔 on 2025/06/01.
//

import SwiftUI

struct FastingTimerView: View {
    // 断食設定
    @State private var fastingHours: Double = 16 // デフォルト16時間
    @State private var isTimerActive = false
    @State private var isFasting = true
    @State private var startTime: Date?
    @State private var timeRemaining: TimeInterval = 16 * 3600
    
    // タイマー更新用
    @State private var timer: Timer?
    
    var eatingHours: Int {
        return 24 - Int(fastingHours)
    }
    
    var body: some View {
        VStack(spacing: 30) {
            // タイトル
            Text("リーンゲインズタイマー")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            // 断食時間設定
            VStack(spacing: 10) {
                Text("断食時間: \(Int(fastingHours))時間")
                    .font(.headline)
                Text("食事時間: \(eatingHours)時間")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack {
                    Text("12h")
                    Slider(value: $fastingHours, in: 12...16, step: 1) {
                        Text("断食時間")
                    }
                    .disabled(isTimerActive)
                    Text("16h")
                }
                .padding(.horizontal)
            }
            
            // メインタイマー表示
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 12)
                    .frame(width: 250, height: 250)
                
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        isFasting ? Color.orange : Color.green,
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .frame(width: 250, height: 250)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 0.5), value: progress)
                
                VStack(spacing: 8) {
                    Text(formatTime(timeRemaining))
                        .font(.system(size: 32, weight: .bold, design: .monospaced))
                    
                    Text(isFasting ? "断食中 🚫" : "食事OK 🍽️")
                        .font(.headline)
                        .foregroundColor(isFasting ? .orange : .green)
                    
                    if let nextTime = getNextSwitchTime() {
                        Text("次回: \(formatNextTime(nextTime))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // 制御ボタン
            HStack(spacing: 20) {
                Button(action: {
                    if isTimerActive {
                        stopTimer()
                    } else {
                        startTimer()
                    }
                }) {
                    Text(isTimerActive ? "停止" : "開始")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(width: 80, height: 40)
                        .background(isTimerActive ? Color.red : Color.blue)
                        .cornerRadius(10)
                }
                
                Button(action: resetTimer) {
                    Text("リセット")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(width: 80, height: 40)
                        .background(Color.gray)
                        .cornerRadius(10)
                }
                .disabled(!isTimerActive && startTime == nil)
            }
            
            Spacer()
        }
        .padding()
        .onAppear {
            resetTimer()
        }
    }
    
    // MARK: - Timer Functions
    
    private func startTimer() {
        isTimerActive = true
        if startTime == nil {
            startTime = Date()
        }
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            updateTimer()
        }
    }
    
    private func stopTimer() {
        isTimerActive = false
        timer?.invalidate()
        timer = nil
    }
    
    private func resetTimer() {
        stopTimer()
        startTime = nil
        isFasting = true
        timeRemaining = fastingHours * 3600
    }
    
    private func updateTimer() {
        guard let startTime = startTime else { return }
        
        let elapsed = Date().timeIntervalSince(startTime)
        let totalCycleTime = 24 * 3600.0 // 24時間
        let fastingTime = fastingHours * 3600.0
        
        let cycleElapsed = elapsed.truncatingRemainder(dividingBy: totalCycleTime)
        
        if cycleElapsed < fastingTime {
            // 断食中
            isFasting = true
            timeRemaining = fastingTime - cycleElapsed
        } else {
            // 食事期間
            isFasting = false
            timeRemaining = totalCycleTime - cycleElapsed
        }
        
        if timeRemaining <= 0 {
            timeRemaining = 0
        }
    }
    
    // MARK: - Helper Functions
    
    private var progress: Double {
        let totalTime = isFasting ? fastingHours * 3600 : Double(eatingHours) * 3600
        let elapsed = totalTime - timeRemaining
        return min(elapsed / totalTime, 1.0)
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let hours = Int(time) / 3600
        let minutes = Int(time) % 3600 / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
    
    private func getNextSwitchTime() -> Date? {
        guard let startTime = startTime else { return nil }
        
        let elapsed = Date().timeIntervalSince(startTime)
        let totalCycleTime = 24 * 3600.0
        let fastingTime = fastingHours * 3600.0
        
        let cycleElapsed = elapsed.truncatingRemainder(dividingBy: totalCycleTime)
        
        if cycleElapsed < fastingTime {
            // 断食中 → 食事開始時刻
            return startTime.addingTimeInterval(elapsed - cycleElapsed + fastingTime)
        } else {
            // 食事中 → 次の断食開始時刻
            return startTime.addingTimeInterval(elapsed - cycleElapsed + totalCycleTime)
        }
    }
    
    private func formatNextTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

#Preview {
    FastingTimerView()
}
