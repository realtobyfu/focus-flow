import SwiftUI
import StoreKit
import FamilyControls

@available(iOS 15.0, *)
struct SettingsView: View {
    @StateObject private var premiumStore = PremiumStore()
    
    @AppStorage("userName") private var userName = ""
    @AppStorage("defaultFocusDuration") private var defaultDuration = 25
    @AppStorage("defaultBreakDuration") private var defaultBreakDuration = 5
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("ambientSoundsEnabled") private var ambientSoundsEnabled = true
    @AppStorage("playAmbientDuringBreaks") private var playAmbientDuringBreaks = false
    @AppStorage("timerNotificationSounds") private var timerNotificationSounds = true
    
    @State private var showingPremiumView = false
    
    var body: some View {
        NavigationView {
            Form {
                // Profile Section
                Section {
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .font(.largeTitle)
                            .foregroundColor(AppTheme.Colors.primary)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(userName.isEmpty ? "Set your name" : userName)
                                .font(.headline)
                            Text(premiumStore.isPremium ? "Premium Member" : "Free Plan")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        if !premiumStore.isPremium {
                            Button("Upgrade") {
                                showingPremiumView = true
                            }
                            .font(.caption)
                            .foregroundColor(.primary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Capsule().fill(AppTheme.Colors.accent))
                        }
                    }
                    .padding(.vertical, 8)
                    
                    TextField("Your Name", text: $userName)
                }
                
                // Focus Settings
                Section("Focus Settings") {
                    HStack {
                        Label("Focus Duration", systemImage: "timer")
                        Spacer()
                        Picker("Duration", selection: $defaultDuration) {
                            ForEach([15, 20, 25, 30, 45, 50, 60, 90], id: \.self) { minutes in
                                Text("\(minutes) min").tag(minutes)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                    
                    HStack {
                        Label("Break Duration", systemImage: "pause.circle")
                        Spacer()
                        Picker("Break", selection: $defaultBreakDuration) {
                            ForEach([5, 10, 15], id: \.self) { minutes in
                                Text("\(minutes) min").tag(minutes)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                    
                    Toggle(isOn: $notificationsEnabled) {
                        Label("Notifications", systemImage: "bell.fill")
                    }
                }
                
                // Sound Settings
                Section("Sound Settings") {
                    Toggle(isOn: $ambientSoundsEnabled) {
                        Label("Ambient Sounds", systemImage: "speaker.wave.3.fill")
                    }
                    
                    if ambientSoundsEnabled {
                        Toggle(isOn: $playAmbientDuringBreaks) {
                            Label("Play During Breaks", systemImage: "speaker.wave.2")
                                .font(.subheadline)
                        }
                        .padding(.leading, 32)
                    }
                    
                    Toggle(isOn: $timerNotificationSounds) {
                        Label("Timer Sounds", systemImage: "bell.and.waveform.fill")
                    }
                }
                
                // App Blocking
                if #available(iOS 15.0, *) {
                    Section("App Blocking") {
                        NavigationLink(destination: advancedBlockingView) {
                            HStack {
                                Label("App Blocking Settings", systemImage: "app.badge.checkmark")
                                Spacer()
                                Text("Screen Time")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
//                                Image(systemName: "chevron.right")
//                                    .font(.caption)
//                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                
                // Appearance
                Section("Appearance") {
                    NavigationLink(destination: ThemeSettingsView()) {
                        HStack {
                            Label("Theme", systemImage: "paintbrush.fill")
                            Spacer()
                            Text(getCurrentThemeName())
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // Premium Features
                if !premiumStore.isPremium {
                    Section("Premium Features") {
                        Button(action: { showingPremiumView = true }) {
                            VStack(alignment: .leading, spacing: 12) {
                                Label("Unlock Premium", systemImage: "crown.fill")
                                    .font(.headline)
                                    .foregroundColor(AppTheme.Colors.accent)
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    FeatureRow(icon: "infinity", text: "Unlimited sessions")
                                    FeatureRow(icon: "paintbrush.fill", text: "All themes & sounds")
                                    FeatureRow(icon: "chart.line.uptrend.xyaxis", text: "Advanced analytics")
                                    FeatureRow(icon: "person.2.fill", text: "Group focus rooms")
                                }
                            }
                            .padding(.vertical, 8)
                        }
                        .foregroundColor(.primary)
                    }
                }
                
                // About
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    Link(destination: URL(string: "https://focusflow.app/privacy")!) {
                        HStack {
                            Text("Privacy Policy")
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                        }
                    }
                    
                    Link(destination: URL(string: "https://focusflow.app/terms")!) {
                        HStack {
                            Text("Terms of Service")
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                        }
                    }
                    
                    Button("Rate Focus Flow") {
                        requestReview()
                    }
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showingPremiumView) {
                PremiumUpgradeView()
            }
        }
    }
    
    private func requestReview() {
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            SKStoreReviewController.requestReview(in: scene)
        }
    }

    @available(iOS 15.0, *)
    private var advancedBlockingView: some View {
        AppBlockingSettingsView()
    }
    
    private func getCurrentThemeName() -> String {
        let themeMode = UserDefaults.standard.string(forKey: "themeMode") ?? "automatic"
        if themeMode == "automatic" {
            return "Automatic"
        } else {
            let selectedTheme = UserDefaults.standard.string(forKey: "selectedTheme") ?? "morningMist"
            return EnvironmentalTheme.allThemes.first { $0.id == selectedTheme }?.name ?? "Morning Mist"
        }
    }
}

// MARK: - Feature Row
struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(AppTheme.Colors.accent)
                .frame(width: 20)
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
        }
    }
}


// MARK: - Premium Upgrade View
struct PremiumUpgradeView: View {
    @StateObject private var store = PremiumStore()
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPlan: PremiumPlan = .yearly
    
    var body: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                colors: [AppTheme.Colors.warmPrimary, AppTheme.Colors.warmAccent],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 30) {
                // Close button
                HStack {
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.white.opacity(0.8))
                            .padding(10)
                            .background(Circle().fill(Color.white.opacity(0.2)))
                    }
                }
                .padding()
                
                // Header
                VStack(spacing: 16) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.yellow)
                    
                    Text("Unlock Premium")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("Take your focus to the next level")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding(.top, 20)
                
                // Features
                VStack(alignment: .leading, spacing: 20) {
                    PremiumFeatureRow(icon: "infinity", title: "Unlimited Sessions", subtitle: "No daily limits")
                    PremiumFeatureRow(icon: "paintbrush.fill", title: "All Themes & Sounds", subtitle: "Premium ambience library")
                    PremiumFeatureRow(icon: "chart.line.uptrend.xyaxis", title: "Advanced Analytics", subtitle: "AI-powered insights")
                    PremiumFeatureRow(icon: "person.2.fill", title: "Group Sessions", subtitle: "Focus with friends")
                    PremiumFeatureRow(icon: "sparkles", title: "AI Recommendations", subtitle: "Personalized suggestions")
                }
                .padding(.horizontal, 40)
                
                Spacer()
                
                // Plan selection
                VStack(spacing: 12) {
                    PlanOption(plan: .monthly, isSelected: selectedPlan == .monthly) {
                        selectedPlan = .monthly
                    }
                    
                    PlanOption(plan: .yearly, isSelected: selectedPlan == .yearly) {
                        selectedPlan = .yearly
                    }
                }
                .padding(.horizontal, 30)
                
                // Subscribe button
                Button(action: subscribe) {
                    Text("Start Free Trial")
                        .font(.headline)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            Capsule()
                                .fill(Color.white)
                                .shadow(color: .white.opacity(0.3), radius: 10)
                        )
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 40)
            }
        }
    }
    
    private func subscribe() {
        Task {
            // Find the product that matches the selected plan
            let productId: String
            switch selectedPlan {
            case .monthly:
                productId = "com.flowstate.app.monthly"
            case .yearly:
                productId = "com.flowstate.app.yearly"
            }
            
            // Wait for products to load if needed
            if store.products.isEmpty {
                await store.requestProducts()
            }
            
            // Find and purchase the product
            if let product = store.products.first(where: { $0.id == productId }) {
                let success = await store.purchase(product)
                if success && store.isPremium {
                    dismiss()
                }
            }
        }
    }
}

