import SwiftUI
import CoreML

class AISessionRecommender: ObservableObject {
    @Published var recommendation: SessionRecommendation?
    @Published var isAnalyzing = false
    
    private let userPatternAnalyzer = UserPatternAnalyzer()
    private let contextAnalyzer = ContextAnalyzer()
    
    func analyzeAndRecommend() {
        isAnalyzing = true
        
        Task {
            let factors = await gatherAnalysisFactors()
            let recommendation = await generateRecommendation(from: factors)
            
            await MainActor.run {
                self.recommendation = recommendation
                self.isAnalyzing = false
            }
        }
    }
    
    private func gatherAnalysisFactors() async -> AnalysisFactors {
        let timeFactors = TimeFactors(
            currentTime: Date(),
            dayOfWeek: Calendar.current.component(.weekday, from: Date()),
            isWeekend: Calendar.current.isDateInWeekend(Date()),
            timeZone: TimeZone.current
        )
        
        let historicalData = await userPatternAnalyzer.analyze()
        let contextData = await contextAnalyzer.getCurrentContext()
        
        return AnalysisFactors(
            timeFactors: timeFactors,
            historicalPatterns: historicalData,
            contextualFactors: contextData,
            energyLevel: estimateEnergyLevel(from: historicalData),
            recentSessions: getRecentSessions()
        )
    }
    
    private func generateRecommendation(from factors: AnalysisFactors) async -> SessionRecommendation {
        // Simple rule-based recommendation for now
        let hour = Calendar.current.component(.hour, from: Date())
        let duration: Int
        let mode: FocusMode
        
        // Time-based recommendations
        switch hour {
        case 6...9: // Morning
            duration = 45
            mode = .deepWork
        case 10...12: // Mid-morning
            duration = 60
            mode = .deepWork
        case 13...14: // After lunch
            duration = 25
            mode = .quickSprint
        case 15...17: // Afternoon
            duration = 45
            mode = .creativeFlow
        case 18...20: // Evening
            duration = 30
            mode = .learning
        default: // Late/early hours
            duration = 25
            mode = .mindfulFocus
        }
        
        let reasoning = generateReasoning(factors: factors, duration: duration, mode: mode)
        
        return SessionRecommendation(
            focusDuration: duration,
            suggestedMode: mode,
            reasoning: reasoning,
            confidenceScore: 0.85,
            alternativeOptions: generateAlternatives(duration: duration, mode: mode)
        )
    }
    
    private func generateReasoning(factors: AnalysisFactors, duration: Int, mode: FocusMode) -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        
        switch hour {
        case 6...9:
            return "Morning hours are ideal for deep work"
        case 10...12:
            return "Peak productivity window - perfect for focused work"
        case 13...14:
            return "Post-lunch energy dip - shorter sessions work better"
        case 15...17:
            return "Afternoon creativity boost - great for flow activities"
        case 18...20:
            return "Evening wind-down - perfect for learning"
        default:
            return "Quiet hours - ideal for mindful focus"
        }
    }
    
    private func generateAlternatives(duration: Int, mode: FocusMode) -> [SessionRecommendation] {
        return [
            SessionRecommendation(
                focusDuration: 25,
                suggestedMode: .quickSprint,
                reasoning: "Quick burst of productivity",
                confidenceScore: 0.7,
                alternativeOptions: []
            ),
            SessionRecommendation(
                focusDuration: 90,
                suggestedMode: .deepWork,
                reasoning: "Extended deep work session",
                confidenceScore: 0.6,
                alternativeOptions: []
            )
        ]
    }
    
    private func estimateEnergyLevel(from patterns: HistoricalPatterns) -> Double {
        // Simplified energy estimation
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 6...10: return 0.9
        case 11...14: return 1.0
        case 15...17: return 0.7
        case 18...21: return 0.6
        default: return 0.4
        }
    }
    
    private func getRecentSessions() -> [FocusSession] {
        // Return recent sessions from storage
        return []
    }
}

// MARK: - Supporting Models

