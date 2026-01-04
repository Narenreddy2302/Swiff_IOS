//
//  SafeUserDefaults.swift
//  Swiff IOS
//
//  Created by Claude Code on 11/20/25.
//  Phase 5.1: Type-safe UserDefaults wrapper with validation and migration
//

import Foundation
import Combine

// MARK: - UserDefaults Error

enum UserDefaultsError: LocalizedError {
    case typeMismatch(key: String, expected: String, actual: String)
    case corruptedData(key: String)
    case migrationFailed(from: Int, to: Int, reason: String)
    case invalidValue(key: String, reason: String)
    case encodingFailed(key: String)
    case decodingFailed(key: String)

    var errorDescription: String? {
        switch self {
        case .typeMismatch(let key, let expected, let actual):
            return "Type mismatch for key '\(key)': expected \(expected), got \(actual)"
        case .corruptedData(let key):
            return "Corrupted data for key '\(key)'"
        case .migrationFailed(let from, let to, let reason):
            return "Migration from v\(from) to v\(to) failed: \(reason)"
        case .invalidValue(let key, let reason):
            return "Invalid value for key '\(key)': \(reason)"
        case .encodingFailed(let key):
            return "Failed to encode value for key '\(key)'"
        case .decodingFailed(let key):
            return "Failed to decode value for key '\(key)'"
        }
    }
}

// MARK: - Settings Keys

enum SettingsKey: String, CaseIterable {
    // App Settings
    case appVersion = "app_version"
    case settingsVersion = "settings_version"
    case firstLaunchDate = "first_launch_date"
    case lastLaunchDate = "last_launch_date"

    // User Preferences
    case isDarkModeEnabled = "is_dark_mode_enabled"
    case notificationsEnabled = "notifications_enabled"
    case biometricAuthEnabled = "biometric_auth_enabled"

    // Data Settings
    case autoBackupEnabled = "auto_backup_enabled"
    case backupFrequency = "backup_frequency"
    case lastBackupDate = "last_backup_date"

    // Display Settings
    case currencySymbol = "currency_symbol"
    case dateFormat = "date_format"
    case language = "language"

    var defaultValue: Any {
        switch self {
        case .appVersion:
            return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        case .settingsVersion:
            return 1
        case .firstLaunchDate, .lastLaunchDate, .lastBackupDate:
            return Date()
        case .isDarkModeEnabled, .notificationsEnabled, .biometricAuthEnabled, .autoBackupEnabled:
            return false
        case .backupFrequency:
            return "weekly"
        case .currencySymbol:
            return "$"
        case .dateFormat:
            return "MM/dd/yyyy"
        case .language:
            return "en"
        }
    }
}

// MARK: - Safe UserDefaults

@propertyWrapper
struct SafeDefault<T> {
    let key: SettingsKey
    let defaultValue: T
    let userDefaults: UserDefaults

    init(key: SettingsKey, defaultValue: T, userDefaults: UserDefaults = .standard) {
        self.key = key
        self.defaultValue = defaultValue
        self.userDefaults = userDefaults
    }

    var wrappedValue: T {
        get {
            return userDefaults.object(forKey: key.rawValue) as? T ?? defaultValue
        }
        set {
            userDefaults.set(newValue, forKey: key.rawValue)
        }
    }
}

// MARK: - Safe UserDefaults Manager

class SafeUserDefaultsManager {

    static let shared = SafeUserDefaultsManager()
    private let userDefaults: UserDefaults
    private let currentSettingsVersion = 1

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    // MARK: - Type-Safe Getters

    func string(forKey key: SettingsKey) -> String {
        return get(forKey: key, type: String.self) ?? key.defaultValue as! String
    }

    func int(forKey key: SettingsKey) -> Int {
        return get(forKey: key, type: Int.self) ?? key.defaultValue as! Int
    }

    func bool(forKey key: SettingsKey) -> Bool {
        return get(forKey: key, type: Bool.self) ?? key.defaultValue as! Bool
    }

    func date(forKey key: SettingsKey) -> Date {
        return get(forKey: key, type: Date.self) ?? key.defaultValue as! Date
    }

    func double(forKey key: SettingsKey) -> Double {
        return get(forKey: key, type: Double.self) ?? key.defaultValue as! Double
    }

    // MARK: - Generic Getter with Validation

