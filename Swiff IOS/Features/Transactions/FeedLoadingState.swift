//
//  FeedLoadingState.swift
//  Swiff IOS
//
//  Skeleton loading state with shimmer animation for Feed page
//

import SwiftUI

// MARK: - Feed Loading State

struct FeedLoadingState: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Show 3 shimmer sections
                ForEach(0..<3, id: \.self) { sectionIndex in
                    ShimmerSection(rowCount: sectionIndex == 0 ? 3 : 2)
                }
            }
            .padding(.top, 8)
            .padding(.bottom, 100)
        }
        .disabled(true)
    }
}

// MARK: - Shimmer Section

struct ShimmerSection: View {
    let rowCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Section header shimmer (matches FeedSectionHeader style)
            HStack(spacing: 8) {
                ShimmerView()
                    .frame(width: 60, height: 11)
                    .cornerRadius(2)

                Rectangle()
                    .fill(Theme.Colors.feedDivider)
                    .frame(height: 1)
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 2)

            // Transaction rows shimmer (plain, no card background)
            VStack(spacing: 0) {
                ForEach(0..<rowCount, id: \.self) { index in
                    ShimmerRow()

                    if index < rowCount - 1 {
                        Rectangle()
                            .fill(Theme.Colors.feedDivider)
                            .frame(height: 1)
                            .padding(.leading, 66)
                    }
                }
            }
        }
    }
}

// MARK: - Shimmer Row

struct ShimmerRow: View {
    var body: some View {
        HStack(spacing: 10) {
            // Avatar shimmer (40x40 to match compact row)
            ShimmerView()
                .frame(width: 40, height: 40)
                .clipShape(Circle())

            // Text content shimmer
            VStack(alignment: .leading, spacing: 4) {
                ShimmerView()
                    .frame(width: 100, height: 12)
                    .cornerRadius(3)

                ShimmerView()
                    .frame(width: 60, height: 10)
                    .cornerRadius(3)
            }

            Spacer()

            // Amount shimmer
            VStack(alignment: .trailing, spacing: 4) {
                ShimmerView()
                    .frame(width: 60, height: 12)
                    .cornerRadius(3)

                ShimmerView()
                    .frame(width: 45, height: 10)
                    .cornerRadius(3)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
    }
}

// MARK: - Shimmer View

struct ShimmerView: View {
    @State private var isAnimating = false

    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.wiseSkeletonBase.opacity(0.15),
                        Color.wiseSkeletonBase.opacity(0.25),
                        Color.wiseSkeletonBase.opacity(0.15),
                    ]),
                    startPoint: isAnimating ? .trailing : .leading,
                    endPoint: isAnimating ? .leading : .trailing
                )
            )
            .onAppear {
                withAnimation(
                    Animation.linear(duration: 1.5)
                        .repeatForever(autoreverses: false)
                ) {
                    isAnimating = true
                }
            }
    }
}

// MARK: - Preview

#Preview("Feed Loading State") {
    VStack(spacing: 0) {
        // Mock header
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Feed")
                    .font(.spotifyDisplayMedium)
                    .foregroundColor(.wisePrimaryText)
                Text("$0.00 spent this month")
                    .font(.spotifyBodySmall)
                    .foregroundColor(.wiseSecondaryText)
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 8)

        FeedLoadingState()
    }
    .background(Color.wiseBackground)
}

#Preview("Shimmer Section") {
    ShimmerSection(rowCount: 3)
        .padding(.vertical, 20)
        .background(Color.wiseBackground)
}

#Preview("Shimmer Row") {
    ShimmerRow()
        .padding()
        .background(Color.wiseCardBackground)
        .cornerRadius(12)
        .padding()
        .background(Color.wiseBackground)
}
