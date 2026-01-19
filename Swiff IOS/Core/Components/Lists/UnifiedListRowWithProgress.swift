//
//  UnifiedListRowWithProgress.swift
//  Swiff IOS
//
//  Created for Unified List Design System
//  Row component with progress bar for Analytics categories
//

import SwiftUI

// MARK: - Unified List Row With Progress

/// A unified list row with an integrated progress bar.
/// Used primarily for Analytics category breakdown views.
/// Features:
/// - Standard row layout (icon, title, subtitle, value)
/// - Progress bar at the bottom showing percentage
/// - Selection state with border highlight
struct UnifiedListRowWithProgress<IconContent: View>: View {
    // Required parameters
    let title: String
    let subtitle: String
    let value: String
    let valueColor: Color
    let percentage: Double

    // Optional parameters
    var valueLabel: String? = nil
    var isSelected: Bool = false

    // Icon content builder
    @ViewBuilder let iconContent: () -> IconContent

    var body: some View {
        VStack(spacing: 0) {
            // Main Row Content
            HStack(spacing: 16) {
                // Icon Area (48x48)
                iconContent()

                // Text Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.spotifyBodyLarge)
                        .foregroundColor(.wisePrimaryText)
                        .lineLimit(1)

                    Text(subtitle)
                        .font(.spotifyBodySmall)
                        .foregroundColor(.wiseSecondaryText)
                        .lineLimit(1)
                }

                Spacer()

                // Value Area
                VStack(alignment: .trailing, spacing: 2) {
                    Text(value)
                        .font(.spotifyNumberMedium)
                        .foregroundColor(valueColor)

                    if let label = valueLabel {
                        Text(label)
                            .font(.spotifyCaptionSmall)
                            .foregroundColor(.wiseSecondaryText)
                    }
                }
            }
            .padding(16)

            // Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background track
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.wiseBorder.opacity(0.3))
                        .frame(height: 4)

                    // Progress fill
                    RoundedRectangle(cornerRadius: 2)
                        .fill(
                            LinearGradient(
                                colors: [valueColor.opacity(0.8), valueColor],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(0, geometry.size.width * (min(percentage, 100) / 100)), height: 4)
                        .animation(.easeInOut(duration: 0.3), value: percentage)
                }
            }
            .frame(height: 4)
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.wiseCardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(
                    isSelected ? valueColor.opacity(0.5) : Color.clear,
                    lineWidth: 2
                )
        )
        .subtleShadow()
    }
}

// MARK: - Preview

#Preview("List Row With Progress") {
    ScrollView {
        VStack(spacing: 12) {
            Text("UnifiedListRowWithProgress Examples")
                .font(.headline)
                .padding()

            // Expense category - selected
            UnifiedListRowWithProgress(
                title: "Food & Dining",
                subtitle: "Expense",
                value: "$450.00",
                valueColor: .wiseError,
                percentage: 35.5,
                valueLabel: "35.5%",
                isSelected: true
            ) {
                UnifiedIconCircle(icon: "fork.knife", color: .orange)
            }
            .padding(.horizontal, 16)

            // Income category
            UnifiedListRowWithProgress(
                title: "Salary",
                subtitle: "Income",
                value: "$5,000.00",
                valueColor: .wiseBrightGreen,
                percentage: 80.0,
                valueLabel: "80.0%"
            ) {
                UnifiedIconCircle(icon: "dollarsign.circle.fill", color: .wiseBrightGreen)
            }
            .padding(.horizontal, 16)

            // Shopping category
            UnifiedListRowWithProgress(
                title: "Shopping",
                subtitle: "Expense",
                value: "$230.50",
                valueColor: .wiseError,
                percentage: 18.2,
                valueLabel: "18.2%"
            ) {
                UnifiedIconCircle(icon: "bag.fill", color: .pink)
            }
            .padding(.horizontal, 16)

            // Entertainment category
            UnifiedListRowWithProgress(
                title: "Entertainment",
                subtitle: "Expense",
                value: "$120.00",
                valueColor: .wiseError,
                percentage: 9.5,
                valueLabel: "9.5%"
            ) {
                UnifiedIconCircle(icon: "tv.fill", color: .purple)
            }
            .padding(.horizontal, 16)

            // Transportation category
            UnifiedListRowWithProgress(
                title: "Transportation",
                subtitle: "Expense",
                value: "$85.00",
                valueColor: .wiseError,
                percentage: 6.7,
                valueLabel: "6.7%"
            ) {
                UnifiedIconCircle(icon: "car.fill", color: .wiseBlue)
            }
            .padding(.horizontal, 16)

            // Full width example
            UnifiedListRowWithProgress(
                title: "Total Income",
                subtitle: "All Sources",
                value: "$10,000.00",
                valueColor: .wiseBrightGreen,
                percentage: 100.0,
                valueLabel: "100%"
            ) {
                UnifiedIconCircle(icon: "chart.pie.fill", color: .wiseBrightGreen)
            }
            .padding(.horizontal, 16)
        }
        .padding(.vertical)
    }
    .background(Color.wiseBackground)
}
