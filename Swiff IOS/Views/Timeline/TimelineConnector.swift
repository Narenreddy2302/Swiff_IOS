//
//  TimelineConnector.swift
//  Swiff IOS
//
//  Created for SWIFF iOS Timeline/Conversation UI Redesign
//  Solid vertical line connecting timeline items
//

import SwiftUI

struct TimelineConnector: View {
    var color: Color = .wiseBorder

    var body: some View {
        Rectangle()
            .fill(color)
            .frame(width: 2)
    }
}

#Preview {
    TimelineConnector()
        .frame(height: 40)
        .padding()
        .background(Color.wiseBackground)
}
