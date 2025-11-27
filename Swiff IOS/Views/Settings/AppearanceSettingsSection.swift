//
//  AppearanceSettingsSection.swift
//  Swiff IOS
//
//  Created by Agent 5 on 11/21/25.
//  Appearance settings with theme, color scheme, and app icon customization
//

import SwiftUI
import Combine

struct AppearanceSettingsSection: View {
    @StateObject private var userSettings = UserSettings.shared
    @State private var showingIconPicker = false
    @State private var selectedThemeMode: ThemeMode = .system
    @State private var selectedAccentColor: AccentColor = .forestGreen
    @State private var selectedAppIcon: AppIcon = .default
    @State private var selectedTabBarStyle: TabBarStyle = .labels

    var body: some View {
        Section {
            // Theme mode selector
            VStack(alignment: .leading, spacing: 12) {
                Text("Theme")
                    .font(.spotifyBodyMedium)
                    .foregroundColor(.wisePrimaryText)

                HStack(spacing: 12) {
                    ForEach(ThemeMode.allCases, id: \.self) { mode in
                        ThemePreviewButton(
                            mode: mode,
                            isSelected: selectedThemeMode == mode,
                            action: {
                                selectedThemeMode = mode
                                userSettings.themeMode = mode.rawValue
                            }
                        )
                    }
                }
            }
            .padding(.vertical, 8)

            // Color scheme picker
            VStack(alignment: .leading, spacing: 12) {
                Text("Accent Color")
                    .font(.spotifyBodyMedium)
                    .foregroundColor(.wisePrimaryText)

                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    ForEach(AccentColor.allCases, id: \.self) { color in
                        ColorPickerButton(
                            color: color,
                            isSelected: selectedAccentColor == color,
                            action: {
                                selectedAccentColor = color
                                userSettings.accentColor = color.rawValue
                            }
                        )
                    }
                }
            }
            .padding(.vertical, 8)

            // App icon selector
            Button(action: {
                showingIconPicker = true
            }) {
                HStack {
                    Image(systemName: "app.badge")
                        .foregroundColor(.wiseBlue)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("App Icon")
                            .font(.spotifyBodyMedium)
                            .foregroundColor(.wisePrimaryText)
                        Text(selectedAppIcon.displayName)
                            .font(.spotifyCaptionMedium)
                            .foregroundColor(.wiseSecondaryText)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14))
                        .foregroundColor(.wiseSecondaryText)
                }
            }

            // Tab bar style selector
            VStack(alignment: .leading, spacing: 12) {
                Text("Tab Bar Style")
                    .font(.spotifyBodyMedium)
                    .foregroundColor(.wisePrimaryText)

                HStack(spacing: 12) {
                    ForEach(TabBarStyle.allCases, id: \.self) { style in
                        TabBarStyleButton(
                            style: style,
                            isSelected: selectedTabBarStyle == style,
                            action: {
                                HapticManager.shared.selection()
                                selectedTabBarStyle = style
                                userSettings.tabBarStyle = style.rawValue
                            }
                        )
                    }
                }
            }
            .padding(.vertical, 8)

        } header: {
            Text("Appearance")
                .font(.spotifyLabelSmall)
                .foregroundColor(.wiseSecondaryText)
        } footer: {
            Text("Customize the look and feel of your app")
                .font(.spotifyCaptionMedium)
                .foregroundColor(.wiseSecondaryText)
        }
        .onAppear {
            // Load current settings
            selectedThemeMode = ThemeMode(rawValue: userSettings.themeMode) ?? .system
            selectedAccentColor = AccentColor(rawValue: userSettings.accentColor) ?? .forestGreen
            selectedAppIcon = AppIcon(rawValue: userSettings.appIcon) ?? .default
            selectedTabBarStyle = TabBarStyle(rawValue: userSettings.tabBarStyle) ?? .labels
        }
        .sheet(isPresented: $showingIconPicker) {
            AppIconPickerView()
        }
    }
}

