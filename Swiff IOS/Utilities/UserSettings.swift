//
//  UserSettings.swift
//  Swiff IOS
//
//  Created by Naren Reddy on 11/20/25.
//  User settings persistence using UserDefaults
//

import Combine
import Foundation

@MainActor
class UserSettings: ObservableObject {
    static let shared = UserSettings()

    private let defaults = UserDefaults.standard

    // Keys for UserDefaults
    private enum Keys {
        static let notificationsEnabled = "notificationsEnabled"
        static let subscriptionReminders = "subscriptionReminders"
        static let paymentReminders = "paymentReminders"
        static let selectedCurrency = "selectedCurrency"

        // AGENT 5: Security settings keys
        static let biometricAuthEnabled = "biometricAuthEnabled"
        static let pinLockEnabled = "pinLockEnabled"
        static let autoLockEnabled = "autoLockEnabled"
        static let autoLockDuration = "autoLockDuration"
        static let encryptedPIN = "encryptedPIN"

        // AGENT 5: Enhanced notification settings keys
        static let renewalReminderDays = "renewalReminderDays"
        static let reminderTime = "reminderTime"
        static let trialExpirationReminders = "trialExpirationReminders"
        static let priceIncreaseAlerts = "priceIncreaseAlerts"
        static let unusedSubscriptionAlerts = "unusedSubscriptionAlerts"
        static let unusedSubscriptionDays = "unusedSubscriptionDays"
        static let quietHoursEnabled = "quietHoursEnabled"
        static let quietHoursStart = "quietHoursStart"
        static let quietHoursEnd = "quietHoursEnd"

        // AGENT 5: Appearance settings keys
        static let themeMode = "themeMode"
        static let accentColor = "accentColor"
        static let appIcon = "appIcon"
        static let tabBarStyle = "tabBarStyle"

        // Privacy settings keys
        static let hideBalances = "hideBalances"
        static let analyticsEnabled = "analyticsEnabled"

        // AGENT 5: Data management settings keys
        static let autoBackupEnabled = "autoBackupEnabled"
        static let backupFrequency = "backupFrequency"
        static let lastBackupDate = "lastBackupDate"
        static let backupEncryptionEnabled = "backupEncryptionEnabled"
        static let backupPassword = "backupPassword"
        static let iCloudSyncEnabled = "iCloudSyncEnabled"

        // AGENT 5: Advanced settings keys
        static let defaultBillingCycle = "defaultBillingCycle"
        static let defaultCurrency = "defaultCurrency"
        static let firstDayOfWeek = "firstDayOfWeek"
        static let dateFormat = "dateFormat"
        static let autoCategorization = "autoCategorization"
        static let developerOptionsEnabled = "developerOptionsEnabled"
        static let versionTapCount = "versionTapCount"
    }

    // Published properties
    @Published var notificationsEnabled: Bool {
        didSet {
            defaults.set(notificationsEnabled, forKey: Keys.notificationsEnabled)
        }
    }

    @Published var subscriptionReminders: Bool {
        didSet {
            defaults.set(subscriptionReminders, forKey: Keys.subscriptionReminders)
        }
    }

    @Published var paymentReminders: Bool {
        didSet {
            defaults.set(paymentReminders, forKey: Keys.paymentReminders)
        }
    }

    @Published var selectedCurrency: String {
        didSet {
            defaults.set(selectedCurrency, forKey: Keys.selectedCurrency)
        }
    }

    // AGENT 5: Security settings properties
    @Published var biometricAuthEnabled: Bool {
        didSet {
            defaults.set(biometricAuthEnabled, forKey: Keys.biometricAuthEnabled)
        }
    }

    @Published var pinLockEnabled: Bool {
        didSet {
            defaults.set(pinLockEnabled, forKey: Keys.pinLockEnabled)
        }
    }

    @Published var autoLockEnabled: Bool {
        didSet {
            defaults.set(autoLockEnabled, forKey: Keys.autoLockEnabled)
        }
    }

    @Published var autoLockDuration: Int {
        didSet {
            defaults.set(autoLockDuration, forKey: Keys.autoLockDuration)
        }
    }

    @Published var encryptedPIN: String? {
        didSet {
            defaults.set(encryptedPIN, forKey: Keys.encryptedPIN)
        }
    }

    // AGENT 5: Enhanced notification settings properties
    @Published var renewalReminderDays: [Int] {
        didSet {
            defaults.set(renewalReminderDays, forKey: Keys.renewalReminderDays)
        }
    }

    @Published var reminderTime: Date {
        didSet {
            defaults.set(reminderTime, forKey: Keys.reminderTime)
        }
    }

    @Published var trialExpirationReminders: Bool {
        didSet {
            defaults.set(trialExpirationReminders, forKey: Keys.trialExpirationReminders)
        }
    }

    @Published var priceIncreaseAlerts: Bool {
        didSet {
            defaults.set(priceIncreaseAlerts, forKey: Keys.priceIncreaseAlerts)
        }
    }

