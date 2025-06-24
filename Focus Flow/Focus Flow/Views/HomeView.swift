import SwiftUI

struct HomeView: View {
    @EnvironmentObject var taskViewModel: TaskViewModel
    @EnvironmentObject var blockingManager: AppBlockingManager
    @AppStorage("defaultFocusDuration") private var defaultFocusDuration: Int = 25
    @State private var showingTagSelection = false
    @State private var selectedTag: FocusTag = .focus
    @State private var showingTimerView = false
    @State private var duration: Int = 0 // Will be set to default on appear
    @State private var showingDurationOptions = false
    @StateObject private var aiRecommender = AISessionRecommender()
    @StateObject private var environmentManager = EnvironmentalThemeManager()
    
    // Duration presets (in minutes)
    let durationOptions = [15, 25, 30, 45, 60, 90, 120]
    
    var body: some View {
        ZStack {
            // Dynamic Environmental Background
            EnvironmentalBackground(
                theme: environmentManager.currentTheme,
                animated: true
            )
            .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 40) {
                // AI Recommendation Card
                if let recommendation = aiRecommender.recommendation {
                    AIRecommendationCard(recommendation: recommendation) {
                        startRecommendedSession(recommendation)
                    }
                    .padding(.horizontal)
                }
                
                HStack {
                    Spacer()
                    Button(action: {
                        blockingManager.toggleBlockingEnabled()
                    }) {
                        Image(systemName: blockingManager.isBlockingEnabled ? "bell.slash.fill" : "bell.fill")
                            .font(.title2)
                            .foregroundColor(blockingManager.isBlockingEnabled ? Color.themePrimary : Color.gray)
                    }
                    .padding(.trailing, AppTheme.Spacing.l)
                }
                Spacer()
                
                // Timer display
                Text("\(duration):00")
                    .font(.system(size: AppTheme.timerDisplay, weight: .semibold))
                    .foregroundColor(Color.timerText)
                    .monospacedDigit()
                    .onTapGesture {
                        showingDurationOptions = true
                    }
                
                // Tag name
                HStack {
                    Text(selectedTag.name)
                        .font(.title2)
                        .foregroundColor(Color.timerText.opacity(0.8))
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(Color.timerText.opacity(0.6))
                        .font(.system(size: 16))
                }
                .onTapGesture {
                    showingTagSelection = true
                }
                
                Spacer()
                
                // Start button
                Button {
                    createAndStartSession()
                } label: {
                    Text("Start Focus")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(Color.timerText)
                        .padding(.vertical, 16)
                        .padding(.horizontal, AppTheme.largePadding * 1.5)
                        .background(
                            Capsule()
                                .fill(Color.buttonBackground)
                        )
                }
                .standardShadow()
                .padding(Edge.Set.bottom, 50)
            }
        }
        .onAppear {
            duration = defaultFocusDuration
            aiRecommender.analyzeAndRecommend()
            environmentManager.updateForTimeOfDay()
        }
        .sheet(isPresented: $showingTagSelection) {
            TagSelectionView(selectedTag: $selectedTag)
                .presentationDetents([.medium])
        }
        .actionSheet(isPresented: $showingDurationOptions) {
            ActionSheet(
                title: Text("Select Duration"),
                buttons: durationOptions.map { minutes in
                    .default(Text("\(minutes) minutes")) {
                        duration = minutes
                    }
                } + [.cancel()]
            )
        }
        .fullScreenCover(isPresented: $showingTimerView) {
            if let task = taskViewModel.currentTask {
                TimerView(task: task)
                    .environmentObject(taskViewModel)
            }
        }
    }
    
    private func createAndStartSession() {
        taskViewModel.createTask(
            title: selectedTag.name,
            totalMinutes: Int64(duration),
            blockMinutes: Int64(duration),
            breakMinutes: Int64(defaultFocusDuration / 5), // dynamic break
            tag: selectedTag.name
        )
        showingTimerView = true
    }
    
    // MARK: - AI Recommended Session
    private func startRecommendedSession(_ recommendation: SessionRecommendation) {
        // Use recommended duration and start session
        duration = recommendation.focusDuration
        createAndStartSession()
    }
}

// MARK: - FocusTag model
enum FocusTag: String, CaseIterable, Identifiable {
    case focus = "Focus"
    case read = "Read"
    case study = "Study"
    case work = "Work"
    case fitness = "Fitness"
    case newTag = "New Tag"
    
    var id: String { self.rawValue }
    
