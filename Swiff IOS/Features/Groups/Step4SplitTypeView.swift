//
//  Step4SplitTypeView.swift
//  Swiff IOS
//
//  Step 4: Choose split calculation method
//

import SwiftUI

struct Step4SplitTypeView: View {
    @Binding var selectedSplitType: SplitType

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                Text("How would you like to split?")
                    .font(.spotifyHeadingMedium)
                    .foregroundColor(.wisePrimaryText)
                    .padding(.horizontal, 20)
                    .padding(.top, 20)

                Text("Choose a method to divide the bill")
                    .font(.spotifyBodyMedium)
                    .foregroundColor(.wiseSecondaryText)
                    .padding(.horizontal, 20)

                // Split type buttons
                VStack(spacing: 12) {
                    ForEach(SplitType.allCases, id: \.self) { splitType in
                        SplitTypeButton(
                            splitType: splitType,
                            isSelected: selectedSplitType == splitType,
                            action: {
                                selectedSplitType = splitType
                            }
                        )
                    }
                }
                .padding(.horizontal, 20)

                Spacer(minLength: 20)
            }
        }
        .background(Color.wiseBackground)
    }
}

// MARK: - Preview

#Preview("Step 4 Split Type") {
    Step4SplitTypeView(selectedSplitType: .constant(.equally))
}
