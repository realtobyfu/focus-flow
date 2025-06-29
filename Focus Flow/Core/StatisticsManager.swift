import SwiftUI
import CoreML
import Combine
import CoreData

class StatisticsManager: ObservableObject {
    @Published var dailyStats: DailyStatistics = DailyStatistics()
    @Published var weeklyStats: WeeklyStatistics = WeeklyStatistics()
    @Published var monthlyStats: MonthlyStatistics = MonthlyStatistics()
    @Published var insights: [ProductivityInsight] = []
    @Published var trends: ProductivityTrends = ProductivityTrends()
    @Published var isAnalyzing = false
    
    private let mlModel = ProductivityMLModel()
    private let dataProcessor = StatisticsDataProcessor()
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        loadStatistics()
        scheduleAnalysis()
    }
    
    // MARK: - Data Collection
    
    func recordFocusSession(_ session: FocusSessionData) {
        // Update daily statistics
        dailyStats.addSession(session)
        
        // Update weekly and monthly aggregates
        updateAggregateStats(session)
        
        // Trigger ML analysis
        Task {
            await analyzeProductivityPatterns()
        }
        
        saveStatistics()
    }
    
    func recordBreakCompleted(duration: Int, quality: Double) {
        dailyStats.addBreak(duration: duration, quality: quality)
        saveStatistics()
    }
    
    func recordAppBlock(app: String, duration: TimeInterval) {
        dailyStats.addBlockedApp(app, duration: duration)
        saveStatistics()
    }
    
    // MARK: - ML Analysis
    
    @MainActor
    func analyzeProductivityPatterns() async {
        isAnalyzing = true
        
        do {
            // Prepare data for ML model
            let features = await prepareMLFeatures()
            
            // Run productivity analysis
            let predictions = try await mlModel.predict(features: features)
            
            // Generate insights
            let newInsights = generateInsights(from: predictions)
            
            // Update trends
            let newTrends = calculateTrends(from: predictions)
            
            await MainActor.run {
                self.insights = newInsights
                self.trends = newTrends
                self.isAnalyzing = false
            }
            
        } catch {
            print("ML Analysis failed: \(error)")
            isAnalyzing = false
        }
    }
    
    private func prepareMLFeatures() async -> MLFeatures {
        return MLFeatures(
            dailyFocusMinutes: Double(dailyStats.totalFocusTime),
            averageSessionLength: dailyStats.averageSessionLength,
            completionRate: dailyStats.completionRate,
            timeOfDay: Double(Calendar.current.component(.hour, from: Date())),
            dayOfWeek: Double(Calendar.current.component(.weekday, from: Date())),
            focusModeDistribution: getFocusModeDistribution(),
            breakQuality: dailyStats.averageBreakQuality,
            distractionsBlocked: Double(dailyStats.blockedAttempts),
            weeklyTrend: weeklyStats.focusTimeTrend,
            streakLength: Double(dailyStats.currentStreak)
        )
    }
    
    private func generateInsights(from predictions: MLPredictions) -> [ProductivityInsight] {
        var insights: [ProductivityInsight] = []
        
        // Optimal focus time insight
        if predictions.optimalFocusTime > 0 {
            insights.append(ProductivityInsight(
                type: .optimalTiming,
                title: "Optimal Focus Time",
                description: "Your most productive hours are \(formatOptimalTime(predictions.optimalFocusTime))",
                confidence: predictions.confidenceScore,
                actionable: true,
                recommendation: "Schedule important tasks during these hours"
            ))
        }
        
        // Session length optimization
        if predictions.recommendedSessionLength > 0 {
            insights.append(ProductivityInsight(
                type: .sessionOptimization,
                title: "Session Length",
                description: "Your ideal focus session is \(Int(predictions.recommendedSessionLength)) minutes",
                confidence: predictions.confidenceScore,
                actionable: true,
                recommendation: "Adjust your timer to this duration"
            ))
        }
        
        // Focus mode recommendations
        if let bestMode = predictions.recommendedFocusMode {
            insights.append(ProductivityInsight(
                type: .focusModeRecommendation,
                title: "Best Focus Mode",
                description: "\(bestMode.rawValue) works best for you at this time",
                confidence: predictions.confidenceScore,
                actionable: true,
                recommendation: "Switch to this mode for better results"
            ))
        }
        
        // Productivity patterns
        if predictions.productivityScore > 0.7 {
            insights.append(ProductivityInsight(
                type: .positivePattern,
                title: "Strong Performance",
                description: "Your productivity has improved by \(Int(predictions.improvementPercentage))%",
                confidence: predictions.confidenceScore,
                actionable: false,
                recommendation: "Keep up the great work!"
            ))
        } else if predictions.productivityScore < 0.4 {
            insights.append(ProductivityInsight(
                type: .improvementArea,
                title: "Room for Growth",
                description: "Consider adjusting your focus strategy",
                confidence: predictions.confidenceScore,
                actionable: true,
                recommendation: "Try shorter sessions or different environments"
            ))
        }
        
        return insights
    }
    
    private func calculateTrends(from predictions: MLPredictions) -> ProductivityTrends {
        return ProductivityTrends(
            focusTimeProgress: predictions.focusTimeTrend,
            completionRateProgress: predictions.completionRateTrend,
            streakStability: predictions.streakStability,
            optimalTimeShift: predictions.optimalTimeShift,
            moodCorrelation: predictions.moodProductivityCorrelation,
            weeklyEfficiency: weeklyStats.efficiencyTrend,
            predictedNextWeek: predictions.nextWeekPrediction
        )
    }
    
    // MARK: - Statistics Calculations
    
    private func updateAggregateStats(_ session: FocusSessionData) {
        // Update weekly stats
        if Calendar.current.isDate(session.startTime, equalTo: Date(), toGranularity: .weekOfYear) {
            weeklyStats.addSession(session)
        }
        
        // Update monthly stats
        if Calendar.current.isDate(session.startTime, equalTo: Date(), toGranularity: .month) {
            monthlyStats.addSession(session)
        }
    }
    
    func getCompletionRate(for period: StatisticsPeriod) -> Double {
        switch period {
        case .today:
            return dailyStats.completionRate
        case .week:
            return weeklyStats.completionRate
        case .month:
            return monthlyStats.completionRate
        }
    }
    
    func getFocusTime(for period: StatisticsPeriod) -> Int {
        switch period {
        case .today:
            return dailyStats.totalFocusTime
        case .week:
            return weeklyStats.totalFocusTime
        case .month:
            return monthlyStats.totalFocusTime
        }
    }
    
    func getProductivityScore(for period: StatisticsPeriod) -> Double {
        switch period {
        case .today:
            return dailyStats.productivityScore
        case .week:
            return weeklyStats.productivityScore
        case .month:
            return monthlyStats.productivityScore
        }
    }
    
    func getStreak() -> Int {
        return dailyStats.currentStreak
    }
    
    func getFocusModeBreakdown() -> [FocusMode: Double] {
        return dailyStats.focusModeDistribution
    }
    
    private func getFocusModeDistribution() -> [Double] {
        let total = dailyStats.focusModeDistribution.values.reduce(0, +)
        guard total > 0 else { return [0.2, 0.2, 0.2, 0.2, 0.2] } // Equal distribution fallback
        
        return FocusMode.allCases.map { mode in
            dailyStats.focusModeDistribution[mode] ?? 0 / total
        }
    }
    
    private func formatOptimalTime(_ time: Double) -> String {
        let hour = Int(time)
        let minute = Int((time - Double(hour)) * 60)
        return String(format: "%02d:%02d", hour, minute)
    }
    
    // MARK: - Persistence
    
    private func saveStatistics() {
        let encoder = JSONEncoder()
        
        if let dailyData = try? encoder.encode(dailyStats) {
            UserDefaults.standard.set(dailyData, forKey: "dailyStats")
        }
        
        if let weeklyData = try? encoder.encode(weeklyStats) {
            UserDefaults.standard.set(weeklyData, forKey: "weeklyStats")
        }
        
        if let monthlyData = try? encoder.encode(monthlyStats) {
            UserDefaults.standard.set(monthlyData, forKey: "monthlyStats")
        }
        
        if let insightsData = try? encoder.encode(insights) {
            UserDefaults.standard.set(insightsData, forKey: "insights")
        }
    }
    
    private func loadStatistics() {
        let decoder = JSONDecoder()
        
        if let dailyData = UserDefaults.standard.data(forKey: "dailyStats"),
           let daily = try? decoder.decode(DailyStatistics.self, from: dailyData) {
            dailyStats = daily
        }
        
        if let weeklyData = UserDefaults.standard.data(forKey: "weeklyStats"),
           let weekly = try? decoder.decode(WeeklyStatistics.self, from: weeklyData) {
            weeklyStats = weekly
        }
        
        if let monthlyData = UserDefaults.standard.data(forKey: "monthlyStats"),
           let monthly = try? decoder.decode(MonthlyStatistics.self, from: monthlyData) {
            monthlyStats = monthly
        }
        
        if let insightsData = UserDefaults.standard.data(forKey: "insights"),
           let savedInsights = try? decoder.decode([ProductivityInsight].self, from: insightsData) {
            insights = savedInsights
        }
    }
    
    private func scheduleAnalysis() {
        // Run analysis every hour
        Timer.publish(every: 3600, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                Task {
                    await self?.analyzeProductivityPatterns()
                }
            }
            .store(in: &cancellables)
    }
}

