//
//  BulkActionsSheet.swift
//  Swiff IOS
//
//  Created for Page 2 Task 2.3
//  Bulk operations for selected transactions
//

import SwiftUI

struct BulkActionsSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataManager: DataManager

    let selectedTransactions: [Transaction]
    let onActionCompleted: () -> Void

    @State private var showingCategoryPicker = false
    @State private var showingTagInput = false
    @State private var showingDeleteConfirmation = false
    @State private var showingExportOptions = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // Header with selection count
                    selectionHeader

                    Divider()
                        .padding(.vertical, 16)

                    // Action buttons
                    VStack(spacing: 16) {
                        BulkActionButton(
                            icon: "trash.circle.fill",
                            title: "Delete Selected",
                            subtitle: "Permanently remove \(selectedTransactions.count) transaction\(selectedTransactions.count == 1 ? "" : "s")",
                            color: .wiseError
                        ) {
                            showingDeleteConfirmation = true
                        }

                        BulkActionButton(
                            icon: "folder.circle.fill",
                            title: "Change Category",
                            subtitle: "Update category for all selected",
                            color: .wiseBlue
                        ) {
                            showingCategoryPicker = true
                        }

                        BulkActionButton(
                            icon: "tag.circle.fill",
                            title: "Add Tags",
                            subtitle: "Add tags to all selected",
                            color: .wiseForestGreen
                        ) {
                            showingTagInput = true
                        }

                        BulkActionButton(
                            icon: "square.and.arrow.up.circle.fill",
                            title: "Export Selected",
                            subtitle: "Export as CSV file",
                            color: .wiseAccentOrange
                        ) {
                            showingExportOptions = true
                        }
                    }
                    .padding(.horizontal, 20)

                    Spacer(minLength: 40)
                }
                .padding(.top, 20)
            }
            .navigationTitle("Bulk Actions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.wiseSecondaryText)
                }
            }
        }
        .alert("Delete Transactions?", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                deleteSelected()
            }
        } message: {
            Text("Are you sure you want to delete \(selectedTransactions.count) transaction\(selectedTransactions.count == 1 ? "" : "s")? This action cannot be undone.")
        }
        .sheet(isPresented: $showingCategoryPicker) {
            BulkCategoryPickerSheet(transactions: selectedTransactions) { category in
                changeCategory(to: category)
            }
        }
        .sheet(isPresented: $showingTagInput) {
            BulkTagInputSheet(transactions: selectedTransactions) { tags in
                addTags(tags)
            }
        }
        .sheet(isPresented: $showingExportOptions) {
            ExportOptionsSheet(transactions: selectedTransactions)
        }
    }

    // MARK: - Selection Header
    private var selectionHeader: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48))
                .foregroundColor(.wiseForestGreen)

            Text("\(selectedTransactions.count) Selected")
                .font(.spotifyHeadingLarge)
                .foregroundColor(.wisePrimaryText)

            Text(totalAmountString)
                .font(.spotifyBodyMedium)
                .foregroundColor(.wiseSecondaryText)
        }
        .padding(.vertical, 20)
    }

    private var totalAmountString: String {
        let total = selectedTransactions.reduce(0) { $0 + $1.amount }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "$"
        return "Total: \(formatter.string(from: NSNumber(value: abs(total))) ?? "$0.00")"
    }

    // MARK: - Actions
    private func deleteSelected() {
        do {
            try dataManager.bulkDeleteTransactions(ids: selectedTransactions.map { $0.id })
            HapticManager.shared.success()
            onActionCompleted()
            dismiss()
        } catch {
            dataManager.error = error
            HapticManager.shared.error()
        }
    }

    private func changeCategory(to category: TransactionCategory) {
        do {
            try dataManager.bulkUpdateCategory(transactionIds: selectedTransactions.map { $0.id }, category: category)
            HapticManager.shared.success()
            onActionCompleted()
            dismiss()
        } catch {
            dataManager.error = error
            HapticManager.shared.error()
        }
    }

    private func addTags(_ tags: [String]) {
        do {
            try dataManager.bulkAddTags(transactionIds: selectedTransactions.map { $0.id }, tags: tags)
            HapticManager.shared.success()
            onActionCompleted()
            dismiss()
        } catch {
            dataManager.error = error
            HapticManager.shared.error()
        }
    }
}

