//
//  AnimationViewModifiers.swift
//  Swiff IOS
//
//  Created by Agent 11 on 11/21/25.
//  Enhanced animation view modifiers with accessibility support
//

import SwiftUI

// MARK: - Card Entry Animation

struct CardEntryAnimation: ViewModifier {
    let delay: Double

    @State private var isVisible = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isVisible ? 1.0 : 0.8)
            .opacity(isVisible ? 1.0 : 0.0)
            .animation(
                AccessibilitySettings.isReduceMotionEnabled
                    ? .none
                    : .bouncy.delay(delay),
                value: isVisible
            )
            .onAppear {
                isVisible = true
            }
    }
}

extension View {
    func cardEntry(delay: Double = 0.0) -> some View {
        self.modifier(CardEntryAnimation(delay: delay))
    }
}

// MARK: - List Item Animation

struct ListItemAnimation: ViewModifier {
    let index: Int

    @State private var isVisible = false

    func body(content: Content) -> some View {
        content
            .offset(x: isVisible ? 0 : 50, y: 0)
            .opacity(isVisible ? 1.0 : 0.0)
            .animation(
                AccessibilitySettings.isReduceMotionEnabled
                    ? .none
                    : .smooth.delay(Double(index) * 0.05),
                value: isVisible
            )
            .onAppear {
                isVisible = true
            }
    }
}

extension View {
    func listItemAnimation(index: Int) -> some View {
        self.modifier(ListItemAnimation(index: index))
    }
}

// MARK: - Deletion Animation

struct DeletionAnimation: ViewModifier {
    let isDeleting: Bool

    func body(content: Content) -> some View {
        content
            .opacity(isDeleting ? 0.0 : 1.0)
            .offset(x: isDeleting ? -100 : 0)
            .animation(
                AccessibilitySettings.isReduceMotionEnabled
                    ? .none
                    : .deletion,
                value: isDeleting
            )
    }
}

extension View {
    func deletionAnimation(isDeleting: Bool) -> some View {
        self.modifier(DeletionAnimation(isDeleting: isDeleting))
    }
}

// MARK: - Number Counter Animation

struct NumberCounterAnimation: ViewModifier {
    let value: Double
    let formatter: NumberFormatter

    @State private var displayValue: Double = 0

    init(value: Double, formatter: NumberFormatter = NumberFormatter()) {
        self.value = value
        self.formatter = formatter
    }

    func body(content: Content) -> some View {
        Text(formatter.string(from: NSNumber(value: displayValue)) ?? "")
            .contentTransition(.numericText(value: displayValue))
            .animation(
                AccessibilitySettings.isReduceMotionEnabled
                    ? .none
                    : .smooth.speed(0.5),
                value: displayValue
            )
            .onAppear {
                displayValue = value
            }
            .onChange(of: value) { _, newValue in
                withAnimation(
                    AccessibilitySettings.isReduceMotionEnabled
                        ? .none
                        : .smooth.speed(0.5)
                ) {
                    displayValue = newValue
                }
            }
    }
}

// MARK: - Sheet Presentation Animation

struct SheetPresentationAnimation: ViewModifier {
    let isPresented: Bool

    func body(content: Content) -> some View {
        content
            .transition(
                AccessibilitySettings.isReduceMotionEnabled
                    ? .opacity
                    : .slideUp
            )
            .animation(
                AccessibilitySettings.isReduceMotionEnabled
                    ? .none
                    : .sheetPresent,
                value: isPresented
            )
    }
}

extension View {
    func sheetPresentation(isPresented: Bool) -> some View {
        self.modifier(SheetPresentationAnimation(isPresented: isPresented))
    }
}

// MARK: - Card Flip Animation

struct CardFlipAnimation: ViewModifier {
    let isFlipped: Bool

    func body(content: Content) -> some View {
        content
            .rotation3DEffect(
                .degrees(isFlipped ? 180 : 0),
                axis: (x: 0, y: 1, z: 0),
                perspective: 0.5
            )
            .animation(
                AccessibilitySettings.isReduceMotionEnabled
                    ? .none
                    : .smooth,
                value: isFlipped
            )
    }
}

extension View {
    func cardFlipAnimation(isFlipped: Bool) -> some View {
        self.modifier(CardFlipAnimation(isFlipped: isFlipped))
    }
}

// MARK: - Pulse Animation

struct PulseAnimation: ViewModifier {
    let isPulsing: Bool
    let scale: CGFloat

    @State private var animationAmount: CGFloat = 1.0

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPulsing ? animationAmount : 1.0)
            .animation(
                AccessibilitySettings.isReduceMotionEnabled || !isPulsing
                    ? .none
                    : .easeInOut(duration: 1.0).repeatForever(autoreverses: true),
                value: animationAmount
            )
            .onAppear {
                if isPulsing && !AccessibilitySettings.isReduceMotionEnabled {
                    animationAmount = scale
                }
            }
    }
}

extension View {
    func pulseAnimation(isPulsing: Bool = true, scale: CGFloat = 1.05) -> some View {
        self.modifier(PulseAnimation(isPulsing: isPulsing, scale: scale))
    }
}

// MARK: - Wiggle Animation

struct WiggleAnimation: ViewModifier {
    let trigger: Int

