//
//  NotificationLimitManagerTests.swift
//  Swiff IOSTests
//
//  Created by Claude Code on 11/20/25.
//  Tests for NotificationLimitManager - Phase 5.3
//

import XCTest
import UserNotifications
@testable import Swiff_IOS

@MainActor
final class NotificationLimitManagerTests: XCTestCase {

    var manager: NotificationLimitManager!

    override func setUp() async throws {
        try await super.setUp()
        manager = NotificationLimitManager.shared

        // Clean up all notifications before each test
        await manager.removeAllNotifications()
    }

    override func tearDown() async throws {
        await manager.removeAllNotifications()
        manager = nil
        try await super.tearDown()
    }

    // MARK: - Test 1: Notification Priority

    func testNotificationPriorityComparison() {
        XCTAssertLessThan(NotificationPriority.low, NotificationPriority.medium)
        XCTAssertLessThan(NotificationPriority.medium, NotificationPriority.high)
        XCTAssertLessThan(NotificationPriority.high, NotificationPriority.critical)
    }

    func testNotificationPriorityDisplayNames() {
        XCTAssertEqual(NotificationPriority.low.displayName, "Low")
        XCTAssertEqual(NotificationPriority.medium.displayName, "Medium")
        XCTAssertEqual(NotificationPriority.high.displayName, "High")
        XCTAssertEqual(NotificationPriority.critical.displayName, "Critical")
    }

    // MARK: - Test 2: Managed Notification

    func testManagedNotificationCreation() {
        let notification = ManagedNotification(
            id: "test-1",
            title: "Test",
            body: "Test body",
            fireDate: Date().addingTimeInterval(3600),
            priority: .high,
            category: "test"
        )

        XCTAssertEqual(notification.id, "test-1")
        XCTAssertEqual(notification.title, "Test")
        XCTAssertEqual(notification.priority, .high)
        XCTAssertEqual(notification.category, "test")
    }

    func testManagedNotificationExpiration() {
        // Not expired
        let futureNotification = ManagedNotification(
            id: "test-1",
            title: "Test",
            body: "Test",
            fireDate: Date().addingTimeInterval(3600),
            priority: .medium,
            category: "test",
            expiresAt: Date().addingTimeInterval(7200)
        )
        XCTAssertFalse(futureNotification.isExpired)

        // Expired
        let expiredNotification = ManagedNotification(
            id: "test-2",
            title: "Test",
            body: "Test",
            fireDate: Date(),
            priority: .medium,
            category: "test",
            expiresAt: Date().addingTimeInterval(-3600)
        )
        XCTAssertTrue(expiredNotification.isExpired)
    }

    func testManagedNotificationDaysUntilFire() {
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!

        let notification = ManagedNotification(
            id: "test-1",
            title: "Test",
            body: "Test",
            fireDate: tomorrow,
            priority: .medium,
            category: "test"
        )

        XCTAssertEqual(notification.daysUntilFire, 1)
    }

    // MARK: - Test 3: Notification Encoding/Decoding

