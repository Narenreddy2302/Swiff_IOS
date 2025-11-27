//
//  ViewExtensions.swift
//  Swiff IOS
//
//  Created by Agent 11 on 11/21/25.
//  Useful view extensions and helpers
//

import SwiftUI

// MARK: - Conditional View Modifier

extension View {
    /// Conditionally apply a view modifier
    @ViewBuilder
    func `if`<Transform: View>(
        _ condition: Bool,
        transform: (Self) -> Transform
    ) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }

    /// Conditionally apply one of two view modifiers
    @ViewBuilder
    func `if`<TrueContent: View, FalseContent: View>(
        _ condition: Bool,
        if ifTransform: (Self) -> TrueContent,
        else elseTransform: (Self) -> FalseContent
    ) -> some View {
        if condition {
            ifTransform(self)
        } else {
            elseTransform(self)
        }
    }

    /// Conditionally apply a view modifier if optional value exists
    @ViewBuilder
    func ifLet<Value, Transform: View>(
        _ value: Value?,
        transform: (Self, Value) -> Transform
    ) -> some View {
        if let value = value {
            transform(self, value)
        } else {
            self
        }
    }
}

// MARK: - Corner Radius Extensions

extension View {
    /// Apply corner radius to specific corners
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// MARK: - Accessibility Header Helper

extension View {
    /// Mark this view as an accessibility header
    func accessibleHeader(label: String? = nil) -> some View {
        self
            .accessibilityAddTraits(.isHeader)
            .if(label != nil) { view in
                view.accessibilityLabel(label!)
            }
    }
}

// MARK: - Hidden Modifier

extension View {
    /// Hide view based on condition
    @ViewBuilder
    func hidden(_ hide: Bool) -> some View {
        if hide {
            self.hidden()
        } else {
            self
        }
    }
}

// MARK: - Frame Extensions

extension View {
    /// Apply a square frame
    func frame(size: CGFloat) -> some View {
        self.frame(width: size, height: size)
    }

    /// Apply frame with equal padding
    func framePadded(width: CGFloat? = nil, height: CGFloat? = nil, padding: CGFloat) -> some View {
        self.frame(
            width: width.map { $0 - (padding * 2) },
            height: height.map { $0 - (padding * 2) }
        )
    }
}

// MARK: - Shadow Extensions

extension View {
    /// Apply a consistent card shadow
    func cardShadow(
        color: Color = .black.opacity(0.1),
        radius: CGFloat = 8,
        x: CGFloat = 0,
        y: CGFloat = 4
    ) -> some View {
        self.shadow(color: color, radius: radius, x: x, y: y)
    }

    /// Apply a consistent elevated shadow
    func elevatedShadow(
        color: Color = .black.opacity(0.15),
        radius: CGFloat = 12,
        x: CGFloat = 0,
        y: CGFloat = 6
    ) -> some View {
        self.shadow(color: color, radius: radius, x: x, y: y)
    }
}

// MARK: - Keyboard Extensions

extension View {
    /// Dismiss keyboard on tap
    func dismissKeyboardOnTap() -> some View {
        self.onTapGesture {
            UIApplication.shared.sendAction(
                #selector(UIResponder.resignFirstResponder),
                to: nil,
                from: nil,
                for: nil
            )
        }
    }
}

// MARK: - Loading Overlay

extension View {
    /// Show loading overlay
    func loadingOverlay(isLoading: Bool, message: String = "Loading...") -> some View {
        self.overlay {
            if isLoading {
                ZStack {
                    Color.wiseOverlayColor
                        .ignoresSafeArea()

                    VStack(spacing: 16) {
                        SpinnerView()
                        Text(message)
                            .font(.spotifyLabelMedium)
                            .foregroundColor(.white)
                    }
                    .padding(24)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.wiseOverlayColor.opacity(0.95))
                    )
                }
                .transition(.opacity)
            }
        }
    }
}

// MARK: - Read Size Modifier

struct SizePreferenceKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}

extension View {
    func readSize(onChange: @escaping (CGSize) -> Void) -> some View {
        background(
            GeometryReader { geometry in
                Color.clear
                    .preference(key: SizePreferenceKey.self, value: geometry.size)
            }
        )
        .onPreferenceChange(SizePreferenceKey.self, perform: onChange)
    }
}

// MARK: - Placeholder Modifier

extension View {
    /// Show placeholder text when condition is true
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content
    ) -> some View {
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}
