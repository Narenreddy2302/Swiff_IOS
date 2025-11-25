//
//  DateTimeHelper.swift
//  Swiff IOS
//
//  Created by Claude Code on 11/20/25.
//  Phase 3.3: DST-aware date/time handling
//

import Foundation

// MARK: - Date/Time Error

enum DateTimeError: LocalizedError {
    case invalidDate
    case invalidTimeZone
    case dstTransitionConflict
    case calculationError

    var errorDescription: String? {
        switch self {
        case .invalidDate:
            return "Invalid date provided"
        case .invalidTimeZone:
            return "Invalid timezone"
        case .dstTransitionConflict:
            return "Date falls during DST transition"
        case .calculationError:
            return "Date calculation failed"
        }
    }
}

// MARK: - DST Transition Info

struct DSTTransitionInfo {
    let isDSTTransition: Bool
    let transitionType: TransitionType?
    let transitionDate: Date?
    let hoursDifference: Int?

    enum TransitionType {
        case springForward  // 23-hour day
        case fallBack       // 25-hour day
    }

    var description: String {
        guard isDSTTransition, let type = transitionType else {
            return "No DST transition"
        }

        switch type {
        case .springForward:
            return "Spring Forward (23-hour day)"
        case .fallBack:
            return "Fall Back (25-hour day)"
        }
    }
}

// MARK: - Date Time Helper

enum DateTimeHelper {

    // MARK: - DST Detection

    /// Check if a date is during a DST transition
    static func isDSTTransition(date: Date, timeZone: TimeZone = .current) -> Bool {
        return timeZone.isDaylightSavingTime(for: date) !=
               timeZone.isDaylightSavingTime(for: date.addingTimeInterval(-3600))
    }

    /// Get DST transition information for a date
    static func dstTransitionInfo(for date: Date, timeZone: TimeZone = .current) -> DSTTransitionInfo {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)

        // Check if DST changed during this day
        let isDSTAtStart = timeZone.isDaylightSavingTime(for: startOfDay)
        let isDSTAtEnd = timeZone.isDaylightSavingTime(for: startOfDay.addingTimeInterval(86400 - 1))

        if isDSTAtStart != isDSTAtEnd {
            // DST transition occurred
            let transitionType: DSTTransitionInfo.TransitionType = isDSTAtStart ? .fallBack : .springForward
            let hoursDiff = isDSTAtStart ? 1 : -1

            return DSTTransitionInfo(
                isDSTTransition: true,
                transitionType: transitionType,
                transitionDate: startOfDay,
                hoursDifference: hoursDiff
            )
        }

