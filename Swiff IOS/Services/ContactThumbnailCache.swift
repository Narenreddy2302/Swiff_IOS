//
//  ContactThumbnailCache.swift
//  Swiff IOS
//
//  Created by Claude Code on 1/8/26.
//  FIX 3.2: Actor-based LRU cache for contact thumbnails
//  Loads thumbnails lazily and evicts old entries to reduce memory usage
//

import Contacts
import Foundation
import UIKit

/// Actor-based cache for contact thumbnails with LRU eviction
/// This significantly reduces memory usage by only caching visible thumbnails
actor ContactThumbnailCache {

    // MARK: - Singleton

    static let shared = ContactThumbnailCache()

    // MARK: - Properties

    /// In-memory cache of thumbnails
    private var cache: [String: UIImage] = [:]

    /// LRU tracking - most recently accessed IDs are at the end
    private var accessOrder: [String] = []

    /// Maximum number of thumbnails to keep in memory
    private let maxCacheSize = 50

    /// CNContactStore for fetching thumbnails
    private let store = CNContactStore()

    /// Keys needed for thumbnail fetch
    private let thumbnailKeys: [CNKeyDescriptor] = [
        CNContactThumbnailImageDataKey as CNKeyDescriptor,
    ]

    // MARK: - Initialization

    private init() {}

    // MARK: - Public Methods

    /// Get thumbnail for contact, loading from CNContactStore if needed
    /// - Parameter contactId: The contact identifier
    /// - Returns: UIImage if available, nil if no thumbnail exists
    func thumbnail(for contactId: String) async -> UIImage? {
        // Return cached if available
        if let cached = cache[contactId] {
            updateAccessOrder(for: contactId)
            return cached
        }

        // Load from system
        let image = await loadFromContactStore(contactId: contactId)

        if let image = image {
            cacheImage(image, for: contactId)
        }

        return image
    }

    /// Prefetch thumbnails for a list of contact IDs
    /// Call this when about to display a list of contacts
    func prefetch(contactIds: [String]) async {
        for contactId in contactIds.prefix(maxCacheSize) {
            if cache[contactId] == nil {
                if let image = await loadFromContactStore(contactId: contactId) {
                    cacheImage(image, for: contactId)
                }
            }
        }
    }

    /// Check if thumbnail is cached (for UI optimization)
    func isCached(contactId: String) -> Bool {
        return cache[contactId] != nil
    }

    /// Clear all cached thumbnails
    func clearCache() {
        cache.removeAll()
        accessOrder.removeAll()
        print("DEBUG: ContactThumbnailCache cleared")
    }

    /// Get current cache statistics
    var statistics: String {
        "Cached thumbnails: \(cache.count)/\(maxCacheSize)"
    }

    // MARK: - Private Methods

    /// Load thumbnail from CNContactStore
    private func loadFromContactStore(contactId: String) async -> UIImage? {
        await Task.detached {
            guard CNContactStore.authorizationStatus(for: .contacts) == .authorized else {
                return nil
            }

            do {
                let contact = try self.store.unifiedContact(
                    withIdentifier: contactId,
                    keysToFetch: self.thumbnailKeys
                )

                if let data = contact.thumbnailImageData {
                    return UIImage(data: data)
                }
            } catch {
                // Contact may not exist or be inaccessible
                // This is expected for some contacts, don't log as error
            }

            return nil
        }.value
    }

    /// Update LRU access order
    private func updateAccessOrder(for contactId: String) {
        accessOrder.removeAll { $0 == contactId }
        accessOrder.append(contactId)
    }

    /// Cache an image with LRU eviction
    private func cacheImage(_ image: UIImage, for contactId: String) {
        // Evict oldest entries if at capacity
        while cache.count >= maxCacheSize, let oldest = accessOrder.first {
            cache.removeValue(forKey: oldest)
            accessOrder.removeFirst()
        }

        cache[contactId] = image
        accessOrder.append(contactId)
    }
}
