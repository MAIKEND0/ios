# Background Sync Info.plist Configuration

This file contains the necessary changes that need to be made to the Info.plist file to enable background sync functionality.

## Required Info.plist Changes

### 1. Enable Background Modes

Add the following to your Info.plist file:

```xml
<key>UIBackgroundModes</key>
<array>
    <string>fetch</string>
    <string>processing</string>
    <string>remote-notification</string>
</array>
```

### 2. Add Background Task Identifiers

Add these background task identifiers to your Info.plist:

```xml
<key>BGTaskSchedulerPermittedIdentifiers</key>
<array>
    <string>com.ksrcranes.app.backgroundrefresh</string>
    <string>com.ksrcranes.app.datasync</string>
    <string>com.ksrcranes.app.notificationsync</string>
</array>
```

### 3. Background Fetch Interval (Optional)

You can suggest a minimum background fetch interval:

```xml
<key>UIApplicationBackgroundFetchInterval</key>
<integer>1800</integer>
```

This sets the minimum fetch interval to 30 minutes (1800 seconds).

## How to Add These Changes

### Option 1: Using Xcode (Recommended)

1. Open your project in Xcode
2. Select your project in the navigator
3. Select your app target
4. Go to the "Signing & Capabilities" tab
5. Click "+ Capability"
6. Add "Background Modes"
7. Check:
   - Background fetch
   - Background processing
   - Remote notifications

For the BGTaskSchedulerPermittedIdentifiers:
1. Right-click on Info.plist in Xcode
2. Select "Open As" > "Source Code"
3. Add the BGTaskSchedulerPermittedIdentifiers array as shown above

### Option 2: Direct Info.plist Edit

Add these entries directly to your Info.plist file:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- Your existing entries... -->
    
    <!-- Background Modes -->
    <key>UIBackgroundModes</key>
    <array>
        <string>fetch</string>
        <string>processing</string>
        <string>remote-notification</string>
    </array>
    
    <!-- Background Task Identifiers -->
    <key>BGTaskSchedulerPermittedIdentifiers</key>
    <array>
        <string>com.ksrcranes.app.backgroundrefresh</string>
        <string>com.ksrcranes.app.datasync</string>
        <string>com.ksrcranes.app.notificationsync</string>
    </array>
    
    <!-- Optional: Background Fetch Interval -->
    <key>UIApplicationBackgroundFetchInterval</key>
    <integer>1800</integer>
    
    <!-- Your existing entries... -->
</dict>
</plist>
```

## Testing Background Tasks

### Simulator Testing

Background tasks can be tested in the Simulator using the following commands:

```bash
# Trigger background refresh
e -l objc -- (void)[[BGTaskScheduler sharedScheduler] _simulateLaunchForTaskWithIdentifier:@"com.ksrcranes.app.backgroundrefresh"]

# Trigger data sync
e -l objc -- (void)[[BGTaskScheduler sharedScheduler] _simulateLaunchForTaskWithIdentifier:@"com.ksrcranes.app.datasync"]

# Trigger notification sync
e -l objc -- (void)[[BGTaskScheduler sharedScheduler] _simulateLaunchForTaskWithIdentifier:@"com.ksrcranes.app.notificationsync"]
```

### Device Testing

On a real device:
1. Run the app
2. Move it to background
3. Wait for the system to trigger background tasks (or use Xcode's Debug menu)

## Important Notes

1. **Battery Optimization**: iOS will limit background activity based on battery level and app usage patterns
2. **Network Conditions**: Background tasks requiring network connectivity will only run when network is available
3. **User Control**: Users can disable background refresh for your app in Settings
4. **Task Duration**: Background tasks have limited execution time (typically 30 seconds for app refresh, a few minutes for processing tasks)

## Troubleshooting

If background tasks are not running:
1. Ensure Info.plist is properly configured
2. Check that background modes capability is added in Xcode
3. Verify task identifiers match exactly between code and Info.plist
4. Check device settings to ensure background refresh is enabled for your app
5. Test on a real device, as Simulator behavior may differ

## Background Task Types

### BGAppRefreshTask
- Used for: Quick updates (notifications, small data syncs)
- Duration: ~30 seconds
- Frequency: System determined, typically every few hours

### BGProcessingTask
- Used for: Longer operations (database sync, large data processing)
- Duration: Several minutes
- Frequency: Less frequent, often overnight when device is charging

### Remote Notifications
- Used for: Push notification triggered background updates
- Duration: ~30 seconds
- Frequency: On-demand when push notification is received