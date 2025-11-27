//
//  NotificationHistoryView.swift
//  Swiff IOS
//
//  Created by Agent 7 on 11/21/25.
//  View for notification history and tracking
//

import SwiftUI
import Combine

// MARK: - AGENT 7: Notification History View

struct NotificationHistoryView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var historyManager = NotificationHistoryManager.shared
    @State private var selectedFilter: NotificationHistoryFilter = .all
    @State private var showingClearAlert = false

    var filteredHistory: [NotificationHistoryEntry] {
        historyManager.history.filter { entry in
            selectedFilter.matches(entry.type)
        }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Filter Tabs
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(NotificationHistoryFilter.allCases, id: \.self) { filter in
                            FilterButton(
                                filter: filter,
                                isSelected: selectedFilter == filter,
                                count: countForFilter(filter)
                            ) {
                                selectedFilter = filter
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
                .background(Color.wiseBackground)

                if filteredHistory.isEmpty {
                    EmptyHistoryView(filter: selectedFilter)
                } else {
                    List {
                        ForEach(filteredHistory) { entry in
                            NotificationHistoryRow(entry: entry)
                        }
                        .onDelete(perform: deleteEntries)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Notification History")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.spotifyBodyMedium)
                    .foregroundColor(.wiseForestGreen)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    if !historyManager.history.isEmpty {
                        Button(action: {
                            showingClearAlert = true
                        }) {
                            Image(systemName: "trash")
                                .foregroundColor(.wiseError)
                        }
                    }
                }
            }
        }
        .alert("Clear History?", isPresented: $showingClearAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Clear All", role: .destructive) {
                historyManager.clearHistory()
            }
        } message: {
            Text("This will delete all notification history records. This action cannot be undone.")
        }
        .onAppear {
            historyManager.loadHistory()
        }
    }

    private func countForFilter(_ filter: NotificationHistoryFilter) -> Int {
        historyManager.history.filter { filter.matches($0.type) }.count
    }

    private func deleteEntries(at offsets: IndexSet) {
        let entriesToDelete = offsets.map { filteredHistory[$0] }
        for entry in entriesToDelete {
            historyManager.removeEntry(entry.id)
        }
    }
}

// MARK: - Filter Button

struct FilterButton: View {
    let filter: NotificationHistoryFilter
    let isSelected: Bool
    let count: Int
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: filter.icon)
                    .font(.system(size: 14))
                Text(filter.rawValue)
                    .font(.spotifyLabelMedium)
                if count > 0 {
                    Text("\(count)")
                        .font(.spotifyCaptionSmall)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(isSelected ? Color.white.opacity(0.3) : Color.wiseBorder.opacity(0.5))
                        )
                }
            }
            .foregroundColor(isSelected ? .white : .wiseSecondaryText)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isSelected ? Color.wiseForestGreen : Color.wiseCardBackground)
                    .shadow(color: Color.wiseShadowColor, radius: 4, x: 0, y: 2)
            )
        }
    }
}

// MARK: - Notification History Row

