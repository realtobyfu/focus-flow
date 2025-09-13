import SwiftUI
import FamilyControls
import DeviceActivity
import ManagedSettings
import Combine

@available(iOS 15.0, *)
class AdvancedAppBlockingManager: ObservableObject {
    @Published var isBlockingEnabled = false
    @Published var isScreenTimeConfigured = false
    @Published var blockedApps: Set<Application> = []
    @Published var blockedCategories: Set<ActivityCategory> = []
    @Published var blockingLevel: BlockingLevel = .moderate {
        didSet {
            saveBlockingLevel()
        }
    }
    @Published var networkBlockingEnabled = false
    @Published var focusFilterEnabled = false
    
    // Store the current blocking configuration
    private var currentBlockedApps: Set<Application> = []
    private var currentBlockedCategories: Set<ActivityCategory> = []
    
    private let authorizationCenter = AuthorizationCenter.shared
    private let managedSettings = ManagedSettingsStore()
    private let deviceActivityCenter = DeviceActivityCenter()
    private let networkBlockingService = NetworkBlockingService()
    private var screenTimeManager = ScreenTimeManager()
    private var cancellables = Set<AnyCancellable>()
    
    enum BlockingLevel: String, CaseIterable {
        case light = "Light"
        case moderate = "Moderate" 
        case strict = "Strict"
        case extreme = "Extreme"
        
        var description: String {
            switch self {
            case .light: return "Notifications only"
            case .moderate: return "Social media & games"
            case .strict: return "All distracting apps"
            case .extreme: return "Everything except essential"
            }
        }
        
        var blockedCategories: Set<ActivityCategory> {
            // Return empty set for now - would be populated with actual categories
            // from FamilyActivityPicker selection
            return Set<ActivityCategory>()
        }
        
        var allowsNotifications: Bool {
            return self == .light
        }
        
        var allowsEmergencyAccess: Bool {
            return true
        }
    }
    
    init() {
        checkAuthorizationStatus()
        setupNetworkMonitoring()
        loadSavedFamilyActivitySelection()
    }
    
    // MARK: - Authorization & Setup
    
    func requestScreenTimeAuthorization() async -> Bool {
        do {
            try await authorizationCenter.requestAuthorization(for: .individual)
            await MainActor.run {
                self.isScreenTimeConfigured = true
            }
            return true
        } catch {
            print("Screen Time authorization failed: \(error)")
            return false
        }
    }
    
    private func checkAuthorizationStatus() {
        switch authorizationCenter.authorizationStatus {
        case .approved:
            isScreenTimeConfigured = true
        case .denied, .notDetermined:
            isScreenTimeConfigured = false
        @unknown default:
            isScreenTimeConfigured = false
        }
    }
    
    // MARK: - App Blocking Controls
    
