//
//  SettingsView.swift
//  Focus Flow
//
//  Created by Tobias Fu on 4/24/25.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var taskViewModel: TaskViewModel
    @AppStorage("selectedTheme") private var selectedTheme: Int = 0
    
    // Theme options
    let themes = ["Blue", "Green", "Purple"]
    
    var body: some View {
        NavigationView {
            List {
                // Theme Settings
                Section(header: Text("App Theme")) {
                    ForEach(0..<themes.count, id: \.self) { index in
                        HStack {
                            Text(themes[index])
                            Spacer()
                            if selectedTheme == index {
                                Image(systemName: "checkmark")
                                    .foregroundColor(Color.themePrimary)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            withAnimation {
                                selectedTheme = index
                                updateTheme()
                            }
                        }
                    }
                }
                
                Section(header: Text("Notifications")) {
                    Toggle("Session Completion", isOn: .constant(true))
                    Toggle("Break Time", isOn: .constant(true))
                    Toggle("Daily Reminder", isOn: .constant(false))
                }
                
                Section(header: Text("Sound")) {
                    Toggle("Timer Sound", isOn: .constant(true))
                    Toggle("Vibration", isOn: .constant(true))
                }
                
                Section(header: Text("Default Timer")) {
                    HStack {
                        Text("Focus Duration")
                        Spacer()
                        Text("25 min")
                            .foregroundColor(.gray)
                    }
                    
                    HStack {
                        Text("Break Duration")
                        Spacer()
                        Text("5 min")
                            .foregroundColor(.gray)
                    }
                }
                
                Section(header: Text("App Data")) {
                    Button(action: {
                        // Reset all tasks (for testing)
                        taskViewModel.tasks.forEach { task in
                            taskViewModel.resetTask(task)
                        }
                    }) {
                        HStack {
                            Text("Reset All Tasks")
                                .foregroundColor(.red)
                            Spacer()
                        }
                    }
                }
                
                Section(header: Text("About")) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.gray)
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Settings")
            .navigationBarItems(
                trailing: Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                }
                .foregroundColor(Color.themePrimary)
            )
        }
        .onAppear {
            // Load current theme
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
