import Foundation

/// Actor-based service for caching contacts locally
actor ContactCacheService {
    static let shared = ContactCacheService()

    private let fileManager = FileManager.default
    private let cacheFileName = "cached_contacts.json"
    private let metadataFileName = "contacts_cache_metadata.json"

    private var cacheURL: URL {
        fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(cacheFileName)
    }

    private var metadataURL: URL {
        fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(metadataFileName)
    }

    struct CacheMetadata: Codable {
        let lastSyncDate: Date
        let contactCount: Int
        let version: Int  // For future cache migrations

        static let currentVersion = 1
    }

    // Load cached contacts - returns nil if no cache exists
    func loadCachedContacts() -> [ContactEntry]? {
        guard fileManager.fileExists(atPath: cacheURL.path) else { return nil }

        do {
            let data = try Data(contentsOf: cacheURL)
            let contacts = try JSONDecoder().decode([ContactEntry].self, from: data)
            return contacts
        } catch {
            print("Failed to load cached contacts: \(error)")
            return nil
        }
    }

    // Save contacts to cache after successful sync
    func cacheContacts(_ contacts: [ContactEntry]) {
        do {
            let data = try JSONEncoder().encode(contacts)
            try data.write(to: cacheURL)

            let metadata = CacheMetadata(
                lastSyncDate: Date(),
                contactCount: contacts.count,
                version: CacheMetadata.currentVersion
            )

            if let metadataData = try? JSONEncoder().encode(metadata) {
                try metadataData.write(to: metadataURL)
            }
        } catch {
            print("Failed to cache contacts: \(error)")
        }
    }

    // Check if cache exists and is fresh (within specified interval)
    func isCacheFresh(maxAge: TimeInterval = 300) -> Bool {
        guard let metadata = getMetadata() else { return false }

        // If version mismatch, cache is not fresh
        if metadata.version != CacheMetadata.currentVersion {
            return false
        }

        return Date().timeIntervalSince(metadata.lastSyncDate) < maxAge
    }

    // Invalidate cache by setting lastSyncDate to distant past
    func invalidateCache() {
        guard let currentMetadata = getMetadata() else { return }

        let staleMetadata = CacheMetadata(
            lastSyncDate: .distantPast,
            contactCount: currentMetadata.contactCount,
            version: currentMetadata.version
        )

        if let metadataData = try? JSONEncoder().encode(staleMetadata) {
            try? metadataData.write(to: metadataURL)
        }
    }

    // Get cache metadata for debugging/UI
    func getMetadata() -> CacheMetadata? {
        guard fileManager.fileExists(atPath: metadataURL.path) else { return nil }

        do {
            let data = try Data(contentsOf: metadataURL)
            return try JSONDecoder().decode(CacheMetadata.self, from: data)
        } catch {
            print("Failed to load cache metadata: \(error)")
            return nil
        }
    }

    // Clear cache (for logout, debugging, etc.)
    func clearCache() {
        try? fileManager.removeItem(at: cacheURL)
        try? fileManager.removeItem(at: metadataURL)
    }
}
