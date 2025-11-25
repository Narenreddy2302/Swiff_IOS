//
//  AccessibilityViewModifiers.swift
//  Swiff IOS
//
//  Created by Agent 11 on 11/21/25.
//  Enhanced accessibility view modifiers for comprehensive support
//

import SwiftUI

// MARK: - Accessible Card Modifier

struct AccessibleCard: ViewModifier {
    let label: String
    let hint: String?
    let value: String?
    let isButton: Bool

    func body(content: Content) -> some View {
        content
            .accessibilityElement(children: .combine)
            .accessibilityLabel(label)
            .if(hint != nil) { view in
                view.accessibilityHint(hint!)
            }
            .if(value != nil) { view in
                view.accessibilityValue(value!)
            }
            .if(isButton) { view in
                view.accessibilityAddTraits(.isButton)
            }
            .accessibilityAction {
                // Default action
            }
    }
}

extension View {
    func accessibleCard(
        label: String,
        hint: String? = nil,
        value: String? = nil,
        isButton: Bool = false
    ) -> some View {
        self.modifier(AccessibleCard(
            label: label,
            hint: hint,
            value: value,
            isButton: isButton
        ))
    }
}

// MARK: - Minimum Touch Target Size

struct MinimumTouchTarget: ViewModifier {
    let size: CGFloat

    func body(content: Content) -> some View {
        content
            .frame(minWidth: size, minHeight: size)
            .contentShape(Rectangle())
    }
}

extension View {
    func minimumTouchTarget(size: CGFloat = 44) -> some View {
        self.modifier(MinimumTouchTarget(size: size))
    }
}

// MARK: - Dynamic Type Support

struct DynamicTypeSupport: ViewModifier {
    let minimumScaleFactor: CGFloat
    let lineLimit: Int?

    func body(content: Content) -> some View {
        content
            .minimumScaleFactor(minimumScaleFactor)
            .if(lineLimit == nil) { view in
                view.lineLimit(nil)
            }
            .if(lineLimit != nil) { view in
                view.lineLimit(lineLimit!)
            }
    }
}

extension View {
    func dynamicTypeSupport(
        minimumScaleFactor: CGFloat = 0.5,
        lineLimit: Int? = nil
    ) -> some View {
        self.modifier(DynamicTypeSupport(
            minimumScaleFactor: minimumScaleFactor,
            lineLimit: lineLimit
        ))
    }
}

// MARK: - Accessible List Row

struct AccessibleListRow: ViewModifier {
    let title: String
    let subtitle: String?
    let value: String?

    var accessibilityText: String {
        var text = title
        if let subtitle = subtitle {
            text += ". \(subtitle)"
        }
        if let value = value {
            text += ". \(value)"
        }
        return text
    }

    func body(content: Content) -> some View {
        content
            .accessibilityElement(children: .combine)
            .accessibilityLabel(accessibilityText)
    }
}

extension View {
    func accessibleListRow(
        title: String,
        subtitle: String? = nil,
        value: String? = nil
    ) -> some View {
        self.modifier(AccessibleListRow(
            title: title,
            subtitle: subtitle,
            value: value
        ))
    }
}

// MARK: - VoiceOver Focus

struct VoiceOverFocus: ViewModifier {
    let shouldFocus: Bool
    @AccessibilityFocusState private var isFocused: Bool

    func body(content: Content) -> some View {
        content
            .accessibilityFocused($isFocused)
            .onAppear {
                if shouldFocus {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        isFocused = true
                    }
                }
            }
    }
}

extension View {
    func voiceOverFocus(shouldFocus: Bool = true) -> some View {
        self.modifier(VoiceOverFocus(shouldFocus: shouldFocus))
    }
}

// MARK: - Semantic Content Attribute

struct SemanticContent: ViewModifier {
    let attribute: UISemanticContentAttribute

    func body(content: Content) -> some View {
        content
            .environment(\.layoutDirection, attribute == .forceRightToLeft ? .rightToLeft : .leftToRight)
    }
}

extension View {
    func semanticContent(_ attribute: UISemanticContentAttribute = .unspecified) -> some View {
        self.modifier(SemanticContent(attribute: attribute))
    }
}

// MARK: - Contrast Adjustment

struct ContrastAdjustment: ViewModifier {
    @Environment(\.accessibilityReduceTransparency) var reduceTransparency
    @Environment(\.colorScheme) var colorScheme

    let normalOpacity: Double
    let highContrastOpacity: Double

    func body(content: Content) -> some View {
        content
            .opacity(reduceTransparency ? highContrastOpacity : normalOpacity)
    }
}

extension View {
    func contrastAdjustment(
        normalOpacity: Double = 1.0,
        highContrastOpacity: Double = 1.0
    ) -> some View {
        self.modifier(ContrastAdjustment(
            normalOpacity: normalOpacity,
            highContrastOpacity: highContrastOpacity
        ))
    }
}

// MARK: - Accessible Image

struct AccessibleImage: ViewModifier {
    let label: String
    let isDecorative: Bool

    func body(content: Content) -> some View {
        content
            .accessibilityLabel(isDecorative ? "" : label)
            .accessibilityHidden(isDecorative)
    }
}

