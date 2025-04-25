import SwiftUI

struct ContentView: View {
    @EnvironmentObject var taskViewModel: TaskViewModel
    @State private var showingAddTaskView = false
    @State private var selectedTab = 0
    @State private var showingSettings = false
    
    // Color theme
    let themeColor = Color("ThemeColor") // Primary blue
    let accentColor = Color("AccentColor") // Light blue accent
    let textColor = Color("TextColor") // Dark blue-gray for text
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                ZStack {
                    themeColor
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
            .edgesIgnoringSafeArea(.top)
            .sheet(isPresented: $showingAddTaskView) {
                AddTaskView()
                    .environmentObject(taskViewModel)
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
        }
        .accentColor(themeColor)
    }
    
    // MARK: - Tasks Tab
    var tasksTab: some View {
        ZStack {
            accentColor.opacity(0.3)
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
                            color: themeColor
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
                        .foregroundColor(textColor)
                    
                    Spacer()
                    
                    Menu {
                        Button("All Tasks", action: { taskViewModel.filterMode = .all })
                        Button("In Progress", action: { taskViewModel.filterMode = .inProgress })
                        Button("Completed", action: { taskViewModel.filterMode = .completed })
                    } label: {
                        HStack {
                            Text(taskViewModel.filterMode.rawValue)
                                .foregroundColor(Color("ThemeColor"))
                            Image(systemName: "chevron.down")
                                .font(.system(size: 14))
                                .foregroundColor(Color("ThemeColor"))
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
                                TaskCard(task: task, themeColor: Color("ThemeColor"))
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
                    .background(themeColor)
                    .cornerRadius(25)
                    .shadow(color: themeColor.opacity(0.3), radius: 5, x: 0, y: 3)
                }
                .padding(.bottom, 16)
            }
        }
    }
    
    // MARK: - Statistics Tab
    var statisticsTab: some View {
        ZStack {
            accentColor.opacity(0.3)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 24) {
                // Weekly Progress Chart
                VStack(alignment: .leading, spacing: 10) {
                    Text("Weekly Progress")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(textColor)
                    
                    WeeklyProgressChart(themeColor: themeColor)
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
                        .foregroundColor(textColor)
                    
                    HStack(spacing: 15) {
                        StatCircle(
                            value: taskViewModel.completedTasksPercentage,
                            label: "Completed",
                            color: Color.green
                        )
                        
                        StatCircle(
                            value: 100 - taskViewModel.completedTasksPercentage,
                            label: "In Progress",
                            color: themeColor
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
                .foregroundColor(Color("ThemeColor").opacity(0.3))
            
            Text("No tasks yet")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(Color("TextColor").opacity(0.7))
            
            Text("Tap the button below to add your first task")
                .font(.subheadline)
                .foregroundColor(Color("TextColor").opacity(0.5))
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
                .foregroundColor(selectedTab == 0 ? Color("ThemeColor") : Color.gray)
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
                .foregroundColor(selectedTab == 1 ? themeColor : Color.gray)
                .frame(maxWidth: .infinity)
            }
            
            Spacer()
        }
        .padding(.vertical, 12)
        .background(Color.white)
        .shadow(color: Color.black.opacity(0.07), radius: 5, y: -3)
    }
}

// MARK: - Supporting Components

// Task Card Component with working progress bar
struct TaskCard: View {
    @ObservedObject var task: TaskEntity
    var themeColor: Color
    
    var body: some View {
        NavigationLink(destination: TimerView(task: task)) {
            VStack(spacing: 0) {
                // Task content
                VStack(alignment: .leading, spacing: 12) {
                    // Title and completion percentage
                    HStack {
                        Text(task.title ?? "Untitled")
                            .font(.headline)
                            .foregroundColor(Color(hex: "2C3E50"))
                        
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

// Statistic Card Component
struct StatisticCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(Color(hex: "2C3E50"))
            }
            
            Spacer()
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5)
    }
}

// Circular Statistic Component
struct StatCircle: View {
    let value: Double
    let label: String
    let color: Color
    
    var body: some View {
        VStack {
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 10)
                    .frame(width: 100, height: 100)
                
                Circle()
                    .trim(from: 0, to: CGFloat(min(value, 100)) / 100.0)
                    .stroke(color, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .frame(width: 100, height: 100)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeOut, value: value)
                
                VStack(spacing: 2) {
                    Text("\(Int(value))%")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(color)
                }
            }
            
            Text(label)
                .font(.footnote)
                .foregroundColor(.secondary)
                .padding(.top, 5)
        }
        .frame(maxWidth: .infinity)
    }
}

// Weekly Progress Chart
struct WeeklyProgressChart: View {
    let themeColor: Color
    
    // Sample data (would be provided by the ViewModel in a real app)
    let weekdays = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
    let focusMinutes = [45, 60, 30, 75, 25, 10, 50]
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 10) {
            ForEach(0..<weekdays.count, id: \.self) { index in
                VStack(spacing: 8) {
                    // Bar
                    RoundedRectangle(cornerRadius: 4)
                        .fill(themeColor.opacity(Date().dayOfWeek == index + 1 ? 1.0 : 0.7))
                        .frame(width: 30, height: max(20, CGFloat(focusMinutes[index]) * 1.5))
                    
                    // Day label
                    Text(weekdays[index])
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal)
    }
}

// Settings View
struct SettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            List {
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
            )
        }
    }
}
