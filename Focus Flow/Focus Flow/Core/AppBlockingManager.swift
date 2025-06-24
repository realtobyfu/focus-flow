//
//  AppBlockingManager.swift
//  Focus Flow
//
//  Created by Tobias Fu on 4/25/25.
//

import Foundation
import SwiftUI

// Defines a blocked app
struct BlockedApp: Identifiable, Codable, Equatable {
    var id = UUID()
    var name: String
    var bundleId: String
    var isBlocked: Bool
    
    // For bundled or commonly blocked apps
    static let commonApps: [BlockedApp] = [
        BlockedApp(name: "Instagram", bundleId: "com.instagram.ios", isBlocked: true),
        BlockedApp(name: "Facebook", bundleId: "com.facebook.Facebook", isBlocked: true),
        BlockedApp(name: "Twitter", bundleId: "com.twitter.ios", isBlocked: true),
        BlockedApp(name: "TikTok", bundleId: "com.zhiliaoapp.musically", isBlocked: true),
        BlockedApp(name: "YouTube", bundleId: "com.google.ios.youtube", isBlocked: true),
        BlockedApp(name: "Reddit", bundleId: "com.reddit.Reddit", isBlocked: true),
        BlockedApp(name: "Snapchat", bundleId: "com.toyopagroup.picaboo", isBlocked: true),
        BlockedApp(name: "WhatsApp", bundleId: "net.whatsapp.WhatsApp", isBlocked: false),
        BlockedApp(name: "Discord", bundleId: "com.hammerandchisel.discord", isBlocked: true),
        BlockedApp(name: "Netflix", bundleId: "com.netflix.Netflix", isBlocked: false),
        BlockedApp(name: "Safari", bundleId: "com.apple.mobilesafari", isBlocked: false)
    ]
}

// Manages the app blocking functionality
class AppBlockingManager: ObservableObject {
    @Published var blockedApps: [BlockedApp] = []
    @Published var isBlockingEnabled: Bool = false
    
    // Stores the user's focus blocking settings
    @AppStorage("blockedApps") private var blockedAppsData: Data?
    @AppStorage("isBlockingEnabled") private var isBlockingEnabledStorage: Bool = false
    
    // Initialize with commonly blocked apps
    init() {
        // Load stored apps if available
        if let data = blockedAppsData,
           let decodedApps = try? JSONDecoder().decode([BlockedApp].self, from: data) {
            blockedApps = decodedApps
        } else {
            // First-time setup: load the common apps
            blockedApps = BlockedApp.commonApps
            saveBlockedApps()
        }
        
        isBlockingEnabled = isBlockingEnabledStorage
    }
    
    // Toggle blocking for a specific app
    func toggleBlock(for app: BlockedApp) {
        if let index = blockedApps.firstIndex(where: { $0.id == app.id }) {
            blockedApps[index].isBlocked.toggle()
            saveBlockedApps()
        }
    }
    
    // Add a new app to the blocked list
    func addApp(name: String, bundleId: String, isBlocked: Bool = true) {
        let newApp = BlockedApp(name: name, bundleId: bundleId, isBlocked: isBlocked)
        blockedApps.append(newApp)
        saveBlockedApps()
    }
    
    // Remove an app from the blocked list
    func removeApp(at indexSet: IndexSet) {
        blockedApps.remove(atOffsets: indexSet)
        saveBlockedApps()
    }
    
    // Toggle the app blocking feature on/off
    func toggleBlockingEnabled() {
        isBlockingEnabled.toggle()
        isBlockingEnabledStorage = isBlockingEnabled
    }
    
    // Start blocking apps during a focus session
    func startBlocking() {
        if isBlockingEnabled {
            // In a real app, this would use the appropriate APIs
            // to restrict app usage. For macOS, this might use
            // Screen Time API or a similar approach
            print("Blocking apps started")
        }
    }
    
    // Stop blocking apps
    func stopBlocking() {
        if isBlockingEnabled {
            // Restore normal app access
            print("Blocking apps stopped")
        }
    }
    
    // Save the blocked app list to persistent storage
    private func saveBlockedApps() {
        if let encoded = try? JSONEncoder().encode(blockedApps) {
            blockedAppsData = encoded
        }
    }
    
    // Get list of currently blocked apps
    var currentlyBlockedApps: [BlockedApp] {
        blockedApps.filter { $0.isBlocked }
    }
}
