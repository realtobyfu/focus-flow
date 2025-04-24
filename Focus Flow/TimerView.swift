//
//  TimerView.swift
//  Focus Flow
//
//  Created by Tobias Fu on 3/8/25.
//
import SwiftUI

struct TimerView: View {
    @ObservedObject var task: TaskEntity
    @Environment(\.presentationMode) var presentationMode
    
    @State private var timeRemaining: Int = 0
    @State private var timerRunning = false
    @State private var currentPhase: TimerPhase = .focus
    @State private var timer: Timer? = nil
    @State private var showCompletionSheet = false
    
    enum TimerPhase { case focus, breakTime }
    
    var body: some View {
        ZStack {
            // Purple background from your design
            Color(#colorLiteral(red: 0.6, green: 0.2, blue: 0.8, alpha: 1.0))
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 30) {
                // Title
                Text(task.title ?? "No Title")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.top, 40)
                
                // Timer display
                ZStack {
                    // Background timer circle
                    HStack(spacing: 4) {
                        Text("\(timeRemaining / 60)")
                            .font(.system(size: 54, weight: .bold))
                        
                        Text(":")
                            .font(.system(size: 54, weight: .bold))
                        
                        Text(String(format: "%02d", timeRemaining % 60))
                            .font(.system(size: 54, weight: .bold))
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.white)
                    .foregroundColor(.black)
                    
                    // Timer progress circle (drawn below)
                    CircularTimer(progress: calculateProgress())
                        .frame(width: 240, height: 240)
                }
                .padding(.top, 40)
                
                Spacer()
                
                // Control buttons
                HStack(spacing: 40) {
                    // Stop button
                    Button(action: {
                        stopTimer()
                        showCompletionSheet = true
                    }) {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 60, height: 60)
                            .overlay(
                                Image(systemName: "stop.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(.white)
                            )
                    }
                    
                    // Play/Pause button
                    Button(action: {
                        if timerRunning {
                            pauseTimer()
                        } else {
                            startTimer()
                        }
                    }) {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 60, height: 60)
                            .overlay(
                                Image(systemName: timerRunning ? "pause.fill" : "play.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(.white)
                            )
                    }
                    
                    // Settings button
                    Button(action: {}) {
                        Circle()
                            .fill(Color.black)
                            .frame(width: 60, height: 60)
                            .overlay(
                                Image(systemName: "gearshape.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(.white)
                            )
                    }
                }
                .padding(.bottom, 60)
            }
        }
        .onAppear(perform: initializeTimer)
        .sheet(isPresented: $showCompletionSheet) {
            BlockCompletionSheet(task: task, currentPhase: $currentPhase, onDismiss: {})
        }
        .onDisappear {
            timer?.invalidate()
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(leading: Button(action: {
            presentationMode.wrappedValue.dismiss()
        }) {
            Image(systemName: "chevron.left")
                .foregroundColor(.white)
                .font(.system(size: 22, weight: .bold))
        })
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
    
    private func calculateProgress() -> Double {
        let total = currentPhase == .focus ? task.blockMinutes * 60 : task.breakMinutes * 60
        return Double(total - Int64(timeRemaining)) / Double(total)
    }
}

// Circular timer progress view
struct CircularTimer: View {
    let progress: Double
    
    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(Color.pink.opacity(0.3), lineWidth: 20)
            
            // Progress circle
            Circle()
                .trim(from: 0, to: CGFloat(min(progress, 1.0)))
                .stroke(Color.red, style: StrokeStyle(lineWidth: 20, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut, value: progress)
        }
    }
}