struct SessionRecommendation {
    let focusDuration: Int
    let suggestedMode: FocusMode
    let reasoning: String
    let confidenceScore: Double
    let alternativeOptions: [SessionRecommendation]
}

enum FocusMode: String, CaseIterable {
    case deepWork = "Deep Work"
    case creativeFlow = "Creative Flow"
    case learning = "Learning"
    case quickSprint = "Quick Sprint"
    case mindfulFocus = "Mindful Focus"
    
    var icon: String {
        switch self {
        case .deepWork: return "brain.head.profile"
        case .creativeFlow: return "paintbrush.fill"
        case .learning: return "book.fill"
        case .quickSprint: return "bolt.fill"
        case .mindfulFocus: return "leaf.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .deepWork: return .blue
        case .creativeFlow: return .purple
        case .learning: return .green
        case .quickSprint: return .orange
        case .mindfulFocus: return .mint
        }
    }
    
    var displayName: String { rawValue }
    var shortName: String { rawValue.components(separatedBy: " ").first ?? rawValue }
    
    var hasParticleEffects: Bool {
        switch self {
        case .creativeFlow, .mindfulFocus: return true
        default: return false
        }
    }
    
    var hasAmbientSound: Bool { true }
    
    var ambientSound: String? {
        switch self {
        case .deepWork: return "deep_space"
        case .creativeFlow: return "aurora_waves"
        case .learning: return "library_ambience"
        case .quickSprint: return "energetic_beats"
        case .mindfulFocus: return "zen_garden"
        }
    }
    
    var gradientColors: [Color] {
        switch self {
        case .deepWork: return [.blue, .indigo]
        case .creativeFlow: return [.purple, .pink]
        case .learning: return [.green, .teal]
        case .quickSprint: return [.orange, .red]
        case .mindfulFocus: return [.mint, .cyan]
        }
    }
    
    var accentColor: Color { color }
    var requiresStrictBlocking: Bool { self == .deepWork }
}

struct AnalysisFactors {
    let timeFactors: TimeFactors
    let historicalPatterns: HistoricalPatterns
    let contextualFactors: ContextualFactors
    let energyLevel: Double
    let recentSessions: [FocusSession]
}

struct TimeFactors {
    let currentTime: Date
    let dayOfWeek: Int
    let isWeekend: Bool
    let timeZone: TimeZone
}

struct HistoricalPatterns {
    let averageCompletedDuration: Int?
    let preferredModes: [FocusMode]
    let completionRateByDuration: [Int: Double]
    let productiveHours: [Int]
    let streakData: StreakData
}

struct ContextualFactors {
    let deviceBatteryLevel: Float
    let isCharging: Bool
    let networkConnectivity: Bool
    let calendarEvents: [CalendarEvent]
}

struct StreakData {
    let current: Int
    let longest: Int
    let lastSessionDate: Date?
}

struct FocusSession {
    let id: String
    let startTime: Date
    let duration: Int
    let mode: FocusMode
    let completionRate: Double
    let qualityScore: Double
}

struct CalendarEvent {
    let title: String
    let startTime: Date
    let endTime: Date
}

// MARK: - User Pattern Analyzer

class UserPatternAnalyzer {
    func analyze() async -> HistoricalPatterns {
        // Simulate analysis of user patterns
        return HistoricalPatterns(
            averageCompletedDuration: 35,
            preferredModes: [.deepWork, .creativeFlow],
            completionRateByDuration: [
                25: 0.9,
                45: 0.7,
                60: 0.6,
                90: 0.4
            ],
            productiveHours: [9, 10, 14, 15],
            streakData: StreakData(
                current: 5,
                longest: 12,
                lastSessionDate: Date().addingTimeInterval(-86400)
            )
        )
    }
}

// MARK: - Context Analyzer

class ContextAnalyzer {
    func getCurrentContext() async -> ContextualFactors {
        return ContextualFactors(
            deviceBatteryLevel: UIDevice.current.batteryLevel,
            isCharging: UIDevice.current.batteryState == .charging,
            networkConnectivity: true, // Simplified
            calendarEvents: []
        )
    }
}