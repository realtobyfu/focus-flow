//
//  TimerView.swift
//  Focus Flow
//
//  Created by Tobias Fu on 3/8/25.
//

import Foundation
import SwiftUI

struct TimerView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @ObservedObject var task: TaskEntity  // The task from the list
    
    // Timer states
    @State private var timeRemaining: Int = 0
    @State private var timerRunning = false
    @State private var currentPhase: TimerPhase = .focus  // focus or break
    
    // We'll store a reference to the Timer
    @State private var timer: Timer? = nil
    
    // When a block ends or is stopped, show a sheet that lets user set % completed
    @State private var showCompletionSheet = false
    
    enum TimerPhase {
        case focus, breakTime
    }
    
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
                    // If user stops mid-block, we also ask for progress
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
                    // Additional or advanced settings
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
        .onAppear {
            initializeTimer()
        }
        // Show a custom sheet for completion updates
        .sheet(isPresented: $showCompletionSheet) {
            BlockCompletionSheet(task: task,
                                currentPhase: $currentPhase,
                                onDismiss: {
                // optional callback
                // maybe you want to auto-start the next phase or do nothing
            })
        }
        .onDisappear {
            // Invalidate if user goes back
            timer?.invalidate()
        }
    }
    
    // MARK: - Timer Logic
    
    private func initializeTimer() {
        // focus vs break time
        let duration = currentPhase == .focus ? task.blockMinutes : task.breakMinutes
        timeRemaining = Int(duration * 60)
    }
    
    private func startTimer() {
        timerRunning = true
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                // Time up: show completion sheet
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
        let minutes = timeRemaining / 60
        let seconds = timeRemaining % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