// MARK: - Supporting Models

struct FocusSessionData: Codable {
    let id: UUID
    let startTime: Date
    let endTime: Date
    let duration: Int
    let focusMode: FocusMode
    let completionRate: Double
    let qualityScore: Double
    let distractionsBlocked: Int
    let environmentTheme: String
    let ambientSound: String?
}

struct DailyStatistics: Codable {
    var date: Date = Date()
    var totalFocusTime: Int = 0
    var sessionsCompleted: Int = 0
    var sessionsStarted: Int = 0
    var averageSessionLength: Double = 0
    var completionRate: Double = 0
    var productivityScore: Double = 0
    var focusModeDistribution: [FocusMode: Double] = [:]
    var averageBreakQuality: Double = 0
    var blockedApps: [String: TimeInterval] = [:]
    var blockedAttempts: Int = 0
    var currentStreak: Int = 0
    
    mutating func addSession(_ session: FocusSessionData) {
        totalFocusTime += session.duration
        sessionsCompleted += 1
        
        // Update focus mode distribution
        focusModeDistribution[session.focusMode, default: 0] += Double(session.duration)
        
        // Recalculate averages
        averageSessionLength = Double(totalFocusTime) / Double(sessionsCompleted)
        completionRate = Double(sessionsCompleted) / Double(max(sessionsStarted, 1))
        
        // Update productivity score
        updateProductivityScore()
    }
    
