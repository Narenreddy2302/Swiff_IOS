//
//  ChatViewModel.swift
//  iMessageTransactionUI
//
//  Description:
//  Main ViewModel handling all business logic for the chat interface.
//  Follows MVVM pattern - all state and logic is centralized here.
//
//  Responsibilities:
//  - Managing the list of messages
//  - Handling message input and sending
//  - Managing transaction form state and validation
//  - Calculating net balance from all transactions
//  - Adding/removing people from transaction splits
//
//  Published Properties (trigger UI updates when changed):
//  - messages: Array of all chat messages
//  - messageText: Current text in the message input field
//  - isShowingTransactionModal: Controls modal visibility
//  - Transaction form fields: transactionName, totalBill, paidBy, splitMethod, people
//
//  Key Methods:
//  - sendMessage(): Sends a text message
//  - createTransaction(): Creates and sends a transaction message
//  - addPerson(name:): Adds a person to the transaction split
//  - removePerson(name:): Removes a person from the split
//  - resetTransactionForm(): Clears all form fields
//
//  Balance Calculation:
//  - Iterates through all transaction messages
//  - Sums up youOwe and owedToYou for each transaction
//  - Returns net balance as BalanceType enum
//

import Foundation
import SwiftUI

// MARK: - ChatViewModel
/// Main ViewModel for the chat interface, managing all state and business logic
class ChatViewModel: ObservableObject {
    
    // MARK: - Published Properties (Chat State)
    
    /// Array of all messages in the conversation
    /// Includes both text messages and transaction messages
    @Published var messages: [Message] = []
    
    /// Current text in the message input field
    @Published var messageText: String = ""
    
    /// Controls visibility of the Add Transaction modal
    @Published var isShowingTransactionModal: Bool = false
    
    // MARK: - Published Properties (Transaction Form State)
    
    /// Name/description of the transaction being created
    @Published var transactionName: String = ""
    
    /// Total bill amount as a string (for text field binding)
    @Published var totalBillString: String = ""
    
    /// Name of the person who paid
    @Published var paidBy: String = ""
    
    /// Selected split method
    @Published var splitMethod: String = "Equally"
    
    /// Array of people involved in the transaction split
    @Published var people: [String] = []
    
    /// Current text in the person input field
    @Published var personInputText: String = ""
    
    // MARK: - Constants
    
    /// Available split method options
    let splitMethodOptions = ["Equally", "By Percentage", "Custom Amount"]
    
    /// Name representing the current user
    let currentUser = "You"
    
    // MARK: - Initializer
    
    /// Initializes the ViewModel with sample data
    init() {
        // Load sample messages for demonstration
        // In production, this would load from a data source
        self.messages = Message.sampleMessages
    }
    
    // MARK: - Computed Properties
    
    /// Validates if the transaction form is complete and valid
    /// - Returns: true if all required fields are filled correctly
    ///
    /// Validation Rules:
    /// - Transaction name must not be empty
    /// - Total bill must be a valid number greater than 0
    /// - Paid by must not be empty
    /// - At least one person must be added to the split
    var isFormValid: Bool {
        let trimmedName = transactionName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPaidBy = paidBy.trimmingCharacters(in: .whitespacesAndNewlines)
        let billAmount = Double(totalBillString) ?? 0
        
        return !trimmedName.isEmpty &&
               billAmount > 0 &&
               !trimmedPaidBy.isEmpty &&
               !people.isEmpty
    }
    
    /// Calculates the net balance from all transactions
    /// - Returns: BalanceType indicating overall balance state
    ///
    /// Calculation Logic:
    /// 1. Iterate through all messages that contain transactions
    /// 2. Sum up the youOwe amounts (what user owes others)
    /// 3. Sum up the owedToYou amounts (what others owe user)
    /// 4. Calculate net: owedToYou - youOwe
    /// 5. Return appropriate BalanceType based on net value
    var netBalance: BalanceType {
        var totalYouOwe: Double = 0
        var totalOwedToYou: Double = 0
        
        // Iterate through all messages and sum transaction amounts
        for message in messages {
            if let transaction = message.transaction {
                totalYouOwe += transaction.youOwe
                totalOwedToYou += transaction.owedToYou
            }
        }
        
        // Calculate net balance
        let net = totalOwedToYou - totalYouOwe
        
        // Return appropriate BalanceType
        if net > 0.001 {
            // Positive balance: others owe the user
            return .theyOwe(net)
        } else if net < -0.001 {
            // Negative balance: user owes others
            return .youOwe(abs(net))
        } else {
            // Zero balance: all settled
            return .settled
        }
    }
    
