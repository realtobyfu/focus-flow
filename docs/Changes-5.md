21. App Delegate & Scene Configuration
swift// App/FlowStateApp.swift
import SwiftUI
import UserNotifications
import BackgroundTasks

@main
struct FlowStateApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var appCoordinator = AppCoordinator.shared
    @StateObject private var taskViewModel: TaskViewModel
    @StateObject private var blockingManager = AdvancedAppBlockingManager()
    @StateObject private var premiumStore = PremiumStore()
    
    init() {
        // Configure app appearance
        configureAppearance()
        
        // Initialize Core Data
        let context = PersistenceController.shared.container.viewContext
        _taskViewModel = StateObject(wrappedValue: TaskViewModel(context: context))
        
        // Register background tasks
        registerBackgroundTasks()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appCoordinator)
                .environmentObject(taskViewModel)
                .environmentObject(blockingManager)
                .environmentObject(premiumStore)
                .onOpenURL { url in
                    appCoordinator.handleDeepLink(url)
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                    refreshAppState()
                }
        }
    }
    
    private func configureAppearance() {
        // Navigation bar appearance
        let appearance = UINavigationBarAppearance()
        appearance.configureWithDefaultBackground()
        appearance.backgroundColor = UIColor.systemBackground
        appearance.titleTextAttributes = [.foregroundColor: UIColor.label]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.label]
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        
        // Tab bar appearance
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithDefaultBackground()
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
    }
    
    private func registerBackgroundTasks() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: "com.flowstate.refresh",
            using: nil
        ) { task in
            self.handleAppRefresh(task: task as! BGAppRefreshTask)
        }
        
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: "com.flowstate.cleanup",
            using: nil
        ) { task in
            self.handleCleanup(task: task as! BGProcessingTask)
        }
    }
    
    private func handleAppRefresh(task: BGAppRefreshTask) {
        // Schedule next refresh
        scheduleAppRefresh()
        
        // Perform refresh tasks
        Task {
            do {
                // Update widgets
                await WidgetUpdateManager.shared.updateAllWidgets()
                
                // Sync data if needed
                if AppConfiguration.Storage.userDefaults.bool(forKey: "iCloudSyncEnabled") {
                    await CloudSyncManager.shared.performSync()
                }
                
                task.setTaskCompleted(success: true)
            } catch {
                task.setTaskCompleted(success: false)
            }
        }
    }
    
    private func handleCleanup(task: BGProcessingTask) {
        // Perform cleanup
        Task {
            do {
                // Clean old sessions
                await DataCleanupManager.shared.cleanOldData()
                
                // Optimize Core Data
                await PersistenceController.shared.performMaintenance()
                
                task.setTaskCompleted(success: true)
            } catch {
                task.setTaskCompleted(success: false)
            }
        }
    }
    
    private func scheduleAppRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: "com.flowstate.refresh")
        request.earliestBeginDate = Date(timeIntervalSinceNow: 3600) // 1 hour
        
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("Failed to schedule app refresh: \(error)")
        }
    }
    
    private func refreshAppState() {
        // Refresh data when app comes to foreground
        taskViewModel.fetchTasks()
        premiumStore.updateCustomerProductStatus()
    }
}

// MARK: - App Delegate

