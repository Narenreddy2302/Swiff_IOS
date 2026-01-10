//
//  BalanceDetailView.swift
//  Swiff IOS
//
//  Created by Naren Reddy on 11/20/25.
//  Detailed balance breakdown view with comprehensive features
//

import SwiftUI
import Combine
import Charts

struct BalanceDetailView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataManager: DataManager

    // MARK: - State Properties
    @State private var selectedFilter: BalanceFilter = .all
    @State private var showingExportSheet = false
    @State private var selectedPerson: Person? = nil
    @State private var showingPersonDetail = false
    @State private var isRefreshing = false

    // MARK: - Computed Properties

    var totalBalance: Double {
        let peopleBalance = dataManager.people.reduce(0.0) { $0 + $1.balance }
        let netIncome = dataManager.getNetMonthlyIncome()
        return peopleBalance + netIncome
    }

    var peopleBalances: [(person: Person, balance: Double)] {
        let allBalances = dataManager.people
            .map { (person: $0, balance: $0.balance) }
            .filter { $0.balance != 0 }
            .sorted { abs($0.balance) > abs($1.balance) }

        switch selectedFilter {
        case .all:
            return allBalances
        case .positive:
            return allBalances.filter { $0.balance > 0 }
        case .negative:
            return allBalances.filter { $0.balance < 0 }
        }
    }

    // Task 4.7: Balance forecast based on recurring transactions
    var forecastedBalance: Double {
        let recurringTransactions = dataManager.getRecurringTransactions()
        let monthlyRecurringTotal = recurringTransactions.reduce(0.0) { $0 + $1.amount }
        return totalBalance + monthlyRecurringTotal
    }

    // Task 4.5: Balance trend data for chart (last 8 weeks)
    var balanceTrendData: [BalanceTrendPoint] {
        let calendar = Calendar.current
        let today = Date()
        var trendPoints: [BalanceTrendPoint] = []

        // Get all transactions sorted by date
        let allTransactions = dataManager.transactions.sorted { $0.date < $1.date }

        for weekOffset in (0..<8).reversed() {
            guard let weekDate = calendar.date(byAdding: .weekOfYear, value: -weekOffset, to: today) else { continue }
            let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: weekDate)) ?? weekDate

            // Calculate cumulative balance up to this week
            let transactionsUpToWeek = allTransactions.filter { $0.date <= startOfWeek }
            let transactionBalance = transactionsUpToWeek.reduce(0.0) { $0 + $1.amount }

            // Add people balances (approximation - in real app would track historical)
            let weekBalance = transactionBalance

            trendPoints.append(BalanceTrendPoint(
                date: startOfWeek,
                balance: weekBalance,
                weekLabel: "W\(9 - weekOffset)"
            ))
        }

        return trendPoints
    }

    // MARK: - Body

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Task 4.1: Large total balance display at top with color-coded amount
                    totalBalanceCard

                    // Task 4.5: Balance trend chart showing weekly changes
                    balanceTrendChart

                    // Task 4.2 & 4.3: Breakdown section with Net This Month and people balances
                    breakdownSection

                    // Task 4.4: Summary section with "You Owe" and "You're Owed" totals
                    summarySection

                    // Task 4.7: Balance forecast
                    forecastSection

                    // Task 4.9: Export balance report
                    exportSection
                }
                .padding(16)
            }
            .background(Color.wiseBackground)
            .navigationTitle("Balance Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.wiseForestGreen)
                }
            }
            .refreshable {
                await refreshData()
            }
            .sheet(isPresented: $showingExportSheet) {
                BalanceExportView(
                    totalBalance: totalBalance,
                    peopleBalances: peopleBalances,
                    netMonthlyIncome: dataManager.getNetMonthlyIncome()
                )
            }
            .sheet(item: $selectedPerson) { person in
                PersonDetailView(personId: person.id)
                    .environmentObject(dataManager)
            }
        }
    }

    // MARK: - Task 4.1: Total Balance Card

    private var totalBalanceCard: some View {
        VStack(spacing: 12) {
            Text("Total Balance")
                .font(.spotifyHeadingSmall)
                .foregroundColor(.wiseSecondaryText)

            Text(formatCurrency(totalBalance))
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundColor(totalBalance >= 0 ? .wiseBrightGreen : .wiseError)

            HStack(spacing: 4) {
                Image(systemName: totalBalance >= 0 ? "arrow.up.right" : "arrow.down.right")
                    .font(.caption)
                Text(totalBalance >= 0 ? "Positive Balance" : "Negative Balance")
                    .font(.spotifyCaptionMedium)
            }
            .foregroundColor(totalBalance >= 0 ? .wiseBrightGreen : .wiseError)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .background(Color.wiseCardBackground)
        .cornerRadius(16)
        .cardShadow()
    }

    // MARK: - Task 4.5: Balance Trend Chart

    private var balanceTrendChart: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Balance Trend")
                .font(.spotifyHeadingMedium)
                .foregroundColor(.wisePrimaryText)

            if !balanceTrendData.isEmpty {
                Chart(balanceTrendData) { dataPoint in
                    LineMark(
                        x: .value("Week", dataPoint.weekLabel),
                        y: .value("Balance", dataPoint.balance)
                    )
                    .foregroundStyle(dataPoint.balance >= 0 ? Color.wiseBrightGreen : Color.wiseError)
                    .lineStyle(StrokeStyle(lineWidth: 3))

                    AreaMark(
                        x: .value("Week", dataPoint.weekLabel),
                        y: .value("Balance", dataPoint.balance)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                (dataPoint.balance >= 0 ? Color.wiseBrightGreen : Color.wiseError).opacity(0.3),
                                (dataPoint.balance >= 0 ? Color.wiseBrightGreen : Color.wiseError).opacity(0.05)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                    PointMark(
                        x: .value("Week", dataPoint.weekLabel),
                        y: .value("Balance", dataPoint.balance)
                    )
                    .foregroundStyle(dataPoint.balance >= 0 ? Color.wiseBrightGreen : Color.wiseError)
                }
                .frame(height: 200)
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let balance = value.as(Double.self) {
                                Text(formatCurrencyShort(balance))
                                    .font(.caption2)
                            }
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks { value in
                        AxisValueLabel {
                            if let label = value.as(String.self) {
                                Text(label)
                                    .font(.caption2)
                            }
                        }
                    }
                }
            } else {
                Text("No trend data available")
                    .font(.spotifyBodyMedium)
                    .foregroundColor(.wiseSecondaryText)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 40)
            }
        }
        .padding(16)
        .background(Color.wiseCardBackground)
        .cornerRadius(16)
        .cardShadow()
    }

    // MARK: - Task 4.2 & 4.3: Breakdown Section

    private var breakdownSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Balance Breakdown")
                    .font(.spotifyHeadingMedium)
                    .foregroundColor(.wisePrimaryText)

                Spacer()

                // Task 4.8: Filter by positive/negative balances
                Menu {
                    Button {
                        selectedFilter = .all
                    } label: {
                        Label("All Balances", systemImage: selectedFilter == .all ? "checkmark" : "")
                    }

                    Button {
                        selectedFilter = .positive
                    } label: {
                        Label("Owed to You", systemImage: selectedFilter == .positive ? "checkmark" : "")
                    }

                    Button {
                        selectedFilter = .negative
                    } label: {
                        Label("You Owe", systemImage: selectedFilter == .negative ? "checkmark" : "")
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(selectedFilter.displayName)
                            .font(.spotifyCaptionMedium)
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .font(.system(size: 14))
                    }
                    .foregroundColor(.wiseForestGreen)
                }
            }

            // Task 4.2: Net Income/Expenses
            BalanceBreakdownRow(
                title: "Net This Month",
                subtitle: "Income - Expenses",
                amount: dataManager.getNetMonthlyIncome(),
                icon: "chart.bar.fill",
                iconColor: .wiseBlue
            )

            // Task 4.3: People Balances
            if !peopleBalances.isEmpty {
                Divider()
                    .padding(.vertical, 8)

                Text("People Balances")
                    .font(.spotifyLabelLarge)
                    .foregroundColor(.wiseSecondaryText)

                ForEach(peopleBalances, id: \.person.id) { item in
                    // Task 4.6 & 4.10: Quick settle actions and drill-down
                    PersonBalanceRowWithActions(
                        person: item.person,
                        balance: item.balance,
                        onTap: {
                            selectedPerson = item.person
                            showingPersonDetail = true
                        },
                        onSettle: {
                            settleBalance(for: item.person)
                        }
                    )
                }
            } else {
                Text("No balances to show")
                    .font(.spotifyBodyMedium)
                    .foregroundColor(.wiseSecondaryText)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            }
        }
        .padding(16)
        .background(Color.wiseCardBackground)
        .cornerRadius(16)
        .cardShadow()
    }

    // MARK: - Task 4.4: Summary Section

    private var summarySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Summary")
                .font(.spotifyHeadingMedium)
                .foregroundColor(.wisePrimaryText)

            HStack(spacing: 12) {
                // You Owe
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color.wiseError.opacity(0.2))
                            .frame(width: 32, height: 32)
                            .overlay(
                                Image(systemName: "arrow.down.circle.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(.wiseError)
                            )

                        Text("You Owe")
                            .font(.spotifyCaptionMedium)
                            .foregroundColor(.wiseSecondaryText)
                    }

                    Text(formatCurrency(calculateTotalOwed()))
                        .font(.spotifyNumberLarge)
                        .foregroundColor(.wiseError)

                    Text("\(peopleBalances.filter { $0.balance < 0 }.count) people")
                        .font(.caption2)
                        .foregroundColor(.wiseSecondaryText)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(Color.wiseError.opacity(0.05))
                .cornerRadius(12)

                // You're Owed
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color.wiseBrightGreen.opacity(0.2))
                            .frame(width: 32, height: 32)
                            .overlay(
                                Image(systemName: "arrow.up.circle.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(.wiseBrightGreen)
                            )

                        Text("You're Owed")
                            .font(.spotifyCaptionMedium)
                            .foregroundColor(.wiseSecondaryText)
                    }

                    Text(formatCurrency(calculateTotalOwedToYou()))
                        .font(.spotifyNumberLarge)
                        .foregroundColor(.wiseBrightGreen)

                    Text("\(peopleBalances.filter { $0.balance > 0 }.count) people")
                        .font(.caption2)
                        .foregroundColor(.wiseSecondaryText)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(Color.wiseBrightGreen.opacity(0.05))
                .cornerRadius(12)
            }
        }
        .padding(16)
        .background(Color.wiseCardBackground)
        .cornerRadius(16)
        .cardShadow()
    }

    // MARK: - Task 4.7: Forecast Section

    private var forecastSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "crystal.ball.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.wiseBlue)

                Text("Balance Forecast")
                    .font(.spotifyHeadingMedium)
                    .foregroundColor(.wisePrimaryText)
            }

            Text("Based on recurring transactions")
                .font(.spotifyCaptionMedium)
                .foregroundColor(.wiseSecondaryText)

            HStack(alignment: .bottom, spacing: 8) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Current")
                        .font(.caption2)
                        .foregroundColor(.wiseSecondaryText)
                    Text(formatCurrency(totalBalance))
                        .font(.spotifyNumberMedium)
                        .foregroundColor(.wisePrimaryText)
                }

                Image(systemName: "arrow.right")
                    .foregroundColor(.wiseSecondaryText)
                    .padding(.bottom, 8)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Next Month")
                        .font(.caption2)
                        .foregroundColor(.wiseSecondaryText)
                    Text(formatCurrency(forecastedBalance))
                        .font(.spotifyNumberMedium)
                        .foregroundColor(forecastedBalance >= 0 ? .wiseBrightGreen : .wiseError)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Change")
                        .font(.caption2)
                        .foregroundColor(.wiseSecondaryText)
                    HStack(spacing: 4) {
                        Image(systemName: (forecastedBalance - totalBalance) >= 0 ? "arrow.up" : "arrow.down")
                            .font(.caption2)
                        Text(formatCurrency(abs(forecastedBalance - totalBalance)))
                            .font(.spotifyNumberMedium)
                    }
                    .foregroundColor((forecastedBalance - totalBalance) >= 0 ? .wiseBrightGreen : .wiseError)
                }
            }
            .padding(12)
            .background(Color.wiseBorder.opacity(0.2))
            .cornerRadius(12)
        }
        .padding(16)
        .background(Color.wiseCardBackground)
        .cornerRadius(16)
        .cardShadow()
    }

    // MARK: - Task 4.9: Export Section

    private var exportSection: some View {
        Button {
            showingExportSheet = true
        } label: {
            HStack {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 18))

                Text("Export Balance Report")
                    .font(.spotifyBodyMedium)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(.wiseSecondaryText)
            }
            .foregroundColor(.wisePrimaryText)
            .padding(16)
            .background(Color.wiseCardBackground)
            .cornerRadius(16)
            .cardShadow()
        }
    }

    // MARK: - Helper Methods

    private func calculateTotalOwed() -> Double {
        dataManager.people.filter { $0.balance < 0 }.reduce(0.0) { $0 + abs($1.balance) }
    }

    private func calculateTotalOwedToYou() -> Double {
        dataManager.people.filter { $0.balance > 0 }.reduce(0.0) { $0 + $1.balance }
    }

    private func formatCurrency(_ amount: Double) -> String {
        String(format: "$%.2f", abs(amount))
    }

    private func formatCurrencyShort(_ amount: Double) -> String {
        let absAmount = abs(amount)
        if absAmount >= 1000 {
            return String(format: "$%.1fk", absAmount / 1000)
        }
        return String(format: "$%.0f", absAmount)
    }

    // Task 4.6: Quick settle action
    private func settleBalance(for person: Person) {
        var updatedPerson = person
        updatedPerson.balance = 0.0

        do {
            try dataManager.updatePerson(updatedPerson)
        } catch {
            print("Error settling balance: \(error)")
        }
    }

    private func refreshData() async {
        isRefreshing = true
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        dataManager.refreshAllData()
        isRefreshing = false
    }
}