struct NotificationHistoryRow: View {
    let entry: NotificationHistoryEntry

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Icon
            Circle()
                .fill((Color(hex: entry.type.color) ?? Color.wiseMidGray).opacity(0.2))
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: entry.type.icon)
                        .font(.system(size: 18))
                        .foregroundColor(Color(hex: entry.type.color) ?? .wiseMidGray)
                )

            VStack(alignment: .leading, spacing: 6) {
                // Title
                Text(entry.title)
                    .font(.spotifyBodyMedium)
                    .foregroundColor(.wisePrimaryText)

                // Body
                Text(entry.body)
                    .font(.spotifyBodySmall)
                    .foregroundColor(.wiseSecondaryText)
                    .lineLimit(2)

                // Metadata
                HStack(spacing: 12) {
                    // Date
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.system(size: 10))
                        Text(entry.sentDate.formatted(date: .abbreviated, time: .shortened))
                            .font(.spotifyCaptionSmall)
                    }

                    // Type
                    HStack(spacing: 4) {
                        Image(systemName: "tag")
                            .font(.system(size: 10))
                        Text(entry.type.rawValue)
                            .font(.spotifyCaptionSmall)
                    }

                    // Opened status
                    if entry.wasOpened {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.wiseForestGreen)
                            Text("Opened")
                                .font(.spotifyCaptionSmall)
                                .foregroundColor(.wiseForestGreen)
                        }
                    }
                }
                .foregroundColor(.wiseSecondaryText)

                // Action taken
                if entry.action != .none {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.system(size: 10))
                        Text("Action: \(entry.action.rawValue)")
                            .font(.spotifyCaptionSmall)
                    }
                    .foregroundColor(.wiseBlue)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.wiseBlue.opacity(0.1))
                    )
                }
            }

            Spacer()
        }
        .padding(.vertical, 12)
    }
}

// MARK: - Empty History View

struct EmptyHistoryView: View {
    let filter: NotificationHistoryFilter

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "bell.slash.fill")
                .font(.system(size: 60))
                .foregroundColor(.wiseSecondaryText.opacity(0.5))

            VStack(spacing: 8) {
                Text("No Notifications")
                    .font(.spotifyHeadingLarge)
                    .foregroundColor(.wisePrimaryText)

                if filter == .all {
                    Text("You haven't received any notifications yet")
                        .font(.spotifyBodyMedium)
                        .foregroundColor(.wiseSecondaryText)
                        .multilineTextAlignment(.center)
                } else {
                    Text("No \(filter.rawValue.lowercased()) notifications found")
                        .font(.spotifyBodyMedium)
                        .foregroundColor(.wiseSecondaryText)
                        .multilineTextAlignment(.center)
                }
            }

            Spacer()
        }
        .padding(.horizontal, 40)
    }
}

// MARK: - Notification History Manager

@MainActor
class NotificationHistoryManager: ObservableObject {
    static let shared = NotificationHistoryManager()

    @Published var history: [NotificationHistoryEntry] = []

    private let userDefaultsKey = "notification_history"

    private init() {
        loadHistory()
    }

    func loadHistory() {
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let decoded = try? JSONDecoder().decode([NotificationHistoryEntry].self, from: data) {
            history = decoded.sorted { $0.sentDate > $1.sentDate }
        }
    }

    func saveHistory() {
        if let encoded = try? JSONEncoder().encode(history) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
    }

    func addEntry(_ entry: NotificationHistoryEntry) {
        history.insert(entry, at: 0)
        saveHistory()
    }

    func removeEntry(_ id: UUID) {
        history.removeAll { $0.id == id }
        saveHistory()
    }

    func clearHistory() {
        history.removeAll()
        saveHistory()
        ToastManager.shared.showSuccess("History cleared")
    }

    func markAsOpened(_ id: UUID) {
        if let index = history.firstIndex(where: { $0.id == id }) {
            history[index].markAsOpened()
            saveHistory()
        }
    }

    func recordAction(_ id: UUID, action: NotificationAction) {
        if let index = history.firstIndex(where: { $0.id == id }) {
            history[index].recordAction(action)
            saveHistory()
        }
    }

    // Statistics
    func getStatistics() -> NotificationStatistics {
        var stats = NotificationStatistics()
        stats.totalSent = history.count
        stats.totalOpened = history.filter { $0.wasOpened }.count
        stats.renewalsSent = history.filter { $0.type == .renewal }.count
        stats.trialsSent = history.filter { $0.type == .trial }.count
        stats.priceChangesSent = history.filter { $0.type == .priceChange }.count
        stats.unusedAlertsSent = history.filter { $0.type == .unused }.count
        stats.paymentsSent = history.filter { $0.type == .payment }.count
        return stats
    }
}

#Preview {
    NotificationHistoryView()
}
