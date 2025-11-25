//
//  EditSubscriptionSheet.swift
//  Swiff IOS
//
//  Created by Naren Reddy on 11/20/25.
//  Edit existing subscription
//

import SwiftUI
import Combine

struct EditSubscriptionSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataManager: DataManager

    let subscription: Subscription
    let onSubscriptionUpdated: () -> Void

    @State private var name: String
    @State private var description: String
    @State private var price: String
    @State private var selectedBillingCycle: BillingCycle
    @State private var selectedCategory: SubscriptionCategory
    @State private var selectedIcon: String
    @State private var selectedColor: String
    @State private var isShared: Bool
    @State private var selectedPaymentMethod: PaymentMethod
    @State private var website: String
    @State private var notes: String
    @State private var showingIconPicker = false
    @State private var showingColorPicker = false

    // AGENT 9: Price change confirmation
    @State private var showingPriceChangeConfirmation = false
    @State private var priceChangeReason = ""
    @State private var isPriceChangeRealChange = true
    private var originalPrice: Double

    // AGENT 8: Trial fields
    @State private var isFreeTrial: Bool
    @State private var trialStartDate: Date
    @State private var trialEndDate: Date
    @State private var trialDuration: Int = 7 // AGENT 8: Default 7 days
    @State private var willConvertToPaid: Bool
    @State private var priceAfterTrial: String

    // AGENT 7: Reminder fields
    @State private var enableRenewalReminder: Bool
    @State private var reminderDaysBefore: Int
    @State private var reminderTime: Date

    init(subscription: Subscription, onSubscriptionUpdated: @escaping () -> Void) {
        self.subscription = subscription
        self.onSubscriptionUpdated = onSubscriptionUpdated
        self.originalPrice = subscription.price  // AGENT 9: Store original price

        _name = State(initialValue: subscription.name)
        _description = State(initialValue: subscription.description)
        _price = State(initialValue: String(format: "%.2f", subscription.price))
        _selectedBillingCycle = State(initialValue: subscription.billingCycle)
        _selectedCategory = State(initialValue: subscription.category)
        _selectedIcon = State(initialValue: subscription.icon)
        _selectedColor = State(initialValue: subscription.color)
        _isShared = State(initialValue: subscription.isShared)
        _selectedPaymentMethod = State(initialValue: subscription.paymentMethod)
        _website = State(initialValue: subscription.website ?? "")
        _notes = State(initialValue: subscription.notes)

        // Initialize trial fields
        _isFreeTrial = State(initialValue: subscription.isFreeTrial)
        _trialStartDate = State(initialValue: subscription.trialStartDate ?? Date())
        _trialEndDate = State(initialValue: subscription.trialEndDate ?? Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date())
        _willConvertToPaid = State(initialValue: subscription.willConvertToPaid)
        _priceAfterTrial = State(initialValue: subscription.priceAfterTrial != nil ? String(format: "%.2f", subscription.priceAfterTrial!) : "")

        // AGENT 7: Initialize reminder fields
        _enableRenewalReminder = State(initialValue: subscription.enableRenewalReminder)
        _reminderDaysBefore = State(initialValue: subscription.reminderDaysBefore)
        let defaultTime = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()
        _reminderTime = State(initialValue: subscription.reminderTime ?? defaultTime)
    }

    let availableIcons = [
        "app.fill", "tv.fill", "music.note", "camera.fill", "icloud.fill",
        "paintbrush.fill", "doc.text.fill", "brain.head.profile", "gamecontroller.fill",
        "newspaper.fill", "creditcard.fill", "car.fill", "house.fill",
        "heart.fill", "graduationcap.fill", "wrench.and.screwdriver.fill",
        "chevron.left.forwardslash.chevron.right", "play.rectangle.fill"
    ]

    let availableColors = [
        "#007AFF", "#FF3B30", "#FF9500", "#FFCC00", "#34C759",
        "#5AC8FA", "#AF52DE", "#FF2D92", "#A2845E", "#8E8E93",
        "#E50914", "#1DB954", "#FF0000", "#181717", "#FF7262",
        "#113CCF", "#000000", "#FF6B35"
    ]

    // AGENT 8: Enhanced form validation for trials
    private var isFormValid: Bool {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty,
              !description.trimmingCharacters(in: .whitespaces).isEmpty,
              !price.trimmingCharacters(in: .whitespaces).isEmpty else {
            return false
        }

        // AGENT 8: Allow price to be 0 if trial
        if isFreeTrial {
            return true
        }

        guard let priceValue = Double(price) else {
            return false
        }
        return priceValue > 0
    }

    // AGENT 8: Check if trial is expiring soon (< 3 days)
    private var isTrialExpiringSoon: Bool {
        guard isFreeTrial else { return false }
        let daysUntilEnd = Calendar.current.dateComponents([.day], from: Date(), to: trialEndDate).day ?? 0
        return daysUntilEnd < 3 && daysUntilEnd >= 0
    }

    // AGENT 8: Calculate trial duration automatically
    private func calculateTrialDuration() -> Int {
        let components = Calendar.current.dateComponents([.day], from: trialStartDate, to: trialEndDate)
        return max(0, components.day ?? 0)
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Visual Preview
                    VStack(spacing: 16) {
                        Text("Preview")
                            .font(.spotifyHeadingMedium)
                            .foregroundColor(.wisePrimaryText)

                        // Subscription Preview Card
                        HStack(spacing: 16) {
                            Circle()
                                .fill((Color(hex: selectedColor) ?? Color.gray).opacity(0.2))
                                .frame(width: 48, height: 48)
                                .overlay(
                                    Image(systemName: selectedIcon)
                                        .font(.system(size: 20, weight: .medium))
                                        .foregroundColor(Color(hex: selectedColor) ?? .gray)
                                )

                            VStack(alignment: .leading, spacing: 4) {
                                Text(name.isEmpty ? "Subscription Name" : name)
                                    .font(.spotifyBodyLarge)
                                    .foregroundColor(.wisePrimaryText)

                                Text(description.isEmpty ? "Description" : description)
                                    .font(.spotifyBodySmall)
                                    .foregroundColor(.wiseSecondaryText)
                                    .lineLimit(1)

                                HStack(spacing: 4) {
                                    Image(systemName: selectedCategory.icon)
                                        .font(.system(size: 12))
                                        .foregroundColor(selectedCategory.color)

                                    Text(selectedCategory.rawValue)
                                        .font(.spotifyCaptionSmall)
                                        .foregroundColor(.wiseSecondaryText)
                                }
                            }

                            Spacer()

                            VStack(alignment: .trailing, spacing: 2) {
                                if let priceValue = Double(price) {
                                    Text(String(format: "$%.2f", priceValue))
                                        .font(.spotifyNumberMedium)
                                        .foregroundColor(.wisePrimaryText)

                                    Text(selectedBillingCycle.displayName)
                                        .font(.spotifyCaptionSmall)
                                        .foregroundColor(.wiseSecondaryText)
                                }
                            }
                        }
                        .padding(16)
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.03), radius: 4, x: 0, y: 2)
                    }

                    // Basic Information
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Basic Information")
                            .font(.spotifyHeadingMedium)
                            .foregroundColor(.wisePrimaryText)

                        // Name
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Name *")
                                .font(.spotifyLabelMedium)
                                .foregroundColor(.wiseSecondaryText)

                            TextField("e.g., Netflix", text: $name)
                                .font(.spotifyBodyMedium)
                                .foregroundColor(.wisePrimaryText)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.wiseBorder.opacity(0.5))
                                        .stroke(Color.wiseBorder, lineWidth: 1)
                                )
                        }

                        // Description
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Description *")
                                .font(.spotifyLabelMedium)
                                .foregroundColor(.wiseSecondaryText)

                            TextField("e.g., Premium streaming plan", text: $description)
                                .font(.spotifyBodyMedium)
                                .foregroundColor(.wisePrimaryText)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.wiseBorder.opacity(0.5))
                                        .stroke(Color.wiseBorder, lineWidth: 1)
                                )
                        }

                        // Price
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Price *")
                                .font(.spotifyLabelMedium)
                                .foregroundColor(.wiseSecondaryText)

                            HStack {
                                Text("$")
                                    .font(.spotifyNumberLarge)
                                    .foregroundColor(.wisePrimaryText)

                                TextField("0.00", text: $price)
                                    .font(.spotifyNumberLarge)
                                    .foregroundColor(.wisePrimaryText)
                                    .keyboardType(.decimalPad)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.wiseBorder.opacity(0.5))
                                    .stroke(Color.wiseBorder, lineWidth: 1)
                            )
                        }

                        // Billing Cycle
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Billing Cycle *")
                                .font(.spotifyLabelMedium)
                                .foregroundColor(.wiseSecondaryText)

                            Picker("Billing Cycle", selection: $selectedBillingCycle) {
                                ForEach(BillingCycle.allCases, id: \.self) { cycle in
                                    Text(cycle.displayName).tag(cycle)
                                }
                            }
                            .pickerStyle(.segmented)
                        }
                    }

                    // Category & Appearance
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Category & Appearance")
                            .font(.spotifyHeadingMedium)
                            .foregroundColor(.wisePrimaryText)

                        // Category
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Category")
                                .font(.spotifyLabelMedium)
                                .foregroundColor(.wiseSecondaryText)

                            Picker("Category", selection: $selectedCategory) {
                                ForEach(SubscriptionCategory.allCases, id: \.self) { category in
                                    HStack {
                                        Image(systemName: category.icon)
                                        Text(category.rawValue)
                                    }
                                    .tag(category)
                                }
                            }
                            .pickerStyle(.menu)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.wiseBorder.opacity(0.5))
                                    .stroke(Color.wiseBorder, lineWidth: 1)
                            )
                        }

                        // Icon
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Icon")
                                .font(.spotifyLabelMedium)
                                .foregroundColor(.wiseSecondaryText)

                            Button(action: { showingIconPicker.toggle() }) {
                                HStack {
                                    Image(systemName: selectedIcon)
                                        .foregroundColor(Color(hex: selectedColor) ?? .gray)
                                    Text("Tap to change icon")
                                        .font(.spotifyBodyMedium)
                                        .foregroundColor(.wisePrimaryText)
                                    Spacer()
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.wiseBorder.opacity(0.5))
                                        .stroke(Color.wiseBorder, lineWidth: 1)
                                )
                            }

                            if showingIconPicker {
                                LazyVGrid(columns: [GridItem(.adaptive(minimum: 50))], spacing: 12) {
                                    ForEach(availableIcons, id: \.self) { icon in
                                        Button(action: {
                                            selectedIcon = icon
                                            showingIconPicker = false
                                        }) {
                                            Image(systemName: icon)
                                                .font(.system(size: 24))
                                                .foregroundColor(selectedIcon == icon ? Color(hex: selectedColor) ?? .gray : .wiseSecondaryText)
                                                .frame(width: 50, height: 50)
                                                .background(
                                                    selectedIcon == icon 
                                                        ? (Color(hex: selectedColor) ?? Color.gray).opacity(0.1)
                                                        : Color.wiseBorder.opacity(0.3)
                                                )
                                                .cornerRadius(8)
                                        }
                                    }
                                }
                                .padding(.top, 8)
                            }
                        }

                        // Color
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Color")
                                .font(.spotifyLabelMedium)
                                .foregroundColor(.wiseSecondaryText)

                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 40))], spacing: 12) {
                                ForEach(availableColors, id: \.self) { colorHex in
                                    Button(action: { selectedColor = colorHex }) {
                                        Circle()
                                            .fill(Color(hex: colorHex) ?? Color.gray)
                                            .frame(width: 40, height: 40)
                                            .overlay(
                                                Circle()
                                                    .stroke(Color.white, lineWidth: selectedColor == colorHex ? 3 : 0)
                                            )
                                            .shadow(color: .black.opacity(0.2), radius: selectedColor == colorHex ? 4 : 0)
                                    }
                                }
                            }
                        }
                    }

                    // Additional Details
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Additional Details")
                            .font(.spotifyHeadingMedium)
                            .foregroundColor(.wisePrimaryText)

                        // Payment Method
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Payment Method")
                                .font(.spotifyLabelMedium)
                                .foregroundColor(.wiseSecondaryText)

                            Picker("Payment Method", selection: $selectedPaymentMethod) {
                                ForEach(PaymentMethod.allCases, id: \.self) { method in
                                    Text(method.rawValue).tag(method)
                                }
                            }
                            .pickerStyle(.segmented)
                        }

                        // Website
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Website (Optional)")
                                .font(.spotifyLabelMedium)
                                .foregroundColor(.wiseSecondaryText)

                            TextField("e.g., netflix.com", text: $website)
                                .font(.spotifyBodyMedium)
                                .foregroundColor(.wisePrimaryText)
                                .autocapitalization(.none)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.wiseBorder.opacity(0.5))
                                        .stroke(Color.wiseBorder, lineWidth: 1)
                                )
                        }

                        // Notes
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Notes (Optional)")
                                .font(.spotifyLabelMedium)
                                .foregroundColor(.wiseSecondaryText)

                            TextEditor(text: $notes)
                                .font(.spotifyBodyMedium)
                                .foregroundColor(.wisePrimaryText)
                                .frame(height: 100)
                                .padding(12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.wiseBorder.opacity(0.5))
                                        .stroke(Color.wiseBorder, lineWidth: 1)
                                )
                        }

                        // Shared toggle
                        Toggle(isOn: $isShared) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Shared Subscription")
                                    .font(.spotifyBodyMedium)
                                    .foregroundColor(.wisePrimaryText)
                                Text("Split costs with others")
                                    .font(.spotifyCaptionMedium)
                                    .foregroundColor(.wiseSecondaryText)
                            }
                        }
                        .tint(.wiseForestGreen)
                    }

                    // Free Trial Settings
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Free Trial Settings")
                            .font(.spotifyHeadingMedium)
                            .foregroundColor(.wisePrimaryText)

                        // Free Trial toggle
                        Toggle(isOn: $isFreeTrial) {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 6) {
                                    Image(systemName: "gift.fill")
                                        .font(.system(size: 14))
                                        .foregroundColor(.orange)
                                    Text("Free Trial")
                                        .font(.spotifyBodyMedium)
                                        .foregroundColor(.wisePrimaryText)
                                }
                                Text("This subscription is currently on a free trial")
                                    .font(.spotifyCaptionMedium)
                                    .foregroundColor(.wiseSecondaryText)
                            }
                        }
                        .tint(.orange)

                        if isFreeTrial {
                            // Trial Start Date
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Trial Start Date")
                                    .font(.spotifyLabelMedium)
                                    .foregroundColor(.wiseSecondaryText)

                                DatePicker("", selection: $trialStartDate, displayedComponents: .date)
                                    .datePickerStyle(.compact)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.wiseBorder.opacity(0.5))
                                            .stroke(Color.wiseBorder, lineWidth: 1)
                                    )
                            }

                            // Trial End Date
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Trial End Date")
                                    .font(.spotifyLabelMedium)
                                    .foregroundColor(.wiseSecondaryText)

                                DatePicker("", selection: $trialEndDate, in: trialStartDate..., displayedComponents: .date)
                                    .datePickerStyle(.compact)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.wiseBorder.opacity(0.5))
                                            .stroke(Color.wiseBorder, lineWidth: 1)
                                    )
                                    .onChange(of: trialEndDate) { _ in
                                        // AGENT 8: Auto-calculate duration when end date changes
                                        trialDuration = calculateTrialDuration()
                                    }
                            }

                            // AGENT 8: Trial Duration Display
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Trial Duration")
                                    .font(.spotifyLabelMedium)
                                    .foregroundColor(.wiseSecondaryText)

                                HStack {
                                    Image(systemName: "calendar.badge.clock")
                                        .font(.system(size: 16))
                                        .foregroundColor(.orange)
                                    Text("\(calculateTrialDuration()) days")
                                        .font(.spotifyBodyMedium)
                                        .foregroundColor(.wisePrimaryText)
                                    Spacer()
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.orange.opacity(0.1))
                                        .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                                )
                            }

                            // AGENT 8: Trial expiration warning
                            if isTrialExpiringSoon {
                                HStack(spacing: 8) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .font(.system(size: 14))
                                        .foregroundColor(.orange)
                                    Text("Trial expires in less than 3 days!")
                                        .font(.spotifyCaptionMedium)
                                        .foregroundColor(.orange)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.orange.opacity(0.1))
                                )
                            }

                            // Will Convert to Paid
                            Toggle(isOn: $willConvertToPaid) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Convert to Paid After Trial")
                                        .font(.spotifyBodyMedium)
                                        .foregroundColor(.wisePrimaryText)
                                    Text("Automatically switch to paid subscription when trial ends")
                                        .font(.spotifyCaptionMedium)
                                        .foregroundColor(.wiseSecondaryText)
                                }
                            }
                            .tint(.wiseForestGreen)

                            // Price After Trial (if different)
                            if willConvertToPaid {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Price After Trial (Optional)")
                                        .font(.spotifyLabelMedium)
                                        .foregroundColor(.wiseSecondaryText)

                                    HStack {
                                        Text("$")
                                            .font(.spotifyNumberLarge)
                                            .foregroundColor(.wisePrimaryText)

                                        TextField("Same as current price", text: $priceAfterTrial)
                                            .font(.spotifyBodyMedium)
                                            .foregroundColor(.wisePrimaryText)
                                            .keyboardType(.decimalPad)
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.wiseBorder.opacity(0.5))
                                            .stroke(Color.wiseBorder, lineWidth: 1)
                                    )

                                    Text("Leave empty if price remains the same")
                                        .font(.spotifyCaptionSmall)
                                        .foregroundColor(.wiseSecondaryText)
                                        .padding(.horizontal, 4)
                                }
                            }
                        }
                    }

                    // AGENT 7: Reminders Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Reminders")
                            .font(.spotifyHeadingMedium)
                            .foregroundColor(.wisePrimaryText)

                        // Enable Renewal Reminders Toggle
                        Toggle(isOn: $enableRenewalReminder) {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 6) {
                                    Image(systemName: "bell.fill")
                                        .font(.system(size: 14))
                                        .foregroundColor(.wiseBlue)
                                    Text("Enable Renewal Reminders")
                                        .font(.spotifyBodyMedium)
                                        .foregroundColor(.wisePrimaryText)
                                }
                                Text("Get notified before this subscription renews")
                                    .font(.spotifyCaptionMedium)
                                    .foregroundColor(.wiseSecondaryText)
                            }
                        }
                        .tint(.wiseBlue)

                        if enableRenewalReminder {
                            // Remind Me Picker
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Remind Me")
                                    .font(.spotifyLabelMedium)
                                    .foregroundColor(.wiseSecondaryText)

                                Picker("Remind me", selection: $reminderDaysBefore) {
                                    Text("1 day before").tag(1)
                                    Text("3 days before").tag(3)
                                    Text("7 days before").tag(7)
                                    Text("14 days before").tag(14)
                                    Text("30 days before").tag(30)
                                }
                                .pickerStyle(.menu)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.wiseBorder.opacity(0.5))
                                        .stroke(Color.wiseBorder, lineWidth: 1)
                                )
                            }

                            // Reminder Time Picker
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Reminder Time")
                                    .font(.spotifyLabelMedium)
                                    .foregroundColor(.wiseSecondaryText)

                                DatePicker("", selection: $reminderTime, displayedComponents: .hourAndMinute)
                                    .datePickerStyle(.compact)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.wiseBorder.opacity(0.5))
                                            .stroke(Color.wiseBorder, lineWidth: 1)
                                    )
                            }

                            // Test Reminder Button
                            Button(action: sendTestReminder) {
                                HStack {
                                    Image(systemName: "paperplane.fill")
                                        .font(.system(size: 14))
                                    Text("Send Test Reminder")
                                        .font(.spotifyBodyMedium)
                                        .fontWeight(.medium)
                                }
                                .frame(maxWidth: .infinity)
                                .foregroundColor(.wiseBlue)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.wiseBlue.opacity(0.1))
                                        .stroke(Color.wiseBlue, lineWidth: 1)
                                )
                            }

                            Text("You'll receive a sample notification to preview how reminders will look")
                                .font(.spotifyCaptionSmall)
                                .foregroundColor(.wiseSecondaryText)
                                .padding(.horizontal, 4)
                        }
                    }

                    Spacer(minLength: 50)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
            .navigationTitle("Edit Subscription")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .font(.spotifyLabelLarge)
                    .foregroundColor(.wiseSecondaryText)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        // AGENT 9: Check if price changed
                        if let newPrice = Double(price), newPrice != originalPrice {
                            showingPriceChangeConfirmation = true
                        } else {
                            updateSubscription()
                        }
                    }
                    .font(.spotifyLabelLarge)
                    .foregroundColor(isFormValid ? .white : .wiseSecondaryText)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(isFormValid ? Color.wiseForestGreen : Color.wiseBorder)
                    )
                    .disabled(!isFormValid)
                }
            }
        }
        // AGENT 9: Price change confirmation sheet
        .sheet(isPresented: $showingPriceChangeConfirmation) {
            priceChangeConfirmationSheet
        }
    }

    // AGENT 9: Price change confirmation sheet
    private var priceChangeConfirmationSheet: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.orange)

                    Text("Price Change Detected")
                        .font(.spotifyHeadingLarge)
                        .foregroundColor(.wisePrimaryText)

                    Text("Did the price really change, or are you correcting an error?")
                        .font(.spotifyBodyMedium)
                        .foregroundColor(.wiseSecondaryText)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 40)

                // Price comparison
                VStack(spacing: 16) {
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Original Price")
                                .font(.spotifyLabelSmall)
                                .foregroundColor(.wiseSecondaryText)
                            Text(String(format: "$%.2f", originalPrice))
                                .font(.spotifyNumberLarge)
                                .foregroundColor(.wisePrimaryText)
                        }

                        Image(systemName: "arrow.right")
                            .font(.system(size: 20))
                            .foregroundColor(.wiseSecondaryText)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("New Price")
                                .font(.spotifyLabelSmall)
                                .foregroundColor(.wiseSecondaryText)
                            if let newPrice = Double(price) {
                                Text(String(format: "$%.2f", newPrice))
                                    .font(.spotifyNumberLarge)
                                    .foregroundColor(newPrice > originalPrice ? .wiseError : .wiseBrightGreen)
                            }
                        }
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.wiseBorder.opacity(0.3))
                    )

                    if let newPrice = Double(price) {
                        let change = ((newPrice - originalPrice) / originalPrice) * 100
                        Text(String(format: "%@%.1f%% %@", change >= 0 ? "+" : "", change, change >= 0 ? "increase" : "decrease"))
                            .font(.spotifyBodyMedium)
                            .fontWeight(.semibold)
                            .foregroundColor(change >= 0 ? .wiseError : .wiseBrightGreen)
                    }
                }

                // Choice buttons
                VStack(spacing: 12) {
                    Button(action: {
                        isPriceChangeRealChange = true
                        showingPriceChangeConfirmation = false
                        updateSubscription()
                    }) {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 20))
                                Text("Yes, the price actually changed")
                                    .font(.spotifyBodyLarge)
                                    .fontWeight(.semibold)
                                Spacer()
                            }
                            Text("This will be recorded in price history and tracked")
                                .font(.spotifyCaptionMedium)
                                .foregroundColor(.wiseSecondaryText)
                        }
                        .foregroundColor(.wisePrimaryText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.wiseForestGreen, lineWidth: 2)
                        )
                    }

                    Button(action: {
                        isPriceChangeRealChange = false
                        showingPriceChangeConfirmation = false
                        updateSubscriptionWithoutPriceTracking()
                    }) {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "pencil.circle.fill")
                                    .font(.system(size: 20))
                                Text("No, I'm correcting an error")
                                    .font(.spotifyBodyLarge)
                                    .fontWeight(.semibold)
                                Spacer()
                            }
                            Text("This won't create a price history record")
                                .font(.spotifyCaptionMedium)
                                .foregroundColor(.wiseSecondaryText)
                        }
                        .foregroundColor(.wisePrimaryText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.wiseSecondaryText.opacity(0.3), lineWidth: 2)
                        )
                    }
                }

                // Optional reason field (for real changes)
                VStack(alignment: .leading, spacing: 8) {
                    Text("Reason (optional)")
                        .font(.spotifyLabelMedium)
                        .foregroundColor(.wiseSecondaryText)

                    TextField("e.g., Annual price increase", text: $priceChangeReason)
                        .font(.spotifyBodyMedium)
                        .foregroundColor(.wisePrimaryText)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.wiseBorder.opacity(0.5))
                        )
                }

                Spacer()
            }
            .padding(.horizontal, 20)
            .background(Color.wiseBackground)
            .navigationTitle("Confirm Price Change")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        showingPriceChangeConfirmation = false
                        priceChangeReason = ""
                    }
                    .font(.spotifyLabelMedium)
                    .foregroundColor(.wiseSecondaryText)
                }
            }
        }
    }

    private func updateSubscription() {
        guard let priceValue = Double(price) else { return }

        var updatedSubscription = subscription
        updatedSubscription.name = name.trimmingCharacters(in: .whitespaces)
        updatedSubscription.description = description.trimmingCharacters(in: .whitespaces)
        updatedSubscription.price = priceValue
        updatedSubscription.billingCycle = selectedBillingCycle
        updatedSubscription.category = selectedCategory
        updatedSubscription.icon = selectedIcon
        updatedSubscription.color = selectedColor
        updatedSubscription.isShared = isShared
        updatedSubscription.paymentMethod = selectedPaymentMethod
        updatedSubscription.website = website.trimmingCharacters(in: .whitespaces)
        updatedSubscription.notes = notes.trimmingCharacters(in: .whitespaces)

        // AGENT 8: Update trial fields with duration tracking
        updatedSubscription.isFreeTrial = isFreeTrial
        if isFreeTrial {
            updatedSubscription.trialStartDate = trialStartDate
            updatedSubscription.trialEndDate = trialEndDate
            updatedSubscription.trialDuration = calculateTrialDuration() // AGENT 8
            updatedSubscription.willConvertToPaid = willConvertToPaid
            if !priceAfterTrial.isEmpty, let afterTrialPrice = Double(priceAfterTrial) {
                updatedSubscription.priceAfterTrial = afterTrialPrice
            } else {
                updatedSubscription.priceAfterTrial = nil
            }
        } else {
            updatedSubscription.trialStartDate = nil
            updatedSubscription.trialEndDate = nil
            updatedSubscription.trialDuration = nil // AGENT 8
            updatedSubscription.willConvertToPaid = true
            updatedSubscription.priceAfterTrial = nil
        }

        // AGENT 7: Update reminder fields
        updatedSubscription.enableRenewalReminder = enableRenewalReminder
        updatedSubscription.reminderDaysBefore = reminderDaysBefore
        updatedSubscription.reminderTime = reminderTime

        do {
            try dataManager.updateSubscription(updatedSubscription)

            // AGENT 8: Schedule trial expiration reminders if applicable
            if isFreeTrial && willConvertToPaid {
                Task {
                    await NotificationManager.shared.scheduleTrialExpirationReminder(for: updatedSubscription)
                }
            }

            // AGENT 7: Update scheduled reminders
            Task {
                await NotificationManager.shared.updateScheduledReminders(for: updatedSubscription)
            }

            onSubscriptionUpdated()
            dismiss()
        } catch {
            dataManager.error = error
        }
    }

    // AGENT 9: Update subscription without tracking price change (for corrections)
    private func updateSubscriptionWithoutPriceTracking() {
        updateSubscription()
    }

    // AGENT 7: Send test reminder
    private func sendTestReminder() {
        Task {
            await NotificationManager.shared.sendTestNotification()
        }
    }
}

#Preview {
    EditSubscriptionSheet(
        subscription: Subscription(
            name: "Netflix",
            description: "Premium streaming",
            price: 17.99,
            billingCycle: .monthly,
            category: .entertainment,
            icon: "tv.fill",
            color: "#E50914"
        ),
        onSubscriptionUpdated: {}
    )
    .environmentObject(DataManager.shared)
}
