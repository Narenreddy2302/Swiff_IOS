//
//  Step2SplitOptionsView.swift
//  Swiff IOS
//
//  Step 2: People Involved - Who paid and who is included
//  Production-ready with design system compliance and accessibility
//

import SwiftUI

// MARK: - Step2SplitOptionsView

struct Step2SplitOptionsView: View {

    // MARK: - Properties

    @ObservedObject var viewModel: NewTransactionViewModel
    @EnvironmentObject var dataManager: DataManager
    
    @State private var payerSearchText: String = ""

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // No header here as it's in the container
            scrollContent
        }
        .onTapGesture {
            dismissKeyboard()
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    dismissKeyboard()
                }
                .font(Theme.Fonts.bodyLarge)
                .fontWeight(.semibold)
                .foregroundColor(Theme.Colors.brandPrimary)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Step 2: People involved in transaction")
    }

    private func dismissKeyboard() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
    }

    // MARK: - Subviews

    private var scrollContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Metrics.paddingLarge) {

                // Summary Header
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(viewModel.basicDetails.amount.asCurrency) • \(viewModel.basicDetails.transactionName.isEmpty ? "Transaction" : viewModel.basicDetails.transactionName)")
                        .font(Theme.Fonts.headerMedium)
                        .foregroundColor(Theme.Colors.textPrimary)
                }
                .padding(.top, Theme.Metrics.paddingMedium)

                // Who paid section
                VStack(alignment: .leading, spacing: Theme.Metrics.paddingSmall) {
                    Text("Who paid?")
                        .font(Theme.Fonts.headerSmall)
                        .foregroundColor(Theme.Colors.textPrimary)

                    // Payer Search
                    searchField(
                        placeholder: "Search payer...",
                        text: $payerSearchText
                    )
                    
                    // Payer List (Limited Height)
                    ScrollView {
                        LazyVStack(spacing: 0) {
                             // "Me" Option always avail if matches search or search empty
                             if payerMatchesSearch(UserProfileManager.shared.profile.name) {
                                  PayerSelectionRow(
                                      person: UserProfileManager.shared.profile.asPerson,
                                      isSelected: isSelfPayer,
                                      action: {
                                          HapticManager.shared.selection()
                                          selectSelfAsPayer()
                                      }
                                  )
                             }
                             
                             ForEach(filteredPayers) { person in
                                 if person.id != UserProfileManager.shared.profile.id {
                                     PayerSelectionRow(
                                         person: person,
                                         isSelected: viewModel.splitOptions.paidByUserId == person.id,
                                         action: {
                                             HapticManager.shared.selection()
                                             viewModel.splitOptions.selectPayer(person.id)
                                             if !viewModel.splitOptions.participantIds.contains(person.id) {
                                                 viewModel.splitOptions.addParticipant(person.id)
                                             }
                                         }
                                     )
                                 }
                             }
                        }
                    }
                    .frame(maxHeight: 200)
                    .background(Theme.Colors.cardBackground)
                    .cornerRadius(Theme.Metrics.cornerRadiusMedium)
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.Metrics.cornerRadiusMedium)
                            .stroke(Theme.Colors.border, lineWidth: 1)
                    )
                }

                // Split with section
                VStack(alignment: .leading, spacing: Theme.Metrics.paddingSmall) {
                    Text("Split with")
                        .font(Theme.Fonts.headerSmall)
                        .foregroundColor(Theme.Colors.textPrimary)

                    searchField(
                        placeholder: "Search people...",
                        text: $viewModel.splitOptions.splitWithSearchText
                    )

                    // People List for Splitting
                    LazyVStack(spacing: 0) {
                        // Show "Me" if matches
                        if matchesSearch(UserProfileManager.shared.profile.name, searchText: viewModel.splitOptions.splitWithSearchText) {
                            PersonSelectionRow(
                                person: UserProfileManager.shared.profile.asPerson,
                                isSelected: viewModel.splitOptions.participantIds.contains(UserProfileManager.shared.profile.id),
                                action: {
                                    HapticManager.shared.selection()
                                    toggleParticipant(UserProfileManager.shared.profile.id)
                                }
                            )
                        }

                        ForEach(filteredSplitPeople) { person in
                            if person.id != UserProfileManager.shared.profile.id {
                                PersonSelectionRow(
                                    person: person,
                                    isSelected: viewModel.splitOptions.participantIds.contains(person.id),
                                    action: {
                                        HapticManager.shared.selection()
                                        toggleParticipant(person.id)
                                    }
                                )
                                if person.id != filteredSplitPeople.last?.id {
                                     Divider().padding(.leading, 72)
                                }
                            }
                        }
                    }
                    .background(Theme.Colors.cardBackground)
                    .cornerRadius(Theme.Metrics.cornerRadiusMedium)
                }

                Spacer(minLength: 100)
            }
            .padding(.horizontal, Theme.Metrics.paddingMedium)
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
                .opacity(viewModel.splitOptions.canProceed ? 1.0 : Theme.Opacity.disabled)
        }
        .disabled(!viewModel.splitOptions.canProceed)
    }

    // MARK: - Helper Views

    private func searchField(placeholder: String, text: Binding<String>) -> some View {
        HStack(spacing: Theme.Metrics.paddingSmall) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: Theme.Metrics.iconSizeSmall))
                .foregroundColor(Theme.Colors.textTertiary)

            TextField(placeholder, text: text)
                .font(Theme.Fonts.bodyMedium)
                .foregroundColor(Theme.Colors.textPrimary)
            
            if !text.wrappedValue.isEmpty {
                 Button(action: { text.wrappedValue = "" }) {
                     Image(systemName: "xmark.circle.fill")
                         .font(.system(size: Theme.Metrics.iconSizeSmall))
                         .foregroundColor(Theme.Colors.textTertiary)
                 }
            }
        }
        .padding(.horizontal, Theme.Metrics.paddingMedium)
        .padding(.vertical, Theme.Metrics.paddingSmall)
        .background(Theme.Colors.secondaryBackground)
        .cornerRadius(Theme.Metrics.cornerRadiusMedium)
        .overlay(
             RoundedRectangle(cornerRadius: Theme.Metrics.cornerRadiusMedium)
                 .stroke(Theme.Colors.border, lineWidth: 1)
        )
    }

    // MARK: - Private Methods
    
    private var filteredPayers: [Person] {
        if payerSearchText.isEmpty {
            return dataManager.people
        }
        return dataManager.people.filter { $0.name.localizedCaseInsensitiveContains(payerSearchText) }
    }
    
    private var filteredSplitPeople: [Person] {
        if viewModel.splitOptions.splitWithSearchText.isEmpty {
            return dataManager.people
        }
        return dataManager.people.filter { $0.name.localizedCaseInsensitiveContains(viewModel.splitOptions.splitWithSearchText) }
    }
    
    private func payerMatchesSearch(_ name: String) -> Bool {
        payerSearchText.isEmpty || name.localizedCaseInsensitiveContains(payerSearchText)
    }
    
    private func matchesSearch(_ name: String, searchText: String) -> Bool {
        searchText.isEmpty || name.localizedCaseInsensitiveContains(searchText)
    }

    private func handleNextStep() {
        HapticManager.shared.selection()
        if viewModel.splitOptions.canProceed {
            viewModel.splitOptions.isSplit = true
            withAnimation(.smooth) {
                viewModel.goToNextStep()
            }
        }
    }

    /// Current user's ID from UserProfileManager
    private var currentUserId: UUID? {
        UserProfileManager.shared.profile.id
    }

    private var isSelfPayer: Bool {
        guard let payerId = viewModel.splitOptions.paidByUserId else { return false }
        if let myId = currentUserId {
            return payerId == myId
        }
        return false
    }

    private func selectSelfAsPayer() {
        if let myId = currentUserId {
            viewModel.splitOptions.selectPayer(myId)
            if !viewModel.splitOptions.participantIds.contains(myId) {
                viewModel.splitOptions.addParticipant(myId)
            }
        }
    }
    
    private func toggleParticipant(_ id: UUID) {
        if viewModel.splitOptions.participantIds.contains(id) {
            viewModel.splitOptions.removeParticipant(id)
        } else {
            viewModel.splitOptions.addParticipant(id)
        }
    }
}

