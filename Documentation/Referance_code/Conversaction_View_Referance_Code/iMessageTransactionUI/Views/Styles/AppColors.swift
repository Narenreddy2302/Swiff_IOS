//
//  AppColors.swift
//  iMessageTransactionUI
//
//  Description:
//  Centralized color definitions for the entire application.
//  All colors match the original HTML/CSS implementation exactly.
//
//  Usage:
//  Access colors via Color extension: Color.iMessageBlue, Color.oweRed, etc.
//
//  Color Categories:
//  - iMessage Colors: Blue and gray for message bubbles
//  - Balance Colors: Red for "you owe", green for "they owe"
//  - Transaction Colors: Orange for transaction amounts
//  - UI Colors: Backgrounds, text, borders, etc.
//
//  Color Values (Hex):
//  - iMessageBlue: #007AFF (iOS system blue)
//  - iMessageGray: #E9E9EB (received message background)
//  - oweRed: #FF3B30 (iOS system red)
//  - owedGreen: #34C759 (iOS system green)
//  - transactionOrange: #FF6B35 (transaction amount in received bubbles)
//  - transactionYellow: #FFD60A (transaction amount in sent bubbles)
//

import SwiftUI

// MARK: - Color Extension
extension Color {
    
    // MARK: - iMessage Bubble Colors
    
    /// iMessage blue color for sent message bubbles
    /// Hex: #007AFF - iOS system blue
    static let iMessageBlue = Color(red: 0/255, green: 122/255, blue: 255/255)
    
    /// iMessage gray color for received message bubbles
    /// Hex: #E9E9EB
    static let iMessageGray = Color(red: 233/255, green: 233/255, blue: 235/255)
    
    // MARK: - Balance Indicator Colors
    
    /// Red color for "You owe" balance display
    /// Hex: #FF3B30 - iOS system red
    static let oweRed = Color(red: 255/255, green: 59/255, blue: 48/255)
    
    /// Green color for "They owe you" balance display
    /// Also used for the Add Transaction button
    /// Hex: #34C759 - iOS system green
    static let owedGreen = Color(red: 52/255, green: 199/255, blue: 89/255)
    
    // MARK: - Transaction Amount Colors
    
    /// Orange color for transaction amounts in received (gray) bubbles
    /// Hex: #FF6B35
    static let transactionOrange = Color(red: 255/255, green: 107/255, blue: 53/255)
    
    /// Yellow color for transaction amounts in sent (blue) bubbles
    /// Hex: #FFD60A
    static let transactionYellow = Color(red: 255/255, green: 214/255, blue: 10/255)
    
    // MARK: - Text Colors
    
    /// Primary text color (black)
    /// Hex: #000000
    static let textPrimary = Color(red: 0/255, green: 0/255, blue: 0/255)
    
    /// Secondary text color (gray)
    /// Used for timestamps, labels, and secondary information
    /// Hex: #8E8E93
    static let textSecondary = Color(red: 142/255, green: 142/255, blue: 147/255)
    
    // MARK: - UI Element Colors
    
    /// Header background color with slight transparency
    /// Hex: #F6F6F6 at 92% opacity
    static let headerBackground = Color(red: 246/255, green: 246/255, blue: 246/255).opacity(0.92)
    
    /// Input field border color
    /// Hex: #C6C6C8
    static let inputBorder = Color(red: 198/255, green: 198/255, blue: 200/255)
    
    /// Placeholder text color
    /// Hex: #C7C7CC
    static let placeholder = Color(red: 199/255, green: 199/255, blue: 204/255)
    
    /// Disabled button color
    /// Hex: #C7C7CC
    static let disabled = Color(red: 199/255, green: 199/255, blue: 204/255)
    
    /// Divider line color in transaction cards (for received bubbles)
    /// Black at 8% opacity
    static let transactionDivider = Color.black.opacity(0.08)
    
    /// Divider line color in transaction cards (for sent bubbles)
    /// White at 20% opacity
    static let transactionDividerSent = Color.white.opacity(0.2)
    
    /// Person tag background color
    /// Uses iMessageGray
    static let personTagBackground = Color.iMessageGray
    
    /// Person tag remove button background
    /// Hex: #8E8E93
    static let personTagRemove = Color(red: 142/255, green: 142/255, blue: 147/255)
}

// MARK: - Color Helper Extension
extension Color {
    
    /// Creates a Color from a hex string
    /// - Parameter hex: Hex color string (with or without #)
    /// - Returns: Color instance
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
