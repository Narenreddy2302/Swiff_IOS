//
//  Step1BasicDetailsView.swift
//  Swiff IOS
//
//  Step 1: Transaction type, amount, description, category
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
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 20) {
                    // MARK: Transaction Type Segmented Control
                    transactionTypeSegment
                        .id("typeSegment")

                    // MARK: Amount Input Section
                    amountInputSection
                        .id("amountSection")

                    // MARK: Currency Picker (Expandable)
                    if viewModel.showCurrencyPicker {
                        CurrencyPickerView(
                            currencies: Currency.allCases,
                            selectedCurrency: $viewModel.selectedCurrency,
                            isPresented: $viewModel.showCurrencyPicker
                        )
                    }

                    // MARK: Description & Category Fields
                    descriptionCategorySection
                        .id("descSection")

                    // MARK: Category Picker (Expandable Grid)
                    if viewModel.showCategoryPicker {
                        CategoryGridPicker(
                            categories: TransactionCategory.allCases,
                            selectedCategory: $viewModel.selectedCategory,
                            isPresented: $viewModel.showCategoryPicker
                        )
                    }

                    // MARK: Continue Button
                    continueButton

                    // Bottom padding for keyboard
                    Spacer(minLength: keyboardHeight > 0 ? keyboardHeight : 60)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
            }
            .scrollDismissesKeyboard(.interactively)
            .onChange(of: focusedField) { _, newValue in
                guard let field = newValue else { return }
                withAnimation(.smooth) {
                    switch field {
                    case .amount:
                        proxy.scrollTo("amountSection", anchor: .center)
                    case .name:
                        proxy.scrollTo("descSection", anchor: .center)
                    }
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { notification in
                if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                    withAnimation(.smooth) {
                        keyboardHeight = keyboardFrame.height
                    }
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
                withAnimation(.smooth) {
                    keyboardHeight = 0
                }
            }
        }
    }

    // MARK: - Transaction Type Segmented Control

    private var transactionTypeSegment: some View {
        Picker("Transaction Type", selection: $viewModel.transactionType) {
            Text("Expense").tag(TransactionTypeOption.expense)
            Text("Income").tag(TransactionTypeOption.income)
        }
        .pickerStyle(.segmented)
        .onChange(of: viewModel.transactionType) { _, _ in
            HapticManager.shared.light()
        }
    }

    // MARK: - Amount Input Section

    private var amountInputSection: some View {
        HStack(spacing: 12) {
            // Currency selector button
            Button {
                HapticManager.shared.light()
                withAnimation(.smooth) {
                    viewModel.showCurrencyPicker.toggle()
                    viewModel.showCategoryPicker = false
                }
            } label: {
                HStack(spacing: 6) {
                    Text(viewModel.selectedCurrency.flag)
                        .font(.system(size: 20))
                    Text(viewModel.selectedCurrency.symbol)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.primary)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(UIColor.systemGroupedBackground))
                .cornerRadius(8)
            }
            .buttonStyle(.plain)

            // Amount text field
            TextField("0.00", text: $viewModel.amountString)
                .font(.system(size: 48, weight: .regular))
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .focused($focusedField, equals: .amount)
                .onChange(of: viewModel.amountString) { _, newValue in
                    // Filter to numbers and single decimal point
                    var filtered = newValue.filter { $0.isNumber || $0 == "." }
                    // Handle leading zeros
                    if filtered.hasPrefix("00") {
                        filtered = String(filtered.dropFirst())
                    }
                    // Ensure 0 before decimal if starting with .
                    if filtered.hasPrefix(".") {
                        filtered = "0" + filtered
                    }
                    // Ensure single decimal point
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
        .padding(20)
        .background(Color.white)
        .cornerRadius(12)
    }

    // MARK: - Description & Category Section

    private var descriptionCategorySection: some View {
        VStack(spacing: 0) {
            // Description input row
            HStack {
                Text("Description")
                    .font(.system(size: 17))
                Spacer()
                TextField("What's this for?", text: $viewModel.transactionName)
                    .font(.system(size: 17))
                    .multilineTextAlignment(.trailing)
                    .foregroundColor(.primary)
                    .focused($focusedField, equals: .name)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider()
                .padding(.leading, 16)

            // Category selector row
            Button {
                HapticManager.shared.light()
                withAnimation(.smooth) {
                    viewModel.showCategoryPicker.toggle()
                    viewModel.showCurrencyPicker = false
                }
            } label: {
                HStack {
                    Text("Category")
                        .font(.system(size: 17))
                        .foregroundColor(.primary)
                    Spacer()

                    // Selected category display
                    HStack(spacing: 6) {
                        Image(systemName: viewModel.selectedCategory.icon)
                            .foregroundColor(viewModel.selectedCategory.color)
                        Text(viewModel.selectedCategory.rawValue)
                            .foregroundColor(viewModel.selectedCategory.color)
                    }
                    .font(.system(size: 17))

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color(UIColor.systemGray3))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .buttonStyle(.plain)
        }
        .background(Color.white)
        .cornerRadius(12)
    }

    // MARK: - Continue Button

    private var continueButton: some View {
        Button {
            if viewModel.canProceedStep1 {
                HapticManager.shared.light()
                withAnimation(.smooth) {
                    viewModel.goToNextStep()
                }
            }
        } label: {
            Text("Continue")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.blue)
                        .opacity(viewModel.canProceedStep1 ? 1 : 0.5)
                )
        }
        .disabled(!viewModel.canProceedStep1)
    }
}

// MARK: - Preview

#Preview("Step 1 - Basic Details") {
    Step1BasicDetailsView(viewModel: NewTransactionViewModel())
        .environmentObject(DataManager.shared)
        .background(Color(UIColor.systemGroupedBackground))
}
