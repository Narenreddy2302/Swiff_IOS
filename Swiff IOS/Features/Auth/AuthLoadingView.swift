//
//  AuthLoadingView.swift
//  Swiff IOS
//
//  Loading screen shown during initial authentication check
//

import SwiftUI

struct AuthLoadingView: View {
    @State private var isAnimating = false

    var body: some View {
        ZStack {
            AuthBackground()

            VStack(spacing: 32) {
                // App Logo/Icon
                SwiffLogo(size: 100)
                    .scaleEffect(isAnimating ? 1.05 : 1.0)
                    .animation(
                        .easeInOut(duration: 1.5).repeatForever(autoreverses: true),
                        value: isAnimating
                    )

                VStack(spacing: 12) {
                    Text("Swiff")
                        .font(Theme.Fonts.displayLarge)
                        .foregroundColor(Theme.Colors.textPrimary)

                    Text("Loading...")
                        .font(Theme.Fonts.bodyMedium)
                        .foregroundColor(Theme.Colors.textSecondary)
                }

                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: Theme.Colors.brandPrimary))
                    .scaleEffect(1.2)
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
}

#Preview {
    AuthLoadingView()
}