    /// Checks if the send button should be enabled
    /// - Returns: true if messageText is not empty
    var canSendMessage: Bool {
        return !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    // MARK: - Message Methods
    
    /// Sends a text message
    /// Creates a new Message with the current messageText and adds it to messages
    /// Clears the messageText after sending
    ///
    /// Post-Action: Simulates a random reply for demo purposes
    func sendMessage() {
        let trimmedText = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }
        
        // Create and add the new message
        let newMessage = Message(
            content: trimmedText,
            type: .sent,
            timestamp: Date()
        )
        messages.append(newMessage)
        
        // Clear the input field
        messageText = ""
        
        // Simulate a reply for demo purposes
        simulateReply()
    }
    
    /// Simulates a received reply message for demonstration
    /// Randomly selects from preset replies and adds after a delay
    private func simulateReply() {
        let replies = [
            "Got it! 👍",
            "Sounds good to me!",
            "Perfect, thanks for letting me know.",
            "I'll check and get back to you.",
            "Sure thing!"
        ]
        
        // 50% chance of getting a reply
        guard Bool.random() else { return }
        
        // Random delay between 1-2 seconds
        let delay = Double.random(in: 1.0...2.0)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            guard let self = self else { return }
            let randomReply = replies.randomElement() ?? "👍"
            let replyMessage = Message(
                content: randomReply,
                type: .received,
                timestamp: Date()
            )
            self.messages.append(replyMessage)
        }
    }
    
    // MARK: - Transaction Methods
    
    /// Creates a new transaction and sends it as a message
    /// Uses the current form field values to create the Transaction
    /// Adds the transaction as a sent message and resets the form
    ///
    /// Post-Action: Simulates an acknowledgment reply
    func createTransaction() {
        guard isFormValid else { return }
        
        let billAmount = Double(totalBillString) ?? 0
        
        // Create the transaction
        let transaction = Transaction(
            name: transactionName.trimmingCharacters(in: .whitespacesAndNewlines),
            totalBill: billAmount,
            paidBy: paidBy.trimmingCharacters(in: .whitespacesAndNewlines),
            splitMethod: splitMethod,
            people: people,
            creatorName: currentUser,
            timestamp: Date()
        )
        
        // Create a message containing the transaction
        let transactionMessage = Message(
            content: "",
            type: .sent,
            timestamp: Date(),
            transaction: transaction
        )
        
        // Add to messages
        messages.append(transactionMessage)
        
        // Reset form and close modal
        resetTransactionForm()
        isShowingTransactionModal = false
        
        // Simulate acknowledgment reply
        simulateTransactionReply()
    }
    
    /// Simulates a reply acknowledging the transaction
    private func simulateTransactionReply() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            guard let self = self else { return }
            let replyMessage = Message(
                content: "Thanks for creating the transaction! I'll pay my share soon.",
                type: .received,
                timestamp: Date()
            )
            self.messages.append(replyMessage)
        }
    }
    
    // MARK: - People Management Methods
    
    /// Adds a person to the transaction split
    /// - Parameter name: Name of the person to add
    ///
    /// Validation:
    /// - Name must not be empty after trimming
    /// - Name must not already exist in the people array (case-sensitive)
    func addPerson(_ name: String) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        
        // Check if person already exists
        if !people.contains(trimmedName) {
            people.append(trimmedName)
        }
        
        // Clear the input field
        personInputText = ""
    }
    
    /// Removes a person from the transaction split
    /// - Parameter name: Name of the person to remove
    func removePerson(_ name: String) {
        people.removeAll { $0 == name }
    }
    
    /// Removes the last person from the split
    /// Called when user presses backspace on empty input field
    func removeLastPerson() {
        guard !people.isEmpty else { return }
        people.removeLast()
    }
    
    // MARK: - Form Management Methods
    
    /// Resets all transaction form fields to their default values
    /// Called after creating a transaction or when canceling the modal
    func resetTransactionForm() {
        transactionName = ""
        totalBillString = ""
        paidBy = ""
        splitMethod = "Equally"
        people = []
        personInputText = ""
    }
    
    /// Opens the transaction modal
    func showTransactionModal() {
        isShowingTransactionModal = true
    }
    
    /// Closes the transaction modal and resets the form
    func closeTransactionModal() {
        isShowingTransactionModal = false
        resetTransactionForm()
    }
}
