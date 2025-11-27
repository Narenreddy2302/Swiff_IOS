//
//  TransactionDetailView.swift
//  Swiff IOS
//
//  Created by Naren Reddy on 11/20/25.
//  Detailed view for transaction management
//

import SwiftUI
import Combine

struct TransactionDetailView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataManager: DataManager

    let transactionId: UUID
    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false
    @State private var showingDuplicateAlert = false

    var transaction: Transaction? {
        dataManager.transactions.first { $0.id == transactionId }
    }

    var amountColor: Color {
        guard let transaction = transaction else { return .wisePrimaryText }
        return transaction.isExpense ? .wiseError : .wiseBrightGreen
    }

    var body: some View {
        ScrollView {
            if let transaction = transaction {
                VStack(spacing: 24) {
                    // Header Section
                    VStack(spacing: 16) {
                        // Large Category Icon
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        transaction.category.color.opacity(0.3),
                                        transaction.category.color.opacity(0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 100, height: 100)
                            .overlay(
                                Image(systemName: transaction.category.icon)
                                    .font(.system(size: 48))
                                    .foregroundColor(transaction.category.color)
                            )

                        Text(transaction.title)
                            .font(.spotifyDisplayMedium)
                            .foregroundColor(.wisePrimaryText)
                            .multilineTextAlignment(.center)

                        // Type Badge
                        HStack(spacing: 4) {
                            Image(systemName: transaction.isExpense ? "arrow.down.circle.fill" : "arrow.up.circle.fill")
                                .font(.system(size: 12))
                            Text(transaction.isExpense ? "Expense" : "Income")
                                .font(.spotifyLabelMedium)
                        }
                        .foregroundColor(amountColor)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(amountColor.opacity(0.1))
                        .cornerRadius(20)
                    }
                    .padding(.top, 20)

                    // Amount Card
                    VStack(spacing: 12) {
                        Text("Amount")
                            .font(.spotifyLabelLarge)
                            .foregroundColor(.wiseSecondaryText)

                        Text(transaction.amountWithSign)
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundColor(amountColor)

                        Text(transaction.formattedAmount)
                            .font(.spotifyBodyMedium)
                            .foregroundColor(.wiseSecondaryText)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
                    .background(Color.wiseCardBackground)
                    .cornerRadius(16)
                    .cardShadow()
                    .padding(.horizontal, 16)

                    // Details Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Details")
                            .font(.spotifyHeadingMedium)
                            .foregroundColor(.wisePrimaryText)

                        // Category
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Category")
                                    .font(.spotifyLabelSmall)
                                    .foregroundColor(.wiseSecondaryText)

                                HStack(spacing: 6) {
                                    Image(systemName: transaction.category.icon)
                                        .font(.system(size: 14))
                                        .foregroundColor(transaction.category.color)
                                    Text(transaction.category.rawValue)
                                        .font(.spotifyBodyMedium)
                                        .foregroundColor(.wisePrimaryText)
                                }
                            }

                            Spacer()
                        }

                        Divider()

                        // Description
                        if !transaction.subtitle.isEmpty {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Description")
                                    .font(.spotifyLabelSmall)
                                    .foregroundColor(.wiseSecondaryText)

                                Text(transaction.subtitle)
                                    .font(.spotifyBodyMedium)
                                    .foregroundColor(.wisePrimaryText)
                            }

                            Divider()
                        }

                        // Date & Time
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Date")
                                    .font(.spotifyLabelSmall)
                                    .foregroundColor(.wiseSecondaryText)

                                Text(transaction.date, style: .date)
                                    .font(.spotifyBodyMedium)
                                    .foregroundColor(.wisePrimaryText)
                            }

                            Spacer()

                            VStack(alignment: .trailing, spacing: 4) {
                                Text("Time")
                                    .font(.spotifyLabelSmall)
                                    .foregroundColor(.wiseSecondaryText)

                                Text(transaction.date, style: .time)
                                    .font(.spotifyBodyMedium)
                                    .foregroundColor(.wisePrimaryText)
                            }
                        }

                        // Tags
                        if !transaction.tags.isEmpty {
                            Divider()

                            VStack(alignment: .leading, spacing: 8) {
                                Text("Tags")
                                    .font(.spotifyLabelSmall)
                                    .foregroundColor(.wiseSecondaryText)

                                FlowLayout(spacing: 8) {
                                    ForEach(transaction.tags, id: \.self) { tag in
                                        Text(tag)
                                            .font(.spotifyLabelSmall)
                                            .foregroundColor(.wiseForestGreen)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(Color.wiseForestGreen.opacity(0.1))
                                            .cornerRadius(16)
                                    }
                                }
                            }
                        }

                        // Recurring status
                        if transaction.isRecurring {
                            Divider()

                            HStack {
                                Image(systemName: "repeat.circle.fill")
                                    .foregroundColor(.wiseBlue)
                                Text("Recurring Transaction")
                                    .font(.spotifyBodyMedium)
                                    .foregroundColor(.wisePrimaryText)
                            }
                        }
                    }
                    .padding(16)
                    .background(Color.wiseCardBackground)
                    .cornerRadius(16)
                    .cardShadow()
                    .padding(.horizontal, 16)

                    // Actions Section
                    VStack(spacing: 12) {
                        Button(action: { duplicateTransaction() }) {
                            HStack {
                                Image(systemName: "doc.on.doc.fill")
                                    .font(.system(size: 18))
                                Text("Duplicate Transaction")
                                    .font(.spotifyBodyLarge)
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.wiseBlue)
                            .cornerRadius(12)
                        }

                        Button(action: { showingDeleteAlert = true }) {
                            Text("Delete Transaction")
                                .font(.spotifyBodyMedium)
                                .foregroundColor(.wiseError)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 40)
                }
            } else {
                // Transaction not found
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 48))
                        .foregroundColor(.wiseError)

                    Text("Transaction not found")
                        .font(.spotifyHeadingMedium)
                        .foregroundColor(.wisePrimaryText)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(Color.wiseBackground)
        .navigationTitle(transaction?.title ?? "Transaction")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingEditSheet = true }) {
                    Text("Edit")
                        .font(.spotifyBodyMedium)
                        .foregroundColor(.wiseForestGreen)
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            if let transaction = transaction {
                EditTransactionSheet(transaction: transaction, onTransactionUpdated: {
                    showingEditSheet = false
                })
            }
        }
        .alert("Delete Transaction?", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                deleteTransaction()
            }
        } message: {
            if let transaction = transaction {
                Text("This will permanently delete this \(transaction.isExpense ? "expense" : "income") of \(transaction.formattedAmount).")
            }
        }
    }

    // MARK: - Helper Functions

    private func duplicateTransaction() {
        guard let transaction = transaction else { return }

        let duplicate = Transaction(
            title: transaction.title,
            subtitle: transaction.subtitle,
            amount: transaction.amount,
            category: transaction.category,
            date: Date(),
            isRecurring: false,
            tags: transaction.tags
        )

        do {
            try dataManager.addTransaction(duplicate)
            dismiss()
        } catch {
            dataManager.error = error
        }
    }

    private func deleteTransaction() {
        guard let transaction = transaction else { return }
        do {
            try dataManager.deleteTransaction(id: transaction.id)
            dismiss()
        } catch {
            dataManager.error = error
        }
    }
}

// MARK: - Flow Layout for Tags
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowLayoutResult(in: proposal.replacingUnspecifiedDimensions().width, subviews: subviews, spacing: spacing)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowLayoutResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.frames[index].minX, y: bounds.minY + result.frames[index].minY), proposal: .unspecified)
        }
    }

    struct FlowLayoutResult {
        var frames: [CGRect] = []
        var size: CGSize = .zero

        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var currentX: CGFloat = 0
            var currentY: CGFloat = 0
            var lineHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)

                if currentX + size.width > maxWidth && currentX > 0 {
                    currentX = 0
                    currentY += lineHeight + spacing
                    lineHeight = 0
                }

                frames.append(CGRect(x: currentX, y: currentY, width: size.width, height: size.height))
                lineHeight = max(lineHeight, size.height)
                currentX += size.width + spacing
            }

            self.size = CGSize(width: maxWidth, height: currentY + lineHeight)
        }
    }
}

#Preview {
    NavigationView {
        TransactionDetailView(transactionId: UUID())
            .environmentObject(DataManager.shared)
    }
}
