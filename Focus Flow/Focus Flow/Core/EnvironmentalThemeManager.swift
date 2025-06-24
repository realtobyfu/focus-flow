import SwiftUI
import Combine

class EnvironmentalThemeManager: ObservableObject {
    @Published var currentTheme: EnvironmentalTheme
    @Published var isTransitioning = false

    private var cancellables = Set<AnyCancellable>()

    init() {
        self.currentTheme = Self.getThemeForCurrentTime()
        setupTimeBasedUpdates()
    }

    private func setupTimeBasedUpdates() {
        Timer.publish(every: 300, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                self.updateForTimeOfDay()
            }
            .store(in: &cancellables)
    }

    func updateForTimeOfDay() {
        let newTheme = Self.getThemeForCurrentTime()
        if newTheme.id != currentTheme.id {
            withAnimation(.easeInOut(duration: 2)) {
                isTransitioning = true
                currentTheme = newTheme
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                self.isTransitioning = false
                HapticStyle.success.trigger()
            }
        }
    }

    /// Returns a theme matching a specific focus mode
    func themeForMode(_ mode: FocusMode) -> EnvironmentalTheme {
        switch mode {
        case .deepWork:
            return EnvironmentalTheme.cosmicFocus
        case .creativeFlow:
            return EnvironmentalTheme.auroraBorealis
        case .learning:
            return EnvironmentalTheme.tranquilLibrary
        case .quickSprint:
            return EnvironmentalTheme.energyBurst
        case .mindfulFocus:
            return EnvironmentalTheme.zenGarden
        }
    }

    /// Determines the theme based on time of day
    static func getThemeForCurrentTime() -> EnvironmentalTheme {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<9:
            return .morningMist
        case 9..<12:
            return .productiveSky
        case 12..<17:
            return .afternoonFocus
        case 17..<21:
            return .eveningGlow
        default:
            return .nighttimeSerenity
        }
    }
}

// MARK: - Environmental Theme Model

struct EnvironmentalTheme: Identifiable {
    let id = UUID()
    let name: String
    let gradientColors: [Color]
    let particleSystem: ParticleSystem
    let ambientSoundName: String?
    let hasParticles: Bool
    let hasAmbientShapes: Bool
    let animationSpeed: Double

    static let cosmicFocus = EnvironmentalTheme(
        name: "Cosmic Focus",
        gradientColors: [Color(hex: "0F2027"), Color(hex: "203A43"), Color(hex: "2C5364")],
        particleSystem: ParticleSystem(type: .stars, density: .medium),
        ambientSoundName: "deep_space",
        hasParticles: true,
        hasAmbientShapes: true,
        animationSpeed: 0.3
    )

    static let auroraBorealis = EnvironmentalTheme(
        name: "Aurora Borealis",
        gradientColors: [Color(hex: "43cea2"), Color(hex: "185a9d"), Color(hex: "ba5370")],
        particleSystem: ParticleSystem(type: .aurora, density: .high),
        ambientSoundName: "arctic_wind",
        hasParticles: true,
        hasAmbientShapes: false,
        animationSpeed: 0.5
    )

    static let tranquilLibrary = EnvironmentalTheme(
        name: "Tranquil Library",
        gradientColors: [Color(hex: "8E9EAB"), Color(hex: "EEF2F3")],
        particleSystem: ParticleSystem(type: .dust, density: .low),
        ambientSoundName: "library_ambience",
        hasParticles: true,
        hasAmbientShapes: false,
        animationSpeed: 0.1
    )

    static let energyBurst = EnvironmentalTheme(
        name: "Energy Burst",
        gradientColors: [Color(hex: "FC466B"), Color(hex: "3F5EFB")],
        particleSystem: ParticleSystem(type: .energy, density: .high),
        ambientSoundName: "motivational_beats",
        hasParticles: true,
        hasAmbientShapes: true,
        animationSpeed: 0.8
    )

    static let zenGarden = EnvironmentalTheme(
        name: "Zen Garden",
        gradientColors: [Color(hex: "134E5E"), Color(hex: "71B280")],
        particleSystem: ParticleSystem(type: .leaves, density: .low),
        ambientSoundName: "zen_garden",
        hasParticles: true,
        hasAmbientShapes: false,
        animationSpeed: 0.2
    )

    // Time-based themes
    static let morningMist = EnvironmentalTheme(
        name: "Morning Mist",
        gradientColors: [Color(hex: "F8B500"), Color(hex: "fceabb"), Color(hex: "F8B500")],
        particleSystem: ParticleSystem(type: .mist, density: .medium),
        ambientSoundName: "morning_birds",
        hasParticles: true,
        hasAmbientShapes: true,
        animationSpeed: 0.3
    )

    static let productiveSky = EnvironmentalTheme(
        name: "Productive Sky",
        gradientColors: [Color(hex: "56CCF2"), Color(hex: "2F80ED")],
        particleSystem: ParticleSystem(type: .clouds, density: .low),
        ambientSoundName: nil,
        hasParticles: false,
        hasAmbientShapes: true,
        animationSpeed: 0.2
    )

    static let afternoonFocus = EnvironmentalTheme(
        name: "Afternoon Focus",
        gradientColors: [Color(hex: "FDBB2D"), Color(hex: "22C1C3")],
        particleSystem: ParticleSystem(type: .none, density: .none),
        ambientSoundName: nil,
        hasParticles: false,
        hasAmbientShapes: true,
        animationSpeed: 0.4
    )

    static let eveningGlow = EnvironmentalTheme(
        name: "Evening Glow",
        gradientColors: [Color(hex: "ee9ca7"), Color(hex: "ffdde1")],
        particleSystem: ParticleSystem(type: .fireflies, density: .medium),
        ambientSoundName: "evening_crickets",
        hasParticles: true,
        hasAmbientShapes: false,
        animationSpeed: 0.3
    )

    static let nighttimeSerenity = EnvironmentalTheme(
        name: "Nighttime Serenity",
        gradientColors: [Color(hex: "141E30"), Color(hex: "243B55")],
        particleSystem: ParticleSystem(type: .stars, density: .high),
        ambientSoundName: "night_sounds",
        hasParticles: true,
        hasAmbientShapes: false,
        animationSpeed: 0.1
    )
}

// MARK: - Particle System

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
} 