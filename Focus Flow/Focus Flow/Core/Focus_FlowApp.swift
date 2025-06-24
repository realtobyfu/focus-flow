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
    
    // Theme state
    @AppStorage("selectedTheme") private var selectedTheme: Int = 0
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding: Bool = false
    
    init() {
        // Create the VM with the container's view context
        let context = persistenceController.container.viewContext
        _taskViewModel = StateObject(wrappedValue: TaskViewModel(context: context))
        
        // Set initial theme based on saved preference
        updateTheme()
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
            .onAppear {
                // Ensure theme is applied when app launches
                updateTheme()
                if hasSeenOnboarding {
                    // Refresh tasks when app launches
                    taskViewModel.fetchTasks()
                }
            }
        }
        .onChange(of: selectedTheme) { newValue in
            updateTheme()
        }
    }
    
    private func updateTheme() {
        // Update app theme based on selection
        switch selectedTheme {
        case 1:
            AppTheme.current = AppTheme.green
        case 2:
            AppTheme.current = AppTheme.purple
        default:
            AppTheme.current = AppTheme.blue
        }
    }
}
