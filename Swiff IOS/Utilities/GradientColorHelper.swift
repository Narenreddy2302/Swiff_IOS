import SwiftUI

struct GradientColorHelper {

    /// Calculates a gradient color based on percentage contribution
    /// - Parameters:
    ///   - percentage: The percentage contribution (0-100)
    ///   - isIncome: True for income (green), false for expense (red)
    ///   - colorScheme: The current color scheme (light or dark)
    /// - Returns: A color from light to dark based on percentage
    static func gradientColor(for percentage: Double, isIncome: Bool, colorScheme: ColorScheme = .light) -> Color {
        if isIncome {
            return incomeGradientColor(for: percentage, colorScheme: colorScheme)
        } else {
            return expenseGradientColor(for: percentage, colorScheme: colorScheme)
        }
    }

    // MARK: - Income Gradient Colors (Using new 5-tier green palette)

    /// Light mode: GREEN 1 → GREEN 5
    private static let incomeGradientStopsLight: [(threshold: Double, color: Color)] = [
        (0,   Color(red: 238/255, green: 242/255, blue: 227/255)),  // GREEN 1 #EEF2E3 - Lightest
        (10,  Color(red: 219/255, green: 241/255, blue: 166/255)),  // Interpolated
        (20,  Color(red: 200/255, green: 241/255, blue: 105/255)),  // GREEN 2 #C8F169
        (30,  Color(red: 160/255, green: 219/255, blue: 66/255)),   // Interpolated
        (50,  Color(red: 120/255, green: 197/255, blue: 28/255)),   // GREEN 3 #78C51C
        (70,  Color(red: 42/255, green: 111/255, blue: 43/255)),    // GREEN 4 #2A6F2B
        (100, Color(red: 4/255, green: 63/255, blue: 46/255))       // GREEN 5 #043F2E - Darkest
    ]

    /// Dark mode: Subtle dark greens → Bright green (reversed direction for dark bg)
    private static let incomeGradientStopsDark: [(threshold: Double, color: Color)] = [
        (0,   Color(red: 4/255, green: 63/255, blue: 46/255).opacity(0.6)),  // GREEN 5 subtle
        (10,  Color(red: 23/255, green: 87/255, blue: 44/255)),              // Interpolated
        (20,  Color(red: 42/255, green: 111/255, blue: 43/255)),             // GREEN 4
        (30,  Color(red: 81/255, green: 154/255, blue: 35/255)),             // Interpolated
        (50,  Color(red: 120/255, green: 197/255, blue: 28/255)),            // GREEN 3
        (70,  Color(red: 160/255, green: 219/255, blue: 66/255)),            // Interpolated
        (100, Color(red: 200/255, green: 241/255, blue: 105/255))            // GREEN 2 - Brightest
    ]

    private static func incomeGradientColor(for percentage: Double, colorScheme: ColorScheme) -> Color {
        let stops = colorScheme == .dark ? incomeGradientStopsDark : incomeGradientStopsLight
        return interpolateColor(percentage: percentage, stops: stops)
    }

    // MARK: - Expense Gradient Colors

    /// Light mode: Light Red → Dark Red
    private static let expenseGradientStopsLight: [(threshold: Double, color: Color)] = [
        (0,   Color(red: 1.00, green: 0.92, blue: 0.93)),  // #FFEBEE - Lightest
        (10,  Color(red: 1.00, green: 0.80, blue: 0.82)),  // #FFCDD2
        (20,  Color(red: 0.94, green: 0.60, blue: 0.60)),  // #EF9A9A
        (30,  Color(red: 0.90, green: 0.45, blue: 0.45)),  // #E57373
        (50,  Color(red: 0.94, green: 0.33, blue: 0.31)),  // #EF5350
        (70,  Color(red: 0.83, green: 0.18, blue: 0.18)),  // #D32F2F
        (100, Color(red: 0.54, green: 0.00, blue: 0.00))   // #8B0000 - Darkest
    ]

