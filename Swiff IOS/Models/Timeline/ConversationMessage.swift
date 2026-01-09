//
//  ConversationMessage.swift
//  Swiff IOS
//
//  Unified message model for conversation timelines
//  Supports text messages across Person, Contact, Group, and Subscription entities
//

import Foundation

// MARK: - Message Entity Type

/// Represents the type of entity a message is associated with
/// Named MessageEntityType to avoid conflict with DataRefreshModifiers.EntityType
enum MessageEntityType: String, Codable, Hashable {
    case person
    case contact
    case group
    case subscription
}

// MARK: - Message Status

/// Represents the delivery status of a message
enum MessageStatus: String, Codable, Hashable {
    case sending    // Message is being sent
    case sent       // Message sent successfully
    case delivered  // Message delivered to recipient
    case read       // Message read by recipient
    case failed     // Message failed to send
}

// MARK: - Conversation Message

/// A text message in a conversation timeline
/// Used for direct messaging between users within the context of
/// expense tracking, dues management, and subscription sharing
struct ConversationMessage: Identifiable, Codable, Hashable {
    let id: UUID
    let entityId: UUID          // Person/Contact/Group/Subscription ID
    let entityType: MessageEntityType
    let content: String
    let isSent: Bool            // true = outgoing (current user), false = incoming
    let timestamp: Date
    var status: MessageStatus

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        entityId: UUID,
        entityType: MessageEntityType,
        content: String,
        isSent: Bool,
        timestamp: Date = Date(),
        status: MessageStatus = .sent
    ) {
        self.id = id
        self.entityId = entityId
        self.entityType = entityType
        self.content = content
        self.isSent = isSent
        self.timestamp = timestamp
        self.status = status
    }

    // MARK: - Convenience Initializers

    /// Create a message for a contact conversation
    static func forContact(
        _ contactId: String,
        content: String,
        isSent: Bool
    ) -> ConversationMessage {
        // Convert string contact ID to UUID using deterministic hashing
        let entityId = UUID(uuidString: contactId) ?? UUID(uuid: UUID_NULL)
        return ConversationMessage(
            entityId: entityId,
            entityType: .contact,
            content: content,
            isSent: isSent
        )
    }

    /// Create a message for a person conversation
    static func forPerson(
        _ personId: UUID,
        content: String,
        isSent: Bool
    ) -> ConversationMessage {
        return ConversationMessage(
            entityId: personId,
            entityType: .person,
            content: content,
            isSent: isSent
        )
    }

    /// Create a message for a group conversation
    static func forGroup(
        _ groupId: UUID,
        content: String,
        isSent: Bool
    ) -> ConversationMessage {
        return ConversationMessage(
            entityId: groupId,
            entityType: .group,
            content: content,
            isSent: isSent
        )
    }

    /// Create a message for a subscription conversation
    static func forSubscription(
        _ subscriptionId: UUID,
        content: String,
        isSent: Bool
    ) -> ConversationMessage {
        return ConversationMessage(
            entityId: subscriptionId,
            entityType: .subscription,
            content: content,
            isSent: isSent
        )
    }
}

// MARK: - Hashable Conformance

extension ConversationMessage {
    static func == (lhs: ConversationMessage, rhs: ConversationMessage) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Sample Data

extension ConversationMessage {
    static var sampleMessages: [ConversationMessage] {
        let entityId = UUID()
        return [
            ConversationMessage(
                entityId: entityId,
                entityType: .contact,
                content: "Hey, can you send me the money for dinner?",
                isSent: false,
                timestamp: Date().addingTimeInterval(-3600)
            ),
            ConversationMessage(
                entityId: entityId,
                entityType: .contact,
                content: "Sure! How much was it again?",
                isSent: true,
                timestamp: Date().addingTimeInterval(-3500)
            ),
            ConversationMessage(
                entityId: entityId,
                entityType: .contact,
                content: "It was $45 total, so your share is $22.50",
                isSent: false,
                timestamp: Date().addingTimeInterval(-3400)
            ),
            ConversationMessage(
                entityId: entityId,
                entityType: .contact,
                content: "Got it, I'll mark it as a due now",
                isSent: true,
                timestamp: Date().addingTimeInterval(-3300)
            )
        ]
    }
}
