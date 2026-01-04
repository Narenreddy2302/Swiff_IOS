//
//  TabBarAccessor.swift
//  Swiff IOS
//
//  Created by Swiff AI on 11/18/25.
//  Refactored from ContentView.swift
//

import SwiftUI
import UIKit

struct TabBarAccessor {

    static func setupAppearance() {
        // Configure tab bar appearance with adaptive colors for dark mode
        let appearance = UITabBarAppearance()
        appearance.configureWithDefaultBackground()

        // Background Color
        let backgroundColor = UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1.0)
                : UIColor.systemBackground
        }
        appearance.backgroundColor = backgroundColor

        // Colors
        let unselectedColor = UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(white: 1.0, alpha: 0.5)
                : UIColor(red: 0.102, green: 0.102, blue: 0.102, alpha: 0.5)
        }

        let selectedColor = UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(red: 4/255, green: 63/255, blue: 46/255, alpha: 1.0)  // GREEN 5 (#043F2E)
                : UIColor(red: 4/255, green: 63/255, blue: 46/255, alpha: 1.0)  // GREEN 5 (#043F2E)
        }

        // Stacked Layout (Normal)
        appearance.stackedLayoutAppearance.normal.iconColor = unselectedColor
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: unselectedColor,
            .font: UIFont.systemFont(ofSize: 10, weight: .medium),
        ]

        // Stacked Layout (Selected)
        appearance.stackedLayoutAppearance.selected.iconColor = selectedColor
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: selectedColor,
            .font: UIFont.systemFont(ofSize: 10, weight: .semibold),
        ]

        // Inline Layout
        appearance.inlineLayoutAppearance.normal.iconColor = unselectedColor
        appearance.inlineLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: unselectedColor,
            .font: UIFont.systemFont(ofSize: 14, weight: .medium),
        ]

        appearance.inlineLayoutAppearance.selected.iconColor = selectedColor
        appearance.inlineLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: selectedColor,
            .font: UIFont.systemFont(ofSize: 14, weight: .semibold),
        ]

        // Compact Inline Layout
        appearance.compactInlineLayoutAppearance.normal.iconColor = unselectedColor
        appearance.compactInlineLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: unselectedColor,
            .font: UIFont.systemFont(ofSize: 12, weight: .medium),
        ]

        appearance.compactInlineLayoutAppearance.selected.iconColor = selectedColor
        appearance.compactInlineLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: selectedColor,
            .font: UIFont.systemFont(ofSize: 12, weight: .semibold),
        ]

        // Separator
        appearance.shadowImage = nil
        appearance.shadowColor = UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(white: 0.2, alpha: 0.3)
                : UIColor(white: 0.8, alpha: 0.3)
        }

        // Global Appearance
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
        UITabBar.appearance().isTranslucent = true
        UITabBar.appearance().backgroundColor = backgroundColor

        // Item positioning
        UITabBar.appearance().itemSpacing = 0
        UITabBar.appearance().itemWidth = 0
        UITabBar.appearance().itemPositioning = .automatic

        // Tint Colors
        UITabBar.appearance().tintColor = selectedColor
        UITabBar.appearance().unselectedItemTintColor = unselectedColor
    }
}
