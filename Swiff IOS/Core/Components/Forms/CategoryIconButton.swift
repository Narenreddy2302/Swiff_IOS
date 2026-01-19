//
//  CategoryIconButton.swift
//  Swiff IOS
//
//  Category icon button with dropdown menu for category selection
//

import SwiftUI

struct CategoryIconButton: View {
    @Binding var selectedCategory: TransactionCategory

    var body: some View {
        Menu {
            ForEach(TransactionCategory.allCases, id: \.self) { category in
                Button(action: {
                    HapticManager.shared.light()
                    selectedCategory = category
                }) {
                    HStack {
                        Image(systemName: category.icon)
                        Text(category.rawValue)
                        if selectedCategory == category {
                            Spacer()
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            Circle()
                .fill(selectedCategory.color.opacity(0.25))
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: selectedCategory.icon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(selectedCategory.color)
                )
                .overlay(
                    Circle()
                        .stroke(selectedCategory.color.opacity(0.6), lineWidth: 1)
                )
        }
    }
}

// MARK: - Preview

#Preview("Category Icon Button") {
    VStack(spacing: 20) {
        HStack(spacing: 16) {
            CategoryIconButton(selectedCategory: .constant(.food))
            CategoryIconButton(selectedCategory: .constant(.income))
            CategoryIconButton(selectedCategory: .constant(.shopping))
            CategoryIconButton(selectedCategory: .constant(.other))
        }

        // Preview in context
        HStack(spacing: 12) {
            CategoryIconButton(selectedCategory: .constant(.dining))

            TextField("e.g., Dinner at Restaurant", text: .constant(""))
                .font(.spotifyBodyMedium)
                .foregroundColor(.wisePrimaryText)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.wiseCardBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.wiseBorder.opacity(0.3), lineWidth: 1)
                        )
                )
        }
        .padding(.horizontal, 20)
    }
    .padding(20)
    .background(Color.wiseBackground)
}
