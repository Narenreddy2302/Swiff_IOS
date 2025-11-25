//
//  CSVExportService.swift
//  Swiff IOS
//
//  Created by Naren Reddy on 11/20/25.
//  Service for exporting data to CSV format
//

import Foundation
import Combine
import UIKit

@MainActor
class CSVExportService {
    static let shared = CSVExportService()

    init() {}

    // MARK: - CSV Export

    /// Export all data to CSV format
    func exportAllToCSV() throws -> URL {
        let tempDirectory = FileManager.default.temporaryDirectory
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let dateString = dateFormatter.string(from: Date())
        let filename = "swiff_export_\(dateString).zip"
        let _ = tempDirectory.appendingPathComponent(filename)

        // Create individual CSV files
        let peopleCSV = try exportPeopleToCSV()
        let groupsCSV = try exportGroupsToCSV()
        let subscriptionsCSV = try exportSubscriptionsToCSV()
        let transactionsCSV = try exportTransactionsToCSV()

        // Create a folder to store CSVs
        let exportFolder = tempDirectory.appendingPathComponent("swiff_export_\(dateString)")
        try FileManager.default.createDirectory(at: exportFolder, withIntermediateDirectories: true)

        // Write CSV files
        try peopleCSV.write(to: exportFolder.appendingPathComponent("people.csv"), atomically: true, encoding: .utf8)
        try groupsCSV.write(to: exportFolder.appendingPathComponent("groups.csv"), atomically: true, encoding: .utf8)
        try subscriptionsCSV.write(to: exportFolder.appendingPathComponent("subscriptions.csv"), atomically: true, encoding: .utf8)
        try transactionsCSV.write(to: exportFolder.appendingPathComponent("transactions.csv"), atomically: true, encoding: .utf8)

        // Create README
        let readme = createReadme()
        try readme.write(to: exportFolder.appendingPathComponent("README.txt"), atomically: true, encoding: .utf8)

        // Return the folder URL (iOS will handle sharing the folder)
        return exportFolder
    }

    /// Export people to CSV
    func exportPeopleToCSV() throws -> String {
        let people = try PersistenceService.shared.fetchAllPeople()

        var csv = "ID,Name,Email,Phone,Balance,Avatar Type,Created Date,Last Modified\n"

        for person in people {
            let row = [
                escapeCSVField(person.id.uuidString),
                escapeCSVField(person.name),
                escapeCSVField(person.email),
                escapeCSVField(person.phone),
                String(person.balance),
                escapeCSVField(person.avatarType.description),
                formatDate(person.createdDate),
                formatDate(person.lastModifiedDate)
            ].joined(separator: ",")

            csv += row + "\n"
        }

        return csv
    }

    /// Export groups to CSV
    func exportGroupsToCSV() throws -> String {
        let groups = try PersistenceService.shared.fetchAllGroups()

        var csv = "ID,Name,Description,Emoji,Member Count,Total Expenses,Created Date\n"

        for group in groups {
            let row = [
                escapeCSVField(group.id.uuidString),
                escapeCSVField(group.name),
                escapeCSVField(group.description),
                escapeCSVField(group.emoji),
                String(group.members.count),
                String(group.expenses.reduce(0) { $0 + $1.amount }),
                formatDate(group.createdDate)
            ].joined(separator: ",")

            csv += row + "\n"
        }

        return csv
    }

    /// Export subscriptions to CSV
    func exportSubscriptionsToCSV() throws -> String {
        let subscriptions = try PersistenceService.shared.fetchAllSubscriptions()

        var csv = "ID,Name,Description,Price,Billing Cycle,Category,Is Active,Is Shared,Created Date,Next Billing Date,Cancellation Date\n"

        for subscription in subscriptions {
            let row = [
                escapeCSVField(subscription.id.uuidString),
                escapeCSVField(subscription.name),
                escapeCSVField(subscription.description),
                String(subscription.price),
                escapeCSVField(subscription.billingCycle.rawValue),
                escapeCSVField(subscription.category.rawValue),
                subscription.isActive ? "Yes" : "No",
                subscription.isShared ? "Yes" : "No",
                formatDate(subscription.createdDate),
                formatDate(subscription.nextBillingDate),
                subscription.cancellationDate.map(formatDate) ?? ""
            ].joined(separator: ",")

            csv += row + "\n"
        }

        return csv
    }

