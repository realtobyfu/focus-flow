//
//  Focus_FlowApp.swift
//  Focus Flow
//
//  Created by Tobias Fu on 3/2/25.
//

import SwiftUI

@main
struct Focus_FlowApp: App {
    @StateObject private var taskViewModel = TaskViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(taskViewModel)
        }
    }
}
