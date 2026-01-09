//
//  MessageInputView.swift
//  iMessageTransactionUI
//
//  Description:
//  Bottom input area for composing and sending messages.
//  Contains text input field, Add Transaction button, and Send button.
//
//  Layout:
//  - HStack containing:
//    1. Text input field (expandable)
//    2. Add Transaction button (green)
//    3. Send button (blue, circular)
//
//  Styling:
//  - Frosted glass background effect
//  - Top border separator
//  - Text field with rounded border
//  - Buttons with appropriate sizing
//
//  Functionality:
//  - Text input binds to viewModel.messageText
//  - Send button disabled when text is empty
//  - Add Transaction button opens the transaction modal
//  - Send triggers viewModel.sendMessage()
//
//  Properties:
//  - viewModel: ChatViewModel - The view model to interact with
//

import SwiftUI

// MARK: - MessageInputView
/// Bottom input area with text field and action buttons
struct MessageInputView: View {
    
    // MARK: - Properties
    
    /// The view model to interact with
    @ObservedObject var viewModel: ChatViewModel
    
    // MARK: - Body
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            // Text input field
            textInputField
            
            // Buttons container
            buttonsContainer
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(inputAreaBackground)
    }
    
    // MARK: - Text Input Field
    /// Expandable text input with placeholder
    private var textInputField: some View {
        TextField("iMessage", text: $viewModel.messageText, axis: .vertical)
            .font(.system(size: 17))
            .lineLimit(1...5)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.white)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.inputBorder, lineWidth: 1)
            )
    }
    
    // MARK: - Buttons Container
    /// Container for Add Transaction and Send buttons
    private var buttonsContainer: some View {
        HStack(spacing: 8) {
            // Add Transaction button
            AddTransactionButton {
                viewModel.showTransactionModal()
            }
            
            // Send button
            sendButton
        }
        .padding(.bottom, 3)
    }
    
    // MARK: - Send Button
    /// Circular send button that triggers message sending
    private var sendButton: some View {
        Button(action: {
            viewModel.sendMessage()
        }) {
            Image(systemName: "arrow.up")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 32, height: 32)
                .background(viewModel.canSendMessage ? Color.iMessageBlue : Color.disabled)
                .clipShape(Circle())
        }
        .disabled(!viewModel.canSendMessage)
    }
    
    // MARK: - Input Area Background
    /// Frosted glass effect background with top border
    private var inputAreaBackground: some View {
        ZStack(alignment: .top) {
            // Blur effect background
            Color.headerBackground
                .background(.ultraThinMaterial)
            
            // Top border
            Rectangle()
                .fill(Color.black.opacity(0.1))
                .frame(height: 0.5)
        }
    }
}

// MARK: - Preview
#Preview {
    VStack {
        Spacer()
        MessageInputView(viewModel: ChatViewModel())
    }
}
