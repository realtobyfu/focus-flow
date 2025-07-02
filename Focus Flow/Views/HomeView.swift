import SwiftUI

struct HomeView: View {
    @EnvironmentObject var taskViewModel: TaskViewModel
    @EnvironmentObject var themeManager: EnvironmentalThemeManager
    @StateObject private var aiRecommender = AISessionRecommender()
    @State private var selectedMinutes: Int = 25 // Changed default to 25 minutes
    @State private var selectedTag: String = "Study"
    @State private var timerIsActive = false
    @State private var showingTimerView = false
    @State private var showingTimeSelector = false
    @State private var showingTagSelector = false
    @State private var navigateToTimer = false
    @State private var animateGradient = false
    @State private var particleAnimationPhase = 0.0
    @Binding var showingAddTask: Bool
    
    let timeOptions = [10, 15, 20, 25, 30, 35, 40, 45, 50, 55, 60, 65, 70, 75, 80, 85, 90]
    let tags = ["Focus", "Study", "Work", "Read", "Fitness"]
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Dynamic theme gradient background
                if let gradient = themeManager.currentTheme.gradients.first {
                    gradient
                        .ignoresSafeArea()
                        .animation(.easeInOut(duration: 3).repeatForever(autoreverses: true), value: animateGradient)
                        .onAppear { animateGradient.toggle() }
                } else {
                    LinearGradient(
                        colors: [Color(hex: "667eea"), Color(hex: "764ba2")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .ignoresSafeArea()
                }
                
                // Floating particles based on theme
                if themeManager.currentTheme.hasParticles {
                    ParticleEffectView(
                        particleSystem: themeManager.currentTheme.particleEffects,
                        animationPhase: particleAnimationPhase
                    )
                    .allowsHitTesting(false)
                    .onAppear {
                        withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
                            particleAnimationPhase = 1.0
                        }
                    }
                }
                
                VStack(spacing: 0) {
                    Spacer()
                    
                    // Timer Display with Glass Morphism
                    VStack(spacing: 20) {
                        // Timer Button
                        Button(action: { showingTimeSelector = true }) {
                            Text("\(selectedMinutes):00")
                                .font(.system(size: AppTheme.timerDisplay, weight: .medium, design: .rounded))
                                .foregroundColor(.white)
                                .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 2)
                        }
                        .padding(.horizontal, 40)
                        .padding(.vertical, 20)
                        .background(
                            GlassMorphismView()
                                .clipShape(RoundedRectangle(cornerRadius: 25))
                        )
                        
                        // Tag Button
                        Button(action: { showingTagSelector = true }) {
                            HStack {
                                Image(systemName: getFocusMode().icon)
                                    .font(.title3)
                                Text(selectedTag)
                                    .font(.title2)
                                    .fontWeight(.medium)
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 30)
                            .padding(.vertical, 12)
                            .background(
                                GlassMorphismView()
                                    .clipShape(Capsule())
                            )
                        }
                    }
                    .scaleEffect(timerIsActive ? 1.05 : 1.0)
                    .animation(.easeInOut(duration: 0.3), value: timerIsActive)
                    
                    Spacer()
                    
                    // Start Button with Glow Effect
                    Button(action: startFocusSession) {
                        HStack(spacing: 12) {
                            Image(systemName: "play.fill")
                                .font(.title3)
                            Text("Start Focus")
                                .font(.title3)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(width: 200, height: 65)
                        .background(
                            ZStack {
                                // Glow effect
                                RoundedRectangle(cornerRadius: 32)
                                    .fill(getFocusMode().color)
                                    .blur(radius: 20)
                                    .opacity(0.6)
                                
                                // Main button
                                RoundedRectangle(cornerRadius: 32)
                                    .fill(
                                        LinearGradient(
                                            colors: [getFocusMode().color, getFocusMode().color.opacity(0.8)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                            }
                        )
                        .scaleEffect(timerIsActive ? 0.95 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: timerIsActive)
                    }
                    .padding(.bottom, 60)
                }
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingTimeSelector) {
            TimeSelector(selectedMinutes: $selectedMinutes)
                .environmentObject(themeManager)
        }
        .sheet(isPresented: $showingTagSelector) {
            TagSelector(selectedTag: $selectedTag)
                .environmentObject(themeManager)
        }
        .fullScreenCover(isPresented: $navigateToTimer) {
            if let activeTask = taskViewModel.activeTask {
                TimerView(task: activeTask, focusMode: getFocusMode())
            }
        }
        .onAppear {
            aiRecommender.analyzeAndRecommend()
        }
    }
    
    private func startFocusSession() {
        // Create or get active task
        let task = taskViewModel.createQuickTask(
            title: selectedTag,
            duration: selectedMinutes,
            tag: selectedTag
        )
        
        taskViewModel.startTask(task)
        navigateToTimer = true
    }
    
    private func showTimeSelector() {
        showingTimeSelector = true
    }
    
    private func showTagSelector() {
        showingTagSelector = true
    }
    
    private func getFocusMode() -> FocusMode {
        switch selectedTag {
        case "Study", "Learning":
            return .learning
        case "Work":
            return .deepWork
        case "Creative", "Design":
            return .creativeFlow
        case "Read", "Reading":
            return .mindfulFocus
        case "Fitness", "Exercise":
            return .quickSprint
        default:
            return .deepWork
        }
    }
}

// MARK: - Glass Morphism View
struct GlassMorphismView: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 25)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 25)
                        .stroke(
                            LinearGradient(
                                colors: [.white.opacity(0.5), .white.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        }
    }
}

