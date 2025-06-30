import SwiftUI

struct HomeView: View {
    @EnvironmentObject var taskViewModel: TaskViewModel
    @StateObject private var aiRecommender = AISessionRecommender()
    @State private var selectedMinutes: Int = 50
    @State private var selectedTag: String = "Study"
    @State private var timerIsActive = false
    @State private var showingTimerView = false
    @State private var showingTimeSelector = false
    @State private var showingTagSelector = false
    @State private var navigateToTimer = false
    @Binding var showingAddTask: Bool
    
    let timeOptions = [10, 15, 20, 25, 30, 35, 40, 45, 50, 55, 60, 65, 70, 75, 80, 85, 90]
    let tags = ["Focus", "Study", "Work", "Read", "Fitness"]
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Warm beige background
                Color(red: 0.96, green: 0.93, blue: 0.88)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    Spacer()
                    
                    // Timer Display - Centered and Clickable
                    VStack(spacing: 16) {
                        Button(action: { showingTimeSelector = true }) {
                            Text("\(selectedMinutes):00")
                                .font(.system(size: AppTheme.timerDisplay, weight: .medium, design: .rounded))
                                .foregroundColor(Color(red: 0.3, green: 0.25, blue: 0.2))
                        }
                        
                        Button(action: { showingTagSelector = true }) {
                            Text(selectedTag)
                                .font(.title2)
                                .foregroundColor(Color(red: 0.5, green: 0.4, blue: 0.35))
                        }
                    }
                    
                    Spacer()
                    
                    // Start Button
                    Button(action: startFocusSession) {
                        Text("Start Focus")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(width: 180, height: 60)
                            .background(
                                RoundedRectangle(cornerRadius: 30)
                                    .fill(Color(red: 0.4, green: 0.3, blue: 0.25))
                            )
                    }
                    .padding(.bottom, 60)
                }
            }
            .navigationBarHidden(true)
            .navigationDestination(isPresented: $navigateToTimer) {
                if let activeTask = taskViewModel.activeTask {
                    TimerView(task: activeTask, focusMode: getFocusMode())
                        .navigationBarHidden(true)
                }
            }
        }
        .sheet(isPresented: $showingTimeSelector) {
            TimeSelector(selectedMinutes: $selectedMinutes)
        }
        .sheet(isPresented: $showingTagSelector) {
            TagSelector(selectedTag: $selectedTag)
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

// MARK: - Time Selector Sheet
struct TimeSelector: View {
    @Binding var selectedMinutes: Int
    @Environment(\.dismiss) private var dismiss
    
    let timeOptions = stride(from: 10, through: 90, by: 5).map { $0 }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(red: 0.96, green: 0.93, blue: 0.88)
                    .ignoresSafeArea()
                
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
                                            .foregroundColor(selectedMinutes == minutes ? .orange : Color(red: 0.3, green: 0.25, blue: 0.2))
                                        
                                        Spacer()
                                        
                                        Text("minutes")
                                            .font(.body)
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(.horizontal, 30)
                                    .padding(.vertical, 12)
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
    
    let tags = [
        ("Focus", Color.orange),
        ("Study", Color.teal),
        ("Work", Color.green),
        ("Read", Color.yellow),
        ("Fitness", Color.orange)
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(red: 0.96, green: 0.93, blue: 0.88)
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    Text("Select Tag")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.top, 40)
                    
                    VStack(spacing: 16) {
                        ForEach(tags, id: \.0) { tag, color in
                            Button(action: {
                                selectedTag = tag
                                dismiss()
                            }) {
                                HStack {
                                    Circle()
                                        .fill(color)
                                        .frame(width: 12, height: 12)
                                    
                                    Text(tag)
                                        .font(.title3)
                                        .fontWeight(.medium)
                                    
                                    Spacer()
                                    
                                    if selectedTag == tag {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.green)
                                    }
                                }
                                .foregroundColor(Color(red: 0.3, green: 0.25, blue: 0.2))
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(selectedTag == tag ? color.opacity(0.2) : Color.white)
                                )
                            }
                        }
                        
                        // New Tag Button
                        Button(action: {
                            // Add new tag functionality
                        }) {
                            HStack {
                                Image(systemName: "lock.fill")
                                    .foregroundColor(.white)
                                
                                Text("New Tag")
                                    .font(.title3)
                                    .fontWeight(.medium)
                                    .foregroundColor(.white)
                                
                                Spacer()
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color(red: 0.85, green: 0.5, blue: 0.4))
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