//
//  EnhancedNotificationSection.swift
//  Swiff IOS
//
//  Created by Agent 5 on 11/21/25.
//  Enhanced notification settings section with advanced options
//

import SwiftUI
import Combine

// AGENT 5: Enhanced notification settings section (Tasks 5.2.1 - 5.2.11)
struct EnhancedNotificationSection: View {
    @ObservedObject var userSettings: UserSettings
    @ObservedObject var notificationManager: NotificationManager

    @State private var showingReminderDaysPicker = false
    @State private var showingCustomDaysInput = false
    @State private var customDays: String = ""
    @State private var showingNotificationHistory = false

    let reminderDayOptions = [1, 3, 7, 14, 30]
    let unusedDaysOptions = [30, 60, 90]

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

            // AGENT 5: Task 5.2.1 - Expand notification section
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

            // AGENT 5: Task 5.2.2 & 5.2.3 - Renewal Reminder Timing with multi-select and custom days
            if userSettings.notificationsEnabled {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Renewal Reminder Timing")
                        .font(.spotifyBodyMedium)
                        .foregroundColor(.wisePrimaryText)

                    ForEach(reminderDayOptions, id: \.self) { days in
                        Toggle(isOn: Binding(
                            get: { userSettings.renewalReminderDays.contains(days) },
                            set: { isOn in
                                if isOn {
                                    if !userSettings.renewalReminderDays.contains(days) {
                                        userSettings.renewalReminderDays.append(days)
                                        userSettings.renewalReminderDays.sort()
                                    }
                                } else {
                                    userSettings.renewalReminderDays.removeAll { $0 == days }
                                }
                            }
                        )) {
                            Text("\(days) \(days == 1 ? "day" : "days") before")
                                .font(.spotifyBodySmall)
                                .foregroundColor(.wisePrimaryText)
                        }
                        .tint(.wiseForestGreen)
                        .padding(.leading, 16)
                    }

                    Button(action: {
                        showingCustomDaysInput = true
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.wiseForestGreen)
                            Text("Add Custom Days")
                                .font(.spotifyBodySmall)
                                .foregroundColor(.wiseForestGreen)
                        }
                        .padding(.leading, 16)
                    }
                }

                // AGENT 5: Task 5.2.4 - Send at time picker
                DatePicker(
                    "Send Reminders At",
                    selection: $userSettings.reminderTime,
                    displayedComponents: .hourAndMinute
                )
                .font(.spotifyBodyMedium)

                Divider()

                // AGENT 5: Task 5.2.5 - Trial Expiration Reminders
                Toggle(isOn: $userSettings.trialExpirationReminders) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Trial Expiration Reminders")
                            .font(.spotifyBodyMedium)
                            .foregroundColor(.wisePrimaryText)
                        Text("Get notified before free trials end")
                            .font(.spotifyCaptionMedium)
                            .foregroundColor(.wiseSecondaryText)
                    }
                }
                .tint(.wiseForestGreen)

                // AGENT 5: Task 5.2.6 - Price Increase Alerts
                Toggle(isOn: $userSettings.priceIncreaseAlerts) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Price Increase Alerts")
                            .font(.spotifyBodyMedium)
                            .foregroundColor(.wisePrimaryText)
                        Text("Be notified of subscription price changes")
                            .font(.spotifyCaptionMedium)
                            .foregroundColor(.wiseSecondaryText)
                    }
                }
                .tint(.wiseForestGreen)

                // AGENT 5: Task 5.2.7 - Unused Subscription Alerts
                VStack(alignment: .leading, spacing: 12) {
                    Toggle(isOn: $userSettings.unusedSubscriptionAlerts) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Unused Subscription Alerts")
                                .font(.spotifyBodyMedium)
                                .foregroundColor(.wisePrimaryText)
                            Text("Get alerts for subscriptions you're not using")
                                .font(.spotifyCaptionMedium)
                                .foregroundColor(.wiseSecondaryText)
                        }
                    }
                    .tint(.wiseForestGreen)

                    if userSettings.unusedSubscriptionAlerts {
                        Picker("Alert After", selection: $userSettings.unusedSubscriptionDays) {
                            ForEach(unusedDaysOptions, id: \.self) { days in
                                Text("\(days) days").tag(days)
                            }
                        }
                        .pickerStyle(.menu)
                        .padding(.leading, 16)
                    }
                }

                Divider()

                // AGENT 5: Task 5.2.8 & 5.2.9 - Quiet Hours
                VStack(alignment: .leading, spacing: 12) {
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
                        DatePicker(
                            "Start Time",
                            selection: $userSettings.quietHoursStart,
                            displayedComponents: .hourAndMinute
                        )
                        .font(.spotifyBodySmall)
                        .padding(.leading, 16)

                        DatePicker(
                            "End Time",
                            selection: $userSettings.quietHoursEnd,
                            displayedComponents: .hourAndMinute
                        )
                        .font(.spotifyBodySmall)
                        .padding(.leading, 16)
                    }
                }

                Divider()

                // AGENT 5: Task 5.2.10 - Test Notification button
                Button(action: sendTestNotification) {
                    HStack {
                        Image(systemName: "bell.badge.fill")
                            .foregroundColor(.wiseBlue)
                        Text("Send Test Notification")
                            .foregroundColor(.wisePrimaryText)
                        Spacer()
                    }
                }

                // AGENT 5: Task 5.2.11 - Notification History link
                Button(action: {
                    showingNotificationHistory = true
                }) {
                    HStack {
                        Image(systemName: "clock.fill")
                            .foregroundColor(.wiseForestGreen)
                        Text("Notification History")
                            .foregroundColor(.wisePrimaryText)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14))
                            .foregroundColor(.wiseSecondaryText)
                    }
                }
            }
        } header: {
            Text("Notifications")
                .font(.spotifyLabelSmall)
                .foregroundColor(.wiseSecondaryText)
        } footer: {
            Text("Customize when and how you receive notifications. Selected reminder days: \(userSettings.renewalReminderDays.map(String.init).joined(separator: ", ")) days before renewal.")
                .font(.spotifyCaptionMedium)
                .foregroundColor(.wiseSecondaryText)
        }
        .alert("Add Custom Days", isPresented: $showingCustomDaysInput) {
            TextField("Days", text: $customDays)
                .keyboardType(.numberPad)
            Button("Cancel", role: .cancel) {
                customDays = ""
            }
            Button("Add") {
                if let days = Int(customDays), days > 0 {
                    if !userSettings.renewalReminderDays.contains(days) {
                        userSettings.renewalReminderDays.append(days)
                        userSettings.renewalReminderDays.sort()
                    }
                }
                customDays = ""
            }
        } message: {
            Text("Enter the number of days before renewal to send a reminder")
        }
        .sheet(isPresented: $showingNotificationHistory) {
            NotificationHistoryView()
        }
    }

    // AGENT 5: Send test notification
    private func sendTestNotification() {
        Task {
            await notificationManager.sendTestNotification()
            ToastManager.shared.showSuccess("Test notification sent")
        }
    }
}

// AGENT 5: Notification history view is now in NotificationHistoryView.swift

#Preview {
    List {
        EnhancedNotificationSection(
            userSettings: UserSettings.shared,
            notificationManager: NotificationManager.shared
        )
    }
}
