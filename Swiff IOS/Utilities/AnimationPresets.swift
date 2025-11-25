//
//  AnimationPresets.swift
//  Swiff IOS
//
//  Created by Naren Reddy on 11/20/25.
//  Centralized animation presets and utilities
//

import SwiftUI

// MARK: - Animation Presets

extension Animation {
    // MARK: - Spring Animations

    /// Smooth spring animation for general UI interactions
    static let smooth = Animation.spring(response: 0.3, dampingFraction: 0.7)

    /// Bouncy spring animation for playful interactions
    static let bouncy = Animation.spring(response: 0.4, dampingFraction: 0.6)

    /// Snappy spring animation for quick feedback
    static let snappy = Animation.spring(response: 0.25, dampingFraction: 0.8)

    /// Gentle spring animation for subtle changes
    static let gentle = Animation.spring(response: 0.5, dampingFraction: 0.8)

    // MARK: - Ease Animations

    /// Quick ease for button taps
    static let quickEase = Animation.easeOut(duration: 0.15)

    /// Standard ease for most transitions
    static let standardEase = Animation.easeInOut(duration: 0.25)

    /// Slow ease for deliberate transitions
    static let slowEase = Animation.easeInOut(duration: 0.35)

    // MARK: - Custom Animations

    /// Animation for card appearance
    static let cardAppear = Animation.spring(response: 0.35, dampingFraction: 0.75)

    /// Animation for sheet presentation
    static let sheetPresent = Animation.spring(response: 0.4, dampingFraction: 0.8)

    /// Animation for list item insertion
    static let listInsert = Animation.spring(response: 0.3, dampingFraction: 0.7)

    /// Animation for deletion
    static let deletion = Animation.easeOut(duration: 0.2)
}

// MARK: - Transition Presets

extension AnyTransition {
    /// Slide and fade transition
    static let slideAndFade = AnyTransition.asymmetric(
        insertion: .move(edge: .trailing).combined(with: .opacity),
        removal: .move(edge: .leading).combined(with: .opacity)
    )

    /// Scale and fade transition
    static let scaleAndFade = AnyTransition.scale.combined(with: .opacity)

    /// Slide from bottom with fade
    static let slideUp = AnyTransition.move(edge: .bottom).combined(with: .opacity)

    /// Slide from top with fade
    static let slideDown = AnyTransition.move(edge: .top).combined(with: .opacity)

    /// Push transition (like navigation)
    static let push = AnyTransition.asymmetric(
        insertion: .move(edge: .trailing),
        removal: .move(edge: .leading)
    )
}

// MARK: - Animated View Modifiers

struct AnimatedScaleButtonStyle: ButtonStyle {
    let scaleAmount: CGFloat

    init(scaleAmount: CGFloat = 0.95) {
        self.scaleAmount = scaleAmount
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scaleAmount : 1.0)
            .animation(.quickEase, value: configuration.isPressed)
    }
}

struct ShakeEffect: GeometryEffect {
    var amount: CGFloat = 10
    var shakesPerUnit = 3
    var animatableData: CGFloat

    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(
            CGAffineTransform(translationX: amount * sin(animatableData * .pi * CGFloat(shakesPerUnit)), y: 0)
        )
    }
}

// MARK: - View Extensions

extension View {
    /// Adds a smooth scale animation on tap
    func scaleOnTap(scale: CGFloat = 0.95) -> some View {
        self.buttonStyle(AnimatedScaleButtonStyle(scaleAmount: scale))
    }

    /// Shake animation for errors
    func shake(trigger: Int) -> some View {
        self.modifier(ShakeEffect(animatableData: CGFloat(trigger)))
    }

    /// Fade in animation
    func fadeIn(duration: Double = 0.3, delay: Double = 0) -> some View {
        self
            .opacity(0)
            .animation(.easeIn(duration: duration).delay(delay), value: UUID())
            .onAppear {
                withAnimation(.easeIn(duration: duration).delay(delay)) {
                    // Trigger animation
                }
            }
    }

