//
//  BlockCompletionSheet.swift
//  Focus Flow
//
//  Created by Tobias Fu on 3/8/25.
//
import SwiftUI

// Updated completion sheet
struct BlockCompletionSheet: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var taskViewModel: TaskViewModel
    @ObservedObject var task: TaskEntity
    
    @Binding var currentPhase: TimerView.TimerPhase
    let completedTime: Int64
    
    // Optional callback if parent needs to do something afterward
    var onDismiss: () -> Void
    
    // We'll store a local slider value
    @State private var newCompletionValue: Double = 0.0
    @Environment(\.presentationMode) private var presentationMode
    
    var body: some View {
        VStack(spacing: 30) {
            // Header
            if currentPhase == .focus {
                Text("Focus Block Complete!")
                    .font(.title2)
                    .fontWeight(.bold)
            } else {
                Text("Break Time Complete")
                    .font(.title2)
                    .fontWeight(.bold)
            }
            
            if currentPhase == .focus {
                // Visual indicator
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 70))
                    .foregroundColor(.green)
                
                // Progress section
                VStack(spacing: 20) {
                    if task.completionPercentage < 100 {
                        Text("Update Task Progress")
                            .font(.headline)
                        
                        VStack(spacing: 15) {
                            // Quick buttons
                            HStack(spacing: 20) {
                                progressButton(percentage: 25)
                                progressButton(percentage: 50)
                                progressButton(percentage: 75)
                                progressButton(percentage: 100)
                            }
                            
                            // Or custom slider
                            VStack(spacing: 10) {
                                Text("Or set custom: \(Int(newCompletionValue))%")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                Slider(value: $newCompletionValue, in: 0...100, step: 1)
                                    .accentColor(Color(hex: "3A7CA5"))
                            }
                            .padding(.horizontal)
                            .padding(.top, 10)
                        }
                    } else {
                        Text("Task is complete!")
                            .font(.headline)
                            .foregroundColor(.green)
                    }
                }
            } else {
                // Break completion
                Image(systemName: "cup.and.saucer.fill")
                    .font(.system(size: 70))
                    .foregroundColor(Color(hex: "3A7CA5"))
                
                Text("Ready for the next focus session?")
                    .font(.headline)
            }
            
            Spacer()
            
            // Action buttons
            HStack(spacing: 15) {
                Button(action: {
                    // Just dismiss without applying changes
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("Cancel")
                        .fontWeight(.semibold)
                        .foregroundColor(Color(hex: "3A7CA5"))
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(10)
                }
                
                Button(action: {
                    // Apply progress changes and continue
                    saveTaskAndDismiss()
                }) {
                    Text("Continue")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color(hex: "3A7CA5"))
                        .cornerRadius(10)
                }
            }
            .padding(.bottom, 30)
        }
        .padding()
        .onAppear {
            newCompletionValue = task.completionPercentage
            
            // Automatically update with time progress
            if currentPhase == .focus && completedTime > 0 {
                taskViewModel.updateTaskProgress(task, completedMinutes: completedTime)
                newCompletionValue = task.completionPercentage
            }
        }
    }
    
    // Quick progress selection button
    private func progressButton(percentage: Double) -> some View {
        Button(action: {
            newCompletionValue = percentage
        }) {
            ZStack {
                Circle()
                    .fill(newCompletionValue == percentage ?
                          Color(hex: "3A7CA5") : Color.gray.opacity(0.2))
                    .frame(width: 54, height: 54)
                
                Text("\(Int(percentage))%")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(newCompletionValue == percentage ? .white : .black)
            }
        }
    }
    
    private func saveTaskAndDismiss() {
        // Update task completion if in focus phase
        if currentPhase == .focus {
            task.completionPercentage = newCompletionValue
            do {
                try viewContext.save()
            } catch {
                print("Error saving updated completion: \(error)")
            }
        }
        
        // Dismiss sheet
        presentationMode.wrappedValue.dismiss()
        
        // Call callback for parent view
        onDismiss()
    }
}

// MARK: - Color extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
