//
//  Step1BasicDetailsView.swift
//  Swiff IOS
//
//  Step 1: Basic Info - Transaction name, amount, currency, category
//  Redesigned to match reference UI exactly with proper theme consistency
//

import SwiftUI

struct Step1BasicDetailsView: View {
    @ObservedObject var viewModel: NewTransactionViewModel
    @EnvironmentObject var dataManager: DataManager
    @FocusState private var focusedField: Field?

    private enum Field: Hashable {
        case amount
        case name
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Metrics.paddingLarge) {
                // Divider below header
                Divider()
                    .padding(.horizontal, -20)

                // Section title
                Text("Basic Info")
                    .font(.spotifyDisplayMedium)
                    .foregroundColor(.wisePrimaryText)

                // Transaction Name Field
                transactionNameField

                // Amount and Currency Row
                amountCurrencyRow

                // Category Section
                categorySection

                Spacer(minLength: 100)
            }
            .padding(.horizontal, Theme.Metrics.paddingMedium + 4)
            .padding(.top, Theme.Metrics.paddingSmall)
        }
        .safeAreaInset(edge: .bottom) {
            // Next Step Button
            nextStepButton
                .padding(.horizontal, Theme.Metrics.paddingMedium + 4)
                .padding(.bottom, Theme.Metrics.paddingMedium + 4)
                .background(
                    Color.wiseGroupedBackground
                        .ignoresSafeArea()
                )
        }
    }

    // MARK: - Transaction Name Field

    private var transactionNameField: some View {
        VStack(alignment: .leading, spacing: Theme.Metrics.paddingSmall) {
            Text("Transaction Name")
                .font(.spotifyLabelLarge)
                .foregroundColor(.wisePrimaryText)

            TextField("e.g., Dinner at Nobu", text: $viewModel.transactionName)
                .font(.spotifyBodyLarge)
                .padding(.horizontal, Theme.Metrics.paddingMedium)
                .padding(.vertical, Theme.Metrics.paddingMedium)
                .background(
                    RoundedRectangle(cornerRadius: Theme.Metrics.cornerRadiusMedium)
                        .fill(Color.wiseCardBackground)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.Metrics.cornerRadiusMedium)
                        .stroke(Color.wiseBorder, lineWidth: 1)
                )
                .focused($focusedField, equals: .name)
        }
    }

    // MARK: - Amount and Currency Row

    private var amountCurrencyRow: some View {
        HStack(alignment: .top, spacing: Theme.Metrics.paddingMedium) {
            // Amount Field
            VStack(alignment: .leading, spacing: Theme.Metrics.paddingSmall) {
                Text("Amount")
                    .font(.spotifyLabelLarge)
                    .foregroundColor(.wisePrimaryText)

                HStack(spacing: Theme.Metrics.paddingSmall) {
                    Text(viewModel.selectedCurrency.symbol)
                        .font(.spotifyBodyLarge)
                        .foregroundColor(.wiseSecondaryText)

                    TextField("0.00", text: $viewModel.amountString)
                        .font(.spotifyBodyLarge)
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
                .padding(.horizontal, Theme.Metrics.paddingMedium)
                .padding(.vertical, Theme.Metrics.paddingMedium)
                .background(
                    RoundedRectangle(cornerRadius: Theme.Metrics.cornerRadiusMedium)
                        .fill(Color.wiseCardBackground)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.Metrics.cornerRadiusMedium)
                        .stroke(Color.wiseBorder, lineWidth: 1)
                )
            }
            .frame(maxWidth: .infinity)

            // Currency Picker
            VStack(alignment: .leading, spacing: Theme.Metrics.paddingSmall) {
                Text("Currency")
                    .font(.spotifyLabelLarge)
                    .foregroundColor(.wisePrimaryText)

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
                            .font(.spotifyBodyLarge)
                            .foregroundColor(.wisePrimaryText)

                        Spacer()

                        Image(systemName: "chevron.up.chevron.down")
                            .font(.system(size: 14))
                            .foregroundColor(.wiseSecondaryText)
                    }
                    .padding(.horizontal, Theme.Metrics.paddingMedium)
                    .padding(.vertical, Theme.Metrics.paddingMedium)
                    .background(
                        RoundedRectangle(cornerRadius: Theme.Metrics.cornerRadiusMedium)
                            .fill(Color.wiseCardBackground)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.Metrics.cornerRadiusMedium)
                            .stroke(Color.wiseBorder, lineWidth: 1)
                    )
                }
            }
            .frame(width: 120)
        }
    }

    // MARK: - Category Section

    private var categorySection: some View {
        VStack(alignment: .leading, spacing: Theme.Metrics.paddingSmall + 4) {
            Text("Category")
                .font(.spotifyLabelLarge)
                .foregroundColor(.wisePrimaryText)

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
            HStack(spacing: Theme.Metrics.paddingSmall) {
                Text("Next Step")
                    .font(.spotifyBodyLarge)
                    .fontWeight(.semibold)

                Image(systemName: "arrow.right")
                    .font(.system(size: 15, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: Theme.Metrics.cornerRadiusMedium + 2)
                    .fill(Color.wiseForestGreen)
                    .opacity(viewModel.canProceedStep1 ? 1 : 0.5)
            )
        }
        .disabled(!viewModel.canProceedStep1)
        .cardShadow()
    }
}

// MARK: - Category Chip Component

struct CategoryChip: View {
    let category: TransactionCategory
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: Theme.Metrics.paddingSmall) {
                Image(systemName: category.icon)
                    .font(.system(size: 22))

                Text(category.rawValue)
                    .font(.spotifyLabelMedium)
            }
            .foregroundColor(isSelected ? .white : .wisePrimaryText)
            .frame(width: 80, height: 80)
            .background(
                RoundedRectangle(cornerRadius: Theme.Metrics.cornerRadiusMedium + 2)
                    .fill(isSelected ? Color.wiseForestGreen : Color.wiseCardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Metrics.cornerRadiusMedium + 2)
                    .stroke(isSelected ? Color.clear : Color.wiseBorder, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .cardShadow()
    }
}

// MARK: - Preview

#Preview("Step 1 - Basic Details") {
    Step1BasicDetailsView(viewModel: NewTransactionViewModel())
        .environmentObject(DataManager.shared)
        .background(Color.wiseGroupedBackground)
}
