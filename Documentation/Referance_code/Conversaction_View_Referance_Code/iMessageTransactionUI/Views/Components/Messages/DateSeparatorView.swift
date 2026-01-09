//
//  DateSeparatorView.swift
//  iMessageTransactionUI
//
//  Description:
//  Displays a date separator between groups of messages.
//  Shows "Today", "Yesterday", or the formatted date.
//
//  Styling:
//  - Centered text
//  - Gray text color (#8E8E93)
//  - 12pt font size with medium weight
//  - Vertical padding for spacing
//
//  Date Formatting:
//  - Today: Shows "Today"
//  - Yesterday: Shows "Yesterday"
//  - Within a week: Shows day name (e.g., "Monday")
//  - Older: Shows full date (e.g., "January 5, 2024")
//
//  Properties:
//  - date: Date - The date to display
//

import SwiftUI

// MARK: - DateSeparatorView
/// Displays a centered date separator between message groups
struct DateSeparatorView: View {
    
    // MARK: - Properties
    
    /// The date to display
    let date: Date
    
    // MARK: - Body
    
    var body: some View {
        Text(date.formattedDateSeparator)
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(.textSecondary)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, 16)
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 0) {
        // Today
        DateSeparatorView(date: Date())
        
        // Yesterday
        DateSeparatorView(date: Calendar.current.date(byAdding: .day, value: -1, to: Date())!)
        
        // A week ago
        DateSeparatorView(date: Calendar.current.date(byAdding: .day, value: -5, to: Date())!)
        
        // A month ago
        DateSeparatorView(date: Calendar.current.date(byAdding: .month, value: -1, to: Date())!)
    }
}
