//
//  Message.swift
//  iMessageTransactionUI
//
//  Description:
//  Model representing a single message in the chat conversation.
//  A message can be either a regular text message or a transaction message.
//
//  Properties:
//  - id: Unique identifier for the message
//  - content: Text content of the message (for text messages)
//  - type: Whether the message is sent by user or received from others
//  - timestamp: When the message was sent
//  - transaction: Optional transaction data (nil for text messages)
//
//  Message Types:
//  - .sent: Messages from the current user (displayed on right, blue bubble)
//  - .received: Messages from other users (displayed on left, gray bubble)
//
//  Transaction Messages:
//  - When transaction is not nil, the message displays as a transaction card
//  - The transaction card is styled based on the message type (sent/received)
//

import Foundation

// MARK: - MessageType Enum
/// Indicates whether a message was sent by the user or received from others
enum MessageType {
    /// Message sent by the current user
    /// - Display: Right-aligned, blue background, white text
    case sent
    
    /// Message received from another user
    /// - Display: Left-aligned, gray background, black text
    case received
}

// MARK: - Message Model
/// Represents a single message in the chat conversation
struct Message: Identifiable, Equatable {
    
    // MARK: - Properties
    
    /// Unique identifier for the message
    let id: UUID
    
    /// Text content of the message
    /// - For text messages: The actual message text
    /// - For transaction messages: Can be empty, transaction data is displayed instead
    let content: String
    
    /// Type of message (sent or received)
    /// Determines the visual styling and alignment of the message bubble
    let type: MessageType
    
    /// Timestamp when the message was sent
    let timestamp: Date
    
    /// Optional transaction data
    /// - nil: Regular text message
    /// - Transaction: Transaction card message
    let transaction: Transaction?
    
    // MARK: - Initializer
    
    /// Creates a new Message instance
    /// - Parameters:
    ///   - id: Unique identifier (defaults to new UUID)
    ///   - content: Text content of the message
    ///   - type: Sent or received
    ///   - timestamp: When the message was sent (defaults to now)
    ///   - transaction: Optional transaction data
    init(
        id: UUID = UUID(),
        content: String,
        type: MessageType,
        timestamp: Date = Date(),
        transaction: Transaction? = nil
    ) {
        self.id = id
        self.content = content
        self.type = type
        self.timestamp = timestamp
        self.transaction = transaction
    }
    
    // MARK: - Computed Properties
    
    /// Checks if this message contains a transaction
    /// - Returns: true if transaction is not nil
    var isTransaction: Bool {
        return transaction != nil
    }
    
    /// Checks if this message was sent by the current user
    /// - Returns: true if type is .sent
    var isSent: Bool {
        return type == .sent
    }
    
    /// Checks if this message was received from another user
    /// - Returns: true if type is .received
    var isReceived: Bool {
        return type == .received
    }
    
    /// Formatted time string for display
    /// - Returns: Time in format "h:mm a" (e.g., "6:30 PM")
    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: timestamp)
    }
    
    // MARK: - Equatable
    
    static func == (lhs: Message, rhs: Message) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - Sample Data Extension
extension Message {
    
    /// Sample messages for preview and testing purposes
    /// These match the HTML implementation's sample data
    static let sampleMessages: [Message] = [
        // Yesterday's messages
        Message(
            content: "Hey everyone! How about we split the dinner bill from last night?",
            type: .received,
            timestamp: Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        ),
        Message(
            content: "Sounds good! How much was it in total?",
            type: .sent,
            timestamp: Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        ),
        Message(
            content: "Let me create a transaction for it",
            type: .received,
            timestamp: Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        ),
        // Transaction 1 - Received
        Message(
            content: "",
            type: .received,
            timestamp: Calendar.current.date(byAdding: .day, value: -1, to: Date())!,
            transaction: Transaction(
                name: "Transaction Name",
                totalBill: 99.99,
                paidBy: "Naren Reddy",
                splitMethod: "Equally",
                people: ["Person 1", "Person 2", "Person 3"],
                creatorName: "Naren Reddy"
            )
        ),
        Message(
            content: "Got it! I'll pay you back soon 👍",
            type: .sent,
            timestamp: Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        ),
        
        // Today's messages
        Message(
            content: "Hey, I also paid for the movie tickets yesterday",
            type: .received,
            timestamp: Date()
        ),
        // Transaction 2 - Movie Tickets (received)
        Message(
            content: "",
            type: .received,
            timestamp: Date(),
            transaction: Transaction(
                name: "Movie Tickets",
                totalBill: 45.00,
                paidBy: "Naren Reddy",
                splitMethod: "Equally",
                people: ["Person 1", "Person 2", "Person 3"],
                creatorName: "Naren Reddy"
            )
        ),
        Message(
            content: "No problem! Let me add the groceries we bought together",
            type: .sent,
            timestamp: Date()
        ),
        // Transaction 3 - Groceries (sent - user paid)
        Message(
            content: "",
            type: .sent,
            timestamp: Date(),
            transaction: Transaction(
                name: "Groceries",
                totalBill: 50.00,
                paidBy: "You",
                splitMethod: "Equally",
                people: ["Person 1", "Person 2", "Person 3", "You"],
                creatorName: "You"
            )
        ),
        Message(
            content: "Thanks for adding that! I'll settle up with everyone soon",
            type: .received,
            timestamp: Date()
        ),
        // Transaction 4 - Uber (received)
        Message(
            content: "",
            type: .received,
            timestamp: Date(),
            transaction: Transaction(
                name: "Uber Ride",
                totalBill: 35.00,
                paidBy: "Sarah",
                splitMethod: "Equally",
                people: ["Person 1", "Person 2", "Person 3", "Person 4"],
                creatorName: "Sarah"
            )
        ),
        Message(
            content: "Perfect, all the expenses are tracked now!",
            type: .sent,
            timestamp: Date()
        )
    ]
}
