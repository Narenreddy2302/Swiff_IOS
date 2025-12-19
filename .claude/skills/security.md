# Security Best Practices

## Purpose
Ensure security best practices are followed throughout the application, protecting user data and preventing common vulnerabilities.

## When to Use This Skill
- Handling user input
- Implementing authentication
- Storing sensitive data
- Managing permissions
- Reviewing code for security

---

## Security Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    User Input                                │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                  Input Sanitization                          │
│              (InputSanitizer.swift)                          │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    Validation                                │
│          (FormValidator, BusinessRuleValidator)              │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                   Secure Storage                             │
│           (Keychain, SafeUserDefaults)                       │
└─────────────────────────────────────────────────────────────┘
```

---

## Input Sanitization

### InputSanitizer

```swift
// Utilities/InputSanitizer.swift
enum InputSanitizer {

    // MARK: - Basic Sanitization

    static func trimWhitespace(_ input: String) -> String {
        input.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func removeDangerousCharacters(_ input: String) -> String {
        let dangerous = CharacterSet(charactersIn: "<>\"'&;\\")
        return input.unicodeScalars
            .filter { !dangerous.contains($0) }
            .map { String($0) }
            .joined()
    }

    // MARK: - HTML/XSS Prevention

    static func escapeHTML(_ input: String) -> String {
        input
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&#39;")
    }

    static func containsXSS(_ input: String) -> Bool {
        let patterns = [
            "<script",
            "javascript:",
            "onerror=",
            "onclick=",
            "onload=",
            "eval(",
            "document.cookie"
        ]
        let lowercased = input.lowercased()
        return patterns.contains { lowercased.contains($0) }
    }

    // MARK: - SQL Injection Prevention

    static func containsSQLInjection(_ input: String) -> Bool {
        let patterns = [
            "'; --",
            "'; DROP",
            "1=1",
            "OR 1=1",
            "UNION SELECT",
            "INSERT INTO",
            "DELETE FROM",
            "UPDATE SET"
        ]
        let uppercased = input.uppercased()
        return patterns.contains { uppercased.contains($0) }
    }

    // MARK: - Path Traversal Prevention

    static func sanitizePath(_ path: String) throws -> String {
        // Remove dangerous path components
        let dangerous = ["../", "..\\", "%2e%2e", "%252e"]
        var result = path
        for pattern in dangerous {
            result = result.replacingOccurrences(of: pattern, with: "")
        }

        // Validate result doesn't escape intended directory
        guard !result.contains("..") else {
            throw SanitizationError.pathTraversal
        }

        return result
    }

    static func sanitizeFilename(_ filename: String) -> String {
        let invalidChars = CharacterSet(charactersIn: "/\\:*?\"<>|")
        return filename.unicodeScalars
            .filter { !invalidChars.contains($0) }
            .map { String($0) }
            .joined()
    }

    // MARK: - Type-Specific Sanitization

    static func sanitizeEmail(_ email: String) -> String {
        trimWhitespace(email).lowercased()
    }

    static func sanitizePhone(_ phone: String) -> String {
        phone.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
    }

    static func sanitizeURL(_ url: String) -> String? {
        guard let url = URL(string: trimWhitespace(url)),
              ["http", "https"].contains(url.scheme?.lowercased()) else {
            return nil
        }
        return url.absoluteString
    }

    // MARK: - Validation

    static func isValidEmail(_ email: String) -> Bool {
        let pattern = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let predicate = NSPredicate(format: "SELF MATCHES %@", pattern)
        return predicate.evaluate(with: email)
    }

    static func isValidPhone(_ phone: String) -> Bool {
        let digitsOnly = sanitizePhone(phone)
        return digitsOnly.count >= 10 && digitsOnly.count <= 15
    }
}

enum SanitizationError: LocalizedError {
    case pathTraversal
    case xssDetected
    case sqlInjectionDetected

    var errorDescription: String? {
        switch self {
        case .pathTraversal:
            return "Invalid path detected"
        case .xssDetected:
            return "Invalid characters detected"
        case .sqlInjectionDetected:
            return "Invalid input detected"
        }
    }
}
```

### Usage in Forms

```swift
struct AddPersonView: View {
    @State private var name = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var validationError: String?

    var body: some View {
        Form {
            TextField("Name", text: $name)
            TextField("Email", text: $email)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
            TextField("Phone", text: $phone)
                .keyboardType(.phonePad)

            if let error = validationError {
                Text(error)
                    .foregroundColor(.red)
            }
        }
    }

    func validateAndSave() {
        // Sanitize inputs
        let sanitizedName = InputSanitizer.trimWhitespace(name)
        let sanitizedEmail = InputSanitizer.sanitizeEmail(email)
        let sanitizedPhone = InputSanitizer.sanitizePhone(phone)

        // Validate
        guard !sanitizedName.isEmpty else {
            validationError = "Name is required"
            return
        }

        guard InputSanitizer.isValidEmail(sanitizedEmail) else {
            validationError = "Invalid email address"
            return
        }

        // Check for injection attacks
        if InputSanitizer.containsSQLInjection(sanitizedName) ||
           InputSanitizer.containsXSS(sanitizedName) {
            validationError = "Invalid characters in name"
            return
        }

        // Save sanitized data
        let person = Person(
            name: sanitizedName,
            email: sanitizedEmail,
            phone: sanitizedPhone
        )
        try? dataManager.addPerson(person)
    }
}
```

---

## Biometric Authentication

```swift
// Services/BiometricAuthenticationService.swift
import LocalAuthentication

@MainActor
class BiometricAuthenticationService: ObservableObject {
    static let shared = BiometricAuthenticationService()

