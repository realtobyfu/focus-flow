import SwiftUI
import AVFoundation

struct TimerView: View {
    @ObservedObject var task: TaskEntity
    let focusMode: FocusMode
    
    @EnvironmentObject var taskViewModel: TaskViewModel
    @EnvironmentObject var blockingManager: AppBlockingManager
    @StateObject private var soundManager = AmbientSoundManager()
    @EnvironmentObject var themeManager: EnvironmentalThemeManager
    
    @State private var timeRemaining: Int = 0
    @State private var timerRunning = false
    @State private var timer: Timer? = nil
    @State private var currentPhase: TimerPhase = .focus
    @State private var completedIntervals = 0
    @State private var showingCompletionSheet = false
    @State private var currentSound: AmbientSound?
    @State private var showingExitConfirmation = false
    
    @AppStorage("playAmbientDuringBreaks") private var playAmbientDuringBreaks = false
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    
    // Timer persistence keys
    @AppStorage("savedTimeRemaining") private var savedTimeRemaining: Int = 0
    @AppStorage("savedTimerPhase") private var savedTimerPhase: String = "focus"
    @AppStorage("savedTaskId") private var savedTaskId: String = ""
    @AppStorage("savedCompletedIntervals") private var savedCompletedIntervals: Int = 0
    @AppStorage("timerWasRunning") private var timerWasRunning: Bool = false
    
    enum TimerPhase {
        case focus, rest
    }
    
