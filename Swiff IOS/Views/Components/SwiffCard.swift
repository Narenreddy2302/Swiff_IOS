import SwiftUI

/// A standardized card container for the Swiff Design System.
/// Provides consistent padding, background, corner radius, and shadow.
struct SwiffCard<Content: View>: View {
    let padding: CGFloat
    let content: Content

    init(
        padding: CGFloat = Theme.Metrics.paddingMedium,
        @ViewBuilder content: () -> Content
    ) {
        self.padding = padding
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: Theme.Metrics.cornerRadiusMedium)
                    .fill(Theme.Colors.cardBackground)
                    .cardShadow()
            )
    }
}

#Preview {
    ZStack {
        Theme.Colors.background.ignoresSafeArea()
        SwiffCard {
            Text("Swiff Card Content")
                .font(Theme.Fonts.bodyMedium)
                .foregroundColor(Theme.Colors.textPrimary)
        }
        .padding()
    }
}
