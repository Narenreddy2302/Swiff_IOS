# Production Readiness Checklist

## Overview
This document lists all issues that need to be addressed before pushing to production. The primary issue is **hardcoded currency symbols (`$` and `USD`)** that should use the user's selected currency via `.asCurrency`.

---

## Already Fixed (This Session)

| File | Issue | Status |
|------|-------|--------|
| `Views/Subscriptions/SubscriptionsView.swift` | Mock shared subscriptions data | Fixed |
| `Views/Subscriptions/SubscriptionDetailView.swift` | Hardcoded currency (5 instances) | Fixed |
| `Views/Subscriptions/EditSubscriptionSheet.swift` | Hardcoded currency (5 instances) | Fixed |
| `Views/Subscriptions/SubscriptionsComponents.swift` | Hardcoded currency (8 instances) | Fixed |
| `Views/Subscriptions/SubscriptionsComponents.swift` | Fake trend data | Fixed |
| `Views/Subscriptions/ShareSubscriptionSheet.swift` | Hardcoded currency (4 instances) | Fixed |
| `Views/Subscriptions/SubscriptionsView.swift` | Missing pull-to-refresh on Shared tab | Fixed |
| `Services/DataManager.swift` | SharedSubscription missing Supabase sync | Fixed |
| `Models/Domain/Subscription.swift` | SharedSubscription missing toSupabaseModel | Fixed |
| `Views/Settings/AnalyticsInsightsPage.swift` | Hardcoded USD currency | Fixed |

---

## Remaining Issues by Category

### 1. Charts (`Views/Charts/`)

#### CustomPieChartView.swift
| Line | Current Code | Fix |
|------|--------------|-----|
| 155 | `formatter.currencyCode = "USD"` | Use `UserSettings.shared.selectedCurrency.code` |
| 204 | `formatter.currencyCode = "USD"` | Use `UserSettings.shared.selectedCurrency.code` |

#### CategoryPieChart.swift
| Line | Current Code | Fix |
|------|--------------|-----|
| 75 | `formatter.currencyCode = "USD"` | Use `UserSettings.shared.selectedCurrency.code` |

#### PriceHistoryChartView.swift
| Line | Current Code | Fix |
|------|--------------|-----|
| 89 | `String(format: "$%.2f", subscription.price)` | Use `.asCurrency` |
| 95 | `String(format: "$%.2f", stats.originalPrice)` | Use `.asCurrency` |
| 116 | `String(format: "$%.2f", stats.averagePrice)` | Use `.asCurrency` |
| 185 | `String(format: "$%.2f", price)` | Use `.asCurrency` |
| 223 | `String(format: "$%.2f", selected.price)` | Use `.asCurrency` |
| 427 | `String(format: "%@$%.2f", sign, abs(totalChange))` | Use `.asCurrency` with sign |
| 437 | `String(format: "%@$%.2f", sign, abs(largestChange))` | Use `.asCurrency` with sign |

---

### 2. Analytics (`Views/Analytics/`)

#### AnalyticsView.swift
| Line | Current Code | Fix |
|------|--------------|-----|
| 871 | `formatter.currencyCode = "USD"` | Use `UserSettings.shared.selectedCurrency.code` |
| 1138 | `formatter.currencyCode = "USD"` | Use `UserSettings.shared.selectedCurrency.code` |
| 1455 | `formatter.currencyCode = "USD"` | Use `UserSettings.shared.selectedCurrency.code` |

#### AnalyticsComponents.swift
| Line | Current Code | Fix |
|------|--------------|-----|
| 477 | `formatter.currencySymbol = "$"` | Use `UserSettings.shared.selectedCurrency.symbol` |
| 484 | `String(format: "$%.0fk", amount / 1000)` | Use custom formatting with user currency |
| 486 | `String(format: "$%.0f", amount)` | Use `.asCurrency` |
| 553 | `formatter.currencySymbol = "$"` | Use `UserSettings.shared.selectedCurrency.symbol` |
| 710 | `formatter.currencySymbol = "$"` | Use `UserSettings.shared.selectedCurrency.symbol` |
| 785 | `formatter.currencySymbol = "$"` | Use `UserSettings.shared.selectedCurrency.symbol` |
| 842 | `formatter.currencySymbol = "$"` | Use `UserSettings.shared.selectedCurrency.symbol` |
| 972 | `formatter.currencySymbol = "$"` | Use `UserSettings.shared.selectedCurrency.symbol` |
| 1026 | `formatter.currencySymbol = "$"` | Use `UserSettings.shared.selectedCurrency.symbol` |

