//
//  SendReminderSheet.swift
//  Swiff IOS
//
//  Created by Naren Reddy on 11/20/25.
//  Send payment reminder to a person
//

import SwiftUI
import MessageUI
import Combine

struct SendReminderSheet: View {
    @Environment(\.dismiss) var dismiss

    let person: Person
    let onReminderSent: () -> Void

    @State private var reminderMethod: ReminderMethod = .message
    @State private var customMessage = ""
    @State private var showingMessageComposer = false
    @State private var showingMailComposer = false
    @State private var showingCantSendAlert = false

    enum ReminderMethod: String, CaseIterable {
        case message = "Message"
        case email = "Email"
        case whatsapp = "WhatsApp"
        case copy = "Copy Link"

        var icon: String {
            switch self {
            case .message: return "message.fill"
            case .email: return "envelope.fill"
            case .whatsapp: return "phone.bubble.left.fill"
            case .copy: return "doc.on.doc.fill"
            }
        }

        var color: Color {
            switch self {
            case .message: return .wiseBlue
            case .email: return .wiseForestGreen
            case .whatsapp: return .green
            case .copy: return .wiseSecondaryText
            }
        }
    }

    var balanceText: String {
        let amountStr = abs(person.balance).asCurrency
        return person.balance > 0 ? "Owes you \(amountStr)" : "You owe \(amountStr)"
    }

    var defaultMessage: String {
        let amountStr = abs(person.balance).asCurrency

        if person.balance > 0 {
            return "Hi \(person.name)! Just a friendly reminder about your outstanding balance of \(amountStr). Let me know when you'd like to settle up. Thanks!"
        } else if person.balance < 0 {
            return "Hi \(person.name)! I owe you \(amountStr). Would you like me to settle up soon?"
        } else {
            return "Hi \(person.name)! Just checking in about our expenses. Let me know if you need anything."
        }
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Person Info
                    VStack(spacing: 12) {
                        AvatarView(avatarType: person.avatarType, size: .large, style: .solid)

                        Text(person.name)
                            .font(.spotifyHeadingMedium)
                            .foregroundColor(.wisePrimaryText)

                        if person.balance != 0 {
                            Text(balanceText)
                                .font(.spotifyBodyMedium)
                                .foregroundColor(person.balance > 0 ? .wiseBrightGreen : .wiseError)
                        }
                    }
                    .padding(.top, 20)

                    // Reminder Method Selection
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Send via")
                            .font(.spotifyHeadingMedium)
                            .foregroundColor(.wisePrimaryText)

                        ForEach(ReminderMethod.allCases, id: \.self) { method in
                            Button(action: { reminderMethod = method }) {
                                HStack(spacing: 12) {
                                    Image(systemName: method.icon)
                                        .font(.system(size: 20))
                                        .foregroundColor(reminderMethod == method ? .white : method.color)
                                        .frame(width: 40, height: 40)
                                        .background(
                                            Circle()
                                                .fill(reminderMethod == method ? method.color : method.color.opacity(0.1))
                                        )

                                    Text(method.rawValue)
                                        .font(.spotifyBodyMedium)
                                        .foregroundColor(.wisePrimaryText)

                                    Spacer()

                                    if reminderMethod == method {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.wiseForestGreen)
                                    }
                                }
                                .padding(12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(reminderMethod == method ? Color.wiseBorder.opacity(0.3) : Color.clear)
                                )
                            }
                        }
                    }

                    // Message Preview
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Message Preview")
                            .font(.spotifyHeadingMedium)
                            .foregroundColor(.wisePrimaryText)

                        TextEditor(text: $customMessage)
                            .font(.spotifyBodyMedium)
                            .foregroundColor(.wisePrimaryText)
                            .frame(height: 120)
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.wiseBorder.opacity(0.3))
                                    .stroke(Color.wiseBorder, lineWidth: 1)
                            )

                        Button(action: { customMessage = defaultMessage }) {
                            Text("Use Default Message")
                                .font(.spotifyLabelMedium)
                                .foregroundColor(.wiseBlue)
                        }
                    }

                    // Send Button
                    Button(action: sendReminder) {
                        HStack {
                            Spacer()
                            Image(systemName: reminderMethod.icon)
                                .font(.system(size: 16))
                            Text("Send Reminder")
                                .font(.spotifyBodyLarge)
                                .fontWeight(.semibold)
                            Spacer()
                        }
                        .foregroundColor(.white)
                        .padding(.vertical, 16)
                        .background(Color.wiseForestGreen)
                        .cornerRadius(12)
                    }
                    .padding(.top, 8)

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 20)
            }
            .navigationTitle("Send Reminder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.wiseSecondaryText)
                }
            }
        }
        .onAppear {
            customMessage = defaultMessage
        }
        .alert("Cannot Send", isPresented: $showingCantSendAlert) {
            Button("OK") {}
        } message: {
            Text("This device is not configured to send messages or emails.")
        }
    }

    private func sendReminder() {
        switch reminderMethod {
        case .message:
            sendMessage()
        case .email:
            sendEmail()
        case .whatsapp:
            sendWhatsApp()
        case .copy:
            copyToClipboard()
        }
    }

    private func sendMessage() {
        guard !person.phone.isEmpty else {
            showingCantSendAlert = true
            return
        }

        // Open Messages app with pre-filled message
        let phoneNumber = person.phone.filter { $0.isNumber }
        let encodedMessage = customMessage.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""

        if let url = URL(string: "sms:\(phoneNumber)&body=\(encodedMessage)") {
            UIApplication.shared.open(url) { success in
                if success {
                    onReminderSent()
                    dismiss()
                } else {
                    showingCantSendAlert = true
                }
            }
        } else {
            showingCantSendAlert = true
        }
    }

    private func sendEmail() {
        guard !person.email.isEmpty else {
            showingCantSendAlert = true
            return
        }

        // Open Mail app with pre-filled email
        let subject = "Payment Reminder"
        let encodedSubject = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let encodedBody = customMessage.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""

        if let url = URL(string: "mailto:\(person.email)?subject=\(encodedSubject)&body=\(encodedBody)") {
            UIApplication.shared.open(url) { success in
                if success {
                    onReminderSent()
                    dismiss()
                } else {
                    showingCantSendAlert = true
                }
            }
        } else {
            showingCantSendAlert = true
        }
    }

    private func sendWhatsApp() {
        guard !person.phone.isEmpty else {
            showingCantSendAlert = true
            return
        }

        // Format phone number (remove non-numeric characters except +)
        let phoneNumber = person.phone.replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "-", with: "").replacingOccurrences(of: "(", with: "").replacingOccurrences(of: ")", with: "")
        let encodedMessage = customMessage.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""

        // WhatsApp URL scheme
        if let url = URL(string: "whatsapp://send?phone=\(phoneNumber)&text=\(encodedMessage)") {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url) { success in
                    if success {
                        onReminderSent()
                        dismiss()
                    } else {
                        showingCantSendAlert = true
                    }
                }
            } else {
                // WhatsApp not installed, fall back to web version
                if let webURL = URL(string: "https://wa.me/\(phoneNumber)?text=\(encodedMessage)") {
                    UIApplication.shared.open(webURL) { success in
                        if success {
                            onReminderSent()
                            dismiss()
                        } else {
                            showingCantSendAlert = true
                        }
                    }
                } else {
                    showingCantSendAlert = true
                }
            }
        } else {
            showingCantSendAlert = true
        }
    }

    private func copyToClipboard() {
        UIPasteboard.general.string = customMessage
        onReminderSent()
        dismiss()
    }
}

