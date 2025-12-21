//
//  HelpSupportPage.swift
//  Swiff IOS
//
//  Help and support settings page
//

import SwiftUI
import StoreKit

struct HelpSupportPage: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.requestReview) private var requestReview

    @State private var showContactSheet = false
    @State private var showBugReportSheet = false

    // App version
    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "Version \(version) (\(build))"
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // FAQ Section
                faqSection

                // Contact Section
                contactSection

                // App Info Section
                appInfoSection
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 20)
        }
        .background(Color.wiseGroupedBackground)
        .navigationTitle("Help & Support")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showContactSheet) {
            ContactSupportSheet()
        }
        .sheet(isPresented: $showBugReportSheet) {
            BugReportSheet()
        }
    }

    // MARK: - FAQ Section

    private var faqSection: some View {
        VStack(spacing: 0) {
            SettingsSectionHeader(title: "FREQUENTLY ASKED QUESTIONS")

            VStack(spacing: 0) {
                ExpandableFAQRow(
                    question: "How do I add a transaction?",
                    answer: "Tap the + button on the home screen, then select 'Add Transaction'. Fill in the details and save.",
                    showDivider: true
                )

                ExpandableFAQRow(
                    question: "How do I track subscriptions?",
                    answer: "Go to the Subscriptions tab and tap + to add a new subscription. Swiff will remind you before renewals.",
                    showDivider: true
                )

                ExpandableFAQRow(
                    question: "Can I export my data?",
                    answer: "Yes! Go to Profile > Settings > Data Management to export your data as JSON or CSV.",
                    showDivider: true
                )

                ExpandableFAQRow(
                    question: "How do I split bills?",
                    answer: "Use the Split Bill feature to divide expenses among friends. You can split equally or by custom amounts.",
                    showDivider: true
                )

                ExpandableFAQRow(
                    question: "Is my data secure?",
                    answer: "Your data is stored locally on your device. Enable biometric lock in Privacy & Security for extra protection.",
                    showDivider: false
                )
            }
            .background(Color.wiseCardBackground)
            .cornerRadius(12)
        }
    }

    // MARK: - Contact Section

    private var contactSection: some View {
        VStack(spacing: 0) {
            SettingsSectionHeader(title: "GET IN TOUCH")

            VStack(spacing: 0) {
                // Contact Support
                SupportRow(
                    icon: "envelope.fill",
                    iconColor: .wiseBlue,
                    title: "Contact Support",
                    subtitle: "Get help from our team",
                    showDivider: true
                ) {
                    showContactSheet = true
                }

                // Report a Bug
                SupportRow(
                    icon: "ladybug.fill",
                    iconColor: .wiseOrange,
                    title: "Report a Bug",
                    subtitle: "Help us improve Swiff",
                    showDivider: true
                ) {
                    showBugReportSheet = true
                }

                // Rate the App
                SupportRow(
                    icon: "star.fill",
                    iconColor: .wiseWarning,
                    title: "Rate Swiff",
                    subtitle: "Share your feedback",
                    showDivider: true
                ) {
                    requestReview()
                }

                // Share App
                SupportRow(
                    icon: "square.and.arrow.up.fill",
                    iconColor: .wiseBrightGreen,
                    title: "Share Swiff",
                    subtitle: "Tell your friends",
                    showDivider: false
                ) {
                    shareApp()
                }
            }
            .background(Color.wiseCardBackground)
            .cornerRadius(12)
        }
    }

    // MARK: - App Info Section

    private var appInfoSection: some View {
        VStack(spacing: 0) {
            SettingsSectionHeader(title: "ABOUT")

            VStack(spacing: 0) {
                // Version
                HStack {
                    Text("Version")
                        .font(.spotifyBodyLarge)
                        .foregroundColor(.wisePrimaryText)

                    Spacer()

                    Text(appVersion)
                        .font(.spotifyBodyMedium)
                        .foregroundColor(.wiseSecondaryText)
                }
                .padding(16)

                Divider().padding(.leading, 16)

                // Privacy Policy
                NavigationLink(destination: PrivacyPolicyView()) {
                    HStack {
                        Text("Privacy Policy")
                            .font(.spotifyBodyLarge)
                            .foregroundColor(.wisePrimaryText)

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.wiseSecondaryText.opacity(0.5))
                    }
                    .padding(16)
                }
                .buttonStyle(PlainButtonStyle())

                Divider().padding(.leading, 16)

                // Terms of Service
                NavigationLink(destination: TermsOfServiceView()) {
                    HStack {
                        Text("Terms of Service")
                            .font(.spotifyBodyLarge)
                            .foregroundColor(.wisePrimaryText)

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.wiseSecondaryText.opacity(0.5))
                    }
                    .padding(16)
                }
                .buttonStyle(PlainButtonStyle())

                Divider().padding(.leading, 16)

                // Acknowledgments
                NavigationLink(destination: AcknowledgmentsView()) {
                    HStack {
                        Text("Acknowledgments")
                            .font(.spotifyBodyLarge)
                            .foregroundColor(.wisePrimaryText)

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.wiseSecondaryText.opacity(0.5))
                    }
                    .padding(16)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .background(Color.wiseCardBackground)
            .cornerRadius(12)
        }
    }

    // MARK: - Helper Functions

    private func shareApp() {
        let text = "Check out Swiff - the best way to track your finances!"
        let activityVC = UIActivityViewController(activityItems: [text], applicationActivities: nil)

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
}

