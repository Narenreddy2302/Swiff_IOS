//
//  Step1BasicDetailsView.swift
//  Swiff IOS
//
//  Step 1: Transaction Details — Amount (hero), Name, Category
//  Features custom numeric keypad with right-to-left currency input
//

import SwiftUI

// MARK: - Step1BasicDetailsView

struct Step1BasicDetailsView: View {

    // MARK: - Properties

    @ObservedObject var viewModel: NewTransactionViewModel
    @EnvironmentObject var dataManager: DataManager
    @FocusState private var isNameFieldFocused: Bool
    @State private var hasAttemptedProceed: Bool = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: Theme.Metrics.paddingLarge) {
                    // Hero Amount Display
                    heroAmountSection
                        .padding(.top, Theme.Metrics.paddingMedium)

                    // Transaction Name
                    nameInputSection
                        .padding(.horizontal, Theme.Metrics.paddingMedium)

                    // Category Chips
                    categorySection

                    Spacer(minLength: 16)
                }
            }
            .scrollDismissesKeyboard(.interactively)

            // Bottom area: Keypad or spacer for system keyboard
            if viewModel.basicDetails.isKeypadActive && !isNameFieldFocused {
                numericKeypad
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .background(Theme.Colors.background)
        .onChange(of: isNameFieldFocused) { _, focused in
            withAnimation(.easeInOut(duration: 0.25)) {
                viewModel.basicDetails.isKeypadActive = !focused
            }
        }
        .onTapGesture {
            if isNameFieldFocused {
                isNameFieldFocused = false
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Step 1: Transaction details")
    }

    // MARK: - Hero Amount Section

    private var heroAmountSection: some View {
        VStack(spacing: 8) {
            // Tap to activate keypad
            Button {
                isNameFieldFocused = false
                withAnimation(.easeInOut(duration: 0.25)) {
                    viewModel.basicDetails.isKeypadActive = true
                }
            } label: {
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(viewModel.basicDetails.currencySymbol)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(
                            viewModel.basicDetails.isAmountZero
                                ? Theme.Colors.textTertiary
                                : Theme.Colors.textSecondary
                        )

                    Text(viewModel.basicDetails.formattedAmountRaw)
                        .font(.system(size: 52, weight: .bold, design: .rounded))
                        .foregroundColor(
                            viewModel.basicDetails.isAmountZero
                                ? Theme.Colors.textTertiary
                                : Theme.Colors.textPrimary
                        )
                        .contentTransition(.numericText())

                    // Blinking cursor
                    if viewModel.basicDetails.isKeypadActive && !isNameFieldFocused {
                        BlinkingCursor()
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, Theme.Metrics.paddingLarge)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Amount: \(viewModel.basicDetails.currencySymbol)\(viewModel.basicDetails.formattedAmountRaw)")
            .accessibilityHint("Tap to edit amount using keypad")

            // Validation hint
            if hasAttemptedProceed && viewModel.basicDetails.isAmountZero {
                Text("Enter an amount")
                    .font(Theme.Fonts.bodySmall)
                    .foregroundColor(Theme.Colors.statusError)
                    .transition(.opacity)
            }
        }
    }

    // MARK: - Name Input Section

    private var nameInputSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: Theme.Metrics.paddingSmall) {
                Image(systemName: "pencil")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Theme.Colors.textTertiary)
                    .frame(width: 20)

                TextField("Transaction name", text: $viewModel.basicDetails.transactionName)
                    .font(.system(size: 17))
                    .foregroundColor(Theme.Colors.textPrimary)
                    .focused($isNameFieldFocused)
                    .submitLabel(.done)
                    .onSubmit {
                        isNameFieldFocused = false
                    }
                    .onChange(of: viewModel.basicDetails.transactionName) { _, _ in
                        viewModel.basicDetails.enforceNameLimit()
                    }

                // Character counter near limit
                if viewModel.basicDetails.isNearCharacterLimit {
                    Text("\(viewModel.basicDetails.transactionName.count)/\(BasicDetailsState.nameCharacterLimit)")
                        .font(.system(size: 12))
                        .foregroundColor(
                            viewModel.basicDetails.remainingCharacters <= 5
                                ? Theme.Colors.statusError
                                : Theme.Colors.textTertiary
                        )
                        .monospacedDigit()
                }
            }
            .padding(.horizontal, Theme.Metrics.paddingMedium)
            .padding(.vertical, 14)
            .background(Theme.Colors.secondaryBackground)
            .cornerRadius(Theme.Metrics.cornerRadiusMedium)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Metrics.cornerRadiusMedium)
                    .stroke(
                        nameFieldBorderColor,
                        lineWidth: isNameFieldFocused ? 2 : 0
                    )
            )

            // Validation hint
            if hasAttemptedProceed && viewModel.basicDetails.transactionName.trimmingCharacters(in: .whitespaces).isEmpty {
                Text("Enter a name for this transaction")
                    .font(Theme.Fonts.bodySmall)
                    .foregroundColor(Theme.Colors.statusError)
                    .padding(.leading, 4)
                    .transition(.opacity)
            }
        }
    }

    private var nameFieldBorderColor: Color {
        if hasAttemptedProceed && viewModel.basicDetails.transactionName.trimmingCharacters(in: .whitespaces).isEmpty {
            return Theme.Colors.statusError
        }
        if isNameFieldFocused {
            return Theme.Colors.brandPrimary
        }
        return .clear
    }

    // MARK: - Category Section

    private var categorySection: some View {
        VStack(alignment: .leading, spacing: Theme.Metrics.paddingSmall) {
            HStack {
                Text(viewModel.basicDetails.selectedCategory == nil ? "Choose a category" : "Category")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Theme.Colors.textSecondary)
                    .textCase(.uppercase)

                Spacer()

                if hasAttemptedProceed && viewModel.basicDetails.selectedCategory == nil {
                    Text("Required")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Theme.Colors.statusError)
                }
            }
            .padding(.horizontal, Theme.Metrics.paddingMedium)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(TransactionCategory.allCases, id: \.self) { category in
                        CategoryChip(
                            category: category,
                            isSelected: viewModel.basicDetails.selectedCategory == category
                        ) {
                            HapticManager.shared.light()
                            withAnimation(reduceMotion ? .none : .spring(response: 0.3, dampingFraction: 0.7)) {
                                viewModel.basicDetails.selectedCategory = category
                            }
                        }
                    }
                }
                .padding(.horizontal, Theme.Metrics.paddingMedium)
                .padding(.vertical, 2)
            }
        }
    }

    // MARK: - Custom Numeric Keypad

    private var numericKeypad: some View {
        VStack(spacing: 0) {
            Divider()

            VStack(spacing: 8) {
                ForEach(keypadRows, id: \.self) { row in
                    HStack(spacing: 8) {
                        ForEach(row, id: \.self) { key in
                            KeypadButton(key: key) {
                                handleKeypadTap(key)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, Theme.Metrics.paddingMedium)
            .padding(.top, 12)
            .padding(.bottom, 8)
        }
        .background(Theme.Colors.secondaryBackground)
    }

    private var keypadRows: [[KeypadKey]] {
        [
            [.digit(1), .digit(2), .digit(3)],
            [.digit(4), .digit(5), .digit(6)],
            [.digit(7), .digit(8), .digit(9)],
            [.empty, .digit(0), .backspace],
        ]
    }

    private func handleKeypadTap(_ key: KeypadKey) {
        switch key {
        case .digit(let d):
            viewModel.basicDetails.appendDigit(d)
            HapticManager.shared.light()
        case .backspace:
            viewModel.basicDetails.deleteLastDigit()
            HapticManager.shared.light()
        case .empty:
            break
        }
    }

    // MARK: - Public Methods

    func attemptProceed() {
        if viewModel.basicDetails.canProceed {
            isNameFieldFocused = false
            viewModel.goToNextStep()
        } else {
            withAnimation(.easeOut(duration: 0.2)) {
                hasAttemptedProceed = true
            }
            HapticManager.shared.warning()
        }
    }
}

// MARK: - Keypad Key Enum

enum KeypadKey: Hashable {
    case digit(Int)
    case backspace
    case empty
}

// MARK: - Keypad Button

private struct KeypadButton: View {
    let key: KeypadKey
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            switch key {
            case .digit(let d):
                Text("\(d)")
                    .font(.system(size: 24, weight: .medium, design: .rounded))
                    .foregroundColor(Theme.Colors.textPrimary)

            case .backspace:
                Image(systemName: "delete.backward")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(Theme.Colors.textPrimary)

            case .empty:
                Color.clear
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 52)
        .background(
            key == .empty
                ? Color.clear
                : Theme.Colors.cardBackground
        )
        .cornerRadius(Theme.Metrics.cornerRadiusMedium)
        .buttonStyle(KeypadPressStyle())
        .disabled(key == .empty)
        .accessibilityLabel(keyAccessibilityLabel)
    }

    private var keyAccessibilityLabel: String {
        switch key {
        case .digit(let d): return "\(d)"
        case .backspace: return "Delete"
        case .empty: return ""
        }
    }
}

// MARK: - Keypad Press Style

private struct KeypadPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? 0.7 : 1.0)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Blinking Cursor

private struct BlinkingCursor: View {
    @State private var isVisible = true

    var body: some View {
        Rectangle()
            .fill(Theme.Colors.brandPrimary)
            .frame(width: 2, height: 36)
            .opacity(isVisible ? 1 : 0)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                    isVisible = false
                }
            }
    }
}

// MARK: - Category Chip

struct CategoryChip: View {
    let category: TransactionCategory
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: category.icon)
                    .font(.system(size: 14, weight: .medium))

                Text(category.rawValue)
                    .font(.system(size: 14, weight: .medium))
                    .lineLimit(1)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                isSelected
                    ? category.color
                    : Theme.Colors.secondaryBackground
            )
            .foregroundColor(
                isSelected ? .white : Theme.Colors.textPrimary
            )
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(
                        isSelected ? Color.clear : Theme.Colors.border,
                        lineWidth: 1
                    )
            )
            .scaleEffect(isSelected ? 1.0 : 0.98)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(category.rawValue) category")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Preview

#Preview("Step 1 - Transaction Details") {
    Step1BasicDetailsView(viewModel: NewTransactionViewModel())
        .environmentObject(DataManager.shared)
}