class AppDelegate: NSObject, UIApplicationDelegate {
    let notificationManager = NotificationManager.shared
    let analyticsManager = AnalyticsManager.shared
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {
        // Configure services
        configureNotifications()
        configureAnalytics()
        configureCrashReporting()
        
        // Handle launch from notification
        if let notification = launchOptions?[.remoteNotification] as? [String: Any] {
            handleNotification(notification)
        }
        
        // Schedule app refresh
        scheduleBackgroundRefresh()
        
        return true
    }
    
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        // Send token to backend
        let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        APIManager.shared.updatePushToken(token)
    }
    
    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable : Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        // Handle remote notification
        handleNotification(userInfo)
        completionHandler(.newData)
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Save app state
        saveAppState()
        
        // Schedule background tasks
        scheduleBackgroundTasks()
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Final cleanup
        saveAppState()
    }
    
    private func configureNotifications() {
        UNUserNotificationCenter.current().delegate = notificationManager
        notificationManager.registerCategories()
    }
    
    private func configureAnalytics() {
        analyticsManager.configure()
        analyticsManager.track(event: .appLaunched)
    }
    
    private func configureCrashReporting() {
        // Configure crash reporting service
        if AppEnvironment.isAppStore {
            // CrashReporter.configure()
        }
    }
    
    private func handleNotification(_ userInfo: [AnyHashable: Any]) {
        guard let type = userInfo["type"] as? String else { return }
        
        switch type {
        case "session_reminder":
            AppCoordinator.shared.handleDeepLink(URL(string: "flowstate://timer")!)
        case "achievement_unlocked":
            if let achievementId = userInfo["achievement_id"] as? String {
                AppCoordinator.shared.handleDeepLink(URL(string: "flowstate://achievements/\(achievementId)")!)
            }
        default:
            break
        }
    }
    
    private func saveAppState() {
        // Save current state
        AppStateManager.shared.saveCurrentState()
    }
    
    private func scheduleBackgroundRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: "com.flowstate.refresh")
        request.earliestBeginDate = Date(timeIntervalSinceNow: 3600)
        
        try? BGTaskScheduler.shared.submit(request)
    }
    
    private func scheduleBackgroundTasks() {
        // Schedule cleanup task
        let cleanupRequest = BGProcessingTaskRequest(identifier: "com.flowstate.cleanup")
        cleanupRequest.requiresNetworkConnectivity = false
        cleanupRequest.requiresExternalPower = false
        cleanupRequest.earliestBeginDate = Date(timeIntervalSinceNow: 86400) // 24 hours
        
        try? BGTaskScheduler.shared.submit(cleanupRequest)
    }
}

## 22. Notification Manager

