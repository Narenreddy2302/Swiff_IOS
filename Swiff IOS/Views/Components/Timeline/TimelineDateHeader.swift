//
//  TimelineDateHeader.swift
//  Swiff IOS
//
//  Created by Claude Code on 12/20/25.
//  Centered date pill for timeline sections
//

import SwiftUI

struct TimelineDateHeader: View {
    let date: Date

    private var dateText: String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM d, yyyy"
            return formatter.string(from: date)
        }
    }

    var body: some View {
        HStack {
            Spacer()
            Text(dateText)
                .font(.spotifyLabelSmall)
                .fontWeight(.semibold)
                .foregroundColor(.wiseSecondaryText)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.wiseBorder.opacity(0.3))
                .cornerRadius(12)
            Spacer()
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        TimelineDateHeader(date: Date())

        TimelineDateHeader(date: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date())

        TimelineDateHeader(date: Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date())

        TimelineDateHeader(date: Calendar.current.date(byAdding: .month, value: -2, to: Date()) ?? Date())
    }
    .padding()
    .background(Color.wiseBackground)
}
