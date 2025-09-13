import SwiftUI
import FamilyControls

// MARK: - Onboarding Coordinator
class OnboardingCoordinator: ObservableObject {
    @Published var currentPage = 0
    @Published var hasCompletedOnboarding = false
    @Published var userName = ""
    @Published var primaryGoal: ProductivityGoal = .general
    @Published var preferredFocusDuration = 25
    @Published var enableNotifications = false
    @Published var enableAppBlocking = false
    @Published var familyActivitySelection = FamilyActivitySelection()
    
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    
    let totalPages = 7
    
    func nextPage() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            if currentPage < totalPages - 1 {
                currentPage += 1
            } else {
                completeOnboarding()
            }
        }
    }
    
    func previousPage() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            if currentPage > 0 {
                currentPage -= 1
            }
        }
    }
    
    func skipToPage(_ page: Int) {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            currentPage = page
        }
    }
    
    func completeOnboarding() {
        // Save preferences
        saveUserPreferences()
        
        // Mark as completed
        hasSeenOnboarding = true
        hasCompletedOnboarding = true
        
        // Trigger haptic feedback
        HapticStyle.success.trigger()
    }
    
    private func saveUserPreferences() {
        UserDefaults.standard.set(userName, forKey: "userName")
        UserDefaults.standard.set(primaryGoal.rawValue, forKey: "primaryGoal")
        UserDefaults.standard.set(preferredFocusDuration, forKey: "defaultFocusDuration")
        UserDefaults.standard.set(enableNotifications, forKey: "notificationsEnabled")
        UserDefaults.standard.set(enableAppBlocking, forKey: "appBlockingEnabled")
        
        // Save FamilyActivitySelection to app group UserDefaults for use by AppBlockingManager
        if enableAppBlocking && (!familyActivitySelection.applications.isEmpty || !familyActivitySelection.categories.isEmpty) {
            if let appGroupDefaults = UserDefaults(suiteName: "group.com.tobiasfu.Focus-Flow") {
                do {
                    let data = try NSKeyedArchiver.archivedData(withRootObject: familyActivitySelection.applications, requiringSecureCoding: true)
                    appGroupDefaults.set(data, forKey: "applicationTokensData")
                    
                    let categoryData = try NSKeyedArchiver.archivedData(withRootObject: familyActivitySelection.categories, requiringSecureCoding: true)
                    appGroupDefaults.set(categoryData, forKey: "categoryTokensData")
                } catch {
                    print("Failed to save family activity selection: \(error)")
                }
            }
        }
    }
}

// MARK: - Main Onboarding View
struct OnboardingView: View {
    @StateObject private var coordinator = OnboardingCoordinator()
    @State private var dragOffset: CGSize = .zero
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            // Dynamic background
            OnboardingBackground(currentPage: coordinator.currentPage)
            
            VStack(spacing: 0) {
                // Progress indicator
                ProgressIndicator(
                    currentPage: coordinator.currentPage,
                    totalPages: coordinator.totalPages
                )
                .padding(.top, 60)
                .padding(.horizontal)
                
                // Content
                TabView(selection: $coordinator.currentPage) {
                    WelcomePage()
                        .tag(0)
                    
                    PersonalizationPage()
                        .tag(1)
                    
                    GoalSelectionPage()
                        .tag(2)
                    
                    FocusSetupPage()
                        .tag(3)
                    
                    AppBlockingSetupPage()
                        .tag(4)
                    
                    NotificationSetupPage()
                        .tag(5)
                    
                    CompletionPage()
                        .tag(6)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .environmentObject(coordinator)
                
                // Navigation buttons
                NavigationButtons()
                    .environmentObject(coordinator)
                    .padding(.horizontal)
                    .padding(.bottom, 50)
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Background
struct OnboardingBackground: View {
    let currentPage: Int
    @State private var animateGradient = false
    
    var gradientColors: [Color] {
        switch currentPage {
        case 0: return [Color(hex: "667eea"), Color(hex: "764ba2")]
        case 1: return [Color(hex: "f093fb"), Color(hex: "f5576c")]
        case 2: return [Color(hex: "4facfe"), Color(hex: "00f2fe")]
        case 3: return [Color(hex: "43e97b"), Color(hex: "38f9d7")]
        case 4: return [Color(hex: "fa709a"), Color(hex: "fee140")]
        case 5: return [Color(hex: "30cfd0"), Color(hex: "330867")]
        default: return [Color(hex: "667eea"), Color(hex: "764ba2")]
        }
    }
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: gradientColors,
                startPoint: animateGradient ? .topLeading : .bottomTrailing,
                endPoint: animateGradient ? .bottomTrailing : .topLeading
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 3), value: currentPage)
            
            // Floating shapes
            FloatingShapes()
                .opacity(0.1)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                animateGradient = true
            }
        }
    }
}