// MARK: - Balance Filter Enum

enum BalanceFilter {
    case all
    case positive
    case negative

    var displayName: String {
        switch self {
        case .all: return "All"
        case .positive: return "Owed to You"
        case .negative: return "You Owe"
        }
    }
}

// MARK: - Balance Trend Point Model

struct BalanceTrendPoint: Identifiable {
    let id = UUID()
    let date: Date
    let balance: Double
    let weekLabel: String
}

// MARK: - Balance Breakdown Row

struct BalanceBreakdownRow: View {
    let title: String
    let subtitle: String
    let amount: Double
    let icon: String
    let iconColor: Color

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(iconColor.opacity(0.2))
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundColor(iconColor)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.spotifyBodyMedium)
                    .foregroundColor(.wisePrimaryText)

                Text(subtitle)
                    .font(.spotifyCaptionMedium)
                    .foregroundColor(.wiseSecondaryText)
            }

            Spacer()

            Text(String(format: "$%.2f", amount))
                .font(.spotifyNumberMedium)
                .foregroundColor(amount >= 0 ? .wiseBrightGreen : .wiseError)
        }
        .padding(12)
        .background(Color.wiseBorder.opacity(0.2))
        .cornerRadius(12)
    }
}

// MARK: - Person Balance Row With Actions (Task 4.6 & 4.10)