extension View {
    func accessibleImage(
        label: String,
        isDecorative: Bool = false
    ) -> some View {
        self.modifier(AccessibleImage(
            label: label,
            isDecorative: isDecorative
        ))
    }
}

// MARK: - Accessible Value Format

struct AccessibleValueFormat: ViewModifier {
    let value: Double
    let format: ValueFormat

    enum ValueFormat {
        case currency(String)
        case percentage
        case number
        case custom((Double) -> String)
    }

    var formattedValue: String {
        switch format {
        case .currency(let symbol):
            return "\(symbol)\(String(format: "%.2f", abs(value)))"
        case .percentage:
            return "\(Int(value * 100))%"
        case .number:
            return "\(value)"
        case .custom(let formatter):
            return formatter(value)
        }
    }

    func body(content: Content) -> some View {
        content
            .accessibilityValue(formattedValue)
    }
}

extension View {
    func accessibleValue(
        _ value: Double,
        format: AccessibleValueFormat.ValueFormat
    ) -> some View {
        self.modifier(AccessibleValueFormat(value: value, format: format))
    }
}

// MARK: - Sort Priority

struct AccessibilitySortPriority: ViewModifier {
    let priority: Double

    func body(content: Content) -> some View {
        content
            .accessibilitySortPriority(priority)
    }
}

extension View {
    func accessibleSortPriority(_ priority: Double) -> some View {
        self.modifier(AccessibilitySortPriority(priority: priority))
    }
}

// MARK: - Accessible Toggle

struct AccessibleToggle: ViewModifier {
    @Binding var isOn: Bool
    let label: String

    func body(content: Content) -> some View {
        content
            .accessibilityElement(children: .combine)
            .accessibilityLabel(label)
            .accessibilityValue(isOn ? "On" : "Off")
            .accessibilityAddTraits(.isButton)
            .accessibilityAction {
                isOn.toggle()
            }
    }
}

extension View {
    func accessibleToggle(
        isOn: Binding<Bool>,
        label: String
    ) -> some View {
        self.modifier(AccessibleToggle(isOn: isOn, label: label))
    }
}

// MARK: - Smart Label Builder

struct SmartAccessibilityLabel: ViewModifier {
    let components: [String?]

    var label: String {
        components
            .compactMap { $0 }
            .filter { !$0.isEmpty }
            .joined(separator: ". ")
    }

    func body(content: Content) -> some View {
        content
            .accessibilityLabel(label)
    }
}

extension View {
    func smartAccessibilityLabel(_ components: String?...) -> some View {
        self.modifier(SmartAccessibilityLabel(components: components))
    }
}

// MARK: - Reduce Motion Transition

struct ReduceMotionTransition: ViewModifier {
    let isVisible: Bool
    let normalTransition: AnyTransition
    let reducedTransition: AnyTransition

    func body(content: Content) -> some View {
        content
            .transition(
                AccessibilitySettings.isReduceMotionEnabled
                    ? reducedTransition
                    : normalTransition
            )
    }
}

extension View {
    func reduceMotionTransition(
        isVisible: Bool,
        normal: AnyTransition = .slideAndFade,
        reduced: AnyTransition = .opacity
    ) -> some View {
        self.modifier(ReduceMotionTransition(
            isVisible: isVisible,
            normalTransition: normal,
            reducedTransition: reduced
        ))
    }
}

// MARK: - Comprehensive Accessibility

struct ComprehensiveAccessibility: ViewModifier {
    let label: String
    let hint: String?
    let value: String?
    let traits: AccessibilityTraits
    let minimumTouchSize: CGFloat

    func body(content: Content) -> some View {
        content
            .frame(minWidth: minimumTouchSize, minHeight: minimumTouchSize)
            .contentShape(Rectangle())
            .accessibilityElement(children: .combine)
            .accessibilityLabel(label)
            .if(hint != nil) { view in
                view.accessibilityHint(hint!)
            }
            .if(value != nil) { view in
                view.accessibilityValue(value!)
            }
            .accessibilityAddTraits(traits)
    }
}

extension View {
    func comprehensiveAccessibility(
        label: String,
        hint: String? = nil,
        value: String? = nil,
        traits: AccessibilityTraits = [],
        minimumTouchSize: CGFloat = 44
    ) -> some View {
        self.modifier(ComprehensiveAccessibility(
            label: label,
            hint: hint,
            value: value,
            traits: traits,
            minimumTouchSize: minimumTouchSize
        ))
    }
}

#Preview {
    VStack(spacing: 20) {
        Text("Accessibility Features")
            .font(.headline)
            .accessibleHeader(label: "Accessibility demo")

        Button("Accessible Button") {}
            .padding()
            .background(Color.wiseForestGreen)
            .foregroundColor(.white)
            .cornerRadius(12)
            .comprehensiveAccessibility(
                label: "Save changes",
                hint: "Double tap to save your changes",
                traits: .isButton
            )

        HStack {
            Image(systemName: "star.fill")
                .accessibleImage(label: "Featured item", isDecorative: false)

            Text("Item Name")
                .dynamicTypeSupport(minimumScaleFactor: 0.7)
        }
        .accessibleCard(
            label: "Featured item with name",
            hint: "Double tap to view details",
            isButton: true
        )
        .minimumTouchTarget()
    }
    .padding()
}