```swift
// Managers/NotificationManager.swift
import UserNotifications
import SwiftUI

class NotificationManager: NSObject, ObservableObject {
    static let shared = NotificationManager()
    
    @Published var pendingNotifications: [UNNotificationRequest] = []
    @Published var deliveredNotifications: [UNNotification] = []
    
    override init() {
        super.init()
        requestAuthorization()
    }
    
    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound, .badge, .providesAppNotificationSettings]
        ) { granted, error in
            if granted {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        }
    }
    
    func registerCategories() {
        // Focus category
        let startFocusAction = UNNotificationAction(
            identifier: AppConfiguration.Notifications.Actions.startFocus,
            title: "Start Focus",
            options: .foreground
        )
        
        let take5MinBreakAction = UNNotificationAction(
            identifier: AppConfiguration.Notifications.Actions.take5MinBreak,
            title: "5 min break",
            options: .foreground
        )
        
        let take15MinBreakAction = UNNotificationAction(
            identifier: AppConfiguration.Notifications.Actions.take15MinBreak,
            title: "15 min break",
            options: .foreground
        )
        
        let focusCategory = UNNotificationCategory(
            identifier: AppConfiguration.Notifications.Categories.focus,
            actions: [startFocusAction, take5MinBreakAction, take15MinBreakAction],
            intentIdentifiers: [],
            options: .customDismissAction
        )
        
        // Achievement category
        let viewAchievementAction = UNNotificationAction(
            identifier: AppConfiguration.Notifications.Actions.viewAchievement,
            title: "View Achievement",
            options: .foreground
        )
        
        let achievementCategory = UNNotificationCategory(
            identifier: AppConfiguration.Notifications.Categories.achievement,
            actions: [viewAchievementAction],
            intentIdentifiers: [],
            options: []
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([
            focusCategory,
            achievementCategory
        ])
    }
    
    func scheduleSessionComplete(duration: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Focus Session Complete! 🎉"
        content.body = "Great job! You focused for \(duration) minutes. Time for a break?"
        content.sound = UNNotificationSound(named: UNNotificationSoundName("success_sound.m4a"))
        content.categoryIdentifier = AppConfiguration.Notifications.Categories.focus
        content.userInfo = ["type": "session_complete", "duration": duration]
        
        let request = UNNotificationRequest(
            identifier: AppConfiguration.Notifications.sessionComplete,
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    func scheduleBreakReminder() {
        let content = UNMutableNotificationContent()
        content.title = "Break Time Over"
        content.body = "Ready to get back to focus?"
        content.sound = .default
        content.categoryIdentifier = AppConfiguration.Notifications.Categories.focus
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: AppConfiguration.Notifications.breakReminder,
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    func scheduleDailyReminder(at time: DateComponents) {
        let content = UNMutableNotificationContent()
        content.title = getDailyReminderTitle()
        content.body = "Start your day with a focused mind"
        content.sound = .default
        content.categoryIdentifier = AppConfiguration.Notifications.Categories.reminder
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: time, repeats: true)
        
        let request = UNNotificationRequest(
            identifier: AppConfiguration.Notifications.dailyReminder,
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    func showAchievementNotification(_ achievement: Achievement) {
        let content = UNMutableNotificationContent()
        content.title = "Achievement Unlocked! 🏆"
        content.body = "\(achievement.name): \(achievement.description)"
        content.sound = UNNotificationSound(named: UNNotificationSoundName("achievement_sound.m4a"))
        content.categoryIdentifier = AppConfiguration.Notifications.Categories.achievement
        content.userInfo = [
            "type": "achievement_unlocked",
            "achievement_id": achievement.id
        ]
        
        // Add attachment if available
        if let imageURL = getAchievementImageURL(for: achievement) {
            do {
                let attachment = try UNNotificationAttachment(
                    identifier: "achievement_image",
                    url: imageURL,
                    options: nil
                )
                content.attachments = [attachment]
            } catch {
                print("Failed to attach achievement image: \(error)")
            }
        }
        
        let request = UNNotificationRequest(
            identifier: "\(AppConfiguration.Notifications.achievementUnlocked)_\(achievement.id)",
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    private func getDailyReminderTitle() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        let name = AppConfiguration.Storage.userDefaults.string(forKey: "userName") ?? "there"
        
        switch hour {
        case 5..<12:
            return "Good morning, \(name)! ☀️"
        case 12..<17:
            return "Good afternoon, \(name)! 🌤"
        case 17..<22:
            return "Good evening, \(name)! 🌅"
        default:
            return "Hi \(name)! 🌙"
        }
    }
    
    private func getAchievementImageURL(for achievement: Achievement) -> URL? {
        // Return URL to achievement badge image
        Bundle.main.url(forResource: "achievement_\(achievement.rarity.rawValue)", withExtension: "png")
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationManager: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        
        switch response.actionIdentifier {
        case AppConfiguration.Notifications.Actions.startFocus:
            NotificationCenter.default.post(name: .startQuickFocus, object: nil)
            
        case AppConfiguration.Notifications.Actions.take5MinBreak:
            NotificationCenter.default.post(
                name: .startQuickFocus,
                object: nil,
                userInfo: ["duration": 5, "isBreak": true]
            )
            
        case AppConfiguration.Notifications.Actions.take15MinBreak:
            NotificationCenter.default.post(
                name: .startQuickFocus,
                object: nil,
                userInfo: ["duration": 15, "isBreak": true]
            )
            
        case AppConfiguration.Notifications.Actions.viewAchievement:
            if let achievementId = userInfo["achievement_id"] as? String {
                AppCoordinator.shared.handleDeepLink(
                    URL(string: "flowstate://achievements/\(achievementId)")!
                )
            }
            
        case UNNotificationDefaultActionIdentifier:
            // Handle tap on notification
            handleNotificationTap(userInfo: userInfo)
            
        default:
            break
        }
        
        completionHandler()
    }
    
    private func handleNotificationTap(userInfo: [AnyHashable: Any]) {
        guard let type = userInfo["type"] as? String else { return }
        
        switch type {
        case "session_complete":
            AppCoordinator.shared.selectedTab = 0
        case "achievement_unlocked":
            AppCoordinator.shared.handleDeepLink(URL(string: "flowstate://achievements")!)
        default:
            break
        }
    }
}

## 23. Analytics Manager

```swift
// Managers/AnalyticsManager.swift
import Foundation

class AnalyticsManager: ObservableObject {
    static let shared = AnalyticsManager()
    
    private var isConfigured = false
    private let queue = DispatchQueue(label: "com.flowstate.analytics", qos: .background)
    
    func configure() {
        guard !isConfigured else { return }
        
        // Initialize analytics SDK
        if AppEnvironment.isAppStore {
            // Configure production analytics
            configureProduction()
        } else {
            // Configure debug analytics
            configureDebug()
        }
        
        isConfigured = true
    }
    
