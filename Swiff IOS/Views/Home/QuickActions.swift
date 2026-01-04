//
//  QuickActions.swift
//  Swiff IOS
//
//  Created by Swiff AI on 11/18/25.
//  Refactored from ContentView.swift
//

import SwiftUI

// MARK: - Quick Action FAB (Floating Action Button)
struct QuickActionFAB: View {
    @Binding var showingQuickActions: Bool
    @State private var isPressed = false

    var body: some View {
        Button(action: {
            HapticManager.shared.impact(.medium)
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                showingQuickActions = true
            }
        }) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Theme.Colors.brandSecondary, Theme.Colors.brandPrimary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 60, height: 60)
                    .shadow(color: Theme.Colors.brandPrimary.opacity(0.4), radius: 8, x: 0, y: 4)

                Image(systemName: "plus")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.white)
            }
        }
        .scaleEffect(isPressed ? 0.9 : 1.0)
        .opacity(isPressed ? 0.8 : 1.0)
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isPressed = false
                    }
                }
        )
    }
}

// MARK: - Quick Action Sheet
struct QuickActionSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataManager: DataManager
    @State private var showingAddTransaction = false
    @State private var showingAddSubscription = false
    @State private var showingAddPerson = false
    @State private var showingAddGroup = false

    private var preferredColorSchemeValue: ColorScheme? {
        switch UserSettings.shared.themeMode.lowercased() {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Quick Actions")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(Theme.Colors.textPrimary)

                Spacer()

                Button(action: {
                    HapticManager.shared.light()
                    dismiss()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 30))
                        .foregroundColor(Theme.Colors.textSecondary.opacity(0.6))
                }
                .buttonStyle(ScaleButtonStyle(scaleAmount: 0.96))
            }
            .padding(.horizontal, 24)
            .padding(.top, 28)
            .padding(.bottom, 20)

            Divider()
                .background(Theme.Colors.textSecondary.opacity(0.12))

            // Actions - NO container, edge-to-edge
            VStack(spacing: 0) {
                QuickActionRowV2(
                    icon: "plus.circle.fill",
                    title: "Add Transaction",
                    subtitle: "Record a new expense or income",
                    iconColor: Theme.Colors.brandPrimary,
                    showDivider: true
                ) {
                    showingAddTransaction = true
                }

                QuickActionRowV2(
                    icon: "creditcard.fill",
                    title: "Add Subscription",
                    subtitle: "Track a new subscription service",
                    iconColor: Theme.Colors.brandSecondary,
                    showDivider: true
                ) {
                    showingAddSubscription = true
                }

                QuickActionRowV2(
                    icon: "person.fill",
                    title: "Add Person",
                    subtitle: "Add a friend to track balances",
                    iconColor: Color(red: 1.0, green: 0.592, blue: 0.0),
                    showDivider: true
                ) {
                    showingAddPerson = true
                }

                QuickActionRowV2(
                    icon: "person.2.fill",
                    title: "Add Group",
                    subtitle: "Create a new group for shared expenses",
                    iconColor: Theme.Colors.brandSecondary,
                    showDivider: false
                ) {
                    showingAddGroup = true
                }
            }

            Spacer(minLength: 0)
        }
        .background(Theme.Colors.cardBackground)
        .presentationDetents([.height(420)])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(20)
        .presentationBackgroundInteraction(.disabled)
        .preferredColorScheme(preferredColorSchemeValue)
        .sheet(isPresented: $showingAddTransaction) {
            AddTransactionSheet(
                showingAddTransactionSheet: $showingAddTransaction,
                onTransactionAdded: { transaction in
                    do {
                        try dataManager.addTransaction(transaction)
                    } catch {
                        dataManager.error = error
                    }
                }
            )
        }
        .sheet(isPresented: $showingAddSubscription) {
            AddSubscriptionSheet(
                showingAddSubscriptionSheet: $showingAddSubscription,
                onSubscriptionAdded: { newSubscription in
                    do {
                        try dataManager.addSubscription(newSubscription)
                    } catch {
                        dataManager.error = error
                    }
                }
            )
        }
        .sheet(isPresented: $showingAddPerson) {
            AddPersonSheet(isPresented: $showingAddPerson)
                .environmentObject(dataManager)
                .presentationDetents([.height(320)])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingAddGroup) {
            AddGroupSheet(
                showingAddGroupSheet: $showingAddGroup, editingGroup: nil,
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

// MARK: - Category Picker Sheet
struct CategoryPickerSheet: View {
    @Binding var selectedCategory: TransactionCategory
    @Binding var isPresented: Bool

    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(
                    columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                    ], spacing: 12
                ) {
                    ForEach(TransactionCategory.allCases, id: \.self) { category in
                        Button(action: {
                            selectedCategory = category
                            isPresented = false
                        }) {
                            VStack(spacing: 12) {
                                Circle()
                                    .fill(category.color.opacity(0.1))
                                    .frame(width: 60, height: 60)
                                    .overlay(
                                        Image(systemName: category.icon)
                                            .font(.system(size: 24))
                                            .foregroundColor(category.color)
                                    )

                                Text(category.rawValue)
                                    .font(Theme.Fonts.labelMedium)
                                    .foregroundColor(Theme.Colors.textPrimary)
                                    .multilineTextAlignment(.center)
                                    .lineLimit(2)
                            }
                            .padding(16)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(
                                        selectedCategory == category
                                            ? category.color.opacity(0.1)
                                            : Theme.Colors.cardBackground
                                    )
                                    .stroke(
                                        selectedCategory == category
                                            ? category.color : Theme.Colors.border,
                                        lineWidth: selectedCategory == category ? 2 : 1)
                            )
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 20)
            }
            .navigationTitle("Select Category")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        isPresented = false
                    }
                    .font(Theme.Fonts.labelLarge)
                    .foregroundColor(Theme.Colors.brandPrimary)
                }
            }
        }
    }
}
