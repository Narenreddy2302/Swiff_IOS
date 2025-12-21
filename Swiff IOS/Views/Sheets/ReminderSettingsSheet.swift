//
//  ReminderSettingsSheet.swift
//  Swiff IOS
//
//  Sheet for configuring subscription renewal reminders
//  Opened from Quick Actions "Remind" button
//

import SwiftUI

struct ReminderSettingsSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataManager: DataManager

    let subscription: Subscription
    let onSettingsSaved: () -> Void

    // Local state for editing
    @State private var enableReminders: Bool
    @State private var daysBefore: Int
    @State private var reminderTime: Date
    @State private var showingTestConfirmation = false
    @State private var isSaving = false

    // Days before options
    private let daysBeforeOptions = [1, 3, 7, 14, 30]

    init(subscription: Subscription, onSettingsSaved: @escaping () -> Void) {
        self.subscription = subscription
        self.onSettingsSaved = onSettingsSaved

        // Initialize state from subscription
        _enableReminders = State(initialValue: subscription.enableRenewalReminder)
        _daysBefore = State(initialValue: subscription.reminderDaysBefore)

        // Default reminder time to 9 AM if not set
        if let time = subscription.reminderTime {
            _reminderTime = State(initialValue: time)
        } else {
            var components = Calendar.current.dateComponents([.hour, .minute], from: Date())
            components.hour = 9
            components.minute = 0
            _reminderTime = State(initialValue: Calendar.current.date(from: components) ?? Date())
        }
    }

    // Calculate when reminder will be sent
    private var reminderPreviewDate: String {
        let calendar = Calendar.current
        let reminderDate = calendar.date(
            byAdding: .day,
            value: -daysBefore,
            to: subscription.nextBillingDate
        ) ?? subscription.nextBillingDate

        let timeComponents = calendar.dateComponents([.hour, .minute], from: reminderTime)

        var components = calendar.dateComponents([.year, .month, .day], from: reminderDate)
        components.hour = timeComponents.hour
        components.minute = timeComponents.minute

        if let finalDate = calendar.date(from: components) {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE, MMM d 'at' h:mm a"
            return formatter.string(from: finalDate)
        }

        return "Invalid date"
    }

    private var hasChanges: Bool {
        enableReminders != subscription.enableRenewalReminder ||
        daysBefore != subscription.reminderDaysBefore ||
        reminderTime != (subscription.reminderTime ?? Date())
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Subscription Info Header
                    subscriptionHeader

                    // Enable/Disable Toggle Card
                    enableToggleCard

                    if enableReminders {
                        // Days Before Selection
                        daysBeforeCard

                        // Time Selection
                        timeSelectionCard

                        // Preview Card
                        reminderPreviewCard

                        // Test Notification Button
                        testNotificationButton
                    }

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 16)
                .padding(.top, 20)
            }
            .background(Color.wiseBackground)
            .navigationTitle("Reminder Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .font(.spotifyBodyMedium)
                    .foregroundColor(.wiseSecondaryText)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveSettings()
                    }
                    .font(.spotifyBodyMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(hasChanges ? .wiseForestGreen : .wiseSecondaryText)
                    .disabled(!hasChanges || isSaving)
                }
            }
        }
        .alert("Test Reminder Sent!", isPresented: $showingTestConfirmation) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Check your notifications to see how reminders will appear.")
        }
    }

    // MARK: - View Components

    private var subscriptionHeader: some View {
        HStack(spacing: 12) {
            // Subscription icon
            Circle()
                .fill(Color(hexString: subscription.color).opacity(0.15))
                .frame(width: 48, height: 48)
                .overlay(
                    Image(systemName: subscription.icon)
                        .font(.system(size: 22))
                        .foregroundColor(Color(hexString: subscription.color))
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(subscription.name)
                    .font(.spotifyHeadingMedium)
                    .foregroundColor(.wisePrimaryText)

                Text("Next billing: \(subscription.nextBillingDate, style: .date)")
                    .font(.spotifyCaptionMedium)
                    .foregroundColor(.wiseSecondaryText)
            }

            Spacer()

            Text(String(format: "$%.2f", subscription.price))
                .font(.spotifyNumberMedium)
                .foregroundColor(.wisePrimaryText)
        }
        .padding(16)
        .background(Color.wiseCardBackground)
        .cornerRadius(16)
        .cardShadow()
    }

    private var enableToggleCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "bell.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.wiseBlue)

                Text("Renewal Reminders")
                    .font(.spotifyHeadingMedium)
                    .foregroundColor(.wisePrimaryText)
            }

            Toggle(isOn: $enableReminders) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Enable Reminders")
                        .font(.spotifyBodyMedium)
                        .foregroundColor(.wisePrimaryText)

                    Text("Get notified before your subscription renews")
                        .font(.spotifyCaptionMedium)
                        .foregroundColor(.wiseSecondaryText)
                }
            }
            .tint(.wiseBlue)
        }
        .padding(16)
        .background(Color.wiseCardBackground)
        .cornerRadius(16)
        .cardShadow()
    }

    private var daysBeforeCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Remind me before")
                .font(.spotifyHeadingMedium)
                .foregroundColor(.wisePrimaryText)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(daysBeforeOptions, id: \.self) { days in
                        DaysBeforeChip(
                            days: days,
                            isSelected: daysBefore == days
                        ) {
                            withAnimation(.spring(response: 0.3)) {
                                daysBefore = days
                            }
                            HapticManager.shared.selection()
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(Color.wiseCardBackground)
        .cornerRadius(16)
        .cardShadow()
    }

    private var timeSelectionCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Reminder Time")
                .font(.spotifyHeadingMedium)
                .foregroundColor(.wisePrimaryText)

            HStack {
                Image(systemName: "clock.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.wiseBlue)

                DatePicker(
                    "",
                    selection: $reminderTime,
                    displayedComponents: .hourAndMinute
                )
                .labelsHidden()
                .tint(.wiseBlue)
            }
        }
        .padding(16)
        .background(Color.wiseCardBackground)
        .cornerRadius(16)
        .cardShadow()
    }

    private var reminderPreviewCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.wiseBlue)

                Text("You'll be reminded on:")
                    .font(.spotifyBodyMedium)
                    .foregroundColor(.wiseSecondaryText)
            }

            Text(reminderPreviewDate)
                .font(.spotifyHeadingSmall)
                .fontWeight(.semibold)
                .foregroundColor(.wisePrimaryText)

            Divider()

            // Notification Preview
            VStack(alignment: .leading, spacing: 8) {
                Text("Preview")
                    .font(.spotifyCaptionMedium)
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
                        Text("\(subscription.name) Renews Soon")
                            .font(.spotifyBodyMedium)
                            .fontWeight(.semibold)
                            .foregroundColor(.wisePrimaryText)

                        Text("$\(String(format: "%.2f", subscription.price)) will be charged in \(daysBefore) day\(daysBefore == 1 ? "" : "s")")
                            .font(.spotifyCaptionMedium)
                            .foregroundColor(.wiseSecondaryText)
                    }

                    Spacer()
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.wiseBorder.opacity(0.2))
                )
            }
        }
        .padding(16)
        .background(Color.wiseBlue.opacity(0.05))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.wiseBlue.opacity(0.2), lineWidth: 1)
        )
        .cornerRadius(16)
    }

    private var testNotificationButton: some View {
        Button(action: sendTestNotification) {
            HStack {
                Image(systemName: "paperplane.fill")
                    .font(.system(size: 16))

                Text("Send Test Notification")
                    .font(.spotifyBodyMedium)
                    .fontWeight(.semibold)
            }
            .foregroundColor(.wiseBlue)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.wiseBlue, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helper Methods

    private func saveSettings() {
        isSaving = true

        guard var updatedSubscription = dataManager.subscriptions.first(where: { $0.id == subscription.id }) else {
            isSaving = false
            return
        }

        updatedSubscription.enableRenewalReminder = enableReminders
        updatedSubscription.reminderDaysBefore = daysBefore
        updatedSubscription.reminderTime = reminderTime

        do {
            try dataManager.updateSubscription(updatedSubscription)
            HapticManager.shared.success()
            onSettingsSaved()
            dismiss()
        } catch {
            dataManager.error = error
            HapticManager.shared.error()
        }

        isSaving = false
    }

    private func sendTestNotification() {
        HapticManager.shared.notification(.success)
        showingTestConfirmation = true
    }
}

// MARK: - Days Before Chip

struct DaysBeforeChip: View {
    let days: Int
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text("\(days)")
                    .font(.system(size: 20, weight: .bold))

                Text(days == 1 ? "day" : "days")
                    .font(.spotifyCaptionSmall)
            }
            .foregroundColor(isSelected ? .white : .wiseBlue)
            .frame(width: 64, height: 64)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.wiseBlue : Color.wiseBlue.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.wiseBlue, lineWidth: isSelected ? 0 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview("Reminder Settings Sheet") {
    ReminderSettingsSheet(
        subscription: MockData.activeSubscription,
        onSettingsSaved: {}
    )
    .environmentObject(DataManager.shared)
}
