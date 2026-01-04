//
//  Step1DetailsView.swift
//  Swiff IOS
//
//  Step 1: Basic bill details (title, amount, date, category, notes)
//

import SwiftUI

struct Step1DetailsView: View {
    @Binding var title: String
    @Binding var totalAmount: String
    @Binding var date: Date
    @Binding var category: TransactionCategory
    @Binding var notes: String

    @FocusState private var focusedField: Field?

    enum Field {
        case title, amount, notes
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Title
                VStack(alignment: .leading, spacing: 8) {
                    Text("Bill Title *")
                        .font(.spotifyLabelMedium)
                        .foregroundColor(.wiseSecondaryText)

                    TextField("e.g., Dinner at Italian Restaurant", text: $title)
                        .font(.spotifyBodyMedium)
                        .foregroundColor(.wisePrimaryText)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.wiseBorder.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.wiseBorder.opacity(0.3), lineWidth: 1)
                                )
                        )
                        .focused($focusedField, equals: .title)
                }

                // Total Amount
                VStack(alignment: .leading, spacing: 8) {
                    Text("Total Amount *")
                        .font(.spotifyLabelMedium)
                        .foregroundColor(.wiseSecondaryText)

                    HStack(spacing: 8) {
                        Text("$")
                            .font(.spotifyNumberLarge)
                            .foregroundColor(.wisePrimaryText)

                        TextField("0.00", text: $totalAmount)
                            .font(.spotifyNumberLarge)
                            .foregroundColor(.wisePrimaryText)
                            .keyboardType(.decimalPad)
                            .focused($focusedField, equals: .amount)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.wiseBorder.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.wiseBorder.opacity(0.3), lineWidth: 1)
                            )
                    )
                }

                // Date
                VStack(alignment: .leading, spacing: 8) {
                    Text("Date")
                        .font(.spotifyLabelMedium)
                        .foregroundColor(.wiseSecondaryText)

                    DatePicker("", selection: $date, displayedComponents: .date)
                        .datePickerStyle(.compact)
                        .labelsHidden()
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.wiseBorder.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.wiseBorder.opacity(0.3), lineWidth: 1)
                                )
                        )
                }

                // Category
                VStack(alignment: .leading, spacing: 8) {
                    Text("Category")
                        .font(.spotifyLabelMedium)
                        .foregroundColor(.wiseSecondaryText)

                    Menu {
                        ForEach(TransactionCategory.allCases, id: \.self) { cat in
                            Button(action: {
                                category = cat
                                HapticManager.shared.light()
                            }) {
                                Label(cat.rawValue, systemImage: cat.icon)
                            }
                        }
                    } label: {
                        HStack {
                            Image(systemName: category.icon)
                                .foregroundColor(category.color)
                            Text(category.rawValue)
                                .font(.spotifyBodyMedium)
                                .foregroundColor(.wisePrimaryText)
                            Spacer()
                            Image(systemName: "chevron.down")
                                .font(.system(size: 14))
                                .foregroundColor(.wiseSecondaryText)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.wiseBorder.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.wiseBorder.opacity(0.3), lineWidth: 1)
                                )
                        )
                    }
                }

                // Notes
                VStack(alignment: .leading, spacing: 8) {
                    Text("Notes (Optional)")
                        .font(.spotifyLabelMedium)
                        .foregroundColor(.wiseSecondaryText)

                    ZStack(alignment: .topLeading) {
                        if notes.isEmpty {
                            Text("Add any additional details...")
                                .font(.spotifyBodyMedium)
                                .foregroundColor(.wisePlaceholderText)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 18)
                        }

                        TextEditor(text: $notes)
                            .font(.spotifyBodyMedium)
                            .foregroundColor(.wisePrimaryText)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .frame(minHeight: 100)
                            .scrollContentBackground(.hidden)
                            .focused($focusedField, equals: .notes)
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.wiseBorder.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.wiseBorder.opacity(0.3), lineWidth: 1)
                            )
                    )
                }

                Spacer(minLength: 20)
            }
            .padding(20)
        }
        .background(Color.wiseBackground)
    }
}

// MARK: - Preview

#Preview("Step 1 Details") {
    Step1DetailsView(
        title: .constant(""),
        totalAmount: .constant(""),
        date: .constant(Date()),
        category: .constant(.dining),
        notes: .constant("")
    )
}
