import SwiftUI

// MARK: - Glass Card Component
struct GlassCard: View {
    let content: AnyView
    var padding: CGFloat = AppTheme.Spacing.m
    
    init<Content: View>(padding: CGFloat = AppTheme.Spacing.m, @ViewBuilder content: () -> Content) {
        self.padding = padding
        self.content = AnyView(content())
    }
    
    var body: some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.l)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.l)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            )
            .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
}

// MARK: - Primary Button
struct PrimaryButton: View {
    let title: String
    let icon: String?
    let action: () -> Void
    var style: ButtonStyle = .filled
    
    enum ButtonStyle {
        case filled, outlined, ghost
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .medium))
                }
                Text(title)
                    .font(AppTheme.Typography.headline)
            }
            .foregroundColor(foregroundColor)
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(background)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.full)
                    .stroke(borderColor, lineWidth: style == .outlined ? 2 : 0)
            )
        }
    }
    
    private var foregroundColor: Color {
        switch style {
        case .filled:
            return .white
        case .outlined, .ghost:
            return Color.themePrimary
        }
    }
    
    private var background: some View {
        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.full)
            .fill(backgroundColor)
    }
    
    private var backgroundColor: Color {
        switch style {
        case .filled:
            return Color.themePrimary
        case .outlined, .ghost:
            return Color.clear
        }
    }
    
    private var borderColor: Color {
        switch style {
        case .outlined:
            return Color.themePrimary
        case .filled, .ghost:
            return Color.clear
        }
    }
}

// MARK: - Icon Button
struct IconButton: View {
    let icon: String
    let action: () -> Void
    var size: CGFloat = 44
    var isActive: Bool = false
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(isActive ? Color.themePrimary : Color.primary.opacity(0.6))
                .frame(width: size, height: size)
                .background(
                    Circle()
                        .fill(.ultraThinMaterial)
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                )
        }
    }
}

// MARK: - Section Header
struct SectionHeader: View {
    let title: String
    let subtitle: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(AppTheme.Typography.title2)
                .foregroundColor(.primary)
            
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(AppTheme.Typography.body)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Feature Card
struct FeatureCard: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Circle()
                    .fill(LinearGradient(
                        colors: [color, color.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 56, height: 56)
                    .overlay(
                        Image(systemName: icon)
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(.white)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(AppTheme.Typography.headline)
                        .foregroundColor(.primary)
                    
                    Text(description)
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.m)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.m)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Scale Button Style
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Time Display
struct TimeDisplay: View {
    let hours: Int
    let minutes: Int
    let seconds: Int
    var fontSize: CGFloat = 72
    var showSeconds: Bool = true
    
    var body: some View {
        HStack(spacing: 0) {
            Text(String(format: "%02d", hours))
                .font(.system(size: fontSize, weight: .medium, design: .rounded))
                .monospacedDigit()
            
            Text(":")
                .font(.system(size: fontSize * 0.8, weight: .light, design: .rounded))
                .opacity(0.8)
            
            Text(String(format: "%02d", minutes))
                .font(.system(size: fontSize, weight: .medium, design: .rounded))
                .monospacedDigit()
            
            if showSeconds {
                Text(":")
                    .font(.system(size: fontSize * 0.8, weight: .light, design: .rounded))
                    .opacity(0.8)
                
                Text(String(format: "%02d", seconds))
                    .font(.system(size: fontSize * 0.7, weight: .light, design: .rounded))
                    .monospacedDigit()
                    .opacity(0.7)
            }
        }
        .foregroundColor(.primary)
    }
}

// MARK: - Progress Ring
struct ProgressRing: View {
    let progress: Double
    let lineWidth: CGFloat
    let size: CGFloat
    
    init(progress: Double, lineWidth: CGFloat = 12, size: CGFloat = 200) {
        self.progress = progress
        self.lineWidth = lineWidth
        self.size = size
    }
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.primary.opacity(0.1), lineWidth: lineWidth)
                .frame(width: size, height: size)
            
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    LinearGradient(
                        colors: [Color.themePrimary, Color.themeSecondary],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.3), value: progress)
        }
    }
}