    /// Export transactions to CSV
    func exportTransactionsToCSV() throws -> String {
        let transactions = try PersistenceService.shared.fetchAllTransactions()
        return generateTransactionsCSV(from: transactions)
    }

    /// Export specific transactions to CSV
    func exportTransactions(_ transactions: [Transaction]) -> URL {
        let csv = generateTransactionsCSV(from: transactions)

        // Create temporary file
        let tempDirectory = FileManager.default.temporaryDirectory
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let dateString = dateFormatter.string(from: Date())
        let filename = "transactions_\(dateString).csv"
        let fileURL = tempDirectory.appendingPathComponent(filename)

        // Write CSV to file
        do {
            try csv.write(to: fileURL, atomically: true, encoding: .utf8)

            // Share the file
            #if os(iOS)
            DispatchQueue.main.async {
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let window = windowScene.windows.first,
                   let rootViewController = window.rootViewController {
                    let activityVC = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)
                    rootViewController.present(activityVC, animated: true)
                }
            }
            #endif

            return fileURL
        } catch {
            print("❌ Error exporting transactions: \(error.localizedDescription)")
            return fileURL
        }
    }

    /// Generate CSV for a specific person's transactions
    func generateCSV(transactions: [Transaction], person: Person) -> String {
        var csv = "# Transactions with \(person.name)\n"
        csv += "# Exported on \(formatDate(Date()))\n"
        csv += "# Total transactions: \(transactions.count)\n"
        csv += "\n"
        csv += generateTransactionsCSV(from: transactions)
        return csv
    }

    /// Generate CSV string from transactions array
    private func generateTransactionsCSV(from transactions: [Transaction]) -> String {
        var csv = "ID,Title,Subtitle,Amount,Category,Is Expense,Is Recurring,Date,Tags,Merchant,Payment Status,Has Receipt,Linked Subscription\n"

        for transaction in transactions {
            let row = [
                escapeCSVField(transaction.id.uuidString),
                escapeCSVField(transaction.title),
                escapeCSVField(transaction.subtitle),
                String(transaction.amount),
                escapeCSVField(transaction.category.rawValue),
                transaction.isExpense ? "Yes" : "No",
                transaction.isRecurring ? "Yes" : "No",
                formatDate(transaction.date),
                escapeCSVField(transaction.tags.joined(separator: "; ")),
                escapeCSVField(transaction.merchant ?? ""),
                escapeCSVField(transaction.paymentStatus.rawValue),
                transaction.hasReceipt ? "Yes" : "No",
                transaction.linkedSubscriptionId?.uuidString ?? ""
            ].joined(separator: ",")

            csv += row + "\n"
        }

        return csv
    }

    // MARK: - Helper Methods

    /// Escape CSV field to handle commas, quotes, and newlines
    private func escapeCSVField(_ field: String) -> String {
        // If field contains comma, quote, or newline, wrap in quotes and escape quotes
        if field.contains(",") || field.contains("\"") || field.contains("\n") {
            let escaped = field.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(escaped)\""
        }
        return field
    }

    /// Format date for CSV
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.string(from: date)
    }

    /// Create README file
    private func createReadme() -> String {
        return """
        Swiff Data Export
        =================

        Export Date: \(formatDate(Date()))

        This folder contains your Swiff data exported to CSV format.

        Files included:
        - people.csv: All contacts and their balances
        - groups.csv: All groups and their members
        - subscriptions.csv: All subscription details
        - transactions.csv: All transaction history

        CSV Format:
        - Dates are in format: yyyy-MM-dd HH:mm:ss
        - Text fields containing commas are quoted
        - All amounts are in your selected currency

        To import this data:
        1. Open the CSV files in a spreadsheet application (Excel, Numbers, Google Sheets)
        2. Or use the Swiff app's import feature (JSON format recommended)

        Note: For full data preservation including relationships and metadata,
        use the JSON export format instead.

        Questions? Contact support@swiffapp.com
        """
    }
}

// MARK: - AvatarType Extension

extension AvatarType {
    var description: String {
        switch self {
        case .emoji(let emoji):
            return "Emoji: \(emoji)"
        case .photo:
            return "Photo"
        case .initials(let initials, _):
            return "Initials: \(initials)"
        }
    }
}
