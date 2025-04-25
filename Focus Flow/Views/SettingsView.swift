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
    @StateObject private var blockingManager = AppBlockingManager()
    
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
                            // Theme color preview
                            Circle()
                                .fill(themeColorForIndex(index))
                                .frame(width: 20, height: 20)
                            
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
                
                // App Blocking
                Section(header: Text("Focus Tools")) {
                    NavigationLink(destination: AppBlockingSettingsView(blockingManager: blockingManager)) {
                        HStack {
                            Image(systemName: "bell.slash.fill")
                                .foregroundColor(Color.themePrimary)
                                .frame(width: 24, height: 24)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("App Blocking")
                                    .font(.headline)
                                Text(blockingManager.isBlockingEnabled ? "Enabled" : "Disabled")
                                    .font(.caption)
                                    .foregroundColor(blockingManager.isBlockingEnabled ? .green : .gray)
                            }
                        }
                    }
                }
                
                Section(header: Text("Notifications")) {
                    Toggle("Session Completion", isOn: .constant(true))
                        .toggleStyle(SwitchToggleStyle(tint: Color.themePrimary))
                    
                    Toggle("Break Time", isOn: .constant(true))
                        .toggleStyle(SwitchToggleStyle(tint: Color.themePrimary))
                    
                    Toggle("Daily Reminder", isOn: .constant(false))
                        .toggleStyle(SwitchToggleStyle(tint: Color.themePrimary))
                }
                
                Section(header: Text("Sound")) {
                    Toggle("Timer Sound", isOn: .constant(true))
                        .toggleStyle(SwitchToggleStyle(tint: Color.themePrimary))
                    
                    Toggle("Vibration", isOn: .constant(true))
                        .toggleStyle(SwitchToggleStyle(tint: Color.themePrimary))
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
    
    private func themeColorForIndex(_ index: Int) -> Color {
        switch index {
        case 1:
            return Color("38B09D") // Green
        case 2:
            return Color("7B68EE") // Purple
        default:
            return Color("ThemeColor") // Blue
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