    mutating func addBreak(duration: Int, quality: Double) {
        // Update break quality average
        averageBreakQuality = (averageBreakQuality + quality) / 2.0
    }
    
    mutating func addBlockedApp(_ app: String, duration: TimeInterval) {
        blockedApps[app, default: 0] += duration
        blockedAttempts += 1
    }
    
    private mutating func updateProductivityScore() {
        // Complex calculation considering multiple factors
        let completionWeight = 0.3
        let timeWeight = 0.2
        let qualityWeight = 0.3
        let consistencyWeight = 0.2
        
        let completionScore = completionRate
        let timeScore = min(Double(totalFocusTime) / 240.0, 1.0) // Target 4 hours
        let qualityScore = averageBreakQuality / 10.0
        let consistencyScore = Double(currentStreak) / 30.0 // Target 30-day streak
        
        productivityScore = (completionScore * completionWeight) +
                           (timeScore * timeWeight) +
                           (qualityScore * qualityWeight) +
                           (min(consistencyScore, 1.0) * consistencyWeight)
    }
}

struct WeeklyStatistics: Codable {
    var startDate: Date = Date()
    var totalFocusTime: Int = 0
    var averageDailyFocus: Double = 0
    var completionRate: Double = 0
    var productivityScore: Double = 0
    var bestDay: Date?
    var efficiencyTrend: Double = 0
    var focusTimeTrend: Double = 0
    
    mutating func addSession(_ session: FocusSessionData) {
        totalFocusTime += session.duration
        // Update other weekly metrics
    }
}

struct MonthlyStatistics: Codable {
    var month: Int = Calendar.current.component(.month, from: Date())
    var year: Int = Calendar.current.component(.year, from: Date())
    var totalFocusTime: Int = 0
    var averageWeeklyFocus: Double = 0
    var completionRate: Double = 0
    var productivityScore: Double = 0
    var bestWeek: Date?
    var growthRate: Double = 0
    
    mutating func addSession(_ session: FocusSessionData) {
        totalFocusTime += session.duration
        // Update other monthly metrics
    }
}

struct ProductivityInsight: Identifiable, Codable {
    let id = UUID()
    let type: InsightType
    let title: String
    let description: String
    let confidence: Double
    let actionable: Bool
    let recommendation: String
    let timestamp: Date = Date()
    
    enum InsightType: String, Codable {
        case optimalTiming = "optimal_timing"
        case sessionOptimization = "session_optimization"
        case focusModeRecommendation = "focus_mode_recommendation"
        case positivePattern = "positive_pattern"
        case improvementArea = "improvement_area"
        case streakMaintenance = "streak_maintenance"
        case environmentalFactors = "environmental_factors"
    }
}

struct ProductivityTrends: Codable {
    var focusTimeProgress: Double = 0
    var completionRateProgress: Double = 0
    var streakStability: Double = 0
    var optimalTimeShift: Double = 0
    var moodCorrelation: Double = 0
    var weeklyEfficiency: Double = 0
    var predictedNextWeek: Double = 0
}

