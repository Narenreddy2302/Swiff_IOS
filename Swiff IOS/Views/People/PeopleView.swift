import Contacts
import ContactsUI
import SwiftUI

struct PeopleView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var selectedTab: PeopleTab = .people
    @State private var showingAddPersonSheet = false
    @State private var showingAddGroupSheet = false
    @State private var showSearchBar = false
    @State private var searchText = ""

    enum PeopleTab: String, CaseIterable {
        case people = "People"
        case groups = "Groups"

        var icon: String {
            switch self {
            case .people: return "person.2.fill"
            case .groups: return "person.3.fill"
            }
        }
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                // Background
                Color.wiseBackground
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Fixed Header Section
                    VStack(spacing: 0) {
                        // Header
                        PeopleHeaderSection(
                            selectedTab: $selectedTab,
                            showingAddPersonSheet: $showingAddPersonSheet,
                            showingAddGroupSheet: $showingAddGroupSheet,
                            showSearchBar: $showSearchBar,
                            searchText: $searchText
                        )
                        .padding(.top, 10)  // Standard top padding after safe area

                        // Quick Stats Cards
                        PeopleQuickStatsView(people: dataManager.people)

                        // No category filter section for People (Groups don't need filters like subscription categories)
                    }
                    .background(Color.wiseBackground)
                    .zIndex(1)  // Keep header on top

                    // Content based on selected tab
                    if selectedTab == .people {
                        PeopleListView(people: dataManager.people, searchText: $searchText)
                            .transition(
                                .asymmetric(
                                    insertion: .move(edge: .trailing).combined(with: .opacity),
                                    removal: .move(edge: .leading).combined(with: .opacity)
                                ))
                    } else {
                        GroupsListView(
                            groups: dataManager.groups, people: dataManager.people,
                            searchText: $searchText
                        )
                        .transition(
                            .asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            ))
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingAddPersonSheet) {
            AddPersonSheet(isPresented: $showingAddPersonSheet)
                .environmentObject(dataManager)
                .presentationDetents([.height(320)])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingAddGroupSheet) {
            AddGroupSheet(
                showingAddGroupSheet: $showingAddGroupSheet,
                editingGroup: nil as Group?,
                people: dataManager.people,
                onGroupAdded: { group in
                    do {
                        try dataManager.addGroup(group)
                    } catch {
                        dataManager.error = error
                    }
                }
            )
            .environmentObject(dataManager)
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
    }
}

// MARK: - People Header Section
struct PeopleHeaderSection: View {
    @Binding var selectedTab: PeopleView.PeopleTab
    @Binding var showingAddPersonSheet: Bool
    @Binding var showingAddGroupSheet: Bool
    @Binding var showSearchBar: Bool
    @Binding var searchText: String

    var body: some View {
        VStack(spacing: 16) {
            // Top Header (matching design system)
            HStack {
                Text("People")
                    .font(Theme.Fonts.displayLarge)
                    .foregroundColor(Theme.Colors.textPrimary)

                Spacer()

                // Search and Add Buttons
                HStack(spacing: 16) {
                    Button(action: {
                        HapticManager.shared.light()
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showSearchBar.toggle()
                            if !showSearchBar {
                                searchText = ""
                            }
                        }
                    }) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 20))
                            .foregroundColor(showSearchBar ? .wiseBrightGreen : .wisePrimaryText)
                    }

                    HeaderActionButton(icon: "plus.circle.fill", color: .wiseForestGreen) {
                        HapticManager.shared.light()
                        if selectedTab == .people {
                            showingAddPersonSheet = true
                        } else {
                            showingAddGroupSheet = true
                        }
                    }
                }
            }
            .padding(.horizontal, 16)

            // Tabs (Pill Buttons)
            HStack(spacing: 12) {
                ForEach(PeopleView.PeopleTab.allCases, id: \.self) { tab in
                    Button(action: {
                        HapticManager.shared.selection()
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedTab = tab
                            searchText = ""  // Clear search when switching tabs
                        }
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 14))
                            Text(tab.rawValue)
                        }
                        .font(.spotifyLabelMedium)
                        .foregroundColor(
                            selectedTab == tab
                                ? Theme.Colors.textOnPrimary : Theme.Colors.textPrimary
                        )
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity)
                        .background(
                            Capsule()
                                .fill(
                                    selectedTab == tab
                                        ? Theme.Colors.brandPrimary : Theme.Colors.border)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 16)

            // Search Bar (matching Feed design)
            if showSearchBar {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.wiseSecondaryText)
                        .font(.system(size: 16))

                    TextField(
                        selectedTab == .people ? "Search people..." : "Search groups...",
                        text: $searchText
                    )
                    .font(.spotifyBodyMedium)
                    .foregroundColor(.wisePrimaryText)

                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.wiseSecondaryText)
                                .font(.system(size: 16))
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Theme.Colors.secondaryBackground)
                )
                .padding(.horizontal, 16)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.bottom, 8)  // Match Subscriptions header bottom padding
    }
}
