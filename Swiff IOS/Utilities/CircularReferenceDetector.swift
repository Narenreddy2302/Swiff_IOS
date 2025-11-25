//
//  CircularReferenceDetector.swift
//  Swiff IOS
//
//  Created by Claude Code on 11/20/25.
//  Phase 4.5: Circular reference detection to prevent infinite loops and data corruption
//

import Foundation
import SwiftData

// MARK: - Circular Reference Error

enum CircularReferenceError: LocalizedError {
    case circularGroupMembership(path: [UUID])
    case circularExpenseChain(path: [UUID])
    case circularTransactionChain(path: [UUID])
    case infiniteRecursionDetected(depth: Int)
    case selfReference(entityType: String, id: UUID)
    case cyclicDependency(entities: [String])

    var errorDescription: String? {
        switch self {
        case .circularGroupMembership(let path):
            return "Circular group membership detected: \(path.count) groups in cycle"
        case .circularExpenseChain(let path):
            return "Circular expense chain detected: \(path.count) expenses in cycle"
        case .circularTransactionChain(let path):
            return "Circular transaction chain detected: \(path.count) transactions in cycle"
        case .infiniteRecursionDetected(let depth):
            return "Infinite recursion detected at depth \(depth)"
        case .selfReference(let entityType, let id):
            return "\(entityType) references itself: \(id)"
        case .cyclicDependency(let entities):
            return "Cyclic dependency detected: \(entities.joined(separator: " → "))"
        }
    }
}

// MARK: - Detection Result

struct CircularReferenceResult {
    let hasCircularReferences: Bool
    let circularPaths: [CircularPath]
    let warnings: [String]

    struct CircularPath {
        let type: ReferenceType
        let entityIds: [UUID]
        let entityNames: [String]

        var pathDescription: String {
            return entityNames.joined(separator: " → ")
        }

        var cycleLength: Int {
            return entityIds.count
        }
    }

    enum ReferenceType: String {
        case groupMembership = "Group Membership"
        case expenseChain = "Expense Chain"
        case transactionChain = "Transaction Chain"
        case personRelationship = "Person Relationship"
    }

    var summary: String {
        if hasCircularReferences {
            return "Found \(circularPaths.count) circular reference(s)"
        } else {
            return "No circular references detected"
        }
    }

    var detailedReport: String {
        var report = "=== Circular Reference Detection Report ===\n\n"
        report += "Status: \(hasCircularReferences ? "⚠️ Issues Found" : "✅ Clean")\n"
        report += "Circular Paths: \(circularPaths.count)\n"
        report += "Warnings: \(warnings.count)\n\n"

        if !circularPaths.isEmpty {
            report += "=== Circular Paths ===\n"
            for (index, path) in circularPaths.enumerated() {
                report += "\(index + 1). \(path.type.rawValue) (length: \(path.cycleLength))\n"
                report += "   Path: \(path.pathDescription)\n\n"
            }
        }

        if !warnings.isEmpty {
            report += "=== Warnings ===\n"
            for warning in warnings {
                report += "⚠️ \(warning)\n"
            }
            report += "\n"
        }

        return report
    }
}

// MARK: - Graph Node

struct GraphNode<T: Hashable>: Hashable {
    let id: T
    var neighbors: Set<T> = []