// MARK: - Progress Indicator
struct ProgressIndicator: View {
    let currentPage: Int
    let totalPages: Int
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<totalPages, id: \.self) { index in
                Capsule()
                    .fill(index <= currentPage ? Color.white : Color.white.opacity(0.3))
                    .frame(width: index == currentPage ? 28 : 8, height: 8)
                    .animation(.spring(response: 0.5), value: currentPage)
            }
        }
    }
}

// MARK: - Navigation Buttons
struct NavigationButtons: View {
    @EnvironmentObject var coordinator: OnboardingCoordinator
    
    var body: some View {
        HStack {
            if coordinator.currentPage > 0 {
                Button(action: coordinator.previousPage) {
                    Image(systemName: "chevron.left")
                        .font(.title3)
                        .foregroundColor(.white)
                        .frame(width: 50, height: 50)
                        .background(Circle().fill(Color.white.opacity(0.2)))
                }
                .transition(.opacity)
            }
            
            Spacer()
            
            if coordinator.currentPage < coordinator.totalPages - 1 {
                Button(action: coordinator.nextPage) {
                    Text(buttonText)
                        .font(AppTheme.Typography.headline)
                        .foregroundColor(.black)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 16)
                        .background(Capsule().fill(Color.white))
                        .shadow(color: .white.opacity(0.5), radius: 10)
                }
            }
        }
    }
        
    private var buttonText: String {
        switch coordinator.currentPage {
        case 0: return "Get Started"
        case coordinator.totalPages - 2: return "Almost Done"
        case coordinator.totalPages - 1: return "Start Focusing"
        default: return "Continue"
        }
    }
}

// MARK: - Page 1: Welcome
struct WelcomePage: View {
    @State private var logoScale: CGFloat = 0.5
    @State private var textOpacity: Double = 0
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // Animated logo
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 150, height: 150)
                    .blur(radius: 20)
                
                Image(systemName: "timer")
                    .font(.system(size: 80))
                    .foregroundColor(.white)
                    .scaleEffect(logoScale)
            }
            
            VStack(spacing: 20) {
                Text("Welcome to\nFocus Flow")
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .opacity(textOpacity)
                
                Text("Your AI-powered productivity companion")
                    .font(AppTheme.Typography.title3)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .opacity(textOpacity)
            }
            
            Spacer()
            Spacer()
        }
        .padding(.horizontal, 40)
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
                logoScale = 1.0
            }
            
            withAnimation(.easeOut(duration: 0.8).delay(0.3)) {
                textOpacity = 1.0
            }
        }
    }
}

// MARK: - Page 2: Personalization
struct PersonalizationPage: View {
    @EnvironmentObject var coordinator: OnboardingCoordinator
    @FocusState private var isNameFieldFocused: Bool
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            VStack(spacing: 20) {
                Text("Let's personalize your experience")
                    .font(AppTheme.Typography.title1)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text("What should we call you?")
                    .font(AppTheme.Typography.body)
                    .foregroundColor(.white.opacity(0.8))
            }
            
