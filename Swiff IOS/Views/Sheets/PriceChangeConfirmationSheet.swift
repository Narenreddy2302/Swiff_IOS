//
//  PriceChangeConfirmationSheet.swift
//  Swiff IOS
//
//  Created by Agent 9 for Price History Tracking
//  Task 9.6: Confirmation dialog to distinguish real price changes from corrections
//

import SwiftUI

// MARK: - Price Change Confirmation Sheet

struct PriceChangeConfirmationSheet: View {
    @Environment(\.dismiss) var dismiss

    let oldPrice: Double
    let newPrice: Double
    let subscriptionName: String
    let onConfirm: (Bool, String?) -> Void // (isRealChange, reason)

    @State private var isRealChange: Bool? = nil
    @State private var reason: String = ""
    @State private var showReasonField = false

    private var priceChanged: Bool {
        oldPrice != newPrice
    }

    private var isIncrease: Bool {
        newPrice > oldPrice
    }

    private var changeAmount: Double {
        newPrice - oldPrice
    }

    private var changePercentage: Double {
        guard oldPrice > 0 else { return 0 }
        return ((newPrice - oldPrice) / oldPrice) * 100
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    headerSection

                    if priceChanged {
                        priceComparisonSection
                        questionSection

                        if let isRealChange = isRealChange {
                            if isRealChange {
                                reasonSection
                            } else {
                                correctionNote
                            }
                        }
                    } else {
                        noPriceChangeSection
                    }
                }
                .padding(.vertical, 20)
            }
            .background(Color.wiseBackground)
            .navigationTitle("Price Change")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Confirm") {
                        handleConfirm()
                    }
                    .fontWeight(.semibold)
                    .disabled(priceChanged && isRealChange == nil)
                }
            }
        }
    }

    // MARK: - View Components

    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: isIncrease ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                .font(.system(size: 56))
                .foregroundColor(isIncrease ? .wiseError : .wiseBrightGreen)

            Text(subscriptionName)
                .font(.spotifyHeadingLarge)
                .foregroundColor(.wisePrimaryText)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 16)
    }

    private var priceComparisonSection: some View {
        VStack(spacing: 16) {
            Text("Price Comparison")
                .font(.spotifyHeadingMedium)
                .foregroundColor(.wisePrimaryText)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 16) {
                // Old Price
                VStack(spacing: 8) {
                    Text("Previous")
                        .font(.spotifyLabelSmall)
                        .foregroundColor(.wiseSecondaryText)

                    Text(oldPrice.asCurrency)
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.wiseSecondaryText)
                        .strikethrough()
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.wiseSecondaryText.opacity(0.08))
                )

                // Arrow
                Image(systemName: "arrow.right")
                    .font(.system(size: 20))
                    .foregroundColor(.wiseSecondaryText)

                // New Price
                VStack(spacing: 8) {
                    Text("New")
                        .font(.spotifyLabelSmall)
                        .foregroundColor(.wiseSecondaryText)

                    Text(newPrice.asCurrency)
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(isIncrease ? .wiseError : .wiseBrightGreen)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill((isIncrease ? Color.wiseError : Color.wiseBrightGreen).opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(isIncrease ? Color.wiseError : Color.wiseBrightGreen, lineWidth: 2)
                        )
                )
            }

            // Change amount
            HStack(spacing: 8) {
                Image(systemName: isIncrease ? "arrow.up" : "arrow.down")
                    .font(.system(size: 14))
                Text("\(isIncrease ? "+" : "")\(abs(changeAmount).asCurrency) (\(isIncrease ? "+" : "")\(String(format: "%.1f", changePercentage))%)")
                    .font(.spotifyBodyMedium)
                    .fontWeight(.semibold)
            }
            .foregroundColor(isIncrease ? .wiseError : .wiseBrightGreen)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill((isIncrease ? Color.wiseError : Color.wiseBrightGreen).opacity(0.15))
            )
        }
        .padding(16)
        .background(Color.wiseCardBackground)
        .cornerRadius(16)
        .cardShadow()
        .padding(.horizontal, 16)
    }

    private var questionSection: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("What happened?")
                    .font(.spotifyHeadingMedium)
                    .foregroundColor(.wisePrimaryText)

                Text("Help us understand if this is a real price change or just a correction")
                    .font(.spotifyBodyMedium)
                    .foregroundColor(.wiseSecondaryText)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: 12) {
                // Real price change option
                Button(action: {
                    isRealChange = true
                    showReasonField = true
                }) {
                    HStack(spacing: 12) {
                        Circle()
                            .stroke(isRealChange == true ? Color.wiseBlue : Color.wiseBorder, lineWidth: 2)
                            .frame(width: 24, height: 24)
                            .overlay(
                                Circle()
                                    .fill(Color.wiseBlue)
                                    .frame(width: 14, height: 14)
                                    .opacity(isRealChange == true ? 1 : 0)
                            )

                        VStack(alignment: .leading, spacing: 4) {
                            Text("The price actually changed")
                                .font(.spotifyBodyLarge)
                                .fontWeight(.medium)
                                .foregroundColor(.wisePrimaryText)

                            Text("The subscription provider increased/decreased the price")
                                .font(.spotifyCaptionMedium)
                                .foregroundColor(.wiseSecondaryText)
                        }

                        Spacer()

                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(isIncrease ? .wiseError : .wiseBrightGreen)
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isRealChange == true ? Color.wiseBlue : Color.wiseBorder, lineWidth: isRealChange == true ? 2 : 1)
                    )
                }
                .buttonStyle(.plain)

                // Correction option
                Button(action: {
                    isRealChange = false
                    showReasonField = false
                    reason = ""
                }) {
                    HStack(spacing: 12) {
                        Circle()
                            .stroke(isRealChange == false ? Color.wiseBlue : Color.wiseBorder, lineWidth: 2)
                            .frame(width: 24, height: 24)
                            .overlay(
                                Circle()
                                    .fill(Color.wiseBlue)
                                    .frame(width: 14, height: 14)
                                    .opacity(isRealChange == false ? 1 : 0)
                            )

                        VStack(alignment: .leading, spacing: 4) {
                            Text("I'm correcting an error")
                                .font(.spotifyBodyLarge)
                                .fontWeight(.medium)
                                .foregroundColor(.wisePrimaryText)

                            Text("I entered the wrong price before")
                                .font(.spotifyCaptionMedium)
                                .foregroundColor(.wiseSecondaryText)
                        }

                        Spacer()

                        Image(systemName: "pencil.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.wiseBlue)
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isRealChange == false ? Color.wiseBlue : Color.wiseBorder, lineWidth: isRealChange == false ? 2 : 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .background(Color.wiseCardBackground)
        .cornerRadius(16)
        .cardShadow()
        .padding(.horizontal, 16)
    }

    private var reasonSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Reason (Optional)")
                .font(.spotifyHeadingMedium)
                .foregroundColor(.wisePrimaryText)

            Text("Add a note about why the price changed")
                .font(.spotifyBodyMedium)
                .foregroundColor(.wiseSecondaryText)

            TextField("e.g., Annual price adjustment, New features added", text: $reason, axis: .vertical)
                .textFieldStyle(.plain)
                .lineLimit(3...6)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.wiseBackground)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.wiseBorder, lineWidth: 1)
                )
        }
        .padding(16)
        .background(Color.wiseCardBackground)
        .cornerRadius(16)
        .cardShadow()
        .padding(.horizontal, 16)
    }

    private var correctionNote: some View {
        HStack(spacing: 12) {
            Image(systemName: "info.circle.fill")
                .font(.system(size: 20))
                .foregroundColor(.wiseBlue)

            VStack(alignment: .leading, spacing: 4) {
                Text("No price history will be created")
                    .font(.spotifyLabelMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(.wisePrimaryText)

                Text("The price will be updated without tracking this as a change")
                    .font(.spotifyCaptionMedium)
                    .foregroundColor(.wiseSecondaryText)
            }

            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.wiseBlue.opacity(0.1))
        )
        .padding(.horizontal, 16)
    }

    private var noPriceChangeSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 56))
                .foregroundColor(.wiseBrightGreen)

            Text("No Price Change")
                .font(.spotifyHeadingLarge)
                .foregroundColor(.wisePrimaryText)

            Text("The price hasn't changed from the previous value")
                .font(.spotifyBodyMedium)
                .foregroundColor(.wiseSecondaryText)
                .multilineTextAlignment(.center)
        }
        .padding(32)
        .background(Color.wiseCardBackground)
        .cornerRadius(16)
        .cardShadow()
        .padding(.horizontal, 16)
    }

    // MARK: - Actions

    private func handleConfirm() {
        if !priceChanged {
            // No price change, just update
            onConfirm(false, nil)
        } else if let isRealChange = isRealChange {
            // User made a selection
            let finalReason = isRealChange && !reason.isEmpty ? reason : nil
            onConfirm(isRealChange, finalReason)
        }
        dismiss()
    }
}

// MARK: - Preview

#Preview("Price Change Confirmation Sheet") {
    PriceChangeConfirmationSheet(
        oldPrice: MockData.priceIncrease.oldPrice,
        newPrice: MockData.priceIncrease.newPrice,
        subscriptionName: "Netflix Premium",
        onConfirm: { isReal, reason in
            print("Real change: \(isReal), Reason: \(reason ?? "none")")
        }
    )
}
