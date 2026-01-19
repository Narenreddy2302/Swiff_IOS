//
//  InlineSearchDropdown.swift
//  Swiff IOS
//
//  Reusable inline search dropdown component with smooth animations
//

import SwiftUI

// MARK: - Single Select Dropdown

struct InlineSearchDropdown<Item: Identifiable>: View {
    let title: String
    let placeholder: String
    @Binding var isExpanded: Bool
    let items: [Item]
    let selectedItem: Item?
    let itemLabel: (Item) -> String
    let itemSubtitle: ((Item) -> String?)?
    let itemIcon: (Item) -> AnyView
    let onSelect: (Item) -> Void

    @State private var searchText = ""
    @FocusState private var isSearchFocused: Bool

    init(
        title: String,
        placeholder: String,
        isExpanded: Binding<Bool>,
        items: [Item],
        selectedItem: Item?,
        itemLabel: @escaping (Item) -> String,
        itemSubtitle: ((Item) -> String?)? = nil,
        itemIcon: @escaping (Item) -> AnyView,
        onSelect: @escaping (Item) -> Void
    ) {
        self.title = title
        self.placeholder = placeholder
        self._isExpanded = isExpanded
        self.items = items
        self.selectedItem = selectedItem
        self.itemLabel = itemLabel
        self.itemSubtitle = itemSubtitle
        self.itemIcon = itemIcon
        self.onSelect = onSelect
    }

    private var filteredItems: [Item] {
        if searchText.isEmpty {
            return items
        }
        return items.filter { itemLabel($0).localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Label
            Text(title)
                .font(.spotifyLabelMedium)
                .foregroundColor(.wiseSecondaryText)

            // Main container
            VStack(spacing: 0) {
                // Collapsed/Header button
                Button(action: {
                    HapticManager.shared.light()
                    withAnimation(.smooth) {
                        isExpanded.toggle()
                        if isExpanded {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                isSearchFocused = true
                            }
                        } else {
                            searchText = ""
                            isSearchFocused = false
                        }
                    }
                }) {
                    HStack(spacing: 12) {
                        if let selected = selectedItem {
                            itemIcon(selected)
                            Text(itemLabel(selected))
                                .font(.spotifyBodyMedium)
                                .foregroundColor(.wisePrimaryText)
                        } else {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 16))
                                .foregroundColor(.wiseSecondaryText)
                            Text(placeholder)
                                .font(.spotifyBodyMedium)
                                .foregroundColor(.wiseSecondaryText)
                        }

                        Spacer()

                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.wiseSecondaryText)
                    }
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.wiseCardBackground)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isExpanded ? Color.wiseBrightGreen : Color.wiseBorder, lineWidth: 1)
                    )
                }
                .buttonStyle(PlainButtonStyle())

                // Expanded content
                if isExpanded {
                    expandedContent
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        }
    }

    private var expandedContent: some View {
        VStack(spacing: 0) {
            // Search input
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16))
                    .foregroundColor(.wiseSecondaryText)

                TextField("Search...", text: $searchText)
                    .font(.spotifyBodyMedium)
                    .focused($isSearchFocused)

                if !searchText.isEmpty {
                    Button(action: {
                        HapticManager.shared.light()
                        searchText = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.wiseSecondaryText)
                    }
                }
            }
            .padding(12)
            .background(Color.wiseCardBackground)

            Divider()
                .background(Color.wiseBorder)

            // Results list
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(filteredItems) { item in
                        Button(action: {
                            HapticManager.shared.light()
                            onSelect(item)
                            withAnimation(.smooth) {
                                isExpanded = false
                                searchText = ""
                                isSearchFocused = false
                            }
                        }) {
                            HStack(spacing: 12) {
                                itemIcon(item)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(itemLabel(item))
                                        .font(.spotifyBodyMedium)
                                        .foregroundColor(.wisePrimaryText)

                                    if let subtitle = itemSubtitle?(item), !subtitle.isEmpty {
                                        Text(subtitle)
                                            .font(.spotifyCaptionMedium)
                                            .foregroundColor(.wiseSecondaryText)
                                    }
                                }

                                Spacer()

                                if let selected = selectedItem, selected.id as AnyHashable == item.id as AnyHashable {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.wiseBrightGreen)
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(PlainButtonStyle())

                        if item.id as AnyHashable != filteredItems.last?.id as AnyHashable {
                            Divider()
                                .padding(.leading, 48)
                        }
                    }
                }
            }
            .frame(maxHeight: 200)
        }
        .background(Color.wiseCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.wiseBorder, lineWidth: 1)
        )
        .padding(.top, 4)
    }
}

