import Foundation

// MARK: - Virtual Plant Model
struct VirtualPlant: Identifiable {
    let id = UUID()
    let name: String
    private(set) var growthPoints: Int

    mutating func grow(by points: Int) {
        growthPoints += points
    }
}

// MARK: - Productivity Garden System
struct ProductivityGarden {
    var plants: [VirtualPlant]
    var gardenLevel: Int
    var weeklyGrowthPoints: Int

    /// Call when a focus session completes to grow plants
    mutating func completeFocusSession(duration: Int, quality: Double) {
        let growthPoints = Int(Double(duration) * quality)
        for index in plants.indices {
            plants[index].grow(by: growthPoints)
        }
        weeklyGrowthPoints += growthPoints
        checkForUnlocks()
    }

    /// Check for garden level unlocks based on accumulated points
    private mutating func checkForUnlocks() {
        let threshold = gardenLevel * 100
        if weeklyGrowthPoints >= threshold {
            gardenLevel += 1
            weeklyGrowthPoints = 0
        }
    }
} 