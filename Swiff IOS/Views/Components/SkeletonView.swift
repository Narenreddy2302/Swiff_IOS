//
//  SkeletonView.swift
//  Swiff IOS
//
//  Created by Naren Reddy on 11/20/25.
//  Skeleton loading placeholders for better loading UX
//

import SwiftUI

// MARK: - Skeleton Shape Modifier

struct ShimmerEffect: ViewModifier {
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .mask(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.black.opacity(0.3),
                        Color.black.opacity(0.6),
                        Color.black.opacity(0.3)
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .offset(x: phase)
                .animation(
                    Animation.linear(duration: 1.5)
                        .repeatForever(autoreverses: false),
                    value: phase
                )
            )
            .onAppear {
                phase = 300
            }
    }
}

// MARK: - Base Skeleton Components

struct SkeletonRectangle: View {
    let width: CGFloat?
    let height: CGFloat
    let cornerRadius: CGFloat

    init(width: CGFloat? = nil, height: CGFloat, cornerRadius: CGFloat = 8) {
        self.width = width
        self.height = height
        self.cornerRadius = cornerRadius
    }

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(Color.wiseBorder.opacity(0.3))
            .frame(width: width, height: height)
            .modifier(ShimmerEffect())
    }
}

struct SkeletonCircle: View {
    let size: CGFloat

    var body: some View {
        Circle()
            .fill(Color.wiseBorder.opacity(0.3))
            .frame(width: size, height: size)
            .modifier(ShimmerEffect())
    }
}

struct SkeletonText: View {
    let width: CGFloat?
    let height: CGFloat

    init(width: CGFloat? = nil, height: CGFloat = 16) {
        self.width = width
        self.height = height
    }

    var body: some View {
        SkeletonRectangle(width: width, height: height, cornerRadius: height / 2)
    }
}

// MARK: - Skeleton Card Components

struct SkeletonPersonRow: View {
    var body: some View {
        HStack(spacing: 16) {
            SkeletonCircle(size: 48)

            VStack(alignment: .leading, spacing: 8) {
                SkeletonText(width: 120, height: 16)
                SkeletonText(width: 80, height: 14)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 8) {
                SkeletonText(width: 60, height: 16)
                SkeletonText(width: 40, height: 14)
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
    }
}

struct SkeletonGroupRow: View {
    var body: some View {
        HStack(spacing: 16) {
            SkeletonCircle(size: 48)

            VStack(alignment: .leading, spacing: 8) {
                SkeletonText(width: 140, height: 16)
                SkeletonText(width: 100, height: 14)

                HStack(spacing: 4) {
                    SkeletonCircle(size: 24)
                    SkeletonCircle(size: 24)
                    SkeletonCircle(size: 24)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 8) {
                SkeletonText(width: 50, height: 14)
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
    }
}

struct SkeletonTransactionRow: View {
    var body: some View {
        HStack(spacing: 16) {
            SkeletonCircle(size: 40)

            VStack(alignment: .leading, spacing: 8) {
                SkeletonText(width: 150, height: 16)
                SkeletonText(width: 100, height: 14)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 8) {
                SkeletonText(width: 70, height: 18)
                SkeletonText(width: 50, height: 12)
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
    }
}

struct SkeletonSubscriptionRow: View {
    var body: some View {
        HStack(spacing: 16) {
            SkeletonRectangle(width: 48, height: 48, cornerRadius: 12)

            VStack(alignment: .leading, spacing: 8) {
                SkeletonText(width: 120, height: 16)
                SkeletonText(width: 80, height: 14)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 8) {
                SkeletonText(width: 60, height: 18)
                SkeletonText(width: 70, height: 12)
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
    }
}

// MARK: - Skeleton List Views

struct SkeletonListView: View {
    let rowCount: Int
    let rowType: SkeletonRowType

    enum SkeletonRowType {
        case person
        case group
        case transaction
        case subscription

        @ViewBuilder
        var row: some View {
            switch self {
            case .person:
                SkeletonPersonRow()
            case .group:
                SkeletonGroupRow()
            case .transaction:
                SkeletonTransactionRow()
            case .subscription:
                SkeletonSubscriptionRow()
            }
        }
    }

    init(rowCount: Int = 5, rowType: SkeletonRowType) {
        self.rowCount = rowCount
        self.rowType = rowType
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(0..<rowCount, id: \.self) { _ in
                    rowType.row
                }

                Spacer(minLength: 100)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
    }
}

// MARK: - Skeleton Dashboard Cards

struct SkeletonBalanceCard: View {
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                SkeletonText(width: 100, height: 16)
                Spacer()
            }

            HStack(alignment: .bottom, spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    SkeletonText(width: 80, height: 14)
                    SkeletonText(width: 120, height: 32)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 8) {
                    SkeletonText(width: 80, height: 14)
                    SkeletonText(width: 120, height: 32)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
        )
    }
}

struct SkeletonActivityCard: View {
    var body: some View {
        HStack(spacing: 12) {
            SkeletonCircle(size: 48)

            VStack(alignment: .leading, spacing: 6) {
                SkeletonText(width: 100, height: 14)
                SkeletonText(width: 70, height: 12)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 6) {
                SkeletonText(width: 60, height: 14)
                SkeletonText(width: 40, height: 10)
            }
        }
        .padding(12)
        .background(Color.white)
        .cornerRadius(12)
    }
}

struct SkeletonDashboard: View {
    var body: some View {
        VStack(spacing: 20) {
            // Balance Card
            SkeletonBalanceCard()

            // Section Header
            HStack {
                SkeletonText(width: 120, height: 20)
                Spacer()
                SkeletonText(width: 60, height: 16)
            }
            .padding(.horizontal, 2)

            // Activity Cards
            VStack(spacing: 12) {
                SkeletonActivityCard()
                SkeletonActivityCard()
                SkeletonActivityCard()
            }
        }
        .padding(.horizontal, 16)
    }
}

// MARK: - View Extension

extension View {
    func skeleton(isLoading: Bool, @ViewBuilder skeleton: () -> some View) -> some View {
        ZStack {
            if isLoading {
                skeleton()
            } else {
                self
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        Text("Skeleton Components Preview")
            .font(.headline)
            .padding()

        ScrollView {
            VStack(spacing: 24) {
                Text("Person Row")
                    .font(.caption)
                SkeletonPersonRow()
                    .padding(.horizontal)

                Text("Group Row")
                    .font(.caption)
                SkeletonGroupRow()
                    .padding(.horizontal)

                Text("Transaction Row")
                    .font(.caption)
                SkeletonTransactionRow()
                    .padding(.horizontal)

                Text("Subscription Row")
                    .font(.caption)
                SkeletonSubscriptionRow()
                    .padding(.horizontal)

                Text("Balance Card")
                    .font(.caption)
                SkeletonBalanceCard()
                    .padding(.horizontal)
            }
        }
    }
    .background(Color.wiseBackground)
}
