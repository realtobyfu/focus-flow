import WidgetKit
import SwiftUI
import Intents
import AppIntents

// MARK: - Widget Provider

struct FocusWidgetProvider: IntentTimelineProvider {
    typealias Entry = FocusWidgetEntry
    typealias Intent = FocusWidgetConfigurationIntent
    
    func placeholder(in context: Context) -> FocusWidgetEntry {
        FocusWidgetEntry(
            date: Date(),
            configuration: FocusWidgetConfigurationIntent(),
            todayFocusTime: 125,
            currentStreak: 7,
            nextSession: "Deep Work in 30 min",
            activeSession: nil,
            productivityScore: 0.85,
            gardenLevel: 5,
            weeklyGoal: 600,
            weeklyProgress: 425
        )
    }
    
    func getSnapshot(for configuration: FocusWidgetConfigurationIntent, in context: Context, completion: @escaping (FocusWidgetEntry) -> Void) {
        let entry = createEntry(for: configuration)
        completion(entry)
    }
    
    func getTimeline(for configuration: FocusWidgetConfigurationIntent, in context: Context, completion: @escaping (Timeline<FocusWidgetEntry>) -> Void) {
        var entries: [FocusWidgetEntry] = []
        
        // Generate timeline entries for the next 4 hours
        let currentDate = Date()
        for hourOffset in 0..<4 {
            let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
            let entry = createEntry(for: configuration, date: entryDate)
            entries.append(entry)
        }
        
        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
    
    private func createEntry(for configuration: FocusWidgetConfigurationIntent, date: Date = Date()) -> FocusWidgetEntry {
        let sharedDefaults = UserDefaults(suiteName: "group.com.focusflow.app")
        
        return FocusWidgetEntry(
            date: date,
            configuration: configuration,
            todayFocusTime: sharedDefaults?.integer(forKey: "todayFocusMinutes") ?? 0,
            currentStreak: sharedDefaults?.integer(forKey: "currentStreak") ?? 0,
            nextSession: sharedDefaults?.string(forKey: "nextScheduledSession"),
            activeSession: getActiveSession(from: sharedDefaults),
            productivityScore: sharedDefaults?.double(forKey: "productivityScore") ?? 0.0,
            gardenLevel: sharedDefaults?.integer(forKey: "gardenLevel") ?? 1,
            weeklyGoal: sharedDefaults?.integer(forKey: "weeklyGoalMinutes") ?? 600,
            weeklyProgress: sharedDefaults?.integer(forKey: "weeklyProgressMinutes") ?? 0
        )
    }
    
    private func getActiveSession(from userDefaults: UserDefaults?) -> ActiveSessionInfo? {
        guard let data = userDefaults?.data(forKey: "activeSession"),
              let session = try? JSONDecoder().decode(ActiveSessionInfo.self, from: data) else {
            return nil
        }
        return session
    }
}

// MARK: - Widget Entry

struct FocusWidgetEntry: TimelineEntry {
    let date: Date
    let configuration: FocusWidgetConfigurationIntent
    let todayFocusTime: Int
    let currentStreak: Int
    let nextSession: String?
    let activeSession: ActiveSessionInfo?
    let productivityScore: Double
    let gardenLevel: Int
    let weeklyGoal: Int
    let weeklyProgress: Int
}

struct ActiveSessionInfo: Codable {
    let title: String
    let timeRemaining: Int
    let totalDuration: Int
    let focusMode: String
    let startTime: Date
    
    var progress: Double {
        let elapsed = totalDuration - timeRemaining
        return Double(elapsed) / Double(totalDuration)
    }
    
