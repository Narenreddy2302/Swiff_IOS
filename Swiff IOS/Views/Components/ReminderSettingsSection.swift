//
//  ReminderSettingsSection.swift
//  Swiff IOS
//
//  Created by Agent 7 on 11/21/25.
//  AGENT 7: Reminder settings component for EditSubscriptionSheet
//

import SwiftUI
import Combine

struct ReminderSettingsSection: View {
    @Binding var subscription: Subscription
    @StateObject private var notificationManager = NotificationManager.shared
    @State private var showingTestConfirmation = false
    @State private var selectedReminderDate: Date?

    // Days before options
    private let daysBeforeOptions = [1, 3, 7, 14, 30]

    // Default reminder time (9 AM)
    private var defaultReminderTime: Date {
        var components = Calendar.current.dateComponents([.hour, .minute], from: Date())
        components.hour = 9
        components.minute = 0
        return Calendar.current.date(from: components) ?? Date()
    }

    // Calculate when reminder will be sent
    private var reminderPreview: String {
        let calendar = Calendar.current
        let reminderDate = calendar.date(
            byAdding: .day,
            value: -subscription.reminderDaysBefore,
            to: subscription.nextBillingDate
        ) ?? subscription.nextBillingDate

        let time = subscription.reminderTime ?? defaultReminderTime
        let timeComponents = calendar.dateComponents([.hour, .minute], from: time)

        var components = calendar.dateComponents([.year, .month, .day], from: reminderDate)
        components.hour = timeComponents.hour
        components.minute = timeComponents.minute

        if let finalDate = calendar.date(from: components) {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d 'at' h:mm a"
            return formatter.string(from: finalDate)
        }

        return "Invalid date"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Section Header
            HStack {
                Image(systemName: "bell.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.wiseForestGreen)

                Text("Renewal Reminders")
                    .font(.spotifyHeadingMedium)
                    .foregroundColor(.wisePrimaryText)

                Spacer()
            }

            // Enable Reminder Toggle
            Toggle(isOn: $subscription.enableRenewalReminder) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Enable Reminders")
                        .font(.spotifyBodyMedium)
                        .foregroundColor(.wisePrimaryText)

                    Text("Get notified before renewal")
                        .font(.spotifyBodySmall)
                        .foregroundColor(.wiseSecondaryText)
                }
            }
            .tint(.wiseForestGreen)

            if subscription.enableRenewalReminder {
                // Days Before Picker
                VStack(alignment: .leading, spacing: 12) {
                    Text("Remind me")
                        .font(.spotifyBodyMedium)
                        .foregroundColor(.wisePrimaryText)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(daysBeforeOptions, id: \.self) { days in
                                DaysBeforeOption(
                                    days: days,
                                    isSelected: subscription.reminderDaysBefore == days
                                ) {
                                    subscription.reminderDaysBefore = days
                                    HapticManager.shared.impact(.light)
                                }
                            }
                        }
                    }
                }

                Divider()
                    .padding(.vertical, 8)

                // Reminder Time Picker
                VStack(alignment: .leading, spacing: 12) {
                    Text("Reminder time")
                        .font(.spotifyBodyMedium)
                        .foregroundColor(.wisePrimaryText)

                    DatePicker(
                        "",
                        selection: Binding(
                            get: { subscription.reminderTime ?? defaultReminderTime },
                            set: { subscription.reminderTime = $0 }
                        ),
                        displayedComponents: .hourAndMinute
                    )
                    .labelsHidden()
                    .tint(.wiseForestGreen)
                }

                Divider()
                    .padding(.vertical, 8)

                // Reminder Preview Card
                ReminderPreviewCard(
                    reminderDate: reminderPreview,
                    daysBefore: subscription.reminderDaysBefore,
                    subscriptionName: subscription.name,
                    price: subscription.price
                )

                // Test Reminder Button
                Button(action: sendTestReminder) {
                    HStack {
                        Image(systemName: "bell.badge.fill")
                            .font(.system(size: 16))

                        Text("Send Test Reminder")
                            .font(.spotifyBodyMedium)
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.wiseForestGreen)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.wiseForestGreen, lineWidth: 2)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 2)
        )
        .alert("Test Reminder Sent!", isPresented: $showingTestConfirmation) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Check your notifications to see how reminders will appear")
        }
    }

    // MARK: - Helper Methods

    private func sendTestReminder() {
        Task {
            await notificationManager.sendTestNotification()
            showingTestConfirmation = true
            HapticManager.shared.notification(.success)
        }
    }
}

// MARK: - Days Before Option

struct DaysBeforeOption: View {
    let days: Int
    let isSelected: Bool
    let action: () -> Void

    private var label: String {
        if days == 1 {
            return "1 day"
        } else {
            return "\(days) days"
        }
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Text("\(days)")
                    .font(.system(size: 24, weight: .bold))

                Text(days == 1 ? "day" : "days")
                    .font(.caption2)
            }
            .foregroundColor(isSelected ? .white : .wiseForestGreen)
            .frame(width: 70, height: 70)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.wiseForestGreen : Color.white)
                    .shadow(
                        color: isSelected ? Color.wiseForestGreen.opacity(0.3) : Color.black.opacity(0.05),
                        radius: isSelected ? 8 : 4,
                        x: 0,
                        y: 2
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.wiseForestGreen, lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Reminder Preview Card

struct ReminderPreviewCard: View {
    let reminderDate: String
    let daysBefore: Int
    let subscriptionName: String
    let price: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.wiseBlue)

                Text("You'll be reminded on:")
                    .font(.spotifyBodySmall)
                    .foregroundColor(.wiseSecondaryText)
            }

            Text(reminderDate)
                .font(.spotifyHeadingSmall)
                .fontWeight(.semibold)
                .foregroundColor(.wisePrimaryText)

            // Preview notification content
            VStack(alignment: .leading, spacing: 8) {
                Text("Preview:")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.wiseSecondaryText)
                    .textCase(.uppercase)

                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "bell.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.wiseBlue)
                        .padding(8)
                        .background(
                            Circle()
                                .fill(Color.wiseBlue.opacity(0.1))
                        )

                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(subscriptionName) Renews Soon")
                            .font(.spotifyBodySmall)
                            .fontWeight(.semibold)
                            .foregroundColor(.wisePrimaryText)

                        Text("\(price.asCurrency) will be charged in \(daysBefore) day\(daysBefore == 1 ? "" : "s")")
                            .font(.spotifyBodySmall)
                            .foregroundColor(.wiseSecondaryText)
                    }

                    Spacer()
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.wiseBackground.opacity(0.5))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.wiseBorder.opacity(0.5), lineWidth: 1)
                        )
                )
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.wiseBlue.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.wiseBlue.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

// MARK: - Preview

#Preview {
    struct PreviewWrapper: View {
        @State private var subscription = Subscription(
            name: "Netflix",
            description: "Streaming Service",
            price: 15.99,
            billingCycle: .monthly,
            category: .entertainment,
            icon: "play.tv.fill",
            color: "#E50914"
        )

        var body: some View {
            ScrollView {
                ReminderSettingsSection(subscription: $subscription)
                    .padding()
            }
            .background(Color.wiseBackground)
        }
    }

    return PreviewWrapper()
}
