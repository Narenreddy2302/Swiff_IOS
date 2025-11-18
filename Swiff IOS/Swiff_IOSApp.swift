//
//  Swiff_IOSApp.swift
//  Swiff IOS
//
//  Created by Naren Reddy on 11/11/25.
//

import SwiftUI
import CoreData

@main
struct Swiff_IOSApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
