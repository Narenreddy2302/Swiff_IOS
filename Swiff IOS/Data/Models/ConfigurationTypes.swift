//
//  ConfigurationTypes.swift
//  Swiff IOS
//
//  Created by Agent on 1/19/26.
//  Configuration types moved to shared file to avoid actor isolation issues
//

import Foundation

// MARK: - Analytics Configuration

/// Configuration for error analytics
struct AnalyticsConfiguration: Sendable {
    let maxEventsStored: Int
    let retentionDays: Int
    let patternDetectionThreshold: Int
    let enableAutoCleanup: Bool
    let trackUserIDs: Bool
    let trackSessionIDs: Bool

    nonisolated static let `default` = AnalyticsConfiguration(
        maxEventsStored: 10000,
        retentionDays: 30,
        patternDetectionThreshold: 5,
        enableAutoCleanup: true,
        trackUserIDs: true,
        trackSessionIDs: true
    )

    nonisolated static let debug = AnalyticsConfiguration(
        maxEventsStored: 1000,
        retentionDays: 7,
        patternDetectionThreshold: 3,
        enableAutoCleanup: false,
        trackUserIDs: true,
        trackSessionIDs: true
    )

    nonisolated static let production = AnalyticsConfiguration(
        maxEventsStored: 50000,
        retentionDays: 90,
        patternDetectionThreshold: 10,
        enableAutoCleanup: true,
        trackUserIDs: false,
        trackSessionIDs: false
    )
}

// MARK: - Network Retry Configuration

struct NetworkRetryConfiguration: Sendable {
    let maxRetries: Int
    let baseDelay: TimeInterval
    let maxDelay: TimeInterval
    let multiplier: Double

    nonisolated static let `default` = NetworkRetryConfiguration(
        maxRetries: 3,
        baseDelay: 1.0,
        maxDelay: 10.0,
        multiplier: 2.0
    )

    nonisolated static let aggressive = NetworkRetryConfiguration(
        maxRetries: 5,
        baseDelay: 0.5,
        maxDelay: 5.0,
        multiplier: 1.5
    )

    nonisolated static let conservative = NetworkRetryConfiguration(
        maxRetries: 2,
        baseDelay: 2.0,
        maxDelay: 15.0,
        multiplier: 3.0
    )

    nonisolated func delay(forAttempt attempt: Int) -> TimeInterval {
        let delay = baseDelay * pow(multiplier, Double(attempt - 1))
        return min(delay, maxDelay)
    }
}