    @Published var biometricType: BiometricType = .none
    @Published var isAuthenticated = false
    @Published var authenticationError: Error?

    enum BiometricType {
        case none
        case faceID
        case touchID

        var displayName: String {
            switch self {
            case .none: return "Passcode"
            case .faceID: return "Face ID"
            case .touchID: return "Touch ID"
            }
        }

        var icon: String {
            switch self {
            case .none: return "lock.fill"
            case .faceID: return "faceid"
            case .touchID: return "touchid"
            }
        }
    }

    private init() {
        checkBiometricAvailability()
    }

    func checkBiometricAvailability() {
        let context = LAContext()
        var error: NSError?

        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            switch context.biometryType {
            case .faceID:
                biometricType = .faceID
            case .touchID:
                biometricType = .touchID
            default:
                biometricType = .none
            }
        } else {
            biometricType = .none
        }
    }

    func authenticate(reason: String = "Authenticate to access your data") async throws -> Bool {
        let context = LAContext()
        context.localizedCancelTitle = "Cancel"

        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason
            )

            await MainActor.run {
                isAuthenticated = success
                authenticationError = nil
            }

            return success
        } catch let error as LAError {
            await MainActor.run {
                isAuthenticated = false
                authenticationError = error
            }

            switch error.code {
            case .userCancel, .systemCancel:
                // User cancelled - not an error
                return false
            case .biometryNotAvailable:
                throw AuthenticationError.biometryNotAvailable
            case .biometryNotEnrolled:
                throw AuthenticationError.biometryNotEnrolled
            case .biometryLockout:
                throw AuthenticationError.biometryLockout
            default:
                throw error
            }
        }
    }

    func resetAuthentication() {
        isAuthenticated = false
    }
}

enum AuthenticationError: LocalizedError {
    case biometryNotAvailable
    case biometryNotEnrolled
    case biometryLockout
    case authenticationFailed

    var errorDescription: String? {
        switch self {
        case .biometryNotAvailable:
            return "Biometric authentication is not available on this device"
        case .biometryNotEnrolled:
            return "No biometric data enrolled. Please set up Face ID or Touch ID in Settings."
        case .biometryLockout:
            return "Biometric authentication is locked. Please use your passcode."
        case .authenticationFailed:
            return "Authentication failed. Please try again."
        }
    }
}
```

---

## Secure Storage

### SafeUserDefaults

```swift
// Utilities/SafeUserDefaults.swift
class SafeUserDefaults {
    static let shared = SafeUserDefaults()

    private let defaults = UserDefaults.standard
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    // MARK: - Type-Safe Getters

    func string(forKey key: String, default defaultValue: String = "") -> String {
        defaults.string(forKey: key) ?? defaultValue
    }

    func int(forKey key: String, default defaultValue: Int = 0) -> Int {
        defaults.object(forKey: key) as? Int ?? defaultValue
    }

    func bool(forKey key: String, default defaultValue: Bool = false) -> Bool {
        defaults.object(forKey: key) as? Bool ?? defaultValue
    }

    func double(forKey key: String, default defaultValue: Double = 0) -> Double {
        defaults.object(forKey: key) as? Double ?? defaultValue
    }

    func date(forKey key: String) -> Date? {
        defaults.object(forKey: key) as? Date
    }

    // MARK: - Codable Support

    func codable<T: Codable>(forKey key: String, type: T.Type) -> T? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? decoder.decode(type, from: data)
    }

    func setCodable<T: Codable>(_ value: T, forKey key: String) {
        if let data = try? encoder.encode(value) {
            defaults.set(data, forKey: key)
        }
    }

    // MARK: - Setters with Validation

    func set(_ value: String, forKey key: String, maxLength: Int = 1000) {
        let sanitized = InputSanitizer.trimWhitespace(value)
        let truncated = String(sanitized.prefix(maxLength))
        defaults.set(truncated, forKey: key)
    }

    func set(_ value: Int, forKey key: String) {
        defaults.set(value, forKey: key)
    }

    func set(_ value: Bool, forKey key: String) {
        defaults.set(value, forKey: key)
    }

    func set(_ value: Double, forKey key: String) {
        defaults.set(value, forKey: key)
    }

    // MARK: - Removal

    func remove(forKey key: String) {
        defaults.removeObject(forKey: key)
    }

    // MARK: - Sensitive Data (Use Keychain Instead)

    // NOTE: For sensitive data like passwords, tokens, use Keychain
    // UserDefaults is NOT secure for sensitive information
}
```

### Keychain Wrapper (for sensitive data)

```swift
import Security

