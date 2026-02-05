//
//  AppTheme.swift
//  Swiff IOS
//
//  Created by Agent 5 on 11/21/25.
//  Theme and appearance settings models
//  Updated with new UI Design System
//

import SwiftUI

// App theme mode options
enum ThemeMode: String, Codable, CaseIterable {
    case light = "Light"
    case dark = "Dark"
    case system = "System"

    var displayName: String {
        return rawValue
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .light: return .light
        case .dark: return .dark
        case .system: return nil
        }
    }
}

// App accent color options - Updated with new UI Design System colors
enum AccentColor: String, Codable, CaseIterable {
    case teal = "Teal"  // Primary accent - #4ECDC4
    case cream = "Cream"  // #F5F0E6
    case forestGreen = "Forest Green"  // Legacy
    case blue = "Blue"
    case purple = "Purple"
    case orange = "Orange"  // #F5A623
    case pink = "Pink"
    case red = "Red"
    case indigo = "Indigo"
    case mint = "Mint"
    case yellow = "Yellow"  // #FFCC02

    var color: Color {
        switch self {
        case .teal: return Theme.Colors.teal  // #4ECDC4
        case .cream: return Theme.Colors.creamWhite  // #F5F0E6
        case .forestGreen: return Theme.Colors.green5  // #043F2E
        case .blue: return Color(red: 0.0, green: 0.478, blue: 1.0)  // #007AFF
        case .purple: return Color(red: 0.6, green: 0.4, blue: 0.8)
        case .orange: return Theme.Colors.orangeBadge  // #F5A623
        case .pink: return Color(red: 0.9, green: 0.4, blue: 0.6)
        case .red: return Theme.Colors.errorRed  // #E74C3C
        case .indigo: return Color(red: 0.4, green: 0.4, blue: 0.8)
        case .mint: return Theme.Colors.tealDark  // #3BA99C
        case .yellow: return Theme.Colors.amberYellow  // #FFCC02
        }
    }
}

// App icon options
enum AppIcon: String, Codable, CaseIterable {
    case `default` = "Default"
    case dark = "Dark"
    case minimal = "Minimal"
    case colorful = "Colorful"
    case neon = "Neon"
    case gradient = "Gradient"

    var displayName: String {
        return rawValue
    }

    var iconName: String? {
        switch self {
        case .default: return nil // Default icon
        case .dark: return "AppIcon-Dark"
        case .minimal: return "AppIcon-Minimal"
        case .colorful: return "AppIcon-Colorful"
        case .neon: return "AppIcon-Neon"
        case .gradient: return "AppIcon-Gradient"
        }
    }

    var isPremium: Bool {
        switch self {
        case .default, .dark, .minimal: return false
        case .colorful, .neon, .gradient: return true
        }
    }
}

// Appearance settings model - Updated default to Teal
struct AppearanceSettings: Codable {
    var themeMode: ThemeMode
    var accentColor: AccentColor
    var appIcon: AppIcon

    init(
        themeMode: ThemeMode = .system,
        accentColor: AccentColor = .teal,  // Changed default from forestGreen to teal
        appIcon: AppIcon = .default
    ) {
        self.themeMode = themeMode
        self.accentColor = accentColor
        self.appIcon = appIcon
    }
}
