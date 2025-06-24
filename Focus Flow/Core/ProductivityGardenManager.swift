import SwiftUI
import Combine
import CoreData

class ProductivityGardenManager: ObservableObject {
    @Published var garden: ProductivityGarden
    @Published var plants: [GardenPlant] = []
    @Published var dailyProgress: DailyProgress
    @Published var achievements: [Achievement] = []
    @Published var isWatering = false
    @Published var showAchievement: Achievement?
    
    private let userDefaults = UserDefaults.standard
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        self.garden = ProductivityGarden()
        self.dailyProgress = DailyProgress()
        loadGardenState()
        setupDailyReset()
    }
    
    // MARK: - Garden Management
    
    func waterPlant(for minutes: Int, focusMode: FocusMode) {
        isWatering = true
        
        // Find or create plant for this focus mode
        if let existingPlant = plants.first(where: { $0.focusMode == focusMode }) {
            existingPlant.water(minutes: minutes)
        } else {
            let newPlant = GardenPlant(focusMode: focusMode)
            newPlant.water(minutes: minutes)
            plants.append(newPlant)
        }
        
        // Update daily progress
        dailyProgress.addFocusTime(minutes, mode: focusMode)
        
        // Check for achievements
        checkForAchievements()
        
        // Update garden level
        garden.addExperience(minutes * 10)
        
        // Save state
        saveGardenState()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.isWatering = false
            HapticStyle.success.trigger()
        }
    }
    
    func harvestPlant(_ plant: GardenPlant) {
        guard plant.canHarvest else { return }
        
        let reward = plant.harvest()
        garden.addSeeds(reward.seeds)
        
        // Check for harvest achievement
        if let achievement = Achievement.allAchievements.first(where: { 
            $0.id == "first_harvest" && !achievements.contains($0) 
        }) {
            unlockAchievement(achievement)
        }
        
        saveGardenState()
        HapticStyle.success.trigger()
    }
    
    func plantSeed(type: PlantType, in slot: Int) {
        guard garden.seeds >= type.seedCost else { return }
        guard slot < garden.maxPlants else { return }
        
        // Ensure we have enough slots
        while plants.count <= slot {
            plants.append(GardenPlant(focusMode: .deepWork))
        }
        
        // Replace plant at slot
        plants[slot] = GardenPlant(focusMode: type.associatedFocusMode, plantType: type)
        garden.spendSeeds(type.seedCost)
        
        saveGardenState()
        HapticStyle.medium.trigger()
    }
    
    // MARK: - Achievements
    
    private func checkForAchievements() {
        let unlockedAchievements = Achievement.checkAchievements(
            dailyProgress: dailyProgress,
            garden: garden,
            plants: plants
        )
        
        for achievement in unlockedAchievements {
            if !achievements.contains(achievement) {
                unlockAchievement(achievement)
            }
        }
    }
    
    private func unlockAchievement(_ achievement: Achievement) {
        achievements.append(achievement)
        showAchievement = achievement
        garden.addExperience(achievement.experienceReward)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            self.showAchievement = nil
        }
        
        HapticStyle.success.trigger()
    }
    
    // MARK: - Persistence
    
    private func saveGardenState() {
        if let gardenData = try? JSONEncoder().encode(garden) {
            userDefaults.set(gardenData, forKey: "productivityGarden")
        }
        
        if let plantsData = try? JSONEncoder().encode(plants) {
            userDefaults.set(plantsData, forKey: "gardenPlants")
        }
        
        if let progressData = try? JSONEncoder().encode(dailyProgress) {
            userDefaults.set(progressData, forKey: "dailyProgress")
        }
        
        if let achievementsData = try? JSONEncoder().encode(achievements) {
            userDefaults.set(achievementsData, forKey: "achievements")
        }
    }
    
    private func loadGardenState() {
        // Load garden
        if let gardenData = userDefaults.data(forKey: "productivityGarden"),
           let savedGarden = try? JSONDecoder().decode(ProductivityGarden.self, from: gardenData) {
            self.garden = savedGarden
        }
        
        // Load plants
        if let plantsData = userDefaults.data(forKey: "gardenPlants"),
           let savedPlants = try? JSONDecoder().decode([GardenPlant].self, from: plantsData) {
            self.plants = savedPlants
        }
        
        // Load daily progress
        if let progressData = userDefaults.data(forKey: "dailyProgress"),
           let savedProgress = try? JSONDecoder().decode(DailyProgress.self, from: progressData) {
            self.dailyProgress = savedProgress
        }
        
        // Load achievements
        if let achievementsData = userDefaults.data(forKey: "achievements"),
           let savedAchievements = try? JSONDecoder().decode([Achievement].self, from: achievementsData) {
            self.achievements = savedAchievements
        }
    }
    
    private func setupDailyReset() {
        Timer.publish(every: 3600, on: .main, in: .common) // Check every hour
            .autoconnect()
            .sink { [weak self] _ in
                self?.checkDailyReset()
            }
            .store(in: &cancellables)
    }
    
    private func checkDailyReset() {
        let calendar = Calendar.current
        let today = Date()
        
        if !calendar.isDate(dailyProgress.date, inSameDayAs: today) {
            // Reset daily progress
            dailyProgress = DailyProgress()
            saveGardenState()
        }
    }
}

