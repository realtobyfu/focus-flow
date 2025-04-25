import SwiftUI

struct TimerView: View {
    @ObservedObject var task: TaskEntity
    @EnvironmentObject var taskViewModel: TaskViewModel
    @Environment(\.presentationMode) var presentationMode
    
    // App blocking manager
    @StateObject private var blockingManager = AppBlockingManager()
    
    // Color theme - use named colors from assets
    let themeColor = Color("ThemeColor")
    let accentColor = Color("AccentColor")
    let textColor = Color("TextColor")
    
    @State private var timeRemaining: Int = 0
    @State private var timerRunning = false
    @State private var currentPhase: TimerPhase = .focus
    @State private var timer: Timer? = nil
    @State private var showCompletionSheet = false
    @State private var completedIntervals = 0
    @State private var totalTimeElapsed: Int64 = 0
    @State private var isPaused = false
    @State private var showBlockingNotice = false
    
    enum TimerPhase: String {
        case focus = "Focus Time"
        case breakTime = "Break Time"
    }
    
    var body: some View {
        ZStack {
            Color.themeBackground
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                // Top Bar
                ZStack {
                    themeColor
                        .edgesIgnoringSafeArea(.top)
                    HStack {
                        Button(action: {
                            // Confirm exit if timer is running
                            if timerRunning {
                                stopTimer()
                                blockingManager.stopBlocking()
                            }
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            HStack {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 20, weight: .medium))
                                
                                Text("Back")
                                    .font(.headline)
                            }
                            .foregroundColor(.white)
                        }
                        .padding(.leading)
                        
                        Spacer()
                    }
                }
                .frame(height: 60)
                
                // Task title
                Text(task.title ?? "Focus Session")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.themeTextPrimary)
                    .padding(.top, 20)
                
