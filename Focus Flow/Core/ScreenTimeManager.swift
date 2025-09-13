import Foundation
import FamilyControls
import ManagedSettings
import DeviceActivity
import Combine

@available(iOS 15.0, *)
class ScreenTimeManager: ObservableObject {
    @Published var isAuthorized = false
    @Published var isBlocking = false
    
    private let authorizationCenter = AuthorizationCenter.shared
    private let managedSettingsStore = ManagedSettingsStore()
    private let deviceActivityCenter = DeviceActivityCenter()
    private var cancellables = Set<AnyCancellable>()
    
    // Store blocked applications and categories
    private var blockedApplications: Set<ApplicationToken> = []
    private var blockedCategories: Set<ActivityCategoryToken> = []
    
    init() {
        checkAuthorizationStatus()
    }
    
    private func checkAuthorizationStatus() {
        switch authorizationCenter.authorizationStatus {
        case .approved:
            isAuthorized = true
        case .denied, .notDetermined:
            isAuthorized = false
        @unknown default:
            isAuthorized = false
        }
    }
    
    func requestAuthorization() async -> Bool {
        do {
            try await authorizationCenter.requestAuthorization(for: .individual)
            await MainActor.run {
                self.isAuthorized = true
            }
            return true
        } catch {
            print("Screen Time authorization failed: \(error)")
            await MainActor.run {
                self.isAuthorized = false
            }
            return false
        }
    }
    
    func loadSavedSelection() {
        guard let appGroupDefaults = UserDefaults(suiteName: "group.com.tobiasfu.Focus-Flow") else {
            return
        }
        
        // Load application tokens
        if let applicationTokensData = appGroupDefaults.data(forKey: "applicationTokensData") {
            do {
                if let applications = try NSKeyedUnarchiver.unarchivedObject(ofClass: NSSet.self, from: applicationTokensData) as? Set<ApplicationToken> {
                    blockedApplications = applications
                }
            } catch {
                print("Failed to load application tokens: \(error)")
            }
        }
        
        // Load category tokens
        if let categoryTokensData = appGroupDefaults.data(forKey: "categoryTokensData") {
            do {
                if let categories = try NSKeyedUnarchiver.unarchivedObject(ofClass: NSSet.self, from: categoryTokensData) as? Set<ActivityCategoryToken> {
                    blockedCategories = categories
                }
            } catch {
                print("Failed to load category tokens: \(error)")
            }
        }
    }
    
    func startBlocking(applications: Set<ApplicationToken>?, categories: Set<ActivityCategoryToken>?, duration: TimeInterval = 0) {
        guard isAuthorized else {
            print("Screen Time not authorized")
            return
        }
        
        // Use provided applications/categories or fall back to saved ones
        let appsToBlock = applications ?? blockedApplications
        let categoriesToBlock = categories ?? blockedCategories
        
        // Configure managed settings to block the applications and categories
        if !appsToBlock.isEmpty {
            managedSettingsStore.shield.applications = appsToBlock
        }
        if !categoriesToBlock.isEmpty {
            managedSettingsStore.shield.applicationCategories = .specific(categoriesToBlock)
        }
        
        // Start device activity monitoring if duration is specified
        if duration > 0 {
            startDeviceActivityMonitoring(duration: duration)
        }
        
        isBlocking = true
        
        // Schedule automatic stop if duration is specified
        if duration > 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                self.stopBlocking()
            }
        }
    }
    
    func stopBlocking() {
        // Clear all managed settings
        managedSettingsStore.clearAllSettings()
        
        // Stop device activity monitoring
        let activities = deviceActivityCenter.activities.compactMap { $0.rawValue }
        for activity in activities {
            deviceActivityCenter.stopMonitoring([DeviceActivityName(activity)])
        }
        
        isBlocking = false
    }
    
    private func startDeviceActivityMonitoring(duration: TimeInterval) {
        let activityName = DeviceActivityName("FocusSession")
        
        let startComponents = Calendar.current.dateComponents([.hour, .minute], from: Date())
        let endDate = Date().addingTimeInterval(duration)
        let endComponents = Calendar.current.dateComponents([.hour, .minute], from: endDate)
        
        let schedule = DeviceActivitySchedule(
            intervalStart: startComponents,
            intervalEnd: endComponents,
            repeats: false
        )
        
        do {
            try deviceActivityCenter.startMonitoring(activityName, during: schedule)
        } catch {
            print("Failed to start device activity monitoring: \(error)")
        }
    }
    
    func updateBlockedApplications(_ applications: Set<ApplicationToken>?) {
        blockedApplications = applications ?? blockedApplications
        saveSelection()
    }
    
    func updateBlockedCategories(_ categories: Set<ActivityCategoryToken>?) {
        blockedCategories = categories ?? blockedCategories
        saveSelection()
    }
    
    private func saveSelection() {
        guard let appGroupDefaults = UserDefaults(suiteName: "group.com.tobiasfu.Focus-Flow") else {
            return
        }
        
        do {
            let applicationData = try NSKeyedArchiver.archivedData(withRootObject: blockedApplications, requiringSecureCoding: true)
            appGroupDefaults.set(applicationData, forKey: "applicationTokensData")
            
            let categoryData = try NSKeyedArchiver.archivedData(withRootObject: blockedCategories, requiringSecureCoding: true)
            appGroupDefaults.set(categoryData, forKey: "categoryTokensData")
        } catch {
            print("Failed to save selection: \(error)")
        }
    }
    
    // Legacy methods for compatibility
    func requestAccess(completion: @escaping (Bool) -> Void) {
        Task {
            let result = await requestAuthorization()
            DispatchQueue.main.async {
                completion(result)
            }
        }
    }
    
    func setAppLimits(_ bundleIds: [String], duration: TimeInterval) {
        // Convert bundle IDs to ApplicationTokens if possible
        // This is a simplified approach - in practice, you'd need to map bundle IDs to tokens
        // For now, use the saved selection
        startBlocking(applications: blockedApplications, categories: blockedCategories, duration: duration)
    }
} 
