//
//  ThemeSettingsView.swift
//  Focus Flow
//
//  Created by Tobias Fu on 3/2/25.
//

import SwiftUI

struct ThemeSettingsView: View {
    @StateObject private var environmentManager = EnvironmentalThemeManager()
    @AppStorage("themeMode") private var themeMode: String = "automatic"
    @AppStorage("selectedTheme") private var selectedTheme: String = "morningMist"
    @State private var showingCustomColorPicker = false
    
    var body: some View {
        Form {
            // Theme Mode Section
            Section {
                Picker("Theme Mode", selection: $themeMode) {
                    Text("Automatic").tag("automatic")
                    Text("Manual").tag("manual")
                }
                .pickerStyle(.segmented)
                .onChange(of: themeMode) { newMode in
                    updateTheme()
                }
                
                if themeMode == "automatic" {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Time-based themes adjust throughout the day", systemImage: "clock.fill")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(getTimeBasedDescription())
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            } header: {
                Text("Theme Mode")
            }
            
            // Theme Selection (only shown in manual mode)
            if themeMode == "manual" {
                Section {
                    ForEach(EnvironmentalTheme.allThemes, id: \.id) { theme in
                        ThemeRow(
                            theme: theme,
                            isSelected: selectedTheme == theme.id,
                            action: {
                                selectedTheme = theme.id
                                updateTheme()
                            }
                        )
                    }
                } header: {
                    Text("Select Theme")
                }
            }
            
            // Preview Section
            Section {
                ThemePreview(theme: getCurrentTheme())
                    .frame(height: 200)
                    .listRowInsets(EdgeInsets())
            } header: {
                Text("Preview")
            }
            
            // Time Schedule (for automatic mode)
            if themeMode == "automatic" {
                Section {
                    TimeScheduleRow(time: "5:00 AM - 9:00 AM", theme: "Morning Mist", colors: "Purple → Pink")
                    TimeScheduleRow(time: "9:00 AM - 12:00 PM", theme: "Productive Sky", colors: "Blue → Cyan")
                    TimeScheduleRow(time: "12:00 PM - 5:00 PM", theme: "Afternoon Focus", colors: "Teal → Green")
                    TimeScheduleRow(time: "5:00 PM - 9:00 PM", theme: "Evening Glow", colors: "Orange → Pink")
                    TimeScheduleRow(time: "9:00 PM - 5:00 AM", theme: "Nighttime Serenity", colors: "Dark Blue → Purple")
                } header: {
                    Text("Automatic Schedule")
                }
            }
        }
        .navigationTitle("Theme")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            updateTheme()
        }
    }
    
    private func getCurrentTheme() -> EnvironmentalTheme {
        if themeMode == "automatic" {
            return environmentManager.currentTheme
        } else {
            return EnvironmentalTheme.allThemes.first { $0.id == selectedTheme } ?? .morningMist
        }
    }
    
    private func updateTheme() {
        if themeMode == "manual" {
            let theme = EnvironmentalTheme.allThemes.first { $0.id == selectedTheme } ?? .morningMist
            environmentManager.setTheme(theme)
        } else {
            environmentManager.updateForTimeOfDay()
        }
    }
    
    private func getTimeBasedDescription() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        let currentTheme = EnvironmentalThemeManager.getThemeForCurrentTime()
        return "Currently showing: \(currentTheme.name)"
    }
}

// MARK: - Theme Row
struct ThemeRow: View {
    let theme: EnvironmentalTheme
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                // Theme gradient preview
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            colors: theme.colors,
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: 60, height: 40)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(theme.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(theme.timeOfDay)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.accentColor)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Theme Preview
struct ThemePreview: View {
    let theme: EnvironmentalTheme
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: theme.colors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Sample UI elements
            VStack(spacing: 20) {
                Text("25:00")
                    .font(.system(size: 48, weight: .light, design: .rounded))
                    .foregroundColor(.white)
                
                Text("Focus Mode")
                    .font(.title3)
                    .foregroundColor(.white.opacity(0.8))
                
                HStack(spacing: 20) {
                    Image(systemName: "play.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                        .frame(width: 50, height: 50)
                        .background(Circle().fill(Color.white.opacity(0.2)))
                    
                    Image(systemName: "pause.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                        .frame(width: 50, height: 50)
                        .background(Circle().fill(Color.white.opacity(0.2)))
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Time Schedule Row
struct TimeScheduleRow: View {
    let time: String
    let theme: String
    let colors: String
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(time)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(theme)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(colors)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    NavigationView {
        ThemeSettingsView()
    }
}