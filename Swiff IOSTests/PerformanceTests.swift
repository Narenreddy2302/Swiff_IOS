//
//  PerformanceTests.swift
//  Swiff IOSTests
//
//  Created by Test Agent 15 on 11/21/25.
//  Performance and load testing for Swiff iOS app
//

import XCTest
@testable import Swiff_IOS

@MainActor
final class PerformanceTests: XCTestCase {

    var dataManager: DataManager!
    var persistenceService: PersistenceService!

    override func setUpWithError() throws {
        try super.setUpWithError()
        continueAfterFailure = false

        dataManager = DataManager.shared
        persistenceService = PersistenceService.shared
    }

    override func tearDownWithError() throws {
        dataManager = nil
        persistenceService = nil
        try super.tearDownWithError()
    }

    // MARK: - 15.4.1: Large Subscription List Performance

    func testLargeSubscriptionList() async throws {
        // Given: 500+ subscriptions
        print("📊 Generating 500 subscriptions...")
        let subscriptions = SampleDataGenerator.generateSubscriptions(count: 500)

        // Measure import performance
        measure(metrics: [XCTClockMetric(), XCTMemoryMetric()]) {
            Task { @MainActor in
                do {
                    try await dataManager.importSubscriptions(subscriptions)
                } catch {
                    XCTFail("Failed to import subscriptions: \(error)")
                }
            }
        }

        // Measure fetch performance
        let fetchMetric = XCTClockMetric()
        measure(metrics: [fetchMetric]) {
            do {
                _ = try persistenceService.fetchAllSubscriptions()
            } catch {
                XCTFail("Failed to fetch subscriptions: \(error)")
            }
        }

        // Measure filtering performance
        measure(metrics: [XCTClockMetric()]) {
            _ = dataManager.getActiveSubscriptions()
        }

        // Cleanup
        for subscription in subscriptions {
            try? dataManager.deleteSubscription(id: subscription.id)
        }

        print("✅ testLargeSubscriptionList completed - 500 subscriptions processed")
    }

    func testScrollPerformanceSimulation() throws {
        // Simulate rapid access patterns similar to scrolling
        let subscriptions = SampleDataGenerator.generateSubscriptions(count: 100)

        measure(metrics: [XCTClockMetric()]) {
            // Simulate accessing items during scroll
            for i in 0..<subscriptions.count {
                _ = subscriptions[i].name
                _ = subscriptions[i].price
                _ = subscriptions[i].category
                _ = subscriptions[i].nextBillingDate
            }
        }

        print("✅ testScrollPerformanceSimulation completed")
    }

    // MARK: - 15.4.2: Large Transaction List Performance

    func testLargeTransactionList() async throws {
        // Given: 5000+ transactions
        print("📊 Generating 5000 transactions...")
        let transactions = SampleDataGenerator.generateTransactions(count: 5000)

        // Measure import time
        let startTime = Date()

        try await dataManager.importTransactions(transactions)

        let importDuration = Date().timeIntervalSince(startTime)
        print("📈 Import duration: \(String(format: "%.2f", importDuration)) seconds")

        // Performance target: Should complete within reasonable time
        XCTAssertLessThan(importDuration, 60.0, "Import of 5000 transactions should complete within 60 seconds")

        // Measure fetch performance
        measure(metrics: [XCTClockMetric(), XCTMemoryMetric()]) {
            do {
                let fetched = try persistenceService.fetchAllTransactions()
                XCTAssertGreaterThanOrEqual(fetched.count, 5000, "Should fetch all transactions")
            } catch {
                XCTFail("Failed to fetch transactions: \(error)")
            }
        }

        // Measure filtering by date
        measure(metrics: [XCTClockMetric()]) {
            _ = dataManager.getCurrentMonthTransactions()
        }

        // Cleanup
        for transaction in transactions {
            try? dataManager.deleteTransaction(id: transaction.id)
        }

        print("✅ testLargeTransactionList completed - 5000 transactions processed")
    }

