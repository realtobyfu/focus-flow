//
//  BlockCompletionSheet.swift
//  Focus Flow
//
//  Created by Tobias Fu on 3/8/25.
//
import SwiftUI

struct BlockCompletionSheet: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var task: TaskEntity
    
    @Binding var currentPhase: TimerView.TimerPhase
    
    // Optional callback if parent needs to do something afterward
    var onDismiss: () -> Void
    
    // We'll store a local slider value
    @State private var newCompletionValue: Double = 0.0
    @Environment(\.presentationMode) private var presentationMode
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Block Finished")
                    .font(.title2)
                    .padding(.top, 10)
                
                // Mark fully complete button
                Button(action: {
                    task.completionPercentage = 100
                    saveTaskAndDismiss()
                }) {
                    Text("Mark Task as Complete (100%)")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .padding(.horizontal)
                
                // Or partial progress
                Text("Or update progress so far:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Slider(value: $newCompletionValue, in: 0...100, step: 1)
                    .padding(.horizontal)
                
                Text("\(Int(newCompletionValue))% completed")
                    .font(.headline)
                
                Spacer()
                
                HStack {
                    Button("Save") {
                        task.completionPercentage = newCompletionValue
                        saveTaskAndDismiss()
                    }
                    .font(.headline)
                    .padding()
                    
                    Spacer()
                    
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .font(.headline)
                    .padding()
                }
                .padding(.horizontal)
            }
            .onAppear {
                newCompletionValue = task.completionPercentage
            }
            .navigationBarTitle("Update Progress", displayMode: .inline)
        }
    }
    
    private func saveTaskAndDismiss() {
        // Switch phases
        if currentPhase == .focus {
            currentPhase = .breakTime
        } else {
            currentPhase = .focus
        }
        
        // Save to Core Data
        do {
            try viewContext.save()
        } catch {
            print("Error saving updated completion: \(error)")
        }
        
        // Dismiss
        presentationMode.wrappedValue.dismiss()
        
        // Optional callback for parent
        onDismiss()
    }
}