    var formattedTimeRemaining: String {
        let minutes = timeRemaining / 60
        let seconds = timeRemaining % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

// MARK: - Widget Views

struct FocusWidget: Widget {
    let kind: String = "FocusWidget"
    
    var body: some WidgetConfiguration {
        IntentConfiguration(kind: kind, intent: FocusWidgetConfigurationIntent.self, provider: FocusWidgetProvider()) { entry in
            FocusWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Focus Flow")
        .description("Track your focus sessions and productivity.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct FocusWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    var entry: FocusWidgetProvider.Entry
    
    var body: some View {
        switch family {
        case .systemSmall:
            SmallFocusWidget(entry: entry)
        case .systemMedium:
            MediumFocusWidget(entry: entry)
        case .systemLarge:
            LargeFocusWidget(entry: entry)
        default:
            SmallFocusWidget(entry: entry)
        }
    }
}

// MARK: - Small Widget

struct SmallFocusWidget: View {
    let entry: FocusWidgetEntry
    
    var body: some View {
        VStack(spacing: 8) {
            if let activeSession = entry.activeSession {
                // Active session view
                VStack(spacing: 4) {
                    Text("FOCUS")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                    
                    Text(activeSession.formattedTimeRemaining)
                        .font(.title2)
                        .fontWeight(.bold)
                        .monospacedDigit()
                    
                    Text(activeSession.title)
                        .font(.caption)
                        .lineLimit(1)
                        .foregroundColor(.secondary)
                }
                
                // Progress ring
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 4)
                    
                    Circle()
                        .trim(from: 0, to: activeSession.progress)
                        .stroke(Color.orange, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                }
                .frame(height: 30)
                
            } else {
                // Stats view
                VStack(spacing: 4) {
                    HStack {
                        Image(systemName: "target")
                            .foregroundColor(.blue)
                        Text("\(entry.todayFocusTime)m")
                            .fontWeight(.semibold)
                        Spacer()
                    }
                    
                    HStack {
                        Image(systemName: "flame.fill")
                            .foregroundColor(.orange)
                        Text("\(entry.currentStreak) days")
                            .fontWeight(.semibold)
                        Spacer()
                    }
                    
                    HStack {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .foregroundColor(.green)
                        Text("\(Int(entry.productivityScore * 100))%")
                            .fontWeight(.semibold)
                        Spacer()
                    }
                }
                .font(.caption)
                
                if let nextSession = entry.nextSession {
                    Text(nextSession)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
    }
}

// MARK: - Medium Widget

struct MediumFocusWidget: View {
    let entry: FocusWidgetEntry
    
    var body: some View {
        HStack(spacing: 16) {
            // Left side - Main info
            VStack(alignment: .leading, spacing: 8) {
                if let activeSession = entry.activeSession {
                    // Active session
                    VStack(alignment: .leading, spacing: 4) {
                        Text("ACTIVE SESSION")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.orange)
                        
                        Text(activeSession.title)
                            .font(.headline)
                            .lineLimit(1)
                        
                        Text(activeSession.formattedTimeRemaining)
                            .font(.title)
                            .fontWeight(.bold)
                            .monospacedDigit()
                        
                        Text(activeSession.focusMode)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                } else {
                    // Today's stats
                    VStack(alignment: .leading, spacing: 4) {
                        Text("TODAY")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                        
                        Text("\(entry.todayFocusTime) minutes")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        if let nextSession = entry.nextSession {
                            Text(nextSession)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                        }
                    }
                }
                
                Spacer()
            }
            
            // Right side - Secondary info
            VStack(alignment: .trailing, spacing: 12) {
                // Streak
                VStack(alignment: .trailing, spacing: 2) {
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .foregroundColor(.orange)
                        Text("\(entry.currentStreak)")
                            .fontWeight(.bold)
                    }
                    Text("day streak")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                // Garden level
                VStack(alignment: .trailing, spacing: 2) {
                    HStack(spacing: 4) {
                        Image(systemName: "leaf.fill")
                            .foregroundColor(.green)
                        Text("Lv. \(entry.gardenLevel)")
                            .fontWeight(.bold)
                    }
                    Text("garden")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                // Weekly progress
                VStack(alignment: .trailing, spacing: 2) {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .foregroundColor(.purple)
                        Text("\(entry.weeklyProgress)m")
                            .fontWeight(.bold)
                    }
                    Text("this week")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .font(.caption)
        }
        .padding()
        .background(Color(UIColor.systemBackground))
    }
}

// MARK: - Large Widget

struct LargeFocusWidget: View {
    let entry: FocusWidgetEntry
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Text("Focus Flow")
                    .font(.headline)
                    .fontWeight(.bold)
                
                Spacer()
                
                if let activeSession = entry.activeSession {
                    Text("ACTIVE")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color.orange))
                }
            }
            
            if let activeSession = entry.activeSession {
                // Active session details
                VStack(spacing: 12) {
                    Text(activeSession.title)
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text(activeSession.formattedTimeRemaining)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .monospacedDigit()
                    
                    // Progress bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(height: 8)
                                .cornerRadius(4)
                            
                            Rectangle()
                                .fill(Color.orange)
                                .frame(width: geometry.size.width * activeSession.progress, height: 8)
                                .cornerRadius(4)
                        }
                    }
                    .frame(height: 8)
                    
                    Text("\(Int(activeSession.progress * 100))% complete")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
            } else {
                // Statistics grid
                HStack(spacing: 16) {
                    StatCard(
                        title: "Today",
                        value: "\(entry.todayFocusTime)m",
                        icon: "target",
                        color: .blue
                    )
                    
                    StatCard(
                        title: "Streak",
                        value: "\(entry.currentStreak)",
                        icon: "flame.fill",
                        color: .orange
                    )
                }
                
                HStack(spacing: 16) {
                    StatCard(
                        title: "Garden",
                        value: "Lv. \(entry.gardenLevel)",
                        icon: "leaf.fill",
                        color: .green
                    )
                    
                    StatCard(
                        title: "Score",
                        value: "\(Int(entry.productivityScore * 100))%",
                        icon: "chart.line.uptrend.xyaxis",
                        color: .purple
                    )
                }
                
                // Weekly progress
                VStack(spacing: 8) {
                    HStack {
                        Text("Weekly Goal")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Spacer()
                        
                        Text("\(entry.weeklyProgress) / \(entry.weeklyGoal) min")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(height: 6)
                                .cornerRadius(3)
                            
                            Rectangle()
                                .fill(Color.blue)
                                .frame(width: geometry.size.width * min(1.0, Double(entry.weeklyProgress) / Double(entry.weeklyGoal)), height: 6)
                                .cornerRadius(3)
                        }
                    }
                    .frame(height: 6)
                }
            }
            
            Spacer()
        }
        .padding()
        .background(Color(UIColor.systemBackground))
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title3)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.title3)
                    .fontWeight(.bold)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(UIColor.secondarySystemBackground))
        )
    }
}

