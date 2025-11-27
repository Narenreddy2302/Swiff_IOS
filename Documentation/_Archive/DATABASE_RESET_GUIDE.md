# Database Reset Guide - Fixing Schema Mismatch

## Problem

You're seeing **EXC_BREAKPOINT** crash at PersistenceService.swift:305 (or similar line) when the app tries to fetch data. This happens because the **old database file** still has the previous versioned schema, but the app is now using concrete models.

## Quick Fix: Delete and Reinstall

The simplest solution is to delete the app and reinstall it:

### Option 1: Delete from Simulator/Device (Recommended)
1. **Stop the app** if it's running
2. **Long press** the app icon on your simulator/device
3. Select **"Remove App"** or **"Delete App"**
4. **Confirm deletion**
5. **Build and run** again from Xcode

This will:
- ✅ Delete the old database file with wrong schema
- ✅ Create a fresh database with correct schema
- ✅ App will start clean with no schema mismatch

### Option 2: Reset Simulator
If you're using the iOS Simulator:

1. **Stop the app**
2. In Xcode menu: **Device > Erase All Content and Settings**
3. **Build and run** again

### Option 3: Programmatic Database Reset
If you want to keep the app installed but reset the database:

1. Add this code temporarily to your `Swiff_IOSApp.swift` onAppear:

```swift
.onAppear {
    // TEMPORARY: Reset database on first launch
    Task {
        await PersistenceService.shared.resetDatabase()
    }

    // Existing code...
    DataManager.shared.loadAllData()
    // ... rest of your code
}
```

2. Run the app once
3. **Remove this code** after the database is reset
4. Run normally

## Why This Happens

**Before the fix:**
- Old database file: Contains PersonModelV1, SubscriptionModelV1, etc.
- New app code: Looking for PersonModel, SubscriptionModel, etc.
- SwiftData: "I can't find PersonModel in the database!" → **CRASH**

**After delete & reinstall:**
- Fresh database: Empty, no schema yet
- App creates: PersonModel, SubscriptionModel, etc.
- SwiftData: "Found PersonModel!" → **Works!**

## Verification

After deleting and reinstalling, you should see these logs:

```
✅ PersistenceService initialized with concrete model schema
📱 Refreshing widget data from main app...
✅ Widget data refreshed
```

And the app should **NOT** crash when:
- Opening the app
- Navigating to People tab
- Navigating to Subscriptions tab
- Creating new data

## If Problem Persists

If you still see the crash after deleting and reinstalling:

1. **Check the schema is correct** in both files:
   - Swiff_IOSApp.swift (should have all 7 models including PriceChangeModel)
   - PersistenceService.swift (should use concrete models, not versioned schema)

2. **Check for database files** that might not be deleted:
   ```swift
   // Add to a test function to see where the database is:
   if let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
       print("Documents path: \(documentsPath.path)")
       let dbPath = documentsPath.appendingPathComponent("default.store")
       print("Database exists: \(FileManager.default.fileExists(atPath: dbPath.path))")
   }
   ```

3. **Clean build folder**:
   - In Xcode: Product > Clean Build Folder (Cmd+Shift+K)
   - Then: Product > Build (Cmd+B)

## Prevention for Future

To prevent this in production:

### 1. Add Migration Support
When you need to change the schema in the future, use proper SwiftData migrations instead of just changing models.

### 2. Version Detection
Add version checking to detect schema mismatches:

```swift
// In PersistenceService init
do {
    let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
    self.modelContainer = container
    self.isInitialized = true
} catch {
    // Check if this is a schema mismatch error
    if error.localizedDescription.contains("model") ||
       error.localizedDescription.contains("schema") {
        print("⚠️ Schema mismatch detected - database needs reset")
        // Could show alert to user here
    }
    throw error
}
```

### 3. Development vs Production
- **Development**: It's OK to delete app and reinstall during development
- **Production**: Must use proper migrations or app users will lose data!

## Summary

✅ **Immediate Fix**: Delete app and reinstall
✅ **Root Cause**: Old database has versioned schema, new code uses concrete models
✅ **Long-term Solution**: Proper migration planning for production

---

**Last Updated:** November 22, 2025
