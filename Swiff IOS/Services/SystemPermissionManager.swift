//
//  SystemPermissionManager.swift
//  Swiff IOS
//
//  Created by Claude Code on 11/20/25.
//  Phase 5.5: Comprehensive system permission handling
//

import Combine
import Foundation
import AVFoundation
import Photos
import UserNotifications
import UIKit
import Contacts

// MARK: - Permission Type

enum PermissionType: String, CaseIterable {
    case camera = "Camera"
    case photoLibrary = "Photo Library"
    case notifications = "Notifications"
    case contacts = "Contacts"

    var displayName: String {
        return self.rawValue
    }

    var icon: String {
        switch self {
        case .camera: return "camera.fill"
        case .photoLibrary: return "photo.fill"
        case .notifications: return "bell.fill"
        case .contacts: return "person.crop.circle.fill"
        }
    }
}

// MARK: - Permission Status

enum PermissionStatus: String {
    case authorized = "Authorized"
    case denied = "Denied"
    case notDetermined = "Not Determined"
    case restricted = "Restricted"
    case limited = "Limited" // For photo library

    var isGranted: Bool {
        return self == .authorized || self == .limited
    }

    var displayName: String {
        return self.rawValue
    }

    var color: String {
        switch self {
        case .authorized, .limited: return "green"
        case .denied: return "red"
        case .notDetermined: return "gray"
        case .restricted: return "orange"
        }
    }
}

// MARK: - Permission Error

enum PermissionError: LocalizedError {
    case denied(PermissionType)
    case restricted(PermissionType)
    case requestFailed(PermissionType, underlying: Error)
    case notDetermined(PermissionType)

    var errorDescription: String? {
        switch self {
        case .denied(let type):
            return "\(type.displayName) access denied. Please enable in Settings."
        case .restricted(let type):
            return "\(type.displayName) access is restricted on this device."
        case .requestFailed(let type, let error):
            return "Failed to request \(type.displayName) permission: \(error.localizedDescription)"
        case .notDetermined(let type):
            return "\(type.displayName) permission not yet requested."
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .denied:
            return "Go to Settings > Privacy to enable access."
        case .restricted:
            return "Contact your device administrator to enable access."
        case .requestFailed:
            return "Try requesting permission again."
        case .notDetermined:
            return "Request permission to continue."
        }
    }
}

// MARK: - Permission Result

struct PermissionResult {
    let type: PermissionType
    let status: PermissionStatus
    let timestamp: Date

    var isGranted: Bool {
        return status.isGranted
    }

    var summary: String {
        return "\(type.displayName): \(status.displayName)"
    }
}

// MARK: - System Permission Manager

@MainActor
class SystemPermissionManager: ObservableObject {

    // MARK: - Properties

    static let shared = SystemPermissionManager()

    @Published var cameraStatus: PermissionStatus = .notDetermined
    @Published var photoLibraryStatus: PermissionStatus = .notDetermined
    @Published var notificationStatus: PermissionStatus = .notDetermined
    @Published var contactsStatus: PermissionStatus = .notDetermined

    private var permissionHistory: [PermissionType: [PermissionResult]] = [:]

    // MARK: - Initialization

    init() {
        Task {
            await updateAllPermissionStatuses()
        }
    }

    // MARK: - Camera Permission

    /// Request camera permission
    func requestCameraPermission() async throws -> PermissionStatus {
        let currentStatus = AVCaptureDevice.authorizationStatus(for: .video)

        switch currentStatus {
        case .authorized:
            cameraStatus = .authorized
            recordPermissionResult(.camera, status: .authorized)
            return .authorized

        case .denied:
            cameraStatus = .denied
            throw PermissionError.denied(.camera)

        case .restricted:
            cameraStatus = .restricted
            throw PermissionError.restricted(.camera)

        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            let status: PermissionStatus = granted ? .authorized : .denied
            cameraStatus = status
            recordPermissionResult(.camera, status: status)

            if !granted {
                throw PermissionError.denied(.camera)
            }

            return status

        @unknown default:
            cameraStatus = .notDetermined
            throw PermissionError.notDetermined(.camera)
        }
    }