// MARK: - Multi-Select Dropdown

struct MultiSelectSearchDropdown<Item: Identifiable>: View {
    let title: String
    let placeholder: String
    @Binding var isExpanded: Bool
    let items: [Item]
    let selectedIds: Set<UUID>
    let itemLabel: (Item) -> String
    let itemSubtitle: ((Item) -> String?)?
    let itemIcon: (Item) -> AnyView
    let getItemId: (Item) -> UUID
    let onToggle: (Item) -> Void
    let highlightedId: UUID?
    let highlightLabel: String?

    @State private var searchText = ""
    @FocusState private var isSearchFocused: Bool

    init(
        title: String,
        placeholder: String,
        isExpanded: Binding<Bool>,
        items: [Item],
        selectedIds: Set<UUID>,
        itemLabel: @escaping (Item) -> String,
        itemSubtitle: ((Item) -> String?)? = nil,
        itemIcon: @escaping (Item) -> AnyView,
        getItemId: @escaping (Item) -> UUID,
        onToggle: @escaping (Item) -> Void,
        highlightedId: UUID? = nil,
        highlightLabel: String? = nil
    ) {
        self.title = title
        self.placeholder = placeholder
        self._isExpanded = isExpanded
        self.items = items
        self.selectedIds = selectedIds
        self.itemLabel = itemLabel
        self.itemSubtitle = itemSubtitle
        self.itemIcon = itemIcon
        self.getItemId = getItemId
        self.onToggle = onToggle
        self.highlightedId = highlightedId
        self.highlightLabel = highlightLabel
    }

    private var filteredItems: [Item] {
        if searchText.isEmpty {
            return items
        }
        return items.filter { itemLabel($0).localizedCaseInsensitiveContains(searchText) }
    }

