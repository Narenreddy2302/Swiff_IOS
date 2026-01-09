//
//  AddTransactionButton.swift
//  iMessageTransactionUI
//
//  Description:
//  Green button for adding a new transaction.
//  Displays "+" icon with "Add Transaction" text.
//
//  Styling:
//  - Green background (#34C759)
//  - White text and icon
//  - Pill shape (rounded corners)
//  - Height: 32 points
//  - Padding: 14 points horizontal
//
//  Responsive Behavior:
//  - On smaller screens, can hide text and show only icon
//  - Use horizontalSizeClass to determine layout
//
//  Properties:
//  - action: () -> Void - Callback when button is tapped
//

import SwiftUI

// MARK: - AddTransactionButton
/// Green button for adding a new transaction
struct AddTransactionButton: View {
    
    // MARK: - Properties
    
    /// Callback when button is tapped
    let action: () -> Void
    
    /// Environment variable for detecting size class
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    // MARK: - Body
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                // Plus icon
                Image(systemName: "plus")
                    .font(.system(size: 14, weight: .bold))
                
                // "Add Transaction" text (hidden on compact width)
                if horizontalSizeClass != .compact {
                    Text("Add Transaction")
                        .font(.system(size: 14, weight: .semibold))
                }
            }
            .foregroundColor(.white)
            .padding(.horizontal, horizontalSizeClass == .compact ? 0 : 14)
            .frame(width: horizontalSizeClass == .compact ? 32 : nil, height: 32)
            .background(Color.owedGreen)
            .clipShape(Capsule())
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Scale Button Style
/// Custom button style that scales down on press
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 20) {
        AddTransactionButton {
            print("Add transaction tapped")
        }
        
        // Simulate compact width
        AddTransactionButton {
            print("Add transaction tapped")
        }
        .environment(\.horizontalSizeClass, .compact)
    }
    .padding()
}
