//
//  AddTaskView.swift
//  Focus Flow
//
//  Created by Tobias Fu on 3/8/25.
//

import SwiftUI

struct AddTaskView: View {
    @EnvironmentObject var taskViewModel: TaskViewModel
    @Environment(\.presentationMode) var presentationMode
    
    // Color theme
    let themeColor = Color("ThemeColor")
    let accentColor = Color("AccentColor")
    let textColor = Color("TextColor")
    
    // Form fields
    @State private var title = ""
    @State private var totalMinutesSelection = 2 // Index for 60 mins
    @State private var blockMinutes: Int64 = 25
    @State private var breakMinutes: Int64 = 5
    
    // Predefined total time options (in minutes)
    let totalTimeOptions = [15, 30, 60, 90, 120, 180]
    
    // Session templates
    struct SessionTemplate: Identifiable {
        let id = UUID()
        let name: String
        let blockMinutes: Int64
        let breakMinutes: Int64
        let icon: String
    }
    
    let templates = [
        SessionTemplate(name: "Classic Pomodoro", blockMinutes: 25, breakMinutes: 5, icon: "timer"),
        SessionTemplate(name: "Extended Focus", blockMinutes: 45, breakMinutes: 10, icon: "brain"),
        SessionTemplate(name: "Short Bursts", blockMinutes: 15, breakMinutes: 3, icon: "bolt.fill"),
        SessionTemplate(name: "Custom", blockMinutes: 0, breakMinutes: 0, icon: "slider.horizontal.3")
    ]
    
    @State private var selectedTemplateIndex = 0
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Task name field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Task Name")
                            .font(.headline)
                            .foregroundColor(themeColor)
                        
                        TextField("Enter task name", text: $title)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(10)
                            .shadow(color: Color.black.opacity(0.05), radius: 3)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                            )
                    }
                    
                    // Presets
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Session Template")
                            .font(.headline)
                            .foregroundColor(themeColor)
                        
                        // Template picker with icons
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 15) {
                                ForEach(0..<templates.count, id: \.self) { index in
                                    templateButton(index)
                                }
                            }
                            .padding(.horizontal, 4)
                            .padding(.vertical, 8)
                        }
                    }
                    
                    // Total duration selector
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Total Duration")
                            .font(.headline)
                            .foregroundColor(themeColor)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 15) {
                                ForEach(0..<totalTimeOptions.count, id: \.self) { index in
                                    durationButton(index)
                                }
                            }
                            .padding(.horizontal, 4)
                            .padding(.vertical, 8)
                        }
                    }
                    
                    // Custom interval settings (if selected)
                    if selectedTemplateIndex == templates.count - 1 {
                        customIntervalSettings
                    } else {
                        // Preview of selected template
                        templatePreview
                    }
                    
                    // Submit button
                    submitButton
                        .padding(.top, 10)
                }
                .padding(20)
            }
            .background(Color("AccentColor").opacity(0.3).ignoresSafeArea())
            .navigationTitle("New Task")
            .navigationBarItems(
                trailing: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
                .foregroundColor(themeColor)
            )
        }
        .onAppear {
            // Use the selected template values when view appears
            applyTemplate()
        }
    }
    
    // MARK: - Custom interval settings
    private var customIntervalSettings: some View {
        VStack(spacing: 24) {
            // Focus interval
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Focus Duration")
                        .font(.headline)
                        .foregroundColor(themeColor)
                    
                    Spacer()
                    
                    Text("\(blockMinutes) min")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Slider(value: Binding(
                    get: { Double(blockMinutes) },
                    set: { blockMinutes = Int64($0) }
                ), in: 5...120, step: 5)
                .accentColor(themeColor)
            }
            
            // Break interval
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Break Duration")
                        .font(.headline)
                        .foregroundColor(themeColor)
                    
                    Spacer()
                    
                    Text("\(breakMinutes) min")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Slider(value: Binding(
                    get: { Double(breakMinutes) },
                    set: { breakMinutes = Int64($0) }
                ), in: 1...30, step: 1)
                .accentColor(themeColor)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5)
    }
    
    // MARK: - Template preview
    private var templatePreview: some View {
        HStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: templates[selectedTemplateIndex].icon)
                        .font(.system(size: 18))
                        .foregroundColor(themeColor)
                    
                    Text(templates[selectedTemplateIndex].name)
                        .font(.headline)
                        .foregroundColor(themeColor)
                }
                
                HStack {
                    Label {
                        Text("\(blockMinutes) min focus")
                    } icon: {
                        Image(systemName: "timer")
                            .foregroundColor(.orange)
                    }
                    .font(.subheadline)
                    
                    Spacer()
                    
                    Label {
                        Text("\(breakMinutes) min break")
                    } icon: {
                        Image(systemName: "cup.and.saucer")
                            .foregroundColor(.green)
                    }
                    .font(.subheadline)
                }
                
                Text("Total duration: \(totalTimeOptions[totalMinutesSelection]) min")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5)
    }
    
    // MARK: - Submit button
    private var submitButton: some View {
        Button(action: {
            taskViewModel.addTask(
                title: title,
                totalMinutes: Int64(totalTimeOptions[totalMinutesSelection]),
                blockMinutes: blockMinutes,
                breakMinutes: breakMinutes
            )
            presentationMode.wrappedValue.dismiss()
        }) {
            Text("Create Task")
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(title.isEmpty ? Color.gray : themeColor)
                .cornerRadius(12)
                .shadow(color: title.isEmpty ? Color.clear : themeColor.opacity(0.3), radius: 5)
        }
        .disabled(title.isEmpty)
    }
    
    // MARK: - Helper Views
    
    // Template selection button
    private func templateButton(_ index: Int) -> some View {
        Button(action: {
            selectedTemplateIndex = index
            applyTemplate()
        }) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(selectedTemplateIndex == index ? themeColor : Color.gray.opacity(0.1))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: templates[index].icon)
                        .font(.system(size: 24))
                        .foregroundColor(selectedTemplateIndex == index ? .white : themeColor)
                }
                
                Text(templates[index].name)
                    .font(.caption)
                    .foregroundColor(selectedTemplateIndex == index ? themeColor : .gray)
                    .multilineTextAlignment(.center)
                    .frame(width: 80)
            }
        }
    }
    
    // Duration selection button
    private func durationButton(_ index: Int) -> some View {
        Button(action: {
            totalMinutesSelection = index
        }) {
            VStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(totalMinutesSelection == index ? themeColor : Color.gray.opacity(0.1))
                        .frame(width: 60, height: 50)
                    
                    Text("\(totalTimeOptions[index])")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(totalMinutesSelection == index ? .white : themeColor)
                }
                
                Text("min")
                    .font(.caption)
                    .foregroundColor(totalMinutesSelection == index ? themeColor : .gray)
            }
        }
    }
    
    // MARK: - Helper Functions
    
    // Apply selected template
    private func applyTemplate() {
        if selectedTemplateIndex < templates.count - 1 {
            // Apply predefined template
            blockMinutes = templates[selectedTemplateIndex].blockMinutes
            breakMinutes = templates[selectedTemplateIndex].breakMinutes
        }
        // For "Custom" we leave the current values as is
    }
}
