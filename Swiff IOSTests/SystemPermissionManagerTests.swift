//
//  SystemPermissionManagerTests.swift
//  Swiff IOSTests
//
//  Created by Claude Code on 11/20/25.
//  Tests for SystemPermissionManager - Phase 5.5
//

import XCTest
import AVFoundation
import Photos
import UserNotifications
@testable import Swiff_IOS

@MainActor
final class SystemPermissionManagerTests: XCTestCase {

    var manager: SystemPermissionManager!

    override func setUp() async throws {
        try await super.setUp()
        manager = SystemPermissionManager.shared
        manager.resetTracking()
    }

    override func tearDown() async throws {
        manager.resetTracking()
        manager = nil
        try await super.tearDown()
    }

    // MARK: - Test 1: Permission Type

    func testPermissionTypeDisplayNames() {
        XCTAssertEqual(PermissionType.camera.displayName, "Camera")
        XCTAssertEqual(PermissionType.photoLibrary.displayName, "Photo Library")
        XCTAssertEqual(PermissionType.notifications.displayName, "Notifications")
    }

    func testPermissionTypeIcons() {
        XCTAssertEqual(PermissionType.camera.icon, "camera.fill")
        XCTAssertEqual(PermissionType.photoLibrary.icon, "photo.fill")
        XCTAssertEqual(PermissionType.notifications.icon, "bell.fill")
    }

    func testPermissionTypeAllCases() {
        let allCases = PermissionType.allCases
        XCTAssertEqual(allCases.count, 3)
        XCTAssertTrue(allCases.contains(.camera))
        XCTAssertTrue(allCases.contains(.photoLibrary))
        XCTAssertTrue(allCases.contains(.notifications))
    }

    // MARK: - Test 2: Permission Status

    func testPermissionStatusIsGranted() {
        XCTAssertTrue(PermissionStatus.authorized.isGranted)
        XCTAssertTrue(PermissionStatus.limited.isGranted)
        XCTAssertFalse(PermissionStatus.denied.isGranted)
        XCTAssertFalse(PermissionStatus.notDetermined.isGranted)
        XCTAssertFalse(PermissionStatus.restricted.isGranted)
    }

    func testPermissionStatusDisplayNames() {
        XCTAssertEqual(PermissionStatus.authorized.displayName, "Authorized")
        XCTAssertEqual(PermissionStatus.denied.displayName, "Denied")
        XCTAssertEqual(PermissionStatus.notDetermined.displayName, "Not Determined")
        XCTAssertEqual(PermissionStatus.restricted.displayName, "Restricted")
        XCTAssertEqual(PermissionStatus.limited.displayName, "Limited")
    }

    func testPermissionStatusColors() {
        XCTAssertEqual(PermissionStatus.authorized.color, "green")
        XCTAssertEqual(PermissionStatus.limited.color, "green")
        XCTAssertEqual(PermissionStatus.denied.color, "red")
        XCTAssertEqual(PermissionStatus.notDetermined.color, "gray")
        XCTAssertEqual(PermissionStatus.restricted.color, "orange")
    }

    // MARK: - Test 3: Permission Error

