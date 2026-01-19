//
//  ShareSubscriptionSheet.swift
//  Swiff IOS
//
//  Sheet for sharing an existing subscription with people
//

import SwiftUI

struct ShareSubscriptionSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataManager: DataManager

    let subscription: Subscription
    @Binding var showingSheet: Bool

    // State
    @State private var selectedPeople: Set<UUID> = []
    @State private var selectedSplitType: CostSplitType = .equal
    @State private var isSubmitting = false
    @State private var showingSuccess = false

    var individualCost: Double {
        let totalPeople = selectedPeople.count + 1
        return subscription.monthlyEquivalent / Double(totalPeople)
    }

    var isFormValid: Bool {
        !selectedPeople.isEmpty
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if showingSuccess {
                    successView
                } else {
                    formContent
                }
            }
            .background(Theme.Colors.background)
            .navigationTitle("Share Subscription")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        showingSheet = false
                    }
                    .foregroundColor(Theme.Colors.textPrimary)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Share") {
                        shareSubscription()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(isFormValid ? Theme.Colors.brandPrimary : Theme.Colors.textSecondary)
                    .disabled(!isFormValid || isSubmitting)
                }
            }
        }
    }

    private var formContent: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Subscription Preview
                subscriptionPreview

                // People Selection
                peopleSelectionSection

                // Split Type Selection
                splitTypeSection

                // Cost Preview
                costPreviewSection
            }
            .padding(20)
        }
    }

    private var subscriptionPreview: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(Color(hexString: subscription.color).opacity(0.15))
                .frame(width: 56, height: 56)
                .overlay(
                    Image(systemName: subscription.icon)
                        .font(.system(size: 24))
                        .foregroundColor(Color(hexString: subscription.color))
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(subscription.name)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Theme.Colors.textPrimary)

                Text("\(subscription.price.asCurrency)/\(subscription.billingCycle.displayShort)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Theme.Colors.textSecondary)
            }

            Spacer()
        }
        .padding(16)
        .background(Theme.Colors.cardBackground)
        .cornerRadius(16)
    }

    private var peopleSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Share With")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Theme.Colors.textPrimary)

            if dataManager.people.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "person.badge.plus")
                        .font(.system(size: 32))
                        .foregroundColor(Theme.Colors.textSecondary)

                    Text("No contacts available")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Theme.Colors.textSecondary)

                    Text("Add people first to share subscriptions")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.Colors.textSecondary.opacity(0.7))
                }
                .padding(24)
                .frame(maxWidth: .infinity)
                .background(Theme.Colors.secondaryBackground)
                .cornerRadius(12)
            } else {
                VStack(spacing: 0) {
                    ForEach(dataManager.people) { person in
                        PersonSelectionRow(
                            person: person,
                            isSelected: selectedPeople.contains(person.id),
                            onToggle: {
                                HapticManager.shared.selection()
                                if selectedPeople.contains(person.id) {
                                    selectedPeople.remove(person.id)
                                } else {
                                    selectedPeople.insert(person.id)
                                }
                            }
                        )

                        if person.id != dataManager.people.last?.id {
                            Divider()
                                .padding(.leading, 56)
                        }
                    }
                }
                .background(Theme.Colors.cardBackground)
                .cornerRadius(12)
            }
        }
    }

    private var splitTypeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Split Type")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Theme.Colors.textPrimary)

            HStack(spacing: 8) {
                ForEach([CostSplitType.equal, .percentage, .fixed], id: \.self) { type in
                    Button(action: {
                        HapticManager.shared.selection()
                        selectedSplitType = type
                    }) {
                        Text(type.rawValue.capitalized)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(selectedSplitType == type ? .white : Theme.Colors.textPrimary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(selectedSplitType == type ? Theme.Colors.brandPrimary : Theme.Colors.secondaryBackground)
                            )
                    }
                }
            }
        }
    }

    private var costPreviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Cost Preview")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Theme.Colors.textPrimary)

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Your share")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Theme.Colors.textSecondary)

                    if selectedPeople.isEmpty {
                        Text("Select people")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(Theme.Colors.textSecondary)
                    } else {
                        Text("\(individualCost.asCurrency)/mo")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(Theme.Colors.brandPrimary)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Splitting with")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Theme.Colors.textSecondary)

                    Text("\(selectedPeople.count + 1) people")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Theme.Colors.textPrimary)
                }
            }
            .padding(16)
            .background(Theme.Colors.cardBackground)
            .cornerRadius(12)

            // Savings indicator
            if !selectedPeople.isEmpty {
                let savings = subscription.monthlyEquivalent - individualCost
                HStack {
                    Image(systemName: "arrow.down.circle.fill")
                        .foregroundColor(Theme.Colors.brandPrimary)

                    Text("You save \(savings.asCurrency)/month by sharing")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Theme.Colors.brandPrimary)
                }
                .padding(.top, 4)
            }
        }
    }

    private var successView: some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Theme.Colors.brandPrimary)
                    .frame(width: 80, height: 80)

                Image(systemName: "checkmark")
                    .font(.system(size: 36, weight: .semibold))
                    .foregroundColor(.white)
            }

            VStack(spacing: 8) {
                Text("Subscription Shared!")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(Theme.Colors.textPrimary)

                Text("Splitting \(subscription.monthlyEquivalent.asCurrency)/mo with \(selectedPeople.count) \(selectedPeople.count == 1 ? "person" : "people")")
                    .font(.system(size: 16))
                    .foregroundColor(Theme.Colors.textSecondary)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private func shareSubscription() {
        isSubmitting = true
        HapticManager.shared.impact(.medium)

        do {
            try dataManager.shareSubscription(
                subscription,
                with: Array(selectedPeople),
                splitType: selectedSplitType
            )

            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                showingSuccess = true
            }

            HapticManager.shared.success()

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                showingSheet = false
            }
        } catch {
            isSubmitting = false
            dataManager.error = error
        }
    }
}

// MARK: - Person Selection Row
struct PersonSelectionRow: View {
    let person: Person
    let isSelected: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 12) {
                // Checkbox
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundColor(isSelected ? Theme.Colors.brandPrimary : Theme.Colors.textSecondary)

                // Avatar
                ZStack {
                    Circle()
                        .fill(InitialsAvatarColors.color(for: person.name))
                        .frame(width: 40, height: 40)

                    Text(InitialsGenerator.generate(from: person.name))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.black)
                }

                // Name and email
                VStack(alignment: .leading, spacing: 2) {
                    Text(person.name)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(Theme.Colors.textPrimary)

                    Text(person.email)
                        .font(.system(size: 12))
                        .foregroundColor(Theme.Colors.textSecondary)
                }

                Spacer()
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview
#Preview {
    ShareSubscriptionSheet(
        subscription: Subscription(
            name: "Netflix",
            description: "Streaming service",
            price: 15.99,
            billingCycle: .monthly,
            category: .entertainment,
            icon: "play.tv.fill",
            color: "#E50914"
        ),
        showingSheet: .constant(true)
    )
    .environmentObject(DataManager.shared)
}
