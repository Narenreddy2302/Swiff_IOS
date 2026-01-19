//
//  ValidationBanner.swift
//  Swiff IOS
//
//  Validation message banner with color coding
//

import SwiftUI

struct ValidationBanner: View {
    enum BannerType {
        case success
        case warning
        case error
        case info

        var color: Color {
            switch self {
            case .success:
                return .wiseSuccess
            case .warning:
                return .wiseWarning
            case .error:
                return .wiseError
            case .info:
                return .wiseBrightGreen
            }
        }

        var icon: String {
            switch self {
            case .success:
                return "checkmark.circle.fill"
            case .warning:
                return "exclamationmark.triangle.fill"
            case .error:
                return "xmark.circle.fill"
            case .info:
                return "info.circle.fill"
            }
        }
    }

    let type: BannerType
    let message: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: type.icon)
                .font(.system(size: 14))
                .foregroundColor(type.color)

            Text(message)
                .font(.spotifyCaptionMedium)
                .foregroundColor(type.color)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
        .padding(12)
        .background(type.color.opacity(0.15))
        .cornerRadius(8)
    }
}

// MARK: - Preview

#Preview("Validation Banners") {
    VStack(spacing: 12) {
        ValidationBanner(
            type: .success,
            message: "Percentages add up to 100%"
        )

        ValidationBanner(
            type: .warning,
            message: "Amounts must add up to $100 (currently $95.50)"
        )

        ValidationBanner(
            type: .error,
            message: "Percentages must add up to 100% (currently 85%)"
        )

        ValidationBanner(
            type: .info,
            message: "Split equally among 3 people"
        )
    }
    .padding(20)
    .background(Color.wiseBackground)
}
