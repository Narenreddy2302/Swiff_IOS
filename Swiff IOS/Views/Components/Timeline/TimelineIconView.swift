//
//  TimelineIconView.swift
//  Swiff IOS
//
//  Created for SWIFF iOS Timeline/Conversation UI Redesign
//  Displays the timeline icon with color coding
//

import SwiftUI

struct TimelineIconView: View {
    let type: TimelineIconType

    var body: some View {
        ZStack {
            Circle()
                .fill(type.backgroundColor)
                .frame(width: 24, height: 24)

            Image(systemName: type.icon)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(type.iconColor)
        }
    }
}

#Preview {
    HStack(spacing: 16) {
        TimelineIconView(type: .message)
        TimelineIconView(type: .payment)
        TimelineIconView(type: .request)
        TimelineIconView(type: .expense)
        TimelineIconView(type: .system)
        TimelineIconView(type: .paidBillSystem)
    }
    .padding()
    .background(Color.wiseBackground)
}
