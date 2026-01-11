//
//  Step2PayerView.swift
//  Swiff IOS
//
//  Step 2: Select who paid the bill
//

import SwiftUI

struct Step2PayerView: View {
    @Binding var selectedPayer: Person?
    @EnvironmentObject var dataManager: DataManager

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                Text("Who paid the bill?")
                    .font(.spotifyHeadingMedium)
                    .foregroundColor(.wisePrimaryText)
                    .padding(.horizontal, 20)
                    .padding(.top, 20)

                Text("Select the person who covered the expense")
                    .font(.spotifyBodyMedium)
                    .foregroundColor(.wiseSecondaryText)
                    .padding(.horizontal, 20)

                // People list
                VStack(spacing: 12) {
                    ForEach(dataManager.people) { person in
                        Button(action: {
                            HapticManager.shared.light()
                            selectedPayer = person
                        }) {
                            HStack(spacing: 16) {
                                // Avatar
                                AvatarView(
                                    avatarType: person.avatarType,
                                    size: .large,
                                    style: .solid
                                )
                                .frame(width: 48, height: 48)

                                // Name and email
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(person.name)
                                        .font(.spotifyBodyLarge)
                                        .foregroundColor(.wisePrimaryText)

                                    if !person.email.isEmpty {
                                        Text(person.email)
                                            .font(.spotifyCaptionMedium)
                                            .foregroundColor(.wiseSecondaryText)
                                    }
                                }

                                Spacer()

                                // Selection indicator
                                if selectedPayer?.id == person.id {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 24))
                                        .foregroundColor(.wiseBrightGreen)
                                } else {
                                    Image(systemName: "circle")
                                        .font(.system(size: 24))
                                        .foregroundColor(.wiseBorder.opacity(0.5))
                                }
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(selectedPayer?.id == person.id ? Color.wiseBrightGreen.opacity(0.1) : Color.wiseCardBackground)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(
                                        selectedPayer?.id == person.id ? Color.wiseBrightGreen : Color.wiseBorder.opacity(0.3),
                                        lineWidth: selectedPayer?.id == person.id ? 2 : 1
                                    )
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, 20)

                if dataManager.people.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "person.2.slash")
                            .font(.system(size: 48))
                            .foregroundColor(.wiseSecondaryText)

                        Text("No people found")
                            .font(.spotifyHeadingMedium)
                            .foregroundColor(.wisePrimaryText)

                        Text("Add people in the People tab first")
                            .font(.spotifyBodyMedium)
                            .foregroundColor(.wiseSecondaryText)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                }

                Spacer(minLength: 20)
            }
        }
        .background(Color.wiseBackground)
    }
}