    /// Check camera permission status
    func checkCameraPermission() -> PermissionStatus {
        let status = AVCaptureDevice.authorizationStatus(for: .video)

        switch status {
        case .authorized:
            cameraStatus = .authorized
            return .authorized
        case .denied:
            cameraStatus = .denied
            return .denied
        case .restricted:
            cameraStatus = .restricted
            return .restricted
        case .notDetermined:
            cameraStatus = .notDetermined
            return .notDetermined
        @unknown default:
            cameraStatus = .notDetermined
            return .notDetermined
        }
    }

    // MARK: - Photo Library Permission

    /// Request photo library permission
    func requestPhotoLibraryPermission() async throws -> PermissionStatus {
        let currentStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)

        switch currentStatus {
        case .authorized:
            photoLibraryStatus = .authorized
            recordPermissionResult(.photoLibrary, status: .authorized)
            return .authorized

        case .limited:
            photoLibraryStatus = .limited
            recordPermissionResult(.photoLibrary, status: .limited)
            return .limited

        case .denied:
            photoLibraryStatus = .denied
            throw PermissionError.denied(.photoLibrary)

        case .restricted:
            photoLibraryStatus = .restricted
            throw PermissionError.restricted(.photoLibrary)

        case .notDetermined:
            let granted = await PHPhotoLibrary.requestAuthorization(for: .readWrite)

            let status: PermissionStatus
            switch granted {
            case .authorized:
                status = .authorized
            case .limited:
                status = .limited
            case .denied:
                status = .denied
            case .restricted:
                status = .restricted
            case .notDetermined:
                status = .notDetermined
            @unknown default:
                status = .notDetermined
            }

            photoLibraryStatus = status
            recordPermissionResult(.photoLibrary, status: status)

            if !status.isGranted {
                throw PermissionError.denied(.photoLibrary)
            }

            return status

        @unknown default:
            photoLibraryStatus = .notDetermined
            throw PermissionError.notDetermined(.photoLibrary)
        }
    }

    /// Check photo library permission status
    func checkPhotoLibraryPermission() -> PermissionStatus {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)

        switch status {
        case .authorized:
            photoLibraryStatus = .authorized
            return .authorized
        case .limited:
            photoLibraryStatus = .limited
            return .limited
        case .denied:
            photoLibraryStatus = .denied
            return .denied
        case .restricted:
            photoLibraryStatus = .restricted
            return .restricted
        case .notDetermined:
            photoLibraryStatus = .notDetermined
            return .notDetermined
        @unknown default:
            photoLibraryStatus = .notDetermined
            return .notDetermined
        }
    }

    // MARK: - Notification Permission

    /// Request notification permission
    func requestNotificationPermission() async throws -> PermissionStatus {
        let center = UNUserNotificationCenter.current()
        let options: UNAuthorizationOptions = [.alert, .badge, .sound]

        do {
            let granted = try await center.requestAuthorization(options: options)

            let status: PermissionStatus = granted ? .authorized : .denied
            notificationStatus = status
            recordPermissionResult(.notifications, status: status)

            if !granted {
                throw PermissionError.denied(.notifications)
            }

            return status

        } catch {
            notificationStatus = .denied
            throw PermissionError.requestFailed(.notifications, underlying: error)
        }
    }

    /// Check notification permission status
    func checkNotificationPermission() async -> PermissionStatus {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()

        let status: PermissionStatus
        switch settings.authorizationStatus {
        case .authorized:
            status = .authorized
        case .denied:
            status = .denied
        case .notDetermined:
            status = .notDetermined
        case .provisional:
            status = .authorized
        case .ephemeral:
            status = .authorized
        @unknown default:
            status = .notDetermined
        }

        notificationStatus = status
        return status
    }

    // MARK: - Contacts Permission

    /// Request contacts permission
    func requestContactsPermission() async throws -> PermissionStatus {
        let store = CNContactStore()
        let currentStatus = CNContactStore.authorizationStatus(for: .contacts)

        switch currentStatus {
        case .authorized:
            contactsStatus = .authorized
            recordPermissionResult(.contacts, status: .authorized)
            return .authorized

        case .denied:
            contactsStatus = .denied
            throw PermissionError.denied(.contacts)

        case .restricted:
            contactsStatus = .restricted
            throw PermissionError.restricted(.contacts)

        case .notDetermined:
            do {
                let granted = try await store.requestAccess(for: .contacts)
                let status: PermissionStatus = granted ? .authorized : .denied
                contactsStatus = status
                recordPermissionResult(.contacts, status: status)

                if !granted {
                    throw PermissionError.denied(.contacts)
                }

                return status
            } catch {
                contactsStatus = .denied
                throw PermissionError.requestFailed(.contacts, underlying: error)
            }

        @unknown default:
            contactsStatus = .notDetermined
            throw PermissionError.notDetermined(.contacts)
        }
    }

    /// Check contacts permission status
    func checkContactsPermission() -> PermissionStatus {
        let status = CNContactStore.authorizationStatus(for: .contacts)

        switch status {
        case .authorized:
            contactsStatus = .authorized
            return .authorized
        case .denied:
            contactsStatus = .denied
            return .denied
        case .restricted:
            contactsStatus = .restricted
            return .restricted
        case .notDetermined:
            contactsStatus = .notDetermined
            return .notDetermined
        @unknown default:
            contactsStatus = .notDetermined
            return .notDetermined
        }
    }

    // MARK: - Batch Operations

    /// Request multiple permissions at once
    func requestPermissions(_ types: [PermissionType]) async -> [PermissionType: Result<PermissionStatus, Error>] {
        var results: [PermissionType: Result<PermissionStatus, Error>] = [:]

        for type in types {
            do {
                let status: PermissionStatus

                switch type {
                case .camera:
                    status = try await requestCameraPermission()
                case .photoLibrary:
                    status = try await requestPhotoLibraryPermission()
                case .notifications:
                    status = try await requestNotificationPermission()
                case .contacts:
                    status = try await requestContactsPermission()
                }

                results[type] = .success(status)

            } catch {
                results[type] = .failure(error)
            }
        }

        return results
    }

    /// Check all permission statuses
    func updateAllPermissionStatuses() async {
        _ = checkCameraPermission()
        _ = checkPhotoLibraryPermission()
        _ = await checkNotificationPermission()
        _ = checkContactsPermission()
    }

    /// Get all current permission statuses
    func getAllPermissionStatuses() async -> [PermissionType: PermissionStatus] {
        await updateAllPermissionStatuses()

        return [
            .camera: cameraStatus,
            .photoLibrary: photoLibraryStatus,
            .notifications: notificationStatus,
            .contacts: contactsStatus
        ]
    }

    // MARK: - Permission Status Checking

    /// Check if a specific permission is granted
    func isPermissionGranted(_ type: PermissionType) async -> Bool {
        switch type {
        case .camera:
            return checkCameraPermission().isGranted
        case .photoLibrary:
            return checkPhotoLibraryPermission().isGranted
        case .notifications:
            return await checkNotificationPermission().isGranted
        case .contacts:
            return checkContactsPermission().isGranted
        }
    }

    /// Check if all specified permissions are granted
    func areAllPermissionsGranted(_ types: [PermissionType]) async -> Bool {
        for type in types {
            if !(await isPermissionGranted(type)) {
                return false
            }
        }
        return true
    }

    /// Get denied permissions
    func getDeniedPermissions() async -> [PermissionType] {
        let statuses = await getAllPermissionStatuses()
        return statuses.filter { $0.value == .denied }.map { $0.key }
    }

    // MARK: - Settings Navigation

    /// Open app settings
    func openAppSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            Task { @MainActor in
                UIApplication.shared.open(url)
            }
        }
    }

    /// Open settings with completion
    func openAppSettings(completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: UIApplication.openSettingsURLString) else {
            completion(false)
            return
        }

        UIApplication.shared.open(url) { success in
            completion(success)
        }
    }

    // MARK: - Permission History

    /// Record permission result in history
    private func recordPermissionResult(_ type: PermissionType, status: PermissionStatus) {
        let result = PermissionResult(type: type, status: status, timestamp: Date())

        if permissionHistory[type] == nil {
            permissionHistory[type] = []
        }

        permissionHistory[type]?.append(result)

        // Keep only last 10 results per type
        if let count = permissionHistory[type]?.count, count > 10 {
            permissionHistory[type]?.removeFirst(count - 10)
        }
    }

    /// Get permission history for a type
    func getPermissionHistory(_ type: PermissionType) -> [PermissionResult] {
        return permissionHistory[type] ?? []
    }

    /// Get most recent permission result
    func getMostRecentResult(_ type: PermissionType) -> PermissionResult? {
        return permissionHistory[type]?.last
    }

    // MARK: - Statistics

    /// Get permission statistics
    func getPermissionStatistics() async -> String {
        let statuses = await getAllPermissionStatuses()

        var stats = "=== Permission Statistics ===\n\n"

        for type in PermissionType.allCases {
            if let status = statuses[type] {
                stats += "\(type.displayName): \(status.displayName)\n"
            }
        }

        let granted = statuses.values.filter { $0.isGranted }.count
        let total = statuses.count

        stats += "\nGranted: \(granted)/\(total)\n"

        if granted == total {
            stats += "Status: ✅ All permissions granted\n"
        } else {
            stats += "Status: ⚠️ Some permissions missing\n"
        }

        return stats
    }

    /// Get summary of missing permissions
    func getMissingPermissionsSummary() async -> String {
        let denied = await getDeniedPermissions()

        if denied.isEmpty {
            return "All required permissions granted"
        }

        var summary = "Missing permissions:\n"
        for type in denied {
            summary += "• \(type.displayName)\n"
        }

        summary += "\nTap to open Settings and grant access."

        return summary
    }

    // MARK: - Reset (for testing)

    /// Reset permission tracking (does not reset actual system permissions)
    func resetTracking() {
        permissionHistory.removeAll()
    }
}

