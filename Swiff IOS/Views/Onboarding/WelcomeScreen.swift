//
//  WelcomeScreen.swift
//  Swiff IOS
//
//  Created by Agent 11 on 11/21/25.
//  Welcome screen for onboarding flow
//

import SwiftUI
import Combine

struct WelcomeScreen: View {
    let onGetStarted: () -> Void

    @Environment(\.colorScheme) var colorScheme
    @State private var logoScale: CGFloat = 0.8
    @State private var textOpacity: Double = 0

    var body: some View {
        VStack(spacing: 40) {
            Spacer()

            // App Logo
            VStack(spacing: 24) {
                Image(systemName: "creditcard.circle.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 120, height: 120)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.wiseForestGreen, Color.wiseBrightGreen],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .scaleEffect(logoScale)
                    .shadow(color: Color.wiseForestGreen.opacity(0.3), radius: 20, x: 0, y: 10)

                Text("Swiff")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(.wisePrimaryText)
            }
            .opacity(textOpacity)

            // Tagline
            VStack(spacing: 12) {
                Text("Track subscriptions,")
                    .font(.title2)
                    .fontWeight(.medium)

                Text("manage expenses,")
                    .font(.title2)
                    .fontWeight(.medium)

                Text("save money")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.wiseForestGreen)
            }
            .multilineTextAlignment(.center)
            .opacity(textOpacity)

            Spacer()

            // Get Started Button
            Button(action: {
                HapticManager.shared.medium()
                onGetStarted()
            }) {
                Text("Get Started")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [Color.wiseForestGreen, Color.wiseBrightGreen],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(16)
            }
            .buttonStyle(ScaleButtonStyle())
            .opacity(textOpacity)
            .accessibilityLabel("Get started with Swiff")
            .accessibilityHint("Double tap to begin setup")
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 60)
        .background(Color.wiseBackground)
        .onAppear {
            withAnimation(.bouncy.delay(0.1)) {
                logoScale = 1.0
            }
            withAnimation(.easeOut(duration: 0.8).delay(0.3)) {
                textOpacity = 1.0
            }
        }
    }
}

#Preview {
    WelcomeScreen(onGetStarted: {})
}
