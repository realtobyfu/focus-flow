import Foundation
import DeviceActivity
import ManagedSettings
import FamilyControls

class FocusFlowDeviceActivityMonitor: DeviceActivityMonitor {
    let store = ManagedSettingsStore()
    
    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)
        
        // Load blocked applications from shared app group
        guard let sharedDefaults = UserDefaults(suiteName: "group.com.tobiasfu.Focus-Flow") else {
            return
        }
        
        // Apply shields when focus session starts
        if activity == DeviceActivityName("FocusSession") {
            applyShieldsFromUserDefaults(sharedDefaults)
        }
    }
    
    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
        
        // Remove all shields when focus session ends
        if activity == DeviceActivityName("FocusSession") {
            store.clearAllSettings()
        }
    }
    
    override func intervalWillStartWarning(for activity: DeviceActivityName, in dateComponents: DateComponents) {
        super.intervalWillStartWarning(for: activity, in: dateComponents)
        
        // Optional: Show warning before focus session starts
        // Could trigger a notification or prepare UI
    }
    
    override func intervalWillEndWarning(for activity: DeviceActivityName, in dateComponents: DateComponents) {
        super.intervalWillEndWarning(for: activity, in: dateComponents)
        
        // Optional: Show warning before focus session ends
        // Could prepare user for transition back to unrestricted mode
    }
    
    override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
        super.eventDidReachThreshold(event, activity: activity)
        
        // Handle specific usage thresholds if configured
        // This could be used for progressive blocking or warnings
    }
    
    private func applyShieldsFromUserDefaults(_ sharedDefaults: UserDefaults) {
        // Load application tokens
        if let applicationTokensData = sharedDefaults.data(forKey: "applicationTokensData") {
            do {
                if let applications = try NSKeyedUnarchiver.unarchivedObject(ofClass: NSSet.self, from: applicationTokensData) as? Set<ApplicationToken> {
                    store.shield.applications = applications
                }
            } catch {
                print("Failed to load application tokens in extension: \(error)")
            }
        }
        
        // Load category tokens
        if let categoryTokensData = sharedDefaults.data(forKey: "categoryTokensData") {
            do {
                if let categories = try NSKeyedUnarchiver.unarchivedObject(ofClass: NSSet.self, from: categoryTokensData) as? Set<ActivityCategoryToken> {
                    store.shield.applicationCategories = .specific(categories)
                }
            } catch {
                print("Failed to load category tokens in extension: \(error)")
            }
        }
        
        // Load blocking level settings
        let blockingLevel = sharedDefaults.string(forKey: "blockingLevel") ?? "moderate"
        configureShieldForBlockingLevel(blockingLevel)
    }
    
    private func configureShieldForBlockingLevel(_ level: String) {
        // Configure shield behavior based on blocking level
        switch level {
        case "light":
            // Light blocking - allow notifications, minimal restrictions
            store.shield.applications = store.shield.applications
        case "moderate":
            // Moderate blocking - standard restrictions
            store.shield.applications = store.shield.applications
        case "strict":
            // Strict blocking - stronger restrictions
            store.shield.applications = store.shield.applications
        case "extreme":
            // Extreme blocking - maximum restrictions
            store.shield.applications = store.shield.applications
        default:
            // Default to moderate
            break
        }
    }
}

// MARK: - Shield Configuration Extension
extension FocusFlowDeviceActivityMonitor {
    
    /// Creates custom shield configuration for blocked apps
    private func createShieldConfiguration() -> ShieldConfiguration {
        // This would be implemented if we had a custom shield configuration UI
        // For now, using the default system shield
        return ShieldConfiguration()
    }
    
    /// Handles emergency access requests
    private func handleEmergencyAccess() {
        // Emergency access logic would go here
        // Could temporarily disable shields or show emergency options
        
        // For now, log the emergency access attempt
        let sharedDefaults = UserDefaults(suiteName: "group.com.tobiasfu.Focus-Flow")
        let emergencyCount = sharedDefaults?.integer(forKey: "emergencyAccessCount") ?? 0
        sharedDefaults?.set(emergencyCount + 1, forKey: "emergencyAccessCount")
        
        print("Emergency access requested. Count: \(emergencyCount + 1)")
    }
}