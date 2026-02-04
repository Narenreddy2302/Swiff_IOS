//
//  TransactionDetailSheet.swift
//  Swiff IOS
//
//  Detailed view of a transaction with full history and actions
//  Features: Comments, payment options, edit/delete, share
//  Created: 2026-02-04
//

import SwiftUI

// MARK: - Transaction Detail Sheet

/// Full detail view for a transaction, shown as a sheet
/// Includes comments, history, and action buttons
struct TransactionDetailSheet: View {
    
    // MARK: - Properties
    
    let transaction: FeedTransaction
    
    @Environment(\.dismiss) private var dismiss
    @State private var commentText = ""
    @State private var showingPaymentSheet = false
    @State private var showingEditSheet = false
    @State private var showingShareSheet = false
    @State private var showingDeleteConfirm = false
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // Main Transaction Card
                    mainTransactionCard
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                    
                    // Action Buttons
                    actionButtons
                        .padding(.horizontal, 16)
                        .padding(.top, 20)
                    
                    // Divider
                    Divider()
                        .padding(.vertical, 20)
                    
                    // Transaction Details
                    detailsSection
                        .padding(.horizontal, 16)
                    
                    // Divider
                    Divider()
                        .padding(.vertical, 20)
                    
                    // Comments Section
                    commentsSection
                        .padding(.horizontal, 16)
                    