    /// Dark mode: Subtle dark reds → Bright red (works better on dark backgrounds)
    private static let expenseGradientStopsDark: [(threshold: Double, color: Color)] = [
        (0,   Color(red: 0.29, green: 0.18, blue: 0.18)),  // #4A2D2D - Subtle dark red
        (10,  Color(red: 0.37, green: 0.24, blue: 0.24)),  // #5F3D3D
        (20,  Color(red: 0.45, green: 0.30, blue: 0.30)),  // #744D4D
        (30,  Color(red: 0.54, green: 0.36, blue: 0.36)),  // #895D5D
        (50,  Color(red: 0.62, green: 0.43, blue: 0.43)),  // #9E6D6D
        (70,  Color(red: 0.70, green: 0.49, blue: 0.49)),  // #B37D7D
        (100, Color(red: 0.78, green: 0.55, blue: 0.55))   // #C78D8D - Brightest
    ]

    private static func expenseGradientColor(for percentage: Double, colorScheme: ColorScheme) -> Color {
        let stops = colorScheme == .dark ? expenseGradientStopsDark : expenseGradientStopsLight
        return interpolateColor(percentage: percentage, stops: stops)
    }

    // MARK: - Color Interpolation

    private static func interpolateColor(percentage: Double, stops: [(threshold: Double, color: Color)]) -> Color {
        // Clamp percentage between 0 and 100
        let clampedPercentage = min(max(percentage, 0), 100)

        // Find the two stops to interpolate between
        var lowerStop = stops[0]
        var upperStop = stops[stops.count - 1]

        for i in 0..<stops.count - 1 {
            if clampedPercentage >= stops[i].threshold && clampedPercentage <= stops[i + 1].threshold {
                lowerStop = stops[i]
                upperStop = stops[i + 1]
                break
            }
        }

        // If percentage is exactly at a stop, return that color
        if clampedPercentage == lowerStop.threshold {
            return lowerStop.color
        }
        if clampedPercentage == upperStop.threshold {
            return upperStop.color
        }

        // Calculate interpolation factor
        let range = upperStop.threshold - lowerStop.threshold
        let factor = range > 0 ? (clampedPercentage - lowerStop.threshold) / range : 0

        // Interpolate between the two colors
        return interpolateColors(from: lowerStop.color, to: upperStop.color, factor: factor)
    }

    private static func interpolateColors(from startColor: Color, to endColor: Color, factor: Double) -> Color {
        // Convert SwiftUI Colors to UIColor for RGB extraction
        let uiStartColor = UIColor(startColor)
        let uiEndColor = UIColor(endColor)

        var startRed: CGFloat = 0, startGreen: CGFloat = 0, startBlue: CGFloat = 0, startAlpha: CGFloat = 0
        var endRed: CGFloat = 0, endGreen: CGFloat = 0, endBlue: CGFloat = 0, endAlpha: CGFloat = 0

        uiStartColor.getRed(&startRed, green: &startGreen, blue: &startBlue, alpha: &startAlpha)
        uiEndColor.getRed(&endRed, green: &endGreen, blue: &endBlue, alpha: &endAlpha)

        let clampedFactor = min(max(factor, 0), 1)

        let red = startRed + (endRed - startRed) * clampedFactor
        let green = startGreen + (endGreen - startGreen) * clampedFactor
        let blue = startBlue + (endBlue - startBlue) * clampedFactor
        let alpha = startAlpha + (endAlpha - startAlpha) * clampedFactor

        return Color(red: Double(red), green: Double(green), blue: Double(blue), opacity: Double(alpha))
    }

    // MARK: - Helper Methods

    /// Returns a lighter version of the gradient color for backgrounds
    static func lightGradientColor(for percentage: Double, isIncome: Bool, colorScheme: ColorScheme = .light) -> Color {
        let baseColor = gradientColor(for: percentage, isIncome: isIncome, colorScheme: colorScheme)
        // Use lower opacity in dark mode since colors are already lighter
        return baseColor.opacity(colorScheme == .dark ? 0.3 : 0.2)
    }

