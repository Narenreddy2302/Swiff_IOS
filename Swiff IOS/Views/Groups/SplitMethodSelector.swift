//
//  SplitMethodSelector.swift
//  Swiff IOS
//
//  Horizontal selector for split calculation methods
//

import SwiftUI

struct SplitMethodSelector: View {
    @Binding var selectedType: SplitType
    var onSelect: (() -> Void)?  // Optional callback for keyboard dismissal

    private let buttonCount: CGFloat = 5
    private let spacing: CGFloat = 8
    private let horizontalPadding: CGFloat = 4

    init(selectedType: Binding<SplitType>, onSelect: (() -> Void)? = nil) {
        self._selectedType = selectedType
        self.onSelect = onSelect
    }

    var body: some View {
        GeometryReader { geometry in
            let totalSpacing = spacing * (buttonCount - 1)
            let totalPadding = horizontalPadding * 2
            let buttonWidth = (geometry.size.width - totalSpacing - totalPadding) / buttonCount

            HStack(spacing: spacing) {
                ForEach(SplitType.allCases, id: \.self) { type in
                    SplitMethodButton(
                        type: type,
                        isSelected: selectedType == type,
                        buttonWidth: buttonWidth,
                        action: {
                            HapticManager.shared.light()
                            onSelect?()  // Call callback to dismiss keyboard
                            withAnimation(.smooth) {
                                selectedType = type
                            }
                        }
                    )
                }
            }
            .padding(.horizontal, horizontalPadding)
        }
        .frame(height: 72)
    }
}

// MARK: - Split Method Button

private struct SplitMethodButton: View {
    let type: SplitType
    let isSelected: Bool
    let buttonWidth: CGFloat
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                // Icon with background circle
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.white.opacity(0.3) : Color.wiseBorder.opacity(0.1))
                        .frame(width: 36, height: 36)

                    Image(systemName: type.icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(isSelected ? .white : .wisePrimaryText)
                }

                Text(type.shortName)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(isSelected ? .white : .wisePrimaryText)
            }
            .frame(width: buttonWidth, height: 68)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isSelected ? Color.wiseForestGreen : Color.wiseCardBackground)
                    .shadow(
                        color: isSelected ? Color.wiseForestGreen.opacity(0.3) : Color.clear,
                        radius: 8,
                        x: 0,
                        y: 4
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(
                        isSelected ? Color.wiseForestGreen : Color.wiseBorder.opacity(0.3),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(.snappy, value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .pressEvents {
            isPressed = true
        } onRelease: {
            isPressed = false
        }
    }
}

// MARK: - Press Events Modifier

private extension View {
    func pressEvents(onPress: @escaping () -> Void, onRelease: @escaping () -> Void) -> some View {
        self.simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in onPress() }
                .onEnded { _ in onRelease() }
        )
    }
}

// MARK: - SplitType Extension

extension SplitType {
    var shortName: String {
        switch self {
        case .equally:
            return "Equal"
        case .exactAmounts:
            return "Fixed"
        case .percentages:
            return "Percent"
        case .shares:
            return "Shares"
        case .adjustments:
            return "Adjust"
        }
    }

    static var allCases: [SplitType] {
        return [.equally, .percentages, .shares, .exactAmounts, .adjustments]
    }
}

// MARK: - Preview

#Preview("Split Method Selector") {
    VStack(spacing: 20) {
        Text("Select Split Method")
            .font(.spotifyHeadingMedium)

        SplitMethodSelector(selectedType: .constant(.equally))

        Text("The selected method determines how the total amount is divided among participants.")
            .font(.spotifyBodyMedium)
            .foregroundColor(.wiseSecondaryText)
            .multilineTextAlignment(.center)
    }
    .padding(20)
    .background(Color.wiseBackground)
}
