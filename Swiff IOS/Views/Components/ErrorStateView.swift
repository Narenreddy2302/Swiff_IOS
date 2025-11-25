//
//  ErrorStateView.swift
//  Swiff IOS
//
//  Created by Agent 11 on 11/21/25.
//  Reusable error state component with helpful messaging
//

import SwiftUI
import UIKit

struct ErrorStateView: View {
    let error: AppError
    let onRetry: (() -> Void)?
    let onDismiss: (() -> Void)?

    @State private var shakeAmount: CGFloat = 0
    @Environment(\.colorScheme) var colorScheme

    init(
        error: AppError,
        onRetry: (() -> Void)? = nil,
        onDismiss: (() -> Void)? = nil
    ) {
        self.error = error
        self.onRetry = onRetry
        self.onDismiss = onDismiss
    }

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Error Icon with Animation
            ZStack {
                Circle()
                    .fill(error.color.opacity(0.15))
                    .frame(width: 100, height: 100)

                Image(systemName: error.icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 50, height: 50)
                    .foregroundColor(error.color)
            }
            .modifier(ShakeEffect(animatableData: shakeAmount))
            .shadow(color: error.color.opacity(0.2), radius: 10, x: 0, y: 5)
            .accessibilityHidden(true)

            // Error Content
            VStack(spacing: 12) {
                Text(error.title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.primary)
                    .accessibilityAddTraits(.isHeader)

                Text(error.message)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .lineLimit(nil)
                    .padding(.horizontal, 32)
            }

            // Action Buttons
            VStack(spacing: 12) {
                if let onRetry = onRetry {
                    Button(action: {
                        HapticManager.shared.medium()
                        onRetry()
                    }) {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text("Try Again")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(error.color)
                        .cornerRadius(16)
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .accessibilityLabel("Retry operation")
                }

                if let onDismiss = onDismiss {
                    Button(action: {
                        HapticManager.shared.light()
                        onDismiss()
                    }) {
                        Text("Dismiss")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.vertical, 12)
                    }
                    .accessibilityLabel("Dismiss error")
                }
            }
            .padding(.horizontal, 32)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            colorScheme == .dark
                ? Color.black.opacity(0.95)
                : Color.wiseBackground
        )
        .onAppear {
            // Shake animation on appear
            if !AccessibilitySettings.isReduceMotionEnabled {
                withAnimation(.default) {
                    shakeAmount = 1
                }
            }

            // Play error haptic
            HapticManager.shared.error()

            // Log error
            ErrorLogger.shared.logError(error)

            // Announce for VoiceOver
            AccessibilityAnnouncer.shared.announce(
                "Error: \(error.title). \(error.message)",
                priority: .announcement
            )
        }
    }
}

// MARK: - App Error Model

enum AppError: Error {
    case networkError
    case persistenceError
    case dataNotFound
    case invalidInput
    case permissionDenied
    case operationFailed
    case importError
    case exportError
    case backupError
    case restoreError
    case subscriptionError
    case notificationError
    case unknown(String)

    var title: String {
        switch self {
        case .networkError:
            return "Connection Error"
        case .persistenceError:
            return "Save Failed"
        case .dataNotFound:
            return "Data Not Found"
        case .invalidInput:
            return "Invalid Input"
        case .permissionDenied:
            return "Permission Denied"
        case .operationFailed:
            return "Operation Failed"
        case .importError:
            return "Import Failed"
        case .exportError:
            return "Export Failed"
        case .backupError:
            return "Backup Failed"
        case .restoreError:
            return "Restore Failed"
        case .subscriptionError:
            return "Subscription Error"
        case .notificationError:
            return "Notification Error"
        case .unknown:
            return "Something Went Wrong"
        }
    }

    var message: String {
        switch self {
        case .networkError:
            return "Please check your internet connection and try again."
        case .persistenceError:
            return "We couldn't save your changes. Please try again."
        case .dataNotFound:
            return "The requested data could not be found."
        case .invalidInput:
            return "Please check your input and try again."
        case .permissionDenied:
            return "This feature requires permission to continue. Please enable it in Settings."
        case .operationFailed:
            return "The operation could not be completed. Please try again."
        case .importError:
            return "We couldn't import your data. Please check the file and try again."
        case .exportError:
            return "We couldn't export your data. Please try again."
        case .backupError:
            return "We couldn't create a backup. Please try again."
        case .restoreError:
            return "We couldn't restore from backup. Please try again."
        case .subscriptionError:
            return "There was a problem with your subscription. Please try again."
        case .notificationError:
            return "We couldn't schedule notifications. Please check your settings."
        case .unknown(let message):
            return message.isEmpty ? "An unexpected error occurred. Please try again." : message
        }
    }

    var icon: String {
        switch self {
        case .networkError:
            return "wifi.slash"
        case .persistenceError:
            return "externaldrive.badge.xmark"
        case .dataNotFound:
            return "doc.badge.ellipsis"
        case .invalidInput:
            return "exclamationmark.triangle"
        case .permissionDenied:
            return "hand.raised.fill"
        case .operationFailed:
            return "xmark.circle"
        case .importError:
            return "arrow.down.doc"
        case .exportError:
            return "arrow.up.doc"
        case .backupError:
            return "icloud.slash"
        case .restoreError:
            return "arrow.counterclockwise.circle"
        case .subscriptionError:
            return "creditcard.trianglebadge.exclamationmark"
        case .notificationError:
            return "bell.slash"
        case .unknown:
            return "exclamationmark.triangle"
        }
    }

    var color: Color {
        switch self {
        case .networkError:
            return .orange
        case .permissionDenied:
            return .yellow
        case .invalidInput:
            return .orange
        default:
            return .red
        }
    }
}

// MARK: - Error Alert Modifier

struct ErrorAlert: ViewModifier {
    @Binding var error: AppError?

    func body(content: Content) -> some View {
        content
            .alert(error?.title ?? "Error", isPresented: .constant(error != nil)) {
                Button("OK") {
                    HapticManager.shared.light()
                    error = nil
                }
            } message: {
                Text(error?.message ?? "")
            }
    }
}

extension View {
    func errorAlert(_ error: Binding<AppError?>) -> some View {
        self.modifier(ErrorAlert(error: error))
    }
}

#Preview {
    ErrorStateView(
        error: .persistenceError,
        onRetry: {},
        onDismiss: {}
    )
}