class KeychainManager {
    static let shared = KeychainManager()

    private let serviceName = "com.swiff.ios"

    func save(_ data: Data, for key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]

        // Delete existing item
        SecItemDelete(query as CFDictionary)

        // Add new item
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.saveFailed(status)
        }
    }

    func load(for key: String) throws -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess else {
            if status == errSecItemNotFound {
                return nil
            }
            throw KeychainError.loadFailed(status)
        }

        return result as? Data
    }

    func delete(for key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key
        ]

        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.deleteFailed(status)
        }
    }
}

enum KeychainError: LocalizedError {
    case saveFailed(OSStatus)
    case loadFailed(OSStatus)
    case deleteFailed(OSStatus)

    var errorDescription: String? {
        switch self {
        case .saveFailed(let status):
            return "Failed to save to Keychain: \(status)"
        case .loadFailed(let status):
            return "Failed to load from Keychain: \(status)"
        case .deleteFailed(let status):
            return "Failed to delete from Keychain: \(status)"
        }
    }
}
```

---

## Permission Management

```swift
// Utilities/SystemPermissionManager.swift
import Photos
import Contacts
import UserNotifications

class SystemPermissionManager: ObservableObject {
    static let shared = SystemPermissionManager()

    @Published var notificationStatus: UNAuthorizationStatus = .notDetermined
    @Published var photoLibraryStatus: PHAuthorizationStatus = .notDetermined
    @Published var contactsStatus: CNAuthorizationStatus = .notDetermined

    func checkAllPermissions() async {
        await checkNotificationPermission()
        checkPhotoLibraryPermission()
        checkContactsPermission()
    }

    // MARK: - Notifications

    func checkNotificationPermission() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        await MainActor.run {
            notificationStatus = settings.authorizationStatus
        }
    }

    func requestNotificationPermission() async throws -> Bool {
        let granted = try await UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .badge, .sound])
        await checkNotificationPermission()
        return granted
    }

    // MARK: - Photo Library

    func checkPhotoLibraryPermission() {
        photoLibraryStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
    }

    func requestPhotoLibraryPermission() async -> PHAuthorizationStatus {
        let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        await MainActor.run {
            photoLibraryStatus = status
        }
        return status
    }

    // MARK: - Contacts

    func checkContactsPermission() {
        contactsStatus = CNContactStore.authorizationStatus(for: .contacts)
    }

    func requestContactsPermission() async throws -> Bool {
        let store = CNContactStore()
        let granted = try await store.requestAccess(for: .contacts)
        checkContactsPermission()
        return granted
    }
}
```

---

## Security Settings

```swift
// Models/SecuritySettings.swift
struct SecuritySettings: Codable {
    var requireAuthOnLaunch: Bool = false
    var lockOnBackground: Bool = false
    var autoLockTimeout: TimeInterval = 300 // 5 minutes
    var useBiometrics: Bool = true
    var usePIN: Bool = false
    var pinHash: String? = nil

    static func load() -> SecuritySettings {
        SafeUserDefaults.shared.codable(forKey: "securitySettings", type: SecuritySettings.self)
            ?? SecuritySettings()
    }

    func save() {
        SafeUserDefaults.shared.setCodable(self, forKey: "securitySettings")
    }
}
```

---

## Privacy in Logging

```swift
// Sanitize logs to remove PII
extension ErrorLogger {
    func sanitize(_ text: String) -> String {
        var result = text

        // Redact email addresses
        let emailPattern = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        result = result.replacingOccurrences(
            of: emailPattern,
            with: "[REDACTED_EMAIL]",
            options: .regularExpression
        )

        // Redact phone numbers
        let phonePattern = "\\+?\\d{10,}"
        result = result.replacingOccurrences(
            of: phonePattern,
            with: "[REDACTED_PHONE]",
            options: .regularExpression
        )

        // Redact credit card numbers
        let ccPattern = "\\d{4}[- ]?\\d{4}[- ]?\\d{4}[- ]?\\d{4}"
        result = result.replacingOccurrences(
            of: ccPattern,
            with: "[REDACTED_CARD]",
            options: .regularExpression
        )

        return result
    }
}
```

---

## Common Mistakes to Avoid

1. **Storing sensitive data in UserDefaults** (use Keychain)
2. **Logging sensitive information**
3. **Not validating user input**
4. **Trusting client-side validation only**
5. **Hardcoding secrets in code**
6. **Not using HTTPS for network requests**

---

## Checklist

- [ ] All user input sanitized
- [ ] SQL injection patterns blocked
- [ ] XSS patterns blocked
- [ ] Path traversal prevented
- [ ] Sensitive data in Keychain (not UserDefaults)
- [ ] Biometric authentication implemented
- [ ] Permissions requested at appropriate time
- [ ] PII redacted from logs

---

## Industry Standards

- **OWASP Mobile Security** - Top 10 vulnerabilities
- **Apple Security Guidelines**
- **GDPR** - Data protection
- **Keychain Services** - Secure storage
- **LocalAuthentication** - Biometrics
