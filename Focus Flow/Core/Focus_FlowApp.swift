//
//  Focus_FlowApp.swift
//  Focus Flow
//
//  Created by Tobias Fu on 3/2/25.
//

import SwiftUI

@main
struct Focus_FlowApp: App {
    let persistenceController = PersistenceController.shared
    
    // Our single source of truth: the view model
    @StateObject private var taskViewModel: TaskViewModel
    
    // App Blocking Manager
    @StateObject private var blockingManager = AppBlockingManager()
    
    // Productivity Garden Manager
    @StateObject private var gardenManager = ProductivityGardenManager()
    
    // App state
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding: Bool = false
    
    init() {
        // Create the VM with the container's view context
        let context = persistenceController.container.viewContext
        _taskViewModel = StateObject(wrappedValue: TaskViewModel(context: context))
        
        // Set the warm theme (only available theme)
        AppTheme.current = .warm
    }
    
    var body: some Scene {
        WindowGroup {
            Group {
                if hasSeenOnboarding {
                    ContentView()
                } else {
                    OnboardingView()
                }
            }
            .environmentObject(taskViewModel)
            .environmentObject(blockingManager)
            .environmentObject(gardenManager)
            .onAppear {
                if hasSeenOnboarding {
                    // Refresh tasks when app launches
                    taskViewModel.fetchTasks()
                }
            }
        }
    }
}
