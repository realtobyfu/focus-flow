import Foundation
import UserNotifications

// MARK: - FocusEntity Manager

class FocusEntityManager {
    private var focusEntities: [FocusEntity] = []
    
    func createCustomFocusMode(named: String, blockedApps: [String], completion: @escaping (Bool) -> Void) {
        print("Creating custom focus mode: \(named)")
        
        // Check if a focus mode with this name exists
        if let existingMode = focusEntities.first(where: { $0.name == named }) {
            print("Found existing focus mode: \(existingMode.name)")
            completion(true)
            return
        }
        
        // Create a new focus mode entity
        let focusMode = FocusEntity(
            name: named,
            isEnabled: true,
            icon: "moon.stars.fill",
            blockedApps: blockedApps
        )
        
        focusEntities.append(focusMode)
        
        // Mock API call - would normally interact with iOS Focus API
        print("Created new focus mode: \(focusMode.name)")
        completion(true)
    }
    
    func activateFocusMode(named: String, completion: @escaping (Bool) -> Void) {
        print("Activating focus mode: \(named)")
        
        // Find the focus mode
        if let index = focusEntities.firstIndex(where: { $0.name == named }) {
            // Modify the focus mode in the array
            var focusMode = focusEntities[index]
            focusMode.isActive = true
            focusEntities[index] = focusMode
            
            // Mock API call - would normally interact with iOS Focus API
            print("Focus mode activated: \(focusMode.name)")
            
            // Show a notification to simulate activation
            let content = UNMutableNotificationContent()
            content.title = "Focus Mode Activated"
            content.body = "\(focusMode.name) is now active. Distractions will be minimized."
            content.sound = UNNotificationSound.default
            
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
            
            UNUserNotificationCenter.current().add(request)
            
            completion(true)
        } else {
            print("Focus mode not found: \(named)")
            completion(false)
        }
    }
    
    func deactivateCurrentFocusMode(completion: @escaping (Bool) -> Void) {
        print("Deactivating current focus mode")
        
        // Find active focus mode
        if let index = focusEntities.firstIndex(where: { $0.isActive }) {
            // Modify the focus mode in the array
            var focusMode = focusEntities[index]
            focusMode.isActive = false
            focusEntities[index] = focusMode
            
            // Mock API call - would normally interact with iOS Focus API
            print("Focus mode deactivated: \(focusMode.name)")
            completion(true)
        } else {
            print("No active focus mode found")
            completion(false)
        }
    }
    
    func getAllFocusModes() -> [FocusEntity] {
        return focusEntities
    }
} 