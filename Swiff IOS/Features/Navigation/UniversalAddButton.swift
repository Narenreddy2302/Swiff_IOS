import SwiftUI

// MARK: - Universal Add Button (Center Tab Bar Button)
struct UniversalAddButton: View {
    @Binding var selectedTab: Int
    @State private var showingQuickActions = false
    @State private var isPressed = false
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        Button(action: {
            HapticManager.shared.impact(.medium)
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                showingQuickActions = true
            }
        }) {
            ZStack {
                // Background circle - adapts to color scheme
                Circle()
                    .fill(
                        colorScheme == .dark
                            ? Color.wiseForestGreen  // GREEN 5 for dark mode
                            : Color.wiseForestGreen  // GREEN 5 for light mode
                    )
                    .frame(width: 56, height: 56)
                    .shadow(
                        color: Color.black.opacity(colorScheme == .dark ? 0.5 : 0.15),
                        radius: 8,
                        x: 0,
                        y: 4
                    )

                // Inner highlight circle for depth
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(colorScheme == .dark ? 0.15 : 0.2),
                                Color.white.opacity(0),
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 56, height: 56)

                // Plus icon
                Image(systemName: "plus")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.white)
            }
        }
        .scaleEffect(isPressed ? 0.92 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isPressed)
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    isPressed = true
                }
                .onEnded { _ in
                    isPressed = false
                }
        )
        .sheet(isPresented: $showingQuickActions) {
            QuickActionSheet()
        }
    }
}