    func track(event: AnalyticsEvent, properties: [String: Any]? = nil) {
        guard AppConfiguration.Storage.userDefaults.bool(forKey: "analyticsEnabled") else { return }
        
        queue.async {
            self.sendEvent(event.rawValue, properties: properties)
        }
    }
    
    func setUserProperty(_ value: Any?, forKey key: String) {
        queue.async {
            self.updateUserProperty(key, value: value)
        }
    }
    
    func trackScreenView(_ screenName: String) {
        track(event: .screenView, properties: ["screen_name": screenName])
    }
    
    // Session tracking
    func trackSessionStart(mode: FocusMode, duration: Int) {
        track(event: .sessionStarted, properties: [
            AppConfiguration.Analytics.Properties.focusMode: mode.rawValue,
            AppConfiguration.Analytics.Properties.sessionDuration: duration
        ])
    }
    
    func trackSessionComplete(mode: FocusMode, duration: Int, completionRate: Double) {
        track(event: .sessionCompleted, properties: [
            AppConfiguration.Analytics.Properties.focusMode: mode.rawValue,
            AppConfiguration.Analytics.Properties.sessionDuration: duration,
            AppConfiguration.Analytics.Properties.completionRate: completionRate
        ])
    }
    
    // Feature tracking
    func trackFeatureUsed(_ feature: TrackedFeature) {
        track(event: .featureUsed, properties: ["feature": feature.rawValue])
    }
    
    // Premium tracking
    func trackPremiumViewShown(source: String) {
        track(event: .premiumViewShown, properties: ["source": source])
    }
    
    func trackPremiumPurchased(type: String, price: Double) {
        track(event: .premiumPurchased, properties: [
            AppConfiguration.Analytics.Properties.purchaseType: type,
            "price": price
        ])
    }
    
    private func configureProduction() {
        // Configure production analytics service
    }
    
    private func configureDebug() {
        // Configure debug logging
    }
    
    private func sendEvent(_ name: String, properties: [String: Any]?) {
        // Send to analytics service
        print("[Analytics] Event: \(name), Properties: \(properties ?? [:])")
    }
    
    private func updateUserProperty(_ key: String, value: Any?) {
        // Update user property
        print("[Analytics] User Property: \(key) = \(String(describing: value))")
    }
}

enum AnalyticsEvent: String {
    case appLaunched = "app_launched"
    case sessionStarted = "session_started"
    case sessionCompleted = "session_completed"
    case sessionSkipped = "session_skipped"
    case taskCreated = "task_created"
    case taskCompleted = "task_completed"
    case featureUsed = "feature_used"
    case premiumViewShown = "premium_view_shown"
    case premiumPurchased = "premium_purchased"
    case screenView = "screen_view"
}

enum TrackedFeature: String {
    case ambientSounds = "ambient_sounds"
    case appBlocking = "app_blocking"
    case socialGroups = "social_groups"
    case aiRecommendations = "ai_recommendations"
    case dataExport = "data_export"
    case achievements = "achievements"
}

## 24. Cloud Sync Manager

