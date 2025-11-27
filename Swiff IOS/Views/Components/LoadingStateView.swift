//
//  LoadingStateView.swift
//  Swiff IOS
//
//  Created by Agent 11 on 11/21/25.
//  Loading states with progress indicators
//

import SwiftUI

// MARK: - Loading State View

struct LoadingStateView: View {
    let message: String?
    let showSpinner: Bool

    init(message: String? = "Loading...", showSpinner: Bool = true) {
        self.message = message
        self.showSpinner = showSpinner
    }

    var body: some View {
        VStack(spacing: 16) {
            if showSpinner {
                if AccessibilitySettings.isReduceMotionEnabled {
                    // Static loading indicator for reduce motion
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .wiseForestGreen))
                        .scaleEffect(1.5)
                } else {
                    // Animated spinner
                    SpinnerView()
                }
            }

            if let message = message {
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.wiseSecondaryText)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(message ?? "Loading")
    }
}

// MARK: - Progress Bar View

struct ProgressBarView: View {
    let progress: Double // 0.0 to 1.0
    let label: String?
    let showPercentage: Bool

    @Environment(\.colorScheme) var colorScheme

    init(
        progress: Double,
        label: String? = nil,
        showPercentage: Bool = true
    ) {
        self.progress = min(max(progress, 0.0), 1.0) // Clamp between 0 and 1
        self.label = label
        self.showPercentage = showPercentage
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Label and Percentage
            HStack {
                if let label = label {
                    Text(label)
                        .font(.subheadline)
                        .foregroundColor(.wisePrimaryText)
                }

                Spacer()

                if showPercentage {
                    Text("\(Int(progress * 100))%")
                        .font(.subheadline)
                        .foregroundColor(.wiseSecondaryText)
                        .monospacedDigit()
                }
            }

            // Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.wiseBorder.opacity(0.3))
                        .frame(height: 8)

                    // Progress Fill
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: [Color.wiseForestGreen, Color.wiseBrightGreen],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * progress, height: 8)
                        .animation(
                            AccessibilitySettings.isReduceMotionEnabled ? .none : .smooth,
                            value: progress
                        )
                }
            }
            .frame(height: 8)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label ?? "Progress"): \(Int(progress * 100)) percent")
    }
}

// MARK: - Bulk Operation Progress View

struct BulkOperationProgressView: View {
    let currentItem: Int
    let totalItems: Int
    let operationName: String
    let itemName: String

    var progress: Double {
        guard totalItems > 0 else { return 0 }
        return Double(currentItem) / Double(totalItems)
    }

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Icon with pulse animation
            ZStack {
                Circle()
                    .fill(Color.wiseForestGreen.opacity(0.15))
                    .frame(width: 100, height: 100)

                Image(systemName: "arrow.triangle.2.circlepath")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 50, height: 50)
                    .foregroundColor(.wiseForestGreen)
                    .if(!AccessibilitySettings.isReduceMotionEnabled) { view in
                        view.rotationEffect(.degrees(progress * 360))
                    }
            }

            // Operation Info
            VStack(spacing: 12) {
                Text(operationName)
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                Text("\(currentItem) of \(totalItems) \(itemName)")
                    .font(.subheadline)
                    .foregroundColor(.wiseSecondaryText)
            }

            // Progress Bar
            ProgressBarView(
                progress: progress,
                showPercentage: true
            )
            .padding(.horizontal, 32)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.wiseBackground)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(operationName). \(currentItem) of \(totalItems) \(itemName). \(Int(progress * 100)) percent complete")
    }
}

// MARK: - Skeleton List with Loading

struct SkeletonLoadingList: View {
    let rowCount: Int
    let rowType: SkeletonListView.SkeletonRowType

    init(rowCount: Int = 5, rowType: SkeletonListView.SkeletonRowType) {
        self.rowCount = rowCount
        self.rowType = rowType
    }