#### CategoryBreakdownChart.swift
| Line | Current Code | Fix |
|------|--------------|-----|
| 238 | `String(format: "$%.0fk", amount / 1000)` | Use custom formatting with user currency |
| 240 | `String(format: "$%.0f", amount)` | Use `.asCurrency` |

#### SubscriptionComparisonChart.swift
| Line | Current Code | Fix |
|------|--------------|-----|
| 248 | `String(format: "$%.0fk", amount / 1000)` | Use custom formatting with user currency |
| 250 | `String(format: "$%.0f", amount)` | Use `.asCurrency` |

---

### 3. Subscriptions (`Views/Subscriptions/`)

#### SubscriptionBillingSummaryCard.swift
| Line | Current Code | Fix |
|------|--------------|-----|
| 202 | `String(format: "$%.2f", subscription.monthlyEquivalent)` | Use `.asCurrency` |
| 227 | `String(format: "$%.2f", subscription.totalSpent)` | Use `.asCurrency` |

#### FeedSubscriptionRow.swift
| Line | Current Code | Fix |
|------|--------------|-----|
| 72 | `formatter.currencySymbol = "$"` | Use `UserSettings.shared.selectedCurrency.symbol` |
| 173 | `String(format: "+$%.2f", balance)` | Use `.asCurrency` with sign |
| 175 | `String(format: "-$%.2f", abs(balance))` | Use `.asCurrency` with sign |

#### SubscriptionCard.swift
| Line | Current Code | Fix |
|------|--------------|-----|
| 32 | `String(format: "$%.2f", subscription.price)` | Use `.asCurrency` |

#### SubscriptionsSheets.swift
| Line | Current Code | Fix |
|------|--------------|-----|
| 54 | `String(format: "$%.2f", totalMonthlySpend)` | Use `.asCurrency` |
| 61 | `String(format: "$%.0f", totalAnnualSpend)` | Use `.asCurrency` |
| 75 | `String(format: "$%.2f", averageSubscriptionCost)` | Use `.asCurrency` |
| 131 | `String(format: "$%.2f", mostExpensive.monthlyEquivalent)` | Use `.asCurrency` |
| 232 | `String(format: "$%.2f", amount)` | Use `.asCurrency` |
| 352 | `String(format: "$%.2f", totalAmount)` | Use `.asCurrency` |
| 418 | `String(format: "$%.2f", subscription.price)` | Use `.asCurrency` |

#### SubscriptionGridCardView.swift
| Line | Current Code | Fix |
|------|--------------|-----|
| 60 | `String(format: "$%.2f", subscription.price)` | Use `.asCurrency` |

#### TrialStatusSection.swift
| Line | Current Code | Fix |
|------|--------------|-----|
| 67 | `String(format: "$%.2f/%@", priceAfterTrial, ...)` | Use `.asCurrency` |
| 74 | `String(format: "$%.2f/%@", subscription.price, ...)` | Use `.asCurrency` |

---

### 4. Conversation (`Views/Conversation/`)

#### SharedSubscriptionCostCard.swift
| Line | Current Code | Fix |
|------|--------------|-----|
| 70 | `String(format: "$%.2f", totalCost)` | Use `.asCurrency` |
| 94 | `String(format: "$%.2f", costPerPerson)` | Use `.asCurrency` |
| 134 | `String(format: "$%.2f", costPerPerson)` | Use `.asCurrency` |
| 168 | `String(format: "$%.2f", costPerPerson)` | Use `.asCurrency` |
| 174 | `String(format: "$%.2f", costPerPerson)` | Use `.asCurrency` |

