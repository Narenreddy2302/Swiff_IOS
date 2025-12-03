//
//  NotificationSettingsSection.swift
//  Swiff IOS
//
//  Created by Agent 5 on 11/21/25.
//  Enhanced notification settings with timing, quiet hours, and test notifications
//

import SwiftUI
import Combine

struct NotificationSettingsSection: View {
    @StateObject private var userSettings = UserSettings.shared
    @StateObject private var notificationManager = NotificationManager.shared
    @State private var showingCustomReminderSheet = false
    @State private var customReminderDays: Int = 3
    @State private var showingNotificationHistory = false

    var body: some View {
        Section {
            // System notification permission
            if !notificationManager.isAuthorized {
                Button(action: {
                    Task {
                        if notificationManager.permissionStatus == .denied {
                            notificationManager.openSettings()
                        } else {
                            _ = await notificationManager.requestPermission()
                        }
                    }
                }) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Enable System Notifications")
                                .font(.spotifyBodyMedium)
                                .foregroundColor(.wisePrimaryText)
                            Text(notificationManager.permissionStatus == .denied
                                ? "Open Settings to enable notifications"
                                : "Allow Swiff to send you notifications")
                                .font(.spotifyCaptionMedium)
                                .foregroundColor(.wiseSecondaryText)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14))
                            .foregroundColor(.wiseSecondaryText)
                    }
                }
            }

            // Master notifications toggle
            Toggle(isOn: $userSettings.notificationsEnabled) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Enable Notifications")
                        .font(.spotifyBodyMedium)
                        .foregroundColor(.wisePrimaryText)
                    Text("Get alerts for important events")
                        .font(.spotifyCaptionMedium)
                        .foregroundColor(.wiseSecondaryText)
                }
            }
            .tint(.wiseForestGreen)
            .disabled(!notificationManager.isAuthorized)

            // Renewal reminder timing
            VStack(alignment: .leading, spacing: 8) {
                Text("Renewal Reminder Timing")
                    .font(.spotifyBodyMedium)
                    .foregroundColor(.wisePrimaryText)

                MultiSelectPicker(
                    selection: $userSettings.renewalReminderDays,
                    options: [1, 3, 7, 14, 30],
                    displayText: { "\($0) day\($0 == 1 ? "" : "s") before" }
                )

                Button(action: {
                    showingCustomReminderSheet = true
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.wiseBlue)
                        Text("Add Custom Day Count")
                            .font(.spotifyCaptionMedium)
                            .foregroundColor(.wiseBlue)
                    }
                }
            }
            .disabled(!userSettings.notificationsEnabled)

            // Reminder time picker
            DatePicker(
                "Send at",
                selection: $userSettings.reminderTime,
                displayedComponents: .hourAndMinute
            )
            .font(.spotifyBodyMedium)
            .foregroundColor(.wisePrimaryText)
            .disabled(!userSettings.notificationsEnabled)

            // Trial expiration reminders
            Toggle(isOn: $userSettings.trialExpirationReminders) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Trial Expiration Reminders")
                        .font(.spotifyBodyMedium)
                        .foregroundColor(.wisePrimaryText)
                    Text("Alert me before trials expire")
                        .font(.spotifyCaptionMedium)
                        .foregroundColor(.wiseSecondaryText)
                }
            }
            .tint(.wiseForestGreen)
            .disabled(!userSettings.notificationsEnabled)

            // Price increase alerts
            Toggle(isOn: $userSettings.priceIncreaseAlerts) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Price Increase Alerts")
                        .font(.spotifyBodyMedium)
                        .foregroundColor(.wisePrimaryText)
                    Text("Notify me when subscription prices go up")
                        .font(.spotifyCaptionMedium)
                        .foregroundColor(.wiseSecondaryText)
                }
            }
            .tint(.wiseForestGreen)
            .disabled(!userSettings.notificationsEnabled)

            // Unused subscription alerts
            VStack(alignment: .leading, spacing: 8) {
                Toggle(isOn: $userSettings.unusedSubscriptionAlerts) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Unused Subscription Alerts")
                            .font(.spotifyBodyMedium)
                            .foregroundColor(.wisePrimaryText)
                        Text("Alert me about subscriptions I'm not using")
                            .font(.spotifyCaptionMedium)
                            .foregroundColor(.wiseSecondaryText)
                    }
                }
                .tint(.wiseForestGreen)

                if userSettings.unusedSubscriptionAlerts {
                    Picker("Alert after", selection: $userSettings.unusedSubscriptionDays) {
                        Text("30 days").tag(30)
                        Text("60 days").tag(60)
                        Text("90 days").tag(90)
                    }
                    .pickerStyle(.segmented)
                }
            }
            .disabled(!userSettings.notificationsEnabled)

            // Quiet hours
            VStack(alignment: .leading, spacing: 8) {
                Toggle(isOn: $userSettings.quietHoursEnabled) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Quiet Hours")
                            .font(.spotifyBodyMedium)
                            .foregroundColor(.wisePrimaryText)
                        Text("Don't send notifications during these hours")
                            .font(.spotifyCaptionMedium)
                            .foregroundColor(.wiseSecondaryText)
                    }
                }
                .tint(.wiseForestGreen)

                if userSettings.quietHoursEnabled {
                    HStack {
                        DatePicker(
                            "Start",
                            selection: $userSettings.quietHoursStart,
                            displayedComponents: .hourAndMinute
                        )
                        .font(.spotifyCaptionMedium)

                        DatePicker(
                            "End",
                            selection: $userSettings.quietHoursEnd,
                            displayedComponents: .hourAndMinute
                        )
                        .font(.spotifyCaptionMedium)
                    }
                }
            }
            .disabled(!userSettings.notificationsEnabled)

            // Test notification button
            Button(action: {
                Task {
                    await NotificationManager.shared.sendTestNotification()
                }
            }) {
                HStack {
                    Image(systemName: "bell.badge.fill")
                        .foregroundColor(.wiseBlue)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Send Test Notification")
                            .font(.spotifyBodyMedium)
                            .foregroundColor(.wisePrimaryText)
                        Text("Preview how notifications will look")
                            .font(.spotifyCaptionMedium)
                            .foregroundColor(.wiseSecondaryText)
                    }
                    Spacer()
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.wiseBlue)
                }
            }
            .disabled(!notificationManager.isAuthorized)

            // Notification history link
            NavigationLink(destination: NotificationHistoryView()) {
                HStack {
                    Image(systemName: "list.bullet.clipboard")
                        .foregroundColor(.wiseBlue)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Notification History")
                            .font(.spotifyBodyMedium)
                            .foregroundColor(.wisePrimaryText)
                        Text("View all sent notifications")
                            .font(.spotifyCaptionMedium)
                            .foregroundColor(.wiseSecondaryText)
                    }
                    Spacer()
                }
            }

        } header: {
            Text("Notifications")
                .font(.spotifyLabelSmall)
                .foregroundColor(.wiseSecondaryText)
        }
        .sheet(isPresented: $showingCustomReminderSheet) {
            CustomReminderDaySheet(
                customDays: $customReminderDays,
                onAdd: {
                    if !userSettings.renewalReminderDays.contains(customReminderDays) {
                        userSettings.renewalReminderDays.append(customReminderDays)
                        userSettings.renewalReminderDays.sort()
                    }
                    showingCustomReminderSheet = false
                }
            )
        }
    }
}

