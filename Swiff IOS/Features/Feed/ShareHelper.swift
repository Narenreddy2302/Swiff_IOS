//
//  ShareHelper.swift
//  Swiff IOS
//
//  Helper for sharing transactions via system share sheet
//  Created: 2026-02-04
//

import SwiftUI
import UIKit

// MARK: - Share Helper

/// Utility class for sharing content via iOS share sheet
struct ShareHelper {
    
    /// Share a transaction summary
    static func shareTransaction(_ transaction: FeedTransaction) {
        let text = generateShareText(for: transaction)
        share(items: [text])
    }
    
    /// Generate shareable text for a transaction
    private static func generateShareText(for transaction: FeedTransaction) -> String {
        var text = ""
        
        // Header
        if transaction.balanceType == .youOwe {
            text += "💸 I owe \(transaction.personName) \(transaction.formattedAmount)"
        } else if transaction.balanceType == .theyOwe {
            text += "💰 \(transaction.personName) owes me \(transaction.formattedAmount)"
        } else {
            text += "✅ Settled: \(transaction.formattedAmount) with \(transaction.personName)"
        }
        
        // Description
        if !transaction.description.isEmpty {
            text += "\n\n\(transaction.description)"
        }
        
        // Category
        text += "\n📁 \(transaction.category)"
        
        // Split info
        if !transaction.participants.isEmpty {
            text += "\n👥 Split with \(transaction.participants.count) people"
        }
        
        // Footer
        text += "\n\n— Shared via Swiff"
        
        return text
    }
    
    /// Present system share sheet
    static func share(items: [Any]) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first?.rootViewController else {
            return
        }
        
        let activityVC = UIActivityViewController(
            activityItems: items,
            applicationActivities: nil
        )
        
        // iPad support
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = rootVC.view
            popover.sourceRect = CGRect(
                x: rootVC.view.bounds.midX,
                y: rootVC.view.bounds.midY,
                width: 0,
                height: 0
            )
            popover.permittedArrowDirections = []
        }
        
        rootVC.present(activityVC, animated: true)
    }
}

// MARK: - Share Button Modifier

struct ShareButtonModifier: ViewModifier {
    let transaction: FeedTransaction
    @State private var showingShare = false
    
    func body(content: Content) -> some View {
        content
            .contextMenu {
                Button(action: {
                    ShareHelper.shareTransaction(transaction)
                }) {
                    Label("Share", systemImage: "square.and.arrow.up")
                }
                
                Button(action: {
                    // Copy to clipboard
                    UIPasteboard.general.string = "\(transaction.personName): \(transaction.formattedAmount)"
                    HapticManager.shared.success()
                }) {
                    Label("Copy Amount", systemImage: "doc.on.doc")
                }
            }
    }
}

extension View {
    func shareable(_ transaction: FeedTransaction) -> some View {
        modifier(ShareButtonModifier(transaction: transaction))
    }
}
