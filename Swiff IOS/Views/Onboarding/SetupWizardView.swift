//
//  SetupWizardView.swift
//  Swiff IOS
//
//  Created by Agent 11 on 11/21/25.
//  Quick setup wizard for onboarding
//

import SwiftUI
import UserNotifications
import Combine

struct SetupWizardView: View {
    @Binding var currentStep: Int
    let onComplete: () -> Void
    let onSkip: () -> Void

    @State private var selectedCurrency: String = "$"
    @State private var notificationsEnabled: Bool = false
    @State private var importOption: ImportOption = .startFresh
    @State private var showingImportPicker: Bool = false

    @Environment(\.colorScheme) var colorScheme

    enum ImportOption: String, CaseIterable {
        case startFresh = "Start Fresh"
        case sampleData = "Sample Data"
        case importCSV = "Import CSV"
        case importBackup = "Import Backup"

        var icon: String {
            switch self {
            case .startFresh: return "sparkles"
            case .sampleData: return "doc.text"
            case .importCSV: return "doc.badge.arrow.up"
            case .importBackup: return "arrow.counterclockwise.circle"
            }
        }

        var description: String {
            switch self {
            case .startFresh: return "Start with a clean slate"
            case .sampleData: return "Explore with pre-filled data"
            case .importCSV: return "Import from CSV file"
            case .importBackup: return "Restore from backup"
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 8) {
                HStack {
                    Button(action: {
                        HapticManager.shared.light()
                        onSkip()
                    }) {
                        Text("Skip")
                            .font(.subheadline)
                            .foregroundColor(.wiseSecondaryText)
                    }
                    .accessibilityLabel("Skip setup")

                    Spacer()

                    Text("Step \(currentStep + 1) of 3")
                        .font(.caption)
                        .foregroundColor(.wiseSecondaryText)
                }
                .padding(.horizontal, 32)
                .padding(.top, 20)

                // Progress Bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color.wiseBorder.opacity(0.3))
                            .frame(height: 4)

                        Rectangle()
                            .fill(Color.wiseForestGreen)
                            .frame(width: geometry.size.width * CGFloat(currentStep + 1) / 3, height: 4)
                            .animation(.smooth, value: currentStep)
                    }
                }
                .frame(height: 4)
                .padding(.horizontal, 32)
                .padding(.top, 12)
            }

            // Content
            TabView(selection: $currentStep) {
                // Step 1: Currency
                currencyStep
                    .tag(0)

                // Step 2: Notifications
                notificationsStep
                    .tag(1)

                // Step 3: Import Data
                importStep
                    .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.smooth, value: currentStep)

