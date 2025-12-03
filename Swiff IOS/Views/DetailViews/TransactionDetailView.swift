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
    @State private var showingReceiptFullscreen = false
    @State private var showingDuplicateAlert = false

    var transaction: Transaction? {
        dataManager.transactions.first { $0.id == transactionId }
    }

    var linkedSubscription: Subscription? {
        guard let transaction = transaction,
              let subscriptionId = transaction.linkedSubscriptionId else { return nil }
        return dataManager.subscriptions.first { $0.id == subscriptionId }
    }

    var amountColor: Color {
        guard let transaction = transaction else { return .wisePrimaryText }
        return transaction.isExpense ? .wiseError : .wiseBrightGreen
    }

    var relatedTransactions: [Transaction] {
        guard let transaction = transaction else { return [] }
        return dataManager.transactions.filter { t in
            t.id != transaction.id && (
                (transaction.merchant != nil && t.merchant == transaction.merchant) ||
                t.category == transaction.category
            )
        }
        .prefix(5)
        .map { $0 }
    }

    var body: some View {
        ScrollView {
            if let transaction = transaction {
                VStack(spacing: 24) {
                    // TASK 3.1: Enhanced Header with large category icon, title, type badge
                    VStack(spacing: 16) {
                        // Large Category Icon - 100pt gradient circle
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

                        // Title
                        Text(transaction.title)
                            .font(.spotifyDisplayMedium)
                            .foregroundColor(.wisePrimaryText)
                            .multilineTextAlignment(.center)

                        // Type Badge - [Expense] or [Income]
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

                    // TASK 3.2: Prominent amount card with sign indicator
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

                    // TASK 3.3: Details section with category, description, date/time, merchant info
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

                        // TASK 3.3: Merchant info
                        if let merchant = transaction.merchant, !merchant.isEmpty {
                            Divider()

                            VStack(alignment: .leading, spacing: 6) {
                                Text("Merchant")
                                    .font(.spotifyLabelSmall)
                                    .foregroundColor(.wiseSecondaryText)

                                Text(merchant)
                                    .font(.spotifyBodyMedium)
                                    .foregroundColor(.wisePrimaryText)
                            }
                        }

                        // TASK 3.9: Location display if available
                        if let location = transaction.location, !location.isEmpty {
                            Divider()

                            HStack(spacing: 6) {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Location")
                                        .font(.spotifyLabelSmall)
                                        .foregroundColor(.wiseSecondaryText)

                                    HStack(spacing: 6) {
                                        Image(systemName: "mappin.circle.fill")
                                            .font(.system(size: 14))
                                            .foregroundColor(.wiseBlue)
                                        Text(location)
                                            .font(.spotifyBodyMedium)
                                            .foregroundColor(.wisePrimaryText)
                                    }
                                }

                                Spacer()
                            }
                        }

                        // TASK 3.8: Payment method display
                        if let paymentMethod = transaction.paymentMethod {
                            Divider()

                            HStack {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Payment Method")
                                        .font(.spotifyLabelSmall)
                                        .foregroundColor(.wiseSecondaryText)

                                    HStack(spacing: 6) {
                                        Image(systemName: paymentMethod.icon)
                                            .font(.system(size: 14))
                                            .foregroundColor(.wiseBlue)
                                        Text(paymentMethod.rawValue)
                                            .font(.spotifyBodyMedium)
                                            .foregroundColor(.wisePrimaryText)
                                    }
                                }

                                Spacer()
                            }
                        }

                        // TASK 3.8: Payment status display
                        Divider()

                        HStack {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Payment Status")
                                    .font(.spotifyLabelSmall)
                                    .foregroundColor(.wiseSecondaryText)

                                TransactionStatusBadge(status: transaction.paymentStatus, size: .medium)
                            }

                            Spacer()
                        }

                        // Notes (if available)
                        if !transaction.notes.isEmpty {
                            Divider()

                            VStack(alignment: .leading, spacing: 6) {
                                Text("Notes")
                                    .font(.spotifyLabelSmall)
                                    .foregroundColor(.wiseSecondaryText)

                                Text(transaction.notes)
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

                    // TASK 3.4: Tags display using FlowLayout with pills
                    if !transaction.tags.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Tags")
                                .font(.spotifyHeadingMedium)
                                .foregroundColor(.wisePrimaryText)
                                .padding(.horizontal, 16)

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
                            .padding(.horizontal, 16)
                        }
                        .padding(.vertical, 16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.wiseCardBackground)
                        .cornerRadius(16)
                        .cardShadow()
                        .padding(.horizontal, 16)
                    }

                    // TASK 3.5: Recurring indicator badge if applicable
                    if transaction.isRecurring || transaction.isRecurringCharge {
                        HStack(spacing: 12) {
                            Image(systemName: "repeat.circle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.wiseBlue)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Recurring Transaction")
                                    .font(.spotifyBodyMedium)
                                    .foregroundColor(.wisePrimaryText)
                                    .fontWeight(.semibold)

                                Text("This transaction repeats automatically")
                                    .font(.spotifyLabelSmall)
                                    .foregroundColor(.wiseSecondaryText)
                            }

                            Spacer()
                        }
                        .padding(16)
                        .background(Color.wiseBlue.opacity(0.1))
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.wiseBlue.opacity(0.3), lineWidth: 1)
                        )
                        .padding(.horizontal, 16)
                    }

                    // TASK 3.6: Receipt image if attached (with zoom capability)
                    if let receiptData = transaction.receiptData,
                       let uiImage = UIImage(data: receiptData) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Receipt")
                                .font(.spotifyHeadingMedium)
                                .foregroundColor(.wisePrimaryText)
                                .padding(.horizontal, 16)

                            Button(action: { showingReceiptFullscreen = true }) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 200)
                                    .clipped()
                                    .cornerRadius(12)
                                    .overlay(
                                        ZStack {
                                            Color.black.opacity(0.3)

                                            VStack(spacing: 8) {
                                                Image(systemName: "arrow.up.left.and.arrow.down.right")
                                                    .font(.system(size: 24))
                                                    .foregroundColor(.white)

                                                Text("Tap to view full size")
                                                    .font(.spotifyLabelSmall)
                                                    .foregroundColor(.white)
                                            }
                                        }
                                        .cornerRadius(12)
                                    )
                            }
                            .padding(.horizontal, 16)
                        }
                        .padding(.vertical, 16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.wiseCardBackground)
                        .cornerRadius(16)
                        .cardShadow()
                        .padding(.horizontal, 16)
                    }

                    // TASK 3.7: Linked subscription badge with navigation
                    if let subscription = linkedSubscription {
                        NavigationLink(destination: SubscriptionDetailView(subscriptionId: subscription.id)) {
                            HStack(spacing: 12) {
                                // Subscription icon
                                UnifiedIconCircle(
                                    icon: subscription.icon,
                                    color: Color(hexString: subscription.color),
                                    size: 48,
                                    iconSize: 20
                                )

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Linked Subscription")
                                        .font(.spotifyLabelSmall)
                                        .foregroundColor(.wiseSecondaryText)

                                    Text(subscription.name)
                                        .font(.spotifyBodyMedium)
                                        .foregroundColor(.wisePrimaryText)
                                        .fontWeight(.semibold)

                                    Text(String(format: "$%.2f", subscription.price))
                                        .font(.spotifyLabelSmall)
                                        .foregroundColor(.wiseSecondaryText)
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.wiseSecondaryText)
                            }
                            .padding(16)
                            .background(Color.wiseCardBackground)
                            .cornerRadius(16)
                            .cardShadow()
                            .padding(.horizontal, 16)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }

                    // TASK 3.12: Related transactions section (same merchant/category)
                    if !relatedTransactions.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Related Transactions")
                                .font(.spotifyHeadingMedium)
                                .foregroundColor(.wisePrimaryText)
                                .padding(.horizontal, 16)

                            VStack(spacing: 8) {
                                ForEach(relatedTransactions) { relatedTx in
                                    NavigationLink(destination: TransactionDetailView(transactionId: relatedTx.id)) {
                                        HStack(spacing: 12) {
                                            UnifiedIconCircle(
                                                icon: relatedTx.category.icon,
                                                color: relatedTx.category.color,
                                                size: 40,
                                                iconSize: 18
                                            )

                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(relatedTx.title)
                                                    .font(.spotifyBodyMedium)
                                                    .foregroundColor(.wisePrimaryText)
                                                    .lineLimit(1)

                                                Text(relatedTx.date, style: .date)
                                                    .font(.spotifyLabelSmall)
                                                    .foregroundColor(.wiseSecondaryText)
                                            }

                                            Spacer()

                                            Text(relatedTx.amountWithSign)
                                                .font(.spotifyBodyMedium)
                                                .fontWeight(.semibold)
                                                .foregroundColor(relatedTx.isExpense ? .wiseError : .wiseBrightGreen)
                                        }
                                        .padding(12)
                                        .background(Color.wiseBackground)
                                        .cornerRadius(12)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                        .padding(.vertical, 16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.wiseCardBackground)
                        .cornerRadius(16)
                        .cardShadow()
                        .padding(.horizontal, 16)
                    }

                    // TASK 3.10 & 3.11: Actions Section - Duplicate and Delete
                    VStack(spacing: 12) {
                        // Duplicate button
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

                        // Delete button
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
                // TASK 3.11: Edit button
                Button(action: { showingEditSheet = true }) {
                    Text("Edit")
                        .font(.spotifyBodyMedium)
                        .foregroundColor(.wiseForestGreen)
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            // TASK 3.11: Edit flow preserving all fields
            if let transaction = transaction {
                EditTransactionSheet(transaction: transaction, onTransactionUpdated: {
                    showingEditSheet = false
                })
            }
        }
        .fullScreenCover(isPresented: $showingReceiptFullscreen) {
            // TASK 3.6: Full-screen receipt viewer with zoom
            if let receiptData = transaction?.receiptData,
               let uiImage = UIImage(data: receiptData) {
                ReceiptFullscreenViewer(image: uiImage, isPresented: $showingReceiptFullscreen)
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

    // TASK 3.10: Duplicate transaction with date set to today
    private func duplicateTransaction() {
        guard let transaction = transaction else { return }

        let duplicate = Transaction(
            title: transaction.title,
            subtitle: transaction.subtitle,
            amount: transaction.amount,
            category: transaction.category,
            date: Date(), // Set to today
            isRecurring: false, // Duplicates are not recurring
            tags: transaction.tags,
            merchant: transaction.merchant,
            paymentStatus: .completed, // Default to completed
            receiptData: transaction.receiptData,
            linkedSubscriptionId: transaction.linkedSubscriptionId,
            merchantCategory: transaction.merchantCategory,
            isRecurringCharge: false,
            paymentMethod: transaction.paymentMethod,
            location: transaction.location,
            notes: transaction.notes
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

// MARK: - Receipt Fullscreen Viewer
// TASK 3.6: Full-screen receipt viewer with zoom capability
private struct ReceiptFullscreenViewer: View {
    let image: UIImage
    @Binding var isPresented: Bool
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .scaleEffect(scale)
                .offset(offset)
                .gesture(
                    MagnificationGesture()
                        .onChanged { value in
                            let delta = value / lastScale
                            lastScale = value
                            scale = min(max(scale * delta, 1), 4)
                        }
                        .onEnded { _ in
                            lastScale = 1.0
                            if scale < 1 {
                                withAnimation(.spring()) {
                                    scale = 1
                                    offset = .zero
                                }
                            }
                        }
                )
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            offset = CGSize(
                                width: lastOffset.width + value.translation.width,
                                height: lastOffset.height + value.translation.height
                            )
                        }
                        .onEnded { _ in
                            lastOffset = offset
                        }
                )

            VStack {
                HStack {
                    Spacer()
                    Button(action: { isPresented = false }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.white)
                            .padding()
                    }
                }
                Spacer()
            }
        }
        .statusBar(hidden: true)
    }
}

// MARK: - Flow Layout for Tags
// TASK 3.4: FlowLayout for tag pills
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

// Note: Color.init(hex:) is defined in SupportingTypes.swift

#Preview {
    NavigationView {
        TransactionDetailView(transactionId: UUID())
            .environmentObject(DataManager.shared)
    }
}
