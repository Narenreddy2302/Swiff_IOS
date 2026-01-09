//
//  ChatView.swift
//  iMessageTransactionUI
//
//  Description:
//  Main container view for the chat interface.
//  Combines the header, messages list, and input area into a complete chat screen.
//
//  Structure:
//  - VStack containing:
//    1. ChatHeaderView (top navigation bar with balance)
//    2. ScrollView with messages list
//    3. MessageInputView (bottom input area)
//  - Sheet for TransactionModalView
//
//  State Management:
//  - Owns the ChatViewModel as @StateObject
//  - Passes viewModel to child views via @ObservedObject or @EnvironmentObject
//
//  Features:
//  - Auto-scrolls to bottom when new messages are added
//  - Groups messages by date with DateSeparatorView
//  - Presents transaction modal as a sheet
//

import SwiftUI

// MARK: - ChatView
/// Main container view for the iMessage-style chat interface
struct ChatView: View {
    
    // MARK: - Properties
    
    /// Main view model managing all chat state and logic
    /// @StateObject ensures the view model persists across view updates
    @StateObject private var viewModel = ChatViewModel()
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            // MARK: Header
            // Top navigation bar with back button, contact info, and balance summary
            ChatHeaderView(balance: viewModel.netBalance)
            
            // MARK: Messages List
            // Scrollable list of all messages with auto-scroll to bottom
            messagesListView
            
            // MARK: Input Area
            // Bottom area with text input and action buttons
            MessageInputView(viewModel: viewModel)
        }
        .background(Color.white)
        // MARK: Transaction Modal
        // Presented as a sheet when isShowingTransactionModal is true
        .sheet(isPresented: $viewModel.isShowingTransactionModal) {
            TransactionModalView(viewModel: viewModel)
        }
    }
    
    // MARK: - Messages List View
    /// Scrollable list of messages with date separators
    private var messagesListView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 6) {
                    // Iterate through messages with date grouping
                    ForEach(Array(viewModel.messages.enumerated()), id: \.element.id) { index, message in
                        
                        // MARK: Date Separator Logic
                        // Show date separator if:
                        // 1. First message, OR
                        // 2. Different day than previous message
                        if shouldShowDateSeparator(for: index) {
                            DateSeparatorView(date: message.timestamp)
                        }
                        
                        // MARK: Message Row
                        // Renders either text bubble or transaction bubble
                        MessageRowView(message: message)
                            .id(message.id)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
            }
            // Auto-scroll to bottom when messages change
            .onChange(of: viewModel.messages.count) { _ in
                withAnimation(.easeOut(duration: 0.3)) {
                    if let lastMessage = viewModel.messages.last {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
            // Initial scroll to bottom on appear
            .onAppear {
                if let lastMessage = viewModel.messages.last {
                    proxy.scrollTo(lastMessage.id, anchor: .bottom)
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    /// Determines if a date separator should be shown before a message
    /// - Parameter index: Index of the message in the array
    /// - Returns: true if separator should be shown
    ///
    /// Logic:
    /// - First message always shows separator
    /// - Subsequent messages show separator only if on different day than previous
    private func shouldShowDateSeparator(for index: Int) -> Bool {
        guard index > 0 else { return true } // First message
        
        let currentMessage = viewModel.messages[index]
        let previousMessage = viewModel.messages[index - 1]
        
        // Show separator if not the same day
        return !currentMessage.timestamp.isSameDay(as: previousMessage.timestamp)
    }
}

// MARK: - Preview
#Preview {
    ChatView()
}