// MARK: - Time Selector Sheet
struct TimeSelector: View {
    @Binding var selectedMinutes: Int
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var themeManager: EnvironmentalThemeManager
    
    let timeOptions = stride(from: 10, through: 90, by: 5).map { $0 }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Theme gradient background
                if let gradient = themeManager.currentTheme.gradients.first {
                    gradient
                        .ignoresSafeArea()
                } else {
                    LinearGradient(
                        colors: [Color(hex: "667eea"), Color(hex: "764ba2")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .ignoresSafeArea()
                }
                
                VStack {
                    // Visual time slider representation
                    ScrollView {
                        VStack(spacing: 0) {
                            ForEach(timeOptions, id: \.self) { minutes in
                                Button(action: {
                                    selectedMinutes = minutes
                                    dismiss()
                                }) {
                                    HStack {
                                        Text("\(minutes)")
                                            .font(.title2)
                                            .fontWeight(selectedMinutes == minutes ? .bold : .regular)
                                        
                                        Spacer()
                                        
                                        Text("minutes")
                                            .font(.body)
                                            .foregroundColor(.white.opacity(0.7))
                                        
                                        if selectedMinutes == minutes {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(.white)
                                                .font(.title3)
                                        }
                                    }
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 25)
                                    .padding(.vertical, 15)
                                    .background(
                                        selectedMinutes == minutes
                                        ? AnyView(
                                            RoundedRectangle(cornerRadius: 16)
                                                .fill(.ultraThinMaterial)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 16)
                                                        .stroke(.white.opacity(0.3), lineWidth: 1)
                                                )
                                        )
                                        : AnyView(Color.clear)
                                    )
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select Duration")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Tag Selector Sheet
struct TagSelector: View {
    @Binding var selectedTag: String
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var themeManager: EnvironmentalThemeManager
    
    let tags = [
        ("Focus", FocusMode.deepWork),
        ("Study", FocusMode.learning),
        ("Work", FocusMode.deepWork),
        ("Read", FocusMode.mindfulFocus),
        ("Fitness", FocusMode.quickSprint)
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                // Theme gradient background
                if let gradient = themeManager.currentTheme.gradients.first {
                    gradient
                        .ignoresSafeArea()
                } else {
                    LinearGradient(
                        colors: [Color(hex: "667eea"), Color(hex: "764ba2")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .ignoresSafeArea()
                }
                
                VStack(spacing: 20) {
                    Text("Select Tag")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.top, 40)
                    
                    VStack(spacing: 16) {
                        ForEach(tags, id: \.0) { tag, focusMode in
                            Button(action: {
                                selectedTag = tag
                                dismiss()
                            }) {
                                HStack {
                                    Image(systemName: focusMode.icon)
                                        .font(.title3)
                                        .foregroundColor(focusMode.color)
                                        .frame(width: 30)
                                    
                                    Text(tag)
                                        .font(.title3)
                                        .fontWeight(.medium)
                                    
                                    Spacer()
                                    
                                    if selectedTag == tag {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.white)
                                            .font(.title3)
                                    }
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 16)
                                .background(
                                    ZStack {
                                        if selectedTag == tag {
                                            RoundedRectangle(cornerRadius: 20)
                                                .fill(focusMode.color.opacity(0.3))
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 20)
                                                        .stroke(focusMode.color, lineWidth: 2)
                                                )
                                        } else {
                                            RoundedRectangle(cornerRadius: 20)
                                                .fill(.ultraThinMaterial)
                                        }
                                    }
                                )
                            }
                        }
                        
                        // New Tag Button with Glass Effect
                        Button(action: {
                            // Add new tag functionality
                        }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title3)
                                
                                Text("Create New Tag")
                                    .font(.title3)
                                    .fontWeight(.medium)
                                
                                Spacer()
                                
                                Image(systemName: "lock.fill")
                                    .font(.caption)
                                    .opacity(0.7)
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                            .background(
                                ZStack {
                                    // Gradient border
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(
                                            LinearGradient(
                                                colors: [.white.opacity(0.6), .white.opacity(0.2)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 2
                                        )
                                    
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(.ultraThinMaterial)
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 30)
                    
                    Spacer()
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
}

#Preview {
    HomeView(showingAddTask: .constant(false))
        .environmentObject(TaskViewModel(context: PersistenceController.preview.container.viewContext))
}