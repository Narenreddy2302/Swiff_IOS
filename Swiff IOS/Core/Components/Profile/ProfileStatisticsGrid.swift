//
//  ProfileStatisticsGrid.swift
//  Swiff IOS
//
//  2x2 grid of statistics cards showing key profile metrics
//

import SwiftUI

/// Statistics type for tap handling
enum StatType {
    case subscriptions
    case spending
    case people
    case groups
}

/// Profile statistics grid component
struct ProfileStatisticsGrid: View {
    let subscriptionsCount: Int
    let monthlySpending: Double
    let peopleCount: Int
    let groupsCount: Int
    let onTap: (StatType) -> Void

    @State private var tappedCard: StatType?
    @State private var cardsAppeared = false
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            // Subscriptions Card
            CompactStatisticsCard(
                icon: "chart.line.uptrend.xyaxis",
                title: "Subscriptions",
                value: formatNumber(subscriptionsCount),
                iconBackgroundColor: .wiseBrightGreen
            )
            .opacity(cardsAppeared ? 1 : 0)
            .offset(y: cardsAppeared ? 0 : 20)
            .animation(reduceMotion ? .none : .easeOut(duration: 0.4).delay(0.0), value: cardsAppeared)
            .animation(reduceMotion ? .none : .easeInOut(duration: 0.3), value: subscriptionsCount)
            .scaleEffect(tappedCard == .subscriptions ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: tappedCard)
            .onTapGesture {
                handleTap(.subscriptions)
            }
            .accessibilityLabel("\(subscriptionsCount) subscriptions")
            .accessibilityHint("Double tap to view all subscriptions")
            .accessibilityAddTraits([.isButton, .updatesFrequently])

            // Spending Card
            CompactStatisticsCard(
                icon: "dollarsign.circle.fill",
                title: "Monthly Spending",
                value: formatCurrency(monthlySpending),
                iconBackgroundColor: .wiseOrange
            )
            .opacity(cardsAppeared ? 1 : 0)
            .offset(y: cardsAppeared ? 0 : 20)
            .animation(reduceMotion ? .none : .easeOut(duration: 0.4).delay(0.1), value: cardsAppeared)
            .animation(reduceMotion ? .none : .easeInOut(duration: 0.3), value: monthlySpending)
            .scaleEffect(tappedCard == .spending ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: tappedCard)
            .onTapGesture {
                handleTap(.spending)
            }
            .accessibilityLabel("Monthly spending \(formatCurrency(monthlySpending))")
            .accessibilityHint("Double tap to view analytics")
            .accessibilityAddTraits([.isButton, .updatesFrequently])

            // People Card
            CompactStatisticsCard(
                icon: "person.2.fill",
                title: "People",
                value: formatNumber(peopleCount),
                iconBackgroundColor: .wiseBlue
            )
            .opacity(cardsAppeared ? 1 : 0)
            .offset(y: cardsAppeared ? 0 : 20)
            .animation(reduceMotion ? .none : .easeOut(duration: 0.4).delay(0.2), value: cardsAppeared)
            .animation(reduceMotion ? .none : .easeInOut(duration: 0.3), value: peopleCount)
            .scaleEffect(tappedCard == .people ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: tappedCard)
            .onTapGesture {
                handleTap(.people)
            }
            .accessibilityLabel("\(peopleCount) people")
            .accessibilityHint("Double tap to view people")
            .accessibilityAddTraits([.isButton, .updatesFrequently])

            // Groups Card
            CompactStatisticsCard(
                icon: "person.3.fill",
                title: "Groups",
                value: formatNumber(groupsCount),
                iconBackgroundColor: .wisePurple
            )
            .opacity(cardsAppeared ? 1 : 0)
            .offset(y: cardsAppeared ? 0 : 20)
            .animation(reduceMotion ? .none : .easeOut(duration: 0.4).delay(0.3), value: cardsAppeared)
            .animation(reduceMotion ? .none : .easeInOut(duration: 0.3), value: groupsCount)
            .scaleEffect(tappedCard == .groups ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: tappedCard)
            .onTapGesture {
                handleTap(.groups)
            }
            .accessibilityLabel("\(groupsCount) groups")
            .accessibilityHint("Double tap to view groups")
            .accessibilityAddTraits([.isButton, .updatesFrequently])
        }
        .onAppear {
            cardsAppeared = true
        }
    }

    // MARK: - Helper Methods

    /// Handles card tap with haptic feedback and animation
    private func handleTap(_ statType: StatType) {
        HapticManager.shared.impact(.light)
        tappedCard = statType

        // Reset animation state after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            tappedCard = nil
        }

        // Trigger callback
        onTap(statType)
    }

    /// Formats currency with user's selected currency
    private func formatCurrency(_ amount: Double) -> String {
        amount.asCurrency
    }

    /// Formats numbers with thousands separator
    private func formatNumber(_ number: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }
}

// MARK: - Preview

#Preview("Profile Statistics Grid") {
    VStack(spacing: 20) {
        // Standard values
        ProfileStatisticsGrid(
            subscriptionsCount: 12,
            monthlySpending: 249.99,
            peopleCount: 8,
            groupsCount: 3
        ) { statType in
            print("Tapped: \(statType)")
        }

        // Large numbers
        ProfileStatisticsGrid(
            subscriptionsCount: 1234,
            monthlySpending: 12500.00,
            peopleCount: 567,
            groupsCount: 89
        ) { statType in
            print("Tapped: \(statType)")
        }

        // Zero values
        ProfileStatisticsGrid(
            subscriptionsCount: 0,
            monthlySpending: 0.00,
            peopleCount: 0,
            groupsCount: 0
        ) { statType in
            print("Tapped: \(statType)")
        }
    }
    .padding()
    .background(Color.wiseBackground)
}

#Preview("Light Mode") {
    ProfileStatisticsGrid(
        subscriptionsCount: 15,
        monthlySpending: 349.99,
        peopleCount: 12,
        groupsCount: 5
    ) { statType in
        print("Tapped: \(statType)")
    }
    .padding()
    .background(Color.wiseBackground)
    .preferredColorScheme(.light)
}

#Preview("Dark Mode") {
    ProfileStatisticsGrid(
        subscriptionsCount: 15,
        monthlySpending: 349.99,
        peopleCount: 12,
        groupsCount: 5
    ) { statType in
        print("Tapped: \(statType)")
    }
    .padding()
    .background(Color.wiseBackground)
    .preferredColorScheme(.dark)
}
