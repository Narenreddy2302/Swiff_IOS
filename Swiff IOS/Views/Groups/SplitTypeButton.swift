//
//  SplitTypeButton.swift
//  Swiff IOS
//
//  Button component for selecting split calculation type
//

import SwiftUI

struct SplitTypeButton: View {
    let splitType: SplitType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: {
            HapticManager.shared.light()
            action()
        }) {
            HStack(spacing: 16) {
                // Icon circle
                ZStack {
                    Circle()
                        .fill(iconBackgroundColor)
                        .frame(width: 48, height: 48)

                    Image(systemName: splitType.icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(iconColor)
                }

                // Title and description
                VStack(alignment: .leading, spacing: 4) {
                    Text(splitType.rawValue)
                        .font(.spotifyBodyLarge)
                        .foregroundColor(.wisePrimaryText)

                    Text(splitType.description)
                        .font(.spotifyCaptionMedium)
                        .foregroundColor(.wiseSecondaryText)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                // Selection indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.wiseBrightGreen)
                }
            }
            .padding(16)
            .background(backgroundColor)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(borderColor, lineWidth: isSelected ? 2 : 1)
            )
            .cornerRadius(12)
        }
        .buttonStyle(ScaleButtonStyle(scaleAmount: 0.98))
    }

    private var backgroundColor: Color {
        isSelected ? Color.wiseBrightGreen.opacity(0.1) : Color.wiseCardBackground
    }

    private var borderColor: Color {
        isSelected ? Color.wiseBrightGreen : Color.wiseBorder.opacity(0.3)
    }

    private var iconBackgroundColor: Color {
        isSelected ? Color.wiseBrightGreen.opacity(0.2) : Color.wiseBorder.opacity(0.1)
    }

    private var iconColor: Color {
        isSelected ? Color.wiseBrightGreen : Color.wiseSecondaryText
    }
}

// MARK: - Preview

#Preview("Split Type Buttons") {
    VStack(spacing: 12) {
        ForEach(SplitType.allCases, id: \.self) { splitType in
            SplitTypeButton(
                splitType: splitType,
                isSelected: splitType == .equally,
                action: {
                    print("\(splitType.rawValue) selected")
                }
            )
        }
    }
    .padding()
    .background(Color.wiseBackground)
}