    func startBlocking(duration: TimeInterval = 0, customApps: Set<Application>? = nil) {
        guard isScreenTimeConfigured else {
            print("Screen Time not configured")
            return
        }
        
        isBlockingEnabled = true
        
        // Multi-layer blocking approach
        startScreenTimeBlocking(customApps: customApps)
        
        if networkBlockingEnabled {
            startNetworkBlocking()
        }
        
        if focusFilterEnabled {
            activateFocusFilter()
        }
        
        // Schedule automatic stop if duration is specified
        if duration > 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                self.stopBlocking()
            }
        }
        
        // Send notification to user
        scheduleBlockingNotification()
    }
    
    func stopBlocking() {
        isBlockingEnabled = false
        
        // Use ScreenTimeManager to stop blocking
        screenTimeManager.stopBlocking()
        
        // Remove all restrictions
        managedSettings.clearAllSettings()
        
        // Stop network blocking
        networkBlockingService.unblockSites()
        
        // Deactivate focus filter
        deactivateFocusFilter()
        
        // Stop device activity monitoring
        let activities = deviceActivityCenter.activities.compactMap { $0.rawValue }
        for activity in activities {
            deviceActivityCenter.stopMonitoring([DeviceActivityName(activity)])
        }
        
        HapticStyle.success.trigger()
    }
    
    private func startScreenTimeBlocking(customApps: Set<Application>? = nil) {
        // Configure which apps to block
        let appsToBlock = customApps ?? getAppsForBlockingLevel()
        let categoriesToBlock = getCategoriesForBlockingLevel()
        
        // Store the blocking configuration
        currentBlockedApps = appsToBlock
        currentBlockedCategories = categoriesToBlock
        
        // Update published properties
        blockedApps = appsToBlock
        blockedCategories = categoriesToBlock
        
        // Convert to tokens for ScreenTimeManager
        let appTokens = Set(appsToBlock.compactMap { $0.token })
        let categoryTokens = Set(categoriesToBlock.compactMap { $0.token })
        
        // Use ScreenTimeManager for actual blocking
        screenTimeManager.startBlocking(
            applications: appTokens,
            categories: categoryTokens,
            duration: 0 // Duration managed by timer
        )
        
        // Configure shield restrictions
        configureShield()
        
        // Configure notification restrictions
        configureNotificationRestrictions()
        
        // Start device activity monitoring
        startDeviceActivityMonitoring()
    }
    
    private func configureShield() {
        // Shield configuration is already done in startBlocking
        // Additional shield customization can be added here if needed
    }
    
    private func configureNotificationRestrictions() {
        if !blockingLevel.allowsNotifications {
            // Shield configuration for notifications would be handled by
            // the DeviceActivityMonitor extension if implemented
        }
    }
    
    private func startDeviceActivityMonitoring() {
        let activityName = DeviceActivityName("FocusSession")
        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: 0, minute: 0),
            intervalEnd: DateComponents(hour: 23, minute: 59),
            repeats: false
        )
        
        do {
            try deviceActivityCenter.startMonitoring(activityName, during: schedule)
        } catch {
            print("Failed to start device activity monitoring: \(error)")
        }
    }
    
    // MARK: - Network-Level Blocking
    
    private func startNetworkBlocking() {
        // Start network blocking with available method
        networkBlockingService.blockDistractingSites()
    }
    
    private func getDomainsForBlockingLevel() -> [String] {
        switch blockingLevel {
        case .light:
            return []
        case .moderate:
            return [
                "facebook.com", "instagram.com", "twitter.com", "tiktok.com",
                "youtube.com", "reddit.com", "snapchat.com"
            ]
        case .strict:
            return [
                "facebook.com", "instagram.com", "twitter.com", "tiktok.com",
                "youtube.com", "reddit.com", "snapchat.com", "netflix.com",
                "twitch.tv", "discord.com", "pinterest.com"
            ]
        case .extreme:
            return [
                "facebook.com", "instagram.com", "twitter.com", "tiktok.com",
                "youtube.com", "reddit.com", "snapchat.com", "netflix.com",
                "twitch.tv", "discord.com", "pinterest.com", "linkedin.com",
                "medium.com", "news.google.com", "cnn.com", "bbc.com"
            ]
        }
    }
    
    // MARK: - Focus Filter Integration
    
    private func activateFocusFilter() {
        // This would integrate with iOS Focus modes
        // Implementation depends on iOS Focus API availability
        let focusFilter = createFocusFilter()
        // Apply focus filter logic here
    }
    
    private func deactivateFocusFilter() {
        // Deactivate focus filter
    }
    
    private func createFocusFilter() -> Any? {
        // Create custom focus filter based on blocking level
        return nil
    }
    
    // MARK: - Helper Methods
    
    private func getAppsForBlockingLevel() -> Set<Application> {
        // Return the configured blocked apps
        return blockedApps
    }
    
    private func getCategoriesForBlockingLevel() -> Set<ActivityCategory> {
        // Return the pre-configured blocked categories for the current blocking level
        return blockedCategories
    }
    
    private func scheduleBlockingNotification() {
        // Schedule a local notification about blocking activation
        let content = UNMutableNotificationContent()
        content.title = "Focus Mode Activated"
        content.body = "Distracting apps are now blocked. Stay focused!"
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: "focus-blocking-start",
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    private func setupNetworkMonitoring() {
        // Network monitoring not available in current implementation
        // This would require a more sophisticated NetworkBlockingService
    }
    
    private func handleBlockedNetworkAttempt(_ attempt: BlockedNetworkAttempt) {
        // Log the blocked attempt and potentially show user feedback
        print("Blocked network attempt to: \(attempt.domain)")
        HapticStyle.warning.trigger()
    }
    
    // MARK: - Emergency Access
    
    func requestEmergencyAccess(reason: String) -> Bool {
        guard blockingLevel.allowsEmergencyAccess else { return false }
        
        // Temporary unlock for emergency situations
        // This would require user confirmation and logging
        temporaryUnlock(duration: 300) // 5 minutes
        return true
    }
    
    private func temporaryUnlock(duration: TimeInterval) {
        // Temporarily disable blocking
        let originalLevel = blockingLevel
        stopBlocking()
        
        // Re-enable after duration
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            self.blockingLevel = originalLevel
            self.startBlocking()
        }
    }
    
    // MARK: - Statistics & Analytics
    
    func getBlockingStatistics() -> BlockingStatistics {
        return BlockingStatistics(
            sessionsBlocked: 0, // Not available in current NetworkBlockingService
            appsBlocked: blockedApps.count,
            totalTimeBlocked: calculateTotalBlockingTime(),
            mostBlockedApp: getMostBlockedApp(),
            blockingEffectiveness: calculateBlockingEffectiveness()
        )
    }
    
    private func calculateTotalBlockingTime() -> TimeInterval {
        // Calculate total time blocking has been active
        return 0 // Placeholder
    }
    
    private func getMostBlockedApp() -> String? {
        // Return the app that has been blocked most frequently
        return nil // Placeholder
    }
    
    private func calculateBlockingEffectiveness() -> Double {
        // Calculate how effective the blocking has been
        return 0.85 // Placeholder - 85% effectiveness
    }
    
    // MARK: - Family Activity Selection Integration
    
    private func loadSavedFamilyActivitySelection() {
        screenTimeManager.loadSavedSelection()
        
        // Load from app group UserDefaults
        guard let appGroupDefaults = UserDefaults(suiteName: "group.com.tobiasfu.Focus-Flow") else {
            return
        }
        
        // Load application objects
        if let applicationData = appGroupDefaults.data(forKey: "applicationData") {
            do {
                if let applications = try NSKeyedUnarchiver.unarchivedObject(ofClass: NSSet.self, from: applicationData) as? Set<Application> {
                    blockedApps = applications
                }
            } catch {
                print("Failed to load applications: \(error)")
            }
        }
        
        // Load category objects  
        if let categoryData = appGroupDefaults.data(forKey: "categoryData") {
            do {
                if let categories = try NSKeyedUnarchiver.unarchivedObject(ofClass: NSSet.self, from: categoryData) as? Set<ActivityCategory> {
                    blockedCategories = categories
                }
            } catch {
                print("Failed to load categories: \(error)")
            }
        }
    }
    
    func updateFamilyActivitySelection(_ selection: FamilyActivitySelection) {
        blockedApps = selection.applications
        blockedCategories = selection.categories
        
        // Update ScreenTimeManager with tokens
        let appTokens = Set(selection.applications.compactMap { $0.token })
        let categoryTokens = Set(selection.categories.compactMap { $0.token })
        screenTimeManager.updateBlockedApplications(appTokens)
        screenTimeManager.updateBlockedCategories(categoryTokens)
        
        // Save to app group UserDefaults
        saveFamilyActivitySelection(selection)
    }
    
    private func saveFamilyActivitySelection(_ selection: FamilyActivitySelection) {
        guard let appGroupDefaults = UserDefaults(suiteName: "group.com.tobiasfu.Focus-Flow") else {
            return
        }
        
        do {
            // Save Application objects
            let applicationData = try NSKeyedArchiver.archivedData(withRootObject: selection.applications, requiringSecureCoding: true)
            appGroupDefaults.set(applicationData, forKey: "applicationData")
            
            // Save ActivityCategory objects
            let categoryData = try NSKeyedArchiver.archivedData(withRootObject: selection.categories, requiringSecureCoding: true)
            appGroupDefaults.set(categoryData, forKey: "categoryData")
            
            // Also save tokens for the Device Activity Monitor extension
            let appTokens = Set(selection.applications.compactMap { $0.token })
            let categoryTokens = Set(selection.categories.compactMap { $0.token })
            
            let applicationTokensData = try NSKeyedArchiver.archivedData(withRootObject: appTokens, requiringSecureCoding: true)
            appGroupDefaults.set(applicationTokensData, forKey: "applicationTokensData")
            
            let categoryTokensData = try NSKeyedArchiver.archivedData(withRootObject: categoryTokens, requiringSecureCoding: true)
            appGroupDefaults.set(categoryTokensData, forKey: "categoryTokensData")
        } catch {
            print("Failed to save family activity selection: \(error)")
        }
    }
    
    private func saveBlockingLevel() {
        guard let appGroupDefaults = UserDefaults(suiteName: "group.com.tobiasfu.Focus-Flow") else {
            return
        }
        appGroupDefaults.set(blockingLevel.rawValue, forKey: "blockingLevel")
    }
}

// MARK: - Supporting Models

struct BlockingStatistics {
    let sessionsBlocked: Int
    let appsBlocked: Int
    let totalTimeBlocked: TimeInterval
    let mostBlockedApp: String?
    let blockingEffectiveness: Double
}

struct BlockedNetworkAttempt {
    let domain: String
    let timestamp: Date
    let appName: String?
}


// MARK: - iOS 14 Compatibility

@available(iOS 14.0, *)
extension AdvancedAppBlockingManager {
    func configureLegacyBlocking() {
        // Fallback implementation for iOS 14
        // Using UIApplication.shared.open restrictions
    }
}