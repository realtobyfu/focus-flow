import SwiftUI

struct ContentView: View {
    @EnvironmentObject var taskViewModel: TaskViewModel
    @StateObject private var blockingManager = AppBlockingManager()
    @State private var showingAddTaskView = false
    @State private var selectedTab = 0
    @State private var showingSettings = false
    @State private var selectedTask: TaskEntity? = nil
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                ZStack {
                    Color.themePrimary
                        .ignoresSafeArea(edges: .top)

                    VStack {
                        HStack {
                            Text(selectedTab == 0 ? "Focus Flow" : (selectedTab == 1 ? "Statistics" : "Settings"))
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            Button(action: {
                                showingSettings = true
                            }) {
                                Image(systemName: "gearshape.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(.white)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 10)
                    }
                }
                .frame(height: 70)
                
                // Content based on selected tab
                TabView(selection: $selectedTab) {
                    // Tasks Tab
                    tasksTab
                        .tag(0)
                    
                    // Statistics Tab
                    statisticsTab
                        .tag(1)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))

                // Custom Tab Bar
                customTabBar
            }
            .sheet(isPresented: $showingAddTaskView) {
                AddTaskView()
                    .environmentObject(taskViewModel)
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
                    .environmentObject(taskViewModel)
                    .environmentObject(blockingManager)
            }
        }
        .accentColor(Color.themePrimary)
        .environmentObject(blockingManager)
    }
    
    // MARK: - Tasks Tab
    var tasksTab: some View {
        ZStack {
            Color.themeBackground
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                // Statistics Summary
                VStack(spacing: 8) {
                    HStack(spacing: 20) {
                        StatisticCard(
                            icon: "checkmark.circle.fill",
                            title: "Completed",
                            value: "\(taskViewModel.completedTasks)",
                            color: Color.green
                        )
                        
                        StatisticCard(
                            icon: "timer",
                            title: "Focus Time",
                            value: taskViewModel.totalFocusTime,
                            color: Color.themePrimary
                        )
                    }
                    .padding(.horizontal)
                }
                .padding(.top, 10)
                
                // Task list header
                HStack {
                    Text("My Tasks")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(Color.themeTextPrimary)
                    
                    Spacer()
                    
                    Menu {
                        Button("All Tasks", action: { taskViewModel.filterMode = .all })
                        Button("In Progress", action: { taskViewModel.filterMode = .inProgress })
                        Button("Completed", action: { taskViewModel.filterMode = .completed })
                    } label: {
                        HStack {
                            Text(taskViewModel.filterMode.rawValue)
                                .foregroundColor(Color.themePrimary)
                            Image(systemName: "chevron.down")
                                .font(.system(size: 14))
                                .foregroundColor(Color.themePrimary)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top, 10)
                
                // Task list
                if taskViewModel.filteredTasks.isEmpty {
                    emptyTasksView
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(taskViewModel.filteredTasks) { task in
                                TaskCardNavigationLink(task: task)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 20)
                    }
                }
                
                Spacer()
                
                // Add Task Button
                Button(action: {
                    showingAddTaskView = true
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 18))
                        Text("Add New Task")
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 24)
                    .background(Color.themePrimary)
                    .cornerRadius(25)
                    .shadow(color: Color.themePrimary.opacity(0.3), radius: 5, x: 0, y: 3)
                }
                .padding(.bottom, 16)
            }
        }
    }
    
    // MARK: - Statistics Tab
    var statisticsTab: some View {
        ZStack {
            Color.themeBackground
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 24) {
                // Weekly Progress Chart
                VStack(alignment: .leading, spacing: 10) {
                    Text("Weekly Progress")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(Color.themeTextPrimary)
                    
                    WeeklyProgressChart(themeColor: Color.themePrimary)
                        .frame(height: 220)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.05), radius: 5)
                }
                .padding(.horizontal)
                
                // Task Completion Stats
                VStack(alignment: .leading, spacing: 10) {
                    Text("Task Stats")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(Color.themeTextPrimary)
                    
                    HStack(spacing: 15) {
                        StatCircle(
                            value: taskViewModel.completedTasksPercentage,
                            label: "Completed",
                            color: Color.green
                        )
                        
                        StatCircle(
                            value: 100 - taskViewModel.completedTasksPercentage,
                            label: "In Progress",
                            color: Color.themePrimary
                        )
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.05), radius: 5)
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .padding(.top, 20)
        }
    }
    
    // Empty state for tasks
    var emptyTasksView: some View {
        VStack(spacing: 16) {
            Spacer()
            
            Image(systemName: "checklist")
                .font(.system(size: 70))
                .foregroundColor(Color.themePrimary.opacity(0.3))
            
            Text("No tasks yet")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(Color.themeTextPrimary.opacity(0.7))
            
            Text("Tap the button below to add your first task")
                .font(.subheadline)
                .foregroundColor(Color.themeTextPrimary.opacity(0.5))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Spacer()
        }
    }
    
    // Custom tab bar
    var customTabBar: some View {
        HStack(spacing: 0) {
            Spacer()
            
            // Tasks Tab
            Button(action: { selectedTab = 0 }) {
                VStack(spacing: 4) {
                    Image(systemName: "list.bullet")
                        .font(.system(size: 22))
                    Text("Tasks")
                        .font(.caption)
                }
                .foregroundColor(selectedTab == 0 ? Color.themePrimary : Color.gray)
                .frame(maxWidth: .infinity)
            }
            
            Spacer()
            
            // Stats Tab
            Button(action: { selectedTab = 1 }) {
                VStack(spacing: 4) {
                    Image(systemName: "chart.bar")
                        .font(.system(size: 22))
                    Text("Stats")
                        .font(.caption)
                }
                .foregroundColor(selectedTab == 1 ? Color.themePrimary : Color.gray)
                .frame(maxWidth: .infinity)
            }
            
            Spacer()
        }
        .padding(.vertical, 12)
        .background(Color.white)
        .shadow(color: Color.black.opacity(0.07), radius: 5, y: -3)
    }
}

