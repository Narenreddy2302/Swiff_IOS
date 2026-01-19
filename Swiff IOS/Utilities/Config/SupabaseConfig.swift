//
//  SupabaseConfig.swift
//  Swiff IOS
//
//  Supabase configuration constants
//

import Foundation

/// Configuration for Supabase connection
enum SupabaseConfig {
    /// Supabase project URL
    static let projectURL = URL(string: "https://mdlkygfocthsqwtbsvie.supabase.co")!

    /// Supabase publishable/anon API key
    /// This key is safe to use in client apps with RLS enabled
    static let apiKey = "sb_publishable_x7XOU4NnHIvEkvMhItx1dg_9mHt-R-q"

    /// Database table names
    enum Tables {
        static let userProfiles = "user_profiles"
        static let persons = "persons"
        static let accounts = "accounts"
        static let groups = "groups"
        static let groupMembers = "group_members"
        static let groupExpenses = "group_expenses"
        static let subscriptions = "subscriptions"
        static let sharedSubscriptions = "shared_subscriptions"
        static let priceChanges = "price_changes"
        static let subscriptionEvents = "subscription_events"
        static let transactions = "transactions"
        static let splitBills = "split_bills"
        static let splitParticipants = "split_participants"
        static let invitations = "invitations"
    }

    /// Sync configuration
    enum Sync {
        /// Maximum number of retries for failed sync operations
        static let maxRetries = 3

        /// Delay between retries (in seconds)
        static let retryDelay: TimeInterval = 2.0

        /// Batch size for bulk sync operations
        static let batchSize = 50

        /// Timeout for sync operations (in seconds)
        static let timeout: TimeInterval = 30.0
    }

    /// Auth configuration
    enum Auth {
        /// Redirect URL for OAuth (if needed in future)
        static let redirectURL = URL(string: "swiff://auth/callback")!

        /// Session expiry buffer (refresh token this many seconds before expiry)
        static let sessionExpiryBuffer: TimeInterval = 300 // 5 minutes
    }
}
