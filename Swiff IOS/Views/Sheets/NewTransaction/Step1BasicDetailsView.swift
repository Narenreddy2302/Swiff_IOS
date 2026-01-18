//
//  Step1BasicDetailsView.swift
//  Swiff IOS
//
//  Step 1: Basic Info - Transaction name, amount, currency, category
//  Production-ready with design system compliance and accessibility
//

import SwiftUI

// MARK: - Step1BasicDetailsView

struct Step1BasicDetailsView: View {

    // MARK: - Properties

    @ObservedObject var viewModel: NewTransactionViewModel
    @EnvironmentObject var dataManager: DataManager
    @FocusState private var focusedField: Field?

    /// Track if user has attempted to proceed (for showing validation)
    @State private var hasAttemptedProceed: Bool = false

    // MARK: - Types

    private enum Field: Hashable {
        case name
        case amount
    }

    // MARK: - Body

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Metrics.paddingLarge) {
                    Divider()
                        .padding(.horizontal, -Theme.Metrics.paddingMedium)

                    sectionTitle
                    transactionNameField
                        .id("nameField")
                    amountCurrencyRow
                        .id("amountField")
                    categorySection

                    Spacer(minLength: 120)
                }
                .padding(.horizontal, Theme.Metrics.paddingMedium)
                .padding(.top, Theme.Metrics.paddingSmall)
            }
            .scrollDismissesKeyboard(.interactively)
            .safeAreaInset(edge: .bottom) {
                nextStepButton
                    .padding(.horizontal, Theme.Metrics.paddingMedium)
                    .padding(.bottom, Theme.Metrics.paddingMedium)
                    .background(
                        Theme.Colors.secondaryBackground
                            .ignoresSafeArea()
                    )
            }
            .onChange(of: focusedField) { _, newValue in
                scrollToField(newValue, proxy: proxy)
            }
        }
        .onTapGesture {
            dismissKeyboard()
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Step 1: Basic transaction details")
    }

    // MARK: - Subviews

    private var sectionTitle: some View {
        Text("Basic Info")
            .font(Theme.Fonts.displayMedium)
            .foregroundColor(Theme.Colors.textPrimary)
            .accessibilityAddTraits(.isHeader)
    }

    private var transactionNameField: some View {
        VStack(alignment: .leading, spacing: Theme.Metrics.paddingSmall) {
            Text("Transaction Name")
                .font(Theme.Fonts.labelLarge)
                .foregroundColor(Theme.Colors.textPrimary)

            TextField("e.g., Dinner at Nobu", text: $viewModel.transactionName)
                .font(Theme.Fonts.bodyLarge)
                .padding(.horizontal, Theme.Metrics.paddingMedium)
                .padding(.vertical, Theme.Metrics.paddingMedium)
                .background(
                    RoundedRectangle(cornerRadius: Theme.Metrics.cornerRadiusMedium)
                        .fill(Theme.Colors.cardBackground)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.Metrics.cornerRadiusMedium)
                        .stroke(borderColor(for: .name), lineWidth: borderWidth(for: .name))
                )
                .focused($focusedField, equals: .name)
                .submitLabel(.next)
                .onSubmit {
                    focusedField = .amount
                }
                .accessibilityLabel("Transaction name")
                .accessibilityHint("Enter a descriptive name for this transaction")

            if hasAttemptedProceed && viewModel.transactionName.trimmingCharacters(in: .whitespaces).isEmpty {
                validationMessage("Enter a transaction name")
            }
        }
    }

    private var amountCurrencyRow: some View {
        HStack(alignment: .top, spacing: Theme.Metrics.paddingMedium) {
            amountField
            currencyPicker
        }
    }

    private var amountField: some View {
        VStack(alignment: .leading, spacing: Theme.Metrics.paddingSmall) {
            Text("Amount")
                .font(Theme.Fonts.labelLarge)
                .foregroundColor(Theme.Colors.textPrimary)

            HStack(spacing: Theme.Metrics.paddingSmall) {
                Text(viewModel.selectedCurrency.symbol)
                    .font(Theme.Fonts.bodyLarge)
                    .foregroundColor(Theme.Colors.textSecondary)

                TextField("0.00", text: $viewModel.amountString)
                    .font(Theme.Fonts.bodyLarge)
                    .keyboardType(.decimalPad)
                    .focused($focusedField, equals: .amount)
                    .onChange(of: viewModel.amountString) { _, newValue in
                        filterAmountInput(newValue)
                    }
                    .accessibilityLabel("Amount")
                    .accessibilityValue("\(viewModel.selectedCurrency.symbol)\(viewModel.amountString.isEmpty ? "0" : viewModel.amountString)")
            }
            .padding(.horizontal, Theme.Metrics.paddingMedium)
            .padding(.vertical, Theme.Metrics.paddingMedium)
            .background(
                RoundedRectangle(cornerRadius: Theme.Metrics.cornerRadiusMedium)
                    .fill(Theme.Colors.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Metrics.cornerRadiusMedium)
                    .stroke(borderColor(for: .amount), lineWidth: borderWidth(for: .amount))
            )

            if hasAttemptedProceed && viewModel.amount <= 0 {
                validationMessage("Enter an amount greater than 0")
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var currencyPicker: some View {
        VStack(alignment: .leading, spacing: Theme.Metrics.paddingSmall) {
            Text("Currency")
                .font(Theme.Fonts.labelLarge)
                .foregroundColor(Theme.Colors.textPrimary)

            Menu {
                ForEach(Currency.allCases, id: \.self) { currency in
                    Button(action: {
                        HapticManager.shared.selection()
                        viewModel.selectedCurrency = currency
                    }) {
                        HStack {
                            Text("\(currency.flag) \(currency.rawValue)")
                            if currency == viewModel.selectedCurrency {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack {
                    Text(viewModel.selectedCurrency.rawValue)
                        .font(Theme.Fonts.bodyLarge)
                        .foregroundColor(Theme.Colors.textPrimary)

                    Spacer()

                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 14))
                        .foregroundColor(Theme.Colors.textSecondary)
                }
                .padding(.horizontal, Theme.Metrics.paddingMedium)
                .padding(.vertical, Theme.Metrics.paddingMedium)
                .background(
                    RoundedRectangle(cornerRadius: Theme.Metrics.cornerRadiusMedium)
                        .fill(Theme.Colors.cardBackground)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.Metrics.cornerRadiusMedium)
                        .stroke(Theme.Colors.border, lineWidth: 1)
                )
            }
            .accessibilityLabel("Currency: \(viewModel.selectedCurrency.rawValue)")
            .accessibilityHint("Double tap to change currency")
        }
        .frame(width: 120)
    }

    private var categorySection: some View {
        VStack(alignment: .leading, spacing: Theme.Metrics.paddingSmall) {
            Text("Category")
                .font(Theme.Fonts.labelLarge)
                .foregroundColor(Theme.Colors.textPrimary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(TransactionCategory.allCases, id: \.self) { category in
                        CategoryChip(
                            category: category,
                            isSelected: viewModel.selectedCategory == category,
                            action: {
                                HapticManager.shared.selection()
                                withAnimation(.snappy) {
                                    viewModel.selectedCategory = category
                                }
                                dismissKeyboard()
                            }
                        )
                    }
                }
                .padding(.vertical, 2)
            }
            .accessibilityElement(children: .contain)
            .accessibilityLabel("Category selection")
        }
    }

    private var nextStepButton: some View {
        VStack(spacing: Theme.Metrics.paddingSmall) {
            Button {
                handleNextStep()
            } label: {
                HStack(spacing: Theme.Metrics.paddingSmall) {
                    Text("Next Step")
                        .font(Theme.Fonts.bodyLarge)
                        .fontWeight(.semibold)

                    Image(systemName: "arrow.right")
                        .font(.system(size: 15, weight: .semibold))
                }
                .foregroundColor(Theme.Colors.textOnPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: SwiffButtonSize.large.height)
                .background(
                    RoundedRectangle(cornerRadius: Theme.Metrics.cornerRadiusMedium)
                        .fill(Theme.Colors.brandPrimary)
                        .opacity(viewModel.canProceedStep1 ? 1 : 0.5)
                )
            }
            .buttonStyle(ScaleButtonStyle())
            .accessibilityLabel("Next step")
            .accessibilityHint(viewModel.canProceedStep1 ? "Proceed to split options" : "Fill in required fields first")
        }
    }

    // MARK: - Helper Views

    private func validationMessage(_ message: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: "exclamationmark.circle.fill")
                .font(.system(size: 12))

            Text(message)
                .font(Theme.Fonts.labelSmall)
        }
        .foregroundColor(Theme.Colors.statusError)
        .transition(.opacity.combined(with: .move(edge: .top)))
        .accessibilityLabel("Error: \(message)")
    }

    // MARK: - Private Methods

    private func handleNextStep() {
        dismissKeyboard()

        if viewModel.canProceedStep1 {
            HapticManager.shared.selection()
            viewModel.goToNextStep()
        } else {
            withAnimation(.smooth) {
                hasAttemptedProceed = true
            }
            HapticManager.shared.warning()
        }
    }

    private func scrollToField(_ field: Field?, proxy: ScrollViewProxy) {
        guard let field = field else { return }

        withAnimation(.smooth) {
            switch field {
            case .name:
                proxy.scrollTo("nameField", anchor: .top)
            case .amount:
                proxy.scrollTo("amountField", anchor: .center)
            }
        }
    }

    private func borderColor(for field: Field) -> Color {
        if focusedField == field {
            return Theme.Colors.brandPrimary
        }

        if hasAttemptedProceed {
            switch field {
            case .name:
                if viewModel.transactionName.trimmingCharacters(in: .whitespaces).isEmpty {
                    return Theme.Colors.statusError
                }
            case .amount:
                if viewModel.amount <= 0 {
                    return Theme.Colors.statusError
                }
            }
        }

        return Theme.Colors.border
    }

    private func borderWidth(for field: Field) -> CGFloat {
        if focusedField == field {
            return 2
        }

        if hasAttemptedProceed {
            switch field {
            case .name:
                if viewModel.transactionName.trimmingCharacters(in: .whitespaces).isEmpty {
                    return 2
                }
            case .amount:
                if viewModel.amount <= 0 {
                    return 2
                }
            }
        }

        return 1
    }

    private func filterAmountInput(_ newValue: String) {
        var filtered = newValue.filter { $0.isNumber || $0 == "." }

        // Prevent leading zeros (except for "0.")
        if filtered.hasPrefix("00") {
            filtered = String(filtered.dropFirst())
        }

        // Add leading zero for decimal starting with "."
        if filtered.hasPrefix(".") {
            filtered = "0" + filtered
        }

        // Prevent multiple decimals
        let decimalCount = filtered.filter { $0 == "." }.count
        if decimalCount > 1 {
            if let lastDecimalIndex = filtered.lastIndex(of: ".") {
                filtered.remove(at: lastDecimalIndex)
            }
        }

        // Limit decimal places to 2
        if let decimalIndex = filtered.firstIndex(of: ".") {
            let decimalPart = filtered[filtered.index(after: decimalIndex)...]
            if decimalPart.count > 2 {
                let endIndex = filtered.index(decimalIndex, offsetBy: 3)
                filtered = String(filtered[..<endIndex])
            }
        }

        if filtered != newValue {
            viewModel.amountString = filtered
        }
    }

    private func dismissKeyboard() {
        focusedField = nil
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
    }
}