// MARK: - PayerSelectionRow
struct PayerSelectionRow: View {
    let person: Person
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Theme.Metrics.paddingMedium) {
                AvatarView(avatarType: person.avatarType, size: .small, style: .solid)
                    .frame(width: Theme.Metrics.avatarStandard, height: Theme.Metrics.avatarStandard)

                VStack(alignment: .leading, spacing: 2) {
                    Text(person.name)
                        .font(Theme.Fonts.bodyLarge)
                        .foregroundColor(Theme.Colors.textPrimary)

                    if !person.phone.isEmpty {
                        Text(person.phone)
                            .font(Theme.Fonts.bodySmall)
                            .foregroundColor(Theme.Colors.textSecondary)
                    }
                }

                Spacer()

                // Radio button indicator
                ZStack {
                    Circle()
                        .stroke(isSelected ? Theme.Colors.accentDark : Theme.Colors.textTertiary, lineWidth: 2)
                        .frame(width: 22, height: 22)

                    if isSelected {
                        Circle()
                            .fill(Theme.Colors.accentDark)
                            .frame(width: 12, height: 12)
                    }
                }
            }
            .padding(.horizontal, Theme.Metrics.paddingMedium)
            .padding(.vertical, 12)
            .background(isSelected ? Theme.Colors.accentLight.opacity(Theme.Opacity.subtle) : Color.clear)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - PersonSelectionRow
struct PersonSelectionRow: View {
    let person: Person
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Theme.Metrics.paddingMedium) {
                AvatarView(avatarType: person.avatarType, size: .small, style: .solid)
                    .frame(width: Theme.Metrics.avatarStandard, height: Theme.Metrics.avatarStandard)

                VStack(alignment: .leading, spacing: 2) {
                    Text(person.name)
                        .font(Theme.Fonts.bodyLarge)
                        .foregroundColor(Theme.Colors.textPrimary)
                        
                    if !person.phone.isEmpty {
                         Text(person.phone)
                             .font(Theme.Fonts.bodySmall)
                             .foregroundColor(Theme.Colors.textSecondary)
                     }
                }

                Spacer()

                // Checkbox indicator
                ZStack {
                    Circle()
                        .stroke(isSelected ? Theme.Colors.accentDark : Theme.Colors.textTertiary, lineWidth: 2)
                        .frame(width: 24, height: 24)

                    if isSelected {
                        Circle()
                            .fill(Theme.Colors.accentDark)
                            .frame(width: 24, height: 24)

                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
            .padding(.horizontal, Theme.Metrics.paddingMedium)
            .padding(.vertical, 12)
            .background(isSelected ? Theme.Colors.accentLight.opacity(Theme.Opacity.subtle) : Color.clear)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

extension Person {
    var asPerson: Person { self }
}

extension UserProfile {
    var asPerson: Person {
        Person(
            name: self.name + " (You)",
            email: self.email,
            phone: self.phone,
            avatarType: self.avatarType
        )
    }
}

#Preview("Step 2 - People Involved") {
    Step2SplitOptionsView(viewModel: NewTransactionViewModel())
        .environmentObject(DataManager.shared)
        .background(Theme.Colors.secondaryBackground)
}