    var body: some View {
        SkeletonListView(rowCount: rowCount, rowType: rowType)
            .accessibilityLabel("Loading content")
    }
}

// MARK: - Loading Overlay Modifier

struct LoadingOverlay: ViewModifier {
    let isLoading: Bool
    let message: String?

    func body(content: Content) -> some View {
        ZStack {
            content
                .disabled(isLoading)
                .blur(radius: isLoading ? 2 : 0)

            if isLoading {
                Color.wiseOverlayColor
                    .ignoresSafeArea()

                VStack(spacing: 20) {
                    if AccessibilitySettings.isReduceMotionEnabled {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.5)
                    } else {
                        LoadingDotsView()
                    }

                    if let message = message {
                        Text(message)
                            .font(.subheadline)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                }
                .padding(24)
                .background(Color.wiseOverlayColor.opacity(0.95))
                .cornerRadius(16)
                .accessibilityElement(children: .combine)
                .accessibilityLabel(message ?? "Loading")
            }
        }
        .animation(
            AccessibilitySettings.isReduceMotionEnabled ? .none : .standardEase,
            value: isLoading
        )
    }
}

extension View {
    func loadingOverlay(isLoading: Bool, message: String? = nil) -> some View {
        self.modifier(LoadingOverlay(isLoading: isLoading, message: message))
    }
}

// MARK: - Pull to Refresh Indicator

struct PullToRefreshIndicator: View {
    let isRefreshing: Bool

    var body: some View {
        HStack {
            Spacer()

            if isRefreshing {
                if AccessibilitySettings.isReduceMotionEnabled {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .wiseForestGreen))
                } else {
                    HStack(spacing: 8) {
                        SpinnerView()
                        Text("Refreshing...")
                            .font(.subheadline)
                            .foregroundColor(.wiseSecondaryText)
                    }
                }
            }

            Spacer()
        }
        .frame(height: 40)
        .accessibilityLabel(isRefreshing ? "Refreshing content" : "")
    }
}

// MARK: - Determinate Loading View

struct DeterminateLoadingView: View {
    let progress: Double
    let title: String
    let subtitle: String?

    init(progress: Double, title: String, subtitle: String? = nil) {
        self.progress = progress
        self.title = title
        self.subtitle = subtitle
    }

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Circular Progress
            ZStack {
                Circle()
                    .stroke(Color.wiseBorder.opacity(0.3), lineWidth: 10)
                    .frame(width: 120, height: 120)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        LinearGradient(
                            colors: [Color.wiseForestGreen, Color.wiseBrightGreen],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 10, lineCap: .round)
                    )
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                    .animation(
                        AccessibilitySettings.isReduceMotionEnabled ? .none : .smooth,
                        value: progress
                    )

                Text("\(Int(progress * 100))%")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.wiseForestGreen)
            }

            // Text Content
            VStack(spacing: 8) {
                Text(title)
                    .font(.headline)
                    .multilineTextAlignment(.center)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(.wiseSecondaryText)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal, 32)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.wiseBackground)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title). \(subtitle ?? ""). \(Int(progress * 100)) percent complete")
    }
}

#Preview("Loading State") {
    LoadingStateView(message: "Loading your data...")
}

#Preview("Progress Bar") {
    VStack(spacing: 20) {
        ProgressBarView(progress: 0.3, label: "Downloading...")
        ProgressBarView(progress: 0.7, label: "Installing...")
        ProgressBarView(progress: 1.0, label: "Complete!")
    }
    .padding()
}

#Preview("Bulk Operation") {
    BulkOperationProgressView(
        currentItem: 7,
        totalItems: 10,
        operationName: "Importing Subscriptions",
        itemName: "items"
    )
}

#Preview("Determinate Loading") {
    DeterminateLoadingView(
        progress: 0.65,
        title: "Creating Backup",
        subtitle: "This may take a moment..."
    )
}
