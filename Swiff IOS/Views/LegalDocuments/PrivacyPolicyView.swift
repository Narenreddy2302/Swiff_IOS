//
//  PrivacyPolicyView.swift
//  Swiff IOS
//
//  Created by Naren Reddy on 11/20/25.
//  Privacy Policy document view
//

import SwiftUI
import Combine

struct PrivacyPolicyView: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Last Updated
                    Text("Last Updated: November 20, 2025")
                        .font(.spotifyCaptionMedium)
                        .foregroundColor(.wiseSecondaryText)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 8)

                    // Introduction
                    SectionView(
                        title: "Introduction",
                        content: "Welcome to Swiff. We respect your privacy and are committed to protecting your personal data. This privacy policy explains how we handle your information when you use our expense tracking and bill splitting application."
                    )

                    // Information We Collect
                    SectionView(
                        title: "Information We Collect",
                        content: """
                        Swiff collects and stores the following information locally on your device:

                        • Personal profile information (name, email, phone number)
                        • Contact information for people you share expenses with
                        • Group details and memberships
                        • Transaction records and expense history
                        • Subscription details and payment reminders
                        • App preferences and settings

                        All data is stored locally on your device and is not transmitted to our servers unless you explicitly use backup or export features.
                        """
                    )

                    // How We Use Your Information
                    SectionView(
                        title: "How We Use Your Information",
                        content: """
                        We use the information you provide to:

                        • Track and manage your shared expenses
                        • Calculate balances between you and your contacts
                        • Send payment reminders and notifications
                        • Manage subscription renewals
                        • Create backups and exports of your data
                        • Improve app functionality and user experience
                        """
                    )

                    // Data Storage and Security
                    SectionView(
                        title: "Data Storage and Security",
                        content: """
                        Your data security is our priority:

                        • All data is stored locally on your device using iOS secure storage
                        • We use industry-standard encryption for data protection
                        • Backups are stored in your device's secure file system
                        • We do not transmit your data to external servers
                        • You have full control over your data exports and backups
                        """
                    )

                    // Third-Party Services
                    SectionView(
                        title: "Third-Party Services",
                        content: """
                        Swiff may use the following device features:

                        • Contacts (only when you explicitly choose to import)
                        • Camera and Photo Library (for profile pictures and receipts)
                        • Notifications (for payment and subscription reminders)
                        • Messages and Email (for sending payment reminders)

                        We do not share your data with third-party services without your explicit consent.
                        """
                    )

                    // Your Rights
                    SectionView(
                        title: "Your Rights",
                        content: """
                        You have the right to:

                        • Access all your data within the app
                        • Export your data in JSON format
                        • Delete all your data at any time
                        • Control notification preferences
                        • Manage app permissions through iOS settings
                        """
                    )

                    // Data Retention
                    SectionView(
                        title: "Data Retention",
                        content: "Your data is retained on your device until you choose to delete it. You can clear all data at any time through the app's settings. Uninstalling the app will also remove all locally stored data."
                    )

                    // Changes to Privacy Policy
                    SectionView(
                        title: "Changes to This Policy",
                        content: "We may update this privacy policy from time to time. We will notify you of any changes by updating the 'Last Updated' date at the top of this policy. Continued use of the app after changes constitutes acceptance of the updated policy."
                    )

                    // Contact Information
                    SectionView(
                        title: "Contact Us",
                        content: "If you have any questions about this privacy policy or how we handle your data, please contact us through the app's support channel or at support@swiffapp.com."
                    )

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 20)
            }
            .background(Color.wiseBackground)
            .navigationTitle("Privacy Policy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.wiseForestGreen)
                }
            }
        }
    }
}

// MARK: - Section View Component

struct SectionView: View {
    let title: String
    let content: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.spotifyHeadingMedium)
                .foregroundColor(.wisePrimaryText)

            Text(content)
                .font(.spotifyBodyMedium)
                .foregroundColor(.wiseSecondaryText)
                .lineSpacing(4)
        }
    }
}

#Preview {
    PrivacyPolicyView()
}
