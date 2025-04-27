//
//  AppTheme.swift
//  Focus Flow
//
//  Created by Tobias Fu on 4/24/25.
//

import SwiftUI

// Create a central theme manager for the app
class AppTheme {
    // Main color theme
    struct Colors {
        let primary: Color
        let secondary: Color
        let accent: Color
        let background: Color
        let textPrimary: Color
        let textSecondary: Color
    }
    
    // Modern predefined themes
    static let blue = Colors(
        primary: Color("ThemeColor"),
        secondary: Color("AccentColor"),
        accent: Color.blue,
        background: Color.black.opacity(0.95),
        textPrimary: Color("TextColor"),
        textSecondary: Color.gray
    )
    
    static let green = Colors(
        primary: Color("38B09D"), // Teal/green
        secondary: Color("EBF7F7"),
        accent: Color("22A183"),
        background: Color.black.opacity(0.95),
        textPrimary: Color("2C3E50"),
        textSecondary: Color.gray
    )
    
    static let purple = Colors(
        primary: Color("7B68EE"), // Medium slate blue
        secondary: Color("F0E6FF"),
        accent: Color("6A5ACD"),
        background: Color.black.opacity(0.95),
        textPrimary: Color("2C3E50"),
        textSecondary: Color.gray
    )
    
    // Default theme
    static var current: Colors = blue
    
    // Font sizes
    static let largeTitle: CGFloat = 34
    static let title1: CGFloat = 28
    static let title2: CGFloat = 22
    static let title3: CGFloat = 20
    static let headline: CGFloat = 17
    static let body: CGFloat = 17
    static let callout: CGFloat = 16
    static let subheadline: CGFloat = 15
    static let footnote: CGFloat = 13
    static let caption: CGFloat = 12
    
    // Timer display size
    static let timerDisplay: CGFloat = 100
    
    // Spacing
    static let standardPadding: CGFloat = 16
    static let smallPadding: CGFloat = 8
    static let largePadding: CGFloat = 24
    
    // Animations
    static let standardAnimation: Animation = .easeInOut(duration: 0.3)
    
    // Corner radius
    static let standardCornerRadius: CGFloat = 12
    static let buttonCornerRadius: CGFloat = 25
    
    // Shadow
    static let standardShadow: Shadow = Shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
}

// Extend Color to easily access theme colors
extension Color {
    static var themePrimary: Color { AppTheme.current.primary }
    static var themeSecondary: Color { AppTheme.current.secondary }
    static var themeAccent: Color { AppTheme.current.accent }
    static var themeBackground: Color { AppTheme.current.background }
    static var themeTextPrimary: Color { AppTheme.current.textPrimary }
    static var themeTextSecondary: Color { AppTheme.current.textSecondary }
    
    // Dynamic colors that work in both dark and light modes
    static var timerText: Color {
        return .white
    }
    
    static var tagBackground: Color {
        return Color(UIColor.systemGray6)
    }
    
    static var buttonBackground: Color {
        return Color.gray.opacity(0.3)
    }
}

// MARK: - Shadow Struct
struct Shadow {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

// MARK: - View Extensions for Theme
extension View {
    func standardShadow() -> some View {
        self.shadow(
            color: AppTheme.standardShadow.color,
            radius: AppTheme.standardShadow.radius,
            x: AppTheme.standardShadow.x,
            y: AppTheme.standardShadow.y
        )
    }
    
    func standardCornerRadius() -> some View {
        self.cornerRadius(AppTheme.standardCornerRadius)
    }
    
    func standardAnimation() -> some View {
        self.animation(AppTheme.standardAnimation, value: UUID())
    }
}