// MARK: - Garden Models

class ProductivityGarden: ObservableObject, Codable {
    @Published var level: Int = 1
    @Published var experience: Int = 0
    @Published var seeds: Int = 10
    @Published var totalFocusHours: Double = 0
    
    var experienceToNextLevel: Int {
        return level * 100
    }
    
    var maxPlants: Int {
        return min(6, 2 + (level / 5)) // Start with 2, add 1 every 5 levels, max 6
    }
    
    enum CodingKeys: CodingKey {
        case level, experience, seeds, totalFocusHours
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        level = try container.decode(Int.self, forKey: .level)
        experience = try container.decode(Int.self, forKey: .experience)
        seeds = try container.decode(Int.self, forKey: .seeds)
        totalFocusHours = try container.decode(Double.self, forKey: .totalFocusHours)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(level, forKey: .level)
        try container.encode(experience, forKey: .experience)
        try container.encode(seeds, forKey: .seeds)
        try container.encode(totalFocusHours, forKey: .totalFocusHours)
    }
    
    init() {}
    
    func addExperience(_ amount: Int) {
        experience += amount
        
        while experience >= experienceToNextLevel {
            experience -= experienceToNextLevel
            level += 1
            seeds += 5 // Bonus seeds for leveling up
        }
    }
    
    func addSeeds(_ amount: Int) {
        seeds += amount
    }
    
    func spendSeeds(_ amount: Int) {
        seeds = max(0, seeds - amount)
    }
    
    func addFocusTime(_ minutes: Int) {
        totalFocusHours += Double(minutes) / 60.0
    }
}

class GardenPlant: ObservableObject, Codable, Identifiable {
    let id = UUID()
    @Published var focusMode: FocusMode
    @Published var plantType: PlantType
    @Published var growth: Double = 0.0
    @Published var waterLevel: Double = 100.0
    @Published var lastWatered: Date = Date()
    @Published var totalCareTime: Int = 0
    
    var growthStage: GrowthStage {
        switch growth {
        case 0..<0.25: return .seedling
        case 0.25..<0.5: return .young
        case 0.5..<0.75: return .mature
        case 0.75..<1.0: return .blooming
        default: return .harvestable
        }
    }
    
    var canHarvest: Bool {
        return growth >= 1.0
    }
    
    var healthColor: Color {
        switch waterLevel {
        case 80...100: return .green
        case 50..<80: return .yellow
        case 20..<50: return .orange
        default: return .red
        }
    }
    