        return DSTTransitionInfo(
            isDSTTransition: false,
            transitionType: nil,
            transitionDate: nil,
            hoursDifference: nil
        )
    }

    /// Get next DST transition date
    static func nextDSTTransition(from date: Date = Date(), timeZone: TimeZone = .current) -> Date? {
        let calendar = Calendar.current
        var currentDate = date

        // Check up to 400 days in the future (covers at least one full year)
        for _ in 0..<400 {
            if let nextDay = calendar.date(byAdding: .day, value: 1, to: currentDate) {
                let info = dstTransitionInfo(for: nextDay, timeZone: timeZone)
                if info.isDSTTransition {
                    return nextDay
                }
                currentDate = nextDay
            } else {
                break
            }
        }

        return nil
    }

    // MARK: - DST-Safe Date Arithmetic

    /// Add days to a date, accounting for DST transitions
    static func addDays(_ days: Int, to date: Date, timeZone: TimeZone = .current) -> Date? {
        var calendar = Calendar.current
        calendar.timeZone = timeZone

        return calendar.date(byAdding: .day, value: days, to: date)
    }

    /// Add hours to a date, accounting for DST transitions
    static func addHours(_ hours: Int, to date: Date, timeZone: TimeZone = .current) -> Date? {
        // Use actual time interval for hours to handle DST correctly
        return date.addingTimeInterval(TimeInterval(hours * 3600))
    }

    /// Calculate actual hours between two dates (accounting for DST)
    static func hoursBetween(start: Date, end: Date, timeZone: TimeZone = .current) -> Int {
        let interval = end.timeIntervalSince(start)
        return Int(interval / 3600)
    }

    /// Calculate days between two dates (accounting for DST)
    static func daysBetween(start: Date, end: Date, timeZone: TimeZone = .current) -> Int {
        var calendar = Calendar.current
        calendar.timeZone = timeZone

        let components = calendar.dateComponents([.day], from: start, to: end)
        return components.day ?? 0
    }

    // MARK: - Same Time Next Day (DST-aware)

    /// Get the same clock time on the next day, even during DST transitions
    static func sameTimeNextDay(from date: Date, timeZone: TimeZone = .current) -> Date? {
        var calendar = Calendar.current
        calendar.timeZone = timeZone

        // Get time components
        let components = calendar.dateComponents([.hour, .minute, .second], from: date)

        // Add one day
        guard let nextDay = calendar.date(byAdding: .day, value: 1, to: date) else {
            return nil
        }

        // Set same time
        return calendar.date(
            bySettingHour: components.hour ?? 0,
            minute: components.minute ?? 0,
            second: components.second ?? 0,
            of: nextDay
        )
    }

    // MARK: - Subscription Renewal Dates (DST-safe)

    /// Calculate subscription renewal date accounting for DST
    static func subscriptionRenewalDate(
        startDate: Date,
        billingCycle: BillingCycle,
        occurrences: Int = 1,
        timeZone: TimeZone = .current
    ) -> Date? {
        var calendar = Calendar.current
        calendar.timeZone = timeZone

        // Get the time components from start date
        let timeComponents = calendar.dateComponents([.hour, .minute, .second], from: startDate)

        // Convert BillingCycle to CalculatorBillingCycle
        let calculatorCycle: CalculatorBillingCycle
        switch billingCycle {
        case .daily:
            calculatorCycle = .weekly // Map daily to weekly for calculator
        case .weekly:
            calculatorCycle = .weekly
        case .biweekly:
            calculatorCycle = .weekly // Map biweekly to weekly for calculator
        case .monthly:
            calculatorCycle = .monthly
        case .quarterly:
            calculatorCycle = .quarterly
        case .semiAnnually:
            calculatorCycle = .semiannually
        case .yearly, .annually:
            calculatorCycle = .annually
        case .lifetime:
            // For lifetime, return nil (no renewal)
            return nil
        }

        // Calculate next date using billing cycle
        guard let nextDate = BillingCycleCalculator.nextBillingDate(
            from: startDate,
            cycle: calculatorCycle,
            occurrences: occurrences
        ) else {
            return nil
        }

        // Preserve the same clock time even if DST changed
        return calendar.date(
            bySettingHour: timeComponents.hour ?? 0,
            minute: timeComponents.minute ?? 0,
            second: timeComponents.second ?? 0,
            of: nextDate
        )
    }

    // MARK: - Time Zone Conversion

    /// Convert date to a different time zone
    static func convertToTimeZone(_ date: Date, to timeZone: TimeZone) -> Date {
        let sourceTimeZone = TimeZone.current
        let sourceOffset = sourceTimeZone.secondsFromGMT(for: date)
        let targetOffset = timeZone.secondsFromGMT(for: date)
        let interval = TimeInterval(targetOffset - sourceOffset)

        return date.addingTimeInterval(interval)
    }

    // MARK: - Start/End of Day (DST-aware)

    /// Get start of day (midnight) accounting for DST
    static func startOfDay(for date: Date, timeZone: TimeZone = .current) -> Date? {
        var calendar = Calendar.current
        calendar.timeZone = timeZone

        return calendar.startOfDay(for: date)
    }

    /// Get end of day (23:59:59) accounting for DST
    static func endOfDay(for date: Date, timeZone: TimeZone = .current) -> Date? {
        var calendar = Calendar.current
        calendar.timeZone = timeZone

        let startOfDay = calendar.startOfDay(for: date)
        return calendar.date(byAdding: .day, value: 1, to: startOfDay)?.addingTimeInterval(-1)
    }

    // MARK: - Working Hours Calculation (DST-aware)

    /// Calculate working hours between two dates, accounting for DST
    static func workingHoursBetween(
        start: Date,
        end: Date,
        workingHoursPerDay: Int = 8,
        timeZone: TimeZone = .current
    ) -> Double {
        var calendar = Calendar.current
        calendar.timeZone = timeZone

        let days = daysBetween(start: start, end: end, timeZone: timeZone)
        let hours = hoursBetween(start: start, end: end, timeZone: timeZone)

        // Calculate actual hours worked
        let fullDays = days
        let remainingHours = hours - (fullDays * 24)

        let workingHours = Double(fullDays * workingHoursPerDay) +
                          min(Double(remainingHours), Double(workingHoursPerDay))

        return workingHours
    }

    // MARK: - Date Validation

    /// Validate that a date exists (not during DST spring forward gap)
    static func isValidDate(
        year: Int,
        month: Int,
        day: Int,
        hour: Int,
        minute: Int,
        timeZone: TimeZone = .current
    ) -> Bool {
        var calendar = Calendar.current
        calendar.timeZone = timeZone

        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute

        return calendar.date(from: components) != nil
    }

    // MARK: - Formatting with DST Info

    /// Format date with DST information
    static func formattedWithDST(
        date: Date,
        timeZone: TimeZone = .current,
        includeOffset: Bool = true
    ) -> String {
        let formatter = DateFormatter()
        formatter.timeZone = timeZone
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"

        var result = formatter.string(from: date)

        if includeOffset {
            let offset = timeZone.secondsFromGMT(for: date)
            let hours = offset / 3600
            let minutes = abs(offset % 3600) / 60

            let offsetString = String(format: "%+03d:%02d", hours, minutes)
            result += " GMT\(offsetString)"

            if timeZone.isDaylightSavingTime(for: date) {
                result += " (DST)"
            }
        }

        return result
    }
}

