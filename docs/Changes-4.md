# Flow State - Final Implementation (Part 4)

## 16. iOS Widgets Implementation

```swift
// Widgets/FlowStateWidget.swift
import WidgetKit
import SwiftUI
import Intents

// MARK: - Widget Provider

struct FlowStateWidgetProvider: IntentTimelineProvider {
    func placeholder(in context: Context) -> FlowStateEntry {
        FlowStateEntry(
            date: Date(),
            configuration: ConfigurationIntent(),
            focusTime: 125,
            currentStreak: 7,
            nextSession: "Deep Work in 30 min",
            activeTask: nil
        )
    }
    
    func getSnapshot(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (FlowStateEntry) -> ()) {
        let entry = FlowStateEntry(
            date: Date(),
            configuration: configuration,
            focusTime: getUserFocusTime(),
            currentStreak: getUserStreak(),
            nextSession: getNextSession(),
            activeTask: getActiveTask()
        )
        completion(entry)
    }
    
    func getTimeline(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        var entries: [FlowStateEntry] = []
        
        // Generate timeline entries for the next 2 hours
        let currentDate = Date()
        for hourOffset in 0 ..< 2 {
            let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
            let entry = FlowStateEntry(
                date: entryDate,
                configuration: configuration,
                focusTime: getUserFocusTime(),
                currentStreak: getUserStreak(),
                nextSession: getNextSession(),
                activeTask: getActiveTask()
            )
            entries.append(entry)
        }
        
        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
    
    // Helper methods
    private func getUserFocusTime() -> Int {
        // Fetch from shared UserDefaults or App Group
        let sharedDefaults = UserDefaults(suiteName: "group.com.flowstate.app")
        return sharedDefaults?.integer(forKey: "todayFocusMinutes") ?? 0
    }
    
    private func getUserStreak() -> Int {
        let sharedDefaults = UserDefaults(suiteName: "group.com.flowstate.app")
        return sharedDefaults?.integer(forKey: "currentStreak") ?? 0
    }
    
    private func getNextSession() -> String? {
        let sharedDefaults = UserDefaults(suiteName: "group.com.flowstate.app")
        return sharedDefaults?.string(forKey: "nextScheduledSession")
    }
    
    private func getActiveTask() -> ActiveTaskInfo? {
        let sharedDefaults = UserDefaults(suiteName: "group.com.flowstate.app")
        guard let data = sharedDefaults?.data(forKey: "activeTask"),
              let task = try? JSONDecoder().decode(ActiveTaskInfo.self, from: data) else {
            return nil
        }
        return task
    }
}

// MARK: - Widget Entry

struct FlowStateEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationIntent
    let focusTime: Int
    let currentStreak: Int
    let nextSession: String?
    let activeTask: ActiveTaskInfo?
}

struct ActiveTaskInfo: Codable {
    let title: String
    let timeRemaining: Int
    let progress: Double
}

// MARK: - Widget Views

struct FlowStateWidgetEntryView: View {
    var entry: FlowStateWidgetProvider.Entry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        case .systemLarge:
            LargeWidgetView(entry: entry)
        case .accessoryInline:
            InlineWidgetView(entry: entry)
        case .accessoryCircular:
            CircularWidgetView(entry: entry)
        case .accessoryRectangular:
            RectangularWidgetView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

// MARK: - Small Widget

struct SmallWidgetView: View {
    let entry: FlowStateEntry
    
    var body: some View {
        ZStack {
            ContainerRelativeShape()
                .fill(
                    LinearGradient(
                        colors: [Color.blue.opacity(0.8), Color.purple.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            VStack(spacing: 12) {
                // Icon and streak
                HStack {
                    Image(systemName: "timer")
                        .font(.title2)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .font(.caption)
                        Text("\(entry.currentStreak)")
                            .font(.caption)
                            .fontWeight(.bold)
                    }
                    .foregroundColor(.orange)
                }
                
                Spacer()
                
                // Focus time
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(entry.focusTime)")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("minutes today")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding()
        }
        .widgetURL(URL(string: "flowstate://home"))
    }
}

// MARK: - Medium Widget

struct MediumWidgetView: View {
    let entry: FlowStateEntry
    
    var body: some View {
        ZStack {
            ContainerRelativeShape()
                .fill(Color(UIColor.systemBackground))
            
            HStack(spacing: 16) {
                // Left side - Stats
                VStack(alignment: .leading, spacing: 12) {
                    Label("Flow State", systemImage: "timer")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    // Focus time
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(entry.focusTime) min")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                        
                        Text("Focus today")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // Streak
                    HStack(spacing: 6) {
                        Image(systemName: "flame.fill")
                            .foregroundColor(.orange)
                        Text("\(entry.currentStreak) day streak")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Divider()
                
                // Right side - Quick actions or active session
                VStack(spacing: 12) {
                    if let activeTask = entry.activeTask {
                        ActiveSessionView(task: activeTask)
                    } else {
                        QuickStartButtonsView()
                    }
                }
            }
            .padding()
        }
    }
}

struct ActiveSessionView: View {
    let task: ActiveTaskInfo
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Active")
                .font(.caption)
                .foregroundColor(.green)
            
            Text(task.title)
                .font(.headline)
                .lineLimit(1)
            
            // Progress ring
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 4)
                
                Circle()
                    .trim(from: 0, to: task.progress)
                    .stroke(Color.green, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .rotationEffect(.degrees(-90))
            }
            .frame(width: 40, height: 40)
            
            Text("\(task.timeRemaining) min left")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .widgetURL(URL(string: "flowstate://timer"))
    }
}

struct QuickStartButtonsView: View {
    var body: some View {
        VStack(spacing: 8) {
            Text("Quick Start")
                .font(.caption)
                .foregroundColor(.secondary)
            
            ForEach([(15, "Quick"), (25, "Focus"), (45, "Deep")], id: \.0) { duration, label in
                Link(destination: URL(string: "flowstate://start/\(duration)")!) {
                    HStack {
                        Text("\(duration)m")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Text(label)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                }
            }
        }
    }
}

// MARK: - Large Widget

struct LargeWidgetView: View {
    let entry: FlowStateEntry
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Label("Flow State", systemImage: "timer")
                    .font(.headline)
                
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .foregroundColor(.orange)
                    Text("\(entry.currentStreak)")
                        .fontWeight(.bold)
                }
            }
            
            // Stats grid
            HStack(spacing: 16) {
                StatCard(
                    value: "\(entry.focusTime)",
                    unit: "min",
                    label: "Today",
                    color: .blue
                )
                
                StatCard(
                    value: formatHours(entry.focusTime * 7),
                    unit: "hrs",
                    label: "This Week",
                    color: .purple
                )
            }
            
            // Weekly chart
            WeeklyChartView()
                .frame(height: 120)
            
            // Next session or quick start
            if let nextSession = entry.nextSession {
                NextSessionCard(session: nextSession)
            } else {
                QuickStartCard()
            }
            
            Spacer()
        }
        .padding()
    }
    
    private func formatHours(_ minutes: Int) -> String {
        let hours = Double(minutes) / 60.0
        return String(format: "%.1f", hours)
    }
}

struct StatCard: View {
    let value: String
    let unit: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(color)
                
                Text(unit)
                    .font(.subheadline)
                    .foregroundColor(color.opacity(0.8))
            }
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Lock Screen Widgets

struct CircularWidgetView: View {
    let entry: FlowStateEntry
    
    var body: some View {
        ZStack {
            AccessoryWidgetBackground()
            
            VStack(spacing: 2) {
                Image(systemName: "timer")
                    .font(.title3)
                
                Text("\(entry.focusTime)")
                    .font(.headline)
                    .minimumScaleFactor(0.5)
            }
        }
        .widgetURL(URL(string: "flowstate://home"))
    }
}

struct RectangularWidgetView: View {
    let entry: FlowStateEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: "timer")
                Text("Flow State")
                    .font(.headline)
            }
            
            HStack {
                VStack(alignment: .leading) {
                    Text("\(entry.focusTime) min")
                        .font(.caption)
                    Text("today")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                HStack(spacing: 2) {
                    Image(systemName: "flame.fill")
                        .font(.caption2)
                    Text("\(entry.currentStreak)")
                        .font(.caption)
                }
            }
        }
        .widgetURL(URL(string: "flowstate://home"))
    }
}

// MARK: - Widget Configuration

@main
struct FlowStateWidget: Widget {
    let kind: String = "FlowStateWidget"
    
    var body: some WidgetConfiguration {
        IntentConfiguration(
            kind: kind,
            intent: ConfigurationIntent.self,
            provider: FlowStateWidgetProvider()
        ) { entry in
            FlowStateWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Flow State")
        .description("Track your focus time and start sessions quickly")
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .systemLarge,
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryInline
        ])
    }
}

## 17. Achievements and Rewards System

```swift
// Core/AchievementManager.swift
import SwiftUI

