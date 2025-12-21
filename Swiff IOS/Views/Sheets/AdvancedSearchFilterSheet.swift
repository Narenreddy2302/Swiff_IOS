//
//  AdvancedSearchFilterSheet.swift
//  Swiff IOS
//
//  Created by Agent 12 on 11/21/25.
//  Advanced search filters sheet with date, amount, status, and category filters
//

import SwiftUI
import Combine

// MARK: - Advanced Search Filter Sheet

struct AdvancedSearchFilterSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var dataManager: DataManager

    @Binding var filters: SearchFilters

    // Local state for temporary filter changes
    @State private var tempFilters: SearchFilters

    // Available filter options (computed from data)
    private var availableCategories: [String] {
        let subscriptionCategories = Set(dataManager.subscriptions.map { $0.category.rawValue })
        let transactionCategories = Set(dataManager.transactions.map { $0.category.rawValue })
        return Array(subscriptionCategories.union(transactionCategories)).sorted()
    }

    private var availableTags: [String] {
        let allTags = dataManager.transactions.flatMap { $0.tags }
        return Array(Set(allTags)).sorted()
    }

    private var availablePaymentMethods: [String] {
        let methods = Set(dataManager.subscriptions.map { $0.paymentMethod.rawValue })
        return Array(methods).sorted()
    }

    init(filters: Binding<SearchFilters>) {
        self._filters = filters
        self._tempFilters = State(initialValue: filters.wrappedValue)
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Result Type Filter
                    resultTypeSection

                    Divider()

                    // Category Filter
                    categorySection

                    Divider()

                    // Date Range Filter
                    dateRangeSection

                    Divider()

                    // Amount Range Filter
                    amountRangeSection

                    Divider()

                    // Status Filter
                    statusSection

                    Divider()

                    // Tags Filter
                    if !availableTags.isEmpty {
                        tagsSection
                        Divider()
                    }

                    // Payment Method Filter
                    if !availablePaymentMethods.isEmpty {
                        paymentMethodSection
                    }
                }
                .padding(.vertical, 20)
            }
            .navigationTitle("Advanced Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Reset") {
                        tempFilters.reset()
                    }
                    .disabled(!tempFilters.isActive)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Apply") {
                        applyFilters()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }

    // MARK: - Result Type Section

    private var resultTypeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "Search In", icon: "line.3.horizontal.decrease.circle.fill")

            VStack(spacing: 12) {
                ForEach(SearchResultType.allCases, id: \.self) { type in
                    FilterToggleRow(
                        title: type.rawValue,
                        icon: type.icon,
                        isSelected: tempFilters.resultTypes.contains(type)
                    ) {
                        toggleResultType(type)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Category Section

    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "Categories", icon: "folder.fill")

            if availableCategories.isEmpty {
                Text("No categories available")
                    .font(.system(size: 14))
                    .foregroundColor(.wiseSecondaryText)
                    .padding(.vertical, 8)
            } else {
                FlowLayout(spacing: 8) {
                    ForEach(availableCategories, id: \.self) { category in
                        FilterChip(
                            title: category,
                            isSelected: tempFilters.selectedCategories.contains(category)
                        ) {
                            toggleCategory(category)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Date Range Section

    private var dateRangeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "Date Range", icon: "calendar")

            VStack(spacing: 16) {
                // Start Date
                DatePicker(
                    "From",
                    selection: Binding(
                        get: { tempFilters.startDate ?? Date().addingTimeInterval(-30*24*60*60) },
                        set: { tempFilters.startDate = $0 }
                    ),
                    displayedComponents: .date
                )
                .datePickerStyle(.compact)

                // End Date
                DatePicker(
                    "To",
                    selection: Binding(
                        get: { tempFilters.endDate ?? Date() },
                        set: { tempFilters.endDate = $0 }
                    ),
                    displayedComponents: .date
                )
                .datePickerStyle(.compact)

                // Clear button
                if tempFilters.startDate != nil || tempFilters.endDate != nil {
                    Button("Clear Date Range") {
                        tempFilters.startDate = nil
                        tempFilters.endDate = nil
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.wiseError)
                }
            }
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Amount Range Section

    private var amountRangeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "Amount Range", icon: "dollarsign.circle.fill")

            VStack(spacing: 16) {
                // Minimum Amount
                HStack {
                    Text("Min:")
                        .font(.system(size: 15, weight: .medium))
                        .frame(width: 50, alignment: .leading)

                    TextField("0.00", value: Binding(
                        get: { tempFilters.minAmount ?? 0 },
                        set: { tempFilters.minAmount = $0 > 0 ? $0 : nil }
                    ), format: .currency(code: "USD"))
                    .keyboardType(.decimalPad)
                    .textFieldStyle(.roundedBorder)
                }

                // Maximum Amount
                HStack {
                    Text("Max:")
                        .font(.system(size: 15, weight: .medium))
                        .frame(width: 50, alignment: .leading)

                    TextField("0.00", value: Binding(
                        get: { tempFilters.maxAmount ?? 0 },
                        set: { tempFilters.maxAmount = $0 > 0 ? $0 : nil }
                    ), format: .currency(code: "USD"))
                    .keyboardType(.decimalPad)
                    .textFieldStyle(.roundedBorder)
                }

                // Clear button
                if tempFilters.minAmount != nil || tempFilters.maxAmount != nil {
                    Button("Clear Amount Range") {
                        tempFilters.minAmount = nil
                        tempFilters.maxAmount = nil
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.wiseError)
                }
            }
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Status Section

    private var statusSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "Status", icon: "checkmark.circle.fill")

            VStack(spacing: 12) {
                FilterToggleRow(
                    title: "Active",
                    icon: "checkmark.circle.fill",
                    isSelected: tempFilters.statusFilters.contains("active")
                ) {
                    toggleStatus("active")
                }

                FilterToggleRow(
                    title: "Paused",
                    icon: "pause.circle.fill",
                    isSelected: tempFilters.statusFilters.contains("paused")
                ) {
                    toggleStatus("paused")
                }

                FilterToggleRow(
                    title: "Cancelled",
                    icon: "xmark.circle.fill",
                    isSelected: tempFilters.statusFilters.contains("cancelled")
                ) {
                    toggleStatus("cancelled")
                }
            }
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Tags Section

    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "Tags", icon: "tag.fill")

            FlowLayout(spacing: 8) {
                ForEach(availableTags, id: \.self) { tag in
                    FilterChip(
                        title: tag,
                        isSelected: tempFilters.selectedTags.contains(tag)
                    ) {
                        toggleTag(tag)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Payment Method Section

    private var paymentMethodSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "Payment Methods", icon: "creditcard.fill")

            FlowLayout(spacing: 8) {
                ForEach(availablePaymentMethods, id: \.self) { method in
                    FilterChip(
                        title: method,
                        isSelected: tempFilters.paymentMethods.contains(method)
                    ) {
                        togglePaymentMethod(method)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Helper Views

    private func sectionHeader(title: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.wiseBrightGreen)

            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.wisePrimaryText)
        }
    }

    // MARK: - Actions

    private func toggleResultType(_ type: SearchResultType) {
        if tempFilters.resultTypes.contains(type) {
            // Don't allow removing all types
            if tempFilters.resultTypes.count > 1 {
                tempFilters.resultTypes.remove(type)
            }
        } else {
            tempFilters.resultTypes.insert(type)
        }
    }

    private func toggleCategory(_ category: String) {
        if tempFilters.selectedCategories.contains(category) {
            tempFilters.selectedCategories.remove(category)
        } else {
            tempFilters.selectedCategories.insert(category)
        }
    }

    private func toggleStatus(_ status: String) {
        if tempFilters.statusFilters.contains(status) {
            tempFilters.statusFilters.remove(status)
        } else {
            tempFilters.statusFilters.insert(status)
        }
    }

    private func toggleTag(_ tag: String) {
        if tempFilters.selectedTags.contains(tag) {
            tempFilters.selectedTags.remove(tag)
        } else {
            tempFilters.selectedTags.insert(tag)
        }
    }

    private func togglePaymentMethod(_ method: String) {
        if tempFilters.paymentMethods.contains(method) {
            tempFilters.paymentMethods.remove(method)
        } else {
            tempFilters.paymentMethods.insert(method)
        }
    }

    private func applyFilters() {
        filters = tempFilters
        dismiss()
    }
}

// MARK: - Filter Toggle Row

struct FilterToggleRow: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(isSelected ? .wiseBrightGreen : .wiseSecondaryText)
                    .frame(width: 24)

                Text(title)
                    .font(.system(size: 15))
                    .foregroundColor(.wisePrimaryText)

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? .wiseBrightGreen : .wiseMidGray.opacity(0.5))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(isSelected ? Color.wiseBrightGreen.opacity(0.1) : Color.wiseBorder.opacity(0.3))
            .cornerRadius(10)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Filter Chip

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isSelected ? .white : .wisePrimaryText)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(isSelected ? Color.wiseBrightGreen : Color.wiseBorder.opacity(0.5))
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isSelected ? Color.clear : Color.wiseMidGray.opacity(0.5), lineWidth: 1)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Flow Layout

// Note: FlowLayout is defined in TransactionDetailView.swift

#Preview("Advanced Search Filter Sheet") {
    AdvancedSearchFilterSheet(filters: .constant(SearchFilters()))
        .environmentObject(DataManager.shared)
}
