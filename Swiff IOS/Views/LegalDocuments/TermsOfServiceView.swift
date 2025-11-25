//
//  TermsOfServiceView.swift
//  Swiff IOS
//
//  Created by Naren Reddy on 11/20/25.
//  Terms of Service document view
//

import SwiftUI
import Combine

struct TermsOfServiceView: View {
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
                        title: "Agreement to Terms",
                        content: "By accessing and using Swiff ('the App'), you agree to be bound by these Terms of Service. If you do not agree to these terms, please do not use the App."
                    )

                    // Use of the App
                    SectionView(
                        title: "Use of the App",
                        content: """
                        Swiff is designed to help you:

                        • Track shared expenses with friends and groups
                        • Split bills and calculate balances
                        • Manage subscriptions and recurring payments
                        • Send payment reminders
                        • Export and backup your financial data

                        You agree to use the App only for lawful purposes and in accordance with these Terms.
                        """
                    )

                    // User Responsibilities
                    SectionView(
                        title: "User Responsibilities",
                        content: """
                        As a user of Swiff, you are responsible for:

                        • Providing accurate information when creating your profile
                        • Maintaining the confidentiality of your device and data
                        • Using the App in compliance with applicable laws
                        • Ensuring accuracy of expense records and transactions
                        • Respecting the privacy of other users
                        • Creating regular backups of your important data
                        """
                    )

                    // Financial Calculations
                    SectionView(
                        title: "Financial Calculations",
                        content: """
                        Important disclaimers about financial information:

                        • Swiff provides tools for tracking and calculating expenses
                        • All calculations are performed locally on your device
                        • You are responsible for verifying the accuracy of all entries
                        • The App does not process actual payments or transfers
                        • We are not liable for any errors in calculations or data entry
                        • Always verify important financial information independently
                        """
                    )

                    // Data Backup
                    SectionView(
                        title: "Data and Backups",
                        content: """
                        Please note:

                        • All data is stored locally on your device
                        • You are responsible for creating backups of your data
                        • We recommend regular backups using the export feature
                        • Uninstalling the app will delete all local data
                        • We are not responsible for data loss due to device failure, deletion, or other causes
                        """
                    )

                    // Intellectual Property
                    SectionView(
                        title: "Intellectual Property",
                        content: "The App, including its design, functionality, and content, is owned by Swiff and protected by copyright and other intellectual property laws. You may not copy, modify, distribute, or reverse engineer any part of the App without our express written permission."
                    )

                    // Prohibited Activities
                    SectionView(
                        title: "Prohibited Activities",
                        content: """
                        You may not use the App to:

                        • Engage in illegal activities or fraud
                        • Harass or harm other users
                        • Attempt to gain unauthorized access to the App
                        • Distribute malware or harmful code
                        • Violate any applicable laws or regulations
                        • Use the App for commercial purposes without authorization
                        """
                    )

                    // Disclaimer of Warranties
                    SectionView(
                        title: "Disclaimer of Warranties",
                        content: "THE APP IS PROVIDED 'AS IS' WITHOUT WARRANTIES OF ANY KIND, EXPRESS OR IMPLIED. WE DO NOT WARRANT THAT THE APP WILL BE ERROR-FREE, SECURE, OR UNINTERRUPTED. YOUR USE OF THE APP IS AT YOUR OWN RISK."
                    )

                    // Limitation of Liability
                    SectionView(
                        title: "Limitation of Liability",
                        content: "TO THE MAXIMUM EXTENT PERMITTED BY LAW, WE SHALL NOT BE LIABLE FOR ANY INDIRECT, INCIDENTAL, SPECIAL, CONSEQUENTIAL, OR PUNITIVE DAMAGES, INCLUDING LOSS OF DATA, LOSS OF PROFITS, OR OTHER FINANCIAL LOSSES ARISING FROM YOUR USE OF THE APP."
                    )

                    // Changes to Terms
                    SectionView(
                        title: "Changes to Terms",
                        content: "We reserve the right to modify these Terms of Service at any time. We will notify you of any changes by updating the 'Last Updated' date. Continued use of the App after changes constitutes acceptance of the updated terms."
                    )

                    // Termination
                    SectionView(
                        title: "Termination",
                        content: "We may terminate or suspend your access to the App at any time, without prior notice, for conduct that we believe violates these Terms or is harmful to other users, us, or third parties."
                    )

                    // Governing Law
                    SectionView(
                        title: "Governing Law",
                        content: "These Terms shall be governed by and construed in accordance with the laws of the jurisdiction in which the App is operated, without regard to its conflict of law provisions."
                    )

                    // Contact Information
                    SectionView(
                        title: "Contact Us",
                        content: "If you have any questions about these Terms of Service, please contact us through the app's support channel or at support@swiffapp.com."
                    )

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 20)
            }
            .background(Color.wiseBackground)
            .navigationTitle("Terms of Service")
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

#Preview {
    TermsOfServiceView()
}
