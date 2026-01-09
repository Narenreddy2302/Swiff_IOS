//
//  Extensions.swift
//  iMessageTransactionUI
//
//  Description:
//  Helper extensions used throughout the application.
//  Contains utility functions for dates, strings, and SwiftUI modifiers.
//
//  Extensions:
//  - Date: Formatting helpers for timestamps and date separators
//  - String: Validation and formatting helpers
//  - View: Custom modifiers for common styling patterns
//

import SwiftUI
import Foundation

// MARK: - Date Extensions
extension Date {
    
    /// Formats the date for message timestamps
    /// - Returns: String in format "h:mm a" (e.g., "6:30 PM")
    ///
    /// Usage:
    /// ```
    /// let timeString = message.timestamp.formattedTime
    /// // Returns: "6:30 PM"
    /// ```
    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: self)
    }
    
    /// Formats the date for date separators in the chat
    /// - Returns: "Today", "Yesterday", or formatted date string
    ///
    /// Logic:
    /// - If today: Returns "Today"
    /// - If yesterday: Returns "Yesterday"
    /// - If within this week: Returns day name (e.g., "Monday")
    /// - Otherwise: Returns full date (e.g., "January 5, 2024")
    ///
    /// Usage:
    /// ```
    /// let separatorText = date.formattedDateSeparator
    /// // Returns: "Today", "Yesterday", "Monday", or "January 5, 2024"
    /// ```
    var formattedDateSeparator: String {
        let calendar = Calendar.current
        
        if calendar.isDateInToday(self) {
            return "Today"
        } else if calendar.isDateInYesterday(self) {
            return "Yesterday"
        } else if let daysAgo = calendar.dateComponents([.day], from: self, to: Date()).day,
                  daysAgo < 7 {
            // Within the last week, show day name
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE"
            return formatter.string(from: self)
        } else {
            // Older than a week, show full date
            let formatter = DateFormatter()
            formatter.dateStyle = .long
            return formatter.string(from: self)
        }
    }
    
    /// Checks if two dates are on the same day
    /// - Parameter date: Date to compare with
    /// - Returns: true if both dates are on the same calendar day
    func isSameDay(as date: Date) -> Bool {
        let calendar = Calendar.current
        return calendar.isDate(self, inSameDayAs: date)
    }
}

// MARK: - String Extensions
extension String {
    
    /// Trims whitespace and newlines from the string
    /// - Returns: Trimmed string
    var trimmed: String {
        return self.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// Checks if the string is empty after trimming whitespace
    /// - Returns: true if string is empty or contains only whitespace
    var isBlank: Bool {
        return self.trimmed.isEmpty
    }
    
    /// Converts a numeric string to a formatted currency string
    /// - Returns: Formatted string like "$X.XX" or nil if not a valid number
    ///
    /// Usage:
    /// ```
    /// "99.99".toCurrency // Returns: "$99.99"
    /// "invalid".toCurrency // Returns: nil
    /// ```
    var toCurrency: String? {
        guard let amount = Double(self) else { return nil }
        return "$\(String(format: "%.2f", amount))"
    }
}

// MARK: - Double Extensions
extension Double {
    
    /// Formats the number as a currency string
    /// - Returns: String in format "$X.XX"
    ///
    /// Usage:
    /// ```
    /// let amount = 99.99
    /// amount.formatted // Returns: "$99.99"
    /// ```
    var formatted: String {
        return "$\(String(format: "%.2f", self))"
    }
}

// MARK: - View Extensions
extension View {
    
    /// Applies the standard message bubble style
    /// - Parameters:
    ///   - isSent: Whether the message is sent (true) or received (false)
    /// - Returns: Modified view with bubble styling
    ///
    /// Styling:
    /// - Sent: Blue background, white text, rounded corners with bottom-right smaller
    /// - Received: Gray background, black text, rounded corners with bottom-left smaller
    func messageBubbleStyle(isSent: Bool) -> some View {
        self
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(isSent ? Color.iMessageBlue : Color.iMessageGray)
            .foregroundColor(isSent ? .white : .textPrimary)
            .clipShape(MessageBubbleShape(isSent: isSent))
    }
    
    /// Applies standard input field styling
    /// - Returns: Modified view with input field styling
    func inputFieldStyle() -> some View {
        self
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color.white)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.inputBorder, lineWidth: 1)
            )
    }
    
    /// Hides the view based on a condition
    /// - Parameter hidden: Whether to hide the view
    /// - Returns: Modified view that may be hidden
    @ViewBuilder
    func isHidden(_ hidden: Bool) -> some View {
        if hidden {
            self.hidden()
        } else {
            self
        }
    }
    
    /// Applies a card-like shadow effect
    /// - Returns: Modified view with shadow
    func cardShadow() -> some View {
        self.shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Message Bubble Shape
/// Custom shape for message bubbles with one smaller corner
struct MessageBubbleShape: Shape {
    
    /// Whether the bubble is for a sent message
    let isSent: Bool
    
    func path(in rect: CGRect) -> Path {
        let radius: CGFloat = 18
        let smallRadius: CGFloat = 4
        
        var path = Path()
        
        if isSent {
            // Sent bubble: small radius on bottom-right
            path.move(to: CGPoint(x: rect.minX + radius, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX - radius, y: rect.minY))
            path.addArc(center: CGPoint(x: rect.maxX - radius, y: rect.minY + radius),
                       radius: radius, startAngle: .degrees(-90), endAngle: .degrees(0), clockwise: false)
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - smallRadius))
            path.addArc(center: CGPoint(x: rect.maxX - smallRadius, y: rect.maxY - smallRadius),
                       radius: smallRadius, startAngle: .degrees(0), endAngle: .degrees(90), clockwise: false)
            path.addLine(to: CGPoint(x: rect.minX + radius, y: rect.maxY))
            path.addArc(center: CGPoint(x: rect.minX + radius, y: rect.maxY - radius),
                       radius: radius, startAngle: .degrees(90), endAngle: .degrees(180), clockwise: false)
            path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + radius))
            path.addArc(center: CGPoint(x: rect.minX + radius, y: rect.minY + radius),
                       radius: radius, startAngle: .degrees(180), endAngle: .degrees(270), clockwise: false)
        } else {
            // Received bubble: small radius on bottom-left
            path.move(to: CGPoint(x: rect.minX + radius, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX - radius, y: rect.minY))
            path.addArc(center: CGPoint(x: rect.maxX - radius, y: rect.minY + radius),
                       radius: radius, startAngle: .degrees(-90), endAngle: .degrees(0), clockwise: false)
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - radius))
            path.addArc(center: CGPoint(x: rect.maxX - radius, y: rect.maxY - radius),
                       radius: radius, startAngle: .degrees(0), endAngle: .degrees(90), clockwise: false)
            path.addLine(to: CGPoint(x: rect.minX + smallRadius, y: rect.maxY))
            path.addArc(center: CGPoint(x: rect.minX + smallRadius, y: rect.maxY - smallRadius),
                       radius: smallRadius, startAngle: .degrees(90), endAngle: .degrees(180), clockwise: false)
            path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + radius))
            path.addArc(center: CGPoint(x: rect.minX + radius, y: rect.minY + radius),
                       radius: radius, startAngle: .degrees(180), endAngle: .degrees(270), clockwise: false)
        }
        
        path.closeSubpath()
        return path
    }
}