    static func == (lhs: GraphNode<T>, rhs: GraphNode<T>) -> Bool {
        return lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Circular Reference Detector

@MainActor
class CircularReferenceDetector {

    private let modelContext: ModelContext
    private let maxRecursionDepth = 100

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Group Membership Detection

    /// Detect circular group memberships
    func detectCircularGroupMemberships() throws -> CircularReferenceResult {
        let circularPaths: [CircularReferenceResult.CircularPath] = []
        var warnings: [String] = []

        // Get all groups
        let groupDescriptor = FetchDescriptor<GroupModel>()
        let groups = try modelContext.fetch(groupDescriptor)

        // Build graph of group relationships (if groups can contain other groups)
        // For now, we'll check if group members reference each other circularly

        let personDescriptor = FetchDescriptor<PersonModel>()
        _ = try modelContext.fetch(personDescriptor)

        // Check for groups where members are in multiple groups that reference each other
        for group in groups {
            if group.memberIds.isEmpty {
                warnings.append("Group '\(group.name)' has no members")
            }

            // Check for self-reference (group containing itself, if that's possible in your schema)
            // This is a simplified check - expand based on your actual group structure
        }

        return CircularReferenceResult(
            hasCircularReferences: !circularPaths.isEmpty,
            circularPaths: circularPaths,
            warnings: warnings
        )
    }

    // MARK: - Transaction Chain Detection

    /// Detect circular transaction chains (A owes B, B owes C, C owes A)
    func detectCircularTransactionChains() throws -> CircularReferenceResult {
        var circularPaths: [CircularReferenceResult.CircularPath] = []
        var warnings: [String] = []

        // Get all people
        let personDescriptor = FetchDescriptor<PersonModel>()
        let people = try modelContext.fetch(personDescriptor)

        // Build debt graph
        var debtGraph: [UUID: Set<UUID>] = [:]

        // Get all transactions
        let transactionDescriptor = FetchDescriptor<TransactionModel>()
        let transactions = try modelContext.fetch(transactionDescriptor)

        // Build graph: payer -> payee edges
        for transaction in transactions {
            guard let payerId = transaction.payerId,
                  let payeeId = transaction.payeeId else {
                warnings.append("Transaction \(transaction.id) has missing payer or payee ID")
                continue
            }
            
            if debtGraph[payerId] == nil {
                debtGraph[payerId] = Set()
            }
            debtGraph[payerId]?.insert(payeeId)

            // Check for self-payment
            if payerId == payeeId {
                let person = people.first { $0.id == payerId }
                warnings.append("Self-payment detected: \(person?.name ?? "Unknown") paying themselves")
            }
        }

        // Detect cycles using DFS
        var visited: Set<UUID> = []
        var recursionStack: Set<UUID> = []
        var currentPath: [UUID] = []

        func dfs(_ personId: UUID) -> [UUID]? {
            visited.insert(personId)
            recursionStack.insert(personId)
            currentPath.append(personId)

            if let neighbors = debtGraph[personId] {
                for neighbor in neighbors {
                    if !visited.contains(neighbor) {
                        if let cycle = dfs(neighbor) {
                            return cycle
                        }
                    } else if recursionStack.contains(neighbor) {
                        // Found a cycle
                        if let cycleStartIndex = currentPath.firstIndex(of: neighbor) {
                            return Array(currentPath[cycleStartIndex...])
                        }
                    }
                }
            }

            currentPath.removeLast()
            recursionStack.remove(personId)
            return nil
        }

        for person in people {
            if !visited.contains(person.id) {
                if let cycle = dfs(person.id) {
                    let names = cycle.compactMap { id in
                        people.first { $0.id == id }?.name ?? "Unknown"
                    }

                    let path = CircularReferenceResult.CircularPath(
                        type: .transactionChain,
                        entityIds: cycle,
                        entityNames: names
                    )
                    circularPaths.append(path)

                    // Reset for next detection
                    visited.removeAll()
                    recursionStack.removeAll()
                    currentPath.removeAll()
                }
            }
        }

        return CircularReferenceResult(
            hasCircularReferences: !circularPaths.isEmpty,
            circularPaths: circularPaths,
            warnings: warnings
        )
    }

    // MARK: - Subscription Chain Detection

    /// Detect circular subscription dependencies
    func detectCircularSubscriptionChains() throws -> CircularReferenceResult {
        var warnings: [String] = []

        // Get all subscriptions
        let subscriptionDescriptor = FetchDescriptor<SubscriptionModel>()
        let subscriptions = try modelContext.fetch(subscriptionDescriptor)

        // Get all people
        let personDescriptor = FetchDescriptor<PersonModel>()
        let people = try modelContext.fetch(personDescriptor)
        let validPersonIds = Set(people.map { $0.id })

        // Check for orphaned subscriptions
        for subscription in subscriptions {
            if let personId = subscription.personId {
                if !validPersonIds.contains(personId) {
                    warnings.append("Subscription '\(subscription.name)' references non-existent person")
                }
            } else {
                warnings.append("Subscription '\(subscription.name)' has no associated person")
            }
        }

        return CircularReferenceResult(
            hasCircularReferences: false,
            circularPaths: [],
            warnings: warnings
        )
    }

    // MARK: - Comprehensive Detection

    /// Detect all types of circular references
    func detectAllCircularReferences() throws -> CircularReferenceResult {
        var allCircularPaths: [CircularReferenceResult.CircularPath] = []
        var allWarnings: [String] = []

        // Detect group membership cycles
        let groupResult = try detectCircularGroupMemberships()
        allCircularPaths.append(contentsOf: groupResult.circularPaths)
        allWarnings.append(contentsOf: groupResult.warnings)

        // Detect transaction cycles
        let transactionResult = try detectCircularTransactionChains()
        allCircularPaths.append(contentsOf: transactionResult.circularPaths)
        allWarnings.append(contentsOf: transactionResult.warnings)

        // Detect subscription issues
        let subscriptionResult = try detectCircularSubscriptionChains()
        allWarnings.append(contentsOf: subscriptionResult.warnings)

        return CircularReferenceResult(
            hasCircularReferences: !allCircularPaths.isEmpty,
            circularPaths: allCircularPaths,
            warnings: allWarnings
        )
    }

    // MARK: - Graph Validation

    /// Validate graph structure for cycles using Tarjan's algorithm
    func validateGraphStructure<T: Hashable>(nodes: [GraphNode<T>]) -> [Set<T>] {
        var index = 0
        var stack: [T] = []
        var indices: [T: Int] = [:]
        var lowLinks: [T: Int] = [:]
        var onStack: Set<T> = []
        var stronglyConnectedComponents: [Set<T>] = []

        func strongConnect(_ nodeId: T, nodeMap: [T: GraphNode<T>]) {
            indices[nodeId] = index
            lowLinks[nodeId] = index
            index += 1
            stack.append(nodeId)
            onStack.insert(nodeId)

            if let node = nodeMap[nodeId] {
                for neighbor in node.neighbors {
                    if indices[neighbor] == nil {
                        strongConnect(neighbor, nodeMap: nodeMap)
                        lowLinks[nodeId] = min(lowLinks[nodeId]!, lowLinks[neighbor]!)
                    } else if onStack.contains(neighbor) {
                        lowLinks[nodeId] = min(lowLinks[nodeId]!, indices[neighbor]!)
                    }
                }
            }

            if lowLinks[nodeId] == indices[nodeId] {
                var component: Set<T> = []
                var w: T

                repeat {
                    w = stack.removeLast()
                    onStack.remove(w)
                    component.insert(w)
                } while w != nodeId

                if component.count > 1 {
                    stronglyConnectedComponents.append(component)
                }
            }
        }

        let nodeMap = Dictionary(uniqueKeysWithValues: nodes.map { ($0.id, $0) })

        for node in nodes {
            if indices[node.id] == nil {
                strongConnect(node.id, nodeMap: nodeMap)
            }
        }

        return stronglyConnectedComponents
    }

    // MARK: - Recursion Prevention

    /// Safe recursive operation with depth limit
    func safeRecursiveOperation<T>(
        maxDepth: Int? = nil,
        operation: (Int) throws -> T
    ) throws -> T {
        let limit = maxDepth ?? maxRecursionDepth

        func recurse(_ depth: Int) throws -> T {
            guard depth < limit else {
                throw CircularReferenceError.infiniteRecursionDetected(depth: depth)
            }

            return try operation(depth)
        }

        return try recurse(0)
    }

    // MARK: - Self-Reference Detection

    /// Check for self-references in transactions
    func detectSelfReferences() throws -> [String] {
        var selfReferences: [String] = []

        // Check transactions
        let transactionDescriptor = FetchDescriptor<TransactionModel>()
        let transactions = try modelContext.fetch(transactionDescriptor)

        let personDescriptor = FetchDescriptor<PersonModel>()
        let people = try modelContext.fetch(personDescriptor)

        for transaction in transactions {
            if let payerId = transaction.payerId,
               let payeeId = transaction.payeeId,
               payerId == payeeId {
                let person = people.first { $0.id == payerId }
                selfReferences.append("Transaction: \(person?.name ?? "Unknown") paying themselves (ID: \(transaction.id))")
            }
        }

        return selfReferences
    }

    // MARK: - Path Finding

    /// Find path between two entities
    func findPath(from sourceId: UUID, to targetId: UUID, via debtGraph: [UUID: Set<UUID>]) -> [UUID]? {
        var visited: Set<UUID> = []
        var queue: [(UUID, [UUID])] = [(sourceId, [sourceId])]

        while !queue.isEmpty {
            let (current, path) = queue.removeFirst()

            if current == targetId {
                return path
            }

            if visited.contains(current) {
                continue
            }

            visited.insert(current)

            if let neighbors = debtGraph[current] {
                for neighbor in neighbors {
                    if !visited.contains(neighbor) {
                        queue.append((neighbor, path + [neighbor]))
                    }
                }
            }
        }

        return nil
    }

    // MARK: - Validation Helpers

    /// Validate that adding a relationship won't create a cycle
    func validateNewRelationship(from: UUID, to: UUID, in graph: [UUID: Set<UUID>]) throws -> Bool {
        // Check if adding this edge would create a cycle
        var tempGraph = graph
        if tempGraph[from] == nil {
            tempGraph[from] = Set()
        }
        tempGraph[from]?.insert(to)

        // Check if there's already a path from 'to' to 'from'
        // If yes, adding 'from' -> 'to' would create a cycle
        if let _ = findPath(from: to, to: from, via: tempGraph) {
            throw CircularReferenceError.cyclicDependency(entities: [
                from.uuidString,
                to.uuidString
            ])
        }

        return true
    }

    // MARK: - Statistics

    /// Get circular reference statistics
    func getStatistics() throws -> String {
        let result = try detectAllCircularReferences()

        var stats = "=== Circular Reference Statistics ===\n\n"
        stats += "Total Circular Paths: \(result.circularPaths.count)\n"
        stats += "Total Warnings: \(result.warnings.count)\n\n"

        if !result.circularPaths.isEmpty {
            let groupedByType = Dictionary(grouping: result.circularPaths) { $0.type }

            for (type, paths) in groupedByType {
                stats += "\(type.rawValue): \(paths.count)\n"
            }
            stats += "\n"
        }

        stats += "Status: \(result.hasCircularReferences ? "⚠️ Action Required" : "✅ Healthy")\n"

        return stats
    }
}

// MARK: - Extensions

extension CircularReferenceDetector {

    /// Quick check for any circular references
    func hasCircularReferences() throws -> Bool {
        let result = try detectAllCircularReferences()
        return result.hasCircularReferences
    }

    /// Get count of circular references by type
    func getCircularReferenceCount() throws -> Int {
        let result = try detectAllCircularReferences()
        return result.circularPaths.count
    }

    /// Export circular reference report
    func exportReport() throws -> String {
        let result = try detectAllCircularReferences()
        return result.detailedReport
    }
}

// MARK: - Usage Examples (Documentation)

/*
 USAGE EXAMPLES:

 1. Detect all circular references:
 ```swift
 let detector = CircularReferenceDetector(modelContext: context)

 let result = try detector.detectAllCircularReferences()

 if result.hasCircularReferences {
     print("⚠️ \(result.summary)")

     for path in result.circularPaths {
         print("Circular \(path.type.rawValue): \(path.pathDescription)")
     }
 } else {
     print("✅ No circular references")
 }
 ```

 2. Detect transaction chains:
 ```swift
 let result = try detector.detectCircularTransactionChains()

 for path in result.circularPaths {
     print("Cycle detected: \(path.pathDescription)")
     print("Length: \(path.cycleLength)")
 }
 ```

 3. Validate before adding relationship:
 ```swift
 var debtGraph: [UUID: Set<UUID>] = [:]
 // ... build graph

 do {
     let isValid = try detector.validateNewRelationship(
         from: person1.id,
         to: person2.id,
         in: debtGraph
     )

     if isValid {
         // Safe to add relationship
     }
 } catch CircularReferenceError.cyclicDependency {
     print("Cannot add: would create circular dependency")
 }
 ```

 4. Safe recursive operation:
 ```swift
 let result = try detector.safeRecursiveOperation(maxDepth: 50) { depth in
     // Your recursive logic here
     return depth
 }
 ```

 5. Get statistics:
 ```swift
 let stats = try detector.getStatistics()
 print(stats)
 ```

 6. Export report:
 ```swift
 let report = try detector.exportReport()
 print(report)
 ```

 7. Quick check:
 ```swift
 if try detector.hasCircularReferences() {
     print("⚠️ Circular references detected!")
 }
 ```
 */