    private var selectionText: String {
        if selectedIds.isEmpty {
            return placeholder
        } else if selectedIds.count == 1, let first = items.first(where: { selectedIds.contains(getItemId($0)) }) {
            return itemLabel(first)
        } else {
            return "\(selectedIds.count) people selected"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Label with count
            HStack {
                Text(title)
                    .font(.spotifyLabelMedium)
                    .foregroundColor(.wiseSecondaryText)

                Spacer()

                if !selectedIds.isEmpty {
                    Text("\(selectedIds.count) selected")
                        .font(.spotifyCaptionMedium)
                        .foregroundColor(.wiseSecondaryText)
                }
            }

            // Main container
            VStack(spacing: 0) {
                // Collapsed/Header button
                Button(action: {
                    HapticManager.shared.light()
                    withAnimation(.smooth) {
                        isExpanded.toggle()
                        if isExpanded {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                isSearchFocused = true
                            }
                        } else {
                            searchText = ""
                            isSearchFocused = false
                        }
                    }
                }) {
                    HStack(spacing: 12) {
                        if selectedIds.isEmpty {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 16))
                                .foregroundColor(.wiseSecondaryText)
                        } else {
                            // Show avatars of selected people
                            selectedAvatarsStack
                        }

                        Text(selectionText)
                            .font(.spotifyBodyMedium)
                            .foregroundColor(selectedIds.isEmpty ? .wiseSecondaryText : .wisePrimaryText)

                        Spacer()

                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.wiseSecondaryText)
                    }
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.wiseCardBackground)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isExpanded ? Color.wiseBrightGreen : Color.wiseBorder, lineWidth: 1)
                    )
                }
                .buttonStyle(PlainButtonStyle())

                // Expanded content
                if isExpanded {
                    expandedContent
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        }
    }

    private var selectedAvatarsStack: some View {
        HStack(spacing: -8) {
            ForEach(Array(items.filter { selectedIds.contains(getItemId($0)) }.prefix(3)), id: \.id) { item in
                itemIcon(item)
                    .overlay(
                        Circle()
                            .stroke(Color.wiseCardBackground, lineWidth: 2)
                    )
            }

            if selectedIds.count > 3 {
                Text("+\(selectedIds.count - 3)")
                    .font(.spotifyCaptionMedium)
                    .foregroundColor(.wisePrimaryText)
                    .frame(width: 28, height: 28)
                    .background(Color.wiseBorder)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color.wiseCardBackground, lineWidth: 2)
                    )
            }
        }
    }

    private var expandedContent: some View {
        VStack(spacing: 0) {
            // Search input
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16))
                    .foregroundColor(.wiseSecondaryText)

                TextField("Search...", text: $searchText)
                    .font(.spotifyBodyMedium)
                    .focused($isSearchFocused)

                if !searchText.isEmpty {
                    Button(action: {
                        HapticManager.shared.light()
                        searchText = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.wiseSecondaryText)
                    }
                }
            }
            .padding(12)
            .background(Color.wiseCardBackground)

            Divider()
                .background(Color.wiseBorder)

            // Results list
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(filteredItems) { item in
                        let itemId = getItemId(item)
                        let isSelected = selectedIds.contains(itemId)
                        let isHighlighted = highlightedId == itemId

                        Button(action: {
                            HapticManager.shared.light()
                            onToggle(item)
                        }) {
                            HStack(spacing: 12) {
                                // Checkbox
                                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                    .font(.system(size: 22))
                                    .foregroundColor(isSelected ? .wiseBrightGreen : .wiseBorder)

                                itemIcon(item)

                                VStack(alignment: .leading, spacing: 2) {
                                    HStack(spacing: 6) {
                                        Text(itemLabel(item))
                                            .font(.spotifyBodyMedium)
                                            .foregroundColor(.wisePrimaryText)

                                        if isHighlighted, let label = highlightLabel {
                                            Text(label)
                                                .font(.spotifyCaptionMedium)
                                                .foregroundColor(.wiseBrightGreen)
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background(Color.wiseBrightGreen.opacity(0.15))
                                                .cornerRadius(4)
                                        }
                                    }

                                    if let subtitle = itemSubtitle?(item), !subtitle.isEmpty {
                                        Text(subtitle)
                                            .font(.spotifyCaptionMedium)
                                            .foregroundColor(.wiseSecondaryText)
                                    }
                                }

                                Spacer()
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(PlainButtonStyle())

                        if itemId != (filteredItems.last.map { getItemId($0) }) {
                            Divider()
                                .padding(.leading, 56)
                        }
                    }
                }
            }
            .frame(maxHeight: 250)
        }
        .background(Color.wiseCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.wiseBorder, lineWidth: 1)
        )
        .padding(.top, 4)
    }
}

// MARK: - Preview

#Preview("Single Select Dropdown") {
    struct PreviewWrapper: View {
        @State private var isExpanded = false
        @State private var selectedId: UUID? = nil

        struct MockPerson: Identifiable {
            let id = UUID()
            let name: String
            let email: String
        }

        let people = [
            MockPerson(name: "John Doe", email: "john@example.com"),
            MockPerson(name: "Jane Smith", email: "jane@example.com"),
            MockPerson(name: "Bob Wilson", email: "bob@example.com")
        ]

        var body: some View {
            VStack {
                InlineSearchDropdown(
                    title: "Paid by",
                    placeholder: "Select who paid",
                    isExpanded: $isExpanded,
                    items: people,
                    selectedItem: people.first { $0.id == selectedId },
                    itemLabel: { $0.name },
                    itemSubtitle: { $0.email },
                    itemIcon: { _ in
                        AnyView(
                            Circle()
                                .fill(Color.wiseBrightGreen)
                                .frame(width: 32, height: 32)
                        )
                    },
                    onSelect: { person in
                        selectedId = person.id
                    }
                )
                .padding()

                Spacer()
            }
            .background(Color.wiseBackground)
        }
    }

    return PreviewWrapper()
}