```swift
// Managers/CloudSyncManager.swift
import CloudKit
import CoreData

class CloudSyncManager: ObservableObject {
    static let shared = CloudSyncManager()
    
    @Published var isSyncing = false
    @Published var lastSyncDate: Date?
    @Published var syncError: Error?
    
    private let container: CKContainer
    private let database: CKDatabase
    private let zone = CKRecordZone(zoneName: "FlowStateZone")
    
    init() {
        container = CKContainer(identifier: "iCloud.com.flowstate.app")
        database = container.privateCloudDatabase
        
        setupCloudKit()
    }
    
    private func setupCloudKit() {
        // Create custom zone
        let operation = CKModifyRecordZonesOperation(
            recordZonesToSave: [zone],
            recordZoneIDsToDelete: nil
        )
        
        operation.modifyRecordZonesResultBlock = { result in
            switch result {
            case .success:
                self.setupSubscriptions()
            case .failure(let error):
                print("Failed to create zone: \(error)")
            }
        }
        
        database.add(operation)
    }
    
    private func setupSubscriptions() {
        // Subscribe to changes
        let subscription = CKDatabaseSubscription(subscriptionID: "flow-state-changes")
        
        let notificationInfo = CKSubscription.NotificationInfo()
        notificationInfo.shouldSendContentAvailable = true
        subscription.notificationInfo = notificationInfo
        
        database.save(subscription) { _, error in
            if let error = error {
                print("Failed to create subscription: \(error)")
            }
        }
    }
    
    func performSync() async {
        guard AppConfiguration.Storage.userDefaults.bool(forKey: "iCloudSyncEnabled") else { return }
        
        await MainActor.run {
            isSyncing = true
        }
        
        do {
            // Check account status
            let status = try await container.accountStatus()
            guard status == .available else {
                throw SyncError.iCloudNotAvailable
            }
            
            // Sync sessions
            try await syncSessions()
            
            // Sync tasks
            try await syncTasks()
            
            // Sync achievements
            try await syncAchievements()
            
            // Update last sync date
            await MainActor.run {
                lastSyncDate = Date()
                isSyncing = false
                
                // Save to UserDefaults
                AppConfiguration.Storage.userDefaults.set(lastSyncDate, forKey: "lastSyncDate")
            }
            
        } catch {
            await MainActor.run {
                syncError = error
                isSyncing = false
            }
        }
    }
    
    private func syncSessions() async throws {
        // Fetch local sessions that need syncing
        let unsyncedSessions = try await fetchUnsyncedSessions()
        
        // Convert to CloudKit records
        let records = unsyncedSessions.map { session in
            let record = CKRecord(recordType: "Session", zoneID: zone.zoneID)
            record["startTime"] = session.startTime
            record["duration"] = session.duration
            record["mode"] = session.mode.rawValue
            record["completionRate"] = session.completionPercentage
            record["deviceID"] = getDeviceID()
            return record
        }
        
        // Save to CloudKit
        if !records.isEmpty {
            let operation = CKModifyRecordsOperation(
                recordsToSave: records,
                recordIDsToDelete: nil
            )
            
            operation.perRecordSaveBlock = { recordID, result in
                switch result {
                case .success(let record):
                    // Mark local record as synced
                    self.markSessionAsSynced(recordID: record.recordID.recordName)
                case .failure(let error):
                    print("Failed to save record: \(error)")
                }
            }
            
            database.add(operation)
        }
        
        // Fetch remote changes
        try await fetchRemoteChanges()
    }
    
    private func syncTasks() async throws {
        // Similar implementation for tasks
    }
    
    private func syncAchievements() async throws {
        // Similar implementation for achievements
    }
    
    private func fetchRemoteChanges() async throws {
        let query = CKQuery(recordType: "Session", predicate: NSPredicate(value: true))
        
        let results = try await database.records(matching: query, inZoneWith: zone.zoneID)
        
        for (_, result) in results.matchResults {
            switch result {
            case .success(let record):
                await processRemoteRecord(record)
            case .failure(let error):
                print("Failed to fetch record: \(error)")
            }
        }
    }
    
    private func processRemoteRecord(_ record: CKRecord) async {
        // Process and merge remote record with local data
        // Implement conflict resolution strategy
    }
    
    private func fetchUnsyncedSessions() async throws -> [FocusSession] {
        // Fetch from Core Data
        []
    }
    
    private func markSessionAsSynced(recordID: String) {
        // Update Core Data
    }
    
    private func getDeviceID() -> String {
        UIDevice.current.identifierForVendor?.uuidString ?? "unknown"
    }
    
    enum SyncError: LocalizedError {
        case iCloudNotAvailable
        case syncFailed(String)
        
        var errorDescription: String? {
            switch self {
            case .iCloudNotAvailable:
                return "iCloud is not available. Please check your settings."
            case .syncFailed(let message):
                return "Sync failed: \(message)"
            }
        }
    }
}

## 25. App Store Metadata

```yaml
# App Store Connect Metadata

App Name: Flow State - AI Focus Timer
Subtitle: Deep Work & Productivity

Primary Category: Productivity
Secondary Category: Health & Fitness

Keywords:
- focus timer
- pomodoro
- productivity
- deep work
- concentration
- study timer
- work timer
- flow state
- time management
- distraction blocker
- focus keeper
- tomato timer
- study app
- meditation timer
- mindfulness

