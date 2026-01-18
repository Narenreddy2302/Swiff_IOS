//
//  TransactionInputStyle.swift
//  Swiff IOS
//
//  Created by Swiff AI on 01/18/26.
//  View modifier for consistent transaction input styling.
//

import SwiftUI

struct TransactionInputStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(.horizontal, Theme.Metrics.paddingSmall)
            .padding(.vertical, Theme.Metrics.spacingTiny)
            .background(Theme.Colors.cardBackground)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Metrics.cornerRadiusSmall)
                    .stroke(
                        Theme.Colors.border.opacity(Theme.Opacity.subtle),
                        lineWidth: Theme.Border.widthDefault)
            )
    }
}

extension View {
    func transactionInputFieldStyle() -> some View {
        modifier(TransactionInputStyle())
    }
}
