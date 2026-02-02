//
//  SwiffWidgets.swift
//  SwiffWidgets
//
//  Created by Agent 10 on 11/21/25.
//  Main widget bundle entry point
//

import WidgetKit
import SwiftUI

@main
struct SwiffWidgetsBundle: WidgetBundle {
    var body: some Widget {
        UpcomingRenewalsWidget()
        QuickActionsWidget()
    }
}
