//
//  MacOSAppBlocker.swift
//  Focus Flow
//
//  Created by Tobias Fu on 3/2/25.
//

import Foundation
import AppKit
import Combine

/// Handles actual app blocking on macOS using NSWorkspace
class MacOSAppBlocker: ObservableObject {
    @Published var isMonitoring = false
    @Published var blockedAppsRunning: Set<String> = []
    
    private var workspace: NSWorkspace
    private var cancellables = Set<AnyCancellable>()
    private var blockedBundleIds: Set<String> = []
    private var timer: Timer?
    
    init() {
        self.workspace = NSWorkspace.shared
        setupNotifications()
    }
    
    private func setupNotifications() {
        // Monitor app launches
        workspace.notificationCenter.addObserver(
            self,
            selector: #selector(appDidLaunch(_:)),
            name: NSWorkspace.didLaunchApplicationNotification,
            object: nil
        )
        
        // Monitor app activations
        workspace.notificationCenter.addObserver(
            self,
            selector: #selector(appDidActivate(_:)),
            name: NSWorkspace.didActivateApplicationNotification,
            object: nil
        )
    }
    
    @objc private func appDidLaunch(_ notification: Notification) {
        guard isMonitoring else { return }
        
        if let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
           let bundleId = app.bundleIdentifier {
            checkAndBlockApp(app, bundleId: bundleId)
        }
    }
    
    @objc private func appDidActivate(_ notification: Notification) {
        guard isMonitoring else { return }
        
        if let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
           let bundleId = app.bundleIdentifier {
            checkAndBlockApp(app, bundleId: bundleId)
        }
    }
    
    private func checkAndBlockApp(_ app: NSRunningApplication, bundleId: String) {
        if blockedBundleIds.contains(bundleId) {
            blockedAppsRunning.insert(bundleId)
            
            // Show notification
            showBlockedAppNotification(appName: app.localizedName ?? bundleId)
            
            // Terminate the app after a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                app.terminate()
            }
        }
    }
    
    func startBlocking(blockedIds: Set<String>) {
        self.blockedBundleIds = blockedIds
        self.isMonitoring = true
        
        // Check currently running apps
        checkRunningApps()
        
        // Start periodic check
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            self.checkRunningApps()
        }
    }
    
    func stopBlocking() {
        self.isMonitoring = false
        self.blockedBundleIds.removeAll()
        self.blockedAppsRunning.removeAll()
        timer?.invalidate()
        timer = nil
    }
    
    private func checkRunningApps() {
        guard isMonitoring else { return }
        
        let runningApps = workspace.runningApplications
        
        for app in runningApps {
            if let bundleId = app.bundleIdentifier,
               blockedBundleIds.contains(bundleId) {
                blockedAppsRunning.insert(bundleId)
                
                // Try to terminate the app
                if app.isActive || app.activationPolicy == .regular {
                    app.terminate()
                }
            }
        }
    }
    
    private func showBlockedAppNotification(appName: String) {
        let notification = NSUserNotification()
        notification.title = "App Blocked"
        notification.informativeText = "\(appName) is blocked during your focus session."
        notification.soundName = NSUserNotificationDefaultSoundName
        
        NSUserNotificationCenter.default.deliver(notification)
    }
    
    deinit {
        workspace.notificationCenter.removeObserver(self)
        timer?.invalidate()
    }
}

// MARK: - Integration with AppBlockingManager
extension AppBlockingManager {
    private static let appBlocker = MacOSAppBlocker()
    
    func startBlockingMacOS() {
        guard isBlockingEnabled else { return }
        
        let blockedIds = Set(blockedApps.filter { $0.isBlocked }.map { $0.bundleId })
        Self.appBlocker.startBlocking(blockedIds: blockedIds)
    }
    
    func stopBlockingMacOS() {
        Self.appBlocker.stopBlocking()
    }
}