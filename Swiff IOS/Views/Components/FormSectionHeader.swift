//
//  FormSectionHeader.swift
//  Swiff IOS
//
//  Form section header component for consistent section titles
//

import SwiftUI

struct FormSectionHeader: View {
    let title: String
    let isRequired: Bool

    init(title: String, isRequired: Bool = false) {
        self.title = title
        self.isRequired = isRequired
    }

    var body: some View {
        HStack(spacing: 4) {
            Text(title.uppercased())
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.wiseSecondaryText)
                .tracking(0.5)

            if isRequired {
                Text("*")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.wiseError)
            }
        }
    }
}

// MARK: - Preview

#Preview("Form Section Headers") {
    VStack(alignment: .leading, spacing: 16) {
        FormSectionHeader(title: "Transaction Name", isRequired: true)
        FormSectionHeader(title: "Total Amount", isRequired: true)
        FormSectionHeader(title: "Category", isRequired: false)
        FormSectionHeader(title: "Notes (Optional)", isRequired: false)
    }
    .padding(20)
    .background(Color.wiseBackground)
}