            // Name input
            VStack(alignment: .leading, spacing: 8) {
                TextField("Your name", text: $coordinator.userName)
                    .font(AppTheme.Typography.title2)
                    .foregroundColor(.white)
                    .textFieldStyle(OnboardingTextFieldStyle())
                    .focused($isNameFieldFocused)
                
                if !coordinator.userName.isEmpty {
                    Text("Nice to meet you, \(coordinator.userName)! 👋")
                        .font(AppTheme.Typography.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .padding(.horizontal, 40)
            Spacer()
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isNameFieldFocused = true
            }
        }
    }
}

// MARK: - Page 3: Goal Selection
struct GoalSelectionPage: View {
    @EnvironmentObject var coordinator: OnboardingCoordinator
    
    let goals = ProductivityGoal.allCases
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            VStack(spacing: 20) {
                Text("What's your main goal?")
                    .font(AppTheme.Typography.title1)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text("We'll customize Focus Flow to help you achieve it")
                    .font(AppTheme.Typography.body)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 40)
            
            // Goal options
            VStack(spacing: 16) {
                ForEach(goals, id: \ .self) { goal in
                    GoalOption(
                        goal: goal,
                        isSelected: coordinator.primaryGoal == goal,
                        action: { coordinator.primaryGoal = goal }
                    )
                }
            }
            .padding(.horizontal, 40)
            
            Spacer()
        }
    }
}

struct GoalOption: View {
    let goal: ProductivityGoal
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            action()
            HapticStyle.light.trigger()
        }) {
            HStack(spacing: 16) {
                Image(systemName: goal.icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .black : .white)
                    .frame(width: 40)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(goal.title)
                        .font(AppTheme.Typography.headline)
                        .foregroundColor(isSelected ? .black : .white)
                    
                    Text(goal.subtitle)
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(isSelected ? .black.opacity(0.7) : .white.opacity(0.7))
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(isSelected ? .black : .white.opacity(0.5))
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.l)
                    .fill(isSelected ? Color.white : Color.white.opacity(0.2))
            )
        }
    }
}

// MARK: - Page 4: Focus Setup
struct FocusSetupPage: View {
    @EnvironmentObject var coordinator: OnboardingCoordinator
    @State private var sliderValue: Double = 25
    
    let presets = [15, 25, 45, 60, 90]
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            VStack(spacing: 20) {
                Text("How long can you focus?")
                    .font(AppTheme.Typography.title1)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text("Don't worry, you can always adjust this later")
                    .font(AppTheme.Typography.body)
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(.horizontal, 40)
            
            // Timer visualization
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.2), lineWidth: 8)
                    .frame(width: 200, height: 200)
                
                Text("\(coordinator.preferredFocusDuration)")
                    .font(.system(size: 60, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text("minutes")
                    .font(AppTheme.Typography.body)
                    .foregroundColor(.white.opacity(0.8))
                    .offset(y: 40)
            }
            
            // Duration slider
            VStack(spacing: 16) {
                Slider(
                    value: $sliderValue,
                    in: 5...120,
                    step: 5,
                    onEditingChanged: { _ in
                        coordinator.preferredFocusDuration = Int(sliderValue)
                        HapticStyle.light.trigger()
                    }
                )
                .accentColor(.white)
                .padding(.horizontal, 40)
                
                // Quick presets
                HStack(spacing: 12) {
                    ForEach(presets, id: \ .self) { duration in
                        PresetButton(
                            duration: duration,
                            isSelected: coordinator.preferredFocusDuration == duration,
                            action: {
                                coordinator.preferredFocusDuration = duration
                                sliderValue = Double(duration)
                            }
                        )
                    }
                }
                .padding(.horizontal, 40)
            }
            
            Spacer()
        }
        .onAppear {
            sliderValue = Double(coordinator.preferredFocusDuration)
        }
    }
}