#### SubscriptionStatusBanner.swift
| Line | Current Code | Fix |
|------|--------------|-----|
| 73 | `String(format: "...charged $%.2f...", priceAfter)` | Use `.asCurrency` |
| 75 | `String(format: "New price: $%.2f", newPrice)` | Use `.asCurrency` |
| 77 | `String(format: "Amount: $%.2f", amount)` | Use `.asCurrency` |

#### SubscriptionTimelineHeader.swift
| Line | Current Code | Fix |
|------|--------------|-----|
| 53 | `String(format: "$%.2f/%@", subscription.price, ...)` | Use `.asCurrency` |
| 68 | `String(format: "$%.2f/person", subscription.costPerPerson)` | Use `.asCurrency` |
| 143 | `String(format: "$%.2f per person", subscription.costPerPerson)` | Use `.asCurrency` |

#### SystemEventRow.swift
| Line | Current Code | Fix |
|------|--------------|-----|
| 129 | `formatter.currencyCode = "USD"` | Use `UserSettings.shared.selectedCurrency.code` |

#### CompactGroupHeader.swift
| Line | Current Code | Fix |
|------|--------------|-----|
| 80 | `String(format: "$%.2f", absAmount)` | Use `.asCurrency` |

#### QuickActionButton.swift
| Line | Current Code | Fix |
|------|--------------|-----|
| 180 | `formatter.currencyCode = "USD"` | Use `UserSettings.shared.selectedCurrency.code` |

#### Base/BalanceText.swift
| Line | Current Code | Fix |
|------|--------------|-----|
| 59 | `formatter.currencyCode = "USD"` | Use `UserSettings.shared.selectedCurrency.code` |

---

### 5. Timeline (`Views/Timeline/`)

#### TransactionBubbleView.swift
| Line | Current Code | Fix |
|------|--------------|-----|
| 207 | `formatter.currencySymbol = "$"` | Use `UserSettings.shared.selectedCurrency.symbol` |
| 334 | `String(format: "$%.2f", amount)` | Use `.asCurrency` |

#### ChatTimelineComponents.swift
| Line | Current Code | Fix |
|------|--------------|-----|
| 51 | `formatter.currencySymbol = "$"` | Use `UserSettings.shared.selectedCurrency.symbol` |
| 52 | `String(format: "$%.2f", value)` | Use `.asCurrency` |
| 88 | `formatter.currencySymbol = "$"` | Use `UserSettings.shared.selectedCurrency.symbol` |
| 89 | `String(format: "$%.2f", value)` | Use `.asCurrency` |

#### TransactionDetailsCard.swift
| Line | Current Code | Fix |
|------|--------------|-----|
| 41 | `String(format: "$%.2f", amount)` | Use `.asCurrency` |

#### TransactionBubbleCard.swift
| Line | Current Code | Fix |
|------|--------------|-----|
| 170 | `formatter.currencySymbol = "$"` | Use `UserSettings.shared.selectedCurrency.symbol` |

#### ExpandedDueBubbleContent.swift
| Line | Current Code | Fix |
|------|--------------|-----|
| 184 | `formatter.currencySymbol = "$"` | Use `UserSettings.shared.selectedCurrency.symbol` |

#### SubscriptionAlertBanner.swift
| Line | Current Code | Fix |
|------|--------------|-----|
| 134 | `formatter.currencyCode = "USD"` | Use `UserSettings.shared.selectedCurrency.code` |

#### StatusBannerView.swift
| Line | Current Code | Fix |
|------|--------------|-----|
| 52 | `formatter.currencyCode = "USD"` | Use `UserSettings.shared.selectedCurrency.code` |

---

### 6. Groups (`Views/Groups/`)

