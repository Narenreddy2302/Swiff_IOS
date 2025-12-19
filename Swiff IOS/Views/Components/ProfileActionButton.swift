//
//  ProfileActionButton.swift
//  Swiff IOS
//
//  Circular action button for profile quick actions
//  Modern design with icon, label, and haptic feedback
//

import SwiftUI

struct ProfileActionButton: View {
    let icon: String
    let title: String
    let backgroundColor: Color
    let iconColor: Color
    let action: () -> Void

    @State private var isPressed = false
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    var body: some View {
        Button(action: {
            HapticManager.shared.impact(.medium)
            action()
        }) {
            VStack(spacing: 8) {
                // Icon Circle
                ZStack {
                    Circle()
                        .fill(backgroundColor.opacity(0.15))
                        .frame(width: 56, height: 56)

                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(iconColor)
                }
                .shadow(color: backgroundColor.opacity(0.3), radius: 8, x: 0, y: 4)

                // Label
                Text(title)
                    .font(.spotifyLabelSmall)
                    .foregroundColor(.wiseSecondaryText)
            }
        }
        .buttonStyle(ScaleButtonStyle(scaleAmount: 0.95))
        .accessibilityLabel("\(title) button")
        .accessibilityHint("Double tap to \(title.lowercased())")
    }
}

// MARK: - Preview

#Preview("Profile Action Buttons") {
    VStack(spacing: 32) {
        HStack(spacing: 20) {
            ProfileActionButton(
                icon: "pencil",
                title: "Edit",
                backgroundColor: .wiseBlue,
                iconColor: .wiseBlue
            ) {
                print("Edit tapped")
            }

            ProfileActionButton(
                icon: "square.and.arrow.up",
                title: "Export",
                backgroundColor: .wiseBrightGreen,
                iconColor: .wiseBrightGreen
            ) {
                print("Export tapped")
            }

            ProfileActionButton(
                icon: "gearshape.fill",
                title: "Settings",
                backgroundColor: .wiseOrange,
                iconColor: .wiseOrange
            ) {
                print("Settings tapped")
            }
        }

        // Dark background preview
        HStack(spacing: 20) {
            ProfileActionButton(
                icon: "pencil",
                title: "Edit",
                backgroundColor: .wiseBlue,
                iconColor: .wiseBlue
            ) {
                print("Edit tapped")
            }

            ProfileActionButton(
                icon: "square.and.arrow.up",
                title: "Export",
                backgroundColor: .wiseBrightGreen,
                iconColor: .wiseBrightGreen
            ) {
                print("Export tapped")
            }

            ProfileActionButton(
                icon: "gearshape.fill",
                title: "Settings",
                backgroundColor: .wiseOrange,
                iconColor: .wiseOrange
            ) {
                print("Settings tapped")
            }
        }
        .padding()
        .background(Color.wiseBackground)
    }
    .padding()
}

#Preview("Profile Action Buttons - Dark Mode") {
    VStack(spacing: 32) {
        HStack(spacing: 20) {
            ProfileActionButton(
                icon: "pencil",
                title: "Edit",
                backgroundColor: .wiseBlue,
                iconColor: .wiseBlue
            ) {
                print("Edit tapped")
            }

            ProfileActionButton(
                icon: "square.and.arrow.up",
                title: "Export",
                backgroundColor: .wiseBrightGreen,
                iconColor: .wiseBrightGreen
            ) {
                print("Export tapped")
            }

            ProfileActionButton(
                icon: "gearshape.fill",
                title: "Settings",
                backgroundColor: .wiseOrange,
                iconColor: .wiseOrange
            ) {
                print("Settings tapped")
            }
        }
    }
    .padding()
    .background(Color.wiseBackground)
    .preferredColorScheme(.dark)
}
