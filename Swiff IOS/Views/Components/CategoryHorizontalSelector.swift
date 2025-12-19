//
//  CategoryHorizontalSelector.swift
//  Swiff IOS
//
//  Horizontal scrolling category selector
//

import SwiftUI

struct CategoryHorizontalSelector: View {
    @Binding var selectedCategory: TransactionCategory
    let categories: [TransactionCategory]

    init(selectedCategory: Binding<TransactionCategory>, categories: [TransactionCategory] = TransactionCategory.allCases) {
        self._selectedCategory = selectedCategory
        self.categories = categories
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(categories, id: \.self) { category in
                    Button(action: {
                        HapticManager.shared.light()
                        selectedCategory = category
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: category.icon)
                                .font(.system(size: 14))

                            Text(category.rawValue)
                                .font(.spotifyLabelMedium)
                        }
                        .foregroundColor(selectedCategory == category ? .white : .wisePrimaryText)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(selectedCategory == category ? Color.wisePrimaryText : Color.wiseCardBackground)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(selectedCategory == category ? Color.clear : Color.wiseBorder, lineWidth: 1)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("Category Horizontal Selector") {
    VStack(spacing: 20) {
        Text("Select a Category")
            .font(.spotifyHeadingMedium)

        CategoryHorizontalSelector(
            selectedCategory: .constant(.dining)
        )
    }
    .padding(20)
    .background(Color.wiseBackground)
}
