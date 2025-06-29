import SwiftUI

// MARK: - Environmental Theme System
struct EnvironmentalTheme: Identifiable {
    let id = UUID()
    let name: String
    let gradients: [LinearGradient]
    let particleEffects: ParticleSystem
    let ambientSounds: [String]
    let unlockRequirement: UnlockRequirement
    
    // UI configuration properties
    var hasParticles: Bool {
        return particleEffects.type != .none
    }
    
    var hasAmbientShapes: Bool {
        // Enable ambient shapes for certain themes
        switch name {
        case "Cosmic Focus", "Energy Burst", "Morning Mist", "Productive Sky", "Afternoon Focus":
            return true
        default:
            return false
        }
    }
    
    // Alias for particleSystem to match expected property name
    var particleSystem: ParticleSystem {
        return particleEffects
    }
    
    // Computed property for backward compatibility
    var gradientColors: [Color] {
        // Extract colors from the first gradient's definition
        // Since we can't access stops directly, we'll provide the colors used in creation
        switch name {
        case "Cosmic Focus":
            return [Color(hex: "30cfd0"), Color(hex: "330867")]
        case "Aurora Borealis":
            return [Color(hex: "667eea"), Color(hex: "764ba2")]
        case "Tranquil Library":
            return [Color(hex: "8E9EAB"), Color(hex: "EEF2F3")]
        case "Energy Burst":
            return [Color(hex: "fa709a"), Color(hex: "fee140")]
        case "Zen Garden":
            return [Color(hex: "134E5E"), Color(hex: "71B280")]
        case "Morning Mist":
            return [Color(hex: "F8B500"), Color(hex: "fceabb")]
        case "Productive Sky":
            return [Color(hex: "56CCF2"), Color(hex: "2F80ED")]
        case "Afternoon Focus":
            return [Color(hex: "FDBB2D"), Color(hex: "22C1C3")]
        case "Evening Glow":
            return [Color(hex: "ee9ca7"), Color(hex: "ffdde1")]
        case "Nighttime Serenity":
            return [Color(hex: "141E30"), Color(hex: "243B55")]
        default:
            return [Color.blue, Color.purple]
        }
    }
    
    // Static theme definitions
    static let cosmicFocus = EnvironmentalTheme(
        name: "Cosmic Focus",
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
    
    static let auroraBorealis = EnvironmentalTheme(
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
    )
    
    static let tranquilLibrary = EnvironmentalTheme(
        name: "Tranquil Library",
        gradients: [
            LinearGradient(
                colors: [Color(hex: "8E9EAB"), Color(hex: "EEF2F3")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        ],
        particleEffects: ParticleSystem(effectName: "dust"),
        ambientSounds: ["library_ambience"],
        unlockRequirement: .sessionsCompleted(3)
    )
    
    static let energyBurst = EnvironmentalTheme(
        name: "Energy Burst",
        gradients: [
            LinearGradient(
                colors: [Color(hex: "fa709a"), Color(hex: "fee140")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        ],
        particleEffects: ParticleSystem(effectName: "energy"),
        ambientSounds: ["energetic_beats"],
        unlockRequirement: .sessionsCompleted(1)
    )
    
    static let zenGarden = EnvironmentalTheme(
        name: "Zen Garden",
        gradients: [
            LinearGradient(
                colors: [Color(hex: "134E5E"), Color(hex: "71B280")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        ],
        particleEffects: ParticleSystem(effectName: "leaves"),
        ambientSounds: ["zen_garden"],
        unlockRequirement: .hoursOfFocusTime(5)
    )
    
    // Time-based themes
    static let morningMist = EnvironmentalTheme(
        name: "Morning Mist",
        gradients: [
            LinearGradient(
                colors: [Color(hex: "F8B500"), Color(hex: "fceabb")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        ],
        particleEffects: ParticleSystem(effectName: "bubbles"),
        ambientSounds: ["morning_birds"],
        unlockRequirement: .sessionsCompleted(0)
    )
    
    static let productiveSky = EnvironmentalTheme(
        name: "Productive Sky",
        gradients: [
            LinearGradient(
                colors: [Color(hex: "56CCF2"), Color(hex: "2F80ED")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        ],
        particleEffects: ParticleSystem(effectName: "clouds"),
        ambientSounds: ["focus_ambience"],
        unlockRequirement: .sessionsCompleted(0)
    )
    
    static let afternoonFocus = EnvironmentalTheme(
        name: "Afternoon Focus",
        gradients: [
            LinearGradient(
                colors: [Color(hex: "FDBB2D"), Color(hex: "22C1C3")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        ],
        particleEffects: ParticleSystem(effectName: "none"),
        ambientSounds: ["concentration_sounds"],
        unlockRequirement: .sessionsCompleted(0)
    )
    
    static let eveningGlow = EnvironmentalTheme(
        name: "Evening Glow",
        gradients: [
            LinearGradient(
                colors: [Color(hex: "ee9ca7"), Color(hex: "ffdde1")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        ],
        particleEffects: ParticleSystem(effectName: "fireflies"),
        ambientSounds: ["evening_crickets"],
        unlockRequirement: .sessionsCompleted(0)
    )
    
    static let nighttimeSerenity = EnvironmentalTheme(
        name: "Nighttime Serenity",
        gradients: [
            LinearGradient(
                colors: [Color(hex: "141E30"), Color(hex: "243B55")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        ],
        particleEffects: ParticleSystem(effectName: "stars"),
        ambientSounds: ["night_sounds"],
        unlockRequirement: .sessionsCompleted(0)
    )
}

// Particle system configuration
struct ParticleSystem {
    enum ParticleType {
        case stars, aurora, dust, energy, leaves, mist, clouds, fireflies, none
    }
    
    enum Density {
        case low, medium, high, none
        
        var particleCount: Int {
            switch self {
            case .low: return 20
            case .medium: return 50
            case .high: return 100
            case .none: return 0
            }
        }
    }
    
    let type: ParticleType
    let density: Density
    let effectName: String
    
    init(effectName: String) {
        self.effectName = effectName
        // Map effect names to types
        switch effectName {
        case "northern_lights": 
            self.type = .aurora
            self.density = .high
        case "bubbles":
            self.type = .mist
            self.density = .medium
        case "clouds":
            self.type = .clouds
            self.density = .low
        case "stars":
            self.type = .stars
            self.density = .high
        default:
            self.type = .none
            self.density = .none
        }
    }
    
    init(type: ParticleType, density: Density) {
        self.type = type
        self.density = density
        self.effectName = type.effectName
    }
}

extension ParticleSystem.ParticleType {
    var effectName: String {
        switch self {
        case .stars: return "stars"
        case .aurora: return "northern_lights" 
        case .dust: return "dust"
        case .energy: return "energy"
        case .leaves: return "leaves"
        case .mist: return "bubbles"
        case .clouds: return "clouds"
        case .fireflies: return "fireflies"
        case .none: return "none"
        }
    }
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