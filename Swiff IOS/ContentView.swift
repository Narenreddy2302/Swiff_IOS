//
//  ContentView.swift
//  Swiff IOS
//
//  Created by Naren Reddy on 11/11/25.
//  Updated on 11/18/25: Refactored to use MainTabView and extracted views
//

import Combine
import ContactsUI
import PhotosUI
import SwiftData
import SwiftUI

struct ContentView: View {
    @EnvironmentObject var dataManager: DataManager

    var body: some View {
        MainTabView()
    }
}

#Preview {
    ContentView()
        .environmentObject(DataManager.shared)
}
