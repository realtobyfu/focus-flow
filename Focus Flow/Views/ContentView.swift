import SwiftUI

struct ContentView: View {
    @EnvironmentObject var taskViewModel: TaskViewModel
    @State private var selectedTab = 0
    @State private var showingAddTask = false
    
    var body: some View {
        ZStack {
            // Warm beige background matching the design mockup
            Color(red: 0.96, green: 0.93, blue: 0.88)
                .ignoresSafeArea()
            
            TabView(selection: $selectedTab) {
                HomeView(showingAddTask: $showingAddTask)
                    .tabItem {
                        Label("Focus", systemImage: "timer")
                    }
                    .tag(0)
                
                ProductivityGardenView()
                    .tabItem {
                        Label("Garden", systemImage: "leaf.fill")
                    }
                    .tag(1)
                
                StatisticsView()
                    .tabItem {
                        Label("Stats", systemImage: "chart.bar.fill")
                    }
                    .tag(2)
                
                SettingsView()
                    .tabItem {
                        Label("Settings", systemImage: "gearshape.fill")
                    }
                    .tag(3)
            }
            .accentColor(AppTheme.Colors.primary)
        }
        .sheet(isPresented: $showingAddTask) {
            AddTaskView()
        }
        .preferredColorScheme(.light)
    }
}

// MARK: - Statistics View Placeholder
struct StatisticsView: View {
    @EnvironmentObject var taskViewModel: TaskViewModel
    @StateObject private var statsManager = StatisticsManager()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Summary Cards
                    HStack(spacing: 15) {
                        StatisticCard(
                            icon: "calendar",
                            title: "Today",
                            value: "\(statsManager.getFocusTime(for: .today))",
                            color: .orange
                        )
                        
                        StatisticCard(
                            icon: "calendar.badge.clock",
                            title: "This Week",
                            value: "\(statsManager.getFocusTime(for: .week))",
                            color: .blue
                        )
                    }
                    .padding(.horizontal)
                    
                    // Weekly Progress Chart
                    WeeklyProgressChart(themeColor: AppTheme.Colors.primary)
                        .frame(height: 200)
                        .padding(.horizontal)
                    
                    // Focus Distribution
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Focus Distribution")
                            .font(.headline)
                            .foregroundColor(Color(red: 0.3, green: 0.25, blue: 0.2))
                            .padding(.horizontal)
                        
                        ForEach(FocusMode.allCases, id: \.self) { mode in
                            HStack {
                                Image(systemName: mode.icon)
                                    .foregroundColor(mode.color)
                                    .frame(width: 30)
                                
                                Text(mode.displayName)
                                    .font(.subheadline)
                                    .foregroundColor(Color(red: 0.3, green: 0.25, blue: 0.2))
                                
                                Spacer()
                                
                                Text("\(taskViewModel.minutesForMode(mode)) min")
                                    .font(.caption)
                                    .foregroundColor(Color(red: 0.5, green: 0.4, blue: 0.35))
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.vertical)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white.opacity(0.8))
                    )
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .background(Color(red: 0.96, green: 0.93, blue: 0.88))
            .navigationTitle("Statistics")
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(TaskViewModel(context: PersistenceController.preview.container.viewContext))
        .environmentObject(AppBlockingManager())
}