#### Step5ConfigureView.swift
| Line | Current Code | Fix |
|------|--------------|-----|
| 100 | `String(format: "$%.2f", ...)` | Use `.asCurrency` |
| 113 | `String(format: "$%.2f", ...)` | Use `.asCurrency` |
| 153 | `String(format: "$%.2f / $%.2f", ...)` | Use `.asCurrency` |
| 185 | `String(format: "$%.2f", ...)` | Use `.asCurrency` |
| 234 | `String(format: "$%.2f", amountPerShare)` | Use `.asCurrency` |
| 260 | `String(format: "$%.2f", amount)` | Use `.asCurrency` |
| 336 | `String(format: "$%.2f", equalAmount)` | Use `.asCurrency` |
| 364 | `String(format: "$%.2f", difference)` | Use `.asCurrency` |
| 402 | `String(format: "$%.2f / $%.2f", ...)` | Use `.asCurrency` |
| 471 | `String(format: "$%.2f", amount)` | Use `.asCurrency` |

#### Step6ReviewView.swift
| Line | Current Code | Fix |
|------|--------------|-----|
| 186 | `String(format: "$%.2f", participant.amount)` | Use `.asCurrency` |

#### SplitBillCard.swift
| Line | Current Code | Fix |
|------|--------------|-----|
| 66 | `String(format: "$%.2f", splitBill.totalAmount)` | Use `.asCurrency` |
| 127 | `String(format: "$%.2f pending", splitBill.totalPending)` | Use `.asCurrency` |

#### SplitBillDetailView.swift
| Line | Current Code | Fix |
|------|--------------|-----|
| 76 | `String(format: "$%.2f", splitBill.totalAmount)` | Use `.asCurrency` |
| 158 | `String(format: "$%.2f remaining", splitBill.totalPending)` | Use `.asCurrency` |
| 302 | `String(format: "$%.2f", participant.amount)` | Use `.asCurrency` |

---

### 7. People (`Views/People/`)

#### PersonCard.swift
| Line | Current Code | Fix |
|------|--------------|-----|
| 32 | `String(format: "$%.2f", abs(person.balance))` | Use `.asCurrency` |

#### PersonSelectionChip.swift
| Line | Current Code | Fix |
|------|--------------|-----|
| 38 | `String(format: "$%.2f", amount)` | Use `.asCurrency` |

#### ContactRowView.swift
| Line | Current Code | Fix |
|------|--------------|-----|
| 98 | `String(format: "$%.2f", abs(balance))` | Use `.asCurrency` |

---

### 8. Components (`Views/Components/`)

#### InitialsListRow.swift (Preview only - low priority)
| Line | Current Code | Fix |
|------|--------------|-----|
| 427, 439, 451, 466, 478, 490 | `String(format: "$%.2f", ...)` | Use `.asCurrency` |

#### ListRowFactory.swift
| Line | Current Code | Fix |
|------|--------------|-----|
| 404 | `formatter.currencyCode = "USD"` | Use `UserSettings.shared.selectedCurrency.code` |
| 413 | `formatter.currencyCode = "USD"` | Use `UserSettings.shared.selectedCurrency.code` |

#### PriceChangeBadge.swift
| Line | Current Code | Fix |
|------|--------------|-----|
| 124 | `String(format: "$%.2f", priceChange.oldPrice)` | Use `.asCurrency` |
| 125 | `String(format: "$%.2f", priceChange.newPrice)` | Use `.asCurrency` |

#### StatisticsHeaderView.swift
| Line | Current Code | Fix |
|------|--------------|-----|
| 183 | `formatter.currencySymbol = "$"` | Use `UserSettings.shared.selectedCurrency.symbol` |

#### ProfileStatisticsGrid.swift
| Line | Current Code | Fix |
|------|--------------|-----|
| 142 | `formatter.currencyCode = "USD"` | Use `UserSettings.shared.selectedCurrency.code` |

#### ParticipantBubble.swift
| Line | Current Code | Fix |
|------|--------------|-----|
| 53 | `String(format: "$%.2f", participant.amount)` | Use `.asCurrency` |

#### UnifiedListRow.swift
| Line | Current Code | Fix |
|------|--------------|-----|
| 93 | `formatter.currencyCode = "USD"` | Use `UserSettings.shared.selectedCurrency.code` |

#### ConversationTransactionHelper.swift
| Line | Current Code | Fix |
|------|--------------|-----|
| 22 | `formatter.currencySymbol = "$"` | Use `UserSettings.shared.selectedCurrency.symbol` |

