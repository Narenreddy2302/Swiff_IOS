//
//  EditTransactionSheet.swift
//  Swiff IOS
//
//  Created by Naren Reddy on 11/20/25.
//  Edit existing transaction
//

import SwiftUI
import PhotosUI
import Combine

struct EditTransactionSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataManager: DataManager

    let transaction: Transaction
    let onTransactionUpdated: () -> Void

    @State private var title: String
    @State private var subtitle: String
    @State private var amount: String
    @State private var selectedCategory: TransactionCategory
    @State private var transactionType: TransactionType
    @State private var isRecurring: Bool
    @State private var selectedDate: Date
    @State private var tags: [String]
    @State private var newTag = ""
    @State private var showingCategoryPicker = false

    // Page 2 Enhancements - New fields
    @State private var merchant: String
    @State private var paymentStatus: PaymentStatus
    @State private var receiptData: Data?
    @State private var linkedSubscriptionId: UUID?
    @State private var showingReceiptPicker = false
    @State private var receiptPhotoItem: PhotosPickerItem?

    init(transaction: Transaction, onTransactionUpdated: @escaping () -> Void) {
        self.transaction = transaction
        self.onTransactionUpdated = onTransactionUpdated

        _title = State(initialValue: transaction.title)
        _subtitle = State(initialValue: transaction.subtitle)
        _amount = State(initialValue: String(format: "%.2f", abs(transaction.amount)))
        _selectedCategory = State(initialValue: transaction.category)
        _transactionType = State(initialValue: transaction.amount < 0 ? .expense : .income)
        _isRecurring = State(initialValue: transaction.isRecurring)
        _selectedDate = State(initialValue: transaction.date)
        _tags = State(initialValue: transaction.tags)

        // Initialize new fields
        _merchant = State(initialValue: transaction.merchant ?? "")
        _paymentStatus = State(initialValue: transaction.paymentStatus)
        _receiptData = State(initialValue: transaction.receiptData)
        _linkedSubscriptionId = State(initialValue: transaction.linkedSubscriptionId)
    }

    enum TransactionType: String, CaseIterable {
        case expense = "Expense"
        case income = "Income"

        var color: Color {
            switch self {
            case .expense: return .wiseError
            case .income: return .wiseBrightGreen
            }
        }

        var icon: String {
            switch self {
            case .expense: return "arrow.down.circle.fill"
            case .income: return "arrow.up.circle.fill"
            }
        }
    }

    private var isFormValid: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty &&
        !subtitle.trimmingCharacters(in: .whitespaces).isEmpty &&
        !amount.trimmingCharacters(in: .whitespaces).isEmpty &&
        Double(amount) != nil
    }

    private var linkedSubscriptionName: String? {
        guard let id = linkedSubscriptionId else { return nil }
        return dataManager.subscriptions.first(where: { $0.id == id })?.name
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Transaction Type Selector
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Transaction Type")
                            .font(.spotifyHeadingMedium)
                            .foregroundColor(.wisePrimaryText)

                        HStack(spacing: 12) {
                            ForEach(TransactionType.allCases, id: \.self) { type in
                                Button(action: { transactionType = type }) {
                                    HStack(spacing: 8) {
                                        Image(systemName: type.icon)
                                            .font(.system(size: 16))
                                        Text(type.rawValue)
                                            .font(.spotifyBodyMedium)
                                    }
                                    .foregroundColor(transactionType == type ? .white : type.color)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    .frame(maxWidth: .infinity)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(transactionType == type ? type.color : type.color.opacity(0.1))
                                    )
                                }
                            }
                        }
                    }

                    // Basic Information
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Basic Information")
                            .font(.spotifyHeadingMedium)
                            .foregroundColor(.wisePrimaryText)

                        // Title
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Title *")
                                .font(.spotifyLabelMedium)
                                .foregroundColor(.wiseSecondaryText)

                            TextField("e.g., Coffee at Starbucks", text: $title)
                                .font(.spotifyBodyMedium)
                                .foregroundColor(.wisePrimaryText)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.wiseBorder.opacity(0.5))
                                        .stroke(Color.wiseBorder, lineWidth: 1)
                                )
                        }

                        // Subtitle/Description
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Description *")
                                .font(.spotifyLabelMedium)
                                .foregroundColor(.wiseSecondaryText)

                            TextField("e.g., Morning coffee", text: $subtitle)
                                .font(.spotifyBodyMedium)
                                .foregroundColor(.wisePrimaryText)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.wiseBorder.opacity(0.5))
                                        .stroke(Color.wiseBorder, lineWidth: 1)
                                )
                        }

                        // Amount
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Amount *")
                                .font(.spotifyLabelMedium)
                                .foregroundColor(.wiseSecondaryText)

                            HStack {
                                Text("$")
                                    .font(.spotifyNumberLarge)
                                    .foregroundColor(.wisePrimaryText)

                                TextField("0.00", text: $amount)
                                    .font(.spotifyNumberLarge)
                                    .foregroundColor(.wisePrimaryText)
                                    .keyboardType(.decimalPad)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.wiseBorder.opacity(0.5))
                                    .stroke(Color.wiseBorder, lineWidth: 1)
                            )
                        }

                        // Merchant (Page 2 Enhancement)
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Merchant (Optional)")
                                .font(.spotifyLabelMedium)
                                .foregroundColor(.wiseSecondaryText)

                            TextField("e.g., Starbucks, Amazon", text: $merchant)
                                .font(.spotifyBodyMedium)
                                .foregroundColor(.wisePrimaryText)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.wiseBorder.opacity(0.5))
                                        .stroke(Color.wiseBorder, lineWidth: 1)
                                )
                        }

                        // Payment Status (Page 2 Enhancement)
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Payment Status")
                                .font(.spotifyLabelMedium)
                                .foregroundColor(.wiseSecondaryText)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(PaymentStatus.allCases, id: \.self) { status in
                                        Button(action: { paymentStatus = status }) {
                                            HStack(spacing: 6) {
                                                Image(systemName: status.icon)
                                                    .font(.system(size: 12))
                                                Text(status.rawValue)
                                                    .font(.spotifyLabelMedium)
                                            }
                                            .foregroundColor(paymentStatus == status ? .white : status.color)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 8)
                                            .background(
                                                Capsule()
                                                    .fill(paymentStatus == status ? status.color : status.badgeBackgroundColor)
                                            )
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Category & Date
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Category & Date")
                            .font(.spotifyHeadingMedium)
                            .foregroundColor(.wisePrimaryText)

                        // Category Picker
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Category *")
                                .font(.spotifyLabelMedium)
                                .foregroundColor(.wiseSecondaryText)

                            Button(action: { showingCategoryPicker.toggle() }) {
                                HStack {
                                    Image(systemName: selectedCategory.icon)
                                        .foregroundColor(selectedCategory.color)
                                    Text(selectedCategory.rawValue)
                                        .font(.spotifyBodyMedium)
                                        .foregroundColor(.wisePrimaryText)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14))
                                        .foregroundColor(.wiseSecondaryText)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.wiseBorder.opacity(0.5))
                                        .stroke(Color.wiseBorder, lineWidth: 1)
                                )
                            }
                        }

                        // Date Picker
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Date")
                                .font(.spotifyLabelMedium)
                                .foregroundColor(.wiseSecondaryText)

                            DatePicker("", selection: $selectedDate, displayedComponents: [.date, .hourAndMinute])
                                .datePickerStyle(.compact)
                                .labelsHidden()
                        }
                    }

                    // Tags
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Tags (Optional)")
                            .font(.spotifyHeadingMedium)
                            .foregroundColor(.wisePrimaryText)

                        // Add tag field
                        HStack {
                            TextField("Add a tag", text: $newTag)
                                .font(.spotifyBodyMedium)
                                .foregroundColor(.wisePrimaryText)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.wiseBorder.opacity(0.5))
                                        .stroke(Color.wiseBorder, lineWidth: 1)
                                )

                            Button(action: addTag) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 32))
                                    .foregroundColor(.wiseForestGreen)
                            }
                            .disabled(newTag.trimmingCharacters(in: .whitespaces).isEmpty)
                        }

                        // Tag list
                        if !tags.isEmpty {
                            FlowLayout(spacing: 8) {
                                ForEach(tags, id: \.self) { tag in
                                    HStack(spacing: 4) {
                                        Text(tag)
                                            .font(.spotifyLabelSmall)
                                            .foregroundColor(.wiseForestGreen)

                                        Button(action: { removeTag(tag) }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .font(.system(size: 14))
                                                .foregroundColor(.wiseSecondaryText)
                                        }
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.wiseForestGreen.opacity(0.1))
                                    .cornerRadius(16)
                                }
                            }
                        }
                    }

                    // Receipt Attachment (Page 2 Enhancement)
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Receipt (Optional)")
                            .font(.spotifyHeadingMedium)
                            .foregroundColor(.wisePrimaryText)

                        PhotosPicker(selection: $receiptPhotoItem, matching: .images) {
                            HStack {
                                Image(systemName: receiptData != nil ? "checkmark.circle.fill" : "camera.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(receiptData != nil ? .wiseForestGreen : .wiseBlue)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(receiptData != nil ? "Receipt attached" : "Add receipt photo")
                                        .font(.spotifyBodyMedium)
                                        .foregroundColor(.wisePrimaryText)

                                    if receiptData != nil {
                                        Text("Tap to change")
                                            .font(.spotifyLabelSmall)
                                            .foregroundColor(.wiseSecondaryText)
                                    }
                                }

                                Spacer()

                                if receiptData != nil {
                                    Button(action: { receiptData = nil; receiptPhotoItem = nil }) {
                                        Image(systemName: "trash.circle.fill")
                                            .font(.system(size: 20))
                                            .foregroundColor(.wiseError)
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.wiseBorder.opacity(0.5))
                                    .stroke(Color.wiseBorder, lineWidth: 1)
                            )
                        }
                        .onChange(of: receiptPhotoItem) { _, newItem in
                            Task {
                                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                                    receiptData = data
                                }
                            }
                        }
                    }

                    // Subscription Link (Page 2 Enhancement)
                    if !dataManager.subscriptions.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Link to Subscription (Optional)")
                                .font(.spotifyHeadingMedium)
                                .foregroundColor(.wisePrimaryText)

                            Menu {
                                Button("None") {
                                    linkedSubscriptionId = nil
                                }

                                ForEach(dataManager.subscriptions) { subscription in
                                    Button(subscription.name) {
                                        linkedSubscriptionId = subscription.id
                                    }
                                }
                            } label: {
                                HStack {
                                    Image(systemName: linkedSubscriptionId != nil ? "link.circle.fill" : "link.circle")
                                        .font(.system(size: 20))
                                        .foregroundColor(linkedSubscriptionId != nil ? .wiseForestGreen : .wiseSecondaryText)

                                    Text(linkedSubscriptionName ?? "Select subscription")
                                        .font(.spotifyBodyMedium)
                                        .foregroundColor(.wisePrimaryText)

                                    Spacer()

                                    Image(systemName: "chevron.down")
                                        .font(.system(size: 14))
                                        .foregroundColor(.wiseSecondaryText)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.wiseBorder.opacity(0.5))
                                        .stroke(Color.wiseBorder, lineWidth: 1)
                                )
                            }
                        }
                    }

                    // Recurring Toggle
                    VStack(alignment: .leading, spacing: 12) {
                        Toggle(isOn: $isRecurring) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Recurring Transaction")
                                    .font(.spotifyBodyMedium)
                                    .foregroundColor(.wisePrimaryText)
                                Text("Automatically repeat this transaction")
                                    .font(.spotifyCaptionMedium)
                                    .foregroundColor(.wiseSecondaryText)
                            }
                        }
                        .tint(.wiseForestGreen)
                    }

                    Spacer(minLength: 50)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
            .navigationTitle("Edit Transaction")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .font(.spotifyLabelLarge)
                    .foregroundColor(.wiseSecondaryText)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        updateTransaction()
                    }
                    .font(.spotifyLabelLarge)
                    .foregroundColor(isFormValid ? .white : .wiseSecondaryText)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(isFormValid ? Color.wiseForestGreen : Color.wiseBorder)
                    )
                    .disabled(!isFormValid)
                }
            }
        }
        .sheet(isPresented: $showingCategoryPicker) {
            TransactionCategoryPickerSheet(selectedCategory: $selectedCategory, isPresented: $showingCategoryPicker)
        }
    }

    private func addTag() {
        let trimmed = newTag.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, !tags.contains(trimmed) else { return }
        tags.append(trimmed)
        newTag = ""
    }

    private func removeTag(_ tag: String) {
        tags.removeAll { $0 == tag }
    }

    private func updateTransaction() {
        guard let amountValue = Double(amount) else { return }

        let finalAmount = transactionType == .expense ? -abs(amountValue) : abs(amountValue)

        let updatedTransaction = Transaction(
            id: transaction.id,
            title: title.trimmingCharacters(in: .whitespaces),
            subtitle: subtitle.trimmingCharacters(in: .whitespaces),
            amount: finalAmount,
            category: selectedCategory,
            date: selectedDate,
            isRecurring: isRecurring,
            tags: tags,
            merchant: merchant.trimmingCharacters(in: .whitespaces).isEmpty ? nil : merchant.trimmingCharacters(in: .whitespaces),
            paymentStatus: paymentStatus,
            receiptData: receiptData,
            linkedSubscriptionId: linkedSubscriptionId
        )

        do {
            try dataManager.updateTransaction(updatedTransaction)
            onTransactionUpdated()
            dismiss()
        } catch {
            dataManager.error = error
        }
    }
}