                    Spacer(minLength: 100)
                }
            }
            .background(Theme.Colors.background)
            .navigationTitle("Transaction")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(Theme.Colors.brandPrimary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: { showingEditSheet = true }) {
                            Label("Edit", systemImage: "pencil")
                        }
                        
                        Button(action: { showingShareSheet = true }) {
                            Label("Share", systemImage: "square.and.arrow.up")
                        }
                        
                        Divider()
                        
                        Button(role: .destructive, action: { showingDeleteConfirm = true }) {
                            Label("Delete", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(Theme.Colors.brandPrimary)
                    }
                }
            }
        }
        .alert("Delete Transaction?", isPresented: $showingDeleteConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                // Delete transaction
                dismiss()
            }
        } message: {
            Text("This action cannot be undone.")
        }
    }
    
    // MARK: - Main Transaction Card
    
    private var mainTransactionCard: some View {
        VStack(spacing: 16) {
            // Person Header
            HStack(spacing: 12) {
                // Avatar
                ZStack {
                    Circle()
                        .fill(transaction.avatarColor.opacity(0.15))
                        .frame(width: 56, height: 56)
                    
                    Text(transaction.initials)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(transaction.avatarColor)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Text(transaction.personName)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(Theme.Colors.textPrimary)
                        
                        if transaction.isVerified {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 14))
                                .foregroundColor(Theme.Colors.brandPrimary)
                        }
                    }
                    
                    Text(transaction.category)
                        .font(.system(size: 14))
                        .foregroundColor(Theme.Colors.textSecondary)
                }
                
                Spacer()
            }
            
            // Description
            Text(transaction.description)
                .font(.system(size: 16))
                .foregroundColor(Theme.Colors.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Amount Display
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(transaction.statusText)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Theme.Colors.textSecondary)
                    
                    Text(transaction.formattedAmount)
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(transaction.amountColor)
                }
                
                Spacer()
                
                // Status Badge
                HStack(spacing: 6) {
                    Image(systemName: transaction.isSettled ? "checkmark.circle.fill" : "clock")
                        .font(.system(size: 14))
                    
                    Text(transaction.isSettled ? "Settled" : "Pending")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(transaction.isSettled ? Theme.Colors.success : Theme.Colors.warning)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    (transaction.isSettled ? Theme.Colors.success : Theme.Colors.warning)
                        .opacity(0.12)
                )
                .cornerRadius(20)
            }
        }
        .padding(20)
        .background(Theme.Colors.cardBackground)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Theme.Colors.border, lineWidth: 1)
        )
    }
    
    // MARK: - Action Buttons
    
    private var actionButtons: some View {
        HStack(spacing: 12) {
            if !transaction.isSettled {
                // Pay/Request Button
                Button(action: { showingPaymentSheet = true }) {
                    HStack(spacing: 8) {
                        Image(systemName: transaction.balanceType == .youOwe ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                            .font(.system(size: 16, weight: .semibold))
                        
                        Text(transaction.balanceType == .youOwe ? "Pay Now" : "Request")
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Theme.Colors.brandPrimary)
                    .foregroundColor(Theme.Colors.textOnPrimary)
                    .cornerRadius(12)
                }
                
                // Remind Button
                Button(action: {
                    HapticManager.shared.light()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "bell")
                            .font(.system(size: 16, weight: .semibold))
                        
                        Text("Remind")
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Theme.Colors.cardBackground)
                    .foregroundColor(Theme.Colors.textPrimary)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Theme.Colors.border, lineWidth: 1)
                    )
                }
            } else {
                // Already Settled
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 16, weight: .semibold))
                    
                    Text("This transaction is settled")
                        .font(.system(size: 15, weight: .semibold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Theme.Colors.success.opacity(0.12))
                .foregroundColor(Theme.Colors.success)
                .cornerRadius(12)
            }
        }
    }
    
    // MARK: - Details Section
    
    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Details")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(Theme.Colors.textPrimary)
            
            VStack(spacing: 12) {
                DetailRow(label: "Date", value: formattedDate)
                DetailRow(label: "Category", value: transaction.category)
                
                if let splitMethod = transaction.splitMethod {
                    DetailRow(label: "Split Method", value: splitMethod)
                }
                
                if !transaction.participants.isEmpty {
                    DetailRow(label: "Participants", value: transaction.participants.joined(separator: ", "))
                }
            }
        }
    }
    
    // MARK: - Comments Section
    
    private var commentsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Comments")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Theme.Colors.textPrimary)
                
                Text("(\(transaction.commentCount))")
                    .font(.system(size: 16))
                    .foregroundColor(Theme.Colors.textSecondary)
                
                Spacer()
            }
            
            // Comment Input
            HStack(spacing: 12) {
                Circle()
                    .fill(Theme.Colors.brandPrimary.opacity(0.15))
                    .frame(width: 36, height: 36)
                    .overlay(
                        Text("Y")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Theme.Colors.brandPrimary)
                    )
                
                TextField("Add a comment...", text: $commentText)
                    .font(.system(size: 15))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Theme.Colors.cardBackground)
                    .cornerRadius(20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Theme.Colors.border, lineWidth: 1)
                    )
                
                if !commentText.isEmpty {
                    Button(action: {
                        HapticManager.shared.impact(.light)
                        commentText = ""
                    }) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(Theme.Colors.brandPrimary)
                    }
                }
            }
            
            // Mock Comments
            if transaction.commentCount > 0 {
                VStack(spacing: 16) {
                    CommentRow(
                        name: "Sarah",
                        initials: "S",
                        color: Theme.Colors.info,
                        text: "Thanks for covering! I'll pay you back tomorrow 🙏",
                        timeAgo: "2h ago"
                    )
                }
                .padding(.top, 8)
            }
        }
    }
    
    // MARK: - Helpers
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: transaction.timestamp)
    }
}

// MARK: - Detail Row

struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 14))
                .foregroundColor(Theme.Colors.textSecondary)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Theme.Colors.textPrimary)
                .multilineTextAlignment(.trailing)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Theme.Colors.cardBackground)
        .cornerRadius(8)
    }
}

// MARK: - Comment Row

struct CommentRow: View {
    let name: String
    let initials: String
    let color: Color
    let text: String
    let timeAgo: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Circle()
                .fill(color.opacity(0.15))
                .frame(width: 32, height: 32)
                .overlay(
                    Text(initials)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(color)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Text(name)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Theme.Colors.textPrimary)
                    
                    Text("· \(timeAgo)")
                        .font(.system(size: 13))
                        .foregroundColor(Theme.Colors.textTertiary)
                }
                
                Text(text)
                    .font(.system(size: 14))
                    .foregroundColor(Theme.Colors.textPrimary)
            }
            
            Spacer()
        }
    }
}

// MARK: - Preview

#Preview {
    TransactionDetailSheet(transaction: FeedTransaction.mockData[0])
}
