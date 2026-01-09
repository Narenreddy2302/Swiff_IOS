//
//  SupabaseService.swift
//  Swiff IOS
//
//  Main Supabase client service for database operations
//

import Foundation
import Supabase
import Combine

/// Main service for interacting with Supabase
@MainActor
final class SupabaseService: ObservableObject {

    // MARK: - Singleton

    static let shared = SupabaseService()

    // MARK: - Published Properties

    @Published private(set) var isInitialized = false
    @Published private(set) var isConnected = false
    @Published private(set) var currentUser: User?
    @Published private(set) var error: SupabaseError?

    // MARK: - Properties

    /// The Supabase client instance
    let client: SupabaseClient

    /// Auth state change subscription
    private var authStateTask: Task<Void, Never>?

    /// Realtime channels
    private var realtimeChannels: [String: RealtimeChannelV2] = [:]

    /// Cancellables for Combine subscriptions
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    private init() {
        // Initialize the Supabase client with new session emission behavior
        self.client = SupabaseClient(
            supabaseURL: SupabaseConfig.projectURL,
            supabaseKey: SupabaseConfig.apiKey,
            options: .init(
                auth: .init(
                    emitLocalSessionAsInitialSession: true
                )
            )
        )

        // Start listening to auth state changes
        setupAuthStateListener()

        isInitialized = true
    }

    // MARK: - Auth State

    private func setupAuthStateListener() {
        authStateTask = Task {
            for await (event, session) in client.auth.authStateChanges {
                await MainActor.run {
                    switch event {
                    case .initialSession:
                        self.currentUser = session?.user
                        self.isConnected = session != nil
                    case .signedIn:
                        self.currentUser = session?.user
                        self.isConnected = true
                    case .signedOut:
                        self.currentUser = nil
                        self.isConnected = false
                    case .tokenRefreshed:
                        self.currentUser = session?.user
                    case .userUpdated:
                        self.currentUser = session?.user
                    case .userDeleted:
                        self.currentUser = nil
                        self.isConnected = false
                    case .passwordRecovery:
                        break
                    case .mfaChallengeVerified:
                        break
                    }
                }
            }
        }
    }

    // MARK: - Database Operations

    /// Fetch all records from a table
    func fetchAll<T: Decodable>(
        from table: String,
        filter: ((PostgrestFilterBuilder) -> PostgrestFilterBuilder)? = nil
    ) async throws -> [T] {
        var query = client.from(table).select()

        if let filter = filter {
            query = filter(query)
        }

        let response: [T] = try await query.execute().value
        return response
    }

    /// Fetch a single record by ID
    func fetchOne<T: Decodable>(
        from table: String,
        id: UUID
    ) async throws -> T? {
        let response: [T] = try await client.from(table)
            .select()
            .eq("id", value: id.uuidString)
            .limit(1)
            .execute()
            .value

        return response.first
    }

    /// Insert a new record
    func insert<T: Encodable>(
        into table: String,
        record: T
    ) async throws {
        try await client.from(table)
            .insert(record)
            .execute()
    }

    /// Insert multiple records
    func insertBatch<T: Encodable>(
        into table: String,
        records: [T]
    ) async throws {
        try await client.from(table)
            .insert(records)
            .execute()
    }

    /// Update a record
    func update<T: Encodable>(
        table: String,
        id: UUID,
        record: T
    ) async throws {
        try await client.from(table)
            .update(record)
            .eq("id", value: id.uuidString)
            .execute()
    }

    /// Soft delete a record (set deleted_at)
    func softDelete(
        from table: String,
        id: UUID
    ) async throws {
        try await client.from(table)
            .update(["deleted_at": ISO8601DateFormatter().string(from: Date())])
            .eq("id", value: id.uuidString)
            .execute()
    }

    /// Hard delete a record
    func hardDelete(
        from table: String,
        id: UUID
    ) async throws {
        try await client.from(table)
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }

    /// Upsert (insert or update) a record
    func upsert<T: Encodable>(
        into table: String,
        record: T,
        onConflict: String = "id"
    ) async throws {
        try await client.from(table)
            .upsert(record, onConflict: onConflict)
            .execute()
    }

    /// Upsert multiple records
    func upsertBatch<T: Encodable>(
        into table: String,
        records: [T],
        onConflict: String = "id"
    ) async throws {
        try await client.from(table)
            .upsert(records, onConflict: onConflict)
            .execute()
    }

    // MARK: - Realtime