// Multi-select picker component
struct MultiSelectPicker<T: Hashable>: View {
    @Binding var selection: [T]
    let options: [T]
    let displayText: (T) -> String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(options, id: \.self) { option in
                Button(action: {
                    if selection.contains(option) {
                        selection.removeAll { $0 == option }
                    } else {
                        selection.append(option)
                    }
                }) {
                    HStack {
                        Image(systemName: selection.contains(option) ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(selection.contains(option) ? .wiseForestGreen : .wiseSecondaryText)
                        Text(displayText(option))
                            .font(.spotifyCaptionMedium)
                            .foregroundColor(.wisePrimaryText)
                        Spacer()
                    }
                }
            }
        }
    }
}

// Custom reminder day sheet
struct CustomReminderDaySheet: View {
    @Environment(\.dismiss) var dismiss
    @Binding var customDays: Int
    let onAdd: () -> Void

    var body: some View {
        NavigationView {
            Form {
                Section {
                    Stepper(value: $customDays, in: 1...365) {
                        HStack {
                            Text("Days before renewal")
                                .font(.spotifyBodyMedium)
                            Spacer()
                            Text("\(customDays)")
                                .font(.spotifyBodyMedium)
                                .foregroundColor(.wiseBlue)
                        }
                    }
                }

                Section {
                    Button(action: onAdd) {
                        HStack {
                            Spacer()
                            Text("Add Reminder")
                                .font(.spotifyBodyMedium)
                                .foregroundColor(.white)
                            Spacer()
                        }
                        .padding(.vertical, 12)
                        .background(Color.wiseForestGreen)
                        .cornerRadius(12)
                    }
                    .listRowBackground(Color.clear)
                }
            }
            .navigationTitle("Custom Reminder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.wiseForestGreen)
                }
            }
        }
    }
}

// Notification history view is now in NotificationHistoryView.swift

// Empty state view component
struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundColor(.wiseSecondaryText)

            Text(title)
                .font(.spotifyHeadingMedium)
                .foregroundColor(.wisePrimaryText)

            Text(message)
                .font(.spotifyBodySmall)
                .foregroundColor(.wiseSecondaryText)
                .multilineTextAlignment(.center)
        }
        .padding(40)
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    NavigationView {
        List {
            NotificationSettingsSection()
        }
    }
}