    func testManagedNotificationCodable() throws {
        let notification = ManagedNotification(
            id: "test-1",
            title: "Test Title",
            body: "Test Body",
            fireDate: Date(),
            priority: .high,
            category: "test"
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(notification)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(ManagedNotification.self, from: data)

        XCTAssertEqual(decoded.id, notification.id)
        XCTAssertEqual(decoded.title, notification.title)
        XCTAssertEqual(decoded.body, notification.body)
        XCTAssertEqual(decoded.priority, notification.priority)
        XCTAssertEqual(decoded.category, notification.category)
    }

    // MARK: - Test 4: Available Slots

    func testGetAvailableSlots() async {
        await manager.updateNotificationCount()
        let slots = manager.getAvailableSlots()

        XCTAssertGreaterThanOrEqual(slots, 0)
        XCTAssertLessThanOrEqual(slots, 64)
    }

    func testAvailableSlotsCalculation() async {
        await manager.updateNotificationCount()
        let initialSlots = manager.getAvailableSlots()
        let initialCount = manager.currentCount

        XCTAssertEqual(initialSlots, 64 - initialCount)
    }

    // MARK: - Test 5: Notification Count Updates

    func testUpdateNotificationCount() async {
        await manager.updateNotificationCount()
        XCTAssertGreaterThanOrEqual(manager.currentCount, 0)
        XCTAssertLessThanOrEqual(manager.currentCount, 64)
    }

    func testIsNearLimitFlag() async {
        await manager.updateNotificationCount()

        // Should not be near limit initially (assuming clean state)
        if manager.currentCount < 55 {
            XCTAssertFalse(manager.isNearLimit)
        }
    }

    // MARK: - Test 6: Statistics

    func testGetStatistics() async {
        let stats = await manager.getStatistics()

        XCTAssertGreaterThanOrEqual(stats.totalScheduled, 0)
        XCTAssertLessThanOrEqual(stats.totalScheduled, 64)
        XCTAssertGreaterThanOrEqual(stats.availableSlots, 0)
        XCTAssertLessThanOrEqual(stats.utilizationPercentage, 100.0)
    }

    func testStatisticsSummary() async {
        let stats = await manager.getStatistics()
        let summary = stats.summary

        XCTAssertTrue(summary.contains("Notification Statistics"))
        XCTAssertTrue(summary.contains("Total Scheduled:"))
        XCTAssertTrue(summary.contains("Available Slots:"))
        XCTAssertTrue(summary.contains("Utilization:"))
    }

    func testStatisticsUtilization() async {
        let stats = await manager.getStatistics()

        let expectedUtilization = (Double(stats.totalScheduled) / 64.0) * 100.0
        XCTAssertEqual(stats.utilizationPercentage, expectedUtilization, accuracy: 0.01)
    }

    // MARK: - Test 7: Content Creation Helper

    func testCreateContent() {
        let content = NotificationLimitManager.createContent(
            title: "Test Title",
            body: "Test Body"
        )

        XCTAssertEqual(content.title, "Test Title")
        XCTAssertEqual(content.body, "Test Body")
        XCTAssertEqual(content.sound, .default)
    }

    func testCreateContentWithBadge() {
        let content = NotificationLimitManager.createContent(
            title: "Test",
            body: "Body",
            badge: 5
        )

        XCTAssertEqual(content.badge, 5)
    }

    // MARK: - Test 8: Trigger Creation Helpers

    func testCreateDateTrigger() {
        let fireDate = Date().addingTimeInterval(3600)
        let trigger = NotificationLimitManager.createDateTrigger(fireDate: fireDate)

        XCTAssertFalse(trigger.repeats)
        XCTAssertNotNil(trigger.dateComponents)
    }

    func testCreateIntervalTrigger() {
        let trigger = NotificationLimitManager.createIntervalTrigger(interval: 60)

        XCTAssertEqual(trigger.timeInterval, 60)
        XCTAssertFalse(trigger.repeats)
    }

    func testCreateRepeatingIntervalTrigger() {
        let trigger = NotificationLimitManager.createIntervalTrigger(interval: 3600, repeats: true)

        XCTAssertEqual(trigger.timeInterval, 3600)
        XCTAssertTrue(trigger.repeats)
    }

    // MARK: - Test 9: Error Messages

    func testLimitReachedErrorMessage() {
        let error = NotificationLimitError.limitReached(scheduled: 64, limit: 64)

        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription!.contains("64"))
        XCTAssertNotNil(error.recoverySuggestion)
    }

    func testAuthorizationDeniedErrorMessage() {
        let error = NotificationLimitError.authorizationDenied

        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription!.contains("permission"))
        XCTAssertNotNil(error.recoverySuggestion)
    }

    func testInvalidIdentifierErrorMessage() {
        let error = NotificationLimitError.invalidIdentifier

        XCTAssertNotNil(error.errorDescription)
        XCTAssertNotNil(error.recoverySuggestion)
    }

    func testNotificationNotFoundErrorMessage() {
        let error = NotificationLimitError.notificationNotFound(identifier: "test-123")

        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription!.contains("test-123"))
    }

    // MARK: - Test 10: Get Managed Notifications

    func testGetManagedNotifications() {
        let notifications = manager.getManagedNotifications()

        // Should return array (might be empty)
        XCTAssertNotNil(notifications)
    }

    func testGetNotificationsByPriority() {
        let highPriority = manager.getNotifications(priority: .high)

        XCTAssertNotNil(highPriority)
        // All returned notifications should be high priority
        for notification in highPriority {
            XCTAssertEqual(notification.priority, .high)
        }
    }

    func testGetNotificationsByCategory() {
        let testCategory = manager.getNotifications(category: "test")

        XCTAssertNotNil(testCategory)
        // All returned notifications should match category
        for notification in testCategory {
            XCTAssertEqual(notification.category, "test")
        }
    }

    // MARK: - Test 11: Remove All Notifications

    func testRemoveAllNotifications() async {
        await manager.removeAllNotifications()
        await manager.updateNotificationCount()

        XCTAssertEqual(manager.currentCount, 0)
    }

    // MARK: - Test 12: Edge Cases

    func testEmptyNotificationList() {
        let notifications = manager.getManagedNotifications()
        // Even if empty, should return valid array
        XCTAssertNotNil(notifications)
    }

    func testStatisticsWithNoNotifications() async {
        await manager.removeAllNotifications()
        let stats = await manager.getStatistics()

        XCTAssertEqual(stats.totalScheduled, 0)
        XCTAssertEqual(stats.availableSlots, 64)
        XCTAssertEqual(stats.utilizationPercentage, 0.0)
    }

    func testMultiplePriorityLevels() {
        let priorities: [NotificationPriority] = [.low, .medium, .high, .critical]

        for priority in priorities {
            let notifications = manager.getNotifications(priority: priority)
            XCTAssertNotNil(notifications)
        }
    }
}
