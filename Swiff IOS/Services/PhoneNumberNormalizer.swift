//
//  PhoneNumberNormalizer.swift
//  Swiff IOS
//
//  Created by Claude Code on 1/8/26.
//  Utility for normalizing phone numbers to E.164 format for matching
//

import CommonCrypto
import Foundation

struct PhoneNumberNormalizer: Sendable {

    // MARK: - Default Country Code

    /// Get default country calling code based on device locale
    static var defaultCountryCode: String {
        guard let regionCode = Locale.current.region?.identifier else {
            return "+1"  // Default to US
        }

        return countryCallingCodes[regionCode] ?? "+1"
    }

    // MARK: - Normalization

    /// Normalize a phone number to E.164 format
    /// - Parameter phoneNumber: Raw phone number in any format
    /// - Returns: Normalized phone number (e.g., +12345678901)
    static func normalize(_ phoneNumber: String) -> String {
        // Remove all non-digit characters except leading +
        var cleaned = phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines)

        // Check if it starts with +
        let hasPlus = cleaned.hasPrefix("+")

        // Remove all non-digits
        cleaned = cleaned.filter { $0.isNumber }

        // If empty after cleaning, return empty
        guard !cleaned.isEmpty else { return "" }

        // Re-add the plus if it existed
        if hasPlus {
            cleaned = "+" + cleaned
        }

        // If no country code, add default
        if !cleaned.hasPrefix("+") {
            // Check if it looks like a US number without country code
            if cleaned.count == 10 {
                cleaned = defaultCountryCode + cleaned
            } else if cleaned.count == 11 && cleaned.hasPrefix("1") {
                // US number with leading 1 but no +
                cleaned = "+" + cleaned
            } else {
                // Add default country code
                cleaned = defaultCountryCode + cleaned
            }
        }

        return cleaned
    }

    /// Normalize multiple phone numbers
    /// - Parameter phoneNumbers: Array of raw phone numbers
    /// - Returns: Array of normalized phone numbers (non-empty only)
    static func normalize(_ phoneNumbers: [String]) -> [String] {
        return
            phoneNumbers
            .map { normalize($0) }
            .filter { !$0.isEmpty }
    }

    /// Check if two phone numbers are equal after normalization
    static func areEqual(_ phone1: String, _ phone2: String) -> Bool {
        let normalized1 = normalize(phone1)
        let normalized2 = normalize(phone2)
        return !normalized1.isEmpty && normalized1 == normalized2
    }

    // MARK: - Hashing

    /// Create SHA-256 hash of normalized phone number for privacy-safe server matching
    /// - Parameter phoneNumber: Phone number to hash (will be normalized first)
    /// - Returns: Hex string of SHA-256 hash
    nonisolated static func hash(_ phoneNumber: String) -> String {
        let normalized = normalize(phoneNumber)
        guard !normalized.isEmpty else { return "" }

        let data = Data(normalized.utf8)
        var hash = [UInt8](repeating: 0, count: 32)

        data.withUnsafeBytes { buffer in
            _ = CC_SHA256(buffer.baseAddress, CC_LONG(buffer.count), &hash)
        }

        return hash.map { String(format: "%02x", $0) }.joined()
    }

    /// Hash multiple phone numbers
    /// - Parameter phoneNumbers: Array of phone numbers to hash
    /// - Returns: Array of (normalized, hash) tuples for non-empty numbers
    static func hashAll(_ phoneNumbers: [String]) -> [(normalized: String, hash: String)] {
        return phoneNumbers.compactMap { phone in
            let normalized = normalize(phone)
            guard !normalized.isEmpty else { return nil }
            return (normalized: normalized, hash: hash(phone))
        }
    }

    // MARK: - Country Codes

    /// Common country calling codes
    private static let countryCallingCodes: [String: String] = [
        "US": "+1",
        "CA": "+1",
        "GB": "+44",
        "AU": "+61",
        "DE": "+49",
        "FR": "+33",
        "IN": "+91",
        "JP": "+81",
        "CN": "+86",
        "BR": "+55",
        "MX": "+52",
        "ES": "+34",
        "IT": "+39",
        "NL": "+31",
        "BE": "+32",
        "CH": "+41",
        "AT": "+43",
        "SE": "+46",
        "NO": "+47",
        "DK": "+45",
        "FI": "+358",
        "PL": "+48",
        "RU": "+7",
        "KR": "+82",
        "SG": "+65",
        "HK": "+852",
        "TW": "+886",
        "NZ": "+64",
        "ZA": "+27",
        "AE": "+971",
        "SA": "+966",
        "IL": "+972",
        "PH": "+63",
        "TH": "+66",
        "MY": "+60",
        "ID": "+62",
        "VN": "+84",
        "PK": "+92",
        "BD": "+880",
        "NG": "+234",
        "EG": "+20",
        "AR": "+54",
        "CL": "+56",
        "CO": "+57",
        "PE": "+51",
        "VE": "+58",
        "IE": "+353",
        "PT": "+351",
        "GR": "+30",
        "CZ": "+420",
        "RO": "+40",
        "HU": "+36",
        "UA": "+380",
        "TR": "+90",
    ]
}