struct PresetButton: View {
    let duration: Int
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            action()
            HapticStyle.light.trigger()
        }) {
            Text("\(duration)")
                .font(AppTheme.Typography.subheadline)
                .foregroundColor(isSelected ? .black : .white)
                .frame(width: 50, height: 36)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.white : Color.white.opacity(0.2))
                )
        }
    }
}

// MARK: - Page 5: App Blocking Setup
struct AppBlockingSetupPage: View {
    @EnvironmentObject var coordinator: OnboardingCoordinator
    @StateObject private var appBlockingManager = AdvancedAppBlockingManager()
    @State private var showingPermissionAlert = false
    @State private var showingFamilyActivityPicker = false
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            VStack(spacing: 20) {
                Text("Block distracting apps")
                    .font(AppTheme.Typography.title1)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text("We'll help you stay focused by blocking these apps during focus sessions")
                    .font(AppTheme.Typography.body)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 40)
            
            // Enable toggle
            Toggle(isOn: $coordinator.enableAppBlocking) {
                HStack {
                    Image(systemName: "app.badge.checkmark")
                        .font(.title2)
                        .foregroundColor(.white)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Enable App Blocking")
                            .font(AppTheme.Typography.headline)
                            .foregroundColor(.white)
                        
                        Text(appBlockingManager.isScreenTimeConfigured ? "Screen Time configured" : "Requires Screen Time permissions")
                            .font(AppTheme.Typography.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
            }
            .toggleStyle(OnboardingToggleStyle())
            .padding(.horizontal, 40)
            .onChange(of: coordinator.enableAppBlocking) { enabled in
                if enabled && !appBlockingManager.isScreenTimeConfigured {
                    requestScreenTimePermission()
                } else if enabled && appBlockingManager.isScreenTimeConfigured {
                    showingFamilyActivityPicker = true
                }
            }
            
            // App selection
            if coordinator.enableAppBlocking && appBlockingManager.isScreenTimeConfigured {
                VStack(spacing: 16) {
                    Button(action: {
                        showingFamilyActivityPicker = true
                    }) {
                        HStack {
                            Image(systemName: "square.grid.3x3.fill")
                                .font(.title2)
                                .foregroundColor(.white)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Select Apps to Block")
                                    .font(AppTheme.Typography.headline)
                                    .foregroundColor(.white)
                                
                                Text("Choose apps and categories")
                                    .font(AppTheme.Typography.caption)
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.title3)
                                .foregroundColor(.white.opacity(0.7))
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.m)
                                .fill(Color.white.opacity(0.2))
                        )
                    }
                    
                    if !coordinator.familyActivitySelection.applications.isEmpty || !coordinator.familyActivitySelection.categories.isEmpty {
                        Text("\(coordinator.familyActivitySelection.applications.count) apps and \(coordinator.familyActivitySelection.categories.count) categories selected")
                            .font(AppTheme.Typography.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                .padding(.horizontal, 40)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
            
            Spacer()
        }
        .alert("Screen Time Permission", isPresented: $showingPermissionAlert) {
            Button("Open Settings") {
                if let settingsURL = URL(string: "App-prefs:SCREEN_TIME") {
                    UIApplication.shared.open(settingsURL)
                } else if let generalSettingsURL = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(generalSettingsURL)
                }
            }
            Button("Later", role: .cancel) {}
        } message: {
            Text("Focus Flow needs Screen Time access to block distracting apps. You can grant permission in Settings.")
        }
        .sheet(isPresented: $showingFamilyActivityPicker) {
            FamilyActivityPicker(selection: $coordinator.familyActivitySelection)
                .presentationDetents([.large])
        }
    }
    
    private func requestScreenTimePermission() {
        Task {
            let success = await appBlockingManager.requestScreenTimeAuthorization()
            if success {
                showingFamilyActivityPicker = true
            } else {
                showingPermissionAlert = true
                coordinator.enableAppBlocking = false
            }
        }
    }
}


// MARK: - Page 6: Notification Setup
struct NotificationSetupPage: View {
    @EnvironmentObject var coordinator: OnboardingCoordinator
    @State private var showingNotificationAlert = false
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // Animated bell
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "bell.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.white)
                    .rotationEffect(.degrees(coordinator.enableNotifications ? -15 : 0))
                    .animation(.spring(response: 0.5), value: coordinator.enableNotifications)
            }
            