    /// Returns a medium opacity version for progress bars
    static func progressBarColor(for percentage: Double, isIncome: Bool, colorScheme: ColorScheme = .light) -> Color {
        let baseColor = gradientColor(for: percentage, isIncome: isIncome, colorScheme: colorScheme)
        return baseColor.opacity(colorScheme == .dark ? 0.8 : 0.6)
    }

    // MARK: - Backward Compatibility (without colorScheme parameter)

    /// Legacy method - uses light mode colors (for backward compatibility)
    static func gradientColorLegacy(for percentage: Double, isIncome: Bool) -> Color {
        return gradientColor(for: percentage, isIncome: isIncome, colorScheme: .light)
    }
}

// MARK: - Adaptive Gradient View Modifier

/// A ViewModifier that provides a gradient background that adapts to color scheme
struct AdaptiveGradientBackground: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    let percentage: Double
    let isIncome: Bool
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(GradientColorHelper.lightGradientColor(
                        for: percentage,
                        isIncome: isIncome,
                        colorScheme: colorScheme
                    ))
            )
    }
}

extension View {
    /// Applies an adaptive gradient background based on percentage contribution
    func adaptiveGradientBackground(percentage: Double, isIncome: Bool, cornerRadius: CGFloat = 12) -> some View {
        self.modifier(AdaptiveGradientBackground(
            percentage: percentage,
            isIncome: isIncome,
            cornerRadius: cornerRadius
        ))
    }
}

// MARK: - Preview

#Preview("Gradient Colors") {
    ScrollView {
        VStack(spacing: 16) {
            Text("Income Gradient (Light Mode)")
                .font(.headline)
            HStack(spacing: 4) {
                ForEach([0, 10, 20, 30, 50, 70, 100], id: \.self) { percentage in
                    RoundedRectangle(cornerRadius: 4)
                        .fill(GradientColorHelper.gradientColor(for: Double(percentage), isIncome: true, colorScheme: .light))
                        .frame(width: 40, height: 40)
                        .overlay(Text("\(percentage)%").font(.caption2).foregroundColor(.white))
                }
            }

            Text("Income Gradient (Dark Mode)")
                .font(.headline)
            HStack(spacing: 4) {
                ForEach([0, 10, 20, 30, 50, 70, 100], id: \.self) { percentage in
                    RoundedRectangle(cornerRadius: 4)
                        .fill(GradientColorHelper.gradientColor(for: Double(percentage), isIncome: true, colorScheme: .dark))
                        .frame(width: 40, height: 40)
                        .overlay(Text("\(percentage)%").font(.caption2).foregroundColor(.white))
                }
            }

            Text("Expense Gradient (Light Mode)")
                .font(.headline)
            HStack(spacing: 4) {
                ForEach([0, 10, 20, 30, 50, 70, 100], id: \.self) { percentage in
                    RoundedRectangle(cornerRadius: 4)
                        .fill(GradientColorHelper.gradientColor(for: Double(percentage), isIncome: false, colorScheme: .light))
                        .frame(width: 40, height: 40)
                        .overlay(Text("\(percentage)%").font(.caption2).foregroundColor(.white))
                }
            }

            Text("Expense Gradient (Dark Mode)")
                .font(.headline)
            HStack(spacing: 4) {
                ForEach([0, 10, 20, 30, 50, 70, 100], id: \.self) { percentage in
                    RoundedRectangle(cornerRadius: 4)
                        .fill(GradientColorHelper.gradientColor(for: Double(percentage), isIncome: false, colorScheme: .dark))
                        .frame(width: 40, height: 40)
                        .overlay(Text("\(percentage)%").font(.caption2).foregroundColor(.white))
                }
            }
        }
        .padding()
    }
}
