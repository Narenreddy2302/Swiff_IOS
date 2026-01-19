//
//  AddSubscriptionSheet.swift
//  Swiff IOS
//
//  Minimal subscription creation sheet - clean and simple
//

import SwiftUI

struct AddSubscriptionSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataManager: DataManager

    @Binding var showingAddSubscriptionSheet: Bool
    let onSubscriptionAdded: (Subscription) -> Void

    // MARK: - Essential State
    @State private var name = ""
    @State private var price = ""
    @State private var selectedCurrency: Currency = .USD
    @State private var selectedBillingCycle: BillingCycle = .monthly

    // MARK: - Quick Category State
    @State private var selectedCategory: SubscriptionCategory = .other
    @State private var selectedIcon = "app.fill"
    @State private var selectedColor = "#007AFF"

    // MARK: - UI State
    @State private var showingSuccess = false
    @State private var isSubmitting = false

    // MARK: - Quick Categories
    private let quickCategories: [SubscriptionCategory] = [
        .entertainment, .music, .cloud, .gaming, .productivity, .other
    ]

    // MARK: - Computed Properties

    private var generatedDescription: String {
        name.trimmingCharacters(in: .whitespaces).isEmpty
            ? "Subscription"
            : "\(name.trimmingCharacters(in: .whitespaces)) subscription"
    }

    private var isFormValid: Bool {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty,
              !price.trimmingCharacters(in: .whitespaces).isEmpty else {
            return false
        }
        guard let priceValue = Double(price), priceValue > 0 else {
            return false
        }
        return true
    }

    // MARK: - Body

    var body: some View {
        NavigationView {
            ZStack {
                if showingSuccess {
                    successView
                } else {
                    formContent
                }
            }
            .navigationTitle("Add Subscription")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                if !showingSuccess {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            showingAddSubscriptionSheet = false
                        }
                        .font(.spotifyLabelLarge)
                        .foregroundColor(.wiseSecondaryText)
                    }

                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Add") {
                            addSubscription()
                        }
                        .font(.spotifyLabelLarge)
                        .foregroundColor(isFormValid ? .white : .wiseSecondaryText)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(isFormValid ? Color.wiseForestGreen : Color.wiseBorder)
                        )
                        .disabled(!isFormValid || isSubmitting)
                    }
                }
            }
        }
    }

    // MARK: - Form Content

    private var formContent: some View {
        ScrollView {
            VStack(spacing: 24) {
                previewSection
                serviceDetailsSection
                quickCategorySection
                Spacer(minLength: 50)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
        }
    }

    // MARK: - Preview Section

    private var previewSection: some View {
        VStack(spacing: 16) {
            Text("Preview")
                .font(.spotifyHeadingMedium)
                .foregroundColor(.wisePrimaryText)

            HStack(spacing: 16) {
                Circle()
                    .fill(Color(hexString: selectedColor).opacity(0.15))
                    .frame(width: 48, height: 48)
                    .overlay(
                        Image(systemName: selectedIcon)
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(Color(hexString: selectedColor))
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text(name.isEmpty ? "Subscription Name" : name)
                        .font(.spotifyBodyLarge)
                        .foregroundColor(.wisePrimaryText)

                    Text(generatedDescription)
                        .font(.spotifyBodySmall)
                        .foregroundColor(.wiseSecondaryText)
                        .lineLimit(1)

                    HStack(spacing: 4) {
                        Image(systemName: selectedCategory.icon)
                            .font(.system(size: 12))
                            .foregroundColor(selectedCategory.color)

                        Text(selectedCategory.rawValue)
                            .font(.spotifyCaptionSmall)
                            .foregroundColor(.wiseSecondaryText)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(price.isEmpty ? "\(selectedCurrency.symbol)0.00" : selectedCurrency.format(Double(price) ?? 0))
                        .font(.spotifyNumberMedium)
                        .foregroundColor(.wisePrimaryText)

                    Text("/\(selectedBillingCycle.displayShort)")
                        .font(.spotifyCaptionSmall)
                        .foregroundColor(.wiseSecondaryText)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.wiseCardBackground)
                    .shadow(color: Color.wiseShadowColor, radius: 4, x: 0, y: 2)
            )
        }
    }

    // MARK: - Service Details Section

    private var serviceDetailsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Service Details")
                .font(.spotifyHeadingMedium)
                .foregroundColor(.wisePrimaryText)

            // Service Name
            VStack(alignment: .leading, spacing: 6) {
                Text("Service Name *")
                    .font(.spotifyLabelMedium)
                    .foregroundColor(.wiseSecondaryText)

                TextField("e.g., Netflix, Spotify, iCloud", text: $name)
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

            // Price and Currency Row
            HStack(spacing: 12) {
                // Price
                VStack(alignment: .leading, spacing: 6) {
                    Text("Price *")
                        .font(.spotifyLabelMedium)
                        .foregroundColor(.wiseSecondaryText)

                    HStack(spacing: 0) {
                        Text(selectedCurrency.symbol)
                            .font(.spotifyBodyMedium)
                            .foregroundColor(.wiseSecondaryText)
                            .padding(.leading, 16)

                        TextField("0.00", text: $price)
                            .font(.spotifyBodyMedium)
                            .foregroundColor(.wisePrimaryText)
                            .keyboardType(.decimalPad)
                            .padding(.vertical, 12)
                            .padding(.leading, 4)
                            .padding(.trailing, 16)
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.wiseBorder.opacity(0.5))
                            .stroke(Color.wiseBorder, lineWidth: 1)
                    )
                }

                // Currency
                VStack(alignment: .leading, spacing: 6) {
                    Text("Currency")
                        .font(.spotifyLabelMedium)
                        .foregroundColor(.wiseSecondaryText)

                    Menu {
                        ForEach(Currency.allCases, id: \.self) { currency in
                            Button(action: { selectedCurrency = currency }) {
                                HStack {
                                    Text(currency.flag)
                                    Text("\(currency.rawValue) - \(currency.name)")
                                }
                            }
                        }
                    } label: {
                        HStack {
                            Text(selectedCurrency.flag)
                            Text(selectedCurrency.rawValue)
                                .font(.spotifyBodyMedium)
                                .foregroundColor(.wisePrimaryText)
                            Image(systemName: "chevron.down")
                                .font(.system(size: 12, weight: .medium))
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

            // Billing Cycle
            VStack(alignment: .leading, spacing: 6) {
                Text("Billing Cycle")
                    .font(.spotifyLabelMedium)
                    .foregroundColor(.wiseSecondaryText)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach([BillingCycle.monthly, .quarterly, .yearly], id: \.self) { cycle in
                            Button(action: { selectedBillingCycle = cycle }) {
                                Text(cycle.displayName)
                                    .font(.spotifyLabelMedium)
                                    .foregroundColor(selectedBillingCycle == cycle ? .white : .wisePrimaryText)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(selectedBillingCycle == cycle ? Color.wiseForestGreen : Color.wiseBorder.opacity(0.5))
                                            .stroke(selectedBillingCycle == cycle ? Color.wiseForestGreen : Color.wiseBorder, lineWidth: 1)
                                    )
                            }
                        }

                        // More options menu
                        Menu {
                            ForEach(BillingCycle.allCases, id: \.self) { cycle in
                                Button(cycle.displayName) {
                                    selectedBillingCycle = cycle
                                }
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Text("More")
                                    .font(.spotifyLabelMedium)
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 10))
                            }
                            .foregroundColor(.wiseSecondaryText)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.wiseBorder.opacity(0.5))
                                    .stroke(Color.wiseBorder, lineWidth: 1)
                            )
                        }
                    }
                }
            }
        }
    }

    // MARK: - Quick Category Section

    private var quickCategorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Category")
                .font(.spotifyLabelMedium)
                .foregroundColor(.wiseSecondaryText)

            HStack(spacing: 8) {
                ForEach(quickCategories, id: \.self) { category in
                    Button(action: {
                        HapticManager.shared.selection()
                        selectedCategory = category
                        selectedIcon = category.icon
                        // Update color based on category
                        selectedColor = colorHexForCategory(category)
                    }) {
                        VStack(spacing: 6) {
                            Image(systemName: category.icon)
                                .font(.system(size: 18))
                                .foregroundColor(selectedCategory == category ? category.color : .wiseSecondaryText)

                            Text(categoryShortName(category))
                                .font(.spotifyCaptionSmall)
                                .foregroundColor(selectedCategory == category ? .wisePrimaryText : .wiseSecondaryText)
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(selectedCategory == category ? category.color.opacity(0.1) : Color.wiseBorder.opacity(0.3))
                                .stroke(selectedCategory == category ? category.color.opacity(0.5) : Color.clear, lineWidth: 1)
                        )
                    }
                }
            }
        }
    }

    // MARK: - Success View

    private var successView: some View {
        VStack(spacing: 20) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.wiseForestGreen)
                    .frame(width: 80, height: 80)

                Image(systemName: "checkmark")
                    .font(.system(size: 36, weight: .semibold))
                    .foregroundColor(.white)
            }
            .scaleEffect(showingSuccess ? 1 : 0)
            .animation(.spring(response: 0.4, dampingFraction: 0.6), value: showingSuccess)

            VStack(spacing: 8) {
                Text("Added!")
                    .font(.spotifyDisplayMedium)
                    .foregroundColor(.wisePrimaryText)

                Text("\(name) \u{2022} \(selectedCurrency.symbol)\(price)/\(selectedBillingCycle.displayShort)")
                    .font(.spotifyBodyMedium)
                    .foregroundColor(.wiseSecondaryText)
            }
            .opacity(showingSuccess ? 1 : 0)
            .animation(.easeIn(duration: 0.3).delay(0.2), value: showingSuccess)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.wiseBackground)
    }

    // MARK: - Helper Functions

    private func categoryShortName(_ category: SubscriptionCategory) -> String {
        switch category {
        case .entertainment: return "TV"
        case .music: return "Music"
        case .cloud: return "Cloud"
        case .gaming: return "Gaming"
        case .productivity: return "Work"
        case .other: return "Other"
        default: return String(category.rawValue.prefix(6))
        }
    }

    private func colorHexForCategory(_ category: SubscriptionCategory) -> String {
        switch category {
        case .entertainment: return "#9B59B6" // Purple
        case .productivity: return "#00B9FF" // Blue
        case .fitness: return "#FF4436" // Red
        case .health: return "#FF6961" // Light Red
        case .education: return "#FF9700" // Orange
        case .news: return "#3C3C3C" // Gray
        case .music: return "#E31E75" // Pink
        case .cloud: return "#78C51C" // GREEN 3
        case .gaming: return "#9B59B6" // Purple
        case .design: return "#E31E75" // Pink
        case .development: return "#043F2E" // GREEN 5
        case .finance: return "#78C51C" // GREEN 3
        case .utilities: return "#A52A2A" // Brown
        case .other: return "#808080" // Medium Gray
        }
    }

    // MARK: - Actions

    private func addSubscription() {
        guard let priceValue = Double(price) else { return }

        isSubmitting = true
        HapticManager.shared.impact(.medium)

        let newSubscription = Subscription(
            name: name.trimmingCharacters(in: .whitespaces),
            description: generatedDescription,
            price: priceValue,
            billingCycle: selectedBillingCycle,
            category: selectedCategory,
            icon: selectedIcon,
            color: selectedColor
        )

        // Show success animation
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            showingSuccess = true
        }

        // Save and dismiss
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onSubscriptionAdded(newSubscription)
            HapticManager.shared.success()

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                showingAddSubscriptionSheet = false
            }
        }
    }
}

// MARK: - Preview

#Preview("Add Subscription Sheet") {
    AddSubscriptionSheet(
        showingAddSubscriptionSheet: .constant(true),
        onSubscriptionAdded: { _ in }
    )
    .environmentObject(DataManager.shared)
}