// MARK: - Supporting Views

struct ExpandableFAQRow: View {
    let question: String
    let answer: String
    let showDivider: Bool

    @State private var isExpanded = false

    var body: some View {
        VStack(spacing: 0) {
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isExpanded.toggle()
                }
                HapticManager.shared.impact(.light)
            }) {
                HStack {
                    Text(question)
                        .font(.spotifyBodyLarge)
                        .foregroundColor(.wisePrimaryText)
                        .multilineTextAlignment(.leading)

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.wiseSecondaryText.opacity(0.5))
                }
                .padding(16)
            }
            .buttonStyle(PlainButtonStyle())

            if isExpanded {
                Text(answer)
                    .font(.spotifyBodyMedium)
                    .foregroundColor(.wiseSecondaryText)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }

            if showDivider {
                Divider().padding(.leading, 16)
            }
        }
    }
}

struct SupportRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let showDivider: Bool
    let action: () -> Void

    var body: some View {
        Button(action: {
            HapticManager.shared.impact(.light)
            action()
        }) {
            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    Circle()
                        .fill(iconColor.opacity(0.2))
                        .frame(width: 40, height: 40)
                        .overlay(
                            Image(systemName: icon)
                                .font(.system(size: 16))
                                .foregroundColor(iconColor)
                        )

                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(.spotifyBodyLarge)
                            .foregroundColor(.wisePrimaryText)
                        Text(subtitle)
                            .font(.spotifyBodySmall)
                            .foregroundColor(.wiseSecondaryText)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.wiseSecondaryText.opacity(0.5))
                }
                .padding(16)

                if showDivider {
                    Divider().padding(.leading, 68)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Contact Support Sheet

struct ContactSupportSheet: View {
    @Environment(\.dismiss) private var dismiss

    @State private var subject = ""
    @State private var message = ""

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Subject")
                        .font(.spotifyLabelSmall)
                        .foregroundColor(.wiseSecondaryText)

                    TextField("What do you need help with?", text: $subject)
                        .font(.spotifyBodyLarge)
                        .padding(16)
                        .background(Color.wiseCardBackground)
                        .cornerRadius(12)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Message")
                        .font(.spotifyLabelSmall)
                        .foregroundColor(.wiseSecondaryText)

                    TextEditor(text: $message)
                        .font(.spotifyBodyLarge)
                        .frame(minHeight: 150)
                        .padding(12)
                        .background(Color.wiseCardBackground)
                        .cornerRadius(12)
                }

                Spacer()

                Button(action: {
                    HapticManager.shared.notification(.success)
                    ToastManager.shared.showSuccess("Message sent successfully")
                    dismiss()
                }) {
                    Text("Send Message")
                        .font(.spotifyBodyLarge)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(subject.isEmpty || message.isEmpty ? Color.wiseBorder : Color.wiseForestGreen)
                        .cornerRadius(12)
                }
                .disabled(subject.isEmpty || message.isEmpty)
            }
            .padding(20)
            .background(Color.wiseGroupedBackground)
            .navigationTitle("Contact Support")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.wiseSecondaryText)
                }
            }
        }
    }
}

