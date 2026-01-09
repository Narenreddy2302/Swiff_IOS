//
//  PersonTagView.swift
//  iMessageTransactionUI
//
//  Description:
//  Displays a single person tag chip with a remove button.
//  Used in the "Who are all involved" section of the transaction form.
//
//  Layout:
//  - HStack containing:
//    1. Person name text
//    2. Remove button (circular with "×")
//
//  Styling:
//  - Gray background (#E9E9EB)
//  - Pill shape (rounded corners)
//  - Padding: 6pt vertical, 10pt horizontal
//  - Remove button: 18x18 circle, gray background (#8E8E93)
//
//  Properties:
//  - name: String - The person's name to display
//  - onRemove: () -> Void - Callback when remove button is tapped
//

import SwiftUI

// MARK: - PersonTagView
/// Displays a person tag chip with a remove button
struct PersonTagView: View {
    
    // MARK: - Properties
    
    /// The person's name to display
    let name: String
    
    /// Callback when remove button is tapped
    let onRemove: () -> Void
    
    // MARK: - Body
    
    var body: some View {
        HStack(spacing: 6) {
            // Person name
            Text(name)
                .font(.system(size: 15))
                .foregroundColor(.textPrimary)
            
            // Remove button
            removeButton
        }
        .padding(.vertical, 6)
        .padding(.leading, 10)
        .padding(.trailing, 6)
        .background(Color.personTagBackground)
        .clipShape(Capsule())
    }
    
    // MARK: - Remove Button
    /// Circular button to remove the person
    private var removeButton: some View {
        Button(action: onRemove) {
            Image(systemName: "xmark")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 18, height: 18)
                .background(Color.personTagRemove)
                .clipShape(Circle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 16) {
        PersonTagView(name: "Person 1") {
            print("Remove Person 1")
        }
        
        PersonTagView(name: "John Doe") {
            print("Remove John Doe")
        }
        
        PersonTagView(name: "You") {
            print("Remove You")
        }
        
        // Multiple tags in a row
        HStack {
            PersonTagView(name: "Alice") {}
            PersonTagView(name: "Bob") {}
            PersonTagView(name: "Charlie") {}
        }
    }
    .padding()
}
