//
//  Persistence.swift
//  Swiff IOS
//
//  Created by Naren Reddy on 11/11/25.
//  Updated on 11/18/25 for SwiftData support
//

import SwiftUI
import SwiftData

/// SwiftData Preview Container for SwiftUI Previews
struct SwiftDataPreview {
    @MainActor
    static let previewContainer: ModelContainer = {
        do {
            let schema = Schema([
                PersonModel.self,
                GroupModel.self,
                GroupExpenseModel.self,
                SubscriptionModel.self,
                SharedSubscriptionModel.self,
                TransactionModel.self
            ])

            let configuration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: true // In-memory for previews
            )

            let container = try ModelContainer(for: schema, configurations: [configuration])

            // Add sample data for previews
            let context = container.mainContext

            // Sample Person
            let samplePerson = PersonModel(
                name: "John Doe",
                email: "john@example.com",
                phone: "+1234567890",
                avatarType: .emoji("👨")
            )
            context.insert(samplePerson)

            // Sample Subscription
            let sampleSubscription = SubscriptionModel(
                name: "Netflix",
                description: "Streaming service",
                price: 15.99,
                billingCycle: .monthly,
                category: .entertainment,
                icon: "tv.fill",
                color: "#E50914"
            )
            context.insert(sampleSubscription)

            try context.save()

            return container
        } catch {
            fatalError("Failed to create preview container: \(error)")
        }
    }()
}

// MARK: - Legacy Core Data Support (Deprecated)
// Note: This app now uses SwiftData. Core Data support is deprecated.
// Keeping this for reference during migration, can be removed later.

/*
import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        // Legacy Core Data implementation
        // This is no longer used. SwiftData is now the persistence layer.
    }
}
*/
