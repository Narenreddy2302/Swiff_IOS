//
//  AddSubscriptionSheet.swift
//  Swiff IOS
//
//  Enhanced subscription creation sheet with all features
//

import SwiftUI

struct AddSubscriptionSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataManager: DataManager

    @Binding var showingAddSubscriptionSheet: Bool
    let onSubscriptionAdded: (Subscription) -> Void

    // MARK: - Basic Info State
    @State private var name = ""
    @State private var description = ""
    @State private var price = ""
    @State private var selectedCurrency: Currency = .USD
    @State private var selectedBillingCycle: BillingCycle = .monthly

    // MARK: - Appearance State
    @State private var selectedCategory: SubscriptionCategory = .other
    @State private var selectedIcon = "app.fill"
    @State private var selectedColor = "#007AFF"
    @State private var showingIconPicker = false

    // MARK: - Account Selection State
    @State private var selectedAccount: Account? = nil
    @State private var showingAccountSheet = false

    // MARK: - Shared Subscription State
    @State private var isShared = false
    @State private var selectedPeople: [Person] = []
    @State private var showingPersonPicker = false

    // MARK: - Free Trial State
    @State private var isFreeTrial = false
    @State private var trialStartDate = Date()
    @State private var trialEndDate = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
    @State private var willConvertToPaid = true
    @State private var priceAfterTrial = ""

    // MARK: - Reminder State
    @State private var enableRenewalReminder = false
    @State private var reminderDaysBefore = 3
    @State private var reminderTime = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()

    // MARK: - Additional State
    @State private var website = ""
    @State private var notes = ""
    @State private var selectedPaymentMethod: PaymentMethod = .creditCard

    // MARK: - Success Animation State
    @State private var showingSuccess = false
    @State private var isSubmitting = false

    // MARK: - Constants
    let availableIcons = [
        "app.fill", "tv.fill", "music.note", "camera.fill", "icloud.fill",
        "paintbrush.fill", "doc.text.fill", "brain.head.profile", "gamecontroller.fill",
        "newspaper.fill", "creditcard.fill", "car.fill", "house.fill",
        "heart.fill", "graduationcap.fill", "wrench.and.screwdriver.fill",
        "chevron.left.forwardslash.chevron.right", "play.rectangle.fill"
    ]

    let availableColors = [
        "#007AFF", "#FF3B30", "#FF9500", "#FFCC00", "#34C759",
        "#5AC8FA", "#AF52DE", "#FF2D92", "#A2845E", "#8E8E93",
        "#E50914", "#1DB954", "#FF0000", "#181717", "#FF7262",
        "#113CCF", "#000000", "#FF6B35"
    ]

    // MARK: - Computed Properties

    private var isFormValid: Bool {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty,
              !description.trimmingCharacters(in: .whitespaces).isEmpty,
              !price.trimmingCharacters(in: .whitespaces).isEmpty else {
            return false
        }

        // Allow price to be 0 if free trial
        if isFreeTrial {
            return true
        }

        guard let priceValue = Double(price) else {
            return false
        }
        return priceValue > 0
    }

    private var trialDuration: Int {
        let components = Calendar.current.dateComponents([.day], from: trialStartDate, to: trialEndDate)
        return max(0, components.day ?? 0)
    }

    private var isTrialExpiringSoon: Bool {
        guard isFreeTrial else { return false }
        let daysUntilEnd = Calendar.current.dateComponents([.day], from: Date(), to: trialEndDate).day ?? 0
        return daysUntilEnd < 3 && daysUntilEnd >= 0
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
        .sheet(isPresented: $showingAccountSheet) {
            AccountSelectionSheet(
                selectedAccount: $selectedAccount,
                onAccountSelected: { account in
                    selectedAccount = account
                }
            )
        }
        .sheet(isPresented: $showingPersonPicker) {
            PersonPickerSheet(
                selectedPeople: $selectedPeople,
                availablePeople: dataManager.people
            )
        }
    }

    // MARK: - Form Content

    private var formContent: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Preview Card
                previewSection

                // Basic Information
                basicInfoSection

                // Pay From (Account Selection)
                payFromSection

                // Category & Appearance
                appearanceSection

                // Shared Subscription
                sharedSection

                // Free Trial Settings
                trialSection

                // Reminders
                remindersSection

                // Additional Options
                additionalSection

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

                    Text(description.isEmpty ? "Description" : description)
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

    // MARK: - Basic Info Section

    private var basicInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Basic Information")
                .font(.spotifyHeadingMedium)
                .foregroundColor(.wisePrimaryText)

            // Name
            VStack(alignment: .leading, spacing: 6) {
                Text("Service Name *")
                    .font(.spotifyLabelMedium)
                    .foregroundColor(.wiseSecondaryText)

                TextField("e.g., Netflix", text: $name)
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

            // Description
            VStack(alignment: .leading, spacing: 6) {
                Text("Description *")
                    .font(.spotifyLabelMedium)
                    .foregroundColor(.wiseSecondaryText)

                TextField("e.g., Premium streaming plan", text: $description)
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

    // MARK: - Pay From Section

    private var payFromSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Pay From")
                .font(.spotifyHeadingMedium)
                .foregroundColor(.wisePrimaryText)

            Button(action: {
                HapticManager.shared.light()
                showingAccountSheet = true
            }) {
                HStack(spacing: 14) {
                    if let account = selectedAccount {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(account.type.color.opacity(0.1))
                                .frame(width: 40, height: 40)

                            Image(systemName: account.type.icon)
                                .font(.system(size: 18))
                                .foregroundColor(account.type.color)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(account.name)
                                .font(.spotifyBodyMedium)
                                .fontWeight(.semibold)
                                .foregroundColor(.wisePrimaryText)

                            if !account.number.isEmpty {
                                Text(account.number)
                                    .font(.spotifyCaptionMedium)
                                    .foregroundColor(.wiseSecondaryText)
                            }
                        }
                    } else {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.wiseBorder.opacity(0.5))
                                .frame(width: 40, height: 40)

                            Image(systemName: "creditcard.fill")
                                .font(.system(size: 18))
                                .foregroundColor(.wiseSecondaryText)
                        }

                        Text("Select account")
                            .font(.spotifyBodyMedium)
                            .foregroundColor(.wisePlaceholderText)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.wiseSecondaryText)
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.wiseBorder.opacity(0.5))
                        .stroke(Color.wiseBorder, lineWidth: 1)
                )
            }
        }
    }

    // MARK: - Appearance Section

    private var appearanceSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Category & Appearance")
                .font(.spotifyHeadingMedium)
                .foregroundColor(.wisePrimaryText)

            // Category Selection
            VStack(alignment: .leading, spacing: 8) {
                Text("Category")
                    .font(.spotifyLabelMedium)
                    .foregroundColor(.wiseSecondaryText)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    ForEach(SubscriptionCategory.allCases.prefix(8), id: \.self) { category in
                        Button(action: { selectedCategory = category }) {
                            HStack(spacing: 10) {
                                Image(systemName: category.icon)
                                    .font(.system(size: 14))
                                    .foregroundColor(category.color)

                                Text(category.rawValue)
                                    .font(.spotifyCaptionLarge)
                                    .foregroundColor(.wisePrimaryText)
                                    .lineLimit(1)

                                Spacer()
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(selectedCategory == category ? category.color.opacity(0.1) : Color.wiseBorder.opacity(0.5))
                                    .stroke(selectedCategory == category ? category.color : Color.clear, lineWidth: 1)
                            )
                        }
                    }
                }

                // More categories
                Menu {
                    ForEach(SubscriptionCategory.allCases, id: \.self) { category in
                        Button(action: { selectedCategory = category }) {
                            Label(category.rawValue, systemImage: category.icon)
                        }
                    }
                } label: {
                    HStack {
                        Text("More categories...")
                            .font(.spotifyCaptionLarge)
                            .foregroundColor(.wiseBlue)
                    }
                }
                .padding(.top, 4)
            }

            // Icon Selection
            VStack(alignment: .leading, spacing: 8) {
                Text("Icon")
                    .font(.spotifyLabelMedium)
                    .foregroundColor(.wiseSecondaryText)

                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 9), spacing: 8) {
                    ForEach(availableIcons, id: \.self) { icon in
                        Button(action: { selectedIcon = icon }) {
                            Image(systemName: icon)
                                .font(.system(size: 16))
                                .foregroundColor(selectedIcon == icon ? Color(hexString: selectedColor) : .wiseSecondaryText)
                                .frame(width: 32, height: 32)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(selectedIcon == icon ? Color(hexString: selectedColor).opacity(0.1) : Color.wiseBorder.opacity(0.5))
                                        .stroke(selectedIcon == icon ? Color(hexString: selectedColor) : Color.clear, lineWidth: 1)
                                )
                        }
                    }
                }
            }

            // Color Selection
            VStack(alignment: .leading, spacing: 8) {
                Text("Color")
                    .font(.spotifyLabelMedium)
                    .foregroundColor(.wiseSecondaryText)

                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 9), spacing: 8) {
                    ForEach(availableColors, id: \.self) { color in
                        Button(action: { selectedColor = color }) {
                            Circle()
                                .fill(Color(hexString: color))
                                .frame(width: 28, height: 28)
                                .overlay(
                                    Circle()
                                        .stroke(selectedColor == color ? Color.wisePrimaryText : Color.clear, lineWidth: 2)
                                        .frame(width: 32, height: 32)
                                )
                        }
                    }
                }
            }
        }
    }

    // MARK: - Shared Section

    private var sharedSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Shared Toggle
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Shared Subscription")
                        .font(.spotifyBodyMedium)
                        .foregroundColor(.wisePrimaryText)

                    Text("Split costs with others")
                        .font(.spotifyCaptionMedium)
                        .foregroundColor(.wiseSecondaryText)
                }

                Spacer()

                Toggle("", isOn: $isShared)
                    .tint(.wiseForestGreen)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.wiseBorder.opacity(0.5))
                    .stroke(Color.wiseBorder, lineWidth: 1)
            )

            // Person Selection (when shared)
            if isShared {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Share With")
                            .font(.spotifyLabelMedium)
                            .foregroundColor(.wiseSecondaryText)

                        Spacer()

                        if !selectedPeople.isEmpty {
                            Text("$\(String(format: "%.2f", (Double(price) ?? 0) / Double(selectedPeople.count + 1)))/person")
                                .font(.spotifyCaptionMedium)
                                .foregroundColor(.wiseBrightGreen)
                        }
                    }

                    // Selected People
                    if !selectedPeople.isEmpty {
                        VStack(spacing: 8) {
                            ForEach(selectedPeople) { person in
                                PersonSelectionChip(
                                    person: person,
                                    showRemove: true,
                                    onRemove: {
                                        selectedPeople.removeAll { $0.id == person.id }
                                    }
                                )
                            }
                        }
                    }

                    // Add Person Button
                    Button(action: {
                        HapticManager.shared.light()
                        showingPersonPicker = true
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.wiseBlue)

                            Text(selectedPeople.isEmpty ? "Add people to share with" : "Add more people")
                                .font(.spotifyBodyMedium)
                                .foregroundColor(.wiseBlue)

                            Spacer()
                        }
                        .padding(14)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.wiseBlue.opacity(0.05))
                                .stroke(Color.wiseBlue.opacity(0.3), lineWidth: 1)
                        )
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.easeInOut(duration: 0.25), value: isShared)
    }

    // MARK: - Trial Section

    private var trialSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Free Trial Settings")
                .font(.spotifyHeadingMedium)
                .foregroundColor(.wisePrimaryText)

            // Free Trial Toggle
            Toggle(isOn: $isFreeTrial) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Image(systemName: "gift.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.wiseOrange)
                        Text("Free Trial")
                            .font(.spotifyBodyMedium)
                            .foregroundColor(.wisePrimaryText)
                    }
                    Text("This subscription starts with a free trial")
                        .font(.spotifyCaptionMedium)
                        .foregroundColor(.wiseSecondaryText)
                }
            }
            .tint(.wiseOrange)

            if isFreeTrial {
                VStack(spacing: 16) {
                    // Trial Start Date
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Trial Start Date")
                            .font(.spotifyLabelMedium)
                            .foregroundColor(.wiseSecondaryText)

                        DatePicker("", selection: $trialStartDate, displayedComponents: .date)
                            .datePickerStyle(.compact)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.wiseBorder.opacity(0.5))
                                    .stroke(Color.wiseBorder, lineWidth: 1)
                            )
                    }

                    // Trial End Date
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Trial End Date")
                            .font(.spotifyLabelMedium)
                            .foregroundColor(.wiseSecondaryText)

                        DatePicker("", selection: $trialEndDate, in: trialStartDate..., displayedComponents: .date)
                            .datePickerStyle(.compact)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.wiseBorder.opacity(0.5))
                                    .stroke(Color.wiseBorder, lineWidth: 1)
                            )
                    }

                    // Trial Duration Display
                    HStack {
                        Image(systemName: "calendar.badge.clock")
                            .font(.system(size: 16))
                            .foregroundColor(.wiseOrange)
                        Text("\(trialDuration) days")
                            .font(.spotifyBodyMedium)
                            .foregroundColor(.wisePrimaryText)
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.wiseOrange.opacity(0.1))
                            .stroke(Color.wiseOrange.opacity(0.3), lineWidth: 1)
                    )

                    // Trial expiration warning
                    if isTrialExpiringSoon {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.wiseOrange)
                            Text("Trial expires in less than 3 days!")
                                .font(.spotifyCaptionMedium)
                                .foregroundColor(.wiseOrange)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.wiseOrange.opacity(0.1))
                        )
                    }

                    // Convert to Paid Toggle
                    Toggle(isOn: $willConvertToPaid) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Convert to Paid After Trial")
                                .font(.spotifyBodyMedium)
                                .foregroundColor(.wisePrimaryText)
                            Text("Automatically switch to paid subscription")
                                .font(.spotifyCaptionMedium)
                                .foregroundColor(.wiseSecondaryText)
                        }
                    }
                    .tint(.wiseForestGreen)

                    // Price After Trial
                    if willConvertToPaid {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Price After Trial (Optional)")
                                .font(.spotifyLabelMedium)
                                .foregroundColor(.wiseSecondaryText)

                            HStack(spacing: 0) {
                                Text(selectedCurrency.symbol)
                                    .font(.spotifyBodyMedium)
                                    .foregroundColor(.wiseSecondaryText)
                                    .padding(.leading, 16)

                                TextField("Same as current price", text: $priceAfterTrial)
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

                            Text("Leave empty if price remains the same")
                                .font(.spotifyCaptionSmall)
                                .foregroundColor(.wiseTertiaryText)
                        }
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.easeInOut(duration: 0.25), value: isFreeTrial)
    }

    // MARK: - Reminders Section

    private var remindersSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Reminders")
                .font(.spotifyHeadingMedium)
                .foregroundColor(.wisePrimaryText)

            Toggle(isOn: $enableRenewalReminder) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Image(systemName: "bell.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.wiseBlue)
                        Text("Enable Renewal Reminders")
                            .font(.spotifyBodyMedium)
                            .foregroundColor(.wisePrimaryText)
                    }
                    Text("Get notified before this subscription renews")
                        .font(.spotifyCaptionMedium)
                        .foregroundColor(.wiseSecondaryText)
                }
            }
            .tint(.wiseBlue)

            if enableRenewalReminder {
                VStack(spacing: 16) {
                    // Remind Me Picker
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Remind Me")
                            .font(.spotifyLabelMedium)
                            .foregroundColor(.wiseSecondaryText)

                        Picker("Remind me", selection: $reminderDaysBefore) {
                            Text("1 day before").tag(1)
                            Text("3 days before").tag(3)
                            Text("7 days before").tag(7)
                            Text("14 days before").tag(14)
                            Text("30 days before").tag(30)
                        }
                        .pickerStyle(.menu)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.wiseBorder.opacity(0.5))
                                .stroke(Color.wiseBorder, lineWidth: 1)
                        )
                    }

                    // Reminder Time
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Reminder Time")
                            .font(.spotifyLabelMedium)
                            .foregroundColor(.wiseSecondaryText)

                        DatePicker("", selection: $reminderTime, displayedComponents: .hourAndMinute)
                            .datePickerStyle(.compact)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.wiseBorder.opacity(0.5))
                                    .stroke(Color.wiseBorder, lineWidth: 1)
                            )
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.easeInOut(duration: 0.25), value: enableRenewalReminder)
    }

    // MARK: - Additional Section

    private var additionalSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Additional Options")
                .font(.spotifyHeadingMedium)
                .foregroundColor(.wisePrimaryText)

            // Payment Method
            VStack(alignment: .leading, spacing: 6) {
                Text("Payment Method")
                    .font(.spotifyLabelMedium)
                    .foregroundColor(.wiseSecondaryText)

                Picker("Payment Method", selection: $selectedPaymentMethod) {
                    ForEach(PaymentMethod.allCases, id: \.self) { method in
                        HStack {
                            Image(systemName: method.icon)
                            Text(method.rawValue)
                        }.tag(method)
                    }
                }
                .pickerStyle(.menu)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.wiseBorder.opacity(0.5))
                        .stroke(Color.wiseBorder, lineWidth: 1)
                )
            }

            // Website
            VStack(alignment: .leading, spacing: 6) {
                Text("Website (Optional)")
                    .font(.spotifyLabelMedium)
                    .foregroundColor(.wiseSecondaryText)

                TextField("e.g., netflix.com", text: $website)
                    .font(.spotifyBodyMedium)
                    .foregroundColor(.wisePrimaryText)
                    .keyboardType(.URL)
                    .autocapitalization(.none)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.wiseBorder.opacity(0.5))
                            .stroke(Color.wiseBorder, lineWidth: 1)
                    )
            }

            // Notes
            VStack(alignment: .leading, spacing: 6) {
                Text("Notes (Optional)")
                    .font(.spotifyLabelMedium)
                    .foregroundColor(.wiseSecondaryText)

                TextField("Additional notes...", text: $notes, axis: .vertical)
                    .lineLimit(3...6)
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

    // MARK: - Actions

    private func addSubscription() {
        guard let priceValue = Double(price) else { return }

        isSubmitting = true
        HapticManager.shared.impact(.medium)

        var newSubscription = Subscription(
            name: name.trimmingCharacters(in: .whitespaces),
            description: description.trimmingCharacters(in: .whitespaces),
            price: priceValue,
            billingCycle: selectedBillingCycle,
            category: selectedCategory,
            icon: selectedIcon,
            color: selectedColor
        )

        // Set additional properties
        newSubscription.isShared = isShared
        newSubscription.sharedWith = selectedPeople.map { $0.id }
        newSubscription.paymentMethod = selectedPaymentMethod
        newSubscription.website = website.isEmpty ? nil : website.trimmingCharacters(in: .whitespaces)
        newSubscription.notes = notes.trimmingCharacters(in: .whitespaces)

        // Trial settings
        newSubscription.isFreeTrial = isFreeTrial
        if isFreeTrial {
            newSubscription.trialStartDate = trialStartDate
            newSubscription.trialEndDate = trialEndDate
            newSubscription.trialDuration = trialDuration
            newSubscription.willConvertToPaid = willConvertToPaid
            if !priceAfterTrial.isEmpty, let afterTrialPrice = Double(priceAfterTrial) {
                newSubscription.priceAfterTrial = afterTrialPrice
            }
        }

        // Reminder settings
        newSubscription.enableRenewalReminder = enableRenewalReminder
        newSubscription.reminderDaysBefore = reminderDaysBefore
        newSubscription.reminderTime = reminderTime

        // Show success animation
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            showingSuccess = true
        }

        // Delay to show animation, then save and dismiss
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onSubscriptionAdded(newSubscription)
            HapticManager.shared.success()

            // Auto dismiss after showing success
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                showingAddSubscriptionSheet = false
            }
        }
    }
}

