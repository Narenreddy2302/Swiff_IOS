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
        .onReceive(
            NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
        ) { notification in
            if let keyboardFrame = notification.userInfo?[
                UIResponder.keyboardFrameEndUserInfoKey] as? CGRect
            {
                withAnimation(.smooth) {
                    keyboardHeight = keyboardFrame.height
                }
            }
        }
        .onReceive(
            NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)
        ) { _ in
            withAnimation(.smooth) {
                keyboardHeight = 0
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
                    viewModel.showDatePicker = false
                }
            } label: {
                HStack(spacing: 4) {
                    Text(viewModel.selectedCurrency.symbol)
                        .font(.system(size: 32, weight: .medium))
                        .foregroundColor(.primary)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                }
            }
            .buttonStyle(.plain)

            // Amount text field
            TextField("0.00", text: $viewModel.amountString)
                .font(.system(size: 56, weight: .regular))
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.leading)  // Changed to leading to sit next to currency
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
        .padding(.vertical, 30)  // Increased vertical padding for "hero" feel
        .frame(maxWidth: .infinity, alignment: .center)  // Center the entire block
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
                    viewModel.showDatePicker = false
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

            Divider()
                .padding(.leading, 16)

            // Date selector row
            Button {
                HapticManager.shared.light()
                withAnimation(.smooth) {
                    viewModel.showDatePicker.toggle()
                    viewModel.showCurrencyPicker = false
                    viewModel.showCategoryPicker = false
                }
            } label: {
                HStack {
                    Text("Date")
                        .font(.system(size: 17))
                        .foregroundColor(.primary)
                    Spacer()

                    Text(formattedDate)
                        .font(.system(size: 17))
                        .foregroundColor(.secondary)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color(UIColor.systemGray3))
                        .rotationEffect(.degrees(viewModel.showDatePicker ? 90 : 0))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .buttonStyle(.plain)

            // Inline date picker (expandable)
            if viewModel.showDatePicker {
                Divider()
                    .padding(.leading, 16)

                DatePicker(
                    "Transaction Date",
                    selection: $viewModel.transactionDate,
                    in: ...Date(),
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .onChange(of: viewModel.transactionDate) { _, _ in
                    HapticManager.shared.light()
                }
            }
        }
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }

    // MARK: - Date Formatting

    private var formattedDate: String {
        let calendar = Calendar.current
        if calendar.isDateInToday(viewModel.transactionDate) {
            return "Today"
        } else if calendar.isDateInYesterday(viewModel.transactionDate) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return formatter.string(from: viewModel.transactionDate)
        }
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
                        .fill(Theme.Colors.brandPrimary)
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
