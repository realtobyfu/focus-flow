import SwiftUI
import Charts

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
    @EnvironmentObject var themeManager: EnvironmentalThemeManager
    @StateObject private var statsManager = StatisticsManager()
    @State private var animateCards = false
    @State private var particleAnimationPhase = 0.0
    
    var body: some View {
        NavigationView {
            ZStack {
                // Dynamic theme gradient background
                if let gradient = themeManager.currentTheme.gradients.first {
                    gradient
                        .ignoresSafeArea()
                } else {
                    LinearGradient(
                        colors: [Color(hex: "667eea"), Color(hex: "764ba2")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .ignoresSafeArea()
                }
                
                // Floating particles
                if themeManager.currentTheme.hasParticles {
                    ParticleEffectView(
                        particleSystem: themeManager.currentTheme.particleEffects,
                        animationPhase: particleAnimationPhase
                    )
                    .allowsHitTesting(false)
                    .onAppear {
                        withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
                            particleAnimationPhase = 1.0
                        }
                    }
                }
                
                ScrollView {
                    VStack(spacing: 25) {
                        // Enhanced Summary Cards with Glass Morphism
                        HStack(spacing: 15) {
                            EnhancedStatCard(
                                icon: "calendar",
                                title: "Today",
                                value: "\(statsManager.getFocusTime(for: .today)) min",
                                color: themeManager.currentTheme.colors.first ?? .orange,
                                theme: themeManager.currentTheme
                            )
                            .scaleEffect(animateCards ? 1.0 : 0.9)
                            .opacity(animateCards ? 1.0 : 0.0)
                            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1), value: animateCards)
                            
                            EnhancedStatCard(
                                icon: "calendar.badge.clock",
                                title: "This Week",
                                value: "\(statsManager.getFocusTime(for: .week)) min",
                                color: themeManager.currentTheme.colors.last ?? .blue,
                                theme: themeManager.currentTheme
                            )
                            .scaleEffect(animateCards ? 1.0 : 0.9)
                            .opacity(animateCards ? 1.0 : 0.0)
                            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2), value: animateCards)
                        }
                        .padding(.horizontal)
                    
                        // Enhanced Weekly Progress Chart
                        EnhancedWeeklyProgressChart(theme: themeManager.currentTheme)
                            .scaleEffect(animateCards ? 1.0 : 0.95)
                            .opacity(animateCards ? 1.0 : 0.0)
                            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.3), value: animateCards)
                            .padding(.horizontal)
                    
                        // Focus Distribution with Glass Morphism
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Focus Distribution")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.horizontal)
                            
                            VStack(spacing: 12) {
                                ForEach(Array(FocusMode.allCases.enumerated()), id: \.element) { index, mode in
                                    HStack {
                                        // Icon with glow
                                        ZStack {
                                            Circle()
                                                .fill(mode.color.opacity(0.2))
                                                .frame(width: 40, height: 40)
                                                .blur(radius: 8)
                                            
                                            Image(systemName: mode.icon)
                                                .foregroundColor(mode.color)
                                                .font(.title3)
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(mode.displayName)
                                                .font(.subheadline)
                                                .fontWeight(.medium)
                                                .foregroundColor(.white)
                                            
                                            // Progress bar
                                            GeometryReader { geometry in
                                                ZStack(alignment: .leading) {
                                                    RoundedRectangle(cornerRadius: 4)
                                                        .fill(.white.opacity(0.1))
                                                        .frame(height: 6)
                                                    
                                                    RoundedRectangle(cornerRadius: 4)
                                                        .fill(mode.color)
                                                        .frame(width: calculateProgressWidth(for: mode, in: geometry.size.width), height: 6)
                                                        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: taskViewModel.minutesForMode(mode))
                                                }
                                            }
                                            .frame(height: 6)
                                        }
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        
                                        Text("\(taskViewModel.minutesForMode(mode)) min")
                                            .font(.caption)
                                            .fontWeight(.medium)
                                            .foregroundColor(.white.opacity(0.8))
                                    }
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 12)
                                    .scaleEffect(animateCards ? 1.0 : 0.95)
                                    .opacity(animateCards ? 1.0 : 0.0)
                                    .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(Double(index) * 0.1 + 0.4), value: animateCards)
                                }
                            }
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(.ultraThinMaterial)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20)
                                            .stroke(
                                                LinearGradient(
                                                    colors: [.white.opacity(0.3), .white.opacity(0.1)],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                ),
                                                lineWidth: 1
                                            )
                                    )
                            )
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Statistics")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                animateCards = true
            }
        }
    }
    
    private func calculateProgressWidth(for mode: FocusMode, in totalWidth: CGFloat) -> CGFloat {
        let totalMinutes = FocusMode.allCases.reduce(0) { $0 + taskViewModel.minutesForMode($1) }
        guard totalMinutes > 0 else { return 0 }
        let percentage = CGFloat(taskViewModel.minutesForMode(mode)) / CGFloat(totalMinutes)
        return totalWidth * percentage
    }
}

// MARK: - Enhanced Stat Card
struct EnhancedStatCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    let theme: EnvironmentalTheme
    
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
            
            VStack(spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.3),
                                    Color.white.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
    }
}

// MARK: - Enhanced Weekly Progress Chart
struct EnhancedWeeklyProgressChart: View {
    let theme: EnvironmentalTheme
    @EnvironmentObject var taskViewModel: TaskViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Weekly Progress")
                .font(.headline)
                .foregroundColor(.white)
            
            // Simple bar chart
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(0..<7) { day in
                    VStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(theme.colors.first ?? .blue)
                            .frame(width: 35, height: CGFloat.random(in: 20...100))
                        
                        Text(dayLabel(for: day))
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
            }
            .frame(height: 120)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
    }
    
    private func dayLabel(for index: Int) -> String {
        ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"][index]
    }
}

#Preview {
    ContentView()
        .environmentObject(TaskViewModel(context: PersistenceController.preview.container.viewContext))
        .environmentObject(AppBlockingManager())
}