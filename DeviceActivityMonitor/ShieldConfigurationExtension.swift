import Foundation
import ManagedSettings
import ManagedSettingsUI
import UIKit

class FocusFlowShieldConfigurationExtension: ShieldConfigurationDataSource {
    
    override func configuration(shielding application: Application) -> ShieldConfiguration {
        // Return the shield configuration for a specific application
        return ShieldConfiguration(
            backgroundBlurStyle: UIBlurEffect.Style.systemUltraThinMaterial,
            backgroundColor: UIColor.systemBackground.withAlphaComponent(0.9),
            icon: UIImage(systemName: "leaf.fill"),
            title: ShieldConfiguration.Label(
                text: "Focus Time",
                color: UIColor.label
            ),
            subtitle: ShieldConfiguration.Label(
                text: "Stay focused on your goals",
                color: UIColor.secondaryLabel
            ),
            primaryButtonLabel: ShieldConfiguration.Label(
                text: "OK",
                color: UIColor.systemBlue
            ),
            secondaryButtonLabel: ShieldConfiguration.Label(
                text: "Emergency Access",
                color: UIColor.systemRed
            )
        )
    }
    
    override func configuration(shielding applicationCategory: ApplicationCategory) -> ShieldConfiguration {
        // Return the shield configuration for a category of applications
        return ShieldConfiguration(
            backgroundBlurStyle: UIBlurEffect.Style.systemUltraThinMaterial,
            backgroundColor: UIColor.systemBackground.withAlphaComponent(0.9),
            icon: UIImage(systemName: "hourglass"),
            title: ShieldConfiguration.Label(
                text: "Category Blocked",
                color: UIColor.label
            ),
            subtitle: ShieldConfiguration.Label(
                text: "This app category is restricted during focus time",
                color: UIColor.secondaryLabel
            ),
            primaryButtonLabel: ShieldConfiguration.Label(
                text: "Understood",
                color: UIColor.systemBlue
            ),
            secondaryButtonLabel: ShieldConfiguration.Label(
                text: "Request Access",
                color: UIColor.systemOrange
            )
        )
    }
    
    override func configuration(shielding webDomain: WebDomain) -> ShieldConfiguration {
        // Return the shield configuration for a specific web domain
        return ShieldConfiguration(
            backgroundBlurStyle: UIBlurEffect.Style.systemUltraThinMaterial,
            backgroundColor: UIColor.systemBackground.withAlphaComponent(0.9),
            icon: UIImage(systemName: "globe.badge.chevron.backward"),
            title: ShieldConfiguration.Label(
                text: "Website Blocked",
                color: UIColor.label
            ),
            subtitle: ShieldConfiguration.Label(
                text: "This website is restricted during your focus session",
                color: UIColor.secondaryLabel
            ),
            primaryButtonLabel: ShieldConfiguration.Label(
                text: "Close",
                color: UIColor.systemBlue
            ),
            secondaryButtonLabel: nil
        )
    }
    
    override func configuration(shielding webDomainCategory: WebDomainCategory) -> ShieldConfiguration {
        // Return the shield configuration for a category of web domains
        return ShieldConfiguration(
            backgroundBlurStyle: UIBlurEffect.Style.systemUltraThinMaterial,
            backgroundColor: UIColor.systemBackground.withAlphaComponent(0.9),
            icon: UIImage(systemName: "safari.fill"),
            title: ShieldConfiguration.Label(
                text: "Site Category Blocked",
                color: UIColor.label
            ),
            subtitle: ShieldConfiguration.Label(
                text: "Websites in this category are restricted",
                color: UIColor.secondaryLabel
            ),
            primaryButtonLabel: ShieldConfiguration.Label(
                text: "Got It",
                color: UIColor.systemBlue
            ),
            secondaryButtonLabel: nil
        )
    }
}

// MARK: - Dynamic Configuration Based on Blocking Level
extension FocusFlowShieldConfigurationExtension {
    