    @Published var unusedSubscriptionAlerts: Bool {
        didSet {
            defaults.set(unusedSubscriptionAlerts, forKey: Keys.unusedSubscriptionAlerts)
        }
    }

    @Published var unusedSubscriptionDays: Int {
        didSet {
            defaults.set(unusedSubscriptionDays, forKey: Keys.unusedSubscriptionDays)
        }
    }

    @Published var quietHoursEnabled: Bool {
        didSet {
            defaults.set(quietHoursEnabled, forKey: Keys.quietHoursEnabled)
        }
    }

    @Published var quietHoursStart: Date {
        didSet {
            defaults.set(quietHoursStart, forKey: Keys.quietHoursStart)
        }
    }

    @Published var quietHoursEnd: Date {
        didSet {
            defaults.set(quietHoursEnd, forKey: Keys.quietHoursEnd)
        }
    }

    // AGENT 5: Appearance settings properties
    @Published var themeMode: String {
        didSet {
            defaults.set(themeMode, forKey: Keys.themeMode)
        }
    }

    @Published var accentColor: String {
        didSet {
            defaults.set(accentColor, forKey: Keys.accentColor)
        }
    }

    @Published var appIcon: String {
        didSet {
            defaults.set(appIcon, forKey: Keys.appIcon)
        }
    }

    /// Tab bar style: "labels" (default), "iconsOnly", or "selectedOnly"
    @Published var tabBarStyle: String {
        didSet {
            defaults.set(tabBarStyle, forKey: Keys.tabBarStyle)
        }
    }

    // AGENT 5: Data management settings properties
    @Published var autoBackupEnabled: Bool {
        didSet {
            defaults.set(autoBackupEnabled, forKey: Keys.autoBackupEnabled)
        }
    }

    @Published var backupFrequency: String {
        didSet {
            defaults.set(backupFrequency, forKey: Keys.backupFrequency)
        }
    }

    @Published var lastBackupDate: Date? {
        didSet {
            defaults.set(lastBackupDate, forKey: Keys.lastBackupDate)
        }
    }

    @Published var backupEncryptionEnabled: Bool {
        didSet {
            defaults.set(backupEncryptionEnabled, forKey: Keys.backupEncryptionEnabled)
        }
    }

    @Published var backupPassword: String? {
        didSet {
            defaults.set(backupPassword, forKey: Keys.backupPassword)
        }
    }

    @Published var iCloudSyncEnabled: Bool {
        didSet {
            defaults.set(iCloudSyncEnabled, forKey: Keys.iCloudSyncEnabled)
        }
    }

    // Privacy settings properties
    @Published var hideBalances: Bool {
        didSet {
            defaults.set(hideBalances, forKey: Keys.hideBalances)
        }
    }

    @Published var analyticsEnabled: Bool {
        didSet {
            defaults.set(analyticsEnabled, forKey: Keys.analyticsEnabled)
        }
    }

    // AGENT 5: Advanced settings properties
    @Published var defaultBillingCycle: String {
        didSet {
            defaults.set(defaultBillingCycle, forKey: Keys.defaultBillingCycle)
        }
    }

    @Published var defaultCurrency: String {
        didSet {
            defaults.set(defaultCurrency, forKey: Keys.defaultCurrency)
        }
    }

    @Published var firstDayOfWeek: Int {
        didSet {
            defaults.set(firstDayOfWeek, forKey: Keys.firstDayOfWeek)
        }
    }

    @Published var dateFormat: String {
        didSet {
            defaults.set(dateFormat, forKey: Keys.dateFormat)
        }
    }

    @Published var autoCategorization: Bool {
        didSet {
            defaults.set(autoCategorization, forKey: Keys.autoCategorization)
        }
    }

    @Published var developerOptionsEnabled: Bool {
        didSet {
            defaults.set(developerOptionsEnabled, forKey: Keys.developerOptionsEnabled)
        }
    }

    @Published var versionTapCount: Int {
        didSet {
            defaults.set(versionTapCount, forKey: Keys.versionTapCount)
        }
    }