            VStack(spacing: 20) {
                Text("Stay on track")
                    .font(AppTheme.Typography.title1)
                    .foregroundColor(.white)
                
                Text("Get gentle reminders to start focus sessions and take breaks")
                    .font(AppTheme.Typography.body)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 40)
            
            // Notification types
            VStack(spacing: 16) {
                NotificationOption(
                    icon: "sunrise.fill",
                    title: "Daily Reminders",
                    subtitle: "Start your day with focus"
                )

                NotificationOption(
                    icon: "bell.badge.fill",
                    title: "Session Complete",
                    subtitle: "Celebrate your achievements"
                )

                NotificationOption(
                    icon: "moon.stars.fill",
                    title: "Wind Down",
                    subtitle: "Time to relax and recharge"
                )
            }
            .padding(.horizontal, 40)
            
            // Enable button
            Button(action: {
                coordinator.enableNotifications = true
                showingNotificationAlert = true
            }) {
                Text(coordinator.enableNotifications ? "Notifications Enabled" : "Enable Notifications")
                    .font(AppTheme.Typography.headline)
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        Capsule()
                            .fill(coordinator.enableNotifications ? Color.green : Color.white)
                    )
            }
            .padding(.horizontal, 40)
            
            if !coordinator.enableNotifications {
                Button("Skip for now") {
                    coordinator.nextPage()
                }
                .font(AppTheme.Typography.subheadline)
                .foregroundColor(.white.opacity(0.8))
            }
            
            Spacer()
        }
        .alert("Enable Notifications", isPresented: $showingNotificationAlert) {
            Button("Allow") {
                // Request notification permission
            }
            Button("Not Now", role: .cancel) {
                coordinator.enableNotifications = false
            }
        } message: {
            Text("Focus Flow would like to send you notifications to help you stay productive.")
        }
    }
}

struct NotificationOption: View {
    let icon: String
    let title: String
    let subtitle: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.white)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(AppTheme.Typography.subheadline)
                    .foregroundColor(.white)
                
                Text(subtitle)
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
        }
    }
}

// MARK: - Page 7: Completion
struct CompletionPage: View {
    @EnvironmentObject var coordinator: OnboardingCoordinator
    @State private var showConfetti = false
    @State private var iconScale: CGFloat = 0
    
    var body: some View {
        ZStack {
            // Confetti
            if showConfetti {
                ConfettiView()
                    .allowsHitTesting(false)
            }
            
            VStack(spacing: 40) {
                Spacer()
                
                // Success icon
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 120, height: 120)
                    
                    Image(systemName: "checkmark")
                        .font(.system(size: 50, weight: .bold))
                        .foregroundColor(.green)
                        .scaleEffect(iconScale)
                }
                
                VStack(spacing: 20) {
                    Text("You're all set!")
                        .font(AppTheme.Typography.title1)
                        .foregroundColor(.white)
                    
                    Text("Let's start your first focus session")
                        .font(AppTheme.Typography.body)
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Spacer()
                
                Button(action: coordinator.completeOnboarding) {
                    Text("Start Focusing")
                        .font(AppTheme.Typography.headline)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Capsule().fill(Color.white))
                        .shadow(color: .white.opacity(0.5), radius: 20)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 50)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.2)) {
                iconScale = 1.0
            }
            
            withAnimation(.easeIn.delay(0.5)) {
                showConfetti = true
            }
        }
    }
}

