# Device Activity Monitor Extension Setup

This directory contains the Device Activity Monitor extension for Focus Flow, which provides custom blocking UI and handles Screen Time events.

## Adding the Extension to Xcode Project

Since Xcode project targets must be created through the IDE, follow these steps:

### 1. Create Extension Target in Xcode

1. Open `Focus Flow.xcodeproj` in Xcode
2. Select the project in navigator
3. Click the `+` button at the bottom of the targets list
4. Choose `iOS` → `Application Extension` → `Device Activity Monitor Extension`
5. Set the following:
   - Product Name: `DeviceActivityMonitor`
   - Bundle Identifier: `com.tobiasfu.Focus-Flow.DeviceActivityMonitor`
   - Language: Swift
   - Team: Your development team

### 2. Configure Extension Target

1. **Replace generated files** with the files from this directory:
   - `DeviceActivityMonitor.swift` (replaces the generated monitor)
   - `ShieldConfigurationExtension.swift` (custom shield UI)
   - `Info.plist` (extension configuration)
   - `DeviceActivityMonitor.entitlements` (required permissions)

2. **Set build settings**:
   - iOS Deployment Target: 15.0 or later
   - Code Signing Entitlements: `DeviceActivityMonitor.entitlements`
   - App Groups capability enabled

3. **Add framework dependencies**:
   - DeviceActivity.framework
   - FamilyControls.framework
   - ManagedSettings.framework
   - ManagedSettingsUI.framework

### 3. Update Main App Configuration

Ensure the main app's `Info.plist` includes:

```xml
<key>NSExtension</key>
<dict>
    <key>NSExtensionAttributes</key>
    <dict>
        <key>device-activity-monitor</key>
        <string>DeviceActivityMonitor</string>
    </dict>
</dict>
```

### 4. Test Extension Integration

1. Build and run the main Focus Flow app
2. Navigate to Settings → App Blocking → Advanced Blocking
3. Request Screen Time authorization
4. Select apps to block using the Family Activity Picker
5. Start a focus session in the Timer
6. Try opening a blocked app - you should see the custom shield UI

## Files Overview

- **DeviceActivityMonitor.swift**: Main extension class that handles Screen Time events
- **ShieldConfigurationExtension.swift**: Custom shield UI configuration
- **Info.plist**: Extension metadata and configuration
- **DeviceActivityMonitor.entitlements**: Required permissions for Screen Time access
- **README.md**: This setup guide

## Key Features

- **Custom Shield UI**: Branded blocking screens with different styles per blocking level
- **Event Handling**: Responds to focus session start/end, warnings, and thresholds
- **Shared Configuration**: Reads settings from main app via App Groups
- **Emergency Access**: Handles emergency access requests (logged to shared UserDefaults)
- **Progressive Blocking**: Different shield configurations based on blocking intensity

## Troubleshooting

**Extension not loading**: 
- Verify App Groups entitlement matches main app
- Check bundle identifier format
- Ensure iOS deployment target is 15.0+

**Shields not appearing**:
- Confirm Screen Time authorization granted
- Check that FamilyActivitySelection contains valid tokens
- Verify extension's principal class is correctly set

**Settings not syncing**:
- Check App Groups configuration
- Verify UserDefaults suite name matches
- Ensure both targets have the same App Groups entitlement