// MARK: - Usage Examples (Documentation)

/*
 USAGE EXAMPLES:

 1. Request single permission:
 ```swift
 let manager = SystemPermissionManager.shared

 do {
     let status = try await manager.requestCameraPermission()
     if status.isGranted {
         // Camera is authorized
         openCamera()
     }
 } catch PermissionError.denied(let type) {
     // Show alert with option to open settings
     showPermissionAlert(for: type)
 } catch {
     print("Error: \(error.localizedDescription)")
 }
 ```

 2. Request multiple permissions:
 ```swift
 let results = await manager.requestPermissions([.camera, .photoLibrary, .notifications])

 for (type, result) in results {
     switch result {
     case .success(let status):
         print("\(type.displayName): \(status.displayName)")
     case .failure(let error):
         print("\(type.displayName): Failed - \(error.localizedDescription)")
     }
 }
 ```

 3. Check permission status:
 ```swift
 let hasCamera = await manager.isPermissionGranted(.camera)

 if !hasCamera {
     // Request permission or show alert
 }
 ```

 4. Monitor permissions in SwiftUI:
 ```swift
 struct PermissionsView: View {
     @StateObject private var permissionManager = SystemPermissionManager.shared

     var body: some View {
         List {
             PermissionRow(
                 icon: "camera.fill",
                 title: "Camera",
                 status: permissionManager.cameraStatus
             )

             PermissionRow(
                 icon: "photo.fill",
                 title: "Photos",
                 status: permissionManager.photoLibraryStatus
             )

             PermissionRow(
                 icon: "bell.fill",
                 title: "Notifications",
                 status: permissionManager.notificationStatus
             )

             if await permissionManager.getDeniedPermissions().count > 0 {
                 Button("Open Settings") {
                     permissionManager.openAppSettings()
                 }
             }
         }
         .task {
             await permissionManager.updateAllPermissionStatuses()
         }
     }
 }
 ```

 5. Check all permissions before action:
 ```swift
 func performAction() async {
     let allGranted = await manager.areAllPermissionsGranted([.camera, .photoLibrary])

     if allGranted {
         // Proceed with action
     } else {
         // Request missing permissions
         let denied = await manager.getDeniedPermissions()
         showPermissionRequest(for: denied)
     }
 }
 ```

 6. Get permission statistics:
 ```swift
 let stats = await manager.getPermissionStatistics()
 print(stats)
 ```

 7. Handle permission denial:
 ```swift
 do {
     _ = try await manager.requestPhotoLibraryPermission()
 } catch PermissionError.denied {
     // Show alert with Settings button
     let alert = UIAlertController(
         title: "Photo Access Required",
         message: "Please enable photo access in Settings",
         preferredStyle: .alert
     )

     alert.addAction(UIAlertAction(title: "Settings", style: .default) { _ in
         manager.openAppSettings()
     })

     alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

     present(alert, animated: true)
 }
 ```
 */