// MARK: - Intent Configuration

class FocusWidgetConfigurationIntent: INIntent {
    // Widget configuration options would go here
    // For example: widget style, data to display, etc.
}

// MARK: - Widget Bundle

struct FocusWidgetBundle: WidgetBundle {
    var body: some Widget {
        FocusWidget()
        ProductivityWidget()
        QuickActionWidget()
    }
}

// MARK: - Additional Widget Types

struct ProductivityWidget: Widget {
    let kind: String = "ProductivityWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ProductivityProvider()) { entry in
            ProductivityWidgetView(entry: entry)
        }
        .configurationDisplayName("Productivity Stats")
        .description("View your productivity insights at a glance.")
        .supportedFamilies([.systemMedium])
    }
}

struct ProductivityProvider: TimelineProvider {
    func placeholder(in context: Context) -> ProductivityEntry {
        ProductivityEntry(date: Date(), weeklyFocus: 280, productivity: 0.85, improvement: 15)
    }
    
    func getSnapshot(in context: Context, completion: @escaping (ProductivityEntry) -> Void) {
        let entry = ProductivityEntry(date: Date(), weeklyFocus: 280, productivity: 0.85, improvement: 15)
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<ProductivityEntry>) -> Void) {
        let entries = [ProductivityEntry(date: Date(), weeklyFocus: 280, productivity: 0.85, improvement: 15)]
        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

struct ProductivityEntry: TimelineEntry {
    let date: Date
    let weeklyFocus: Int
    let productivity: Double
    let improvement: Int
}

struct ProductivityWidgetView: View {
    let entry: ProductivityEntry
    
    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("This Week")
                    .font(.headline)
                    .fontWeight(.bold)
                
                HStack {
                    Image(systemName: "clock.fill")
                        .foregroundColor(.blue)
                    Text("\(entry.weeklyFocus) min")
                        .font(.title2)
                        .fontWeight(.semibold)
                }
                
                HStack {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .foregroundColor(.green)
                    Text("\(Int(entry.productivity * 100))% efficiency")
                        .font(.subheadline)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 8) {
                Text("Improvement")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("+\(entry.improvement)%")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.green)
                
                Image(systemName: "arrow.up.right")
                    .foregroundColor(.green)
                    .font(.title2)
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
    }
}

// MARK: - Quick Action Widget

struct QuickActionWidget: Widget {
    let kind: String = "QuickActionWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: QuickActionProvider()) { entry in
            QuickActionWidgetView(entry: entry)
        }
        .configurationDisplayName("Quick Actions")
        .description("Start focus sessions quickly.")
        .supportedFamilies([.systemSmall])
    }
}

struct QuickActionProvider: TimelineProvider {
    func placeholder(in context: Context) -> QuickActionEntry {
        QuickActionEntry(date: Date(), suggestedDuration: 25, suggestedMode: "Deep Work")
    }
    
    func getSnapshot(in context: Context, completion: @escaping (QuickActionEntry) -> Void) {
        let entry = QuickActionEntry(date: Date(), suggestedDuration: 25, suggestedMode: "Deep Work")
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<QuickActionEntry>) -> Void) {
        let entries = [QuickActionEntry(date: Date(), suggestedDuration: 25, suggestedMode: "Deep Work")]
        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

struct QuickActionEntry: TimelineEntry {
    let date: Date
    let suggestedDuration: Int
    let suggestedMode: String
}

struct QuickActionWidgetView: View {
    let entry: QuickActionEntry
    
    var body: some View {
        VStack(spacing: 12) {
            VStack(spacing: 4) {
                Text("Quick Start")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.orange)
                
                Text("\(entry.suggestedDuration) min")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(entry.suggestedMode)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            if #available(iOS 17.0, *) {
                Button(intent: StartFocusIntent(duration: entry.suggestedDuration)) {
                    HStack {
                        Image(systemName: "play.fill")
                        Text("Start")
                    }
                    .font(.caption)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(Color.orange))
                }
            } else {
                // Fallback on earlier versions
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
    }
}

// MARK: - App Intents

struct StartFocusIntent: AppIntent {
    static var title: LocalizedStringResource = "Start Focus Session"
    
    @Parameter(title: "Duration")
    var duration: Int
    
    init() {
        duration = 25
    }
    
    init(duration: Int) {
        self.duration = duration
    }
    
    func perform() async throws -> some IntentResult {
        // This would open the app and start a focus session
        return .result()
    }
}