Description:
Transform your productivity with Flow State, the AI-powered focus companion that learns your patterns and helps you achieve deep, meaningful work.

KEY FEATURES:

🧠 AI-POWERED RECOMMENDATIONS
- Smart session suggestions based on your productivity patterns
- Personalized focus duration recommendations
- Optimal break timing for sustained performance

🎨 IMMERSIVE FOCUS EXPERIENCE
- Beautiful environmental themes that adapt to time of day
- Ambient sounds and binaural beats for deep concentration
- Particle effects and animations that enhance focus

🚫 ADVANCED DISTRACTION BLOCKING
- Multi-layer app and website blocking
- Integration with iOS Focus modes
- Emergency override after 80% completion

👥 SOCIAL ACCOUNTABILITY
- Join live focus rooms with friends
- Group challenges and leaderboards
- Motivational messages and support

📊 COMPREHENSIVE ANALYTICS
- ML-powered productivity insights
- Beautiful charts and heatmaps
- Export your data in multiple formats

🏆 GAMIFICATION & REWARDS
- Grow your virtual productivity garden
- Unlock achievements and badges
- Daily streaks and challenges

🎯 PREMIUM FEATURES:
- Unlimited tasks and sessions
- All focus modes and themes
- Advanced analytics and insights
- Premium ambient sounds
- Widget and shortcuts support
- Priority support

WHY FLOW STATE?

Unlike basic timers, Flow State uses machine learning to understand your unique productivity rhythms. It knows when you're most focused, suggests the perfect session length, and creates an immersive environment that makes deep work feel effortless.

Join thousands of students, professionals, and creators who've discovered their flow state.

Download now and start your journey to peak productivity!

---

SUBSCRIPTION PRICING:
- Monthly: $9.99
- Yearly: $59.99 (save 50%)
- Lifetime: $149.99

Privacy Policy: https://flowstate.app/privacy
Terms of Service: https://flowstate.app/terms

What's New (Version 1.0):
- Initial release
- AI-powered session recommendations
- Beautiful environmental themes
- Live focus rooms
- Advanced app blocking
- Comprehensive analytics
- 50+ achievements to unlock

Promotional Text:
🚀 Launch Sale - 50% off Lifetime Premium! Transform your productivity with AI-powered focus sessions. Limited time offer!

Screenshots:
1. Home screen with AI recommendation
2. Immersive timer with environmental theme
3. Live focus room with friends
4. Analytics dashboard
5. Achievements and garden
6. Premium features overview

App Preview Video:
- 30-second video showing key features
- Focus on visual appeal and unique features
- Include testimonials from beta users
26. Build Configuration
swift// Configuration/BuildConfiguration.swift
import Foundation

enum BuildConfiguration {
    case debug
    case testFlight
    case appStore
    
    static var current: BuildConfiguration {
        #if DEBUG
        return .debug
        #elseif TESTFLIGHT
        return .testFlight
        #else
        return .appStore
        #endif
    }
    
    var apiBaseURL: String {
        switch self {
        case .debug:
            return "https://dev-api.flowstate.app/v1"
        case .testFlight:
            return "https://staging-api.flowstate.app/v1"
        case .appStore:
            return "https://api.flowstate.app/v1"
        }
    }
    
    var shouldShowDebugMenu: Bool {
        switch self {
        case .debug, .testFlight:
            return true
        case .appStore:
            return false
        }
    }
    
    var analyticsEnabled: Bool {
        switch self {
        case .debug:
            return false
        case .testFlight, .appStore:
            return true
        }
    }
}

// MARK: - Info.plist Configuration

/*
Add to Info.plist:

<key>BGTaskSchedulerPermittedIdentifiers</key>
<array>
    <string>com.flowstate.refresh</string>
    <string>com.flowstate.cleanup</string>
</array>

<key>UIBackgroundModes</key>
<array>
    <string>fetch</string>
    <string>processing</string>
    <string>audio</string>
</array>

<key>NSUserNotificationsUsageDescription</key>
<string>Flow State sends notifications to remind you to take breaks and celebrate your achievements.</string>

<key>NSCameraUsageDescription</key>
<string>Flow State needs camera access to let you customize your profile picture.</string>

<key>NSPhotoLibraryUsageDescription</key>
<string>Flow State needs photo library access to let you customize your profile picture.</string>

<key>NSMicrophoneUsageDescription</key>
<string>Flow State needs microphone access for voice notes in focus sessions.</string>

<key>ITSAppUsesNonExemptEncryption</key>
<false/>

<key>LSApplicationQueriesSchemes</key>
<array>
    <string>instagram</string>
    <string>twitter</string>
    <string>facebook</string>
</array>

<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>flowstate</string>
        </array>
        <key>CFBundleURLName</key>
        <string>com.flowstate.app</string>
    </dict>
</array>
*/

