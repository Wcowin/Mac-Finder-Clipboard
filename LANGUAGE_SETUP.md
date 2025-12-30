# Language Selection Setup Guide

## What Was Added

A complete internationalization system with Chinese/English language selection has been added to FinderClip.

### New Files Created
- `LocalizationManager.swift` - Core localization system with all translated strings

### Modified Files
- `SettingsManager.swift` - Added language preference storage
- `AppDelegate.swift` - Updated menu bar and about dialog with localized strings
- `SettingsWindowController.swift` - Added language selector UI and localized all strings
- `FinderCutPasteManager.swift` - Updated notifications with localized strings

## Setup Instructions

### Step 1: Add LocalizationManager.swift to Xcode Project

1. Open `FinderClip.xcodeproj` in Xcode
2. Right-click on the project navigator (left sidebar)
3. Select "Add Files to FinderClip..."
4. Navigate to and select `LocalizationManager.swift`
5. Make sure "Copy items if needed" is **unchecked** (file is already in the correct location)
6. Make sure "Add to targets: FinderClip" is **checked**
7. Click "Add"

### Step 2: Build and Test

1. Build the project (⌘+B)
2. Run the application (⌘+R)
3. Open Settings to see the new language selector at the top
4. Switch between Chinese (中文) and English
5. Verify that all UI elements update immediately

## Features

### Language Selection
- **Location**: Settings window, first option with globe icon
- **Options**: 中文 (Chinese) / English
- **Behavior**: Changes take effect immediately across all UI elements

### What Gets Localized
- Menu bar items (Ready, Grant Permission, Settings, About, Quit, etc.)
- Settings window (all labels, buttons, and options)
- About dialog (version, description, shortcuts)
- Notifications (Cut, Cancelled, etc.)
- Shortcut hints (Cut, Paste & Move, Cancel)

### Language Persistence
- Selected language is saved to UserDefaults
- Persists across app restarts
- Default language is based on system language (Chinese for zh-*, English otherwise)

## Technical Details

### Architecture
- `LocalizationManager`: Singleton managing current language and providing translations
- `AppLanguage`: Enum with `.chinese` and `.english` cases
- `LocalizedKey`: Enum containing all translatable strings
- Notification-based updates: UI refreshes when language changes

### Adding New Strings
To add new translatable strings:

1. Add a new case to `LocalizedKey` enum in `LocalizationManager.swift`
2. Add translations in both `chineseString` and `englishString` computed properties
3. Use `LocalizationManager.shared.localized(.yourNewKey)` in your code

### Example Usage
```swift
let loc = LocalizationManager.shared
let title = loc.localized(.menuSettings)
```

## Troubleshooting

### Build Errors
If you see "Cannot find 'LocalizationManager' in scope":
- Ensure `LocalizationManager.swift` is added to the Xcode project target
- Clean build folder (⌘+Shift+K) and rebuild

### Language Not Changing
- Check that notifications are being posted: `.languageChanged`
- Verify UI components are listening for language change notifications
- Restart the app if needed

## Future Enhancements

Potential additions:
- More languages (Japanese, Korean, etc.)
- System language auto-detection improvements
- Export/import language files for community translations
