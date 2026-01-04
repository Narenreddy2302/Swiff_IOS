//
//  AdvancedFilterSheet.swift
//  Swiff IOS
//
//  Created for Page 2 Task 2.2
//  Comprehensive advanced filtering for transactions
//

import SwiftUI

struct AdvancedFilterSheet: View {
    @Environment(\.dismiss) var dismiss
    @Binding var filter: AdvancedTransactionFilter
    @Binding var savedPresets: [FilterPreset]

    @State private var showingPresetSaveSheet = false
    @State private var showingDatePicker = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Filter Presets Section
                    if !savedPresets.isEmpty {
                        filterPresetsSection
                    }

                    // Active Filters Count
                    if filter.hasActiveFilters {
                        activeFiltersIndicator
                    }

                    // Date Range Section
                    dateRangeSection

                    // Amount Range Section
                    amountRangeSection

                    // Category Selection Section
                    categorySelectionSection

                    // Toggle Filters Section
                    toggleFiltersSection

                    // Status Selection Section
                    statusSelectionSection

                    // Transaction Type Section
                    transactionTypeSection

                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
            .navigationTitle("Advanced Filters")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Reset") {
                        withAnimation {
                            filter.reset()
                        }
                        HapticManager.shared.light()
                    }
                    .font(.spotifyLabelLarge)
                    .foregroundColor(filter.hasActiveFilters ? .wiseError : .wiseSecondaryText)
                    .disabled(!filter.hasActiveFilters)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.spotifyLabelLarge)
                    .fontWeight(.semibold)
                    .foregroundColor(.wiseForestGreen)
                }
            }
        }
        .sheet(isPresented: $showingPresetSaveSheet) {
            SaveFilterPresetSheet(filter: filter, savedPresets: $savedPresets)
        }
    }

    // MARK: - Filter Presets Section
    private var filterPresetsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Saved Presets")
                    .font(.spotifyHeadingMedium)
                    .foregroundColor(.wisePrimaryText)

                Spacer()

                Button(action: { showingPresetSaveSheet = true }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.wiseForestGreen)
                }
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(FilterPreset.defaults + savedPresets) { preset in
                        PresetButton(preset: preset) {
                            filter = preset.filter
                            HapticManager.shared.light()
                        }
                    }
                }
            }
        }
    }

    // MARK: - Active Filters Indicator
    private var activeFiltersIndicator: some View {
        HStack {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.wiseForestGreen)
            Text("\(filter.activeFilterCount) filter\(filter.activeFilterCount == 1 ? "" : "s") active")
                .font(.spotifyBodyMedium)
                .foregroundColor(.wisePrimaryText)

            Spacer()
        }
        .padding(12)
        .background(Color.wiseForestGreen.opacity(0.1))
        .cornerRadius(12)
    }

    // MARK: - Date Range Section
    private var dateRangeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Date Range")
                .font(.spotifyHeadingMedium)
                .foregroundColor(.wisePrimaryText)

            // Quick date range buttons
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(AdvancedTransactionFilter.DateRange.allCases.filter { $0 != .custom }, id: \.self) { range in
                    Button(action: {
                        filter.dateRange = range
                        filter.useCustomDateRange = false
                        HapticManager.shared.light()
                    }) {
                        Text(range.rawValue)
                            .font(.spotifyBodyMedium)
                            .foregroundColor(filter.dateRange == range && !filter.useCustomDateRange ? .white : .wisePrimaryText)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(filter.dateRange == range && !filter.useCustomDateRange ? Color.wiseBlue : Color.wiseBorder.opacity(0.3))
                            )
                    }
                }
            }

            // Custom date range
            Button(action: {
                showingDatePicker.toggle()
                HapticManager.shared.light()
            }) {
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(.wiseBlue)
                    Text(filter.useCustomDateRange ? "Custom: \(formattedCustomRange)" : "Custom Date Range")
                        .font(.spotifyBodyMedium)
                        .foregroundColor(.wisePrimaryText)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14))
                        .foregroundColor(.wiseSecondaryText)
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(filter.useCustomDateRange ? Color.wiseBlue.opacity(0.1) : Color.wiseBorder.opacity(0.3))
                )
            }

            if showingDatePicker {
                customDatePickerView
            }
        }
    }

    private var customDatePickerView: some View {
        VStack(spacing: 16) {
            DatePicker("Start Date", selection: Binding(
                get: { filter.customStartDate ?? Date() },
                set: { filter.customStartDate = $0; filter.useCustomDateRange = true; filter.dateRange = .custom }
            ), displayedComponents: .date)
                .datePickerStyle(.compact)

            DatePicker("End Date", selection: Binding(
                get: { filter.customEndDate ?? Date() },
                set: { filter.customEndDate = $0; filter.useCustomDateRange = true; filter.dateRange = .custom }
            ), displayedComponents: .date)
                .datePickerStyle(.compact)
        }
        .padding(12)
        .background(Color.wiseBlue.opacity(0.05))
        .cornerRadius(10)
    }

    private var formattedCustomRange: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        guard let start = filter.customStartDate, let end = filter.customEndDate else {
            return "Select dates"
        }
        return "\(formatter.string(from: start)) - \(formatter.string(from: end))"
    }

    // MARK: - Amount Range Section
    private var amountRangeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Amount Range")
                .font(.spotifyHeadingMedium)
                .foregroundColor(.wisePrimaryText)

            VStack(spacing: 16) {
                // Min amount
                VStack(alignment: .leading, spacing: 8) {
                    Text("Minimum Amount")
                        .font(.spotifyLabelMedium)
                        .foregroundColor(.wiseSecondaryText)

                    HStack {
                        Text("$")
                            .font(.spotifyBodyLarge)
                            .foregroundColor(.wisePrimaryText)

                        TextField("0.00", value: Binding(
                            get: { filter.minAmount ?? 0 },
                            set: { filter.minAmount = $0 > 0 ? $0 : nil }
                        ), format: .number)
                            .keyboardType(.decimalPad)
                            .font(.spotifyBodyLarge)
                            .foregroundColor(.wisePrimaryText)
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.wiseBorder.opacity(0.3))
                    )
                }

                // Max amount
                VStack(alignment: .leading, spacing: 8) {
                    Text("Maximum Amount")
                        .font(.spotifyLabelMedium)
                        .foregroundColor(.wiseSecondaryText)

                    HStack {
                        Text("$")
                            .font(.spotifyBodyLarge)
                            .foregroundColor(.wisePrimaryText)

                        TextField("999999", value: Binding(
                            get: { filter.maxAmount ?? 0 },
                            set: { filter.maxAmount = $0 > 0 ? $0 : nil }
                        ), format: .number)
                            .keyboardType(.decimalPad)
                            .font(.spotifyBodyLarge)
                            .foregroundColor(.wisePrimaryText)
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.wiseBorder.opacity(0.3))
                    )
                }
            }
        }
    }

    // MARK: - Category Selection Section
    private var categorySelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Categories")
                    .font(.spotifyHeadingMedium)
                    .foregroundColor(.wisePrimaryText)

                Spacer()

                Button(filter.filterAllCategories ? "Select All" : "Clear All") {
                    withAnimation {
                        if filter.filterAllCategories {
                            filter.selectedCategories = Set(TransactionCategory.allCases)
                            filter.filterAllCategories = false
                        } else {
                            filter.selectedCategories = []
                            filter.filterAllCategories = true
                        }
                    }
                    HapticManager.shared.light()
                }
                .font(.spotifyLabelMedium)
                .foregroundColor(.wiseBlue)
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(TransactionCategory.allCases, id: \.self) { category in
                    CategoryCheckbox(
                        category: category,
                        isSelected: filter.filterAllCategories || filter.selectedCategories.contains(category)
                    ) {
                        toggleCategory(category)
                    }
                }
            }
        }
    }

    private func toggleCategory(_ category: TransactionCategory) {
        if filter.filterAllCategories {
            filter.selectedCategories = Set(TransactionCategory.allCases)
            filter.selectedCategories.remove(category)
            filter.filterAllCategories = false
        } else {
            if filter.selectedCategories.contains(category) {
                filter.selectedCategories.remove(category)
            } else {
                filter.selectedCategories.insert(category)
            }

            if filter.selectedCategories.count == TransactionCategory.allCases.count {
                filter.filterAllCategories = true
                filter.selectedCategories = []
            }
        }
        HapticManager.shared.light()
    }

    // MARK: - Toggle Filters Section
    private var toggleFiltersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Additional Filters")
                .font(.spotifyHeadingMedium)
                .foregroundColor(.wisePrimaryText)

            ToggleFilterRow(
                icon: "camera.circle.fill",
                title: "Has Receipt",
                value: Binding(
                    get: { filter.hasReceipt },
                    set: { filter.hasReceipt = $0 }
                ),
                color: .wiseForestGreen
            )

            ToggleFilterRow(
                icon: "repeat.circle.fill",
                title: "Recurring Only",
                value: Binding(
                    get: { filter.isRecurring },
                    set: { filter.isRecurring = $0 }
                ),
                color: .wiseBlue
            )

            ToggleFilterRow(
                icon: "link.circle.fill",
                title: "Linked to Subscription",
                value: Binding(
                    get: { filter.isLinkedToSubscription },
                    set: { filter.isLinkedToSubscription = $0 }
                ),
                color: .wiseBlue
            )
        }
    }

    // MARK: - Status Selection Section
    private var statusSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Payment Status")
                .font(.spotifyHeadingMedium)
                .foregroundColor(.wisePrimaryText)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(PaymentStatus.allCases, id: \.self) { status in
                    StatusCheckbox(
                        status: status,
                        isSelected: filter.filterAllStatuses || filter.selectedStatuses.contains(status)
                    ) {
                        toggleStatus(status)
                    }
                }
            }
        }
    }

    private func toggleStatus(_ status: PaymentStatus) {
        if filter.filterAllStatuses {
            filter.selectedStatuses = Set(PaymentStatus.allCases)
            filter.selectedStatuses.remove(status)
            filter.filterAllStatuses = false
        } else {
            if filter.selectedStatuses.contains(status) {
                filter.selectedStatuses.remove(status)
            } else {
                filter.selectedStatuses.insert(status)
            }

            if filter.selectedStatuses.count == PaymentStatus.allCases.count {
                filter.filterAllStatuses = true
                filter.selectedStatuses = []
            }
        }
        HapticManager.shared.light()
    }

    // MARK: - Transaction Type Section
    private var transactionTypeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Transaction Type")
                .font(.spotifyHeadingMedium)
                .foregroundColor(.wisePrimaryText)

            HStack(spacing: 12) {
                ForEach([AdvancedTransactionFilter.TransactionTypeFilter.all, .expenses, .income], id: \.self) { type in
                    Button(action: {
                        filter.transactionType = type
                        HapticManager.shared.light()
                    }) {
                        Text(type.rawValue)
                            .font(.spotifyBodyMedium)
                            .foregroundColor(filter.transactionType == type ? .white : .wisePrimaryText)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(filter.transactionType == type ? Color.wiseForestGreen : Color.wiseBorder.opacity(0.3))
                            )
                    }
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct PresetButton: View {
    let preset: FilterPreset
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: preset.icon)
                    .font(.system(size: 24))
                    .foregroundColor(.wiseBlue)

                Text(preset.name)
                    .font(.spotifyLabelMedium)
                    .foregroundColor(.wisePrimaryText)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }
            .frame(width: 100)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.wiseBlue.opacity(0.1))
            )
        }
    }
}