                // Session Status
                HStack {
                    Text(currentPhase.rawValue)
                        .font(.headline)
                        .foregroundColor(currentPhase == .focus ? themeColor : .green)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.white)
                                .shadow(color: Color.black.opacity(0.05), radius: 3)
                        )
                    
                    if currentPhase == .focus {
                        Text("\(completedIntervals + 1) of \(calculateTotalIntervals())")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.leading, 4)
                    }
                }
                .padding(.top, 16)
                
                // Timer Circle
                ZStack {
                    // Outer progress ring
                    CircularProgressView(progress: calculateProgress(),
                                        lineWidth: 12,
                                        primaryColor: currentPhase == .focus ? themeColor : Color.green,
                                        secondaryColor: Color.gray.opacity(0.2))
                        .frame(width: 280, height: 280)
                    
                    // Inner white circle with time
                    Circle()
                        .fill(Color.white)
                        .frame(width: 220, height: 220)
                        .shadow(color: Color.black.opacity(0.1), radius: 5)
                    
                    // Time display
                    VStack(spacing: 8) {
                        Text(formatTime(timeRemaining))
                            .font(.system(size: 54, weight: .bold))
                            .foregroundColor(themeColor)
                            .monospacedDigit()
                        
                        Text(currentPhase == .focus ? "until break" : "until next focus session")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 20)
                
                // App Blocking Status (if enabled)
                if blockingManager.isBlockingEnabled && currentPhase == .focus && timerRunning {
                    HStack {
                        Image(systemName: "bell.slash.fill")
                            .foregroundColor(.orange)
                        
                        Text("Distracting apps are being blocked")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(8)
                    .padding(.horizontal)
                    .transition(.opacity)
                }
                
                // Session Progress
                VStack(spacing: 8) {
                    HStack {
                        Text("Session Progress:")
                            .font(.headline)
                        
                        Spacer()
                        
                        Text("\(Int(task.completionPercentage))%")
                            .font(.headline)
                            .foregroundColor(themeColor)
                    }
                    .padding(.horizontal)
                    
                    // Progress bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 10)
                                .cornerRadius(5)
                            
                            Rectangle()
                                .fill(themeColor)
                                .frame(width: max(0, min(CGFloat(task.completionPercentage) / 100.0 * geometry.size.width, geometry.size.width)), height: 10)
                                .cornerRadius(5)
                        }
                    }
                    .frame(height: 10)
                    .padding(.horizontal)
                }
                .padding()
                
                Spacer()
                
                // Control Buttons
                HStack(spacing: 24) {
                    // Reset Button
                    Button(action: {
                        stopTimer()
                        resetTimer()
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color.red.opacity(0.15))
                                .frame(width: 60, height: 60)
                            
                            Image(systemName: "arrow.counterclockwise")
                                .font(.system(size: 24))
                                .foregroundColor(.red)
                        }
                    }
                    
                    // Play/Pause Button
                    Button(action: {
                        if timerRunning {
                            pauseTimer()
                        } else {
                            startTimer()
                        }
                    }) {
                        ZStack {
                            Circle()
                                .fill(themeColor)
                                .frame(width: 80, height: 80)
                                .shadow(color: themeColor.opacity(0.4), radius: 5)
                            
                            Image(systemName: timerRunning ? "pause.fill" : "play.fill")
                                .font(.system(size: 30))
                                .foregroundColor(.white)
                        }
                    }
                    
                    // Skip Button
                    Button(action: {
                        skipToNextPhase()
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color.gray.opacity(0.15))
                                .frame(width: 60, height: 60)
                            
                            Image(systemName: "forward.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(.bottom, 50)
            }
        }
        .navigationBarHidden(true)
        .onAppear(perform: {
            initializeTimer()
            
            // Handle the weird animation issue by using a slight delay
            // This allows the view transition to complete before initializing
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                // Additional setup if needed
            }
        })
        .sheet(isPresented: $showCompletionSheet) {
            BlockCompletionSheet(task: task,
                                currentPhase: $currentPhase,
                                completedTime: currentPhase == .focus ? task.blockMinutes : 0) {
                if currentPhase == .focus {
                    // Advance to break after completing a focus block
                    switchToBreak()
                } else {
                    // Advance to next focus session after break
                    switchToFocus()
                }
            }
        }
        .alert("App Blocking Enabled", isPresented: $showBlockingNotice) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Distracting apps will be blocked during your focus session to help you stay on task.")
        }
        .onDisappear {
            timer?.invalidate()
            if timerRunning {
                blockingManager.stopBlocking()
            }
        }
    }
    
    // MARK: - Timer Functions
    
    private func initializeTimer() {
        let duration = currentPhase == .focus ? task.blockMinutes : task.breakMinutes
        timeRemaining = Int(duration * 60)
    }
    
    private func startTimer() {
        timerRunning = true
        isPaused = false
        
        // Start app blocking if enabled and in focus mode
        if currentPhase == .focus && blockingManager.isBlockingEnabled {
            blockingManager.startBlocking()
            
            // Show notice first time only
            if completedIntervals == 0 && !showBlockingNotice {
                showBlockingNotice = true
            }
        }
        
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
                
                // If this is a focus phase, update the elapsed time
                if currentPhase == .focus {
                    totalTimeElapsed += 1
                }
            } else {
                // Timer finished
                timerRunning = false
                timer?.invalidate()
                timer = nil
                
                // Stop app blocking if in break mode
                if currentPhase == .breakTime {
                    blockingManager.stopBlocking()
                }
                
                // Show completion dialog
                showCompletionSheet = true
            }
        }
    }
    
    private func pauseTimer() {
        timerRunning = false
        isPaused = true
        timer?.invalidate()
        timer = nil
    }
    
    private func stopTimer() {
        pauseTimer()
        isPaused = false
    }
    
    private func resetTimer() {
        initializeTimer()
    }
    
    private func skipToNextPhase() {
        stopTimer()
        
        if currentPhase == .focus {
            // Calculate progress for partial completion
            let fullBlockSeconds = Int(task.blockMinutes * 60)
            let completedSeconds = fullBlockSeconds - timeRemaining
            let completedMinutes = Int64(completedSeconds / 60)
            
            if completedMinutes > 0 {
                // Update task progress based on completed time
                taskViewModel.updateTaskProgress(task, completedMinutes: completedMinutes)
            }
            
            // Stop app blocking
            blockingManager.stopBlocking()
            
            switchToBreak()
        } else {
            switchToFocus()
        }
    }
    
    private func switchToFocus() {
        currentPhase = .focus
        completedIntervals += 1
        resetTimer()
    }
    
    private func switchToBreak() {
        currentPhase = .breakTime
        resetTimer()
    }
    
    private func calculateTotalIntervals() -> Int {
        // Calculate approximately how many focus intervals are needed
        // for the total task based on block minutes
        return max(1, Int(ceil(Double(task.totalMinutes) / Double(task.blockMinutes))))
    }
    
    private func calculateProgress() -> Double {
        let total = currentPhase == .focus ? task.blockMinutes * 60 : task.breakMinutes * 60
        return Double(total - Int64(timeRemaining)) / Double(total)
    }
    
    private func formatTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }
}

// MARK: - Supporting Views

// Circular progress indicator
struct CircularProgressView: View {
    let progress: Double
    let lineWidth: CGFloat
    let primaryColor: Color
    let secondaryColor: Color
    
    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(lineWidth: lineWidth)
                .foregroundColor(secondaryColor)
            
            // Progress circle
            Circle()
                .trim(from: 0, to: CGFloat(min(progress, 1.0)))
                .stroke(style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .foregroundColor(primaryColor)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut, value: progress)
        }
    }
}