    private func getBlockingLevel() -> String {
        guard let sharedDefaults = UserDefaults(suiteName: "group.com.tobiasfu.Focus-Flow") else {
            return "moderate"
        }
        return sharedDefaults.string(forKey: "blockingLevel") ?? "moderate"
    }
    
    private func configurationForBlockingLevel(_ level: String, application: Application) -> ShieldConfiguration {
        switch level {
        case "light":
            return lightBlockingConfiguration(for: application)
        case "moderate":
            return moderateBlockingConfiguration(for: application)
        case "strict":
            return strictBlockingConfiguration(for: application)
        case "extreme":
            return extremeBlockingConfiguration(for: application)
        default:
            return moderateBlockingConfiguration(for: application)
        }
    }
    
    private func lightBlockingConfiguration(for application: Application) -> ShieldConfiguration {
        return ShieldConfiguration(
            backgroundBlurStyle: UIBlurEffect.Style.systemThinMaterial,
            backgroundColor: UIColor.systemBackground.withAlphaComponent(0.7),
            icon: UIImage(systemName: "moon.fill"),
            title: ShieldConfiguration.Label(
                text: "Light Focus Mode",
                color: UIColor.label
            ),
            subtitle: ShieldConfiguration.Label(
                text: "Consider if you really need this app right now",
                color: UIColor.secondaryLabel
            ),
            primaryButtonLabel: ShieldConfiguration.Label(
                text: "Continue Anyway",
                color: UIColor.systemBlue
            ),
            secondaryButtonLabel: ShieldConfiguration.Label(
                text: "Stay Focused",
                color: UIColor.systemGreen
            )
        )
    }
    
    private func moderateBlockingConfiguration(for application: Application) -> ShieldConfiguration {
        return ShieldConfiguration(
            backgroundBlurStyle: UIBlurEffect.Style.systemUltraThinMaterial,
            backgroundColor: UIColor.systemBackground.withAlphaComponent(0.9),
            icon: UIImage(systemName: "leaf.fill"),
            title: ShieldConfiguration.Label(
                text: "Focus Time Active",
                color: UIColor.label
            ),
            subtitle: ShieldConfiguration.Label(
                text: "This app is blocked during your focus session",
                color: UIColor.secondaryLabel
            ),
            primaryButtonLabel: ShieldConfiguration.Label(
                text: "OK",
                color: UIColor.systemBlue
            ),
            secondaryButtonLabel: ShieldConfiguration.Label(
                text: "Emergency",
                color: UIColor.systemRed
            )
        )
    }
    
    private func strictBlockingConfiguration(for application: Application) -> ShieldConfiguration {
        return ShieldConfiguration(
            backgroundBlurStyle: UIBlurEffect.Style.systemUltraThinMaterial,
            backgroundColor: UIColor.systemRed.withAlphaComponent(0.1),
            icon: UIImage(systemName: "xmark.circle.fill"),
            title: ShieldConfiguration.Label(
                text: "Strict Blocking",
                color: UIColor.systemRed
            ),
            subtitle: ShieldConfiguration.Label(
                text: "Access denied during deep focus",
                color: UIColor.secondaryLabel
            ),
            primaryButtonLabel: ShieldConfiguration.Label(
                text: "Understood",
                color: UIColor.systemRed
            ),
            secondaryButtonLabel: nil
        )
    }
    
    private func extremeBlockingConfiguration(for application: Application) -> ShieldConfiguration {
        return ShieldConfiguration(
            backgroundBlurStyle: UIBlurEffect.Style.systemUltraThinMaterial,
            backgroundColor: UIColor.black.withAlphaComponent(0.8),
            icon: UIImage(systemName: "lock.fill"),
            title: ShieldConfiguration.Label(
                text: "Maximum Focus",
                color: UIColor.white
            ),
            subtitle: ShieldConfiguration.Label(
                text: "Complete digital detox mode active",
                color: UIColor.lightGray
            ),
            primaryButtonLabel: ShieldConfiguration.Label(
                text: "Close",
                color: UIColor.white
            ),
            secondaryButtonLabel: nil
        )
    }
}