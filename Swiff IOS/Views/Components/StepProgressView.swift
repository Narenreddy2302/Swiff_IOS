//
//  StepProgressView.swift
//  Swiff IOS
//
//  Progress indicator for multi-step wizard flows
//

import SwiftUI

struct StepProgressView: View {
    let currentStep: Int
    let totalSteps: Int
    let stepTitles: [String]

    var body: some View {
        VStack(spacing: 12) {
            // Progress dots
            HStack(spacing: 8) {
                ForEach(0..<totalSteps, id: \.self) { step in
                    Circle()
                        .fill(stepColor(for: step))
                        .frame(width: 8, height: 8)
                        .scaleEffect(step == currentStep ? 1.2 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentStep)
                }
            }

            // Current step title
            if currentStep < stepTitles.count {
                Text(stepTitles[currentStep])
                    .font(.spotifyLabelMedium)
                    .foregroundColor(.wiseSecondaryText)
            }

            // Step counter
            Text("Step \(currentStep + 1) of \(totalSteps)")
                .font(.spotifyCaptionMedium)
                .foregroundColor(.wiseSecondaryText)
        }
        .padding(.vertical, 12)
    }

    private func stepColor(for step: Int) -> Color {
        if step < currentStep {
            return .wiseBrightGreen // Completed
        } else if step == currentStep {
            return .wiseBrightGreen // Current
        } else {
            return .wiseBorder.opacity(0.3) // Upcoming
        }
    }
}

// MARK: - Preview

#Preview("Step Progress") {
    VStack(spacing: 30) {
        StepProgressView(
            currentStep: 0,
            totalSteps: 6,
            stepTitles: ["Details", "Payer", "Participants", "Split Type", "Configure", "Review"]
        )

        StepProgressView(
            currentStep: 2,
            totalSteps: 6,
            stepTitles: ["Details", "Payer", "Participants", "Split Type", "Configure", "Review"]
        )

        StepProgressView(
            currentStep: 5,
            totalSteps: 6,
            stepTitles: ["Details", "Payer", "Participants", "Split Type", "Configure", "Review"]
        )
    }
    .padding()
    .background(Color.wiseBackground)
}