class AchievementManager: ObservableObject {
    @Published var unlockedAchievements: Set<String> = []
    @Published var recentUnlock: Achievement?
    @Published var points: Int = 0
    @Published var level: Int = 1
    @Published var levelProgress: Double = 0
    
    private let persistenceKey = "unlockedAchievements"
    
    init() {
        loadAchievements()
    }
    
    func checkAchievements(for event: AchievementEvent) {
        let applicableAchievements = Achievement.all.filter { achievement in
            !unlockedAchievements.contains(achievement.id) &&
            achievement.trigger.matches(event)
        }
        
        for achievement in applicableAchievements {
            if achievement.requirement.isMet(by: event) {
                unlock(achievement)
            }
        }
    }
    
    private func unlock(_ achievement: Achievement) {
        unlockedAchievements.insert(achievement.id)
        points += achievement.points
        recentUnlock = achievement
        saveAchievements()
        
        // Update level
        updateLevel()
        
        // Show notification
        showUnlockNotification(for: achievement)
        
        // Haptic feedback
        HapticStyle.success.trigger()
    }
    
    private func updateLevel() {
        let pointsPerLevel = 1000
        level = (points / pointsPerLevel) + 1
        levelProgress = Double(points % pointsPerLevel) / Double(pointsPerLevel)
    }
    
    private func showUnlockNotification(for achievement: Achievement) {
        NotificationManager.shared.showAchievementNotification(achievement)
    }
    
    private func loadAchievements() {
        if let data = UserDefaults.standard.data(forKey: persistenceKey),
           let achievements = try? JSONDecoder().decode(Set<String>.self, from: data) {
            unlockedAchievements = achievements
        }
        
        points = UserDefaults.standard.integer(forKey: "achievementPoints")
        updateLevel()
    }
    
    private func saveAchievements() {
        if let data = try? JSONEncoder().encode(unlockedAchievements) {
            UserDefaults.standard.set(data, forKey: persistenceKey)
        }
        UserDefaults.standard.set(points, forKey: "achievementPoints")
    }
}

// MARK: - Achievement Models

struct Achievement: Identifiable {
    let id: String
    let name: String
    let description: String
    let icon: String
    let category: Category
    let rarity: Rarity
    let points: Int
    let trigger: AchievementTrigger
    let requirement: AchievementRequirement
    let isSecret: Bool
    
    enum Category: String, CaseIterable {
        case focus = "Focus Master"
        case streak = "Consistency"
        case productivity = "Productivity"
        case social = "Community"
        case special = "Special"
        
        var color: Color {
            switch self {
            case .focus: return .blue
            case .streak: return .orange
            case .productivity: return .green
            case .social: return .purple
            case .special: return .yellow
            }
        }
    }
    
    enum Rarity: Int {
        case common = 1
        case uncommon = 2
        case rare = 3
        case epic = 4
        case legendary = 5
        
        var color: Color {
            switch self {
            case .common: return .gray
            case .uncommon: return .green
            case .rare: return .blue
            case .epic: return .purple
            case .legendary: return .orange
            }
        }
        
        var displayName: String {
            switch self {
            case .common: return "Common"
            case .uncommon: return "Uncommon"
            case .rare: return "Rare"
            case .epic: return "Epic"
            case .legendary: return "Legendary"
            }
        }
    }
    