// MARK: - Fixed Navigation Task Card

// Fixed task card with NavigationLink to avoid animation issues
struct TaskCardNavigationLink: View {
    @ObservedObject var task: TaskEntity
    
    var body: some View {
        ZStack {
            NavigationLink(destination: TimerView(task: task)) {
                EmptyView()
            }
            .opacity(0)
            
            TaskCard(task: task, themeColor: Color.themePrimary)
                .contentShape(Rectangle())
        }
    }
}

// Task Card Component with working progress bar
struct TaskCard: View {
    @ObservedObject var task: TaskEntity
    var themeColor: Color
    
    var body: some View {
        VStack(spacing: 0) {
            // Task content
            VStack(alignment: .leading, spacing: 12) {
                // Title and completion percentage
                HStack {
                    Text(task.title ?? "Untitled")
                        .font(.headline)
                        .foregroundColor(Color.themeTextPrimary)
                    
                    Spacer()
                    
                    Text("\(Int(task.completionPercentage))%")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(themeColor)
                }
                
                // Progress bar (fixed)
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 8)
                            .cornerRadius(4)
                        
                        // Progress
                        Rectangle()
                            .fill(progressColor)
                            .frame(width: max(0, min(CGFloat(task.completionPercentage) / 100.0 * geometry.size.width, geometry.size.width)), height: 8)
                            .cornerRadius(4)
                    }
                }
                .frame(height: 8)
                
                // Time info
                HStack {
                    // Total time
                    Label("\(task.totalMinutes) min total", systemImage: "clock")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    // Focus/Break time
                    Label("\(task.blockMinutes)/\(task.breakMinutes)", systemImage: "timer")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .help("Focus/Break time in minutes")
                }
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.07), radius: 5)
        }
    }
    
    // Dynamic color based on completion percentage
    var progressColor: Color {
        if task.completionPercentage >= 100 {
            return Color.green
        } else if task.completionPercentage >= 50 {
            return themeColor
        } else {
            return Color.orange
        }
    }
}