// MARK: - Bug Report Sheet

struct BugReportSheet: View {
    @Environment(\.dismiss) private var dismiss

    @State private var bugType = "UI Issue"
    @State private var description = ""

    let bugTypes = ["UI Issue", "Crash", "Data Issue", "Performance", "Other"]

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Bug Type")
                        .font(.spotifyLabelSmall)
                        .foregroundColor(.wiseSecondaryText)

                    Picker("Bug Type", selection: $bugType) {
                        ForEach(bugTypes, id: \.self) { type in
                            Text(type).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Description")
                        .font(.spotifyLabelSmall)
                        .foregroundColor(.wiseSecondaryText)

                    TextEditor(text: $description)
                        .font(.spotifyBodyLarge)
                        .frame(minHeight: 150)
                        .padding(12)
                        .background(Color.wiseCardBackground)
                        .cornerRadius(12)

                    Text("Please describe the issue in detail, including steps to reproduce if possible.")
                        .font(.spotifyCaptionSmall)
                        .foregroundColor(.wiseSecondaryText)
                }

                Spacer()

                Button(action: {
                    HapticManager.shared.notification(.success)
                    ToastManager.shared.showSuccess("Bug report submitted")
                    dismiss()
                }) {
                    Text("Submit Report")
                        .font(.spotifyBodyLarge)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(description.isEmpty ? Color.wiseBorder : Color.wiseForestGreen)
                        .cornerRadius(12)
                }
                .disabled(description.isEmpty)
            }
            .padding(20)
            .background(Color.wiseGroupedBackground)
            .navigationTitle("Report a Bug")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.wiseSecondaryText)
                }
            }
        }
    }
}

// MARK: - Acknowledgments View

struct AcknowledgmentsView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Swiff uses the following open source libraries and resources:")
                    .font(.spotifyBodyMedium)
                    .foregroundColor(.wiseSecondaryText)

                VStack(alignment: .leading, spacing: 16) {
                    AcknowledgmentItem(
                        name: "SwiftUI",
                        description: "Apple's declarative UI framework"
                    )

                    AcknowledgmentItem(
                        name: "SwiftData",
                        description: "Apple's data persistence framework"
                    )

                    AcknowledgmentItem(
                        name: "SF Symbols",
                        description: "Apple's iconography system"
                    )
                }
                .padding(16)
                .background(Color.wiseCardBackground)
                .cornerRadius(12)

                Text("Made with love in San Francisco")
                    .font(.spotifyBodySmall)
                    .foregroundColor(.wiseSecondaryText)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 20)
            }
            .padding(20)
        }
        .background(Color.wiseGroupedBackground)
        .navigationTitle("Acknowledgments")
        .navigationBarTitleDisplayMode(.large)
    }
}

struct AcknowledgmentItem: View {
    let name: String
    let description: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(name)
                .font(.spotifyBodyLarge)
                .foregroundColor(.wisePrimaryText)

            Text(description)
                .font(.spotifyBodySmall)
                .foregroundColor(.wiseSecondaryText)
        }
    }
}

#Preview("Help Support Page") {
    NavigationView {
        HelpSupportPage()
    }
}