    static let all: [Achievement] = [
        // Focus achievements
        Achievement(
            id: "first_focus",
            name: "First Steps",
            description: "Complete your first focus session",
            icon: "star.fill",
            category: .focus,
            rarity: .common,
            points: 10,
            trigger: .sessionCompleted,
            requirement: .count(1),
            isSecret: false
        ),
        Achievement(
            id: "hour_power",
            name: "Hour Power",
            description: "Complete a 60-minute focus session",
            icon: "clock.fill",
            category: .focus,
            rarity: .uncommon,
            points: 50,
            trigger: .sessionCompleted,
            requirement: .duration(60),
            isSecret: false
        ),
        Achievement(
            id: "deep_diver",
            name: "Deep Diver",
            description: "Complete a 90-minute deep work session",
            icon: "brain",
            category: .focus,
            rarity: .rare,
            points: 100,
            trigger: .sessionCompleted,
            requirement: .modeAndDuration(.deepWork, 90),
            isSecret: false
        ),
        Achievement(
            id: "marathon_mind",
            name: "Marathon Mind",
            description: "Focus for 500 minutes in a single day",
            icon: "figure.run",
            category: .focus,
            rarity: .epic,
            points: 200,
            trigger: .dailyTotal,
            requirement: .totalMinutes(500),
            isSecret: false
        ),
        
        // Streak achievements
        Achievement(
            id: "week_warrior",
            name: "Week Warrior",
            description: "Maintain a 7-day streak",
            icon: "flame.fill",
            category: .streak,
            rarity: .common,
            points: 25,
            trigger: .streakReached,
            requirement: .streak(7),
            isSecret: false
        ),
        Achievement(
            id: "monthly_master",
            name: "Monthly Master",
            description: "Maintain a 30-day streak",
            icon: "calendar.badge.checkmark",
            category: .streak,
            rarity: .rare,
            points: 150,
            trigger: .streakReached,
            requirement: .streak(30),
            isSecret: false
        ),
        Achievement(
            id: "centurion",
            name: "Centurion",
            description: "Maintain a 100-day streak",
            icon: "crown.fill",
            category: .streak,
            rarity: .legendary,
            points: 500,
            trigger: .streakReached,
            requirement: .streak(100),
            isSecret: false
        ),
        
        // Productivity achievements
        Achievement(
            id: "task_master",
            name: "Task Master",
            description: "Complete 10 tasks",
            icon: "checkmark.circle.fill",
            category: .productivity,
            rarity: .common,
            points: 30,
            trigger: .taskCompleted,
            requirement: .count(10),
            isSecret: false
        ),
        Achievement(
            id: "perfectionist",
            name: "Perfectionist",
            description: "Complete 5 tasks with 100% focus quality",
            icon: "star.circle.fill",
            category: .productivity,
            rarity: .rare,
            points: 100,
            trigger: .perfectSession,
            requirement: .count(5),
            isSecret: false
        ),
        
        // Social achievements
        Achievement(
            id: "team_player",
            name: "Team Player",
            description: "Join your first focus group",
            icon: "person.3.fill",
            category: .social,
            rarity: .common,
            points: 20,
            trigger: .groupJoined,
            requirement: .count(1),
            isSecret: false
        ),
        Achievement(
            id: "motivator",
            name: "Motivator",
            description: "Send 50 encouragement messages",
            icon: "heart.fill",
            category: .social,
            rarity: .uncommon,
            points: 75,
            trigger: .encouragementSent,
            requirement: .count(50),
            isSecret: false
        ),
        
        // Secret achievements
        Achievement(
            id: "night_owl",
            name: "Night Owl",
            description: "Complete a focus session between 2-5 AM",
            icon: "moon.stars.fill",
            category: .special,
            rarity: .rare,
            points: 100,
            trigger: .sessionCompleted,
            requirement: .timeRange(2, 5),
            isSecret: true
        ),
        Achievement(
            id: "early_bird",
            name: "Early Bird",
            description: "Start a focus session before 6 AM",
            icon: "sunrise.fill",
            category: .special,
            rarity: .uncommon,
            points: 50,
            trigger: .sessionStarted,
            requirement: .timeBefore(6),
            isSecret: true
        )
    ]
}

enum AchievementTrigger {
    case sessionCompleted
    case sessionStarted
    case taskCompleted
    case streakReached
    case dailyTotal
    case groupJoined
    case encouragementSent
    case perfectSession
    
    func matches(_ event: AchievementEvent) -> Bool {
        switch (self, event) {
        case (.sessionCompleted, .sessionCompleted):
            return true
        case (.sessionStarted, .sessionStarted):
            return true
        case (.taskCompleted, .taskCompleted):
            return true
        case (.streakReached, .streakUpdate):
            return true
        case (.dailyTotal, .dailyStats):
            return true
        case (.groupJoined, .groupJoined):
            return true
        case (.encouragementSent, .messageSent):
            return true
        case (.perfectSession, .sessionCompleted):
            return true
        default:
            return false
        }
    }
}

enum AchievementRequirement {
    case count(Int)
    case duration(Int)
    case streak(Int)
    case totalMinutes(Int)
    case modeAndDuration(FocusMode, Int)
    case timeRange(Int, Int)
    case timeBefore(Int)
    
    func isMet(by event: AchievementEvent) -> Bool {
        switch (self, event) {
        case (.count(let required), .sessionCompleted(_, _, let count, _)):
            return count >= required
        case (.duration(let required), .sessionCompleted(let duration, _, _, _)):
            return duration >= required
        case (.streak(let required), .streakUpdate(let current)):
            return current >= required
        case (.totalMinutes(let required), .dailyStats(let total)):
            return total >= required
        case (.modeAndDuration(let mode, let duration), .sessionCompleted(let actualDuration, let actualMode, _, _)):
            return actualMode == mode && actualDuration >= duration
        case (.timeRange(let start, let end), .sessionCompleted(_, _, _, let time)):
            let hour = Calendar.current.component(.hour, from: time)
            return hour >= start && hour <= end
        case (.timeBefore(let hour), .sessionStarted(let time)):
            let startHour = Calendar.current.component(.hour, from: time)
            return startHour < hour
        default:
            return false
        }
    }
}

enum AchievementEvent {
    case sessionCompleted(duration: Int, mode: FocusMode, totalCount: Int, time: Date)
    case sessionStarted(time: Date)
    case taskCompleted(count: Int)
    case streakUpdate(current: Int)
    case dailyStats(totalMinutes: Int)
    case groupJoined
    case messageSent(type: ChatMessage.ChatMessageType)
}

// MARK: - Achievement Views

struct AchievementsView: View {
    @StateObject private var achievementManager = AchievementManager()
    @State private var selectedCategory: Achievement.Category? = nil
    @State private var showingDetail: Achievement? = nil
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Progress header
                    AchievementProgressHeader(
                        level: achievementManager.level,
                        progress: achievementManager.levelProgress,
                        points: achievementManager.points
                    )
                    
                    // Category filter
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            CategoryFilterChip(
                                title: "All",
                                isSelected: selectedCategory == nil,
                                action: { selectedCategory = nil }
                            )
                            
                            ForEach(Achievement.Category.allCases, id: \.self) { category in
                                CategoryFilterChip(
                                    title: category.rawValue,
                                    color: category.color,
                                    isSelected: selectedCategory == category,
                                    action: { selectedCategory = category }
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Achievements grid
                    LazyVGrid(
                        columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ],
                        spacing: 16
                    ) {
                        ForEach(filteredAchievements) { achievement in
                            AchievementTile(
                                achievement: achievement,
                                isUnlocked: achievementManager.unlockedAchievements.contains(achievement.id),
                                action: { showingDetail = achievement }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle("Achievements")
            .sheet(item: $showingDetail) { achievement in
                AchievementDetailView(
                    achievement: achievement,
                    isUnlocked: achievementManager.unlockedAchievements.contains(achievement.id)
                )
            }
        }
    }
    
    private var filteredAchievements: [Achievement] {
        let achievements = Achievement.all.filter { !$0.isSecret || achievementManager.unlockedAchievements.contains($0.id) }
        
        if let category = selectedCategory {
            return achievements.filter { $0.category == category }
        }
        return achievements
    }
}

struct AchievementProgressHeader: View {
    let level: Int
    let progress: Double
    let points: Int
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Level \(level)")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("\(points) points")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Level badge
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.purple, .blue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 80, height: 80)
                    
                    Text("\(level)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
            }
            
            // Progress bar
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Progress to Level \(level + 1)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(Int(progress * 100))%")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.2))
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                LinearGradient(
                                    colors: [.purple, .blue],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * progress)
                    }
                }
                .frame(height: 8)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.secondarySystemBackground))
        )
        .padding(.horizontal)
    }
}

