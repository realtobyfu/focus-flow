//
//  ContentView.swift
//  Focus Flow
//
//  Created by Tobias Fu on 3/2/25.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var taskViewModel: TaskViewModel
    @State private var showingAddTaskView = false

    var body: some View {
        ZStack {
            // Background color to match the teal in your design
            Color(#colorLiteral(red: 0.2, green: 0.8, blue: 0.8, alpha: 1.0))
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                // Title
                Text("Tasks")
                    .font(.system(size: 38, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                
                // Task list
                ScrollView {
                    VStack(spacing: 20) {
                        ForEach(taskViewModel.tasks) { task in
                            TaskCard(task: task)
                        }
                    }
                    .padding(.horizontal)
                }
                
                Spacer()
                
                // Add button
                HStack {
                    Spacer()
                    Button(action: {
                        showingAddTaskView = true
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 60, height: 60)
                                .shadow(color: Color.black.opacity(0.2), radius: 5)
                            
                            Image(systemName: "plus")
                                .font(.system(size: 30, weight: .bold))
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(.trailing, 20)
                    .padding(.bottom, 10)
                }
                
                // Bottom navigation bar
                HStack(spacing: 0) {
                    NavBarButton(icon: "house.fill", isActive: true)
                    NavBarButton(icon: "calendar", isActive: false)
                    NavBarButton(icon: "gearshape", isActive: false)
                }
                .frame(height: 50)
                .background(Color.blue)
                .cornerRadius(0)
            }
        }
        .sheet(isPresented: $showingAddTaskView) {
            AddTaskView()
                .environmentObject(taskViewModel)
        }
    }
}

// Task Card Component that looks like your design
struct TaskCard: View {
    @ObservedObject var task: TaskEntity
    
    var body: some View {
        NavigationLink(destination: TimerView(task: task)) {
            ZStack {
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.1), radius: 5)
                
                VStack(alignment: .leading, spacing: 10) {
                    // Progress bar at top
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 15)
                            .cornerRadius(7.5)
                        
                        Rectangle()
                            .fill(Color.black)
                            .frame(width: min(CGFloat(task.completionPercentage) / 100.0 * UIScreen.main.bounds.width * 0.75, UIScreen.main.bounds.width * 0.75), height: 15)
                            .cornerRadius(7.5)
                    }
                    
                    Text(task.title ?? "Untitled")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                    
                    HStack {
                        // Clock icon with time
                        Image(systemName: "clock")
                            .foregroundColor(.red)
                        
                        Text("\(task.totalMinutes) mins")
                            .foregroundColor(.black)
                        
                        Spacer()
                        
                        // Play button
                        Circle()
                            .fill(Color.red)
                            .frame(width: 30, height: 30)
                            .overlay(
                                Image(systemName: "play.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(.white)
                            )
                    }
                }
                .padding()
            }
            .frame(height: 130)
        }
    }
}

// Bottom navigation bar button
struct NavBarButton: View {
    let icon: String
    let isActive: Bool
    
    var body: some View {
        Button(action: {}) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
        }
    }
}
