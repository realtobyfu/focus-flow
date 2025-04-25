//
//  AppTheme.swift
//  Focus Flow
//
//  Created by Tobias Fu on 4/24/25.
//

import SwiftUI

// Create a central theme manager for the app
struct AppTheme {
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
        background: Color("AccentColor").opacity(0.15),
        textPrimary: Color("TextColor"),
        textSecondary: Color.gray
    )
    
    static let green = Colors(
        primary: Color("38B09D"), // Teal/green
        secondary: Color("EBF7F7"),
        accent: Color("22A183"),
        background: Color("EBF7F7").opacity(0.2),
        textPrimary: Color("2C3E50"),
        textSecondary: Color.gray
    )
    
    static let purple = Colors(
        primary: Color("7B68EE"), // Medium slate blue
        secondary: Color("F0E6FF"),
        accent: Color("6A5ACD"),
        background: Color("F0E6FF").opacity(0.2),
        textPrimary: Color("2C3E50"),
        textSecondary: Color.gray
    )
    
    // Default theme
    static var current: Colors = blue
}

// Extend Color to easily access theme colors
extension Color {
    static var themePrimary: Color { AppTheme.current.primary }
    static var themeSecondary: Color { AppTheme.current.secondary }
    static var themeAccent: Color { AppTheme.current.accent }
    static var themeBackground: Color { AppTheme.current.background }
    static var themeTextPrimary: Color { AppTheme.current.textPrimary }
    static var themeTextSecondary: Color { AppTheme.current.textSecondary }
}