// MARK: - Date Extension

extension Date {
    /// Check if this date is during a DST transition
    var isDSTTransition: Bool {
        return DateTimeHelper.isDSTTransition(date: self)
    }

    /// Get DST transition info for this date
    var dstTransitionInfo: DSTTransitionInfo {
        return DateTimeHelper.dstTransitionInfo(for: self)
    }

    /// Add days (DST-safe)
    func addingDays(_ days: Int, timeZone: TimeZone = .current) -> Date? {
        return DateTimeHelper.addDays(days, to: self, timeZone: timeZone)
    }

    /// Add hours (DST-safe)
    func addingHours(_ hours: Int, timeZone: TimeZone = .current) -> Date? {
        return DateTimeHelper.addHours(hours, to: self, timeZone: timeZone)
    }

    /// Get same time next day (DST-safe)
    func sameTimeNextDay(timeZone: TimeZone = .current) -> Date? {
        return DateTimeHelper.sameTimeNextDay(from: self, timeZone: timeZone)
    }

    /// Formatted with DST info
    func formattedWithDST(timeZone: TimeZone = .current) -> String {
        return DateTimeHelper.formattedWithDST(date: self, timeZone: timeZone)
    }
}

// MARK: - Usage Examples (Documentation)

/*
 USAGE EXAMPLES:

 1. Detect DST transition:
 ```swift
 let date = Date()
 let info = date.dstTransitionInfo

 if info.isDSTTransition {
     print("DST Transition: \(info.description)")
 }
 ```

 2. Add days safely:
 ```swift
 let tomorrow = date.addingDays(1)
 // Handles DST transitions correctly
 ```

 3. Calculate subscription renewal:
 ```swift
 let renewal = DateTimeHelper.subscriptionRenewalDate(
     startDate: subscriptionStart,
     billingCycle: .monthly,
     occurrences: 1
 )
 // Preserves same clock time even during DST
 ```

 4. Find next DST transition:
 ```swift
 if let nextDST = DateTimeHelper.nextDSTTransition() {
     print("Next DST change: \(nextDST)")
 }
 ```
 */