    func get<T>(forKey key: SettingsKey, type: T.Type = T.self) -> T? {
        guard let value = userDefaults.object(forKey: key.rawValue) else {
            return key.defaultValue as? T
        }

        // Type validation
        if let typedValue = value as? T {
            return typedValue
        }

        // Log type mismatch
        let expectedTypeName = String(describing: type)
        let actualTypeName = String(describing: Swift.type(of: value))
        print("⚠️ Type mismatch for key '\(key.rawValue)': expected \(expectedTypeName), got \(actualTypeName)")

        // Return default value with explicit cast
        if let defaultValue = key.defaultValue as? T {
            return defaultValue
        }
        
        return nil
    }

    // MARK: - Type-Safe Setters

    func set(_ value: String, forKey key: SettingsKey) {
        userDefaults.set(value, forKey: key.rawValue)
    }

    func set(_ value: Int, forKey key: SettingsKey) {
        userDefaults.set(value, forKey: key.rawValue)
    }

    func set(_ value: Bool, forKey key: SettingsKey) {
        userDefaults.set(value, forKey: key.rawValue)
    }

    func set(_ value: Date, forKey key: SettingsKey) {
        userDefaults.set(value, forKey: key.rawValue)
    }

    func set(_ value: Double, forKey key: SettingsKey) {
        userDefaults.set(value, forKey: key.rawValue)
    }

    // MARK: - Codable Support

    func setCodable<T: Codable>(_ value: T, forKey key: String) throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(value)
        userDefaults.set(data, forKey: key)
    }

    func getCodable<T: Codable>(forKey key: String, type: T.Type = T.self) throws -> T? {
        guard let data = userDefaults.data(forKey: key) else {
            return nil
        }

        let decoder = JSONDecoder()
        return try decoder.decode(type, from: data)
    }

    // MARK: - Validation

    func validate(key: SettingsKey) -> Bool {
        guard let value = userDefaults.object(forKey: key.rawValue) else {
            return false
        }

        // Check if value matches expected type
        let expectedType = type(of: key.defaultValue)
        return type(of: value) == expectedType
    }

    func validateAll() -> [String: Bool] {
        var results: [String: Bool] = [:]

        for key in SettingsKey.allCases {
            results[key.rawValue] = validate(key: key)
        }

        return results
    }

    // MARK: - Corrupted Data Detection

    func detectCorrupted() -> [SettingsKey] {
        var corrupted: [SettingsKey] = []

        for key in SettingsKey.allCases {
            if !validate(key: key) {
                corrupted.append(key)
            }
        }

        return corrupted
    }

    func cleanupCorrupted() -> Int {
        let corrupted = detectCorrupted()

        for key in corrupted {
            remove(key: key)
        }

        return corrupted.count
    }

    // MARK: - Migration

    func migrateIfNeeded() throws {
        let currentVersion = int(forKey: .settingsVersion)

        if currentVersion < currentSettingsVersion {
            try migrate(from: currentVersion, to: currentSettingsVersion)
            set(currentSettingsVersion, forKey: .settingsVersion)
        }
    }

    private func migrate(from oldVersion: Int, to newVersion: Int) throws {
        // Migration logic for different versions

        if oldVersion == 0 && newVersion >= 1 {
            // Migration from v0 to v1
            // Add any new default values
            if userDefaults.object(forKey: SettingsKey.autoBackupEnabled.rawValue) == nil {
                set(false, forKey: .autoBackupEnabled)
            }
        }

        // Add more migration steps as needed
    }

    // MARK: - Reset

    func reset(key: SettingsKey) {
        userDefaults.removeObject(forKey: key.rawValue)
    }

    func resetAll() {
        for key in SettingsKey.allCases {
            reset(key: key)
        }
    }

    func resetToDefaults() {
        for key in SettingsKey.allCases {
            userDefaults.set(key.defaultValue, forKey: key.rawValue)
        }
    }

    // MARK: - Remove

    func remove(key: SettingsKey) {
        userDefaults.removeObject(forKey: key.rawValue)
    }

    // MARK: - Exists Check

    func exists(key: SettingsKey) -> Bool {
        return userDefaults.object(forKey: key.rawValue) != nil
    }

    // MARK: - Export/Import

    func exportSettings() -> [String: Any] {
        var settings: [String: Any] = [:]

        for key in SettingsKey.allCases {
            if let value = userDefaults.object(forKey: key.rawValue) {
                settings[key.rawValue] = value
            }
        }

        return settings
    }

    func importSettings(_ settings: [String: Any]) throws {
        for (key, value) in settings {
            if let settingsKey = SettingsKey(rawValue: key) {
                // Validate type before importing
                let expectedType = type(of: settingsKey.defaultValue)
                if type(of: value) == expectedType {
                    userDefaults.set(value, forKey: key)
                } else {
                    throw UserDefaultsError.typeMismatch(
                        key: key,
                        expected: String(describing: expectedType),
                        actual: String(describing: type(of: value))
                    )
                }
            }
        }
    }

    // MARK: - Statistics

    func getStatistics() -> String {
        var stats = "=== UserDefaults Statistics ===\n\n"
        stats += "Total Keys: \(SettingsKey.allCases.count)\n"

        let existingKeys = SettingsKey.allCases.filter { exists(key: $0) }
        stats += "Existing Keys: \(existingKeys.count)\n"

        let corruptedKeys = detectCorrupted()
        stats += "Corrupted Keys: \(corruptedKeys.count)\n"

        if !corruptedKeys.isEmpty {
            stats += "\nCorrupted:\n"
            for key in corruptedKeys {
                stats += "  - \(key.rawValue)\n"
            }
        }

        stats += "\nSettings Version: \(int(forKey: .settingsVersion))\n"
        stats += "Current Version: \(currentSettingsVersion)\n"

        return stats
    }
}

