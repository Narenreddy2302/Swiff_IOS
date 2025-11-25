//
//  TransactionGroupHeader.swift
//  Swiff IOS
//
//  Created for Page 2 Task 2.1.6
//  Date grouping header for transaction lists
//

import SwiftUI
import Combine

struct TransactionGroupHeader: View {
    let date: Date
    let transactionCount: Int

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(dateLabel)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.wisePrimaryText)

                Text(fullDateString)
                    .font(.system(size: 13))
                    .foregroundColor(.wiseSecondaryText)
            }

            Spacer()

            Text("\(transactionCount) transaction\(transactionCount == 1 ? "" : "s")")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.wiseSecondaryText)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(Color.wiseBorder.opacity(0.3))
                )
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.8))
    }

    // MARK: - Computed Properties

    private var dateLabel: String {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let transactionDay = calendar.startOfDay(for: date)

        let daysDifference = calendar.dateComponents([.day], from: transactionDay, to: today).day ?? 0

        switch daysDifference {
        case 0:
            return "Today"
        case 1:
            return "Yesterday"
        case 2...6:
            return "This Week"
        case 7...13:
            return "Last Week"
        case 14...30:
            return "This Month"
        default:
            return "Earlier"
        }
    }

    private var fullDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d, yyyy"
        return formatter.string(from: date)
    }
}

// MARK: - Grouping Helper Extension
extension Array where Element == Transaction {
    /// Group transactions by date sections (Today, Yesterday, This Week, Earlier)
    func groupedByDateSections() -> [(sectionDate: Date, label: String, transactions: [Transaction])] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Sort transactions by date (newest first)
        let sorted = self.sorted { $0.date > $1.date }

        var groups: [Date: [Transaction]] = [:]

        for transaction in sorted {
            let transactionDay = calendar.startOfDay(for: transaction.date)
            let daysDifference = calendar.dateComponents([.day], from: transactionDay, to: today).day ?? 0

            // Determine section date based on grouping logic
            let sectionDate: Date
            switch daysDifference {
            case 0:
                // Today
                sectionDate = today
            case 1:
                // Yesterday
                sectionDate = calendar.date(byAdding: .day, value: -1, to: today)!
            case 2...6:
                // This Week - group all together
                sectionDate = calendar.date(byAdding: .day, value: -2, to: today)!
            default:
                // Earlier - group by actual day
                sectionDate = transactionDay
            }

            if groups[sectionDate] == nil {
                groups[sectionDate] = []
            }
            groups[sectionDate]?.append(transaction)
        }

        // Convert to array and sort by date (newest first)
        return groups.map { (sectionDate: $0.key, label: sectionLabel(for: $0.key), transactions: $0.value) }
            .sorted { $0.sectionDate > $1.sectionDate }
    }

    private func sectionLabel(for date: Date) -> String {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let sectionDay = calendar.startOfDay(for: date)

        let daysDifference = calendar.dateComponents([.day], from: sectionDay, to: today).day ?? 0

        switch daysDifference {
        case 0:
            return "Today"
        case 1:
            return "Yesterday"
        case 2...6:
            return "This Week"
        default:
            return "Earlier"
        }
    }
}

// MARK: - Preview
#Preview("Transaction Group Headers") {
    VStack(spacing: 20) {
        Text("Transaction List with Group Headers")
            .font(.title2)
            .fontWeight(.bold)
            .padding(.top)

        ScrollView {
            VStack(spacing: 0) {
                // Today
                TransactionGroupHeader(date: Date(), transactionCount: 5)

                // Yesterday
                TransactionGroupHeader(
                    date: Calendar.current.date(byAdding: .day, value: -1, to: Date())!,
                    transactionCount: 3
                )

                // This Week
                TransactionGroupHeader(
                    date: Calendar.current.date(byAdding: .day, value: -4, to: Date())!,
                    transactionCount: 12
                )

                // Earlier
                TransactionGroupHeader(
                    date: Calendar.current.date(byAdding: .day, value: -30, to: Date())!,
                    transactionCount: 45
                )
            }
        }

        Spacer()
    }
    .background(Color.gray.opacity(0.05))
}

#Preview("With Transactions") {
    VStack(spacing: 0) {
        TransactionGroupHeader(date: Date(), transactionCount: 2)

        VStack(spacing: 12) {
            // Mock transaction cards
            ForEach(0..<2) { index in
                HStack {
                    Circle()
                        .fill(Color.blue.opacity(0.2))
                        .frame(width: 48, height: 48)
                        .overlay(
                            Image(systemName: "fork.knife.circle.fill")
                                .foregroundColor(.blue)
                        )

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Transaction \(index + 1)")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Description • 2h ago")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Text("-$\(Double.random(in: 5...50), specifier: "%.2f")")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.red)
                }
                .padding()
                .background(Color.white)
                .cornerRadius(12)
            }
        }
        .padding()

        Spacer()
    }
    .background(Color.gray.opacity(0.05))
}