#### CategoryContributionList.swift
| Line | Current Code | Fix |
|------|--------------|-----|
| 91 | `formatter.currencyCode = "USD"` | Use `UserSettings.shared.selectedCurrency.code` |

---

### 9. Transactions (`Views/Transactions/`)

#### TransactionDetailView.swift
| Line | Current Code | Fix |
|------|--------------|-----|
| 421 | `String(format: "$%.2f", subscription.price)` | Use `.asCurrency` |

#### FeedHeader.swift
| Line | Current Code | Fix |
|------|--------------|-----|
| 88 | `formatter.currencyCode = "USD"` | Use `UserSettings.shared.selectedCurrency.code` |

---

### 10. Search (`Views/Search/`)

#### SearchView.swift
| Line | Current Code | Fix |
|------|--------------|-----|
| 432 | `String(format: "$%.2f", person.balance)` | Use `.asCurrency` |
| 458 | `String(format: "$%.2f/%@", subscription.price, ...)` | Use `.asCurrency` |

---

### 11. Notifications (`Views/Notifications/`)

#### ReminderSettingsSheet.swift
| Line | Current Code | Fix |
|------|--------------|-----|
| 162 | `String(format: "$%.2f", subscription.price)` | Use `.asCurrency` |

#### SendReminderSheet.swift
| Line | Current Code | Fix |
|------|--------------|-----|
| 53 | `formatter.currencySymbol = "$"` | Use `UserSettings.shared.selectedCurrency.symbol` |
| 61 | `formatter.currencySymbol = "$"` | Use `UserSettings.shared.selectedCurrency.symbol` |

---

### 12. Sheets (`Views/Sheets/`)

#### BulkActionsSheet.swift
| Line | Current Code | Fix |
|------|--------------|-----|
| 133 | `formatter.currencySymbol = "$"` | Use `UserSettings.shared.selectedCurrency.symbol` |

#### PriceChangeConfirmationSheet.swift
| Line | Current Code | Fix |
|------|--------------|-----|
| 116 | `String(format: "$%.2f", oldPrice)` | Use `.asCurrency` |
| 139 | `String(format: "$%.2f", newPrice)` | Use `.asCurrency` |
| 159 | `String(format: "%@$%.2f (%@%.1f%%", ...)` | Use `.asCurrency` with sign |

#### UsageTrackingSheet.swift
| Line | Current Code | Fix |
|------|--------------|-----|
| 127 | `String(format: "$%.2f/%@", subscription.price, ...)` | Use `.asCurrency` |
| 260 | `String(format: "$%.2f", cost)` | Use `.asCurrency` |
| 344 | `String(format: "$%.2f", ...)` | Use `.asCurrency` |
| 351 | `String(format: "$%.2f", subscription.monthlyEquivalent)` | Use `.asCurrency` |

---

### 13. Services

#### AnalyticsService.swift
| Line | Current Code | Fix |
|------|--------------|-----|
| 920 | `formatter.currencySymbol = "$"` | Use `UserSettings.shared.selectedCurrency.symbol` |

#### SpotlightIndexingService.swift
| Line | Current Code | Fix |
|------|--------------|-----|
| 172 | `String(format: "$%.2f per %@", subscription.price, ...)` | Use `.asCurrency` |

#### SubscriptionEventService.swift
| Line | Current Code | Fix |
|------|--------------|-----|
| 393 | `String(format: "$%.2f", subscription.price)` | Use `.asCurrency` |

#### SplitCalculationService.swift
| Line | Current Code | Fix |
|------|--------------|-----|
| 127 | `String(format: "%.2f", ...)` (error message) | Low priority - internal error |

---

### 14. Models

#### Transaction.swift
| Line | Current Code | Fix |
|------|--------------|-----|
| 93 | `formatter.currencySymbol = "$"` | Use `UserSettings.shared.selectedCurrency.symbol` |

#### SubscriptionEvent.swift
| Line | Current Code | Fix |
|------|--------------|-----|
| 170 | `String(format: "%@ $%.2f", sign, abs(amount))` | Use `.asCurrency` with sign |

