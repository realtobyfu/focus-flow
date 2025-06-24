import Foundation

// Model for Focus Entity that represents an iOS Focus Mode
struct FocusEntity: Identifiable {
    var id = UUID()
    var name: String
    var isEnabled: Bool
    var isActive: Bool = false
    var icon: String
    var blockedApps: [String]
    
    // Time restrictions (optional)
    var scheduleEnabled: Bool = false
    var startTime: Date?
    var endTime: Date?
    
    // Allow list - contacts that can break through (for real Focus API implementation)
    var allowedContacts: [String] = []
} 