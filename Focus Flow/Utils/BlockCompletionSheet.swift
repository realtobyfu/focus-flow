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
    
    // Use named colors
    let themeColor = Color("ThemeColor")
    
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
                                    .accentColor(themeColor)
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
                    .foregroundColor(themeColor)
                
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
                        .foregroundColor(themeColor)
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
                        .background(themeColor)
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
                          themeColor : Color.gray.opacity(0.2))
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