// MARK: - Supporting Components

struct FloatingShapes: View {
    @State private var offset1 = CGSize.zero
    @State private var offset2 = CGSize.zero
    @State private var offset3 = CGSize.zero
    
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.white.opacity(0.1))
                .frame(width: 100, height: 100)
                .offset(offset1)
                .blur(radius: 10)
            
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.1))
                .frame(width: 150, height: 150)
                .rotationEffect(.degrees(45))
                .offset(offset2)
                .blur(radius: 15)
            
            Capsule()
                .fill(Color.white.opacity(0.1))
                .frame(width: 200, height: 80)
                .rotationEffect(.degrees(-30))
                .offset(offset3)
                .blur(radius: 20)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 8).repeatForever(autoreverses: true)) {
                offset1 = CGSize(width: 50, height: -30)
                offset2 = CGSize(width: -80, height: 60)
                offset3 = CGSize(width: 30, height: -100)
            }
        }
    }
}

struct OnboardingTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.m)
                    .fill(Color.white.opacity(0.2))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.m)
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
            )
    }
}

struct OnboardingToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label
            
            Spacer()
            
            ZStack {
                Capsule()
                    .fill(configuration.isOn ? Color.white : Color.white.opacity(0.3))
                    .frame(width: 50, height: 30)
                
                Circle()
                    .fill(configuration.isOn ? Color.black : Color.white)
                    .frame(width: 26, height: 26)
                    .offset(x: configuration.isOn ? 10 : -10)
            }
            .onTapGesture {
                withAnimation(.spring(response: 0.3)) {
                    configuration.isOn.toggle()
                    HapticStyle.light.trigger()
                }
            }
        }
    }
}

// MARK: - Models

enum ProductivityGoal: String, CaseIterable {
    case student = "Student"
    case professional = "Professional"
    case creative = "Creative"
    case general = "General"
    
    var title: String { rawValue }
    
    var subtitle: String {
        switch self {
        case .student:
            return "Study smarter, ace your exams"
        case .professional:
            return "Deep work for career success"
        case .creative:
            return "Find your flow, create magic"
        case .general:
            return "Build better focus habits"
        }
    }
    
    var icon: String {
        switch self {
        case .student: return "book.fill"
        case .professional: return "briefcase.fill"
        case .creative: return "paintbrush.fill"
        case .general: return "star.fill"
        }
    }
    
    var suggestedDuration: Int {
        switch self {
        case .student: return 25
        case .professional: return 45
        case .creative: return 60
        case .general: return 30
        }
    }
}

struct ConfettiView: View {
    @State private var particles: [ConfettiParticle] = []
    
    struct ConfettiParticle: Identifiable {
        let id = UUID()
        let x: CGFloat
        let color: Color
        let size: CGFloat
        var y: CGFloat = -50
        let speed: CGFloat
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles) { particle in
                    Circle()
                        .fill(particle.color)
                        .frame(width: particle.size, height: particle.size)
                        .position(x: particle.x, y: particle.y)
                }
            }
            .onAppear {
                generateParticles(in: geometry.size)
            }
        }
    }
    
    private func generateParticles(in size: CGSize) {
        let colors: [Color] = [.red, .orange, .yellow, .green, .blue, .purple, .pink]
        
        for _ in 0..<100 {
            let particle = ConfettiParticle(
                x: CGFloat.random(in: 0...size.width),
                color: colors.randomElement()!,
                size: CGFloat.random(in: 5...15),
                speed: CGFloat.random(in: 2...5)
            )
            particles.append(particle)
        }
        
        // Animate particles falling
        Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { timer in
            for i in particles.indices {
                particles[i].y += particles[i].speed
                
                // Reset particles that fall off screen
                if particles[i].y > size.height + 50 {
                    particles[i].y = -50
                }
            }
        }
    }
} 