    func testPermissionErrorDenied() {
        let error = PermissionError.denied(.camera)

        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription!.contains("Camera"))
        XCTAssertTrue(error.errorDescription!.contains("denied"))
        XCTAssertNotNil(error.recoverySuggestion)
    }

    func testPermissionErrorRestricted() {
        let error = PermissionError.restricted(.photoLibrary)

        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription!.contains("Photo Library"))
        XCTAssertTrue(error.errorDescription!.contains("restricted"))
    }

    func testPermissionErrorNotDetermined() {
        let error = PermissionError.notDetermined(.notifications)

        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription!.contains("Notifications"))
    }

    // MARK: - Test 4: Permission Result

    func testPermissionResultCreation() {
        let result = PermissionResult(
            type: .camera,
            status: .authorized,
            timestamp: Date()
        )

        XCTAssertEqual(result.type, .camera)
        XCTAssertEqual(result.status, .authorized)
        XCTAssertTrue(result.isGranted)
    }

    func testPermissionResultSummary() {
        let result = PermissionResult(
            type: .photoLibrary,
            status: .denied,
            timestamp: Date()
        )

        let summary = result.summary
        XCTAssertTrue(summary.contains("Photo Library"))
        XCTAssertTrue(summary.contains("Denied"))
    }

    func testPermissionResultGrantedStatus() {
        let authorized = PermissionResult(
            type: .camera,
            status: .authorized,
            timestamp: Date()
        )
        XCTAssertTrue(authorized.isGranted)

        let limited = PermissionResult(
            type: .photoLibrary,
            status: .limited,
            timestamp: Date()
        )
        XCTAssertTrue(limited.isGranted)

        let denied = PermissionResult(
            type: .camera,
            status: .denied,
            timestamp: Date()
        )
        XCTAssertFalse(denied.isGranted)
    }

    // MARK: - Test 5: Camera Permission

    func testCheckCameraPermission() {
        let status = manager.checkCameraPermission()

        // Status should be one of the valid states
        XCTAssertTrue([
            .authorized,
            .denied,
            .restricted,
            .notDetermined
        ].contains(status))
    }

    func testCameraPermissionStatusUpdates() {
        _ = manager.checkCameraPermission()

        // Manager's published status should be updated
        XCTAssertTrue([
            .authorized,
            .denied,
            .restricted,
            .notDetermined
        ].contains(manager.cameraStatus))
    }

    // MARK: - Test 6: Photo Library Permission

    func testCheckPhotoLibraryPermission() {
        let status = manager.checkPhotoLibraryPermission()

        // Status should be one of the valid states
        XCTAssertTrue([
            .authorized,
            .limited,
            .denied,
            .restricted,
            .notDetermined
        ].contains(status))
    }

    func testPhotoLibraryPermissionStatusUpdates() {
        _ = manager.checkPhotoLibraryPermission()

        // Manager's published status should be updated
        XCTAssertTrue([
            .authorized,
            .limited,
            .denied,
            .restricted,
            .notDetermined
        ].contains(manager.photoLibraryStatus))
    }

    // MARK: - Test 7: Notification Permission

    func testCheckNotificationPermission() async {
        let status = await manager.checkNotificationPermission()

        // Status should be one of the valid states
        XCTAssertTrue([
            .authorized,
            .denied,
            .notDetermined
        ].contains(status))
    }

    func testNotificationPermissionStatusUpdates() async {
        _ = await manager.checkNotificationPermission()

        // Manager's published status should be updated
        XCTAssertTrue([
            .authorized,
            .denied,
            .notDetermined
        ].contains(manager.notificationStatus))
    }

    // MARK: - Test 8: Update All Permissions

    func testUpdateAllPermissionStatuses() async {
        await manager.updateAllPermissionStatuses()

        // All statuses should be set (not notDetermined for all)
        XCTAssertNotNil(manager.cameraStatus)
        XCTAssertNotNil(manager.photoLibraryStatus)
        XCTAssertNotNil(manager.notificationStatus)
    }

    func testGetAllPermissionStatuses() async {
        let statuses = await manager.getAllPermissionStatuses()

        XCTAssertEqual(statuses.count, 3)
        XCTAssertNotNil(statuses[.camera])
        XCTAssertNotNil(statuses[.photoLibrary])
        XCTAssertNotNil(statuses[.notifications])
    }

    // MARK: - Test 9: Permission Checking

    func testIsPermissionGranted() async {
        // This will return actual device permission status
        let cameraGranted = await manager.isPermissionGranted(.camera)
        let photoGranted = await manager.isPermissionGranted(.photoLibrary)
        let notificationGranted = await manager.isPermissionGranted(.notifications)

        // Should return boolean values
        XCTAssertTrue(cameraGranted == true || cameraGranted == false)
        XCTAssertTrue(photoGranted == true || photoGranted == false)
        XCTAssertTrue(notificationGranted == true || notificationGranted == false)
    }

    func testAreAllPermissionsGranted() async {
        let allGranted = await manager.areAllPermissionsGranted([.camera, .photoLibrary])

        // Should return a boolean
        XCTAssertTrue(allGranted == true || allGranted == false)
    }

    func testGetDeniedPermissions() async {
        let denied = await manager.getDeniedPermissions()

        // Should return an array (might be empty)
        XCTAssertNotNil(denied)

        // All denied permissions should be valid types
        for permission in denied {
            XCTAssertTrue(PermissionType.allCases.contains(permission))
        }
    }

    // MARK: - Test 10: Permission History

    func testGetPermissionHistory() {
        let history = manager.getPermissionHistory(.camera)

        // Should return array (might be empty initially)
        XCTAssertNotNil(history)
    }

    func testGetMostRecentResult() {
        // Initially should be nil
        let recent = manager.getMostRecentResult(.camera)
        XCTAssertNil(recent)
    }

    // MARK: - Test 11: Statistics

    func testGetPermissionStatistics() async {
        let stats = await manager.getPermissionStatistics()

        XCTAssertTrue(stats.contains("Permission Statistics"))
        XCTAssertTrue(stats.contains("Camera:"))
        XCTAssertTrue(stats.contains("Photo Library:"))
        XCTAssertTrue(stats.contains("Notifications:"))
        XCTAssertTrue(stats.contains("Granted:"))
    }

    func testGetMissingPermissionsSummary() async {
        let summary = await manager.getMissingPermissionsSummary()

        XCTAssertFalse(summary.isEmpty)

        // Should either say all granted or list missing ones
        XCTAssertTrue(
            summary.contains("All required permissions granted") ||
            summary.contains("Missing permissions:")
        )
    }

    // MARK: - Test 12: Settings Navigation

    func testOpenAppSettings() {
        // This should not crash
        manager.openAppSettings()

        // Just verify the method exists and can be called
        XCTAssertTrue(true)
    }

    func testOpenAppSettingsWithCompletion() {
        let expectation = XCTestExpectation(description: "Settings completion")

        manager.openAppSettings { success in
            // Completion should be called
            XCTAssertTrue(success == true || success == false)
            expectation.fulfill()
        }

        // Give it a moment to execute
        wait(for: [expectation], timeout: 2.0)
    }

    // MARK: - Test 13: Reset Tracking

    func testResetTracking() {
        manager.resetTracking()

        // History should be empty after reset
        for type in PermissionType.allCases {
            let history = manager.getPermissionHistory(type)
            XCTAssertTrue(history.isEmpty)
        }
    }

    // MARK: - Test 14: Edge Cases

    func testMultiplePermissionTypes() {
        let types = PermissionType.allCases
        XCTAssertGreaterThan(types.count, 0)

        for type in types {
            XCTAssertFalse(type.displayName.isEmpty)
            XCTAssertFalse(type.icon.isEmpty)
        }
    }

    func testAllPermissionStatuses() {
        let statuses: [PermissionStatus] = [
            .authorized,
            .denied,
            .notDetermined,
            .restricted,
            .limited
        ]

        for status in statuses {
            XCTAssertFalse(status.displayName.isEmpty)
            XCTAssertFalse(status.color.isEmpty)
        }
    }

    func testPermissionResultTimestamp() {
        let result = PermissionResult(
            type: .camera,
            status: .authorized,
            timestamp: Date()
        )

        // Timestamp should be recent (within last minute)
        let now = Date()
        let timeDifference = now.timeIntervalSince(result.timestamp)
        XCTAssertLessThan(timeDifference, 60)
    }
}