    /// Slide in from edge
    func slideIn(from edge: Edge, duration: Double = 0.3, delay: Double = 0) -> some View {
        self
            .transition(.move(edge: edge).combined(with: .opacity))
            .animation(.easeInOut(duration: duration).delay(delay), value: UUID())
    }

    /// Animated conditional appearance
    func animatedAppearance(isVisible: Bool, transition: AnyTransition = .scaleAndFade) -> some View {
        SwiftUI.Group {
            if isVisible {
                self.transition(transition)
            }
        }
    }

    /// Card flip animation
    func cardFlip(isFlipped: Binding<Bool>) -> some View {
        self
            .rotation3DEffect(
                .degrees(isFlipped.wrappedValue ? 180 : 0),
                axis: (x: 0, y: 1, z: 0)
            )
            .animation(.smooth, value: isFlipped.wrappedValue)
    }

    /// Pulse animation
    func pulse(scale: CGFloat = 1.05, duration: Double = 1.0) -> some View {
        self.modifier(PulseModifier(scale: scale, duration: duration))
    }

    /// Shimmer loading effect
    func shimmer() -> some View {
        self.modifier(ShimmerEffect())
    }
}

// MARK: - Pulse Modifier

struct PulseModifier: ViewModifier {
    let scale: CGFloat
    let duration: Double

    @State private var isAnimating = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isAnimating ? scale : 1.0)
            .animation(
                Animation.easeInOut(duration: duration)
                    .repeatForever(autoreverses: true),
                value: isAnimating
            )
            .onAppear {
                isAnimating = true
            }
    }
}

// MARK: - Loading Animations

struct LoadingDotsView: View {
    @State private var animationAmount: CGFloat = 0

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(Color.wiseForestGreen)
                    .frame(width: 8, height: 8)
                    .scaleEffect(animationAmount == CGFloat(index) ? 1.3 : 1.0)
                    .animation(
                        Animation.easeInOut(duration: 0.6)
                            .repeatForever()
                            .delay(Double(index) * 0.2),
                        value: animationAmount
                    )
            }
        }
        .onAppear {
            animationAmount = 1
        }
    }
}

struct SpinnerView: View {
    @State private var isRotating = false

    var body: some View {
        Circle()
            .trim(from: 0, to: 0.7)
            .stroke(
                AngularGradient(
                    gradient: Gradient(colors: [Color.wiseForestGreen, Color.wiseForestGreen.opacity(0.1)]),
                    center: .center
                ),
                style: StrokeStyle(lineWidth: 3, lineCap: .round)
            )
            .frame(width: 24, height: 24)
            .rotationEffect(Angle(degrees: isRotating ? 360 : 0))
            .animation(
                Animation.linear(duration: 1)
                    .repeatForever(autoreverses: false),
                value: isRotating
            )
            .onAppear {
                isRotating = true
            }
    }
}

// MARK: - Page Transition

struct PageTransition: ViewModifier {
    let isPresented: Bool

    func body(content: Content) -> some View {
        content
            .transition(.slideAndFade)
            .animation(.smooth, value: isPresented)
    }
}

extension View {
    func pageTransition(isPresented: Bool) -> some View {
        self.modifier(PageTransition(isPresented: isPresented))
    }
}

// MARK: - Bounce Effect

struct BounceEffect: GeometryEffect {
    var animatableData: CGFloat

    func effectValue(size: CGSize) -> ProjectionTransform {
        let translation = -abs(sin(animatableData * .pi * 2)) * 10
        return ProjectionTransform(CGAffineTransform(translationX: 0, y: translation))
    }
}

extension View {
    func bounceEffect(trigger: Int) -> some View {
        self.modifier(BounceEffect(animatableData: CGFloat(trigger)))
    }
}

#Preview {
    VStack(spacing: 40) {
        Text("Animation Presets")
            .font(.headline)

        LoadingDotsView()

        SpinnerView()

        Button("Tap Me") {}
            .padding()
            .background(Color.wiseForestGreen)
            .foregroundColor(.white)
            .cornerRadius(12)
            .scaleOnTap()

        Circle()
            .fill(Color.wiseBrightGreen)
            .frame(width: 50, height: 50)
            .pulse()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.wiseBackground)
}
