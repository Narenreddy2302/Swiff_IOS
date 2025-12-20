//
//  MemojiPickerView.swift
//  Swiff IOS
//
//  Created by Naren Reddy on 12/18/25.
//  SwiftUI wrapper for Memoji picker with instructions and preview
//

import SwiftUI

/// A view that allows users to pick their Memoji/stickers from the iOS keyboard
/// Only available on iOS 18.0+
@available(iOS 18.0, *)
struct MemojiPickerView: View {
    @Binding var selectedImage: UIImage?
    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Instructions
            VStack(spacing: 8) {
                Image(systemName: "face.smiling")
                    .font(.system(size: 48))
                    .foregroundColor(.wiseForestGreen)

                Text("Select Your Memoji")
                    .font(.spotifyHeadingSmall)
                    .foregroundColor(.wisePrimaryText)

                Text("Tap below to open the keyboard, then select your Memoji or sticker")
                    .font(.spotifyBodySmall)
                    .foregroundColor(.wiseSecondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }

            // Memoji picker text field
            VStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.wiseBorder.opacity(0.3))
                        .frame(height: 80)

                    if selectedImage != nil {
                        // Show selected Memoji
                        Image(uiImage: selectedImage!)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 60, height: 60)
                            .clipShape(Circle())
                    } else {
                        // Placeholder with tap instruction
                        VStack(spacing: 4) {
                            Image(systemName: "hand.tap")
                                .font(.system(size: 24))
                                .foregroundColor(.wiseSecondaryText)

                            Text("Tap to Select")
                                .font(.spotifyBodySmall)
                                .foregroundColor(.wiseSecondaryText)
                        }
                    }

                    // Invisible text field overlay
                    MemojiPickerTextField(pickedImage: $selectedImage)
                        .frame(height: 80)
                        .opacity(0.01) // Nearly invisible but still tappable
                        .focused($isTextFieldFocused)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    isTextFieldFocused = true
                }

                // Clear button when image is selected
                if selectedImage != nil {
                    Button(action: {
                        selectedImage = nil
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 14))
                            Text("Clear Selection")
                                .font(.spotifyBodySmall)
                        }
                        .foregroundColor(.wiseSecondaryText)
                    }
                }
            }
            .padding(.horizontal, 16)

            // Help text
            Text("Switch to the Emoji keyboard and select the Memoji/Stickers tab")
                .font(.spotifyCaptionSmall)
                .foregroundColor(.wiseTertiaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Spacer()
        }
    }
}
