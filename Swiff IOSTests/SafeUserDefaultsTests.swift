//
//  SafeUserDefaultsTests.swift
//  Swiff IOSTests
//
//  Created by Claude Code on 11/20/25.
//  Tests for SafeUserDefaultsManager - Phase 5.1
//

import XCTest
@testable import Swiff_IOS

final class SafeUserDefaultsTests: XCTestCase {

    var testDefaults: UserDefaults!
    var manager: SafeUserDefaultsManager!

    override func setUp() {
        super.setUp()

        // Create test UserDefaults instance
        testDefaults = UserDefaults(suiteName: "com.swiff.test")!
        testDefaults.removePersistentDomain(forName: "com.swiff.test")

        manager = SafeUserDefaultsManager(userDefaults: testDefaults)
    }

    override func tearDown() {
        testDefaults.removePersistentDomain(forName: "com.swiff.test")
        testDefaults = nil
        manager = nil
        super.tearDown()
    }

    // MARK: - Test 1: Type-Safe Getters

    func testStringGetter() {
        manager.set("TestValue", forKey: .currencySymbol)
        let value = manager.string(forKey: .currencySymbol)
        XCTAssertEqual(value, "TestValue")
    }

    func testIntGetter() {
        manager.set(42, forKey: .settingsVersion)
        let value = manager.int(forKey: .settingsVersion)
        XCTAssertEqual(value, 42)
    }

    func testBoolGetter() {
        manager.set(true, forKey: .isDarkModeEnabled)
        let value = manager.bool(forKey: .isDarkModeEnabled)
        XCTAssertTrue(value)
    }

    // MARK: - Test 2: Default Values

    func testDefaultValueString() {
        let value = manager.string(forKey: .currencySymbol)
        XCTAssertEqual(value, "$")
    }

    func testDefaultValueBool() {
        let value = manager.bool(forKey: .isDarkModeEnabled)
        XCTAssertFalse(value)
    }

    // MARK: - Test 3: Validation

    func testValidateExistingKey() {
        manager.set(true, forKey: .notificationsEnabled)
        XCTAssertTrue(manager.validate(key: .notificationsEnabled))
    }

    func testValidateAll() {
        manager.set(true, forKey: .notificationsEnabled)
        manager.set("USD", forKey: .currencySymbol)

        let results = manager.validateAll()
        XCTAssertTrue(results[SettingsKey.notificationsEnabled.rawValue] == true)
    }

    // MARK: - Test 4: Corrupted Data Detection

    func testDetectCorruptedData() {
        // Manually set wrong type
        testDefaults.set(123, forKey: SettingsKey.currencySymbol.rawValue)

        let corrupted = manager.detectCorrupted()
        XCTAssertTrue(corrupted.contains(.currencySymbol))
    }

    func testCleanupCorrupted() {
        testDefaults.set(123, forKey: SettingsKey.currencySymbol.rawValue)

        let count = manager.cleanupCorrupted()
        XCTAssertEqual(count, 1)
        XCTAssertFalse(manager.exists(key: .currencySymbol))
    }

    // MARK: - Test 5: Reset Functions

    func testResetSingleKey() {
        manager.set(true, forKey: .isDarkModeEnabled)
        manager.reset(key: .isDarkModeEnabled)
        XCTAssertFalse(manager.exists(key: .isDarkModeEnabled))
    }

    func testResetToDefaults() {
        manager.set(true, forKey: .isDarkModeEnabled)
        manager.resetToDefaults()
        XCTAssertTrue(manager.exists(key: .isDarkModeEnabled))
        XCTAssertFalse(manager.bool(forKey: .isDarkModeEnabled))
    }

    // MARK: - Test 6: Exists Check

    func testExistsTrue() {
        manager.set("Test", forKey: .currencySymbol)
        XCTAssertTrue(manager.exists(key: .currencySymbol))
    }

    func testExistsFalse() {
        XCTAssertFalse(manager.exists(key: .currencySymbol))
    }

    // MARK: - Test 7: Export/Import

    func testExportSettings() {
        manager.set(true, forKey: .isDarkModeEnabled)
        manager.set("EUR", forKey: .currencySymbol)

        let exported = manager.exportSettings()
        XCTAssertTrue(exported.count >= 2)
    }

    func testImportSettings() throws {
        let settings: [String: Any] = [
            SettingsKey.isDarkModeEnabled.rawValue: true,
            SettingsKey.currencySymbol.rawValue: "GBP"
        ]

        try manager.importSettings(settings)
        XCTAssertTrue(manager.bool(forKey: .isDarkModeEnabled))
        XCTAssertEqual(manager.string(forKey: .currencySymbol), "GBP")
    }

    // MARK: - Test 8: Statistics

    func testGetStatistics() {
        manager.set(true, forKey: .isDarkModeEnabled)
        let stats = manager.getStatistics()

        XCTAssertTrue(stats.contains("UserDefaults Statistics"))
        XCTAssertTrue(stats.contains("Total Keys"))
    }

    // MARK: - Test 9: Convenience Extensions

    func testSafeStringExtension() {
        let value = testDefaults.safeString(forKey: "nonexistent", default: "default")
        XCTAssertEqual(value, "default")
    }

    func testSafeIntExtension() {
        let value = testDefaults.safeInt(forKey: "nonexistent", default: 42)
        XCTAssertEqual(value, 42)
    }

    // MARK: - Test 10: Edge Cases

    func testMultipleSetGet() {
        manager.set(1, forKey: .settingsVersion)
        manager.set(2, forKey: .settingsVersion)
        XCTAssertEqual(manager.int(forKey: .settingsVersion), 2)
    }
}
