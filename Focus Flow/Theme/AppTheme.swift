//
//  AppTheme.swift
//  Focus Flow
//
//  Created by Tobias Fu on 4/24/25.
//

import SwiftUI

// MARK: - Main Theme Class
class AppTheme {
    
    // MARK: - Dynamic Color System
    static func primaryGradient(for hour: Int? = nil) -> LinearGradient {
        let currentHour = hour ?? Calendar.current.component(.hour, from: Date())
        let colors = gradientColors(for: currentHour)
        
        return LinearGradient(
            colors: colors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    static func gradientColors(for hour: Int) -> [Color] {
        switch hour {
        case 5..<9: // Early morning - Purple to Pink
            return [Color(hex: "667eea"), Color(hex: "764ba2")]
        case 9..<12: // Morning - Blue to Cyan
            return [Color(hex: "4facfe"), Color(hex: "00f2fe")]
        case 12..<17: // Afternoon - Teal to Green
            return [Color(hex: "43e97b"), Color(hex: "38f9d7")]
        case 17..<21: // Evening - Orange to Pink
            return [Color(hex: "fa709a"), Color(hex: "fee140")]
        default: // Night - Dark Blue to Purple
            return [Color(hex: "30cfd0"), Color(hex: "330867")]
        }
    }
    
    // MARK: - Focus Mode Gradients
    static func gradient(for mode: FocusMode) -> LinearGradient {
        let colors: [Color]
        
        switch mode {
        case .deepWork:
            colors = [Color(hex: "667eea"), Color(hex: "764ba2")]
        case .creativeFlow:
            colors = [Color(hex: "f093fb"), Color(hex: "f5576c")]
        case .learning:
            colors = [Color(hex: "4facfe"), Color(hex: "00f2fe")]
        case .quickSprint:
            colors = [Color(hex: "fa709a"), Color(hex: "fee140")]
        }
        
        return LinearGradient(
            colors: colors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    // MARK: - Semantic Colors
    struct Colors {
        // Primary colors
        static let primary = Color(hex: "667eea")
        static let secondary = Color(hex: "764ba2")
        static let accent = Color(hex: "00f2fe")
        
        // Background colors
        static let background = Color(hex: "0a0a0a")
        static let surface = Color(hex: "1a1a1a")
        static let elevated = Color(hex: "2a2a2a")
        
        // Text colors
        static let textPrimary = Color.white
        static let textSecondary = Color.white.opacity(0.7)
        static let textTertiary = Color.white.opacity(0.5)
        
        // Semantic colors
        static let success = Color(hex: "4ade80")
        static let warning = Color(hex: "fbbf24")
        static let error = Color(hex: "ef4444")
        static let info = Color(hex: "3b82f6")
        
        // Glass effects
        static let glass = Color.white.opacity(0.1)
        static let glassStroke = Color.white.opacity(0.2)
    }
    
    // MARK: - Typography
    struct Typography {
        static let largeTitle = Font.system(size: 34, weight: .bold, design: .rounded)
        static let title1 = Font.system(size: 28, weight: .bold, design: .rounded)
        static let title2 = Font.system(size: 22, weight: .semibold, design: .rounded)
        static let title3 = Font.system(size: 20, weight: .semibold, design: .rounded)
        
        static let headline = Font.system(size: 17, weight: .semibold, design: .default)
        static let body = Font.system(size: 17, weight: .regular, design: .default)
        static let callout = Font.system(size: 16, weight: .regular, design: .default)
        static let subheadline = Font.system(size: 15, weight: .regular, design: .default)
        static let footnote = Font.system(size: 13, weight: .regular, design: .default)
        static let caption = Font.system(size: 12, weight: .regular, design: .default)
        static let caption2 = Font.system(size: 11, weight: .regular, design: .default)
        
        static let timer = Font.system(size: 72, weight: .ultraLight, design: .rounded)
        static let timerLarge = Font.system(size: 100, weight: .ultraLight, design: .rounded)
        static let score = Font.system(size: 48, weight: .bold, design: .rounded)
    }
    
    // MARK: - Spacing
    struct Spacing {
        static let xxs: CGFloat = 4
        static let xs: CGFloat = 8
        static let s: CGFloat = 12
        static let m: CGFloat = 16
        static let l: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 40
        static let xxxl: CGFloat = 48
    }
    
    // MARK: - Corner Radius
    struct CornerRadius {
        static let s: CGFloat = 8
        static let m: CGFloat = 12
        static let l: CGFloat = 16
        static let xl: CGFloat = 20
        static let xxl: CGFloat = 24
        static let full: CGFloat = 1000
    }
    
    // MARK: - Shadows
    struct Shadows {
        static let small = Shadow(
            color: Color.black.opacity(0.1),
            radius: 5,
            x: 0,
            y: 2
        )
        
        static let medium = Shadow(
            color: Color.black.opacity(0.15),
            radius: 10,
            x: 0,
            y: 4
        )
        
        static let large = Shadow(
            color: Color.black.opacity(0.2),
            radius: 20,
            x: 0,
            y: 8
        )
        
        static let glow = Shadow(
            color: Color.white.opacity(0.5),
            radius: 10,
            x: 0,
            y: 0
        )
    }
    
    // MARK: - Animations
    struct Animation {
        static let quick = SwiftUI.Animation.easeInOut(duration: 0.2)
        static let standard = SwiftUI.Animation.easeInOut(duration: 0.3)
        static let smooth = SwiftUI.Animation.easeInOut(duration: 0.5)
        static let slow = SwiftUI.Animation.easeInOut(duration: 0.8)
        static let spring = SwiftUI.Animation.spring(response: 0.6, dampingFraction: 0.8)
    }
}

// MARK: - View Modifiers

extension View {
    func glassEffect(cornerRadius: CGFloat = AppTheme.CornerRadius.l) -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(AppTheme.Colors.glass)
                    .background(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(AppTheme.Colors.glassStroke, lineWidth: 1)
                    )
            )
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.ultraThinMaterial)
                    .opacity(0.5)
            )
    }
    