    func body(content: Content) -> some View {
        content
            .rotationEffect(
                AccessibilitySettings.isReduceMotionEnabled
                    ? .degrees(0)
                    : .degrees(Double(trigger % 2 == 0 ? 0 : 5))
            )
            .animation(
                AccessibilitySettings.isReduceMotionEnabled
                    ? .none
                    : .spring(response: 0.2, dampingFraction: 0.3),
                value: trigger
            )
    }
}

extension View {
    func wiggleAnimation(trigger: Int) -> some View {
        self.modifier(WiggleAnimation(trigger: trigger))
    }
}

// MARK: - Bounce on Appear

struct BounceOnAppear: ViewModifier {
    @State private var hasAppeared = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(hasAppeared ? 1.0 : 0.5)
            .animation(
                AccessibilitySettings.isReduceMotionEnabled
                    ? .none
                    : .bouncy,
                value: hasAppeared
            )
            .onAppear {
                hasAppeared = true
            }
    }
}

extension View {
    func bounceOnAppear() -> some View {
        self.modifier(BounceOnAppear())
    }
}

// MARK: - Slide In From Edge

struct SlideInFromEdge: ViewModifier {
    let edge: Edge
    let delay: Double

    @State private var isVisible = false

    func body(content: Content) -> some View {
        content
            .offset(x: offsetX, y: offsetY)
            .opacity(isVisible ? 1.0 : 0.0)
            .animation(
                AccessibilitySettings.isReduceMotionEnabled
                    ? .none
                    : .smooth.delay(delay),
                value: isVisible
            )
            .onAppear {
                isVisible = true
            }
    }

    private var offsetX: CGFloat {
        if isVisible { return 0 }
        switch edge {
        case .leading: return -100
        case .trailing: return 100
        default: return 0
        }
    }

    private var offsetY: CGFloat {
        if isVisible { return 0 }
        switch edge {
        case .top: return -100
        case .bottom: return 100
        default: return 0
        }
    }
}

extension View {
    func slideInFromEdge(_ edge: Edge, delay: Double = 0.0) -> some View {
        self.modifier(SlideInFromEdge(edge: edge, delay: delay))
    }
}

// MARK: - Conditional Animation

struct ConditionalAnimation<V: Equatable>: ViewModifier {
    let value: V
    let animation: Animation?

    func body(content: Content) -> some View {
        content
            .animation(
                AccessibilitySettings.isReduceMotionEnabled
                    ? .none
                    : animation,
                value: value
            )
    }
}

extension View {
    func conditionalAnimation<V: Equatable>(
        _ animation: Animation?,
        value: V
    ) -> some View {
        self.modifier(ConditionalAnimation(value: value, animation: animation))
    }
}

// MARK: - Fade Transition

struct FadeTransition: ViewModifier {
    let isVisible: Bool
    let duration: Double

    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1.0 : 0.0)
            .animation(
                AccessibilitySettings.isReduceMotionEnabled
                    ? .none
                    : .easeInOut(duration: duration),
                value: isVisible
            )
    }
}

extension View {
    func fadeTransition(isVisible: Bool, duration: Double = 0.3) -> some View {
        self.modifier(FadeTransition(isVisible: isVisible, duration: duration))
    }
}

// MARK: - Highlight on Change

struct HighlightOnChange<V: Equatable>: ViewModifier {
    let value: V

    @State private var isHighlighted = false

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.wiseForestGreen.opacity(isHighlighted ? 0.2 : 0.0))
            )
            .animation(
                AccessibilitySettings.isReduceMotionEnabled
                    ? .none
                    : .easeInOut(duration: 0.3),
                value: isHighlighted
            )
            .onChange(of: value) { _, _ in
                isHighlighted = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isHighlighted = false
                }
            }
    }
}

extension View {
    func highlightOnChange<V: Equatable>(of value: V) -> some View {
        self.modifier(HighlightOnChange(value: value))
    }
}

// MARK: - Rotate on Appear

struct RotateOnAppear: ViewModifier {
    let degrees: Double
    let duration: Double

    @State private var rotation: Double = 0

    func body(content: Content) -> some View {
        content
            .rotationEffect(.degrees(rotation))
            .onAppear {
                withAnimation(
                    AccessibilitySettings.isReduceMotionEnabled
                        ? .none
                        : .linear(duration: duration).repeatForever(autoreverses: false)
                ) {
                    rotation = degrees
                }
            }
    }
}

extension View {
    func rotateOnAppear(degrees: Double = 360, duration: Double = 2.0) -> some View {
        self.modifier(RotateOnAppear(degrees: degrees, duration: duration))
    }
}

#Preview {
    VStack(spacing: 20) {
        Text("Animation Modifiers")
            .font(.headline)

        HStack(spacing: 16) {
            ForEach(0..<3) { index in
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.wiseForestGreen)
                    .frame(width: 80, height: 80)
                    .cardEntry(delay: Double(index) * 0.1)
            }
        }

        Circle()
            .fill(Color.wiseBrightGreen)
            .frame(width: 60, height: 60)
            .pulseAnimation()

        Text("Bounce on Appear")
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
            .bounceOnAppear()
    }
    .padding()
}