// MARK: - Convenience Extensions

extension UserDefaults {
    func safeString(forKey key: String, default defaultValue: String) -> String {
        return string(forKey: key) ?? defaultValue
    }

    func safeInt(forKey key: String, default defaultValue: Int) -> Int {
        if object(forKey: key) == nil {
            return defaultValue
        }
        return integer(forKey: key)
    }

    func safeBool(forKey key: String, default defaultValue: Bool) -> Bool {
        if object(forKey: key) == nil {
            return defaultValue
        }
        return bool(forKey: key)
    }
}

// MARK: - Usage Examples (Documentation)

/*
 USAGE EXAMPLES:

 1. Basic type-safe access:
 ```swift
 let manager = SafeUserDefaultsManager.shared

 // Get values with automatic fallback to defaults
 let isDarkMode = manager.bool(forKey: .isDarkModeEnabled)
 let currency = manager.string(forKey: .currencySymbol)

 // Set values
 manager.set(true, forKey: .isDarkModeEnabled)
 manager.set("$", forKey: .currencySymbol)
 ```

 2. Property wrapper:
 ```swift
 class Settings {
     @SafeDefault(key: .isDarkModeEnabled, defaultValue: false)
     var isDarkModeEnabled: Bool

     @SafeDefault(key: .currencySymbol, defaultValue: "$")
     var currencySymbol: String
 }

 let settings = Settings()
 settings.isDarkModeEnabled = true
 ```

 3. Detect and cleanup corrupted data:
 ```swift
 let corrupted = manager.detectCorrupted()
 if !corrupted.isEmpty {
     print("Found \(corrupted.count) corrupted key(s)")
     let cleaned = manager.cleanupCorrupted()
     print("Cleaned up \(cleaned) key(s)")
 }
 ```

 4. Migration:
 ```swift
 do {
     try manager.migrateIfNeeded()
 } catch {
     print("Migration failed: \(error)")
 }
 ```

 5. Reset settings:
 ```swift
 // Reset specific key
 manager.reset(key: .isDarkModeEnabled)

 // Reset all to defaults
 manager.resetToDefaults()

 // Remove all
 manager.resetAll()
 ```

 6. Export/Import:
 ```swift
 // Export
 let settings = manager.exportSettings()

 // Import
 try manager.importSettings(settings)
 ```

 7. Codable support:
 ```swift
 struct UserPreferences: Codable {
     var theme: String
     var fontSize: Int
 }

 let prefs = UserPreferences(theme: "dark", fontSize: 14)
 try manager.setCodable(prefs, forKey: "user_preferences")

 if let loaded = try manager.getCodable(forKey: "user_preferences", type: UserPreferences.self) {
     print("Theme: \(loaded.theme)")
 }
 ```
 */
