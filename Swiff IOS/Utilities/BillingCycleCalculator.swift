//
//  BillingCycleCalculator.swift
//  Swiff IOS
//
//  Created by Claude Code on 11/20/25.
//  Phase 3.2: Accurate billing cycle calculations with Decimal precision
//

import Foundation

// MARK: - Calculator Billing Cycle

enum CalculatorBillingCycle: String, Codable, CaseIterable {
    case daily = "Daily"
    case weekly = "Weekly"
    case biweekly = "Biweekly"
    case monthly = "Monthly"
    case quarterly = "Quarterly"
    case semiannually = "Semiannually"
    case annually = "Annually"

    /// Weeks per year (precise calculation)
    static let weeksPerYear: Decimal = 52.1429 // 365.25 / 7

    /// Get the number of occurrences per year
    var occurrencesPerYear: Decimal {
        switch self {
        case .daily:
            return 365.25 // Account for leap years
        case .weekly:
            return CalculatorBillingCycle.weeksPerYear // 52.1429
        case .biweekly:
            return CalculatorBillingCycle.weeksPerYear / 2 // 26.0714
        case .monthly:
            return 12
        case .quarterly:
            return 4
        case .semiannually:
            return 2
        case .annually:
            return 1
        }
    }

    /// Get average days per cycle
    var averageDaysPerCycle: Decimal {
        return 365.25 / occurrencesPerYear
    }
}

// MARK: - Billing Cycle Calculator

enum BillingCycleCalculator {

    // MARK: - Annual Cost Calculation

    /// Calculate precise annual cost from cycle cost
    /// - Parameters:
    ///   - cycleAmount: Amount per billing cycle
    ///   - cycle: The billing cycle
    /// - Returns: Annualized amount
    static func annualCost(cycleAmount: Currency, cycle: CalculatorBillingCycle) -> Currency {
        return cycleAmount * cycle.occurrencesPerYear
    }

    /// Calculate precise annual cost from Double (backward compatible)
    static func annualCost(cycleAmount: Double, cycle: CalculatorBillingCycle) -> Double {
        let currency = Currency(double: cycleAmount)
        let annual = annualCost(cycleAmount: currency, cycle: cycle)
        return annual.doubleValue
    }

    // MARK: - Monthly Cost Calculation

    /// Calculate precise monthly cost from cycle cost
    /// - Parameters:
    ///   - cycleAmount: Amount per billing cycle
    ///   - cycle: The billing cycle
    /// - Returns: Monthly amount
    static func monthlyCost(cycleAmount: Currency, cycle: CalculatorBillingCycle) -> Currency {
        let annual = annualCost(cycleAmount: cycleAmount, cycle: cycle)
        return try! annual / 12 // Safe: dividing by non-zero constant
    }

    /// Calculate precise monthly cost from Double (backward compatible)
    static func monthlyCost(cycleAmount: Double, cycle: CalculatorBillingCycle) -> Double {
        let currency = Currency(double: cycleAmount)
        let monthly = monthlyCost(cycleAmount: currency, cycle: cycle)
        return monthly.doubleValue
    }

    // MARK: - Cycle Cost Calculation

    /// Calculate cost for a specific cycle from annual amount
    /// - Parameters:
    ///   - annualAmount: Annual amount
    ///   - cycle: Target billing cycle
    /// - Returns: Amount per cycle
    static func cycleCost(annualAmount: Currency, cycle: CalculatorBillingCycle) -> Currency {
        return try! annualAmount / cycle.occurrencesPerYear
    }

    // MARK: - Next Billing Date

    /// Calculate next billing date from start date
    /// - Parameters:
    ///   - startDate: Subscription start date
    ///   - cycle: Billing cycle
    ///   - occurrences: Number of occurrences (default: 1)
    /// - Returns: Next billing date
    static func nextBillingDate(
        from startDate: Date,
        cycle: CalculatorBillingCycle,
        occurrences: Int = 1
    ) -> Date? {
        let calendar = Calendar.current

        switch cycle {
        case .daily:
            return calendar.date(byAdding: .day, value: occurrences, to: startDate)

        case .weekly:
            return calendar.date(byAdding: .weekOfYear, value: occurrences, to: startDate)

        case .biweekly:
            return calendar.date(byAdding: .weekOfYear, value: occurrences * 2, to: startDate)

        case .monthly:
            return calendar.date(byAdding: .month, value: occurrences, to: startDate)

        case .quarterly:
            return calendar.date(byAdding: .month, value: occurrences * 3, to: startDate)

        case .semiannually:
            return calendar.date(byAdding: .month, value: occurrences * 6, to: startDate)

        case .annually:
            return calendar.date(byAdding: .year, value: occurrences, to: startDate)
        }
    }

    // MARK: - Billing Periods in Date Range