#### PriceChange.swift
| Line | Current Code | Fix |
|------|--------------|-----|
| 50 | `String(format: "%@$%.2f", sign, abs(changeAmount))` | Use `.asCurrency` with sign |

---

### 15. Utilities

#### CurrencyFormatter.swift
| Line | Current Code | Fix |
|------|--------------|-----|
| 29-56 | Multiple hardcoded currency symbols | This file defines formatters - may need refactoring |

#### CurrencyHelper.swift
| Line | Current Code | Fix |
|------|--------------|-----|
| 110 | Default `currencyCode: String = "USD"` | Change default to use `UserSettings.shared.selectedCurrency.code` |

---

## Priority Order for Fixes

### P0 - Critical (User-facing, high visibility)
1. `Views/Subscriptions/SubscriptionsSheets.swift` - Insights sheet
2. `Views/Subscriptions/SubscriptionBillingSummaryCard.swift`
3. `Views/Conversation/SharedSubscriptionCostCard.swift`
4. `Views/People/PersonCard.swift`
5. `Views/Groups/SplitBillCard.swift`
6. `Views/Groups/SplitBillDetailView.swift`

### P1 - High (User-facing, moderate visibility)
1. `Views/Analytics/*` - All analytics views
2. `Views/Charts/*` - All chart views
3. `Views/Timeline/*` - All timeline views
4. `Views/Groups/Step5ConfigureView.swift`
5. `Views/Groups/Step6ReviewView.swift`

### P2 - Medium (User-facing, lower visibility)
1. `Views/Sheets/*`
2. `Views/Notifications/*`
3. `Views/Search/SearchView.swift`
4. `Views/Components/*`

### P3 - Low (Internal/Preview only)
1. Preview code in `InitialsListRow.swift`
2. Error messages in services
3. Documentation files

---

## Recommended Approach

### Option 1: Create a Global Currency Helper
Create a single helper function that all views use:

```swift
extension Double {
    var asCurrencyWithSign: String {
        let symbol = self >= 0 ? "+" : "-"
        return "\(symbol)\(abs(self).asCurrency)"
    }
}
```

### Option 2: Bulk Find & Replace
Use regex to find and replace patterns:
- `String(format: "$%.2f", X)` → `X.asCurrency`
- `formatter.currencyCode = "USD"` → `formatter.currencyCode = UserSettings.shared.selectedCurrency.code`
- `formatter.currencySymbol = "$"` → `formatter.currencySymbol = UserSettings.shared.selectedCurrency.symbol`

---

## Widgets (Separate Consideration)

The `SwiffWidgets/` folder has its own hardcoded currency. Widgets may have limited access to UserSettings, so this needs special handling:
- `WidgetDataService.swift` - lines 46, 74, 94
- `UpcomingRenewalsWidget.swift` - lines 156, 230
- `WidgetModels.swift` - line 29

---

## Summary

| Category | Files | Instances | Priority |
|----------|-------|-----------|----------|
| Charts | 3 | 12 | P1 |
| Analytics | 4 | 20 | P1 |
| Subscriptions | 7 | 18 | P0-P1 |
| Conversation | 7 | 15 | P0-P1 |
| Timeline | 7 | 12 | P1 |
| Groups | 4 | 18 | P0-P1 |
| People | 3 | 4 | P0 |
| Components | 9 | 15 | P2 |
| Transactions | 2 | 2 | P1 |
| Search | 1 | 2 | P2 |
| Notifications | 2 | 3 | P2 |
| Sheets | 4 | 8 | P2 |
| Services | 4 | 4 | P2 |
| Models | 3 | 3 | P1 |
| Utilities | 2 | 8 | P3 |
| **TOTAL** | **62** | **~144** | |

---

## Next Steps

1. Start with P0 files (6 files, ~20 instances)
2. Move to P1 files (20+ files, ~60 instances)
3. Complete P2 files (15+ files, ~40 instances)
4. Address P3 files if time permits

Estimated time: 2-4 hours for full cleanup
