//
//  Step1BasicDetailsView.swift
//  Swiff IOS
//
//  Step 1: Basic Info - Transaction name, amount, currency, category
//  Redesigned to match reference UI exactly
//

import SwiftUI

struct Step1BasicDetailsView: View {
    @ObservedObject var viewModel: NewTransactionViewModel
    @EnvironmentObject var dataManager: DataManager
    @FocusState private var focusedField: Field?
    @State private var keyboardHeight: CGFloat = 0

    private enum Field: Hashable {
        case amount
        case name
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Divider below header
                Divider()
                    .padding(.horizontal, -20)

                // Section title
                Text("Basic Info")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(Theme.Colors.textPrimary)

                // Transaction Name Field
                transactionNameField

                // Amount and Currency Row
                amountCurrencyRow

                // Category Section
                categorySection

                Spacer(minLength: 100)
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
        }
        .safeAreaInset(edge: .bottom) {
            // Next Step Button
            nextStepButton
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
                .background(
                    Color(UIColor.systemGroupedBackground)
                        .ignoresSafeArea()
                )
        }
    }

    // MARK: - Transaction Name Field

    private var transactionNameField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Transaction Name")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(Theme.Colors.textPrimary)

            TextField("e.g., Dinner at Nobu", text: $viewModel.transactionName)
                .font(.system(size: 17))
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(UIColor.secondarySystemGroupedBackground))
                )
                .focused($focusedField, equals: .name)
        }
    }

    // MARK: - Amount and Currency Row

    private var amountCurrencyRow: some View {
        HStack(alignment: .top, spacing: 16) {
            // Amount Field
            VStack(alignment: .leading, spacing: 8) {
                Text("Amount")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(Theme.Colors.textPrimary)

                HStack(spacing: 8) {
                    Text(viewModel.selectedCurrency.symbol)
                        .font(.system(size: 17))
                        .foregroundColor(Theme.Colors.textSecondary)

                    TextField("0.00", text: $viewModel.amountString)
                        .font(.system(size: 17))
                        .keyboardType(.decimalPad)
                        .focused($focusedField, equals: .amount)
                        .onChange(of: viewModel.amountString) { _, newValue in
                            var filtered = newValue.filter { $0.isNumber || $0 == "." }
                            if filtered.hasPrefix("00") {
                                filtered = String(filtered.dropFirst())
                            }
                            if filtered.hasPrefix(".") {
                                filtered = "0" + filtered
                            }
                            let decimalCount = filtered.filter { $0 == "." }.count
                            if decimalCount > 1 {
                                if let lastDecimalIndex = filtered.lastIndex(of: ".") {
                                    filtered.remove(at: lastDecimalIndex)
                                }
                            }
                            if filtered != newValue {
                                viewModel.amountString = filtered
                            }
                        }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(UIColor.secondarySystemGroupedBackground))
                )
            }
            .frame(maxWidth: .infinity)

            // Currency Picker
            VStack(alignment: .leading, spacing: 8) {
                Text("Currency")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(Theme.Colors.textPrimary)

                Menu {
                    ForEach(Currency.allCases, id: \.self) { currency in
                        Button(action: {
                            HapticManager.shared.light()
                            viewModel.selectedCurrency = currency
                        }) {
                            HStack {
                                Text(currency.rawValue)
                                if currency == viewModel.selectedCurrency {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack {
                        Text(viewModel.selectedCurrency.rawValue)
                            .font(.system(size: 17))
                            .foregroundColor(Theme.Colors.textPrimary)

                        Spacer()

                        Image(systemName: "chevron.up.chevron.down")
                            .font(.system(size: 14))
                            .foregroundColor(Theme.Colors.textSecondary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(UIColor.secondarySystemGroupedBackground))
                    )
                }
            }
            .frame(width: 120)
        }
    }

    // MARK: - Category Section

    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Category")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(Theme.Colors.textPrimary)

            // Horizontal scrollable category chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(TransactionCategory.allCases, id: \.self) { category in
                        CategoryChip(
                            category: category,
                            isSelected: viewModel.selectedCategory == category,
                            action: {
                                HapticManager.shared.light()
                                viewModel.selectedCategory = category
                            }
                        )
                    }
                }
            }
        }
    }

    // MARK: - Next Step Button

    private var nextStepButton: some View {
        Button {
            if viewModel.canProceedStep1 {
                HapticManager.shared.light()
                withAnimation(.smooth) {
                    viewModel.goToNextStep()
                }
            }
        } label: {
            HStack(spacing: 8) {
                Text("Next Step")
                    .font(.system(size: 17, weight: .semibold))

                Image(systemName: "arrow.right")
                    .font(.system(size: 15, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Theme.Colors.brandPrimary)
                    .opacity(viewModel.canProceedStep1 ? 1 : 0.5)
            )
        }
        .disabled(!viewModel.canProceedStep1)
    }
}

// MARK: - Category Chip Component

struct CategoryChip: View {
    let category: TransactionCategory
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: category.icon)
                    .font(.system(size: 22))

                Text(category.rawValue)
                    .font(.system(size: 13, weight: .medium))
            }
            .foregroundColor(isSelected ? .white : Theme.Colors.textPrimary)
            .frame(width: 80, height: 80)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isSelected ? Theme.Colors.brandPrimary : Color(UIColor.secondarySystemGroupedBackground))
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview("Step 1 - Basic Details") {
    Step1BasicDetailsView(viewModel: NewTransactionViewModel())
        .environmentObject(DataManager.shared)
        .background(Color(UIColor.systemGroupedBackground))
}
