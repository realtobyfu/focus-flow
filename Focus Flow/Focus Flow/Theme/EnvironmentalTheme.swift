import SwiftUI

// MARK: - Environmental Theme System
struct EnvironmentalTheme: Identifiable {
    let id = UUID()
    let name: String
    let gradients: [LinearGradient]
    let particleEffects: ParticleSystem
    let ambientSounds: [String]
    let unlockRequirement: UnlockRequirement
}

// Simple particle system stub
struct ParticleSystem {
    let effectName: String
    // Additional configuration parameters can be added here
}

// Defines how a theme is unlocked
enum UnlockRequirement {
    case hoursOfFocusTime(Int)
    case sessionsCompleted(Int)
}

// Example themes
let environmentalThemes: [EnvironmentalTheme] = [
    EnvironmentalTheme(
        name: "Aurora Borealis",
        gradients: [
            LinearGradient(
                colors: [Color(hex: "667eea"), Color(hex: "764ba2")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        ],
        particleEffects: ParticleSystem(effectName: "northern_lights"),
        ambientSounds: ["aurora_borealis"],
        unlockRequirement: .sessionsCompleted(5)
    ),
    EnvironmentalTheme(
        name: "Underwater Sanctuary",
        gradients: [
            LinearGradient(
                colors: [Color(hex: "4facfe"), Color(hex: "00f2fe")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        ],
        particleEffects: ParticleSystem(effectName: "bubbles"),
        ambientSounds: ["whale_sounds"],
        unlockRequirement: .hoursOfFocusTime(10)
    ),
    EnvironmentalTheme(
        name: "Mountain Peak",
        gradients: [
            LinearGradient(
                colors: [Color(hex: "fa709a"), Color(hex: "fee140")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        ],
        particleEffects: ParticleSystem(effectName: "clouds"),
        ambientSounds: ["wind_sounds"],
        unlockRequirement: .sessionsCompleted(10)
    ),
    EnvironmentalTheme(
        name: "Cosmic Journey",
        gradients: [
            LinearGradient(
                colors: [Color(hex: "30cfd0"), Color(hex: "330867")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        ],
        particleEffects: ParticleSystem(effectName: "stars"),
        ambientSounds: ["space_ambience"],
        unlockRequirement: .hoursOfFocusTime(20)
    )
] 