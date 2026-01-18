//
//  CategoryGridPicker.swift
//  Swiff IOS
//
//  4-column grid-based category selector matching reference design
//

import SwiftUI

/// Grid-based category picker with icons and names
/// Matches the reference design with 4-column layout
struct CategoryGridPicker: View {
    let categories: [TransactionCategory]
    @Binding var selectedCategory: TransactionCategory
    @Binding var isPresented: Bool

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 4)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(categories, id: \.self) { category in
                Button {
                    HapticManager.shared.light()
                    selectedCategory = category
                    withAnimation(.smooth) {
                        isPresented = false
                    }
                } label: {
                    VStack(spacing: 6) {
                        // Category icon
                        Image(systemName: category.icon)
                            .font(.system(size: 28))
                            .foregroundColor(selectedCategory == category ? category.color : .secondary)

                        // Category name
                        Text(category.rawValue)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(selectedCategory == category ? category.color : .primary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(UIColor.secondarySystemGroupedBackground))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(
                                        selectedCategory == category ? category.color : Color.clear,
                                        lineWidth: 2
                                    )
                            )
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .transition(.opacity.combined(with: .move(edge: .top)))
    }
}

// MARK: - Preview

#Preview("Category Grid Picker") {
    struct PreviewWrapper: View {
        @State private var selectedCategory: TransactionCategory = .food
        @State private var isPresented: Bool = true

        var body: some View {
            ScrollView {
                VStack(spacing: 20) {
                    Text("Selected: \(selectedCategory.rawValue)")
                        .font(.headline)

                    CategoryGridPicker(
                        categories: TransactionCategory.allCases,
                        selectedCategory: $selectedCategory,
                        isPresented: $isPresented
                    )
                    .padding(.horizontal, 20)

                    Spacer()
                }
                .padding(.top, 40)
            }
            .background(Color(UIColor.systemGroupedBackground))
        }
    }

    return PreviewWrapper()
}