    /// Calculate number of billing periods between two dates
    /// - Parameters:
    ///   - startDate: Start date
    ///   - endDate: End date
    ///   - cycle: Billing cycle
    /// - Returns: Number of complete billing periods
    static func billingPeriods(
        from startDate: Date,
        to endDate: Date,
        cycle: CalculatorBillingCycle
    ) -> Int {
        let calendar = Calendar.current
        let components: Calendar.Component

        switch cycle {
        case .daily:
            components = .day
        case .weekly, .biweekly:
            components = .weekOfYear
        case .monthly, .quarterly, .semiannually:
            components = .month
        case .annually:
            components = .year
        }

        let difference = calendar.dateComponents([components], from: startDate, to: endDate)

        switch cycle {
        case .daily:
            return difference.day ?? 0
        case .weekly:
            return (difference.weekOfYear ?? 0)
        case .biweekly:
            return (difference.weekOfYear ?? 0) / 2
        case .monthly:
            return difference.month ?? 0
        case .quarterly:
            return (difference.month ?? 0) / 3
        case .semiannually:
            return (difference.month ?? 0) / 6
        case .annually:
            return difference.year ?? 0
        }
    }

    // MARK: - Cost in Date Range

    /// Calculate total cost for a date range
    /// - Parameters:
    ///   - cycleAmount: Amount per billing cycle
    ///   - cycle: Billing cycle
    ///   - startDate: Start date
    ///   - endDate: End date
    /// - Returns: Total cost for the period
    static func totalCost(
        cycleAmount: Currency,
        cycle: CalculatorBillingCycle,
        from startDate: Date,
        to endDate: Date
    ) -> Currency {
        let periods = billingPeriods(from: startDate, to: endDate, cycle: cycle)
        return cycleAmount * periods
    }

    // MARK: - Proration

    /// Calculate prorated amount for partial billing period
    /// - Parameters:
    ///   - cycleAmount: Full cycle amount
    ///   - cycle: Billing cycle
    ///   - daysUsed: Number of days in the partial period
    /// - Returns: Prorated amount
    static func prorated(
        cycleAmount: Currency,
        cycle: CalculatorBillingCycle,
        daysUsed: Int
    ) -> Currency {
        let daysInCycle = cycle.averageDaysPerCycle
        let ratio = Decimal(daysUsed) / daysInCycle
        return cycleAmount * ratio
    }
}

// MARK: - Billing Summary

struct BillingSummary: CustomStringConvertible {
    let cycleAmount: Currency
    let cycle: CalculatorBillingCycle
    let monthlyEquivalent: Currency
    let annualTotal: Currency

    init(cycleAmount: Currency, cycle: CalculatorBillingCycle) {
        self.cycleAmount = cycleAmount
        self.cycle = cycle
        self.monthlyEquivalent = BillingCycleCalculator.monthlyCost(
            cycleAmount: cycleAmount,
            cycle: cycle
        )
        self.annualTotal = BillingCycleCalculator.annualCost(
            cycleAmount: cycleAmount,
            cycle: cycle
        )
    }

    var description: String {
        """
        Billing Summary:
        - Cycle: \(cycle.rawValue)
        - Per Cycle: \(cycleAmount.formatted())
        - Monthly Equivalent: \(monthlyEquivalent.formatted())
        - Annual Total: \(annualTotal.formatted())
        """
    }
}

// MARK: - Extensions

extension CalculatorBillingCycle {
    /// Human-readable description
    var displayName: String {
        return rawValue
    }

    /// Short description for UI
    var shortName: String {
        switch self {
        case .daily: return "Day"
        case .weekly: return "Week"
        case .biweekly: return "2 Weeks"
        case .monthly: return "Month"
        case .quarterly: return "Quarter"
        case .semiannually: return "6 Months"
        case .annually: return "Year"
        }
    }
}

// MARK: - Usage Examples (Documentation)

/*
 USAGE EXAMPLES:

 1. Calculate annual cost from weekly subscription:
 ```swift
 let weeklyPrice = Currency(double: 9.99)
 let annual = BillingCycleCalculator.annualCost(
     cycleAmount: weeklyPrice,
     cycle: .weekly
 )
 // Result: $520.66 (9.99 × 52.1429 weeks)
 ```

 2. Calculate monthly equivalent:
 ```swift
 let weeklyPrice = Currency(double: 10.00)
 let monthly = BillingCycleCalculator.monthlyCost(
     cycleAmount: weeklyPrice,
     cycle: .weekly
 )
 // Result: $43.45 (10.00 × 52.1429 / 12)
 ```

 3. Calculate next billing date:
 ```swift
 let startDate = Date()
 let nextBilling = BillingCycleCalculator.nextBillingDate(
     from: startDate,
     cycle: .monthly,
     occurrences: 1
 )
 ```

 4. Create billing summary:
 ```swift
 let summary = BillingSummary(
     cycleAmount: Currency(double: 15.00),
     cycle: .monthly
 )
 print(summary.description)
 ```
 */