    var body: some View {
        ZStack {
            // Environmental Background
            EnvironmentalBackground(
                theme: themeManager.currentTheme,
                animated: timerRunning
            )
            .ignoresSafeArea()
            
            VStack {
                // Top Bar
                HStack {
                    Button(action: handleExit) {
                        Image(systemName: "xmark")
                            .font(.title3)
                            .foregroundColor(.white.opacity(0.8))
                            .padding(12)
                            .background(Circle().fill(Color.white.opacity(0.2)))
                    }
                    
                    Spacer()
                    
                    // Sound toggle
                    Button(action: toggleSound) {
                        Image(systemName: soundManager.isPlaying ? "speaker.wave.3.fill" : "speaker.slash.fill")
                            .font(.title3)
                            .foregroundColor(.white.opacity(0.8))
                            .padding(12)
                            .background(Circle().fill(Color.white.opacity(0.2)))
                    }
                }
                .padding()
                
                Spacer()
                
                // Timer Display
                VStack(spacing: 24) {
                    Text(currentPhase == .focus ? focusMode.displayName : "Break Time")
                        .font(.title2)
                        .foregroundColor(.white.opacity(0.8))
                    
                    // Timer Ring
                    ZStack {
                        // Background ring
                        Circle()
                            .stroke(Color.white.opacity(0.2), lineWidth: 12)
                            .frame(width: 280, height: 280)
                        
                        // Progress ring
                        Circle()
                            .trim(from: 0, to: timerProgress)
                            .stroke(
                                LinearGradient(
                                    colors: currentPhase == .focus ? focusMode.gradientColors : [.green, .mint],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                style: StrokeStyle(lineWidth: 12, lineCap: .round)
                            )
                            .frame(width: 280, height: 280)
                            .rotationEffect(.degrees(-90))
                            .animation(.linear(duration: 1), value: timerProgress)
                        
                        // Time display
                        VStack(spacing: 8) {
                            Text(formatTime(timeRemaining))
                                .font(.system(size: 64, weight: .light, design: .rounded))
                                .foregroundColor(.white)
                                .monospacedDigit()
                            
                            Text(getMotivationalText())
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }
                    
                    // Play/Pause button only
                    Button(action: toggleTimer) {
                        Image(systemName: timerRunning ? "pause.fill" : "play.fill")
                            .font(.title)
                            .foregroundColor(.black)
                            .frame(width: 80, height: 80)
                            .background(
                                Circle()
                                    .fill(Color.white)
                                    .shadow(color: .white.opacity(0.5), radius: 10)
                            )
                    }
                }
                
                Spacer()
                
                // Session info
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(task.title ?? "Focus Session")
                            .font(.headline)
                            .foregroundColor(.white)
                        Text("Interval \(completedIntervals + 1)")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                    }
                    
                    Spacer()
                    
                    Text("\(Int(task.completionPercentage))%")
                        .font(.headline)
                        .foregroundColor(.white)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.1))
                )
                .padding()
            }
        }
        .onAppear {
            setupTimer()
            startBlockingIfEnabled()
            // Auto-start the timer
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                startTimer()
            }
        }
        .onDisappear {
            cleanup()
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .background || newPhase == .inactive {
                if timerRunning {
                    saveTimerState()
                }
            }
        }
        .sheet(isPresented: $showingCompletionSheet) {
            SessionCompletionView(
                task: task,
                completedMinutes: Int(task.blockMinutes),
                focusMode: focusMode
            )
        }
        .alert("Exit Focus Session?", isPresented: $showingExitConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Exit", role: .destructive) {
                cleanup()
                dismiss()
            }
        } message: {
            Text("Are you sure you want to exit? Your progress will be reset.")
        }
    }
    
    private var timerProgress: Double {
        let total = currentPhase == .focus ? Double(task.blockMinutes * 60) : Double(task.breakMinutes * 60)
        guard total > 0 else { return 0 }
        return 1.0 - (Double(timeRemaining) / total)
    }
    
    private func setupTimer() {
        // Check if we have a saved state for this task
        if savedTaskId == task.id?.uuidString && savedTimeRemaining > 0 {
            // Restore saved state
            timeRemaining = savedTimeRemaining
            currentPhase = savedTimerPhase == "rest" ? .rest : .focus
            completedIntervals = savedCompletedIntervals
            
            // Clear saved state after restoring
            clearSavedState()
            
            // Auto-resume if timer was running
            if timerWasRunning {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    startTimer()
                }
            }
        } else {
            // Fresh start
            timeRemaining = Int(task.blockMinutes * 60)
        }
        
        themeManager.updateForTimeOfDay()
        
        // Load ambient sound if available
        if let sound = soundManager.soundForFocusMode(focusMode) {
            currentSound = sound
        }
    }
    
    private func toggleTimer() {
        if timerRunning {
            pauseTimer()
        } else {
            startTimer()
        }
    }
    
    private func startTimer() {
        timerRunning = true
        
        // Only play ambient sound during focus phase or if playAmbientDuringBreaks is enabled
        if let sound = currentSound, !soundManager.isPlaying {
            if currentPhase == .focus || playAmbientDuringBreaks {
                soundManager.play(sound: sound)
            }
        }
        
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                handlePhaseComplete()
            }
        }
    }
    
    private func pauseTimer() {
        timerRunning = false
        timer?.invalidate()
        timer = nil
        soundManager.stop()
        
        // Save current state
        saveTimerState()
    }
    
    private func handlePhaseComplete() {
        pauseTimer()
        HapticStyle.success.trigger()
        
        if currentPhase == .focus {
            // Update task progress
            let completedMinutes = task.blockMinutes
            taskViewModel.updateTaskProgress(task, completedMinutes: completedMinutes)
            
            // Switch to break
            currentPhase = .rest
            timeRemaining = Int(task.breakMinutes * 60)
            
            // Handle ambient sound for break phase
            if soundManager.isPlaying && !playAmbientDuringBreaks {
                soundManager.stop()
            }
            
            // Show notification (NotificationManager not implemented yet)
            // NotificationManager.shared.scheduleSessionComplete(duration: Int(completedMinutes))
        } else {
            // Complete interval
            completedIntervals += 1
            
            // Check if task is complete
            if task.completionPercentage >= 100 {
                completeSession()
            } else {
                // Start next focus interval
                currentPhase = .focus
                timeRemaining = Int(task.blockMinutes * 60)
                
                // Resume ambient sound for focus phase if it was playing before
                if currentSound != nil && !soundManager.isPlaying {
                    soundManager.play(sound: currentSound!)
                }
            }
        }
        
        // Auto-start next phase
        if !task.isCompleted {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                startTimer()
            }
        }
    }
    
    private func skipPhase() {
        HapticStyle.light.trigger()
        handlePhaseComplete()
    }
    
    private func completeSession() {
        pauseTimer()
        // Stop blocking with Screen Time manager
        if #available(iOS 15.0, *) {
            blockingManager.stopBlocking()
        }
        showingCompletionSheet = true
    }
    
    private func handleExit() {
        // Show confirmation if timer is running or time has been spent
        if timerRunning || (timeRemaining < Int(task.blockMinutes * 60)) {
            pauseTimer()
            showingExitConfirmation = true
        } else {
            cleanup()
            dismiss()
        }
    }
    
    private func cleanup() {
        // Save state before cleanup if timer is running
        if timerRunning {
            saveTimerState()
        }
        
        timer?.invalidate()
        timer = nil
        soundManager.stop()
        // Stop blocking with Screen Time manager
        if #available(iOS 15.0, *) {
            blockingManager.stopBlocking()
        }
    }
    
    private func saveTimerState() {
        savedTaskId = task.id?.uuidString ?? ""
        savedTimeRemaining = timeRemaining
        savedTimerPhase = currentPhase == .rest ? "rest" : "focus"
        savedCompletedIntervals = completedIntervals
        timerWasRunning = timerRunning
    }
    
    private func clearSavedState() {
        savedTaskId = ""
        savedTimeRemaining = 0
        savedTimerPhase = "focus"
        savedCompletedIntervals = 0
        timerWasRunning = false
    }
    
    private func toggleSound() {
        if soundManager.isPlaying {
            soundManager.stop()
        } else if let sound = currentSound {
            soundManager.play(sound: sound)
        }
    }
    
    private func startBlockingIfEnabled() {
        // Use Screen Time blocking if available and configured on iOS 15+
        if #available(iOS 15.0, *), blockingManager.isScreenTimeConfigured {
            blockingManager.startBlocking()
        }
    }
    
    private func formatTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }
    
    private func getMotivationalText() -> String {
        if currentPhase == .rest {
            return "Take a deep breath"
        }
        
        switch focusMode {
        case .deepWork:
            return "Stay in the zone"
        case .creativeFlow:
            return "Let creativity flow"
        case .learning:
            return "Absorb and understand"
        case .quickSprint:
            return "Push through!"
        case .mindfulFocus:
            return "Be present"
        }
    }
}

