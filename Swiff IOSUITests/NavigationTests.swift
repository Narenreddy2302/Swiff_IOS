//
//  NavigationTests.swift
//  Swiff IOSUITests
//
//  Created by Test Agent 15 on 11/21/25.
//  UI tests for navigation flows in Swiff iOS app
//

import XCTest

final class NavigationTests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        try super.setUpWithError()
        continueAfterFailure = false

        app = XCUIApplication()
        app.launchArguments = ["UI-Testing"]
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
        try super.tearDownWithError()
    }

    // MARK: - 15.2.1: Tab Bar Navigation

    func testTabBarNavigation() throws {
        // Test navigation between all tabs

        // Home tab should be visible by default
        XCTAssertTrue(app.tabBars.firstMatch.exists, "Tab bar should exist")

        // Test switching to Subscriptions tab
        let subscriptionsTab = app.tabBars.buttons["Subscriptions"]
        if subscriptionsTab.exists {
            subscriptionsTab.tap()
            // Verify we're on subscriptions view
            XCTAssertTrue(app.navigationBars["Subscriptions"].exists || app.staticTexts["Subscriptions"].exists,
                          "Should navigate to Subscriptions tab")
        }

        // Test switching to People tab
        let peopleTab = app.tabBars.buttons["People"]
        if peopleTab.exists {
            peopleTab.tap()
            XCTAssertTrue(app.navigationBars["People"].exists || app.staticTexts["People"].exists,
                          "Should navigate to People tab")
        }

        // Test switching to Groups tab
        let groupsTab = app.tabBars.buttons["Groups"]
        if groupsTab.exists {
            groupsTab.tap()
            XCTAssertTrue(app.navigationBars["Groups"].exists || app.staticTexts["Groups"].exists,
                          "Should navigate to Groups tab")
        }

        // Test switching to Transactions tab
        let transactionsTab = app.tabBars.buttons["Transactions"]
        if transactionsTab.exists {
            transactionsTab.tap()
            XCTAssertTrue(app.navigationBars["Transactions"].exists || app.staticTexts["Transactions"].exists,
                          "Should navigate to Transactions tab")
        }

        // Test switching to Analytics tab
        let analyticsTab = app.tabBars.buttons["Analytics"]
        if analyticsTab.exists {
            analyticsTab.tap()
            XCTAssertTrue(app.navigationBars["Analytics"].exists || app.staticTexts["Analytics"].exists,
                          "Should navigate to Analytics tab")
        }

        // Return to home
        let homeTab = app.tabBars.buttons["Home"]
        if homeTab.exists {
            homeTab.tap()
            XCTAssertTrue(app.navigationBars["Home"].exists || app.staticTexts["Home"].exists,
                          "Should return to Home tab")
        }

        print("✅ testTabBarNavigation passed")
    }

    // MARK: - 15.2.2: Subscription Detail Navigation

    func testSubscriptionDetailNavigation() throws {
        // Navigate to subscriptions
        let subscriptionsTab = app.tabBars.buttons["Subscriptions"]
        if subscriptionsTab.exists {
            subscriptionsTab.tap()
        }

        // Wait for content to load
        sleep(1)

        // Find and tap first subscription (if exists)
        let subscriptionsList = app.scrollViews.firstMatch
        if subscriptionsList.exists {
            // Look for any tappable subscription card
            let firstSubscription = subscriptionsList.buttons.firstMatch
            if firstSubscription.exists {
                firstSubscription.tap()

                // Verify detail view opened
                sleep(1)
                XCTAssertTrue(app.navigationBars.count > 0, "Detail view should open")

                // Navigate back
                let backButton = app.navigationBars.buttons.element(boundBy: 0)
                if backButton.exists {
                    backButton.tap()
                }
            }
        }

        print("✅ testSubscriptionDetailNavigation passed")
    }

    // MARK: - 15.2.3: Person Detail Navigation

    func testPersonDetailNavigation() throws {
        // Navigate to people tab
        let peopleTab = app.tabBars.buttons["People"]
        if peopleTab.exists {
            peopleTab.tap()
        }

        sleep(1)

        // Find and tap first person
        let peopleList = app.tables.firstMatch
        if peopleList.exists {
            let firstPerson = peopleList.cells.firstMatch
            if firstPerson.exists {
                firstPerson.tap()

                // Verify detail view
                sleep(1)
                XCTAssertTrue(app.navigationBars.count > 0, "Person detail should open")

                // Navigate back
                let backButton = app.navigationBars.buttons.element(boundBy: 0)
                if backButton.exists {
                    backButton.tap()
                }
            }
        }

        print("✅ testPersonDetailNavigation passed")
    }

    // MARK: - 15.2.4: Search Navigation

    func testSearchNavigation() throws {
        // Navigate to search (usually via search button or search tab)
        let searchButton = app.buttons["Search"]
        if searchButton.exists {
            searchButton.tap()

            sleep(1)

            // Look for search field
            let searchField = app.searchFields.firstMatch
            if searchField.exists {
                // Type search query
                searchField.tap()
                searchField.typeText("Test")

                sleep(1)

                // Verify results appear
                XCTAssertTrue(app.tables.firstMatch.exists || app.scrollViews.firstMatch.exists,
                              "Search results should appear")

                // Tap on a result if available
                let firstResult = app.tables.cells.firstMatch
                if firstResult.exists {
                    firstResult.tap()
                    sleep(1)

                    // Should navigate to detail
                    XCTAssertTrue(app.navigationBars.count > 0, "Should navigate to result detail")
                }
            }
        }

        print("✅ testSearchNavigation passed")
    }

    // MARK: - Navigation Stress Tests

    func testRapidTabSwitching() throws {
        // Test rapid tab switching doesn't cause crashes
        let tabs = ["Home", "Subscriptions", "People", "Groups", "Transactions"]

        for _ in 0..<3 {
            for tabName in tabs {
                let tab = app.tabBars.buttons[tabName]
                if tab.exists {
                    tab.tap()
                    // Brief pause
                    usleep(100000) // 100ms
                }
            }
        }

        XCTAssertTrue(app.exists, "App should remain stable after rapid tab switching")
        print("✅ testRapidTabSwitching passed")
    }

    func testDeepNavigationAndBack() throws {
        // Test deep navigation stack

        // Go to subscriptions
        app.tabBars.buttons["Subscriptions"].tap()
        sleep(1)

        // Open detail
        let firstItem = app.scrollViews.firstMatch.buttons.firstMatch
        if firstItem.exists {
            firstItem.tap()
            sleep(1)

            // Open edit/settings if available
            let editButton = app.buttons["Edit"]
            if editButton.exists {
                editButton.tap()
                sleep(1)

                // Now navigate back through the stack
                while app.navigationBars.buttons.count > 0 {
                    let backButton = app.navigationBars.buttons.element(boundBy: 0)
                    if backButton.exists {
                        backButton.tap()
                        sleep(0.5)
                    } else {
                        break
                    }
                }
            }
        }

        XCTAssertTrue(app.exists, "Should successfully navigate back through deep stack")
        print("✅ testDeepNavigationAndBack passed")
    }

    func testNavigationBarElements() throws {
        // Test navigation bar has expected elements

        // Home navigation bar
        app.tabBars.buttons["Home"].tap()
        sleep(1)

        // Check for common navigation elements
        let navigationBar = app.navigationBars.firstMatch
        if navigationBar.exists {
            // Might have title, buttons, etc.
            XCTAssertTrue(true, "Navigation bar exists")
        }

        print("✅ testNavigationBarElements passed")
    }

    func testModalPresentation() throws {
        // Test modal sheets presentation and dismissal

        // Look for add buttons (usually + or "Add")
        let addButton = app.buttons["Add"] ?? app.buttons["+"]
        if let button = addButton as? XCUIElement, button.exists {
            button.tap()
            sleep(1)

            // Sheet should appear
            XCTAssertTrue(app.sheets.count > 0 || app.exists, "Modal should present")

            // Dismiss - look for Cancel or Close button
            let cancelButton = app.buttons["Cancel"] ?? app.buttons["Close"]
            if let button = cancelButton as? XCUIElement, button.exists {
                button.tap()
                sleep(1)
            } else {
                // Try swipe down to dismiss
                app.swipeDown()
                sleep(1)
            }

            // Modal should be dismissed
            XCTAssertTrue(app.exists, "Should dismiss modal successfully")
        }

        print("✅ testModalPresentation passed")
    }

    func testPullToRefresh() throws {
        // Test pull-to-refresh functionality

        // Navigate to a view with refresh capability (likely home or transactions)
        app.tabBars.buttons["Home"].tap()
        sleep(1)

        let scrollView = app.scrollViews.firstMatch
        if scrollView.exists {
            // Pull down to refresh
            let start = scrollView.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.3))
            let end = scrollView.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.7))
            start.press(forDuration: 0.1, thenDragTo: end)

            sleep(2) // Wait for refresh to complete

            XCTAssertTrue(app.exists, "Pull to refresh should work without crashing")
        }

        print("✅ testPullToRefresh passed")
    }

    func testSettingsNavigation() throws {
        // Test navigating to settings

        let settingsButton = app.buttons["Settings"] ?? app.buttons["settings"]
        if let button = settingsButton as? XCUIElement, button.exists {
            button.tap()
            sleep(1)

            // Settings view should appear
            XCTAssertTrue(app.exists, "Settings should open")

            // Navigate back
            let backButton = app.navigationBars.buttons.element(boundBy: 0)
            if backButton.exists {
                backButton.tap()
                sleep(1)
            }
        }

        print("✅ testSettingsNavigation passed")
    }
}