enum StatisticsPeriod {
    case today, week, month
}

// MARK: - ML Models

struct MLFeatures {
    let dailyFocusMinutes: Double
    let averageSessionLength: Double
    let completionRate: Double
    let timeOfDay: Double
    let dayOfWeek: Double
    let focusModeDistribution: [Double]
    let breakQuality: Double
    let distractionsBlocked: Double
    let weeklyTrend: Double
    let streakLength: Double
}

struct MLPredictions {
    let optimalFocusTime: Double
    let recommendedSessionLength: Double
    let recommendedFocusMode: FocusMode?
    let productivityScore: Double
    let improvementPercentage: Double
    let confidenceScore: Double
    let focusTimeTrend: Double
    let completionRateTrend: Double
    let streakStability: Double
    let optimalTimeShift: Double
    let moodProductivityCorrelation: Double
    let nextWeekPrediction: Double
}

// MARK: - ML Model Implementation

class ProductivityMLModel {
    private var model: MLModel?
    
    init() {
        // Load Core ML model if available
        // Model loading would happen here if a real ML model was bundled
        self.model = nil
    }
    
    func predict(features: MLFeatures) async throws -> MLPredictions {
        // This would use the actual Core ML model
        // For now, returning simulated predictions
        
        return MLPredictions(
            optimalFocusTime: calculateOptimalTime(features),
            recommendedSessionLength: calculateOptimalSessionLength(features),
            recommendedFocusMode: determineOptimalFocusMode(features),
            productivityScore: calculateProductivityScore(features),
            improvementPercentage: calculateImprovement(features),
            confidenceScore: 0.85,
            focusTimeTrend: calculateTrend(features.dailyFocusMinutes),
            completionRateTrend: calculateTrend(features.completionRate),
            streakStability: features.streakLength / 30.0,
            optimalTimeShift: 0.0,
            moodProductivityCorrelation: 0.7,
            nextWeekPrediction: features.dailyFocusMinutes * 1.1
        )
    }
    
    private func loadProductivityModel() throws -> MLModel {
        // Load actual ML model from bundle
        throw NSError(domain: "MLModel", code: 404, userInfo: [NSLocalizedDescriptionKey: "Model not found"])
    }
    
    private func calculateOptimalTime(_ features: MLFeatures) -> Double {
        // Simple heuristic - actual model would be more sophisticated
        if features.focusModeDistribution.max() ?? 0 > 0.5 {
            return features.timeOfDay + 1.0 // Shift by 1 hour
        }
        return features.timeOfDay
    }
    
    private func calculateOptimalSessionLength(_ features: MLFeatures) -> Double {
        // Simple heuristic based on completion rate
        if features.completionRate > 0.8 {
            return min(features.averageSessionLength * 1.2, 90) // Increase by 20%, max 90 min
        } else if features.completionRate < 0.5 {
            return max(features.averageSessionLength * 0.8, 15) // Decrease by 20%, min 15 min
        }
        return features.averageSessionLength
    }
    
    private func determineOptimalFocusMode(_ features: MLFeatures) -> FocusMode? {
        // Return mode with highest usage
        let maxIndex = features.focusModeDistribution.enumerated().max { $0.element < $1.element }?.offset
        if let index = maxIndex, index < FocusMode.allCases.count {
            return FocusMode.allCases[index]
        }
        return nil
    }
    
    private func calculateProductivityScore(_ features: MLFeatures) -> Double {
        return (features.completionRate * 0.4) + 
               (min(features.dailyFocusMinutes / 240.0, 1.0) * 0.3) +
               (features.breakQuality / 10.0 * 0.3)
    }
    
    private func calculateImprovement(_ features: MLFeatures) -> Double {
        // Simulate improvement calculation
        return max(0, (features.weeklyTrend - 1.0) * 100)
    }
    
    private func calculateTrend(_ value: Double) -> Double {
        // Simple trend calculation
        return value > 0 ? 1.05 : 0.95 // 5% increase or decrease
    }
}

// MARK: - Data Processor

class StatisticsDataProcessor {
    func processSessionData(_ sessions: [FocusSessionData]) -> ProcessedStatistics {
        // Process raw session data into insights
        return ProcessedStatistics()
    }
    
    func calculateCorrelations(_ data: [String: Double]) -> [String: Double] {
        // Calculate correlations between different metrics
        return [:]
    }
    
    func identifyPatterns(_ data: [FocusSessionData]) -> [String] {
        // Identify patterns in user behavior
        return []
    }
}

struct ProcessedStatistics {
    let patterns: [String] = []
    let correlations: [String: Double] = [:]
    let anomalies: [String] = []
}