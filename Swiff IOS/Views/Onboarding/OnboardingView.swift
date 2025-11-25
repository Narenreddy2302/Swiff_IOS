//
//  OnboardingView.swift
//  Swiff IOS
//
//  Created by Agent 11 on 11/21/25.
//  Main onboarding coordinator view
//

import SwiftUI

struct OnboardingView: View {
    @State private var onboardingStage: OnboardingStage = .welcome
    @State private var featurePage: Int = 0
    @State private var setupStep: Int = 0

    let onComplete: () -> Void

    enum OnboardingStage {
        case welcome
        case features
        case setup
    }

    var body: some View {
        ZStack {
            switch onboardingStage {
            case .welcome:
                WelcomeScreen(onGetStarted: {
                    withAnimation(.smooth) {
                        onboardingStage = .features
                    }
                })
                .transition(.asymmetric(
                    insertion: .opacity,
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))

            case .features:
                FeatureShowcaseScreen(
                    currentPage: $featurePage,
                    onNext: {
                        withAnimation(.smooth) {
                            onboardingStage = .setup
                        }
                    },
                    onSkip: {
                        completeOnboarding()
                    }
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))

            case .setup:
                SetupWizardView(
                    currentStep: $setupStep,
                    onComplete: {
                        completeOnboarding()
                    },
                    onSkip: {
                        completeOnboarding()
                    }
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .opacity
                ))
            }
        }
        .animation(
            UIAccessibility.isReduceMotionEnabled ? .none : .smooth,
            value: onboardingStage
        )
    }

    private func completeOnboarding() {
        // Save completion status
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        HapticManager.shared.success()

        // Announce completion for VoiceOver
        AccessibilityAnnouncer.shared.announce("Onboarding complete. Welcome to Swiff!")

        onComplete()
    }
}

#Preview {
    OnboardingView(onComplete: {})
}
