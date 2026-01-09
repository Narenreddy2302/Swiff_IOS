//
//  SharedSubscriptionCostCard.swift
//  Swiff IOS
//
//  Card showing subscription cost breakdown for shared subscriptions
//  Displays total cost vs your share and lists all shared members with their amounts
//

import SwiftUI

// MARK: - Shared Subscription Cost Card

struct SharedSubscriptionCostCard: View {
    let subscription: Subscription
    let sharedPeople: [Person]

    private var costPerPerson: Double {
        subscription.monthlyEquivalent / Double(sharedPeople.count + 1)
    }

    private var totalCost: Double {
        subscription.monthlyEquivalent
    }

    var body: some View {
        VStack(spacing: 16) {
            // Header - Total vs Your Share
            costComparisonHeader

            Divider()

            // Shared members list
            VStack(spacing: 0) {
                // You (owner) row
                selfRow

                // Other shared people
                if !sharedPeople.isEmpty {
                    AlignedDivider()

                    ForEach(Array(sharedPeople.enumerated()), id: \.element.id) { index, person in
                        sharedPersonRow(person: person)

                        if index < sharedPeople.count - 1 {
                            AlignedDivider()
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(Color.wiseCardBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.wiseBorder, lineWidth: 1)
        )
    }

    // MARK: - Cost Comparison Header

    private var costComparisonHeader: some View {
        HStack(spacing: 20) {
            // Total cost
            VStack(alignment: .leading, spacing: 4) {
                Text("Total Cost")
                    .font(Theme.Fonts.labelSmall)
                    .foregroundColor(.wiseSecondaryText)

                Text(String(format: "$%.2f", totalCost))
                    .font(Theme.Fonts.numberLarge)
                    .foregroundColor(.wisePrimaryText)

                Text("per month")
                    .font(Theme.Fonts.captionSmall)
                    .foregroundColor(.wiseSecondaryText)
            }

            Spacer()

            // Arrow separator
            Image(systemName: "arrow.right")
                .font(Theme.Fonts.bodyMedium)
                .foregroundColor(.wiseSecondaryText)

            Spacer()

            // Your share
            VStack(alignment: .trailing, spacing: 4) {
                Text("Your Share")
                    .font(Theme.Fonts.labelSmall)
                    .foregroundColor(.wiseSecondaryText)

                Text(String(format: "$%.2f", costPerPerson))
                    .font(Theme.Fonts.numberLarge)
                    .foregroundColor(.wiseForestGreen)

                Text("per month")
                    .font(Theme.Fonts.captionSmall)
                    .foregroundColor(.wiseSecondaryText)
            }
        }
    }

    // MARK: - Self Row (Owner)

    private var selfRow: some View {
        HStack(spacing: 14) {
            // "You" avatar
            ZStack {
                Circle()
                    .fill(Color.wiseForestGreen.opacity(0.2))
                    .frame(width: Theme.Metrics.minTapTarget, height: Theme.Metrics.minTapTarget)

                Image(systemName: "person.fill")
                    .font(Theme.Fonts.navigationIcon)
                    .foregroundColor(.wiseForestGreen)
            }

            // Name
            VStack(alignment: .leading, spacing: 3) {
                Text("You")
                    .font(Theme.Fonts.headerSmall)
                    .foregroundColor(.wisePrimaryText)

                Text("Owner")
                    .font(Theme.Fonts.bodyMedium)
                    .foregroundColor(.wiseSecondaryText)
            }

            Spacer()

            // Share amount
            Text(String(format: "$%.2f", costPerPerson))
                .font(Theme.Fonts.headerSmall)
                .foregroundColor(AmountColors.positive)
        }
        .padding(.vertical, 12)
    }

    // MARK: - Shared Person Row

    @ViewBuilder
    private func sharedPersonRow(person: Person) -> some View {
        HStack(spacing: 14) {
            // Avatar
            AvatarView(person: person, size: .medium, style: .solid)
                .frame(width: Theme.Metrics.minTapTarget, height: Theme.Metrics.minTapTarget)

            // Name and email
            VStack(alignment: .leading, spacing: 3) {
                Text(person.name)
                    .font(Theme.Fonts.headerSmall)
                    .foregroundColor(.wisePrimaryText)
                    .lineLimit(1)

                if !person.email.isEmpty {
                    Text(person.email)
                        .font(Theme.Fonts.bodyMedium)
                        .foregroundColor(.wiseSecondaryText)
                        .lineLimit(1)
                }
            }

            Spacer()

            // Share amount
            Text(String(format: "$%.2f", costPerPerson))
                .font(Theme.Fonts.headerSmall)
                .foregroundColor(AmountColors.positive)
        }
        .padding(.vertical, 12)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(person.name), share: \(String(format: "$%.2f", costPerPerson))")
    }
}

// MARK: - Preview

#Preview("Shared Subscription Cost Card") {
    ScrollView {
        VStack(spacing: 16) {
            // With 2 people (3 total including you)
            SharedSubscriptionCostCard(
                subscription: {
                    var sub = Subscription(
                        name: "Netflix",
                        description: "Streaming service",
                        price: 19.99,
                        billingCycle: .monthly,
                        category: .entertainment,
                        icon: "tv.fill",
                        color: "#E50914"
                    )
                    sub.isShared = true
                    sub.sharedWith = [UUID(), UUID()]
                    return sub
                }(),
                sharedPeople: [
                    Person(name: "Alex Thompson", email: "alex@example.com", phone: "", avatarType: .initials("AT", colorIndex: 0)),
                    Person(name: "Maria Santos", email: "maria@example.com", phone: "", avatarType: .initials("MS", colorIndex: 1))
                ]
            )

            // With 4 people (5 total including you)
            SharedSubscriptionCostCard(
                subscription: {
                    var sub = Subscription(
                        name: "Spotify Family",
                        description: "Music streaming",
                        price: 16.99,
                        billingCycle: .monthly,
                        category: .music,
                        icon: "music.note",
                        color: "#1DB954"
                    )
                    sub.isShared = true
                    sub.sharedWith = [UUID(), UUID(), UUID(), UUID()]
                    return sub
                }(),
                sharedPeople: [
                    Person(name: "Alex Thompson", email: "alex@example.com", phone: "", avatarType: .initials("AT", colorIndex: 0)),
                    Person(name: "Maria Santos", email: "maria@example.com", phone: "", avatarType: .initials("MS", colorIndex: 1)),
                    Person(name: "John Davis", email: "john@example.com", phone: "", avatarType: .initials("JD", colorIndex: 2)),
                    Person(name: "Sarah Lee", email: "sarah@example.com", phone: "", avatarType: .emoji("🎨"))
                ]
            )

            // With annual subscription (converted to monthly)
            SharedSubscriptionCostCard(
                subscription: {
                    var sub = Subscription(
                        name: "Adobe Creative Cloud",
                        description: "Design tools",
                        price: 659.88,
                        billingCycle: .yearly,
                        category: .design,
                        icon: "paintbrush.fill",
                        color: "#FF0000"
                    )
                    sub.isShared = true
                    sub.sharedWith = [UUID()]
                    return sub
                }(),
                sharedPeople: [
                    Person(name: "Design Partner", email: "partner@studio.com", phone: "", avatarType: .initials("DP", colorIndex: 4))
                ]
            )
        }
        .padding(16)
    }
    .background(Color.wiseBackground)
}