// MARK: - CategoryChip

struct CategoryChip: View {

    // MARK: - Properties

    let category: TransactionCategory
    let isSelected: Bool
    let action: () -> Void

    @State private var isPressed: Bool = false

    // MARK: - Body

    var body: some View {
        Button(action: action) {
            VStack(spacing: Theme.Metrics.paddingSmall) {
                Image(systemName: category.icon)
                    .font(.system(size: Theme.Metrics.iconSizeMedium))

                Text(category.rawValue)
                    .font(Theme.Fonts.labelMedium)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .foregroundColor(isSelected ? Theme.Colors.textOnPrimary : Theme.Colors.textPrimary)
            .frame(width: 80, height: 80)
            .background(
                RoundedRectangle(cornerRadius: Theme.Metrics.cornerRadiusMedium)
                    .fill(isSelected ? Theme.Colors.brandPrimary : Theme.Colors.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Metrics.cornerRadiusMedium)
                    .stroke(isSelected ? Color.clear : Theme.Colors.border, lineWidth: 1)
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(category.rawValue) category")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(.quickEase) {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    withAnimation(.quickEase) {
                        isPressed = false
                    }
                }
        )
    }
}

// MARK: - Preview

#Preview("Step 1 - Basic Details") {
    Step1BasicDetailsView(viewModel: NewTransactionViewModel())
        .environmentObject(DataManager.shared)
        .background(Theme.Colors.secondaryBackground)
}
