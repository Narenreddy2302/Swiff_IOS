//
//  DataRefreshModifiers.swift
//  Swiff IOS
//
//  View modifiers for real-time data synchronization
//

import SwiftUI
import Combine

// MARK: - Entity Type Enum

/// Entity types that can be observed for changes
enum EntityType {
    case person
    case group
    case subscription
    case transaction
    case splitBill
    case account
}

// MARK: - View Extensions

extension View {
    /// Force view refresh when any data changes in DataManager
    /// Use this for views that need to update when any data changes
    func refreshOnDataChange(_ dataManager: DataManager) -> some View {
        self.id(dataManager.dataRevision)
    }

    /// Observe specific entity changes and refresh the view when that entity is updated
    /// Use this for detail views that display a single entity
    func observeEntity(_ id: UUID, type: EntityType, dataManager: DataManager) -> some View {
        self.modifier(EntityObserverModifier(entityId: id, entityType: type, dataManager: dataManager))
    }

    /// Observe multiple entity types and refresh when any of them change
    /// Use this for views that display data from multiple entity types
    func observeEntities(types: [EntityType], dataManager: DataManager) -> some View {
        self.modifier(MultiEntityObserverModifier(entityTypes: types, dataManager: dataManager))
    }
}

// MARK: - Entity Observer Modifier

/// A view modifier that observes changes to a specific entity and refreshes the view
struct EntityObserverModifier: ViewModifier {
    let entityId: UUID
    let entityType: EntityType
    @ObservedObject var dataManager: DataManager
    @State private var refreshToken = UUID()

    func body(content: Content) -> some View {
        content
            .id(refreshToken)
            .onReceive(dataManager.dataChangeSubject) { change in
                if shouldRefresh(for: change) {
                    refreshToken = UUID()
                }
            }
    }

    private func shouldRefresh(for change: DataManager.DataChange) -> Bool {
        switch (entityType, change) {
        // Person changes
        case (.person, .personUpdated(let id)) where id == entityId:
            return true
        case (.person, .personDeleted(let id)) where id == entityId:
            return true

        // Group changes
        case (.group, .groupUpdated(let id)) where id == entityId:
            return true
        case (.group, .groupDeleted(let id)) where id == entityId:
            return true

        // Subscription changes
        case (.subscription, .subscriptionUpdated(let id)) where id == entityId:
            return true
        case (.subscription, .subscriptionDeleted(let id)) where id == entityId:
            return true

        // Transaction changes
        case (.transaction, .transactionUpdated(let id)) where id == entityId:
            return true
        case (.transaction, .transactionDeleted(let id)) where id == entityId:
            return true

        // Split Bill changes
        case (.splitBill, .splitBillUpdated(let id)) where id == entityId:
            return true
        case (.splitBill, .splitBillDeleted(let id)) where id == entityId:
            return true

        // Account changes
        case (.account, .accountUpdated(let id)) where id == entityId:
            return true
        case (.account, .accountDeleted(let id)) where id == entityId:
            return true

        // All data reloaded - always refresh
        case (_, .allDataReloaded):
            return true

        default:
            return false
        }
    }
}

// MARK: - Multi-Entity Observer Modifier

/// A view modifier that observes changes to multiple entity types
struct MultiEntityObserverModifier: ViewModifier {
    let entityTypes: [EntityType]
    @ObservedObject var dataManager: DataManager
    @State private var refreshToken = UUID()

    func body(content: Content) -> some View {
        content
            .id(refreshToken)
            .onReceive(dataManager.dataChangeSubject) { change in
                if shouldRefresh(for: change) {
                    refreshToken = UUID()
                }
            }
    }

    private func shouldRefresh(for change: DataManager.DataChange) -> Bool {
        // Always refresh on full data reload
        if case .allDataReloaded = change {
            return true
        }

        // Check if any of the observed entity types match the change
        for entityType in entityTypes {
            switch (entityType, change) {
            case (.person, .personAdded), (.person, .personUpdated), (.person, .personDeleted):
                return true
            case (.group, .groupAdded), (.group, .groupUpdated), (.group, .groupDeleted):
                return true
            case (.subscription, .subscriptionAdded), (.subscription, .subscriptionUpdated), (.subscription, .subscriptionDeleted):
                return true
            case (.transaction, .transactionAdded), (.transaction, .transactionUpdated), (.transaction, .transactionDeleted):
                return true
            case (.splitBill, .splitBillAdded), (.splitBill, .splitBillUpdated), (.splitBill, .splitBillDeleted):
                return true
            case (.account, .accountAdded), (.account, .accountUpdated), (.account, .accountDeleted):
                return true
            default:
                continue
            }
        }

        return false
    }
}

// MARK: - Related Entity Observer

/// A view modifier for observing related entity changes (e.g., a person's split bills)
struct RelatedEntityObserverModifier: ViewModifier {
    let primaryId: UUID
    let primaryType: EntityType
    let relatedTypes: [EntityType]
    @ObservedObject var dataManager: DataManager
    @State private var refreshToken = UUID()

    func body(content: Content) -> some View {
        content
            .id(refreshToken)
            .onReceive(dataManager.dataChangeSubject) { change in
                if shouldRefresh(for: change) {
                    refreshToken = UUID()
                }
            }
    }

    private func shouldRefresh(for change: DataManager.DataChange) -> Bool {
        // Always refresh on full data reload
        if case .allDataReloaded = change {
            return true
        }

        // Check primary entity
        switch (primaryType, change) {
        case (.person, .personUpdated(let id)) where id == primaryId:
            return true
        case (.group, .groupUpdated(let id)) where id == primaryId:
            return true
        case (.subscription, .subscriptionUpdated(let id)) where id == primaryId:
            return true
        case (.transaction, .transactionUpdated(let id)) where id == primaryId:
            return true
        case (.splitBill, .splitBillUpdated(let id)) where id == primaryId:
            return true
        case (.account, .accountUpdated(let id)) where id == primaryId:
            return true
        default:
            break
        }

        // Check related entity types (any change to related types triggers refresh)
        for relatedType in relatedTypes {
            switch (relatedType, change) {
            case (.splitBill, .splitBillAdded), (.splitBill, .splitBillUpdated), (.splitBill, .splitBillDeleted):
                return true
            case (.transaction, .transactionAdded), (.transaction, .transactionUpdated), (.transaction, .transactionDeleted):
                return true
            case (.person, .personAdded), (.person, .personUpdated), (.person, .personDeleted):
                return true
            case (.group, .groupAdded), (.group, .groupUpdated), (.group, .groupDeleted):
                return true
            case (.subscription, .subscriptionAdded), (.subscription, .subscriptionUpdated), (.subscription, .subscriptionDeleted):
                return true
            case (.account, .accountAdded), (.account, .accountUpdated), (.account, .accountDeleted):
                return true
            default:
                continue
            }
        }

        return false
    }
}

extension View {
    /// Observe a primary entity and its related entities
    /// Use this for detail views that show related data (e.g., PersonDetailView showing split bills)
    func observeEntityWithRelated(
        _ id: UUID,
        type: EntityType,
        relatedTypes: [EntityType],
        dataManager: DataManager
    ) -> some View {
        self.modifier(RelatedEntityObserverModifier(
            primaryId: id,
            primaryType: type,
            relatedTypes: relatedTypes,
            dataManager: dataManager
        ))
    }
}
