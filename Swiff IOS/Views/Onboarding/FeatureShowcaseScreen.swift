//
//  FeatureShowcaseScreen.swift
//  Swiff IOS
//
//  Created by Agent 11 on 11/21/25.
//  Feature showcase carousel for onboarding
//

import SwiftUI
import Combine

struct FeatureShowcaseScreen: View {
    @Binding var currentPage: Int
    let onNext: () -> Void
    let onSkip: () -> Void

    @Environment(\.colorScheme) var colorScheme

    private let features = [
        FeatureData(
            icon: "list.bullet.rectangle.portrait",
            title: "Track All Subscriptions",
            description: "Keep track of all your recurring payments in one place. Never lose track of what you're paying for.",
            color: Color.wiseForestGreen
        ),
        FeatureData(
            icon: "bell.badge",
            title: "Never Miss a Payment",
            description: "Get timely reminders before your subscriptions renew. Stay on top of your bills effortlessly.",
            color: Color.wiseBrightGreen
        ),
        FeatureData(
            icon: "chart.bar.fill",
            title: "Visualize Your Spending",
            description: "See where your money goes with beautiful charts and insights. Make smarter financial decisions.",
            color: Color.wiseBlue
        ),
        FeatureData(
            icon: "person.3.fill",
            title: "Split Expenses with Friends",
            description: "Share subscriptions and expenses with friends. Track who owes what and settle up easily.",
            color: Color.wisePurple
        )
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Skip Button
            HStack {
                Spacer()
                Button(action: {
                    HapticManager.shared.light()
                    onSkip()
                }) {
                    Text("Skip")
                        .font(.subheadline)
                        .foregroundColor(.wiseSecondaryText)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                }
                .accessibilityLabel("Skip onboarding")
                .accessibilityHint("Double tap to skip the tutorial")
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)

            // Feature Carousel
            TabView(selection: $currentPage) {
                ForEach(features.indices, id: \.self) { (index: Int) in
                    FeatureCard(feature: features[index])
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .onChange(of: currentPage) { _, _ in
                if !AccessibilitySettings.isReduceMotionEnabled {
                    HapticManager.shared.selection()
                }
            }

            // Page Indicators
            HStack(spacing: 8) {
                ForEach(features.indices, id: \.self) { index in
                    Circle()
                        .fill(currentPage == index ? Color.wiseForestGreen : Color.wiseMidGray.opacity(0.5))
                        .frame(width: 8, height: 8)
                        .scaleEffect(currentPage == index ? 1.2 : 1.0)
                        .animation(.smooth, value: currentPage)
                }
            }
            .padding(.vertical, 20)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Page \(currentPage + 1) of \(features.count)")

            // Next Button
            Button(action: {
                HapticManager.shared.medium()
                if currentPage < features.count - 1 {
                    withAnimation(.smooth) {
                        currentPage += 1
                    }
                } else {
                    onNext()
                }
            }) {
                Text(currentPage < features.count - 1 ? "Next" : "Continue")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.wiseForestGreen)
                    .cornerRadius(16)
            }
            .buttonStyle(ScaleButtonStyle())
            .padding(.horizontal, 32)
            .padding(.bottom, 40)
            .accessibilityLabel(currentPage < features.count - 1 ? "Next feature" : "Continue to setup")
        }
        .background(Color.wiseBackground)
    }
}

struct FeatureCard: View {
    let feature: FeatureData

    @State private var iconScale: CGFloat = 0.8
    @State private var contentOpacity: Double = 0

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Icon
            ZStack {
                Circle()
                    .fill(feature.color.opacity(0.15))
                    .frame(width: 140, height: 140)

                Image(systemName: feature.icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 70, height: 70)
                    .foregroundColor(feature.color)
            }
            .scaleEffect(iconScale)
            .shadow(color: feature.color.opacity(0.3), radius: 20, x: 0, y: 10)

            // Text Content
            VStack(spacing: 16) {
                Text(feature.title)
                    .font(.title)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.wisePrimaryText)

                Text(feature.description)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.wiseSecondaryText)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 20)
            }
            .opacity(contentOpacity)

            Spacer()
        }
        .padding(.horizontal, 40)
        .onAppear {
            withAnimation(.bouncy.delay(0.1)) {
                iconScale = 1.0
            }
            withAnimation(.easeOut(duration: 0.6).delay(0.3)) {
                contentOpacity = 1.0
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(feature.title). \(feature.description)")
    }
}

struct FeatureData {
    let icon: String
    let title: String
    let description: String
    let color: Color
}

#Preview {
    FeatureShowcaseScreen(
        currentPage: .constant(0),
        onNext: {},
        onSkip: {}
    )
}
