//
//  WidgetModels.swift
//  SwiffWidgets
//
//  Created by Agent 10 on 11/21/25.
//  Additional data models for widget communication
//  Note: Core widget data models (WidgetSubscription, WidgetMonthlySpending)
//  are defined in WidgetDataService.swift to avoid duplicate type declarations.
//

import Foundation

// MARK: - Widget Quick Action Model

struct WidgetQuickAction: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
    let color: String
    let deepLink: String
}

// MARK: - Widget Display Helpers

/// Helper extensions for formatting widget data
extension Double {
    /// Format as currency string
    var asCurrencyString: String {
        String(format: "$%.2f", self)
    }

    /// Format as percentage string with sign
    var asPercentageString: String {
        let sign = self >= 0 ? "+" : ""
        return String(format: "%@%.1f%%", sign, self)
    }
}

extension Date {
    /// Days until this date from now
    var daysFromNow: Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: Date(), to: self)
        return components.day ?? 0
    }

    /// Human-readable countdown text
    var countdownText: String {
        let days = daysFromNow
        if days == 0 {
            return "Today"
        } else if days == 1 {
            return "Tomorrow"
        } else if days < 0 {
            return "Overdue"
        } else if days < 7 {
            return "In \(days) days"
        } else if days < 30 {
            let weeks = days / 7
            return "In \(weeks) week\(weeks == 1 ? "" : "s")"
        } else {
            return "In \(days) days"
        }
    }
}