    enum CodingKeys: CodingKey {
        case focusMode, plantType, growth, waterLevel, lastWatered, totalCareTime
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        focusMode = try container.decode(FocusMode.self, forKey: .focusMode)
        plantType = try container.decode(PlantType.self, forKey: .plantType)
        growth = try container.decode(Double.self, forKey: .growth)
        waterLevel = try container.decode(Double.self, forKey: .waterLevel)
        lastWatered = try container.decode(Date.self, forKey: .lastWatered)
        totalCareTime = try container.decode(Int.self, forKey: .totalCareTime)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(focusMode, forKey: .focusMode)
        try container.encode(plantType, forKey: .plantType)
        try container.encode(growth, forKey: .growth)
        try container.encode(waterLevel, forKey: .waterLevel)
        try container.encode(lastWatered, forKey: .lastWatered)
        try container.encode(totalCareTime, forKey: .totalCareTime)
    }
    
    init(focusMode: FocusMode, plantType: PlantType = .defaultPlant) {
        self.focusMode = focusMode
        self.plantType = plantType
    }
    
    func water(minutes: Int) {
        totalCareTime += minutes
        waterLevel = min(100, waterLevel + Double(minutes) * 2)
        
        // Growth based on care time and plant type
        let growthRate = plantType.growthRate * (waterLevel / 100.0)
        growth = min(1.0, growth + (Double(minutes) * growthRate / 1000.0))
        
        lastWatered = Date()
    }
    
    func harvest() -> HarvestReward {
        let seeds = Int(growth * Double(plantType.harvestSeeds))
        let experience = plantType.harvestExperience
        
        // Reset plant
        growth = 0
        waterLevel = 100
        totalCareTime = 0
        
        return HarvestReward(seeds: seeds, experience: experience)
    }
    
    func updateWaterLevel() {
        let hoursSinceWatered = Date().timeIntervalSince(lastWatered) / 3600
        let decay = hoursSinceWatered * 5 // 5% per hour
        waterLevel = max(0, waterLevel - decay)
    }
}

struct HarvestReward {
    let seeds: Int
    let experience: Int
}

enum GrowthStage: String, CaseIterable {
    case seedling = "<1"
    case young = "<?"
    case mature = "<3"
    case blooming = "<8"
    case harvestable = "<N"
    
    var description: String {
        switch self {
        case .seedling: return "Seedling"
        case .young: return "Young Plant"
        case .mature: return "Mature Plant"
        case .blooming: return "Blooming"
        case .harvestable: return "Ready to Harvest"
        }
    }
}

enum PlantType: String, CaseIterable, Codable {
    case defaultPlant = "Basic Plant"
    case focusTree = "Focus Tree"
    case creativeBush = "Creative Bush"
    case learningVine = "Learning Vine"
    case speedFlower = "Speed Flower"
    case mindfulLotus = "Mindful Lotus"
    
    var associatedFocusMode: FocusMode {
        switch self {
        case .defaultPlant, .focusTree: return .deepWork
        case .creativeBush: return .creativeFlow
        case .learningVine: return .learning
        case .speedFlower: return .quickSprint
        case .mindfulLotus: return .mindfulFocus
        }
    }
    
    var growthRate: Double {
        switch self {
        case .defaultPlant: return 1.0
        case .focusTree: return 0.8
        case .creativeBush: return 1.2
        case .learningVine: return 1.0
        case .speedFlower: return 1.5
        case .mindfulLotus: return 0.6
        }
    }
    
    var seedCost: Int {
        switch self {
        case .defaultPlant: return 0
        case .focusTree: return 10
        case .creativeBush: return 8
        case .learningVine: return 8
        case .speedFlower: return 5
        case .mindfulLotus: return 15
        }
    }
    
    var harvestSeeds: Int {
        switch self {
        case .defaultPlant: return 3
        case .focusTree: return 15
        case .creativeBush: return 12
        case .learningVine: return 12
        case .speedFlower: return 8
        case .mindfulLotus: return 20
        }
    }
    
    var harvestExperience: Int {
        return harvestSeeds * 5
    }
    
    var icon: String {
        switch self {
        case .defaultPlant: return "<1"
        case .focusTree: return "<3"
        case .creativeBush: return "<:"
        case .learningVine: return "<C"
        case .speedFlower: return "¡"
        case .mindfulLotus: return ">·"
        }
    }
    
    var color: Color {
        return associatedFocusMode.color
    }
}