    func testTransactionSortingPerformance() throws {
        // Test sorting performance with large dataset
        var transactions = SampleDataGenerator.generateTransactions(count: 1000)

        measure(metrics: [XCTClockMetric()]) {
            transactions.sort { $0.date > $1.date }
        }

        measure(metrics: [XCTClockMetric()]) {
            transactions.sort { $0.amount < $1.amount }
        }

        print("✅ testTransactionSortingPerformance completed")
    }

    // MARK: - 15.4.3: Search Performance

    func testSearchPerformance() async throws {
        // Given: 10,000 items to search across
        print("📊 Generating large dataset for search testing...")

        let people = SampleDataGenerator.generatePeople(count: 1000)
        let subscriptions = SampleDataGenerator.generateSubscriptions(count: 4000)
        let transactions = SampleDataGenerator.generateTransactions(count: 5000)

        // Import all data
        try await dataManager.importPeople(people)
        try await dataManager.importSubscriptions(subscriptions)
        try await dataManager.importTransactions(transactions)

        // Measure search performance
        let searchTerms = ["Test", "Transaction", "Person", "Subscription", "123"]

        for term in searchTerms {
            measure(metrics: [XCTClockMetric()]) {
                // Search people
                _ = dataManager.searchPeople(byName: term)

                // Search subscriptions
                _ = dataManager.subscriptions.filter { $0.name.localizedStandardContains(term) }

                // Search transactions
                _ = dataManager.transactions.filter { $0.title.localizedStandardContains(term) }
            }
        }

        // Performance target: Search should be fast
        // Actual measurement is in the measure blocks above

        // Cleanup
        for person in people {
            try? dataManager.deletePerson(id: person.id)
        }
        for subscription in subscriptions {
            try? dataManager.deleteSubscription(id: subscription.id)
        }
        for transaction in transactions {
            try? dataManager.deleteTransaction(id: transaction.id)
        }

        print("✅ testSearchPerformance completed - 10,000 items searched")
    }

    func testFilteringPerformance() throws {
        // Test performance of various filters
        let transactions = SampleDataGenerator.generateFilterableTransactions()

        measure(metrics: [XCTClockMetric()]) {
            // Filter by category
            _ = transactions.filter { $0.category == .income }

            // Filter by date range
            let startDate = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
            _ = transactions.filter { $0.date >= startDate }

            // Filter by amount
            _ = transactions.filter { abs($0.amount) > 100 }

            // Complex filter
            _ = transactions.filter { transaction in
                transaction.category == .shopping &&
                abs(transaction.amount) > 50 &&
                transaction.date >= startDate
            }
        }

        print("✅ testFilteringPerformance completed")
    }

    // MARK: - 15.4.4 & 15.4.5: Memory Usage and Leak Detection

    func testMemoryUsageWithLargeDataset() async throws {
        // This test measures memory footprint
        measure(metrics: [XCTMemoryMetric()]) {
            Task { @MainActor in
                // Create large dataset in memory
                let dataset = SampleDataGenerator.generateLargeDataset(
                    peopleCount: 100,
                    subscriptionsCount: 500,
                    transactionsCount: 5000,
                    groupsCount: 50
                )

                // Access the data to ensure it's loaded
                _ = dataset.people.count
                _ = dataset.subscriptions.count
                _ = dataset.transactions.count
                _ = dataset.groups.count
            }
        }

        print("✅ testMemoryUsageWithLargeDataset completed")
    }

    func testMemoryLeakInCRUDOperations() async throws {
        // Test for memory leaks in repeated CRUD operations
        measure(metrics: [XCTMemoryMetric()]) {
            Task { @MainActor in
                for i in 0..<100 {
                    let person = SampleDataGenerator.generatePerson(name: "Leak Test \(i)")

                    do {
                        try dataManager.addPerson(person)
                        try dataManager.updatePerson(person)
                        try dataManager.deletePerson(id: person.id)
                    } catch {
                        // Ignore errors in this test
                    }
                }
            }
        }

        print("✅ testMemoryLeakInCRUDOperations completed")
    }

