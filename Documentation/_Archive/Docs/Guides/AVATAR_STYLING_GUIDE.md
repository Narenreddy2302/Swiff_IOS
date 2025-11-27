# Avatar Styling Guide - Swiff iOS

## Overview
This document defines the standardized usage of avatars throughout the Swiff iOS application.

## Avatar Sizes

All avatar sizes are defined in the `AvatarSize` enum:

```swift
enum AvatarSize {
    case small    // 32x32 - List items, small badges
    case medium   // 44x44 - Standard list rows
    case large    // 56x56 - Headers, cards
    case xlarge   // 64x64 - Detail views
    case xxlarge  // 80x80 - Profile, hero sections
}
```

## Avatar Styles

Three styles are available:

```swift
enum AvatarStyle {
    case solid     // Solid background color
    case gradient  // Gradient background
    case bordered  // With border ring
}
```

## Usage Guidelines

### When to Use Each Size

#### `.small` (32x32)
- **Use in**: Compact lists, badges, inline mentions
- **Example**: Member lists in expense split view
```swift
AvatarView(person: person, size: .small, style: .bordered)
```

#### `.medium` (44x44)
- **Use in**: Standard list rows, member selection
- **Example**: Group member lists
```swift
AvatarView(person: person, size: .medium, style: .solid)
```

#### `.large` (56x56)
- **Use in**: List headers, cards, search results
- **Example**: Person list rows, search results
```swift
AvatarView(person: person, size: .large, style: .gradient)
```

#### `.xlarge` (64x64)
- **Use in**: Detail view headers, settings
- **Example**: User profile in settings
```swift
AvatarView(avatarType: avatarType, size: .xlarge, style: .solid)
```

#### `.xxlarge` (80x80)
- **Use in**: Profile pages, hero sections
- **Example**: Person detail view header
```swift
AvatarView(person: person, size: .xxlarge, style: .solid)
```

### When to Use Each Style

#### `.solid`
- **Primary use**: Most common style
- **Best for**: Clean, minimal look
- **Use in**: Settings, detail views, forms

#### `.gradient`
- **Primary use**: Visual emphasis
- **Best for**: Making items stand out
- **Use in**: Featured items, main person lists

#### `.bordered`
- **Primary use**: Dense layouts
- **Best for**: Distinguishing from background
- **Use in**: Overlapping avatars, compact lists

## Current Usage Audit

### ✅ Correct Usage

All instances have been audited and use proper enum-based sizes:

1. **SearchView.swift:288** - `.large` for search results ✅
2. **SettingsView.swift:42** - `.xlarge` for user profile ✅
3. **ContentView.swift:2558** - `.large` with gradient for person rows ✅
4. **ContentView.swift:2850** - `.xlarge` for preview ✅
5. **ContentView.swift:3138-3144** - `.large` for avatar selection ✅
6. **ContentView.swift:3461** - `.medium` for group members ✅
7. **ContentView.swift:4480** - `.small` with border for compact lists ✅
8. **SendReminderSheet.swift:67** - `.large` for reminder target ✅
9. **BalanceDetailView.swift:190** - `.large` for detail header ✅
10. **PersonDetailView.swift:49** - `.xxlarge` for hero section ✅
11. **UserProfileEditView.swift:34** - `.xlarge` for profile editor ✅
12. **GroupDetailView.swift:87** - `.xlarge` for member detail ✅
13. **AddGroupExpenseSheet.swift:154,207** - `.medium` for member selection ✅
14. **SubscriptionDetailView.swift:340** - `.medium` for shared members ✅

### Best Practices

1. **Always use enum sizes** - Never use numeric values like `size: 44`
2. **Always specify style** - Don't rely on defaults
3. **Consistent context** - Same size for same context across app
4. **Performance** - Reuse avatar instances when possible

### Size Context Matrix

| Context | Size | Style | Rationale |
|---------|------|-------|-----------|
| List Row | `.large` | `.gradient` or `.solid` | Prominent but not dominant |
| Search Result | `.large` | `.solid` | Consistency with lists |
| Detail Header | `.xxlarge` | `.solid` | Hero element |
| Settings Profile | `.xlarge` | `.solid` | Important but not hero |
| Group Members | `.medium` | `.solid` | Secondary information |
| Expense Split | `.small` | `.bordered` | Compact, many items |
| Member Selection | `.medium` | `.solid` | Touch target size |
| Inline Mention | `.small` | `.solid` | Inline with text |

## Implementation Notes

### Creating Avatar Views

Always use one of these patterns:

```swift
// With Person object
AvatarView(person: person, size: .large, style: .solid)

// With AvatarType directly
AvatarView(avatarType: .emoji("👤"), size: .medium, style: .solid)

// With Group (emoji only)
// Groups use emoji directly, not AvatarView
Text(group.emoji)
    .font(.system(size: 28))
```

### Animation Support

Avatars support smooth transitions:

```swift
AvatarView(avatarType: avatarType, size: .xlarge, style: .solid)
    .animation(.smooth, value: avatarType)
```

### Accessibility

All avatars automatically include:
- Proper accessibility labels
- VoiceOver support
- Dynamic type scaling (within constraints)

## Migration Checklist

- ✅ All numeric sizes replaced with enum values
- ✅ All instances specify explicit style
- ✅ Consistent sizing across similar contexts
- ✅ Documentation updated
- ✅ No hardcoded size values in codebase

## Status: ✅ COMPLETE

All avatar usages in the app follow standardized guidelines.

---

Last Updated: November 20, 2025