struct DailyProgress: Codable {
    var date: Date = Date()
    var totalFocusMinutes: Int = 0
    var sessionCount: Int = 0
    var focusModeMinutes: [FocusMode: Int] = [:]
    var longestSession: Int = 0
    var currentStreak: Int = 0
    
    mutating func addFocusTime(_ minutes: Int, mode: FocusMode) {
        totalFocusMinutes += minutes
        sessionCount += 1
        focusModeMinutes[mode, default: 0] += minutes
        longestSession = max(longestSession, minutes)
        
        // Update streak logic would go here
        if totalFocusMinutes >= 25 { // Minimum for streak
            currentStreak += 1
        }
    }
    
    var focusHours: Double {
        return Double(totalFocusMinutes) / 60.0
    }
}

struct Achievement: Identifiable, Codable, Equatable {
    let id: String
    let title: String
    let description: String
    let icon: String
    let experienceReward: Int
    let requirement: AchievementRequirement
    
    static func == (lhs: Achievement, rhs: Achievement) -> Bool {
        return lhs.id == rhs.id
    }
    
    enum AchievementRequirement: Codable {
        case firstSession
        case dailyGoal(minutes: Int)
        case streak(days: Int)
        case totalHours(hours: Int)
        case plantGrowth(count: Int)
        case gardenLevel(level: Int)
        case focusMode(mode: FocusMode, sessions: Int)
    }
    
    static let allAchievements: [Achievement] = [
        Achievement(
            id: "first_session",
            title: "First Steps",
            description: "Complete your first focus session",
            icon: "<1",
            experienceReward: 50,
            requirement: .firstSession
        ),
        Achievement(
            id: "daily_goal_1h",
            title: "Daily Dedication",
            description: "Focus for 1 hour in a single day",
            icon: "ð",
            experienceReward: 100,
            requirement: .dailyGoal(minutes: 60)
        ),
        Achievement(
            id: "streak_7",
            title: "Week Warrior",
            description: "Maintain a 7-day focus streak",
            icon: "=%",
            experienceReward: 200,
            requirement: .streak(days: 7)
        ),
        Achievement(
            id: "total_10h",
            title: "Focus Master",
            description: "Accumulate 10 hours of total focus time",
            icon: "<Æ",
            experienceReward: 300,
            requirement: .totalHours(hours: 10)
        ),
        Achievement(
            id: "first_harvest",
            title: "Green Thumb",
            description: "Harvest your first plant",
            icon: "<>",
            experienceReward: 150,
            requirement: .plantGrowth(count: 1)
        ),
        Achievement(
            id: "garden_level_5",
            title: "Garden Guardian",
            description: "Reach garden level 5",
            icon: "<;",
            experienceReward: 250,
            requirement: .gardenLevel(level: 5)
        )
    ]
    
    static func checkAchievements(dailyProgress: DailyProgress, garden: ProductivityGarden, plants: [GardenPlant]) -> [Achievement] {
        var achieved: [Achievement] = []
        
        for achievement in allAchievements {
            switch achievement.requirement {
            case .firstSession:
                if dailyProgress.sessionCount > 0 {
                    achieved.append(achievement)
                }
            case .dailyGoal(let minutes):
                if dailyProgress.totalFocusMinutes >= minutes {
                    achieved.append(achievement)
                }
            case .streak(let days):
                if dailyProgress.currentStreak >= days {
                    achieved.append(achievement)
                }
            case .totalHours(let hours):
                if garden.totalFocusHours >= Double(hours) {
                    achieved.append(achievement)
                }
            case .plantGrowth(let count):
                let harvestableCount = plants.filter { $0.canHarvest }.count
                if harvestableCount >= count {
                    achieved.append(achievement)
                }
            case .gardenLevel(let level):
                if garden.level >= level {
                    achieved.append(achievement)
                }
            case .focusMode(let mode, let sessions):
                let modeMinutes = dailyProgress.focusModeMinutes[mode] ?? 0
                let estimatedSessions = modeMinutes / 25 // Assuming 25min average
                if estimatedSessions >= sessions {
                    achieved.append(achievement)
                }
            }
        }
        
        return achieved
    }
}