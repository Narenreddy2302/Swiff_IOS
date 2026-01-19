//
//  SplitOptionsState.swift
//  Swiff IOS
//
//  Created by Swiff AI on 11/18/25.
//  State management for Step 2: Split Options (People & Payer)
//

import Combine
import SwiftUI

@MainActor
class SplitOptionsState: ObservableObject {

    // MARK: - Published Properties

    @Published var isSplit: Bool = false
    @Published var paidByUserId: UUID?
    @Published var participantIds: Set<UUID> = []
    @Published var selectedGroup: Group?

    // MARK: - UI State

    @Published var paidBySearchText: String = ""
    @Published var splitWithSearchText: String = ""
    @Published var isPaidBySearchFocused: Bool = false
    @Published var isSplitWithSearchFocused: Bool = false

    // MARK: - Computed Properties

    var canProceed: Bool {
        if !isSplit { return true }
        return paidByUserId != nil && participantIds.count >= 2
    }

    /// Current user's ID
    var currentUserId: UUID? {
        UserProfileManager.shared.profile.id
    }

    // MARK: - Actions

    func addParticipant(_ personId: UUID) {
        participantIds.insert(personId)

        // Default payer to self if not set, else first added person
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

        // Handle payer removal
        if paidByUserId == personId {
            // Prefer current user
            if let myId = currentUserId, participantIds.contains(myId) {
                paidByUserId = myId
            } else {
                paidByUserId = participantIds.first
            }
        }

        if selectedGroup != nil {
            selectedGroup = nil
        }
    }

    func selectPayer(_ personId: UUID) {
        paidByUserId = personId
        participantIds.insert(personId)
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
        return people.filter { $0.matches(search) }
    }

    func filteredSplitWithContacts(from people: [Person]) -> [Person] {
        guard !splitWithSearchText.isEmpty else { return people }
        let search = splitWithSearchText.lowercased()
        return people.filter { $0.matches(search) }
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

// MARK: - Helper Extension

extension Person {
    fileprivate func matches(_ query: String) -> Bool {
        name.lowercased().contains(query) || email.lowercased().contains(query)
            || phone.contains(query)
    }
}
