//
//  AppIconPickerView.swift
//  Swiff IOS
//
//  Created for Agent 16: Polish & Launch Preparation
//  App icon picker for alternate app icons
//

import SwiftUI
import Combine

struct AppIconPickerView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var iconManager = AppIconManager.shared
    @State private var showingChangeAlert = false
    @State private var selectedIconName: String?

    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "app.fill")
                            .font(.system(size: 50))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.wiseForestGreen, .wiseBlue],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )

                        Text("Choose App Icon")
                            .font(.spotifyHeadingLarge)
                            .foregroundColor(.wisePrimaryText)

                        Text("Personalize your home screen")
                            .font(.spotifyBodyMedium)
                            .foregroundColor(.wiseSecondaryText)
                    }
                    .padding(.top, 20)

                    // Icon Grid
                    LazyVGrid(columns: columns, spacing: 20) {
                        ForEach(AlternateAppIcon.allCases, id: \.self) { icon in
                            IconButton(
                                icon: icon,
                                isSelected: iconManager.currentIcon == icon,
                                action: {
                                    if icon != iconManager.currentIcon {
                                        selectedIconName = icon.iconName
                                        iconManager.changeIcon(to: icon) { success in
                                            if success {
                                                HapticManager.shared.notification(.success)
                                            } else {
                                                HapticManager.shared.notification(.error)
                                            }
                                        }
                                    }
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 20)

                    // Info Section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 12) {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(.wiseBlue)
                            Text("Icon changes may take a moment to appear")
                                .font(.spotifyCaptionMedium)
                                .foregroundColor(.wiseSecondaryText)
                        }

                        HStack(spacing: 12) {
                            Image(systemName: "sparkles")
                                .foregroundColor(.wiseForestGreen)
                            Text("More icons coming soon!")
                                .font(.spotifyCaptionMedium)
                                .foregroundColor(.wiseSecondaryText)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
            .background(Color.wiseBackground.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.spotifyBodyMedium)
                    .foregroundColor(.wiseForestGreen)
                }
            }
        }
    }
}

struct IconButton: View {
    let icon: AlternateAppIcon
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                ZStack {
                    // Selection Ring
                    if isSelected {
                        RoundedRectangle(cornerRadius: 24)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [.wiseForestGreen, .wiseBlue],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 3
                            )
                            .frame(width: 94, height: 94)
                    }

                    // Icon Image
                    if let image = icon.previewImage {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 80, height: 80)
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                            .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
                    } else {
                        // Placeholder if image not available
                        RoundedRectangle(cornerRadius: 18)
                            .fill(
                                LinearGradient(
                                    colors: [icon.primaryColor, icon.secondaryColor],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 80, height: 80)
                            .overlay(
                                Image(systemName: icon.systemIconName)
                                    .font(.system(size: 36, weight: .semibold))
                                    .foregroundColor(.white)
                            )
                            .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
                    }

                    // Checkmark Badge
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.wiseForestGreen)
                            .background(
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 20, height: 20)
                            )
                            .offset(x: 30, y: -30)
                    }
                }

                Text(icon.displayName)
                    .font(.spotifyCaptionMedium)
                    .foregroundColor(isSelected ? .wisePrimaryText : .wiseSecondaryText)
                    .lineLimit(1)
                    .frame(width: 80)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(response: 0.3), value: isSelected)
    }
}

// MARK: - Alternate App Icon Options

enum AlternateAppIcon: String, CaseIterable {
    case primary = "AppIcon"
    case dark = "AppIcon-Dark"
    case minimal = "AppIcon-Minimal"
    case classic = "AppIcon-Classic"
    case neon = "AppIcon-Neon"
    case gold = "AppIcon-Gold"

    var displayName: String {
        switch self {
        case .primary: return "Default"
        case .dark: return "Dark"
        case .minimal: return "Minimal"
        case .classic: return "Classic"
        case .neon: return "Neon"
        case .gold: return "Premium"
        }
    }

    var iconName: String? {
        switch self {
        case .primary: return nil // nil means default icon
        default: return rawValue
        }
    }

    var systemIconName: String {
        switch self {
        case .primary: return "dollarsign.circle.fill"
        case .dark: return "moon.fill"
        case .minimal: return "s.circle.fill"
        case .classic: return "banknote.fill"
        case .neon: return "sparkles"
        case .gold: return "crown.fill"
        }
    }

    var primaryColor: Color {
        switch self {
        case .primary: return .wiseForestGreen
        case .dark: return .black
        case .minimal: return .gray
        case .classic: return .green
        case .neon: return .purple
        case .gold: return .yellow
        }
    }

    var secondaryColor: Color {
        switch self {
        case .primary: return .wiseBlue
        case .dark: return Color(white: 0.2)
        case .minimal: return .white
        case .classic: return Color.green.opacity(0.7)
        case .neon: return .pink
        case .gold: return .orange
        }
    }

    var previewImage: UIImage? {
        // Try to load the icon image from the bundle
        // This would load the actual app icon if available
        // For now, returns nil and uses placeholder
        return nil
    }
}

// MARK: - App Icon Manager

class AppIconManager: ObservableObject {
    static let shared = AppIconManager()

    @Published var currentIcon: AlternateAppIcon

    private init() {
        // Get current icon name
        if let iconName = UIApplication.shared.alternateIconName {
            self.currentIcon = AlternateAppIcon(rawValue: iconName) ?? .primary
        } else {
            self.currentIcon = .primary
        }
    }

    func changeIcon(to icon: AlternateAppIcon, completion: ((Bool) -> Void)? = nil) {
        guard UIApplication.shared.supportsAlternateIcons else {
            completion?(false)
            return
        }

        UIApplication.shared.setAlternateIconName(icon.iconName) { error in
            DispatchQueue.main.async {
                if error == nil {
                    self.currentIcon = icon
                    completion?(true)
                } else {
                    print("Error changing app icon: \(error?.localizedDescription ?? "Unknown error")")
                    completion?(false)
                }
            }
        }
    }

    func resetToDefault(completion: ((Bool) -> Void)? = nil) {
        changeIcon(to: .primary, completion: completion)
    }
}

// MARK: - Preview

struct AppIconPickerView_Previews: PreviewProvider {
    static var previews: some View {
        AppIconPickerView()
    }
}