## 27. Testing Setup

```swift
// Tests/FlowStateTests.swift
import XCTest
@testable import Flow_State

class FlowStateTests: XCTestCase {
    var taskViewModel: TaskViewModel!
    var mockContext: NSManagedObjectContext!
    
    override func setUpWithError() throws {
        // Setup in-memory Core Data stack
        mockContext = PersistenceController(inMemory: true).container.viewContext
        taskViewModel = TaskViewModel(context: mockContext)
    }
    
    override func tearDownWithError() throws {
        taskViewModel = nil
        mockContext = nil
    }
    
    // MARK: - Task Tests
    
    func testCreateTask() throws {
        // Given
        let taskTitle = "Test Task"
        let duration: Int64 = 25
        
        // When
        taskViewModel.createTask(
            title: taskTitle,
            totalMinutes: duration,
            blockMinutes: duration,
            breakMinutes: 5
        )
        
        // Then
        XCTAssertEqual(taskViewModel.tasks.count, 1)
        XCTAssertEqual(taskViewModel.tasks.first?.title, taskTitle)
    }
    
    func testUpdateTaskProgress() throws {
        // Given
        taskViewModel.createTask(
            title: "Test",
            totalMinutes: 60,
            blockMinutes: 25,
            breakMinutes: 5
        )
        let task = taskViewModel.tasks.first!
        
        // When
        taskViewModel.updateTaskProgress(task, completedMinutes: 25)
        
        // Then
        XCTAssertEqual(task.completionPercentage, 41.67, accuracy: 0.01)
    }
    
    // MARK: - AI Recommendation Tests
    
    func testRecommendationGeneration() async throws {
        // Given
        let recommender = AISessionRecommender()
        
        // When
        recommender.analyzeAndRecommend()
        
        // Wait for async operation
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        // Then
        XCTAssertNotNil(recommender.recommendation)
        XCTAssertGreaterThan(recommender.recommendation!.confidenceScore, 0)
    }
    
    // MARK: - Achievement Tests
    
    func testAchievementUnlock() throws {
        // Given
        let manager = AchievementManager()
        let initialCount = manager.unlockedAchievements.count
        
        // When
        manager.checkAchievements(for: .sessionCompleted(
            duration: 25,
            mode: .deepWork,
            totalCount: 1,
            time: Date()
        ))
        
        // Then
        XCTAssertGreaterThan(manager.unlockedAchievements.count, initialCount)
    }
    
    // MARK: - Premium Store Tests
    
    func testPremiumFeatureCheck() throws {
        // Given
        let featuresManager = PremiumFeaturesManager()
        
        // When
        let isLocked = featuresManager.requiresPremium(for: .aiInsights)
        
        // Then
        XCTAssertTrue(isLocked) // Should be locked by default
    }
}

// MARK: - UI Tests

class FlowStateUITests: XCTestCase {
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }
    
    func testOnboardingFlow() throws {
        // Test onboarding appears on first launch
        XCTAssertTrue(app.staticTexts["Welcome to\nFlow State"].exists)
        
        // Continue through onboarding
        app.buttons["Get Started"].tap()
        
        // Test goal selection
        XCTAssertTrue(app.staticTexts["What brings you here?"].exists)
    }
    
    func testStartFocusSession() throws {
        // Skip onboarding if needed
        skipOnboardingIfPresent()
        
        // Start a focus session
        app.buttons["Start Focus"].tap()
        
        // Verify timer is running
        XCTAssertTrue(app.staticTexts["25:00"].exists)
    }
    
    private func skipOnboardingIfPresent() {
        if app.buttons["Skip"].exists {
            app.buttons["Skip"].tap()
        }
    }
}