// Theme preview button
struct ThemePreviewButton: View {
    let mode: ThemeMode
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(themeBackgroundColor)
                        .frame(height: 60)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(isSelected ? Color.wiseForestGreen : Color.wiseMidGray.opacity(0.5), lineWidth: isSelected ? 2 : 1)
                        )

                    // Theme preview content
                    VStack(spacing: 4) {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(themeAccentColor)
                                .frame(width: 12, height: 12)
                            Rectangle()
                                .fill(themeTextColor)
                                .frame(height: 4)
                        }
                        .padding(.horizontal, 8)

                        Rectangle()
                            .fill(themeTextColor.opacity(0.5))
                            .frame(height: 3)
                            .padding(.horizontal, 8)

                        Rectangle()
                            .fill(themeTextColor.opacity(0.3))
                            .frame(height: 3)
                            .padding(.horizontal, 8)
                    }
                }

                Text(mode.displayName)
                    .font(.spotifyCaptionMedium)
                    .foregroundColor(isSelected ? .wiseForestGreen : .wisePrimaryText)
            }
        }
        .frame(maxWidth: .infinity)
    }

    var themeBackgroundColor: Color {
        switch mode {
        case .light: return .white
        case .dark: return Color(white: 0.15)
        case .system: return Color(white: 0.5)
        }
    }

    var themeTextColor: Color {
        switch mode {
        case .light: return .black
        case .dark: return .white
        case .system: return .white
        }
    }

    var themeAccentColor: Color {
        .wiseForestGreen
    }
}

// Color picker button
struct ColorPickerButton: View {
    let color: AccentColor
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Circle()
                    .fill(color.color)
                    .frame(width: 44, height: 44)
                    .overlay(
                        Circle()
                            .stroke(isSelected ? Color.white : Color.clear, lineWidth: 3)
                    )
                    .overlay(
                        Circle()
                            .stroke(isSelected ? color.color : Color.wiseMidGray.opacity(0.5), lineWidth: isSelected ? 3 : 1)
                    )

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(color.color)
                }
            }
        }
    }
}

// App icon picker sheet

// App icon cell
struct AppIconCell: View {
    let icon: AppIcon
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.wiseForestGreen.opacity(0.1))
                        .frame(width: 80, height: 80)

                    Image(systemName: "app.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.wiseForestGreen)

                    if isSelected {
                        Circle()
                            .fill(Color.wiseForestGreen)
                            .frame(width: 24, height: 24)
                            .overlay(
                                Image(systemName: "checkmark")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.white)
                            )
                            .offset(x: 30, y: -30)
                    }

                    if icon.isPremium {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 16))
                            .foregroundColor(Color(red: 1.0, green: 0.8, blue: 0.0)) // Gold crown color
                            .offset(x: -30, y: -30)
                    }
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(isSelected ? Color.wiseForestGreen : Color.clear, lineWidth: 2)
                        .frame(width: 80, height: 80)
                )

                Text(icon.displayName)
                    .font(.spotifyCaptionMedium)
                    .foregroundColor(isSelected ? .wiseForestGreen : .wisePrimaryText)
            }
        }
    }
}

// Tab bar style enum
enum TabBarStyle: String, CaseIterable {
    case labels = "labels"
    case iconsOnly = "iconsOnly"
    case selectedOnly = "selectedOnly"

    var displayName: String {
        switch self {
        case .labels: return "Labels"
        case .iconsOnly: return "Icons Only"
        case .selectedOnly: return "Selected Only"
        }
    }

    var icon: String {
        switch self {
        case .labels: return "text.below.photo"
        case .iconsOnly: return "photo"
        case .selectedOnly: return "text.below.photo.fill"
        }
    }

    var description: String {
        switch self {
        case .labels: return "Always show text labels"
        case .iconsOnly: return "Show only icons"
        case .selectedOnly: return "Show label for selected tab"
        }
    }
}

// Tab bar style button
struct TabBarStyleButton: View {
    let style: TabBarStyle
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isSelected ? Color.wiseForestGreen.opacity(0.1) : Color.wiseBorder.opacity(0.3))
                        .frame(height: 50)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(isSelected ? Color.wiseForestGreen : Color.wiseMidGray.opacity(0.3), lineWidth: isSelected ? 2 : 1)
                        )

                    // Tab bar preview
                    HStack(spacing: 8) {
                        ForEach(0..<3, id: \.self) { index in
                            VStack(spacing: 2) {
                                Circle()
                                    .fill(index == 1 ? Color.wiseForestGreen : Color.wiseMidGray)
                                    .frame(width: 12, height: 12)

                                // Show text based on style
                                if style == .labels || (style == .selectedOnly && index == 1) {
                                    Rectangle()
                                        .fill(index == 1 ? Color.wiseForestGreen : Color.wiseMidGray)
                                        .frame(width: 16, height: 3)
                                        .cornerRadius(1)
                                }
                            }
                        }
                    }
                }

                Text(style.displayName)
                    .font(.spotifyCaptionMedium)
                    .foregroundColor(isSelected ? .wiseForestGreen : .wisePrimaryText)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    NavigationView {
        List {
            AppearanceSettingsSection()
        }
    }
}
