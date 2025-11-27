//
//  ToastManager.swift
//  Swiff IOS
//
//  Created by Naren Reddy on 11/20/25.
//  Toast notification manager for displaying messages and errors
//

import Combine
import SwiftUI

// MARK: - Toast Model

struct Toast: Identifiable, Equatable {
    let id = UUID()
    let message: String
    let type: ToastType
    let duration: TimeInterval

    enum ToastType {
        case success
        case error
        case warning
        case info

        var icon: String {
            switch self {
            case .success: return "checkmark.circle.fill"
            case .error: return "xmark.circle.fill"
            case .warning: return "exclamationmark.triangle.fill"
            case .info: return "info.circle.fill"
            }
        }

        var color: Color {
            switch self {
            case .success: return .wiseSuccess
            case .error: return .wiseError
            case .warning: return .wiseWarning
            case .info: return .wiseInfo
            }
        }
    }

    init(message: String, type: ToastType, duration: TimeInterval = 3.0) {
        self.message = message
        self.type = type
        self.duration = duration
    }
}

// MARK: - Toast Manager

@MainActor
class ToastManager: ObservableObject {
    static let shared = ToastManager()

    @Published var currentToast: Toast?

    // MARK: - Memory Leak Fix (Phase 2.2)
    // Store Task reference to prevent orphaned tasks
    private var dismissTask: Task<Void, Never>?

    private init() {}

    deinit {
        // Clean up any pending tasks
        dismissTask?.cancel()
        dismissTask = nil
    }

    func show(_ message: String, type: Toast.ToastType = .info, duration: TimeInterval = 3.0) {
        // Cancel any existing toast and its dismiss task
        dismissTask?.cancel()
        dismissTask = nil
        currentToast = nil

        // Show new toast
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            currentToast = Toast(message: message, type: type, duration: duration)
        }

        // Capture the toast ID for comparison
        let toastId = currentToast?.id

        // Auto-dismiss after duration - store Task reference
        dismissTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))

            // Check if task was cancelled
            guard !Task.isCancelled else { return }

            // Only dismiss if this is still the current toast
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                if currentToast?.id == toastId {
                    currentToast = nil
                }
            }

            // Clear task reference
            dismissTask = nil
        }
    }

    func showSuccess(_ message: String, duration: TimeInterval = 3.0) {
        show(message, type: .success, duration: duration)
    }

    func showError(_ message: String, duration: TimeInterval = 4.0) {
        show(message, type: .error, duration: duration)
    }

    func showWarning(_ message: String, duration: TimeInterval = 3.5) {
        show(message, type: .warning, duration: duration)
    }

    func showInfo(_ message: String, duration: TimeInterval = 3.0) {
        show(message, type: .info, duration: duration)
    }

    func showError(_ error: Error, duration: TimeInterval = 4.0) {
        show(error.localizedDescription, type: .error, duration: duration)
    }

    func dismiss() {
        // Cancel pending dismiss task
        dismissTask?.cancel()
        dismissTask = nil

        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            currentToast = nil
        }
    }

    /// Cancel any pending dismiss tasks (for cleanup)
    func cleanup() {
        dismissTask?.cancel()
        dismissTask = nil
        currentToast = nil
    }
}

// MARK: - Toast View

struct ToastView: View {
    let toast: Toast
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: toast.type.icon)
                .font(.system(size: 20))
                .foregroundColor(toast.type.color)

            Text(toast.message)
                .font(.spotifyBodyMedium)
                .foregroundColor(.wisePrimaryText)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()

            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.wiseSecondaryText)
                    .frame(width: 24, height: 24)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.wiseElevatedBackground)
                .shadow(color: Color.wiseShadowColor, radius: 10, x: 0, y: 4)
        )
        .padding(.horizontal, 16)
    }
}

// MARK: - Toast Container Modifier

struct ToastModifier: ViewModifier {
    @StateObject private var toastManager = ToastManager.shared

    func body(content: Content) -> some View {
        ZStack {
            content

            if let toast = toastManager.currentToast {
                VStack {
                    Spacer()
                    ToastView(toast: toast) {
                        toastManager.dismiss()
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: toastManager.currentToast != nil)
                    .padding(.bottom, 60)
                }
            }
        }
    }
}

// MARK: - View Extension

extension View {
    func toast() -> some View {
        modifier(ToastModifier())
    }
}
