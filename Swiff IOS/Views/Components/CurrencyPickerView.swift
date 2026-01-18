//
//  CurrencyPickerView.swift
//  Swiff IOS
//
//  Expandable inline currency selection list matching reference design
//

import SwiftUI

/// Expandable list of currencies for selection
/// Matches the reference design with flag, name, code, and checkmark
struct CurrencyPickerView: View {
    let currencies: [Currency]
    @Binding var selectedCurrency: Currency
    @Binding var isPresented: Bool

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(currencies.enumerated()), id: \.element) { index, currency in
                Button {
                    HapticManager.shared.light()
                    selectedCurrency = currency
                    withAnimation(.smooth) {
                        isPresented = false
                    }
                } label: {
                    HStack(spacing: 12) {
                        // Flag emoji
                        Text(currency.flag)
                            .font(.system(size: 20))

                        // Currency name
                        Text(currency.name)
                            .font(.system(size: 17))
                            .foregroundColor(.primary)

                        Spacer()

                        // Currency code
                        Text(currency.rawValue)
                            .font(.system(size: 17))
                            .foregroundColor(.secondary)

                        // Checkmark for selected
                        if selectedCurrency == currency {
                            Image(systemName: "checkmark")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                // Divider between items (not after last)
                if index < currencies.count - 1 {
                    Divider()
                        .padding(.leading, 48)
                }
            }
        }
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .transition(.opacity.combined(with: .move(edge: .top)))
    }
}

// MARK: - Preview

#Preview("Currency Picker") {
    struct PreviewWrapper: View {
        @State private var selectedCurrency: Currency = .USD
        @State private var isPresented: Bool = true

        var body: some View {
            VStack(spacing: 20) {
                Text("Selected: \(selectedCurrency.symbol) \(selectedCurrency.name)")
                    .font(.headline)

                CurrencyPickerView(
                    currencies: Currency.allCases,
                    selectedCurrency: $selectedCurrency,
                    isPresented: $isPresented
                )
                .padding(.horizontal, 20)

                Spacer()
            }
            .padding(.top, 40)
            .background(Color(UIColor.systemGroupedBackground))
        }
    }

    return PreviewWrapper()
}