            // Navigation Buttons
            HStack(spacing: 16) {
                if currentStep > 0 {
                    Button(action: {
                        HapticManager.shared.light()
                        withAnimation(.smooth) {
                            currentStep -= 1
                        }
                    }) {
                        Text("Back")
                            .font(.headline)
                            .foregroundColor(.wiseForestGreen)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.wiseForestGreen.opacity(0.1))
                            .cornerRadius(16)
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .accessibilityLabel("Go back")
                }

                Button(action: {
                    HapticManager.shared.medium()
                    if currentStep < 2 {
                        withAnimation(.smooth) {
                            currentStep += 1
                        }
                    } else {
                        completeSetup()
                    }
                }) {
                    Text(currentStep < 2 ? "Continue" : "Get Started")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.wiseForestGreen)
                        .cornerRadius(16)
                }
                .buttonStyle(ScaleButtonStyle())
                .accessibilityLabel(currentStep < 2 ? "Continue to next step" : "Complete setup")
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 40)
        }
        .background(Color.wiseBackground)
    }

    // MARK: - Currency Step

    private var currencyStep: some View {
        VStack(spacing: 32) {
            VStack(spacing: 12) {
                Image(systemName: "dollarsign.circle.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 80, height: 80)
                    .foregroundColor(.wiseForestGreen)

                Text("Choose Your Currency")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Select your preferred currency for tracking expenses")
                    .font(.subheadline)
                    .foregroundColor(.wiseSecondaryText)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 40)

            VStack(spacing: 12) {
                ForEach(CurrencyCode.allCases, id: \.self) { currency in
                    Button(action: {
                        HapticManager.shared.selection()
                        selectedCurrency = currency.symbol
                        UserSettings.shared.selectedCurrency = currency.symbol
                    }) {
                        HStack {
                            Text(currency.symbol)
                                .font(.title2)
                                .frame(width: 40)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(currency.name)
                                    .font(.headline)
                                Text(currency.code)
                                    .font(.caption)
                                    .foregroundColor(.wiseSecondaryText)
                            }

                            Spacer()

                            if selectedCurrency == currency.symbol {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.wiseForestGreen)
                                    .imageScale(.large)
                            }
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(selectedCurrency == currency.symbol
                                      ? Color.wiseForestGreen.opacity(0.1)
                                      : Color(UIColor.systemGray6))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(selectedCurrency == currency.symbol
                                        ? Color.wiseForestGreen
                                        : Color.clear, lineWidth: 2)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .accessibilityLabel("\(currency.name), \(currency.code)")
                    .accessibilityAddTraits(selectedCurrency == currency.symbol ? [.isSelected] : [])
                }
            }
            .padding(.horizontal, 32)

            Spacer()
        }
    }

    // MARK: - Notifications Step

    private var notificationsStep: some View {
        VStack(spacing: 32) {
            VStack(spacing: 12) {
                Image(systemName: "bell.badge.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 80, height: 80)
                    .foregroundColor(.wiseBrightGreen)

                Text("Enable Notifications")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Get reminders before your subscriptions renew")
                    .font(.subheadline)
                    .foregroundColor(.wiseSecondaryText)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 40)

            VStack(spacing: 20) {
                FeatureBullet(icon: "calendar.badge.clock", text: "Renewal reminders")
                FeatureBullet(icon: "dollarsign.circle", text: "Payment due alerts")
                FeatureBullet(icon: "chart.line.uptrend.xyaxis", text: "Spending insights")
                FeatureBullet(icon: "bell.slash", text: "Easy to customize or disable")
            }
            .padding(.horizontal, 32)

            Button(action: {
                requestNotificationPermission()
            }) {
                HStack {
                    Image(systemName: notificationsEnabled ? "checkmark.circle.fill" : "bell.fill")
                    Text(notificationsEnabled ? "Notifications Enabled" : "Enable Notifications")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(notificationsEnabled ? Color.wiseSuccess : Color.wiseBrightGreen)
                .cornerRadius(16)
            }
            .buttonStyle(ScaleButtonStyle())
            .padding(.horizontal, 32)
            .disabled(notificationsEnabled)
            .accessibilityLabel(notificationsEnabled ? "Notifications are enabled" : "Enable notifications")

            Spacer()
        }
    }

    // MARK: - Import Step

    private var importStep: some View {
        VStack(spacing: 32) {
            VStack(spacing: 12) {
                Image(systemName: "tray.and.arrow.down.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 80, height: 80)
                    .foregroundColor(.wiseBlue)

                Text("Import Data")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Choose how you'd like to start")
                    .font(.subheadline)
                    .foregroundColor(.wiseSecondaryText)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 40)

            VStack(spacing: 12) {
                ForEach(ImportOption.allCases, id: \.self) { option in
                    Button(action: {
                        HapticManager.shared.selection()
                        importOption = option
                    }) {
                        HStack {
                            Image(systemName: option.icon)
                                .font(.title2)
                                .foregroundColor(.wiseForestGreen)
                                .frame(width: 40)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(option.rawValue)
                                    .font(.headline)
                                Text(option.description)
                                    .font(.caption)
                                    .foregroundColor(.wiseSecondaryText)
                            }

                            Spacer()

                            if importOption == option {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.wiseForestGreen)
                                    .imageScale(.large)
                            }
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(importOption == option
                                      ? Color.wiseForestGreen.opacity(0.1)
                                      : Color(UIColor.systemGray6))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(importOption == option
                                        ? Color.wiseForestGreen
                                        : Color.clear, lineWidth: 2)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .accessibilityLabel("\(option.rawValue). \(option.description)")
                    .accessibilityAddTraits(importOption == option ? [.isSelected] : [])
                }
            }
            .padding(.horizontal, 32)

            Spacer()
        }
    }

    // MARK: - Helper Views

    struct FeatureBullet: View {
        let icon: String
        let text: String

        var body: some View {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .foregroundColor(.wiseBrightGreen)
                    .frame(width: 24)

                Text(text)
                    .font(.body)
                    .foregroundColor(.wisePrimaryText)

                Spacer()
            }
        }
    }

    // MARK: - Helper Methods

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                if granted {
                    HapticManager.shared.success()
                    notificationsEnabled = true
                    UserSettings.shared.notificationsEnabled = true
                } else {
                    HapticManager.shared.error()
                }
            }
        }
    }

    private func completeSetup() {
        // Save setup preferences
        UserSettings.shared.selectedCurrency = selectedCurrency
        UserSettings.shared.notificationsEnabled = notificationsEnabled

        // Handle import option
        switch importOption {
        case .sampleData:
            SampleDataGenerator.shared.generateSampleData()
            UserSettings.shared.hasSampleData = true
        case .startFresh, .importCSV, .importBackup:
            break // Handle later
        }

        onComplete()
    }
}

// MARK: - Currency Code Enum

enum CurrencyCode: String, CaseIterable {
    case usd = "US Dollar"
    case eur = "Euro"
    case gbp = "British Pound"
    case jpy = "Japanese Yen"
    case cad = "Canadian Dollar"
    case aud = "Australian Dollar"
    case inr = "Indian Rupee"

    var symbol: String {
        switch self {
        case .usd, .cad, .aud: return "$"
        case .eur: return "€"
        case .gbp: return "£"
        case .jpy: return "¥"
        case .inr: return "₹"
        }
    }

    var code: String {
        switch self {
        case .usd: return "USD"
        case .eur: return "EUR"
        case .gbp: return "GBP"
        case .jpy: return "JPY"
        case .cad: return "CAD"
        case .aud: return "AUD"
        case .inr: return "INR"
        }
    }

    var name: String {
        rawValue
    }
}

#Preview {
    SetupWizardView(
        currentStep: .constant(0),
        onComplete: {},
        onSkip: {}
    )
}