struct CategoryCheckbox: View {
    let category: TransactionCategory
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? category.color : .wiseSecondaryText)

                Image(systemName: category.icon)
                    .font(.system(size: 16))
                    .foregroundColor(category.color)

                Text(category.rawValue)
                    .font(.spotifyLabelMedium)
                    .foregroundColor(.wisePrimaryText)
                    .lineLimit(1)

                Spacer()
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? category.color.opacity(0.1) : Color.wiseBorder.opacity(0.2))
            )
        }
    }
}

struct StatusCheckbox: View {
    let status: PaymentStatus
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? status.color : .wiseSecondaryText)

                Text(status.rawValue)
                    .font(.spotifyLabelMedium)
                    .foregroundColor(.wisePrimaryText)

                Spacer()
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? status.color.opacity(0.1) : Color.wiseBorder.opacity(0.2))
            )
        }
    }
}

struct ToggleFilterRow: View {
    let icon: String
    let title: String
    @Binding var value: Bool?
    let color: Color

    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)

            Text(title)
                .font(.spotifyBodyMedium)
                .foregroundColor(.wisePrimaryText)

            Spacer()

            // Three-state toggle: nil (off), true (yes), false (no)
            Button(action: {
                if value == nil {
                    value = true
                } else if value == true {
                    value = false
                } else {
                    value = nil
                }
                HapticManager.shared.light()
            }) {
                HStack(spacing: 4) {
                    if let val = value {
                        Image(systemName: val ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(val ? .wiseForestGreen : .wiseError)
                        Text(val ? "Yes" : "No")
                            .font(.spotifyLabelMedium)
                            .foregroundColor(val ? .wiseForestGreen : .wiseError)
                    } else {
                        Text("Any")
                            .font(.spotifyLabelMedium)
                            .foregroundColor(.wiseSecondaryText)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(value != nil ? (value! ? Color.wiseForestGreen.opacity(0.1) : Color.wiseError.opacity(0.1)) : Color.wiseBorder.opacity(0.2))
                )
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.wiseBorder.opacity(0.1))
        )
    }
}

// MARK: - Save Preset Sheet
struct SaveFilterPresetSheet: View {
    @Environment(\.dismiss) var dismiss
    let filter: AdvancedTransactionFilter
    @Binding var savedPresets: [FilterPreset]

    @State private var presetName = ""

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Preset Name")
                        .font(.spotifyHeadingMedium)
                        .foregroundColor(.wisePrimaryText)

                    TextField("e.g., Large Expenses", text: $presetName)
                        .font(.spotifyBodyMedium)
                        .foregroundColor(.wisePrimaryText)
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.wiseBorder.opacity(0.3))
                        )
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)

                Spacer()
            }
            .navigationTitle("Save Filter Preset")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        savePreset()
                    }
                    .disabled(presetName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func savePreset() {
        let preset = FilterPreset(name: presetName, filter: filter)
        savedPresets.append(preset)
        dismiss()
    }
}