    var name: String {
        self.rawValue
    }
    
    var color: Color {
        switch self {
        case .focus:
            return .orange
        case .read:
            return .yellow
        case .study:
            return .teal
        case .work:
            return .green
        case .fitness:
            return .orange.opacity(0.8)
        case .newTag:
            return .red.opacity(0.7)
        }
    }
}

// MARK: - Tag Selection View
struct TagSelectionView: View {
    @Binding var selectedTag: FocusTag
    @State private var newTagName = ""
    @State private var showingNewTagField = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            // Sheet indicator
            Capsule()
                .fill(Color.gray.opacity(0.5))
                .frame(width: 40, height: 5)
                .padding(.top, 8)
            
            Text("Select Tag")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.bottom, 10)
            
            ScrollView {
                VStack(spacing: 16) {
                    // New Tag button
                    TagSelectionButton(
                        color: Color.red.opacity(0.7),
                        icon: "lock.fill",
                        title: "New Tag",
                        isLocked: true,
                        isSelected: false
                    ) {
                        // This would open a premium upgrade sheet in a real app
                    }
                    
                    // Standard tags in a grid layout
                    TagGrid(selectedTag: $selectedTag)
                }
                .padding(.horizontal)
            }
            
            Spacer()
            
            // Done button
            Button("Done") {
                dismiss()
            }
            .font(.headline)
            .foregroundColor(.white)
            .padding(.vertical, 12)
            .padding(.horizontal, 40)
            .background(Color.black)
            .cornerRadius(12)
            .padding(.bottom, 30)
        }
        .padding()
        .background(Color(UIColor.systemBackground))
    }
}

// Grid layout for tags
struct TagGrid: View {
    @Binding var selectedTag: FocusTag
    
    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            ForEach(FocusTag.allCases.filter { $0 != .newTag }) { tag in
                TagSelectionButton(
                    color: tag.color,
                    icon: nil,
                    title: tag.name,
                    isLocked: false,
                    isSelected: selectedTag == tag
                ) {
                    selectedTag = tag
                }
            }
        }
    }
}

// Tag button in selection sheet
struct TagSelectionButton: View {
    let color: Color
    let icon: String?
    let title: String
    let isLocked: Bool
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                if let icon = icon {
                    Image(systemName: icon)
                        .foregroundColor(.white)
                        .padding(.leading, 8)
                } else {
                    Circle()
                        .fill(color)
                        .frame(width: 10, height: 10)
                        .padding(.leading, 8)
                }
                
                Text(title)
                    .foregroundColor(isLocked ? .white : (isSelected ? color : .primary))
                    .font(.headline)
                
                Spacer()
            }
            .padding(.vertical, 16)
            .background(
                Capsule()
                    .fill(
                        isLocked ? 
                            color :
                            (isSelected ? color.opacity(0.2) : Color.gray.opacity(0.2))
                    )
            )
        }
    }
}

// MARK: - TagButton Component for main view
struct TagButton: View {
    let tag: FocusTag
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                if tag == .newTag {
                    Image(systemName: "lock.fill")
                        .foregroundColor(.white)
                        .padding(.leading, 8)
                } else {
                    Circle()
                        .fill(tag.color)
                        .frame(width: 10, height: 10)
                        .padding(.leading, 8)
                }
                
                Text(tag.name)
                    .foregroundColor(tag == .newTag ? .white : .primary)
                    .font(.headline)
                
                Spacer()
            }
            .padding(.vertical, 16)
            .background(
                Capsule()
                    .fill(
                        tag == .newTag ? 
                            Color.red.opacity(0.7) :
                            (isSelected ? tag.color.opacity(0.2) : Color.gray.opacity(0.2))
                    )
            )
        }
    }
}

// MARK: - AI Recommendation Card
struct AIRecommendationCard: View {
    let recommendation: SessionRecommendation
    let onAccept: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("AI Recommendation")
                .font(.headline)

            HStack {
                Text("\(recommendation.focusDuration)-minute \(recommendation.suggestedMode.rawValue)")
                    .font(.subheadline)
                Spacer()
                Button(action: onAccept) {
                    Text("Start")
                        .font(.subheadline)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(Color.themePrimary))
                        .foregroundColor(.white)
                }
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(UIColor.secondarySystemBackground)))
        .shadow(radius: 5)
    }
}

//// MARK: - Preview
//struct HomeView_Previews: PreviewProvider {
//    static var previews: some View {
//        HomeView()
//            .environmentObject(TaskViewModel())
//    }
//} 

