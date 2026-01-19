//
//  HidesTabBarModifier.swift
//  Swiff IOS
//
//  ViewModifier for WhatsApp-style tab bar hiding on detail views
//

import SwiftUI

struct HidesTabBarModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .toolbar(.hidden, for: .tabBar)
    }
}

extension View {
    /// Apply to detail views to hide the tab bar (WhatsApp-style)
    func hidesTabBar() -> some View {
        modifier(HidesTabBarModifier())
    }
}