// MARK: - Person Picker Sheet

struct PersonPickerSheet: View {
    @Environment(\.dismiss) var dismiss
    @Binding var selectedPeople: [Person]
    let availablePeople: [Person]

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 8) {
                    if availablePeople.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "person.2.fill")
                                .font(.system(size: 48))
                                .foregroundColor(.wiseSecondaryText.opacity(0.4))

                            Text("No people added yet")
                                .font(.spotifyBodyLarge)
                                .foregroundColor(.wiseSecondaryText)

                            Text("Add people from the People tab first")
                                .font(.spotifyBodySmall)
                                .foregroundColor(.wiseTertiaryText)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 60)
                    } else {
                        ForEach(availablePeople) { person in
                            let isSelected = selectedPeople.contains { $0.id == person.id }

                            Button(action: {
                                HapticManager.shared.selection()
                                if isSelected {
                                    selectedPeople.removeAll { $0.id == person.id }
                                } else {
                                    selectedPeople.append(person)
                                }
                            }) {
                                HStack(spacing: 14) {
                                    AvatarView(
                                        avatarType: person.avatarType,
                                        size: .large,
                                        style: .solid
                                    )
                                    .frame(width: 44, height: 44)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(person.name)
                                            .font(.spotifyBodyMedium)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.wisePrimaryText)

                                        if !person.email.isEmpty {
                                            Text(person.email)
                                                .font(.spotifyCaptionMedium)
                                                .foregroundColor(.wiseSecondaryText)
                                        }
                                    }

                                    Spacer()

                                    if isSelected {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: 22))
                                            .foregroundColor(.wiseForestGreen)
                                    } else {
                                        Circle()
                                            .stroke(Color.wiseBorder, lineWidth: 2)
                                            .frame(width: 22, height: 22)
                                    }
                                }
                                .padding(14)
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(isSelected ? Color.wiseForestGreen.opacity(0.05) : Color.wiseCardBackground)
                                        .stroke(isSelected ? Color.wiseForestGreen : Color.wiseBorder, lineWidth: 1)
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .navigationTitle("Select People")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .font(.spotifyLabelLarge)
                    .foregroundColor(.wiseSecondaryText)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.spotifyLabelLarge)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color.wiseForestGreen)
                    )
                }
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