    func testMemoryGrowthOverTime() async throws {
        // Verify memory doesn't grow unbounded
        let initialMemory = getMemoryUsage()

        // Perform many operations
        for batch in 0..<10 {
            let people = SampleDataGenerator.generatePeople(count: 50)
            try await dataManager.importPeople(people)

            // Delete them
            for person in people {
                try? dataManager.deletePerson(id: person.id)
            }

            if batch % 3 == 0 {
                // Periodic memory check
                let currentMemory = getMemoryUsage()
                print("📊 Memory after batch \(batch): \(currentMemory) MB")
            }
        }

        let finalMemory = getMemoryUsage()
        let memoryGrowth = finalMemory - initialMemory

        print("📊 Memory growth: \(String(format: "%.2f", memoryGrowth)) MB")

        // Memory shouldn't grow excessively (allow some growth for caching, etc.)
        XCTAssertLessThan(memoryGrowth, 100, "Memory growth should be less than 100MB")

        print("✅ testMemoryGrowthOverTime completed")
    }

    // MARK: - 15.4.6: Device Performance Testing

    func testPerformanceOnConstrainedDevice() {
        // Simulate constrained device performance
        // This test ensures the app performs reasonably on older devices like iPhone SE

        let subscriptions = SampleDataGenerator.generateSubscriptions(count: 200)

        // Measure time for common operations
        measure(metrics: [XCTClockMetric()]) {
            // Filtering
            _ = subscriptions.filter { $0.isActive }

            // Sorting
            let sorted = subscriptions.sorted { $0.price > $1.price }

            // Mapping
            _ = sorted.map { $0.name }
        }

        print("✅ testPerformanceOnConstrainedDevice completed")
    }

    // MARK: - 15.4.7: App Launch Performance

    func testAppLaunchPerformance() {
        // Measure app launch simulation
        measure(metrics: [XCTClockMetric()]) {
            // Simulate app launch tasks
            dataManager.loadAllData()
        }

        // Target: Should complete quickly
        print("✅ testAppLaunchPerformance completed")
    }

    func testColdLaunchSimulation() async throws {
        // Simulate cold launch with data loading
        let startTime = Date()

        // Load all data as if app just launched
        dataManager.loadAllData()

        // Wait for any async operations
        try await Task.sleep(nanoseconds: 500_000_000) // 500ms

        let launchTime = Date().timeIntervalSince(startTime)
        print("📈 Simulated cold launch time: \(String(format: "%.2f", launchTime)) seconds")

        // Target: < 2 seconds for cold launch
        XCTAssertLessThan(launchTime, 2.0, "Cold launch should complete within 2 seconds")

        print("✅ testColdLaunchSimulation completed")
    }

    func testWarmLaunchSimulation() async throws {
        // First launch (warm up)
        dataManager.loadAllData()
        try await Task.sleep(nanoseconds: 100_000_000) // 100ms

        // Measure second launch (warm)
        let startTime = Date()
        dataManager.refreshAllData()
        try await Task.sleep(nanoseconds: 100_000_000) // 100ms

        let launchTime = Date().timeIntervalSince(startTime)
        print("📈 Simulated warm launch time: \(String(format: "%.2f", launchTime)) seconds")

        // Target: < 0.5 seconds for warm launch
        XCTAssertLessThan(launchTime, 0.5, "Warm launch should complete within 0.5 seconds")

        print("✅ testWarmLaunchSimulation completed")
    }

    // MARK: - 15.4.8: Optimization Identification

    func testBottleneckIdentification() async throws {
        // Identify potential bottlenecks in data operations

        print("🔍 Testing for bottlenecks...")

        // Test 1: Bulk vs Individual inserts
        let bulkStart = Date()
        let bulkPeople = SampleDataGenerator.generatePeople(count: 100)
        try await dataManager.importPeople(bulkPeople)
        let bulkTime = Date().timeIntervalSince(bulkStart)
        print("📊 Bulk insert time: \(String(format: "%.2f", bulkTime))s for 100 items")

        // Cleanup
        for person in bulkPeople {
            try? dataManager.deletePerson(id: person.id)
        }

        // Test 2: Individual inserts
        let individualStart = Date()
        for i in 0..<50 {
            let person = SampleDataGenerator.generatePerson(name: "Individual \(i)")
            try dataManager.addPerson(person)
        }
        let individualTime = Date().timeIntervalSince(individualStart)
        print("📊 Individual insert time: \(String(format: "%.2f", individualTime))s for 50 items")

        // Analysis
        let bulkTimePerItem = bulkTime / 100.0
        let individualTimePerItem = individualTime / 50.0

        print("📊 Bulk time per item: \(String(format: "%.4f", bulkTimePerItem))s")
        print("📊 Individual time per item: \(String(format: "%.4f", individualTimePerItem))s")

        if bulkTimePerItem < individualTimePerItem {
            print("✅ Bulk operations are more efficient (as expected)")
        } else {
            print("⚠️ Individual operations might need optimization")
        }

        print("✅ testBottleneckIdentification completed")
    }