// MARK: - Floating Action Button
struct FloatingActionButton: View {
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(.white)
                .frame(width: 60, height: 60)
                .background(
                    Circle()
                        .fill(LinearGradient(
                            colors: [Color.themePrimary, Color.themeSecondary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                )
                .shadow(color: Color.themePrimary.opacity(0.3), radius: 10, x: 0, y: 5)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Toggle Card
struct ToggleCard: View {
    let title: String
    let description: String
    let icon: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(isOn ? Color.themePrimary : .secondary)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(AppTheme.Typography.headline)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(Color.themePrimary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.m)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.m)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

// MARK: - Navigation Components

struct NavigationContainer: View {
    @Binding var selectedTab: Int
    @State private var showingSettings = false
    @State private var showingAddTask = false
    @EnvironmentObject var themeManager: EnvironmentalThemeManager
    
    var body: some View {
        ZStack {
            // Environmental Background
            EnvironmentalBackground(
                theme: themeManager.currentTheme,
                animated: true
            )
            .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                // Modern Top Navigation Bar
                ModernTopBar(
                    selectedTab: selectedTab,
                    showingSettings: $showingSettings,
                    showingAddTask: $showingAddTask
                )
                
                Spacer()
                
                // Modern Bottom Tab Bar
                ModernTabBar(selectedTab: $selectedTab)
            }
        }
        .onAppear {
            themeManager.updateForTimeOfDay()
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showingAddTask) {
            AddTaskView()
        }
    }
}

// MARK: - Modern Top Bar
struct ModernTopBar: View {
    let selectedTab: Int
    @Binding var showingSettings: Bool
    @Binding var showingAddTask: Bool
    @EnvironmentObject var taskViewModel: TaskViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                // Dynamic Title
                VStack(alignment: .leading, spacing: 4) {
                    Text(currentTabTitle)
                        .font(AppTheme.Typography.title1)
                        .foregroundColor(.primary)
                        .animation(.easeInOut(duration: 0.3), value: selectedTab)
                    
                    Text(currentTabSubtitle)
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(.secondary)
                        .animation(.easeInOut(duration: 0.3), value: selectedTab)
                }
                
                Spacer()
                
                // Contextual Actions
                HStack(spacing: 12) {
                    
                    // Add Task Button (Tasks tab)
                    if selectedTab == 1 {
                        ActionButton(icon: "plus") {
                            showingAddTask = true
                        }
                    }
                    
                    // Settings Button
                    ActionButton(icon: "gearshape.fill") {
                        showingSettings = true
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 16)
        }
        .background(
            // Glass morphism background
            RoundedRectangle(cornerRadius: 0)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            // Bottom border
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.3), Color.white.opacity(0.1)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 0.5),
            alignment: .bottom
        )
    }
    
    private var currentTabTitle: String {
        switch selectedTab {
        case 0: return "Focus Flow"
        case 1: return "Tasks"
        case 2: return "Statistics"
        default: return "Focus Flow"
        }
    }
    
    private var currentTabSubtitle: String {
        switch selectedTab {
        case 0: return "Ready to focus"
        case 1: return "\(taskViewModel.tasks.count) total tasks"
        case 2: return "Track your progress"
        default: return "Ready to focus"
        }
    }
}

// MARK: - Modern Tab Bar
struct ModernTabBar: View {
    @Binding var selectedTab: Int
    @State private var tabBarOffset: CGFloat = 0
    
    var body: some View {
        HStack(spacing: 0) {
            TabBarItem(
                icon: "house.fill",
                title: "Focus",
                isSelected: selectedTab == 0,
                action: { selectTab(0) }
            )
            
            TabBarItem(
                icon: "checklist",
                title: "Tasks", 
                isSelected: selectedTab == 1,
                action: { selectTab(1) }
            )
            
            TabBarItem(
                icon: "chart.bar.fill",
                title: "Stats",
                isSelected: selectedTab == 2,
                action: { selectTab(2) }
            )
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            ZStack {
                // Main glass background
                Color.clear
                    .background(.ultraThinMaterial)
                
                // Gradient overlay
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.1),
                        Color.clear,
                        Color.black.opacity(0.05)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                
                // Top border highlight
                LinearGradient(
                    colors: [Color.white.opacity(0.4), Color.white.opacity(0.1)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(height: 0.5)
                .offset(y: -12)
            }
        )
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: -5)
    }
    
    private func selectTab(_ tab: Int) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            selectedTab = tab
        }
        
        // Haptic feedback
        HapticStyle.light.trigger()
    }
}

// MARK: - Enhanced Tab Bar Item
struct TabBarItem: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack {
                    // Selection indicator background
                    if isSelected {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.themePrimary.opacity(0.2), Color.themePrimary.opacity(0.1)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(width: 44, height: 44)
                            .transition(.scale.combined(with: .opacity))
                    }
                    
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(isSelected ? Color.themePrimary : .secondary)
                        .scaleEffect(isSelected ? 1.1 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
                }
                
                Text(title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(isSelected ? Color.themePrimary : .secondary)
                    .animation(.easeInOut(duration: 0.2), value: isSelected)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(TabButtonStyle())
    }
}

// MARK: - Action Button
struct ActionButton: View {
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.primary)
                .frame(width: 40, height: 40)
                .background(
                    Circle()
                        .fill(.ultraThinMaterial)
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Status Indicator
struct StatusIndicator: View {
    let icon: String
    let color: Color
    let isActive: Bool
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(color)
            
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
                .opacity(isActive ? 1.0 : 0.3)
                .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isActive)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(color.opacity(0.1))
                .overlay(
                    Capsule()
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - Tab Button Style
struct TabButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}