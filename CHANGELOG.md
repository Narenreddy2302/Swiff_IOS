# Changelog

All notable changes to Swiff iOS will be documented in this file.

## [Unreleased] - 2026-02-04

### Added

#### Twitter-Style Feed (Tab 4)
- **TwitterFeedView** - New card-based transaction feed replacing iMessage-style conversation
- **TransactionPostCard** - Tweet-style transaction cards with avatar, amount, and engagement bar
- **FeedTransactionDetailSheet** - Full transaction detail modal with comments and actions
- **FeedDataService** - Bridge between CoreData and feed UI with reactive updates
- **FeedSummaryCard** - Balance overview showing net position, you owe, they owe
- **ShareHelper** - System share sheet integration for transactions

#### Analytics Enhancements
- **SpendingTrendsChart** - Interactive 6-month spending line chart with gradient fill
- **MonthlyComparisonCard** - This month vs last month comparison with progress bars

#### Home Improvements
- **QuickActionsBar** - Quick access to Add Expense, Request, Split Bill, Settle Up
- **UpcomingRenewalsWidget** - 7-day renewal preview with urgency indicators

#### People Enhancements
- **PeopleSummaryCard** - Balance overview card with net position indicator

### Changed
- **MainTabView** - Feed tab now uses TwitterFeedView instead of RecentActivityView
- **AnalyticsView** - Added SpendingTrendsChart and MonthlyComparisonCard sections
- **HomeView** - Added QuickActionsBar and UpcomingRenewalsWidget

### Fixed
- Renamed TransactionDetailSheet in Feed module to FeedTransactionDetailSheet to avoid naming conflicts

## Technical Details

### New Files Created (13 total)
```
Features/Feed/
├── TwitterFeedView.swift         (~350 lines)
├── TransactionPostCard.swift     (~450 lines)
├── FeedTransactionDetailSheet.swift (~420 lines)
├── FeedDataService.swift         (~200 lines)
├── FeedSummaryCard.swift         (~170 lines)
└── ShareHelper.swift             (~100 lines)

Features/Analytics/
├── SpendingTrendsChart.swift     (~280 lines)
└── MonthlyComparisonCard.swift   (~210 lines)

Features/Home/
└── QuickActionsBar.swift         (~130 lines)

Features/People/
└── PeopleSummaryCard.swift       (~230 lines)

Features/Subscriptions/
└── UpcomingRenewalsWidget.swift  (~230 lines)
```

### Sprint Summary
- **Duration:** 5 days (Feb 4-9, 2026)
- **Goal:** Production-ready Twitter-style redesign
- **Progress:** 80% complete (Days 1-4 done)
- **Commits:** 11 new commits
- **Lines Added:** ~2,800+

---

*This changelog follows [Keep a Changelog](https://keepachangelog.com/) format.*