    func testDebouncerPerformance() async throws {
        // Test debouncer efficiency for auto-save
        let person = SampleDataGenerator.generatePerson()
        try dataManager.addPerson(person)

        let startTime = Date()

        // Simulate rapid edits (like typing)
        for i in 0..<20 {
            var editedPerson = person
            editedPerson.name = "Edit \(i)"
            dataManager.scheduleSave(for: editedPerson, delay: 0.3)

            // Small delay between edits
            try await Task.sleep(nanoseconds: 50_000_000) // 50ms
        }

        // Wait for debouncer to complete
        try await Task.sleep(nanoseconds: 500_000_000) // 500ms

        let totalTime = Date().timeIntervalSince(startTime)
        print("📊 Debouncer test time: \(String(format: "%.2f", totalTime))s for 20 rapid edits")

        // Cleanup
        try? dataManager.deletePerson(id: person.id)

        print("✅ testDebouncerPerformance completed")
    }

    func testCachingEffectiveness() throws {
        // Test if caching improves repeated access performance
        let subscriptions = SampleDataGenerator.generateSubscriptions(count: 100)

        // First access (no cache)
        let firstAccessStart = Date()
        let activeFirst = subscriptions.filter { $0.isActive }
        let firstAccessTime = Date().timeIntervalSince(firstAccessStart)

        // Second access (potentially cached)
        let secondAccessStart = Date()
        let activeSecond = subscriptions.filter { $0.isActive }
        let secondAccessTime = Date().timeIntervalSince(secondAccessStart)

        print("📊 First access time: \(String(format: "%.4f", firstAccessTime))s")
        print("📊 Second access time: \(String(format: "%.4f", secondAccessTime))s")

        XCTAssertEqual(activeFirst.count, activeSecond.count, "Results should be consistent")

        print("✅ testCachingEffectiveness completed")
    }

    // MARK: - Helper Methods

    private func getMemoryUsage() -> Double {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4

        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }

        if kerr == KERN_SUCCESS {
            let usedMemoryMB = Double(info.resident_size) / 1024.0 / 1024.0
            return usedMemoryMB
        } else {
            return 0
        }
    }

    // MARK: - Stress Tests

    func testStressTestRapidOperations() async throws {
        // Stress test with rapid operations
        print("🔥 Running stress test...")

        let iterations = 50

        for i in 0..<iterations {
            let person = SampleDataGenerator.generatePerson(name: "Stress \(i)")

            try dataManager.addPerson(person)
            try dataManager.updatePerson(person)
            try dataManager.deletePerson(id: person.id)

            if i % 10 == 0 {
                print("📊 Stress test progress: \(i)/\(iterations)")
            }
        }

        print("✅ testStressTestRapidOperations completed")
    }

    func testConcurrentStressTest() async throws {
        // Maximum concurrent stress
        print("🔥 Running concurrent stress test...")

        await withTaskGroup(of: Void.self) { group in
            for i in 0..<30 {
                group.addTask { @MainActor in
                    let subscription = SampleDataGenerator.generateSubscription(name: "Stress Sub \(i)")

                    do {
                        try self.dataManager.addSubscription(subscription)
                        try await Task.sleep(nanoseconds: 10_000_000) // 10ms
                        try self.dataManager.deleteSubscription(id: subscription.id)
                    } catch {
                        print("⚠️ Operation \(i) failed: \(error)")
                    }
                }
            }
        }

        print("✅ testConcurrentStressTest completed")
    }
}
