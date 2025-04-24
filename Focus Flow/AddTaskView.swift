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

    @State private var title = ""
    @State private var totalMinutes: Int64 = 60
    @State private var blockMinutes: Int64 = 25
    @State private var breakMinutes: Int64 = 5

    var body: some View {
        ZStack {
            Color(#colorLiteral(red: 0.2, green: 0.8, blue: 0.8, alpha: 1.0))
                .edgesIgnoringSafeArea(.all)
            
            VStack(alignment: .leading, spacing: 20) {
                Text("Add New Task")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.top, 20)
                
                VStack(spacing: 20) {
                    // Task name field
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Task Name")
                            .font(.headline)
                            .foregroundColor(.white)
                            
                        TextField("", text: $title)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(10)
                            .shadow(color: Color.black.opacity(0.1), radius: 5)
                    }
                    
                    // Time settings
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Time Settings")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        // Total time
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Total Time: \(totalMinutes) mins")
                                .foregroundColor(.white)
                            
                            HStack {
                                Slider(value: Binding(
                                    get: { Double(totalMinutes) },
                                    set: { totalMinutes = Int64($0) }
                                ), in: 5...240, step: 5)
                                .accentColor(.white)
                            }
                        }
                        
                        // Focus block
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Focus Block: \(blockMinutes) mins")
                                .foregroundColor(.white)
                            
                            HStack {
                                Slider(value: Binding(
                                    get: { Double(blockMinutes) },
                                    set: { blockMinutes = Int64($0) }
                                ), in: 1...120, step: 1)
                                .accentColor(.white)
                            }
                        }
                        
                        // Break time
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Break Time: \(breakMinutes) mins")
                                .foregroundColor(.white)
                            
                            HStack {
                                Slider(value: Binding(
                                    get: { Double(breakMinutes) },
                                    set: { breakMinutes = Int64($0) }
                                ), in: 1...30, step: 1)
                                .accentColor(.white)
                            }
                        }
                    }
                }
                .padding()
                
                Spacer()
                
                // Bottom buttons
                HStack {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.gray)
                    .cornerRadius(10)
                    
                    Button("Save") {
                        taskViewModel.addTask(
                            title: title,
                            totalMinutes: totalMinutes,
                            blockMinutes: blockMinutes,
                            breakMinutes: breakMinutes
                        )
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(title.isEmpty ? Color.gray : Color.blue)
                    .cornerRadius(10)
                    .disabled(title.isEmpty)
                }
                .padding(.bottom, 30)
            }
            .padding(.horizontal)
        }
    }
}
