//
//  DataManagerModifiers.swift
//  Swiff IOS
//
//  Created by Naren Reddy on 11/18/25.
//  View modifiers for displaying DataManager errors and progress
//

import SwiftUI

// MARK: - Error Alert Modifier

/// Displays an alert when DataManager encounters an error
struct DataManagerErrorAlert: ViewModifier {
    @EnvironmentObject var dataManager: DataManager
    @State private var showingError = false

    func body(content: Content) -> some View {
        content
            .onChange(of: dataManager.error?.localizedDescription) { oldValue, newValue in
                showingError = newValue != nil
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK") {
                    // Clear error after user acknowledges
                    dataManager.error = nil
                }
                Button("Retry Last Operation") {
                    // User can implement retry logic if needed
                    dataManager.error = nil
                }
            } message: {
                if let error = dataManager.error {
                    Text(error.localizedDescription)
                }
            }
    }
}

// MARK: - Progress Overlay Modifier

/// Displays a progress overlay when long-running operations are in progress
struct DataManagerProgressOverlay: ViewModifier {
    @EnvironmentObject var dataManager: DataManager

    func body(content: Content) -> some View {
        ZStack {
            content

            // Progress overlay
            if dataManager.isPerformingOperation {
                Color.wiseOverlayColor
                    .ignoresSafeArea()

                VStack(spacing: 20) {
                    if let progress = dataManager.operationProgress {
                        // Determinate progress
                        ProgressView(value: progress) {
                            Text(dataManager.operationMessage ?? "Processing...")
                                .font(.spotifyLabelLarge)
                                .foregroundColor(.white)
                        }
                        .progressViewStyle(.linear)
                        .tint(.wiseBrightGreen)
                        .frame(maxWidth: 250)

                        Text("\(Int(progress * 100))%")
                            .font(.spotifyBodyMedium)
                            .foregroundColor(.white.opacity(0.8))
                    } else {
                        // Indeterminate progress
                        ProgressView {
                            Text(dataManager.operationMessage ?? "Loading...")
                                .font(.spotifyLabelLarge)
                                .foregroundColor(.white)
                        }
                        .tint(.wiseBrightGreen)
                    }
                }
                .padding(40)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.wisePrimaryText)
                        .shadow(radius: 20)
                )
                .transition(.scale.combined(with: .opacity))
                .animation(.spring(), value: dataManager.isPerformingOperation)
            }
        }
    }
}

// MARK: - Combined Modifier

/// Combines error alerts and progress overlay
struct DataManagerOverlays: ViewModifier {
    func body(content: Content) -> some View {
        content
            .modifier(DataManagerErrorAlert())
            .modifier(DataManagerProgressOverlay())
    }
}

// MARK: - View Extensions

extension View {
    /// Adds error handling and progress display for DataManager operations
    func dataManagerOverlays() -> some View {
        modifier(DataManagerOverlays())
    }

    /// Adds only error alert for DataManager
    func dataManagerErrorAlert() -> some View {
        modifier(DataManagerErrorAlert())
    }

    /// Adds only progress overlay for DataManager
    func dataManagerProgressOverlay() -> some View {
        modifier(DataManagerProgressOverlay())
    }
}
