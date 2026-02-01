//
//  SplitOptionsState.swift
//  Swiff IOS
//
//  State management for Step 2: People Selection
//  Manages payer (single select) and split members (multi select)
//

import Combine
import SwiftUI

@MainActor
class SplitOptionsState: ObservableObject {

    // MARK: - Published Properties

    /// Whether this transaction involves a split
    @Published var isSplit: Bool = false

    /// The person who paid — single selection
    @Published var paidByUserId: UUID?

    /// People included in the split
    @Published var participantIds: Set<UUID> = []

    /// Selected group (auto-adds all members)
    @Published var selectedGroup: Group?

    // MARK: - Search State

    @Published var paidBySearchText: String = ""
    @Published var splitWithSearchText: String = ""
    @Published var isPaidBySearchFocused: Bool = false
    @Published var isSplitWithSearchFocused: Bool = false

    // MARK: - Computed Properties

    /// Validation: payer must be set and at least 2 people in split
    var canProceed: Bool {
        paidByUserId != nil && participantIds.count >= 2
    }

    /// Current user's ID from UserProfileManager
    var currentUserId: UUID? {
        UserProfileManager.shared.profile.id
    }

    /// Ordered array of participant IDs — current user first, then alphabetically
    var orderedParticipantIds: [UUID] {
        var ordered: [UUID] = []
        if let myId = currentUserId, participantIds.contains(myId) {
            ordered.append(myId)
        }
        let others = participantIds
            .filter { $0 != currentUserId }
            .sorted()
        ordered.append(contentsOf: others)
        return ordered
    }

    /// Number of participants for display
    var participantCount: Int {
        participantIds.count
    }

    /// Validation message when not enough participants
    var validationMessage: String? {
        if participantIds.count == 1 {
            return "Add at least one more person to split with"
        }
        if participantIds.isEmpty {
            return "Select people to split with"
        }
        return nil
    }

    // MARK: - Actions

    func addParticipant(_ personId: UUID) {
        participantIds.insert(personId)

        // Auto-set payer to self if not yet set
        if paidByUserId == nil {
            if let myId = currentUserId, personId == myId {
                paidByUserId = myId
            } else {
                paidByUserId = personId
            }
        }
    }

    func removeParticipant(_ personId: UUID) {
        participantIds.remove(personId)

        // Reassign payer if the payer was removed
        if paidByUserId == personId {
            if let myId = currentUserId, participantIds.contains(myId) {
                paidByUserId = myId
            } else {
                paidByUserId = participantIds.first
            }
        }

        // Clear group selection if we manually changed members
        if selectedGroup != nil {
            selectedGroup = nil
        }
    }

    func toggleParticipant(_ personId: UUID) {
        if participantIds.contains(personId) {
            removeParticipant(personId)
        } else {
            addParticipant(personId)
        }
    }

    func selectPayer(_ personId: UUID) {
        paidByUserId = personId
        paidBySearchText = ""
        isPaidBySearchFocused = false
    }

    func selectGroup(_ group: Group) {
        selectedGroup = group
        for memberId in group.members {
            participantIds.insert(memberId)
        }
        splitWithSearchText = ""
    }

    // MARK: - Search Filtering

    func filteredPaidByContacts(from people: [Person]) -> [Person] {
        guard !paidBySearchText.isEmpty else { return people }
        let search = paidBySearchText.lowercased()
        return people.filter { $0.matchesSearch(search) }
    }

    func filteredSplitWithContacts(from people: [Person]) -> [Person] {
        guard !splitWithSearchText.isEmpty else { return people }
        let search = splitWithSearchText.lowercased()
        return people.filter { $0.matchesSearch(search) }
    }

    // MARK: - Helpers

    func isCurrentUser(_ personId: UUID) -> Bool {
        personId == currentUserId
    }

    // MARK: - Reset

    func reset() {
        isSplit = false
        paidByUserId = nil
        participantIds.removeAll()
        selectedGroup = nil
        paidBySearchText = ""
        splitWithSearchText = ""
        isPaidBySearchFocused = false
        isSplitWithSearchFocused = false
    }
}

// MARK: - Person Search Extension

extension Person {
    fileprivate func matchesSearch(_ query: String) -> Bool {
        name.lowercased().contains(query)
            || email.lowercased().contains(query)
            || phone.contains(query)
    }
}