// MARK: - Supporting Views
struct PremiumFeatureRow: View {
    let icon: String
    let title: String
    let subtitle: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.yellow)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
        }
    }
}

struct PlanOption: View {
    let plan: PremiumPlan
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(plan.displayName)
                            .font(.headline)
                        if plan == .yearly {
                            Text("BEST VALUE")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(Color.green))
                        }
                    }
                    
                    Text(plan.description)
                        .font(.caption)
                        .opacity(0.8)
                }
                
                Spacer()
                
                Text(plan.displayPrice)
                    .font(.title3)
                    .fontWeight(.bold)
            }
            .foregroundColor(isSelected ? .black : .white)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? Color.white : Color.white.opacity(0.2))
            )
        }
    }
}

// MARK: - Models

enum PremiumPlan {
    case monthly, yearly
    
    var displayName: String {
        switch self {
        case .monthly: return "Monthly"
        case .yearly: return "Yearly"
        }
    }
    
    var displayPrice: String {
        switch self {
        case .monthly: return "$9.99/mo"
        case .yearly: return "$59.99/yr"
        }
    }
    
    var description: String {
        switch self {
        case .monthly: return "Billed monthly"
        case .yearly: return "Save 50% • Billed yearly"
        }
    }
}

@available(iOS 15.0, *)
#Preview {
    SettingsView()
}