// MARK: - Transaction Category Picker Sheet
struct TransactionCategoryPickerSheet: View {
    @Binding var selectedCategory: TransactionCategory
    @Binding var isPresented: Bool

    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    ForEach(TransactionCategory.allCases, id: \.self) { category in
                        Button(action: {
                            selectedCategory = category
                            isPresented = false
                        }) {
                            VStack(spacing: 12) {
                                Circle()
                                    .fill(category.color.opacity(0.2))
                                    .frame(width: 60, height: 60)
                                    .overlay(
                                        Image(systemName: category.icon)
                                            .font(.system(size: 24))
                                            .foregroundColor(category.color)
                                    )

                                Text(category.rawValue)
                                    .font(.spotifyLabelMedium)
                                    .foregroundColor(.wisePrimaryText)
                                    .multilineTextAlignment(.center)
                                    .lineLimit(2)
                            }
                            .padding(16)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(selectedCategory == category ? category.color.opacity(0.1) : Color.wiseCardBackground)
                                    .stroke(selectedCategory == category ? category.color : Color.wiseBorder, lineWidth: selectedCategory == category ? 2 : 1)
                            )
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
            .navigationTitle("Select Category")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        isPresented = false
                    }
                    .font(.spotifyLabelLarge)
                    .foregroundColor(.wiseForestGreen)
                }
            }
        }
    }
}

#Preview {
    EditTransactionSheet(
        transaction: Transaction(
            title: "Coffee",
            subtitle: "Morning coffee",
            amount: -5.50,
            category: .food,
            date: Date(),
            isRecurring: false,
            tags: ["coffee", "breakfast"]
        ),
        onTransactionUpdated: {}
    )
    .environmentObject(DataManager.shared)
}