struct PersonBalanceRowWithActions: View {
    let person: Person
    let balance: Double
    let onTap: () -> Void
    let onSettle: () -> Void

    @State private var showingSettleConfirmation = false

    var body: some View {
        Button {
            onTap()
        } label: {
            HStack(spacing: 12) {
                AvatarView(person: person, size: .large, style: .solid)

                VStack(alignment: .leading, spacing: 4) {
                    Text(person.name)
                        .font(.spotifyBodyMedium)
                        .foregroundColor(.wisePrimaryText)

                    Text(balance > 0 ? "owes you" : "you owe")
                        .font(.spotifyCaptionMedium)
                        .foregroundColor(.wiseSecondaryText)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(String(format: "$%.2f", abs(balance)))
                        .font(.spotifyNumberMedium)
                        .foregroundColor(balance > 0 ? .wiseBrightGreen : .wiseError)

                    // Task 4.6: Quick settle button
                    Button {
                        showingSettleConfirmation = true
                    } label: {
                        Text("Settle")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.wiseForestGreen)
                            .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(12)
            .background(Color.wiseBorder.opacity(0.2))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
        .confirmationDialog(
            "Settle Balance",
            isPresented: $showingSettleConfirmation,
            titleVisibility: .visible
        ) {
            Button("Settle \(String(format: "$%.2f", abs(balance))) with \(person.name)", role: .destructive) {
                onSettle()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will mark the balance as settled and set it to $0.00")
        }
    }
}

// MARK: - Balance Export View (Task 4.9)

struct BalanceExportView: View {
    @Environment(\.dismiss) var dismiss

    let totalBalance: Double
    let peopleBalances: [(person: Person, balance: Double)]
    let netMonthlyIncome: Double

    @State private var isExporting = false
    @State private var exportCompleted = false

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Image(systemName: "doc.text.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.wiseForestGreen)
                    .padding(.top, 40)

                VStack(spacing: 12) {
                    Text("Balance Report")
                        .font(.spotifyHeadingLarge)
                        .foregroundColor(.wisePrimaryText)

                    Text("Export a detailed summary of all balances")
                        .font(.spotifyBodyMedium)
                        .foregroundColor(.wiseSecondaryText)
                        .multilineTextAlignment(.center)
                }

                VStack(alignment: .leading, spacing: 16) {
                    ReportInfoRow(
                        icon: "dollarsign.circle.fill",
                        title: "Total Balance",
                        value: String(format: "$%.2f", totalBalance)
                    )

                    ReportInfoRow(
                        icon: "person.2.fill",
                        title: "People",
                        value: "\(peopleBalances.count) balances"
                    )

                    ReportInfoRow(
                        icon: "chart.bar.fill",
                        title: "Net Monthly Income",
                        value: String(format: "$%.2f", netMonthlyIncome)
                    )

                    ReportInfoRow(
                        icon: "calendar",
                        title: "Report Date",
                        value: Date().formatted(date: .abbreviated, time: .omitted)
                    )
                }
                .padding(16)
                .background(Color.wiseCardBackground)
                .cornerRadius(16)
                .cardShadow()
                .padding(.horizontal)

                Spacer()

                if exportCompleted {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.wiseBrightGreen)
                        Text("Report exported successfully!")
                            .font(.spotifyBodyMedium)
                            .foregroundColor(.wiseBrightGreen)
                    }
                    .padding()
                    .background(Color.wiseBrightGreen.opacity(0.1))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }

                Button {
                    exportReport()
                } label: {
                    HStack {
                        if isExporting {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "square.and.arrow.up")
                            Text("Export Report")
                        }
                    }
                    .font(.spotifyBodyLarge)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.wiseForestGreen)
                    .cornerRadius(12)
                }
                .disabled(isExporting)
                .padding(.horizontal)
                .padding(.bottom, 32)
            }
            .background(Color.wiseBackground)
            .navigationTitle("Export Report")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func exportReport() {
        isExporting = true

        // Simulate export process
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            // Generate report text
            var reportText = "BALANCE REPORT\n"
            reportText += "Generated: \(Date().formatted(date: .long, time: .shortened))\n\n"
            reportText += "═══════════════════════════════════════\n\n"
            reportText += "SUMMARY\n"
            reportText += "Total Balance: $\(String(format: "%.2f", totalBalance))\n"
            reportText += "Net Monthly Income: $\(String(format: "%.2f", netMonthlyIncome))\n\n"
            reportText += "PEOPLE BALANCES (\(peopleBalances.count) total)\n"
            reportText += "───────────────────────────────────────\n\n"

            for (index, item) in peopleBalances.enumerated() {
                let status = item.balance > 0 ? "owes you" : "you owe"
                reportText += "\(index + 1). \(item.person.name)\n"
                reportText += "   \(status) $\(String(format: "%.2f", abs(item.balance)))\n"
                reportText += "   Email: \(item.person.email)\n\n"
            }

            reportText += "═══════════════════════════════════════\n"
            reportText += "End of Report\n"

            // Create activity view controller
            let activityVC = UIActivityViewController(
                activityItems: [reportText],
                applicationActivities: nil
            )

            // Present on the topmost view controller
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootVC = windowScene.windows.first?.rootViewController {
                var topController = rootVC
                while let presentedVC = topController.presentedViewController {
                    topController = presentedVC
                }
                activityVC.popoverPresentationController?.sourceView = topController.view
                topController.present(activityVC, animated: true)
            }

            isExporting = false
            exportCompleted = true

            // Reset completed state after 3 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                exportCompleted = false
            }
        }
    }
}

// MARK: - Report Info Row

struct ReportInfoRow: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.wiseForestGreen)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.spotifyCaptionMedium)
                    .foregroundColor(.wiseSecondaryText)

                Text(value)
                    .font(.spotifyBodyMedium)
                    .foregroundColor(.wisePrimaryText)
            }

            Spacer()
        }
    }
}

// MARK: - Preview

#Preview("Balance Detail - Default") {
    BalanceDetailView()
        .environmentObject(DataManager.shared)
}

#Preview("Balance Detail - Dark Mode") {
    BalanceDetailView()
        .environmentObject(DataManager.shared)
        .preferredColorScheme(.dark)
}