// MARK: - Session Completion View
struct SessionCompletionView: View {
    let task: TaskEntity
    let completedMinutes: Int
    let focusMode: FocusMode
    
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var taskViewModel: TaskViewModel
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: focusMode.gradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                // Success icon
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 120, height: 120)
                    
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.white)
                }
                
                VStack(spacing: 16) {
                    Text("Great Work!")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("You focused for \(completedMinutes) minutes")
                        .font(.title3)
                        .foregroundColor(.white.opacity(0.8))
                }
                
                // Stats
                HStack(spacing: 40) {
                    VStack(spacing: 8) {
                        Text("\(taskViewModel.todayMinutes)")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        Text("Minutes Today")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    VStack(spacing: 8) {
                        Text("\(taskViewModel.currentStreak)")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        Text("Day Streak")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white.opacity(0.2))
                )
                
                Spacer()
                
                // Action buttons
                VStack(spacing: 16) {
                    Button(action: startAnotherSession) {
                        Text("Start Another Session")
                            .font(.headline)
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                Capsule()
                                    .fill(Color.white)
                            )
                    }
                    
                    Button(action: { dismiss() }) {
                        Text("Done")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
            }
        }
    }
    
    private func startAnotherSession() {
        dismiss()
        // Navigate back to home for new session
    }
}

#Preview {
    TimerView(task: {
        let context = PersistenceController.preview.container.viewContext
        let task = TaskEntity(context: context)
        task.title = "Study Session"
        task.blockMinutes = 25
        task.breakMinutes = 5
        task.totalMinutes = 50
        return task
    }(), focusMode: .learning)
        .environmentObject(TaskViewModel(context: PersistenceController.preview.container.viewContext))
        .environmentObject(AppBlockingManager())
}