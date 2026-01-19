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

    // MARK: - Body

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: Theme.Metrics.paddingLarge) {

                    // Hero Amount Input
                    heroAmountSection
                        .id("amountField")
                        .padding(.top, Theme.Metrics.paddingLarge)

                    // Form Fields
                    VStack(spacing: Theme.Metrics.paddingMedium) {
                        
                        // Name Input Card
                        inputCard(
                            icon: "pencil",
                            title: "Transaction Name",
                            placeholder: "Enter description...",
                            text: $viewModel.basicDetails.transactionName,
                            field: .name
                        )
                        .id("nameField")

                        // Category Section
                        categorySection

                        // Date Input Card (Custom implementation for DatePicker)
                        dateInputCard

                        // Notes Input Card
                        inputCard(
                            icon: "text.justify.left",
                            title: "Notes (Optional)",
                            placeholder: "Add details...",
                            text: $viewModel.basicDetails.notes,
                            field: nil
                        )
                    }
                    .padding(.horizontal, Theme.Metrics.paddingMedium)

                    Spacer(minLength: 120)
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .safeAreaInset(edge: .bottom) {
                continueButton
                    .padding(.horizontal, Theme.Metrics.paddingMedium)
                    .padding(.bottom, Theme.Metrics.paddingLarge)
                    .background(
                        Theme.Colors.secondaryBackground
                            .ignoresSafeArea()
                    )
            }
            .onChange(of: focusedField) { _, newValue in
                scrollToField(newValue, proxy: proxy)
            }
        }
        .background(Theme.Colors.background)
        .onTapGesture {
            dismissKeyboard()
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Step 1: Basic transaction details")
    }

    // MARK: - Subviews

    private var heroAmountSection: some View {
        VStack(spacing: Theme.Metrics.paddingSmall) {
            HStack(alignment: .center, spacing: 4) {
                Menu {
                    ForEach(Currency.allCases, id: \.self) { currency in
                        Button(action: {
                            HapticManager.shared.selection()
                            viewModel.basicDetails.selectedCurrency = currency
                        }) {
                            HStack {
                                Text("\(currency.flag) \(currency.rawValue)")
                                if currency == viewModel.basicDetails.selectedCurrency {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    Text(viewModel.basicDetails.selectedCurrency.symbol)
                        .font(Theme.Fonts.displayLarge)
                        .foregroundColor(Theme.Colors.textSecondary)
                }

                TextField("0", text: $viewModel.basicDetails.amountString)
                    .font(Theme.Fonts.displayLarge)
                    .foregroundColor(Theme.Colors.textPrimary)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.center)
                    .focused($focusedField, equals: .amount)
                    .fixedSize(horizontal: true, vertical: false)
                    .onChange(of: viewModel.basicDetails.amountString) { _, newValue in
                        filterAmountInput(newValue)
                    }
            }

            // Underline accent
            Rectangle()
                .fill(Theme.Colors.accentMedium)
                .frame(height: 2)
                .frame(maxWidth: 120)
            
            if hasAttemptedProceed && viewModel.basicDetails.amount <= 0 {
                Text("Enter amount")
                    .font(Theme.Fonts.labelSmall)
                    .foregroundColor(Theme.Colors.statusError)
            }
        }
        .padding(.vertical, Theme.Metrics.paddingLarge)
    }

    private func inputCard(icon: String, title: String, placeholder: String, text: Binding<String>, field: Field?) -> some View {
        HStack(spacing: Theme.Metrics.paddingMedium) {
            // Icon circle
            Circle()
                .fill(Theme.Colors.accentLight)
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: icon)
                        .font(.system(size: Theme.Metrics.iconSizeSmall))
                        .foregroundColor(Theme.Colors.accentDark)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(Theme.Fonts.labelSmall)
                    .foregroundColor(Theme.Colors.textSecondary)

                TextField(placeholder, text: text)
                    .font(Theme.Fonts.bodyLarge)
                    .foregroundColor(Theme.Colors.textPrimary)
                    .focused($focusedField, equals: field)
                    .submitLabel(field == .name ? .done : .return)
            }
        }
        .padding(Theme.Metrics.paddingMedium)
        .background(Theme.Colors.cardBackground)
        .cornerRadius(Theme.Metrics.cornerRadiusMedium)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Metrics.cornerRadiusMedium)
                .stroke(
                     field == .name && hasAttemptedProceed && text.wrappedValue.trimmingCharacters(in: .whitespaces).isEmpty ? Theme.Colors.statusError : Color.clear,
                     lineWidth: 2
                )
        )
    }

    private var categorySection: some View {
        VStack(alignment: .leading, spacing: Theme.Metrics.paddingSmall) {
            Text("Category")
                .font(Theme.Fonts.labelSmall)
                .foregroundColor(Theme.Colors.textSecondary)
                .padding(.leading, Theme.Metrics.paddingMedium)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Theme.Metrics.paddingSmall) {
                    ForEach(TransactionCategory.allCases, id: \.self) { category in
                        CategoryPill(
                            category: category,
                            isSelected: viewModel.basicDetails.selectedCategory == category,
                            action: {
                                HapticManager.shared.selection()
                                withAnimation(.snappy) {
                                    viewModel.basicDetails.selectedCategory = category
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal, Theme.Metrics.paddingMedium)
            }
        }
    }

    private var dateInputCard: some View {
        HStack(spacing: Theme.Metrics.paddingMedium) {
            // Icon circle
            Circle()
                .fill(Theme.Colors.accentLight)
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: "calendar")
                        .font(.system(size: Theme.Metrics.iconSizeSmall))
                        .foregroundColor(Theme.Colors.accentDark)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text("Date")
                    .font(Theme.Fonts.labelSmall)
                    .foregroundColor(Theme.Colors.textSecondary)

                DatePicker(
                    "",
                    selection: $viewModel.basicDetails.transactionDate,
                    displayedComponents: .date
                )
                .labelsHidden()
                .datePickerStyle(.compact)
            }
            Spacer()
        }
        .padding(Theme.Metrics.paddingMedium)
        .background(Theme.Colors.cardBackground)
        .cornerRadius(Theme.Metrics.cornerRadiusMedium)
    }

    private var continueButton: some View {
        Button(action: handleNextStep) {
            Text("Continue")
                .font(Theme.Fonts.labelLarge)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: SwiffButtonSize.large.height)
                .background(Theme.Colors.accentDark)
                .cornerRadius(Theme.Metrics.cornerRadiusMedium)
                .opacity(viewModel.basicDetails.canProceed ? 1.0 : Theme.Opacity.disabled)
        }
        .disabled(!viewModel.basicDetails.canProceed)
    }
    
    // MARK: - Private Methods

    private func handleNextStep() {
        dismissKeyboard()
        if viewModel.basicDetails.canProceed {
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
                proxy.scrollTo("nameField", anchor: .center)
            case .amount:
                proxy.scrollTo("amountField", anchor: .center)
            }
        }
    }

    private func filterAmountInput(_ newValue: String) {
        var filtered = newValue.filter { $0.isNumber || $0 == "." }
        
        // Basic filtering logic reuse
        if filtered.hasPrefix("00") { filtered = String(filtered.dropFirst()) }
        if filtered == "0" { } // Allow 0
        if filtered.hasPrefix(".") { filtered = "0" + filtered }
        
        let decimalCount = filtered.filter { $0 == "." }.count
        if decimalCount > 1 {
             if let lastIndex = filtered.lastIndex(of: ".") {
                 filtered.remove(at: lastIndex)
             }
        }
        
        if let decimalIndex = filtered.firstIndex(of: ".") {
            let decimalPart = filtered[filtered.index(after: decimalIndex)...]
            if decimalPart.count > 2 {
                let endIndex = filtered.index(decimalIndex, offsetBy: 3)
                filtered = String(filtered[..<endIndex])
            }
        }

        if filtered != newValue {
            viewModel.basicDetails.amountString = filtered
        }
    }

    private func dismissKeyboard() {
        focusedField = nil
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

struct CategoryPill: View {
    let category: TransactionCategory
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: category.icon)
                    .font(.system(size: Theme.Metrics.iconSizeSmall))
                Text(category.rawValue)
                    .font(Theme.Fonts.labelSmall)
            }
            .padding(.horizontal, Theme.Metrics.paddingMedium)
            .padding(.vertical, Theme.Metrics.paddingSmall)
            .background(isSelected ? Theme.Colors.accentDark : Theme.Colors.secondaryBackground)
            .foregroundColor(isSelected ? .white : Theme.Colors.textPrimary)
            .clipShape(Capsule())
        }
    }
}

// MARK: - Preview

#Preview("Step 1 - Basic Details") {
    Step1BasicDetailsView(viewModel: NewTransactionViewModel())
        .environmentObject(DataManager.shared)
        .background(Theme.Colors.secondaryBackground)
}