    func cardStyle(cornerRadius: CGFloat = AppTheme.CornerRadius.l) -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(AppTheme.Colors.surface)
                    .shadow(
                        color: AppTheme.Shadows.medium.color,
                        radius: AppTheme.Shadows.medium.radius,
                        x: AppTheme.Shadows.medium.x,
                        y: AppTheme.Shadows.medium.y
                    )
            )
    }
    
    func glowEffect(color: Color = .white, radius: CGFloat = 10) -> some View {
        self
            .shadow(color: color.opacity(0.5), radius: radius)
            .shadow(color: color.opacity(0.3), radius: radius * 2)
    }
    
    func gradientForeground(colors: [Color]) -> some View {
        self.overlay(
            LinearGradient(
                colors: colors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .mask(self)
    }
}

// MARK: - Custom Components

struct GlassButton: View {
    let title: String
    let icon: String?
    let action: () -> Void
    var isLarge: Bool = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: AppTheme.Spacing.xs) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(isLarge ? .title3 : .body)
                }
                
                Text(title)
                    .font(isLarge ? AppTheme.Typography.headline : AppTheme.Typography.body)
            }
            .foregroundColor(.white)
            .padding(.horizontal, isLarge ? AppTheme.Spacing.l : AppTheme.Spacing.m)
            .padding(.vertical, isLarge ? AppTheme.Spacing.m : AppTheme.Spacing.s)
            .glassEffect(cornerRadius: AppTheme.CornerRadius.full)
        }
    }
}

struct PremiumCard<Content: View>: View {
    let content: Content
    var padding: CGFloat = AppTheme.Spacing.m
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(padding)
            .cardStyle()
    }
}

struct AnimatedGradientBackground: View {
    @State private var animateGradient = false
    let colors: [Color]
    
    var body: some View {
        LinearGradient(
            colors: colors,
            startPoint: animateGradient ? .topLeading : .bottomTrailing,
            endPoint: animateGradient ? .bottomTrailing : .topLeading
        )
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.linear(duration: 3).repeatForever(autoreverses: true)) {
                animateGradient = true
            }
        }
    }
}

// MARK: - Focus Mode Extension

enum FocusMode: String, CaseIterable {
    case deepWork = "Deep Work"
    case creativeFlow = "Creative Flow"
    case learning = "Learning"
    case quickSprint = "Quick Sprint"
    
    var icon: String {
        switch self {
        case .deepWork: return "brain"
        case .creativeFlow: return "paintbrush.fill"
        case .learning: return "book.fill"
        case .quickSprint: return "bolt.fill"
        }
    }
    
    var defaultDuration: Int {
        switch self {
        case .deepWork: return 90
        case .creativeFlow: return 45
        case .learning: return 25
        case .quickSprint: return 15
        }
    }
}

// MARK: - Shadow Model

struct Shadow {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    static var themePrimary: Color { AppTheme.Colors.primary }
    static var themeSecondary: Color { AppTheme.Colors.secondary }
    static var themeBackground: Color { AppTheme.Colors.background }
    static var themeTextPrimary: Color { AppTheme.Colors.textPrimary }
    static var themeTextSecondary: Color { AppTheme.Colors.textSecondary }
}

// MARK: - Haptic Feedback

enum HapticStyle {
    case light, medium, heavy, success, warning, error
    
    func trigger() {
        #if os(iOS)
        switch self {
        case .light:
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        case .medium:
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        case .heavy:
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        case .success:
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        case .warning:
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
        case .error:
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }
        #endif
    }
}