struct AchievementTile: View {
    let achievement: Achievement
    let isUnlocked: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(
                            isUnlocked ?
                            achievement.rarity.color.opacity(0.2) :
                            Color.gray.opacity(0.1)
                        )
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: achievement.icon)
                        .font(.title2)
                        .foregroundColor(
                            isUnlocked ?
                            achievement.rarity.color :
                            Color.gray.opacity(0.3)
                        )
                    
                    if !isUnlocked && !achievement.isSecret {
                        Circle()
                            .fill(Color.black.opacity(0.6))
                            .frame(width: 60, height: 60)
                        
                        Image(systemName: "lock.fill")
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                
                Text(isUnlocked || !achievement.isSecret ? achievement.name : "???")
                    .font(.caption)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .foregroundColor(isUnlocked ? .primary : .secondary)
                
                // Points badge
                if isUnlocked {
                    Text("+\(achievement.points)")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(achievement.rarity.color)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

## 18. Data Export Manager

```swift
// Core/DataExportManager.swift
import SwiftUI
import UniformTypeIdentifiers

class DataExportManager: ObservableObject {
    @Published var isExporting = false
    @Published var exportProgress: Double = 0
    @Published var lastExportDate: Date?
    
    func exportAllData(format: ExportFormat) async throws -> URL {
        isExporting = true
        exportProgress = 0
        
        defer {
            isExporting = false
        }
        
        let data = try await gatherAllData()
        
        switch format {
        case .json:
            return try await exportAsJSON(data)
        case .csv:
            return try await exportAsCSV(data)
        case .pdf:
            return try await exportAsPDF(data)
        }
    }
    
    private func gatherAllData() async throws -> ExportData {
        updateProgress(0.1)
        
        // Gather sessions
        let sessions = try await fetchAllSessions()
        updateProgress(0.3)
        
        // Gather tasks
        let tasks = try await fetchAllTasks()
        updateProgress(0.5)
        
        // Gather achievements
        let achievements = try await fetchAchievements()
        updateProgress(0.7)
        
        // Gather statistics
        let statistics = try await calculateStatistics()
        updateProgress(0.9)
        
        return ExportData(
            exportDate: Date(),
            sessions: sessions,
            tasks: tasks,
            achievements: achievements,
            statistics: statistics,
            userPreferences: gatherPreferences()
        )
    }
    
    private func exportAsJSON(_ data: ExportData) async throws -> URL {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        let jsonData = try encoder.encode(data)
        
        let fileName = "FlowState_Export_\(dateString()).json"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        try jsonData.write(to: url)
        
        updateProgress(1.0)
        lastExportDate = Date()
        
        return url
    }
    
    private func exportAsCSV(_ data: ExportData) async throws -> URL {
        var csvContent = ""
        
        // Sessions CSV
        csvContent += "FOCUS SESSIONS\n"
        csvContent += "Date,Start Time,Duration (min),Mode,Task,Completion,Quality\n"
        
        for session in data.sessions {
            csvContent += "\(formatDate(session.date)),\(formatTime(session.startTime)),\(session.duration),\(session.mode.rawValue),\"\(session.taskName ?? "N/A")\",\(session.completionPercentage)%,\(session.quality.rawValue)\n"
        }
        
        csvContent += "\n\nTASKS\n"
        csvContent += "Title,Created,Total Minutes,Completed Minutes,Status\n"
        
        for task in data.tasks {
            let status = task.completionPercentage >= 100 ? "Completed" : "In Progress"
            csvContent += "\"\(task.title)\",\(formatDate(task.dateCreated)),\(task.totalMinutes),\(Int(Double(task.totalMinutes) * task.completionPercentage / 100)),\(status)\n"
        }
        
        // Add statistics summary
        csvContent += "\n\nSTATISTICS SUMMARY\n"
        csvContent += "Metric,Value\n"
        csvContent += "Total Sessions,\(data.statistics.totalSessions)\n"
        csvContent += "Total Focus Time,\(data.statistics.totalMinutes) minutes\n"
        csvContent += "Average Session Duration,\(data.statistics.averageSessionDuration) minutes\n"
        csvContent += "Longest Streak,\(data.statistics.longestStreak) days\n"
        csvContent += "Most Productive Hour,\(data.statistics.mostProductiveHour ?? 0):00\n"
        
        let fileName = "FlowState_Export_\(dateString()).csv"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        try csvContent.write(to: url, atomically: true, encoding: .utf8)
        
        updateProgress(1.0)
        lastExportDate = Date()
        
        return url
    }
    
    private func exportAsPDF(_ data: ExportData) async throws -> URL {
        // Create PDF document
        let pdfRenderer = PDFReportGenerator()
        let pdfData = try await pdfRenderer.generateReport(from: data)
        
        let fileName = "FlowState_Report_\(dateString()).pdf"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        try pdfData.write(to: url)
        
        updateProgress(1.0)
        lastExportDate = Date()
        
        return url
    }
    
    private func updateProgress(_ progress: Double) {
        Task { @MainActor in
            self.exportProgress = progress
        }
    }
    
    private func dateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
    
    private func formatDate(_ date: Date?) -> String {
        guard let date = date else { return "" }
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
    
    private func formatTime(_ date: Date?) -> String {
        guard let date = date else { return "" }
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Export Models

enum ExportFormat: String, CaseIterable {
    case json = "JSON"
    case csv = "CSV"
    case pdf = "PDF Report"
    
    var icon: String {
        switch self {
        case .json: return "doc.text"
        case .csv: return "tablecells"
        case .pdf: return "doc.richtext"
        }
    }
    
    var fileExtension: String {
        switch self {
        case .json: return "json"
        case .csv: return "csv"
        case .pdf: return "pdf"
        }
    }
}

struct ExportData: Codable {
    let exportDate: Date
    let sessions: [SessionExport]
    let tasks: [TaskExport]
    let achievements: [AchievementExport]
    let statistics: StatisticsExport
    let userPreferences: PreferencesExport
}

struct SessionExport: Codable {
    let id: String
    let date: Date
    let startTime: Date
    let duration: Int
    let mode: FocusMode
    let taskName: String?
    let completionPercentage: Double
    let quality: FocusQuality
    let distractions: Int
}

struct TaskExport: Codable {
    let id: String
    let title: String
    let dateCreated: Date
    let totalMinutes: Int64
    let completionPercentage: Double
    let tag: String?
}

struct AchievementExport: Codable {
    let id: String
    let name: String
    let unlockedDate: Date
    let points: Int
}

struct StatisticsExport: Codable {
    let totalSessions: Int
    let totalMinutes: Int
    let averageSessionDuration: Int
    let longestStreak: Int
    let currentStreak: Int
    let mostProductiveHour: Int?
    let favoriteMode: String?
    let weeklyAverage: Int
}

struct PreferencesExport: Codable {
    let defaultFocusDuration: Int
    let defaultBreakDuration: Int
    let notificationsEnabled: Bool
    let soundsEnabled: Bool
    let theme: String
}

// MARK: - PDF Report Generator

class PDFReportGenerator {
    func generateReport(from data: ExportData) async throws -> Data {
        let pageSize = CGSize(width: 612, height: 792) // US Letter
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(origin: .zero, size: pageSize))
        
        let pdfData = renderer.pdfData { context in
            // Cover page
            context.beginPage()
            drawCoverPage(in: context, data: data)
            
            // Statistics overview
            context.beginPage()
            drawStatisticsPage(in: context, data: data)
            
            // Sessions summary
            context.beginPage()
            drawSessionsSummary(in: context, data: data)
            
            // Achievements page
            if !data.achievements.isEmpty {
                context.beginPage()
                drawAchievementsPage(in: context, data: data)
            }
        }
        
        return pdfData
    }
    
    private func drawCoverPage(in context: UIGraphicsPDFRendererContext, data: ExportData) {
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 36, weight: .bold),
            .foregroundColor: UIColor.label
        ]
        
        let title = "Flow State"
        let titleSize = title.size(withAttributes: titleAttributes)
        let titleRect = CGRect(
            x: (context.format.bounds.width - titleSize.width) / 2,
            y: 100,
            width: titleSize.width,
            height: titleSize.height
        )
        
        title.draw(in: titleRect, withAttributes: titleAttributes)
        
        // Subtitle
        let subtitleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 24, weight: .medium),
            .foregroundColor: UIColor.secondaryLabel
        ]
        
        let subtitle = "Productivity Report"
        let subtitleSize = subtitle.size(withAttributes: subtitleAttributes)
        let subtitleRect = CGRect(
            x: (context.format.bounds.width - subtitleSize.width) / 2,
            y: titleRect.maxY + 20,
            width: subtitleSize.width,
            height: subtitleSize.height
        )
        
        subtitle.draw(in: subtitleRect, withAttributes: subtitleAttributes)
        
        // Date
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        let dateString = dateFormatter.string(from: data.exportDate)
        
        let dateAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 16),
            .foregroundColor: UIColor.tertiaryLabel
        ]
        
        let dateSize = dateString.size(withAttributes: dateAttributes)
        let dateRect = CGRect(
            x: (context.format.bounds.width - dateSize.width) / 2,
            y: subtitleRect.maxY + 40,
            width: dateSize.width,
            height: dateSize.height
        )
        
        dateString.draw(in: dateRect, withAttributes: dateAttributes)
        
        // Logo or illustration
        if let image = UIImage(systemName: "timer") {
            let imageSize = CGSize(width: 120, height: 120)
            let imageRect = CGRect(
                x: (context.format.bounds.width - imageSize.width) / 2,
                y: (context.format.bounds.height - imageSize.height) / 2,
                width: imageSize.width,
                height: imageSize.height
            )
            
            image.withTintColor(.systemBlue).draw(in: imageRect)
        }
    }
    
    private func drawStatisticsPage(in context: UIGraphicsPDFRendererContext, data: ExportData) {
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 24, weight: .bold),
            .foregroundColor: UIColor.label
        ]
        
        "Statistics Overview".draw(at: CGPoint(x: 50, y: 50), withAttributes: titleAttributes)
        
        // Draw statistics grid
        var yPosition: CGFloat = 120
        let statistics = [
            ("Total Sessions", "\(data.statistics.totalSessions)"),
            ("Total Focus Time", "\(data.statistics.totalMinutes / 60) hours \(data.statistics.totalMinutes % 60) minutes"),
            ("Average Session", "\(data.statistics.averageSessionDuration) minutes"),
            ("Longest Streak", "\(data.statistics.longestStreak) days"),
            ("Current Streak", "\(data.statistics.currentStreak) days"),
            ("Weekly Average", "\(data.statistics.weeklyAverage) minutes")
        ]
        
        let labelAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 16),
            .foregroundColor: UIColor.secondaryLabel
        ]
        
        let valueAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 20, weight: .semibold),
            .foregroundColor: UIColor.label
        ]
        
        for (label, value) in statistics {
            label.draw(at: CGPoint(x: 50, y: yPosition), withAttributes: labelAttributes)
            value.draw(at: CGPoint(x: 300, y: yPosition), withAttributes: valueAttributes)
            yPosition += 40
        }
    }
    
    private func drawSessionsSummary(in context: UIGraphicsPDFRendererContext, data: ExportData) {
        // Implementation for sessions summary page
    }
    
    private func drawAchievementsPage(in context: UIGraphicsPDFRendererContext, data: ExportData) {
        // Implementation for achievements page
    }
}

// MARK: - Export View

struct DataExportView: View {
    @StateObject private var exportManager = DataExportManager()
    @State private var selectedFormat: ExportFormat = .json
    @State private var showingExportSheet = false
    @State private var exportURL: URL?
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Export options
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Export Format")
                            .font(.headline)
                        
                        ForEach(ExportFormat.allCases, id: \.self) { format in
                            ExportFormatOption(
                                format: format,
                                isSelected: selectedFormat == format,
                                action: { selectedFormat = format }
                            )
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(UIColor.secondarySystemBackground))
                    )
                    
                    // Data preview
                    DataPreviewCard()
                    
                    // Export button
                    Button(action: startExport) {
                        if exportManager.isExporting {
                            HStack {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                                    .scaleEffect(0.8)
                                
                                Text("Exporting...")
                            }
                        } else {
                            Label("Export Data", systemImage: "square.and.arrow.up")
                        }
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(exportManager.isExporting ? Color.gray : Color.blue)
                    )
                    .disabled(exportManager.isExporting)
                    
                    // Progress indicator
                    if exportManager.isExporting {
                        VStack(spacing: 8) {
                            ProgressView(value: exportManager.exportProgress)
                                .progressViewStyle(LinearProgressViewStyle())
                            
                            Text("\(Int(exportManager.exportProgress * 100))% complete")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Last export info
                    if let lastExport = exportManager.lastExportDate {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            
                            Text("Last exported \(lastExport, style: .relative) ago")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Export Data")
            .sheet(isPresented: $showingExportSheet) {
                if let url = exportURL {
                    ShareSheet(items: [url])
                }
            }
            .alert("Export Error", isPresented: $showingError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func startExport() {
        Task {
            do {
                exportURL = try await exportManager.exportAllData(format: selectedFormat)
                showingExportSheet = true
            } catch {
                errorMessage = error.localizedDescription
                showingError = true
            }
        }
    }
}

struct ExportFormatOption: View {
    let format: ExportFormat
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: format.icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .blue : .secondary)
                    .frame(width: 40)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(format.rawValue)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(formatDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.blue.opacity(0.1) : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var formatDescription: String {
        switch format {
        case .json:
            return "Complete data in machine-readable format"
        case .csv:
            return "Spreadsheet-compatible for analysis"
        case .pdf:
            return "Formatted report with charts and insights"
        }
    }
}

struct DataPreviewCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Data to Export", systemImage: "doc.text.magnifyingglass")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                DataPreviewRow(icon: "timer", label: "Focus Sessions", count: "1,234")
                DataPreviewRow(icon: "checklist", label: "Tasks", count: "89")
                DataPreviewRow(icon: "trophy.fill", label: "Achievements", count: "45")
                DataPreviewRow(icon: "chart.xyaxis.line", label: "Statistics", count: "All")
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.secondarySystemBackground))
        )
    }
}

struct DataPreviewRow: View {
    let icon: String
    let label: String
    let count: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 24)
            
            Text(label)
                .foregroundColor(.primary)
            
            Spacer()
            
            Text(count)
                .foregroundColor(.secondary)
                .fontWeight(.medium)
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

## 19. Enhanced Settings & Customization

```swift
// Views/EnhancedSettingsView.swift
import SwiftUI

struct EnhancedSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var settingsManager = SettingsManager()
    @StateObject private var themeManager = ThemeManager()
    @State private var selectedSection: SettingsSection = .general
    
    var body: some View {
        NavigationView {
            HStack(spacing: 0) {
                // Sidebar (iPad/Mac)
                if UIDevice.current.userInterfaceIdiom == .pad {
                    SettingsSidebar(selectedSection: $selectedSection)
                        .frame(width: 250)
                        .background(Color(UIColor.secondarySystemBackground))
                }
                
                // Content
                ScrollView {
                    VStack(spacing: 24) {
                        switch selectedSection {
                        case .general:
                            GeneralSettingsView()
                        case .focus:
                            FocusSettingsView()
                        case .notifications:
                            NotificationSettingsView()
                        case .appearance:
                            AppearanceSettingsView()
                        case .sounds:
                            SoundSettingsView()
                        case .blocking:
                            BlockingSettingsView()
                        case .widgets:
                            WidgetSettingsView()
                        case .shortcuts:
                            ShortcutSettingsView()
                        case .data:
                            DataSettingsView()
                        case .premium:
                            PremiumSettingsView()
                        case .about:
                            AboutSettingsView()
                        }
                    }
                    .padding()
                }
                .navigationTitle(selectedSection.title)
                .navigationBarTitleDisplayMode(.large)
            }
            .navigationBarItems(
                trailing: Button("Done") { dismiss() }
            )
        }
    }
}

enum SettingsSection: String, CaseIterable {
    case general = "General"
    case focus = "Focus Sessions"
    case notifications = "Notifications"
    case appearance = "Appearance"
    case sounds = "Sounds"
    case blocking = "App Blocking"
    case widgets = "Widgets"
    case shortcuts = "Shortcuts"
    case data = "Data & Privacy"
    case premium = "Premium"
    case about = "About"
    
    var title: String { rawValue }
    
    var icon: String {
        switch self {
        case .general: return "gear"
        case .focus: return "timer"
        case .notifications: return "bell"
        case .appearance: return "paintbrush"
        case .sounds: return "speaker.wave.2"
        case .blocking: return "app.badge.checkmark"
        case .widgets: return "apps.iphone"
        case .shortcuts: return "command"
        case .data: return "lock.shield"
        case .premium: return "crown"
        case .about: return "info.circle"
        }
    }
}

// MARK: - Settings Manager

class SettingsManager: ObservableObject {
    // General
    @AppStorage("userName") var userName = ""
    @AppStorage("userGoal") var userGoal = ProductivityGoal.general
    @AppStorage("weeklyGoalMinutes") var weeklyGoalMinutes = 1200
    
    // Focus
    @AppStorage("defaultFocusDuration") var defaultFocusDuration = 25
    @AppStorage("defaultBreakDuration") var defaultBreakDuration = 5
    @AppStorage("longBreakDuration") var longBreakDuration = 15
    @AppStorage("sessionsBeforeLongBreak") var sessionsBeforeLongBreak = 4
    @AppStorage("autoStartBreaks") var autoStartBreaks = false
    @AppStorage("autoStartNextSession") var autoStartNextSession = false
    
    // Notifications
    @AppStorage("notificationsEnabled") var notificationsEnabled = true
    @AppStorage("sessionCompleteNotification") var sessionCompleteNotification = true
    @AppStorage("breakReminderNotification") var breakReminderNotification = true
    @AppStorage("dailyReminderEnabled") var dailyReminderEnabled = false
    @AppStorage("dailyReminderTime") var dailyReminderTime = Date()
    @AppStorage("motivationalQuotes") var motivationalQuotes = true
    
    // Appearance
    @AppStorage("selectedTheme") var selectedTheme = 0
    @AppStorage("useSystemTheme") var useSystemTheme = true
    @AppStorage("reducedMotion") var reducedMotion = false
    @AppStorage("showParticleEffects") var showParticleEffects = true
    
    // Sounds
    @AppStorage("soundsEnabled") var soundsEnabled = true
    @AppStorage("ambientSoundsEnabled") var ambientSoundsEnabled = true
    @AppStorage("tickingSoundEnabled") var tickingSoundEnabled = false
    @AppStorage("completionSound") var completionSound = "success_1"
    @AppStorage("soundVolume") var soundVolume = 0.7
    
    // App Blocking
    @AppStorage("appBlockingEnabled") var appBlockingEnabled = false
    @AppStorage("strictModeEnabled") var strictModeEnabled = false
    @AppStorage("allowEmergencyOverride") var allowEmergencyOverride = true
    @AppStorage("blockWebsites") var blockWebsites = true
    
    // Data
    @AppStorage("iCloudSyncEnabled") var iCloudSyncEnabled = true
    @AppStorage("analyticsEnabled") var analyticsEnabled = true
    @AppStorage("crashReportingEnabled") var crashReportingEnabled = true
    
    // Advanced
    @AppStorage("developerModeEnabled") var developerModeEnabled = false
    @AppStorage("showDebugInfo") var showDebugInfo = false
}

// MARK: - General Settings

struct GeneralSettingsView: View {
    @ObservedObject private var settings = SettingsManager()
    
    var body: some View {
        VStack(spacing: 24) {
            // Profile section
            SettingsSection(title: "Profile") {
                HStack {
                    Text("Name")
                    Spacer()
                    TextField("Your name", text: $settings.userName)
                        .multilineTextAlignment(.trailing)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(maxWidth: 200)
                }
                
                HStack {
                    Text("Primary Goal")
                    Spacer()
                    Picker("Goal", selection: $settings.userGoal) {
                        ForEach([ProductivityGoal.student, .professional, .creative, .general], id: \.self) { goal in
                            Text(goal.title).tag(goal)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
            }
            
            // Weekly goal
            SettingsSection(title: "Weekly Goal") {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Target Minutes")
                        Spacer()
                        Text("\(settings.weeklyGoalMinutes) min")
                            .foregroundColor(.secondary)
                    }
                    
                    Slider(
                        value: Binding(
                            get: { Double(settings.weeklyGoalMinutes) },
                            set: { settings.weeklyGoalMinutes = Int($0) }
                        ),
                        in: 300...3000,
                        step: 100
                    )
                    
                    Text("That's about \(settings.weeklyGoalMinutes / 60) hours per week")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

// MARK: - Focus Settings

struct FocusSettingsView: View {
    @ObservedObject private var settings = SettingsManager()
    
    var body: some View {
        VStack(spacing: 24) {
            // Timer defaults
            SettingsSection(title: "Timer Defaults") {
                StepperRow(
                    title: "Focus Duration",
                    value: $settings.defaultFocusDuration,
                    range: 5...120,
                    step: 5,
                    unit: "min"
                )
                
                StepperRow(
                    title: "Break Duration",
                    value: $settings.defaultBreakDuration,
                    range: 1...30,
                    step: 1,
                    unit: "min"
                )
                
                StepperRow(
                    title: "Long Break Duration",
                    value: $settings.longBreakDuration,
                    range: 10...60,
                    step: 5,
                    unit: "min"
                )
                
                StepperRow(
                    title: "Sessions Before Long Break",
                    value: $settings.sessionsBeforeLongBreak,
                    range: 2...8,
                    step: 1,
                    unit: ""
                )
            }
            
            // Automation
            SettingsSection(title: "Automation") {
                ToggleRow(
                    title: "Auto-start Breaks",
                    subtitle: "Automatically start break timer after focus sessions",
                    isOn: $settings.autoStartBreaks
                )
                
                ToggleRow(
                    title: "Auto-start Next Session",
                    subtitle: "Continue to next focus session after breaks",
                    isOn: $settings.autoStartNextSession
                )
            }
        }
    }
}

// MARK: - Appearance Settings

struct AppearanceSettingsView: View {
    @ObservedObject private var settings = SettingsManager()
    @ObservedObject private var themeManager = ThemeManager()
    @State private var showingThemeSelector = false
    
    var body: some View {
        VStack(spacing: 24) {
            // Theme selection
            SettingsSection(title: "Theme") {
                ToggleRow(
                    title: "Use System Theme",
                    subtitle: "Automatically match your device's appearance",
                    isOn: $settings.useSystemTheme
                )
                
                if !settings.useSystemTheme {
                    Button(action: { showingThemeSelector = true }) {
                        HStack {
                            Text("App Theme")
                            Spacer()
                            
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(themeManager.currentTheme.primaryColor)
                                    .frame(width: 24, height: 24)
                                
                                Text(themeManager.currentTheme.name)
                                    .foregroundColor(.secondary)
                                
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .foregroundColor(.primary)
                }
            }
            
            // Visual effects
            SettingsSection(title: "Visual Effects") {
                ToggleRow(
                    title: "Reduced Motion",
                    subtitle: "Minimize animations throughout the app",
                    isOn: $settings.reducedMotion
                )
                
                ToggleRow(
                    title: "Particle Effects",
                    subtitle: "Show ambient particles during focus sessions",
                    isOn: $settings.showParticleEffects
                )
            }
            
            // Icon options
            SettingsSection(title: "App Icon") {
                AppIconSelector()
            }
        }
        .sheet(isPresented: $showingThemeSelector) {
            ThemeSelectorView()
        }
    }
}

// MARK: - Supporting Views

struct SettingsSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.headline)
                .foregroundColor(.secondary)
                .textCase(.uppercase)
            
            VStack(spacing: 16) {
                content
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(UIColor.secondarySystemBackground))
            )
        }
    }
}

struct ToggleRow: View {
    let title: String
    let subtitle: String?
    @Binding var isOn: Bool
    
    init(title: String, subtitle: String? = nil, isOn: Binding<Bool>) {
        self.title = title
        self.subtitle = subtitle
        self._isOn = isOn
    }
    
    var body: some View {
        Toggle(isOn: $isOn) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .foregroundColor(.primary)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .toggleStyle(SwitchToggleStyle(tint: .blue))
    }
}

struct StepperRow: View {
    let title: String
    @Binding var value: Int
    let range: ClosedRange<Int>
    let step: Int
    let unit: String
    
    var body: some View {
        HStack {
            Text(title)
            Spacer()
            
            HStack(spacing: 16) {
                Text("\(value) \(unit)")
                    .foregroundColor(.secondary)
                    .monospacedDigit()
                
                Stepper("", value: $value, in: range, step: step)
                    .labelsHidden()
            }
        }
    }
}

## 20. App Configuration & Constants

```swift
// Core/AppConfiguration.swift
import Foundation

struct AppConfiguration {
    // MARK: - App Info
    struct App {
        static let name = "Flow State"
        static let bundleId = "com.flowstate.app"
        static let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        static let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        static let appStoreId = "1234567890"
        static let supportEmail = "support@flowstate.app"
        static let privacyPolicyURL = URL(string: "https://flowstate.app/privacy")!
        static let termsOfServiceURL = URL(string: "https://flowstate.app/terms")!
    }
    
    // MARK: - API Configuration
    struct API {
        static let baseURL = "https://api.flowstate.app/v1"
        static let websocketURL = "wss://api.flowstate.app/live"
        static let timeout: TimeInterval = 30
        
        struct Headers {
            static let authorization = "Authorization"
            static let contentType = "Content-Type"
            static let userAgent = "User-Agent"
            static let apiVersion = "X-API-Version"
        }
    }
    
    // MARK: - Storage Keys
    struct Storage {
        static let userDefaults = UserDefaults(suiteName: "group.com.flowstate.app")!
        
        struct Keys {
            // User
            static let userId = "userId"
            static let userName = "userName"
            static let userEmail = "userEmail"
            static let isOnboarded = "hasSeenOnboarding"
            
            // Preferences
            static let selectedTheme = "selectedTheme"
            static let defaultFocusDuration = "defaultFocusDuration"
            static let defaultBreakDuration = "defaultBreakDuration"
            static let notificationsEnabled = "notificationsEnabled"
            static let soundsEnabled = "soundsEnabled"
            
            // Stats
            static let totalFocusMinutes = "totalFocusMinutes"
            static let currentStreak = "currentStreak"
            static let longestStreak = "longestStreak"
            static let lastSessionDate = "lastSessionDate"
            
            // Premium
            static let hasPremium = "hasPremium"
            static let premiumExpiryDate = "premiumExpiryDate"
            
            // App State
            static let activeTaskId = "activeTaskId"
            static let activeSessionStartTime = "activeSessionStartTime"
        }
    }
    
    // MARK: - Notification Identifiers
    struct Notifications {
        static let sessionComplete = "sessionComplete"
        static let breakReminder = "breakReminder"
        static let dailyReminder = "dailyReminder"
        static let achievementUnlocked = "achievementUnlocked"
        static let streakReminder = "streakReminder"
        
        struct Categories {
            static let focus = "focus"
            static let achievement = "achievement"
            static let reminder = "reminder"
        }
        
        struct Actions {
            static let startFocus = "startFocus"
            static let take5MinBreak = "take5MinBreak"
            static let take15MinBreak = "take15MinBreak"
            static let viewAchievement = "viewAchievement"
        }
    }
    
    // MARK: - Deep Links
    struct DeepLinks {
        static let scheme = "flowstate"
        
        struct Paths {
            static let home = "home"
            static let timer = "timer"
            static let startFocus = "start"
            static let tasks = "tasks"
            static let stats = "stats"
            static let achievements = "achievements"
            static let settings = "settings"
            static let premium = "premium"
        }
    }
    
    // MARK: - Widget Configuration
    struct Widgets {
        static let kind = "FlowStateWidget"
        static let displayName = "Flow State"
        static let description = "Track focus time and start sessions"
        
        struct Timeline {
            static let updateInterval: TimeInterval = 3600 // 1 hour
            static let entriesCount = 5
        }
    }
    
    // MARK: - In-App Purchase
    struct IAP {
        static let sharedSecret = "your-shared-secret"
        
        struct Products {
            static let monthlySubscription = "com.flowstate.premium.monthly"
            static let yearlySubscription = "com.flowstate.premium.yearly"
            static let lifetimePurchase = "com.flowstate.premium.lifetime"
        }
    }
    
    // MARK: - Analytics Events
    struct Analytics {
        struct Events {
            // User actions
            static let appLaunched = "app_launched"
            static let sessionStarted = "session_started"
            static let sessionCompleted = "session_completed"
            static let sessionSkipped = "session_skipped"
            static let taskCreated = "task_created"
            static let taskCompleted = "task_completed"
            
            // Feature usage
            static let ambientSoundPlayed = "ambient_sound_played"
            static let appBlockingEnabled = "app_blocking_enabled"
            static let groupJoined = "group_joined"
            static let achievementUnlocked = "achievement_unlocked"
            
            // Premium
            static let premiumViewShown = "premium_view_shown"
            static let premiumPurchased = "premium_purchased"
            static let premiumRestored = "premium_restored"
        }
        
        struct Properties {
            static let sessionDuration = "session_duration"
            static let focusMode = "focus_mode"
            static let completionRate = "completion_rate"
            static let soundType = "sound_type"
            static let groupSize = "group_size"
            static let achievementId = "achievement_id"
            static let purchaseType = "purchase_type"
        }
    }
    
    // MARK: - Limits
    struct Limits {
        static let maxTasksForFreeUsers = 5
        static let maxSessionDuration = 180 // minutes
        static let maxBreakDuration = 60 // minutes
        static let maxGroupSize = 25
        static let maxChatMessageLength = 500
        static let maxTaskTitleLength = 100
        static let maxExportSizeMB = 50
    }
    
    // MARK: - Defaults
    struct Defaults {
        static let focusDuration = 25 // minutes
        static let breakDuration = 5 // minutes
        static let longBreakDuration = 15 // minutes
        static let sessionsBeforeLongBreak = 4
        static let dailyGoalMinutes = 120
        static let weeklyGoalMinutes = 600
    }
    
    // MARK: - Feature Flags
    struct Features {
        static let aiRecommendations = true
        static let socialGroups = true
        static let advancedBlocking = true
        static let environmentalThemes = true
        static let gamification = true
        static let widgets = true
        static let shortcuts = true
        static let macOSMenuBar = true
    }
}

// MARK: - Environment Keys

struct AppEnvironment {
    static var isDebug: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }
    
    static var isTestFlight: Bool {
        guard let path = Bundle.main.appStoreReceiptURL?.path else {
            return false
        }
        return path.contains("sandboxReceipt")
    }
    
    static var isAppStore: Bool {
        !isDebug && !isTestFlight
    }
    
    static var isSimulator: Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }
}

// MARK: - App Coordinator

class AppCoordinator: ObservableObject {
    @Published var selectedTab: Int = 0
    @Published var isShowingPremium = false
    @Published var activeDeepLink: URL?
    
    static let shared = AppCoordinator()
    
    func handleDeepLink(_ url: URL) {
        guard url.scheme == AppConfiguration.DeepLinks.scheme else { return }
        
        activeDeepLink = url
        
        switch url.host {
        case AppConfiguration.DeepLinks.Paths.home:
            selectedTab = 0
        case AppConfiguration.DeepLinks.Paths.tasks:
            selectedTab = 1
        case AppConfiguration.DeepLinks.Paths.stats:
            selectedTab = 2
        case AppConfiguration.DeepLinks.Paths.premium:
            isShowingPremium = true
        case AppConfiguration.DeepLinks.Paths.startFocus:
            handleStartFocus(from: url)
        default:
            break
        }
    }
    
    private func handleStartFocus(from url: URL) {
        // Extract duration from URL path
        // flowstate://start/25
        if let durationString = url.pathComponents.last,
           let duration = Int(durationString) {
            // Start focus session with duration
            NotificationCenter.default.post(
                name: .startQuickFocus,
                object: nil,
                userInfo: ["duration": duration]
            )
        }
    }
}

extension Notification.Name {
    static let startQuickFocus = Notification.Name("startQuickFocus")
    static let sessionCompleted = Notification.Name("sessionCompleted")
    static let achievementUnlocked = Notification.Name("achievementUnlocked")
}
```
