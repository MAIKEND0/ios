# Firebase Push Notifications Setup Guide

## 1. Firebase Project Setup

### Create Firebase Project
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add project"
3. Enter project name: `ksr-cranes-app`
4. Disable Google Analytics (not needed)
5. Click "Create project"

### Add iOS App to Firebase
1. In Firebase project, click "Add app" → iOS
2. **Bundle ID**: `dk.KSR-Cranes-App` (must match exactly)
3. **App nickname**: `KSR Cranes App`
4. **App Store ID**: Leave empty for now
5. Click "Register app"

### Download GoogleService-Info.plist
1. Download the `GoogleService-Info.plist` file
2. **IMPORTANT**: Add this file to your Xcode project:
   - Drag and drop into Xcode project navigator
   - Make sure "Copy items if needed" is checked
   - Add to KSR Cranes App target
   - Place it in the root of the project (same level as `KSR_Cranes_AppApp.swift`)

## 2. Apple Developer Setup

### APNs Authentication Key
1. Go to [Apple Developer Portal](https://developer.apple.com/account/resources/authkeys/list)
2. Create new Key:
   - **Key Name**: `KSR Cranes Push Notifications`
   - **Services**: Enable "Apple Push Notifications service (APNs)"
3. Download the `.p8` file (save securely - only downloadable once)
4. Note the **Key ID** and **Team ID**

### Configure APNs in Firebase
1. In Firebase Console → Project Settings → Cloud Messaging
2. Under "Apple app configuration":
   - Upload your APNs Authentication Key (.p8 file)
   - Enter Key ID
   - Enter Team ID (from Apple Developer account)

## 3. Xcode Project Configuration

### Add Firebase SDK
1. In Xcode, go to File → Add Package Dependencies
2. Enter URL: `https://github.com/firebase/firebase-ios-sdk`
3. Select "Up to Next Major Version" (11.0.0)
4. Click "Add Package"
5. Select these libraries:
   - **FirebaseCore** ✅
   - **FirebaseMessaging** ✅
   - Do NOT add FirebaseAnalytics or other unnecessary libraries

### Enable Push Notifications Capability
1. In Xcode project navigator, select KSR Cranes App project
2. Select KSR Cranes App target
3. Go to "Signing & Capabilities" tab
4. Click "+ Capability"
5. Add "Push Notifications"

### Background Modes
1. Still in "Signing & Capabilities"
2. Click "+ Capability" 
3. Add "Background Modes"
4. Check "Background processing" and "Remote notifications"

## 4. Server Environment Variables

Add these environment variables to your server deployment:

```bash
# Firebase Admin SDK Configuration
FIREBASE_PROJECT_ID=ksr-cranes-app
FIREBASE_CLIENT_EMAIL=firebase-adminsdk-xxxxx@ksr-cranes-app.iam.gserviceaccount.com
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\nMIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQC...\n-----END PRIVATE KEY-----\n"
```

### Get Firebase Admin SDK Credentials
1. In Firebase Console → Project Settings → Service Accounts
2. Click "Generate new private key"
3. Download the JSON file
4. Extract the values:
   - `project_id` → `FIREBASE_PROJECT_ID`
   - `client_email` → `FIREBASE_CLIENT_EMAIL`
   - `private_key` → `FIREBASE_PRIVATE_KEY` (keep the \n characters)

## 5. Testing

### Test APNs Connection
1. Build and run the app on a physical device (simulator won't work)
2. Check Xcode console for logs:
   ```
   [FirebaseAppDelegate] Firebase configured and push notifications initialized
   [FirebaseAppDelegate] APNs token received
   [FirebaseAppDelegate] FCM token received: [token]
   [PushNotificationService] FCM Token registered: [token]
   [PushNotificationService] Token saved to server: true
   ```

### Send Test Notification
1. In Firebase Console → Cloud Messaging
2. Click "Send your first message"
3. Enter notification title and text
4. Select your iOS app
5. Send immediately
6. Should receive notification on device

## 6. Production Checklist

- [ ] GoogleService-Info.plist added to Xcode project
- [ ] Firebase SDK dependencies added
- [ ] Push Notifications capability enabled
- [ ] Background Modes configured
- [ ] APNs Authentication Key uploaded to Firebase
- [ ] Server environment variables configured
- [ ] Test notification sent successfully
- [ ] App builds without errors
- [ ] Push tokens are being registered to server

## Troubleshooting

### Common Issues
1. **No FCM token received**: Check GoogleService-Info.plist is in project
2. **APNs registration failed**: Verify provisioning profile includes push notifications
3. **Server errors**: Check Firebase Admin SDK credentials
4. **Notifications not received**: Verify APNs key is correctly configured in Firebase

### Debug Commands
```bash
# Check server environment variables
echo $FIREBASE_PROJECT_ID
echo $FIREBASE_CLIENT_EMAIL

# Test Firebase connection (add to server)
curl -X POST http://localhost:3000/api/test-firebase
```

### Bundle ID Verification
The Bundle ID must match exactly:
- **Xcode Project**: `dk.KSR-Cranes-App`
- **Firebase Console**: `dk.KSR-Cranes-App`
- **Apple Developer**: `dk.KSR-Cranes-App`
- **Provisioning Profile**: `dk.KSR-Cranes-App`

If Bundle IDs don't match, notifications will fail silently.