// MARK: - Bulk Action Button
struct BulkActionButton: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: {
            HapticManager.shared.light()
            action()
        }) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 32))
                    .foregroundColor(color)
                    .frame(width: 50)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.spotifyBodyLarge)
                        .fontWeight(.semibold)
                        .foregroundColor(.wisePrimaryText)

                    Text(subtitle)
                        .font(.spotifyBodySmall)
                        .foregroundColor(.wiseSecondaryText)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.wiseSecondaryText)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.wiseCardBackground)
                    .cardShadow()
            )
        }
    }
}

// MARK: - Bulk Category Picker Sheet
struct BulkCategoryPickerSheet: View {
    @Environment(\.dismiss) var dismiss
    let transactions: [Transaction]
    let onCategorySelected: (TransactionCategory) -> Void

    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(TransactionCategory.allCases, id: \.self) { category in
                        Button(action: {
                            onCategorySelected(category)
                            dismiss()
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
                                    .fill(Color.wiseCardBackground)
                                    .stroke(Color.wiseBorder, lineWidth: 1)
                            )
                        }
                    }
                }
                .padding(20)
            }
            .navigationTitle("Select Category")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Bulk Tag Input Sheet
struct BulkTagInputSheet: View {
    @Environment(\.dismiss) var dismiss
    let transactions: [Transaction]
    let onTagsAdded: ([String]) -> Void

    @State private var tagInput = ""
    @State private var tags: [String] = []

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Add Tags")
                        .font(.spotifyHeadingMedium)
                        .foregroundColor(.wisePrimaryText)

                    HStack {
                        TextField("Enter tag", text: $tagInput)
                            .font(.spotifyBodyMedium)
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.wiseBorder.opacity(0.3))
                            )

                        Button(action: addTag) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 32))
                                .foregroundColor(.wiseForestGreen)
                        }
                        .disabled(tagInput.trimmingCharacters(in: .whitespaces).isEmpty)
                    }

                    if !tags.isEmpty {
                        FlowLayout(spacing: 8) {
                            ForEach(tags, id: \.self) { tag in
                                HStack(spacing: 4) {
                                    Text(tag)
                                        .font(.spotifyLabelMedium)
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
                .padding(.horizontal, 20)
                .padding(.top, 20)

                Spacer()

                Button(action: {
                    onTagsAdded(tags)
                    dismiss()
                }) {
                    Text("Add to \(transactions.count) Transaction\(transactions.count == 1 ? "" : "s")")
                        .font(.spotifyBodyMedium)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.wiseForestGreen)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
                .disabled(tags.isEmpty)
            }
            .navigationTitle("Add Tags")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func addTag() {
        let trimmed = tagInput.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, !tags.contains(trimmed) else { return }
        tags.append(trimmed)
        tagInput = ""
    }

    private func removeTag(_ tag: String) {
        tags.removeAll { $0 == tag }
    }
}

// MARK: - Export Options Sheet
struct ExportOptionsSheet: View {
    @Environment(\.dismiss) var dismiss
    let transactions: [Transaction]

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Text("Export \(transactions.count) transaction\(transactions.count == 1 ? "" : "s") as CSV")
                    .font(.spotifyBodyMedium)
                    .foregroundColor(.wiseSecondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .padding(.top, 40)

                Button(action: exportToCSV) {
                    HStack {
                        Image(systemName: "doc.text")
                        Text("Export to CSV")
                    }
                    .font(.spotifyBodyMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.wiseForestGreen)
                    .cornerRadius(12)
                }
                .padding(.horizontal, 40)

                Spacer()
            }
            .navigationTitle("Export")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func exportToCSV() {
        // CSV export logic will be handled by CSVExportService
        let csvService = CSVExportService()
        _ = csvService.exportTransactions(transactions)
        HapticManager.shared.success()
        dismiss()
    }
}

#Preview("Bulk Actions Sheet") {
    BulkActionsSheet(
        selectedTransactions: [MockData.expenseTransaction, MockData.groceryTransaction],
        onActionCompleted: {}
    )
    .environmentObject(DataManager.shared)
}
