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
    
    init() {
        // Create the VM with the container's view context
        let context = persistenceController.container.viewContext
        _taskViewModel = StateObject(wrappedValue: TaskViewModel(context: context))
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(taskViewModel)
        }
    }
}
