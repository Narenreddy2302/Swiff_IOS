//
//  ContactActionBar.swift
//  Swiff IOS
//
//  Created by Claude Code on 1/8/26.
//  Bottom action bar for contact conversation view
//

import SwiftUI

struct ContactActionBar: View {
    let contact: ContactEntry
    let onTheyOweMe: () -> Void
    let onIOwe: () -> Void
    let onSplitBill: () -> Void
    let onInvite: (() -> Void)?

    var body: some View {
        VStack(spacing: 0) {
            Divider()

            VStack(spacing: 12) {
                // Primary actions row (Due creation)
                HStack(spacing: 12) {
                    // "They owe me" button
                    Button(action: {
                        HapticManager.shared.light()
                        onTheyOweMe()
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.down.circle.fill")
                                .font(.system(size: 16))
                            Text("They owe me")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundColor(AmountColors.positive)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(AmountColors.positive.opacity(0.12))
                                .stroke(AmountColors.positive.opacity(0.3), lineWidth: 1)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())

                    // "I owe them" button
                    Button(action: {
                        HapticManager.shared.light()
                        onIOwe()
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.system(size: 16))
                            Text("I owe them")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundColor(.wiseError)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.wiseError.opacity(0.12))
                                .stroke(Color.wiseError.opacity(0.3), lineWidth: 1)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }

                // Secondary actions row
                HStack(spacing: 12) {
                    // "Split a bill" button
                    Button(action: {
                        HapticManager.shared.light()
                        onSplitBill()
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "divide.circle.fill")
                                .font(.system(size: 16))
                            Text("Split a bill")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .foregroundColor(.wiseBlue)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.wiseBlue.opacity(0.12))
                                .stroke(Color.wiseBlue.opacity(0.3), lineWidth: 1)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())

                    // "Invite" button (only if contact doesn't have app account)
                    if !contact.hasAppAccount, let onInvite = onInvite {
                        Button(action: {
                            HapticManager.shared.light()
                            onInvite()
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "paperplane.fill")
                                    .font(.system(size: 16))
                                Text("Invite")
                                    .font(.system(size: 14, weight: .medium))
                            }
                            .foregroundColor(.wiseBrightGreen)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.wiseBrightGreen.opacity(0.12))
                                    .stroke(Color.wiseBrightGreen.opacity(0.3), lineWidth: 1)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.wiseCardBackground)
        }
    }
}

// MARK: - Preview

#Preview("ContactActionBar - Not on Swiff") {
    VStack {
        Spacer()
        ContactActionBar(
            contact: ContactEntry(
                id: "1",
                name: "John Smith",
                phoneNumbers: ["+12025551234"],
                email: nil,
                thumbnailImageData: nil,
                hasAppAccount: false
            ),
            onTheyOweMe: { print("They owe me tapped") },
            onIOwe: { print("I owe them tapped") },
            onSplitBill: { print("Split bill tapped") },
            onInvite: { print("Invite tapped") }
        )
    }
    .background(Color.wiseBackground)
}

#Preview("ContactActionBar - On Swiff") {
    VStack {
        Spacer()
        ContactActionBar(
            contact: ContactEntry(
                id: "2",
                name: "Jane Doe",
                phoneNumbers: ["+12025555678"],
                email: nil,
                thumbnailImageData: nil,
                hasAppAccount: true
            ),
            onTheyOweMe: { print("They owe me tapped") },
            onIOwe: { print("I owe them tapped") },
            onSplitBill: { print("Split bill tapped") },
            onInvite: nil
        )
    }
    .background(Color.wiseBackground)
}
