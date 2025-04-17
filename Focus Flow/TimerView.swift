//
//  TimerView.swift
//  Focus Flow
//
//  Created by Tobias Fu on 3/8/25.
//

import SwiftUI

struct TimerView: View {
    @ObservedObject var task: TaskEntity
    
    @State private var timeRemaining: Int = 0
    @State private var timerRunning = false
    @State private var currentPhase: TimerPhase = .focus
    @State private var timer: Timer? = nil
    @State private var showCompletionSheet = false
    
    enum TimerPhase { case focus, breakTime }
    
    var body: some View {
        VStack(spacing: 40) {
            Text(task.title ?? "No Title")
                .font(.title)
                .padding(.top)
            
            Text(formattedTime)
                .font(.system(size: 48, weight: .bold, design: .monospaced))
            
            HStack(spacing: 40) {
                Button {
                    if timerRunning {
                        pauseTimer()
                    } else {
                        startTimer()
                    }
                } label: {
                    Text(timerRunning ? "Pause" : "Start")
                        .font(.title2)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }

                Button {
                    stopTimer()
                    showCompletionSheet = true
                } label: {
                    Text("Stop")
                        .font(.title2)
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }

                Button {
                    // Additional settings
                } label: {
                    Text("Settings")
                        .font(.title2)
                        .padding()
                        .background(Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
            Spacer()
        }
        .padding()
        .onAppear(perform: initializeTimer)
        .sheet(isPresented: $showCompletionSheet) {
            // Show your BlockCompletionSheet or a simplified version
            BlockCompletionSheet(task: task, currentPhase: $currentPhase, onDismiss: { })
        }
        .onDisappear {
            timer?.invalidate()
        }
    }
    
    private func initializeTimer() {
        let duration = currentPhase == .focus ? task.blockMinutes : task.breakMinutes
        timeRemaining = Int(duration * 60)
    }
    
    private func startTimer() {
        timerRunning = true
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                pauseTimer()
                showCompletionSheet = true
            }
        }
    }
    
    private func pauseTimer() {
        timerRunning = false
        timer?.invalidate()
        timer = nil
    }
    
    private func stopTimer() {
        pauseTimer()
        timeRemaining = 0
    }
    
    private var formattedTime: String {
        String(format: "%02d:%02d", timeRemaining / 60, timeRemaining % 60)
    }
}