    private init() {
        // Load saved values or use defaults
        self.notificationsEnabled = defaults.object(forKey: Keys.notificationsEnabled) as? Bool ?? true
        self.subscriptionReminders = defaults.object(forKey: Keys.subscriptionReminders) as? Bool ?? true
        self.paymentReminders = defaults.object(forKey: Keys.paymentReminders) as? Bool ?? true
        self.selectedCurrency = defaults.string(forKey: Keys.selectedCurrency) ?? "USD"

        // AGENT 5: Load security settings
        self.biometricAuthEnabled = defaults.object(forKey: Keys.biometricAuthEnabled) as? Bool ?? false
        self.pinLockEnabled = defaults.object(forKey: Keys.pinLockEnabled) as? Bool ?? false
        self.autoLockEnabled = defaults.object(forKey: Keys.autoLockEnabled) as? Bool ?? false
        self.autoLockDuration = defaults.object(forKey: Keys.autoLockDuration) as? Int ?? 0
        self.encryptedPIN = defaults.string(forKey: Keys.encryptedPIN)

        // AGENT 5: Load enhanced notification settings
        self.renewalReminderDays = defaults.array(forKey: Keys.renewalReminderDays) as? [Int] ?? [1, 7]
        self.reminderTime = defaults.object(forKey: Keys.reminderTime) as? Date ?? Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()
        self.trialExpirationReminders = defaults.object(forKey: Keys.trialExpirationReminders) as? Bool ?? true
        self.priceIncreaseAlerts = defaults.object(forKey: Keys.priceIncreaseAlerts) as? Bool ?? true
        self.unusedSubscriptionAlerts = defaults.object(forKey: Keys.unusedSubscriptionAlerts) as? Bool ?? false
        self.unusedSubscriptionDays = defaults.object(forKey: Keys.unusedSubscriptionDays) as? Int ?? 30
        self.quietHoursEnabled = defaults.object(forKey: Keys.quietHoursEnabled) as? Bool ?? false
        self.quietHoursStart = defaults.object(forKey: Keys.quietHoursStart) as? Date ?? Calendar.current.date(bySettingHour: 22, minute: 0, second: 0, of: Date()) ?? Date()
        self.quietHoursEnd = defaults.object(forKey: Keys.quietHoursEnd) as? Date ?? Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: Date()) ?? Date()

        // AGENT 5: Load appearance settings
        self.themeMode = defaults.string(forKey: Keys.themeMode) ?? "System"
        self.accentColor = defaults.string(forKey: Keys.accentColor) ?? "Forest Green"
        self.appIcon = defaults.string(forKey: Keys.appIcon) ?? "Default"
        self.tabBarStyle = defaults.string(forKey: Keys.tabBarStyle) ?? "labels"

        // AGENT 5: Load data management settings
        self.autoBackupEnabled = defaults.object(forKey: Keys.autoBackupEnabled) as? Bool ?? false
        self.backupFrequency = defaults.string(forKey: Keys.backupFrequency) ?? "Weekly"
        self.lastBackupDate = defaults.object(forKey: Keys.lastBackupDate) as? Date
        self.backupEncryptionEnabled = defaults.object(forKey: Keys.backupEncryptionEnabled) as? Bool ?? false
        self.backupPassword = defaults.string(forKey: Keys.backupPassword)
        self.iCloudSyncEnabled = defaults.object(forKey: Keys.iCloudSyncEnabled) as? Bool ?? false

        // Load privacy settings
        self.hideBalances = defaults.object(forKey: Keys.hideBalances) as? Bool ?? false
        self.analyticsEnabled = defaults.object(forKey: Keys.analyticsEnabled) as? Bool ?? true

        // AGENT 5: Load advanced settings
        self.defaultBillingCycle = defaults.string(forKey: Keys.defaultBillingCycle) ?? "Monthly"
        self.defaultCurrency = defaults.string(forKey: Keys.defaultCurrency) ?? "USD"
        self.firstDayOfWeek = defaults.object(forKey: Keys.firstDayOfWeek) as? Int ?? 0 // 0 = Sunday
        self.dateFormat = defaults.string(forKey: Keys.dateFormat) ?? "MM/DD/YYYY"
        self.autoCategorization = defaults.object(forKey: Keys.autoCategorization) as? Bool ?? true
        self.developerOptionsEnabled = defaults.object(forKey: Keys.developerOptionsEnabled) as? Bool ?? false
        self.versionTapCount = defaults.object(forKey: Keys.versionTapCount) as? Int ?? 0
    }

    // Reset all settings to defaults
    func resetToDefaults() {
        notificationsEnabled = true
        subscriptionReminders = true
        paymentReminders = true
        selectedCurrency = "USD"

        // AGENT 5: Reset security settings
        biometricAuthEnabled = false
        pinLockEnabled = false
        autoLockEnabled = false
        autoLockDuration = 0
        encryptedPIN = nil

        // AGENT 5: Reset notification settings
        renewalReminderDays = [1, 7]
        reminderTime = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()
        trialExpirationReminders = true
        priceIncreaseAlerts = true
        unusedSubscriptionAlerts = false
        unusedSubscriptionDays = 30
        quietHoursEnabled = false

        // AGENT 5: Reset appearance settings
        themeMode = "System"
        accentColor = "Forest Green"
        appIcon = "Default"
        tabBarStyle = "labels"

        // AGENT 5: Reset data management settings
        autoBackupEnabled = false
        backupFrequency = "Weekly"
        backupEncryptionEnabled = false
        backupPassword = nil
        iCloudSyncEnabled = false

        // Reset privacy settings
        hideBalances = false
        analyticsEnabled = true

        // AGENT 5: Reset advanced settings
        defaultBillingCycle = "Monthly"
        defaultCurrency = "USD"
        firstDayOfWeek = 0
        dateFormat = "MM/DD/YYYY"
        autoCategorization = true
        developerOptionsEnabled = false
        versionTapCount = 0
    }
}
