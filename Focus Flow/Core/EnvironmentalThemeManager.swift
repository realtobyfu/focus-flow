import SwiftUI
import UIKit
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

    /// Manually set a specific theme (overrides time-based themes)
    func setTheme(_ theme: EnvironmentalTheme) {
        withAnimation(.easeInOut(duration: 1)) {
            currentTheme = theme
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

 