    /// Subscribe to realtime changes on a table
    func subscribeToTable(
        _ table: String,
        filter: String? = nil,
        onChange: @escaping (RealtimeMessage) -> Void
    ) async throws {
        let channelName = filter != nil ? "\(table):\(filter!)" : table

        // Remove existing channel if any
        if let existingChannel = realtimeChannels[channelName] {
            await existingChannel.unsubscribe()
            realtimeChannels.removeValue(forKey: channelName)
        }

        let channel = client.realtimeV2.channel(channelName)

        let changes = channel.postgresChange(
            AnyAction.self,
            schema: "public",
            table: table
        )

        try await channel.subscribeWithError()

        realtimeChannels[channelName] = channel

        // Listen for changes
        Task {
            for await change in changes {
                await MainActor.run {
                    let message = RealtimeMessage(
                        table: table,
                        eventType: extractString(from: change.rawMessage.payload["type"]) ?? "unknown",
                        newRecord: extractDictionary(from: change.rawMessage.payload["new"]),
                        oldRecord: extractDictionary(from: change.rawMessage.payload["old"])
                    )
                    onChange(message)
                }
            }
        }
    }

    // MARK: - AnyJSON Helpers

    /// Extract string from AnyJSON
    private func extractString(from json: AnyJSON?) -> String? {
        guard let json = json else { return nil }
        switch json {
        case .string(let value):
            return value
        default:
            return nil
        }
    }

    /// Extract dictionary from AnyJSON
    private func extractDictionary(from json: AnyJSON?) -> [String: Any]? {
        guard let json = json else { return nil }
        switch json {
        case .object(let dict):
            return dict.mapValues { convertAnyJSON($0) }
        default:
            return nil
        }
    }

    /// Convert AnyJSON to Any for general use
    private func convertAnyJSON(_ json: AnyJSON) -> Any {
        switch json {
        case .string(let value):
            return value
        case .double(let value):
            return value
        case .integer(let value):
            return value
        case .bool(let value):
            return value
        case .null:
            return NSNull()
        case .array(let arr):
            return arr.map { convertAnyJSON($0) }
        case .object(let dict):
            return dict.mapValues { convertAnyJSON($0) }
        }
    }

    /// Unsubscribe from a table
    func unsubscribeFromTable(_ table: String, filter: String? = nil) async {
        let channelName = filter != nil ? "\(table):\(filter!)" : table

        if let channel = realtimeChannels[channelName] {
            await channel.unsubscribe()
            realtimeChannels.removeValue(forKey: channelName)
        }
    }

    /// Unsubscribe from all tables
    func unsubscribeAll() async {
        for (_, channel) in realtimeChannels {
            await channel.unsubscribe()
        }
        realtimeChannels.removeAll()
    }

    // MARK: - Sync Helpers

    /// Fetch records modified after a specific date
    func fetchModifiedSince<T: Decodable>(
        from table: String,
        since: Date,
        includeDeleted: Bool = true
    ) async throws -> [T] {
        let dateString = ISO8601DateFormatter().string(from: since)

        var query = client.from(table)
            .select()
            .gte("updated_at", value: dateString)

        if !includeDeleted {
            query = query.is("deleted_at", value: nil)
        }

        let response: [T] = try await query.execute().value
        return response
    }

    /// Get the server timestamp
    func getServerTime() async throws -> Date {
        // Use a simple query to get server time
        _ = try await client.rpc("now").execute()
        // Parse the response to get the timestamp
        // For now, return local time as fallback
        return Date()
    }

    // MARK: - User Specific Queries

    /// Fetch all records for the current user
    func fetchUserRecords<T: Decodable>(
        from table: String,
        additionalFilter: ((PostgrestFilterBuilder) -> PostgrestFilterBuilder)? = nil
    ) async throws -> [T] {
        guard let userId = currentUser?.id else {
            throw SupabaseError.notAuthenticated
        }

        var query = client.from(table)
            .select()
            .eq("user_id", value: userId.uuidString)
            .is("deleted_at", value: nil)

        if let additionalFilter = additionalFilter {
            query = additionalFilter(query)
        }

        let response: [T] = try await query.execute().value
        return response
    }

    // MARK: - Cleanup

    func cleanup() async {
        authStateTask?.cancel()
        await unsubscribeAll()
    }

    deinit {
        authStateTask?.cancel()
    }
}

// MARK: - Supporting Types

/// Custom error types for Supabase operations
enum SupabaseError: LocalizedError {
    case notAuthenticated
    case networkError(Error)
    case decodingError(Error)
    case serverError(String)
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "User is not authenticated"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .serverError(let message):
            return "Server error: \(message)"
        case .unknown(let message):
            return "Unknown error: \(message)"
        }
    }
}

/// Realtime message wrapper
struct RealtimeMessage {
    let table: String
    let eventType: String
    let newRecord: [String: Any]?
    let oldRecord: [String: Any]?

    var isInsert: Bool { eventType == "INSERT" }
    var isUpdate: Bool { eventType == "UPDATE" }
    var isDelete: Bool { eventType == "DELETE" }
}
