//
//  AppTheme.swift
//  Swiff IOS
//
//  Created by Agent 5 on 11/21/25.
//  Theme and appearance settings models
//

import SwiftUI

// AGENT 5: App theme mode options
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

// AGENT 5: App accent color options
enum AccentColor: String, Codable, CaseIterable {
    case forestGreen = "Forest Green"
    case blue = "Blue"
    case purple = "Purple"
    case orange = "Orange"
    case pink = "Pink"
    case red = "Red"
    case teal = "Teal"
    case indigo = "Indigo"
    case mint = "Mint"
    case yellow = "Yellow"

    var color: Color {
        switch self {
        case .forestGreen: return .wiseForestGreen
        case .blue: return .wiseBlue
        case .purple: return Color(red: 0.6, green: 0.4, blue: 0.8)
        case .orange: return Color(red: 0.95, green: 0.55, blue: 0.2)
        case .pink: return Color(red: 0.9, green: 0.4, blue: 0.6)
        case .red: return .wiseError
        case .teal: return Color(red: 0.2, green: 0.7, blue: 0.7)
        case .indigo: return Color(red: 0.4, green: 0.4, blue: 0.8)
        case .mint: return Color(red: 0.4, green: 0.8, blue: 0.7)
        case .yellow: return Color(red: 0.95, green: 0.8, blue: 0.2)
        }
    }
}

// AGENT 5: App icon options
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

// AGENT 5: Appearance settings model
struct AppearanceSettings: Codable {
    var themeMode: ThemeMode
    var accentColor: AccentColor
    var appIcon: AppIcon

    init(
        themeMode: ThemeMode = .system,
        accentColor: AccentColor = .forestGreen,
        appIcon: AppIcon = .default
    ) {
        self.themeMode = themeMode
        self.accentColor = accentColor
        self.appIcon = appIcon
    }
}
