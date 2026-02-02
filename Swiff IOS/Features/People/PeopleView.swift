import Contacts
import ContactsUI
import SwiftUI

struct PeopleView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var selectedTab: PeopleTab = .people
    @State private var showSearchBar = false
    @State private var searchText = ""
    @State private var showingAddPersonSheet = false

    enum PeopleTab: String, CaseIterable {
        case people = "People"
        case groups = "Groups"
        case contacts = "Contacts"

        var icon: String {
            switch self {
            case .people: return "person.2.fill"
            case .contacts: return "person.crop.circle.fill"
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
                            showSearchBar: $showSearchBar,
                            searchText: $searchText,
                            showingAddPersonSheet: $showingAddPersonSheet
                        )
                        .padding(.top, 10)  // Standard top padding after safe area

                        // No category filter section for People (Groups don't need filters like subscription categories)
                    }
                    .background(Color.wiseBackground)
                    .zIndex(1)  // Keep header on top

                    // Content based on selected tab (Contacts now shown in popup sheet)
                    switch selectedTab {
                    case .people:
                        PeopleListView(people: dataManager.people, searchText: $searchText)
                            .transition(
                                .asymmetric(
                                    insertion: .move(edge: .trailing).combined(with: .opacity),
                                    removal: .move(edge: .leading).combined(with: .opacity)
                                ))
                    case .groups:
                        GroupsListView(
                            groups: dataManager.groups, people: dataManager.people,
                            searchText: $searchText
                        )
                        .transition(
                            .asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            ))
                    case .contacts:
                        // Contacts are now shown in popup sheet, but keep case for enum completeness
                        EmptyView()
                    }
                }
            }
            .navigationBarHidden(true)
        }

        .sheet(isPresented: $showingAddPersonSheet) {
            AddPersonFromContactsSheet(isPresented: $showingAddPersonSheet)
                .environmentObject(dataManager)
        }
        .onAppear {
            // Pre-load contacts in background so they display instantly when "+" is tapped
            Task {
                await ContactSyncManager.shared.loadContactsWithCache()
            }
        }
    }
}

// MARK: - People Header Section
struct PeopleHeaderSection: View {
    @Binding var selectedTab: PeopleView.PeopleTab
    @Binding var showSearchBar: Bool
    @Binding var searchText: String
    @Binding var showingAddPersonSheet: Bool

    private var searchPlaceholder: String {
        switch selectedTab {
        case .people: return "Search people..."
        case .contacts: return "Search contacts..."
        case .groups: return "Search groups..."
        }
    }

    var body: some View {
        VStack(spacing: 16) {
            // Top Header (matching design system)
            HStack {
                Text("People")
                    .font(Theme.Fonts.displayLarge)
                    .foregroundColor(Theme.Colors.textPrimary)

                Spacer()

                // Search and Contacts Buttons
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
                            .foregroundColor(showSearchBar ? Theme.Colors.brandPrimary : Theme.Colors.textPrimary)
                    }

                    // Add Person Button (WhatsApp Style)
                    HeaderActionButton(icon: "plus.circle.fill", color: Theme.Colors.brandPrimary) {
                        HapticManager.shared.impact(.medium)
                        showingAddPersonSheet = true
                    }
                }
            }
            .padding(.horizontal, 16)

            // Tabs (Pill Buttons) - People and Groups only, Contacts moved to header icon
            HStack(spacing: 12) {
                ForEach([PeopleView.PeopleTab.people, PeopleView.PeopleTab.groups], id: \.self) {
                    tab in
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
                        searchPlaceholder,
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


