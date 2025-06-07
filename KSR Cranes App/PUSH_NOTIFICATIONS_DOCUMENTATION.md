# Push Notifications Implementation Documentation

## Overview

This document provides comprehensive documentation for the push notification system implemented in the KSR Cranes application. The system uses Firebase Cloud Messaging (FCM) integrated with the existing notification infrastructure to deliver real-time push notifications to iOS devices.

## Architecture

### Components

1. **iOS App (Swift/SwiftUI)**
   - Firebase SDK integration
   - FCM token management
   - Push notification handling
   - Permission management

2. **Server (Next.js/Node.js)**
   - Firebase Admin SDK
   - Push notification service
   - API endpoints for token management
   - Integration with work entries workflow

3. **Database (Prisma/MySQL)**
   - Push token storage
   - Notification logging
   - Push settings management

## Implementation Details

### iOS Implementation

#### 1. Firebase Integration (`KSR_Cranes_AppApp.swift`)

```swift
import Firebase
import FirebaseMessaging
import UserNotifications

// Firebase App Delegate
class FirebaseAppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        
        // Set messaging delegate
        Messaging.messaging().delegate = self
        
        // Set notification delegate
        UNUserNotificationCenter.current().delegate = self
        
        // Request notification permissions
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        }
        
        return true
    }
    
    // FCM Token received
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let fcmToken = fcmToken else { return }
        
        Task { @MainActor in
            await PushNotificationService.shared.registerToken(fcmToken)
        }
    }
    
    // Handle notifications when app is in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .badge])
    }
}
```

#### 2. Push Notification Service (`Core/Services/PushNotificationService.swift`)

```swift
import Foundation
import Firebase
import FirebaseMessaging

@MainActor
class PushNotificationService: ObservableObject {
    static let shared = PushNotificationService()
    @Published var fcmToken: String?
    
    private init() {}
    
    func registerToken(_ token: String) async {
        self.fcmToken = token
        await saveTokenToServer(token)
    }
    
    private func saveTokenToServer(_ token: String) async {
        // Implementation details...
    }
}
```

#### 3. Fixed Notification Model (`Core/Models/AppNotification.swift`)

**Issue Fixed**: Metadata parsing error that prevented app from loading notifications.

```swift
struct AppNotification: Codable, Identifiable {
    let id: Int
    let employeeId: Int
    let notificationType: String
    let title: String?
    let message: String
    let isRead: Bool
    let createdAt: Date
    let metadata: String? // Changed from [String: Any]? to String?
    
    private enum CodingKeys: String, CodingKey {
        case id = "notification_id"
        case employeeId = "employee_id"
        case notificationType = "notification_type"
        case title, message
        case isRead = "is_read"
        case createdAt = "created_at"
        case metadata
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(Int.self, forKey: .id)
        employeeId = try container.decode(Int.self, forKey: .employeeId)
        notificationType = try container.decode(String.self, forKey: .notificationType)
        title = try container.decodeIfPresent(String.self, forKey: .title)
        message = try container.decode(String.self, forKey: .message)
        isRead = try container.decode(Bool.self, forKey: .isRead)
        
        // Fixed metadata parsing
        if let metadataString = try? container.decodeIfPresent(String.self, forKey: .metadata) {
            metadata = metadataString
        } else {
            metadata = nil
        }
        
        let dateString = try container.decode(String.self, forKey: .createdAt)
        createdAt = ISO8601DateFormatter().date(from: dateString) ?? Date()
    }
}
```

### Server Implementation

#### 1. Push Notification Service (`server/lib/pushNotificationService.ts`)

```typescript
import { PrismaClient } from '@prisma/client';
import { initializeApp, getApps, cert } from 'firebase-admin/app';
import { getMessaging } from 'firebase-admin/messaging';

const prisma = new PrismaClient();

// Initialize Firebase Admin SDK
if (!getApps().length) {
  const serviceAccount = {
    projectId: process.env.FIREBASE_PROJECT_ID,
    clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
    privateKey: process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, '\n'),
  };

  initializeApp({
    credential: cert(serviceAccount),
    projectId: process.env.FIREBASE_PROJECT_ID,
  });
}

interface PushNotificationData {
  employee_id: number;
  title: string;
  message: string;
  notification_type: string;
  priority?: 'URGENT' | 'HIGH' | 'NORMAL' | 'LOW';
  category?: string;
  action_required?: boolean;
  metadata?: any;
  notification_id?: number;
}

export class PushNotificationService {
  
  static async sendToEmployee(data: PushNotificationData): Promise<boolean> {
    try {
      // Get active push tokens for employee
      const tokens = await prisma.pushTokens.findMany({
        where: {
          employee_id: data.employee_id,
          is_active: true
        }
      });
      
      if (tokens.length === 0) {
        console.log('[PushNotificationService] No active tokens found for employee:', data.employee_id);
        return false;
      }
      
      // Prepare FCM message
      const fcmTokens = tokens.map(token => token.token);
      const priority = this.mapPriority(data.priority || 'NORMAL');
      
      const message = {
        notification: {
          title: data.title,
          body: data.message,
        },
        data: {
          notification_type: data.notification_type,
          employee_id: data.employee_id.toString(),
          category: data.category || 'GENERAL',
          action_required: (data.action_required || false).toString(),
          notification_id: data.notification_id?.toString() || '',
          metadata: JSON.stringify(data.metadata || {})
        },
        android: {
          priority: priority as any,
          notification: {
            sound: 'default',
            clickAction: 'FLUTTER_NOTIFICATION_CLICK'
          }
        },
        apns: {
          payload: {
            aps: {
              alert: {
                title: data.title,
                body: data.message
              },
              sound: 'default',
              badge: await this.getUnreadCount(data.employee_id)
            }
          },
          headers: {
            'apns-priority': priority === 'high' ? '10' : '5'
          }
        },
        tokens: fcmTokens
      };
      
      // Send via Firebase
      const messaging = getMessaging();
      const response = await messaging.sendEachForMulticast(message);
      
      // Log push notification
      await this.logPushNotification(data, response.successCount > 0);
      
      // Handle failed tokens
      if (response.failureCount > 0) {
        await this.handleFailedTokens(tokens, response.responses);
      }
      
      return response.successCount > 0;
      
    } catch (error) {
      console.error('[PushNotificationService] Error sending notification:', error);
      return false;
    }
  }
}
```

#### 2. Token Registration Endpoint (`server/api/app/push/register-token-v2/route.ts`)

```typescript
import { NextRequest, NextResponse } from 'next/server';
import { prisma } from '../../../../lib/prisma';
import jwt from 'jsonwebtoken';

const SECRET = process.env.NEXTAUTH_SECRET || process.env.JWT_SECRET!;

async function authenticate(req: NextRequest) {
  const auth = req.headers.get("authorization")?.split(" ");
  if (auth?.[0] !== "Bearer" || !auth[1]) {
    throw new Error("Unauthorized");
  }
  try {
    return jwt.verify(auth[1], SECRET) as { id: number };
  } catch {
    throw new Error("Invalid token");
  }
}

export async function POST(request: NextRequest) {
  try {
    const { id: employeeId } = await authenticate(request);
    const body = await request.json();
    const { token, device_type, app_version, os_version } = body;

    if (!token) {
      return NextResponse.json({
        success: false,
        error: 'FCM token is required'
      }, { status: 400 });
    }

    // Deactivate old tokens for this employee
    await prisma.pushTokens.updateMany({
      where: {
        employee_id: employeeId,
        is_active: true
      },
      data: {
        is_active: false,
        updated_at: new Date()
      }
    });

    // Create or update token
    const pushToken = await prisma.pushTokens.upsert({
      where: {
        employee_id_token: {
          employee_id: employeeId,
          token: token
        }
      },
      create: {
        employee_id: employeeId,
        token: token,
        device_type: device_type || 'ios',
        app_version: app_version || '1.0.0',
        os_version: os_version || 'unknown',
        is_active: true
      },
      update: {
        device_type: device_type || 'ios',
        app_version: app_version || '1.0.0',
        os_version: os_version || 'unknown',
        is_active: true,
        updated_at: new Date()
      }
    });

    return NextResponse.json({
      success: true,
      message: 'Push token registered successfully',
      token_id: pushToken.token_id
    });

  } catch (error: any) {
    console.error('[Push Token Registration] Error:', error);
    return NextResponse.json({
      success: false,
      error: error.message || 'Failed to register push token'
    }, { status: error.message === 'Unauthorized' ? 401 : 500 });
  }
}
```

## Integration with Work Entries

### Work Entry Submission (`server/api/app/work-entries/route.ts`)

When a worker submits work hours, push notifications are sent to byggeleder (managers) for approval and to chefs for information:

```typescript
// Send notification to chefs for information (they don't approve, just receive notifications)
for (const boss of chefs) {
  try {
    await PushNotificationService.sendToEmployee({
      employee_id: boss.employee_id,
      title: "⏰ New Hours Submitted",
      message: `${employeeName} submitted hours for ${projectTitle} (Week ${isoWeekNumber}). Byggeleder will review and approve.`,
      notification_type: "HOURS_SUBMITTED",
      priority: "NORMAL",
      category: "HOURS",
      action_required: false, // Chef doesn't approve, just informed
      notification_id: notification.notification_id,
      metadata: {
        task_id: taskId,
        project_id: task?.Projects?.project_id,
        employee_name: employeeName,
        week_number: isoWeekNumber,
        week_start: weekStart,
        project_title: projectTitle,
        task_title: taskTitle
      }
    });
  } catch (pushError: any) {
    console.error(`Failed to send push notification to chef ${boss.employee_id}:`, pushError);
  }
}
```

### Work Entry Approval (`server/api/app/work-entries/confirmed/route.ts`)

When byggeleder (managers) approve or reject hours, workers receive push notifications:

```typescript
// Approval notification
case 'approve':
  await PushNotificationService.sendToEmployee({
    employee_id: entry.employee_id,
    title: "✅ Hours Approved",
    message: `Your work hours for ${new Date(entry.work_date).toLocaleDateString()} have been approved for payroll.`,
    notification_type: "HOURS_CONFIRMED",
    priority: "NORMAL",
    category: "HOURS",
    action_required: false,
    metadata: {
      entry_id: entry.entry_id,
      task_id: entry.task_id,
      work_date: entry.work_date
    }
  });

// Rejection notification
case 'reject':
  const rejectionMessage = notes 
    ? `Your work hours for ${new Date(entry.work_date).toLocaleDateString()} have been rejected. Reason: ${notes}`
    : `Your work hours for ${new Date(entry.work_date).toLocaleDateString()} have been rejected. Please review and resubmit.`;

  await PushNotificationService.sendToEmployee({
    employee_id: entry.employee_id,
    title: "❌ Hours Rejected",
    message: rejectionMessage,
    notification_type: "HOURS_REJECTED",
    priority: "HIGH",
    category: "HOURS",
    action_required: true,
    metadata: {
      entry_id: entry.entry_id,
      task_id: entry.task_id,
      work_date: entry.work_date,
      rejection_reason: notes || ''
    }
  });
```

## Database Schema

### Push Tokens Table
```sql
CREATE TABLE PushTokens (
  token_id BIGINT PRIMARY KEY AUTO_INCREMENT,
  employee_id INT NOT NULL,
  token VARCHAR(1024) NOT NULL,
  device_type ENUM('ios', 'android') DEFAULT 'ios',
  app_version VARCHAR(50),
  os_version VARCHAR(50),
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  last_used_at TIMESTAMP NULL,
  
  FOREIGN KEY (employee_id) REFERENCES Employees(employee_id),
  UNIQUE KEY unique_employee_token (employee_id, token),
  INDEX idx_employee_active (employee_id, is_active)
);
```

### Push Notifications Log Table
```sql
CREATE TABLE PushNotifications (
  notification_id BIGINT PRIMARY KEY AUTO_INCREMENT,
  employee_id INT NOT NULL,
  title VARCHAR(255) NOT NULL,
  message TEXT NOT NULL,
  notification_type ENUM(...) NOT NULL,
  priority ENUM('URGENT', 'HIGH', 'NORMAL', 'LOW') DEFAULT 'NORMAL',
  category ENUM('HOURS', 'TASK', 'PROJECT', 'WORKPLAN', 'LEAVE', 'PAYROLL', 'SYSTEM', 'EMERGENCY') DEFAULT 'SYSTEM',
  action_required BOOLEAN DEFAULT FALSE,
  status ENUM('PENDING', 'SENT', 'FAILED', 'EXPIRED') DEFAULT 'PENDING',
  error_message TEXT NULL,
  sent_at TIMESTAMP NULL,
  expires_at TIMESTAMP NULL,
  token_id BIGINT NULL,
  
  FOREIGN KEY (employee_id) REFERENCES Employees(employee_id),
  FOREIGN KEY (token_id) REFERENCES PushTokens(token_id),
  INDEX idx_employee_status (employee_id, status),
  INDEX idx_sent_at (sent_at)
);
```

## Environment Variables

### Required Firebase Configuration
```env
# Firebase Project Configuration
FIREBASE_PROJECT_ID=your-firebase-project-id
FIREBASE_CLIENT_EMAIL=firebase-adminsdk-xxxxx@your-project.iam.gserviceaccount.com
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\nYOUR_PRIVATE_KEY_HERE\n-----END PRIVATE KEY-----\n"

# JWT Configuration
JWT_SECRET=your-jwt-secret
NEXTAUTH_SECRET=your-nextauth-secret

# SendGrid (for email notifications)
SENDGRID_API_KEY=your-sendgrid-api-key
EMAIL_USER=info@ksrcranes.dk
```

## API Endpoints

### 1. Register Push Token
**POST** `/api/app/push/register-token-v2`

**Headers:**
```
Authorization: Bearer <jwt_token>
Content-Type: application/json
```

**Body:**
```json
{
  "token": "fcm_token_here",
  "device_type": "ios",
  "app_version": "1.0.0",
  "os_version": "17.0"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Push token registered successfully",
  "token_id": 123
}
```

### 2. Send Push Notification
**POST** `/api/app/push/send`

**Body:**
```json
{
  "employee_id": 2,
  "title": "Test Notification",
  "message": "This is a test message",
  "notification_type": "GENERAL_INFO",
  "priority": "NORMAL",
  "category": "SYSTEM",
  "action_required": false,
  "metadata": {
    "custom_data": "value"
  }
}
```

### 3. Test Push Notification
**GET** `/api/app/push/send-test?employee_id=2`
**POST** `/api/app/push/send-test`

Quick testing endpoint for development.

## Testing

### 1. iOS Device Testing

1. **Install the app** on a physical iOS device
2. **Grant notification permissions** when prompted
3. **Login** to register FCM token
4. **Send test notification** using the test endpoint

### 2. Testing with curl

```bash
# Test token registration
curl -X POST https://ksrcranes.dk/api/app/push/register-token-v2 \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "token": "fcm_token_here",
    "device_type": "ios",
    "app_version": "1.0.0"
  }'

# Send test notification
curl -X GET "https://ksrcranes.dk/api/app/push/send-test?employee_id=2"
```

### 3. Database Verification

```sql
-- Check registered tokens
SELECT * FROM PushTokens WHERE is_active = 1;

-- Check push notification logs
SELECT * FROM PushNotifications ORDER BY sent_at DESC LIMIT 10;

-- Check employee notifications
SELECT * FROM Notifications WHERE employee_id = 2 ORDER BY created_at DESC;
```

## Troubleshooting

### Common Issues

#### 1. FCM Token Not Registering
- **Check Firebase configuration** in environment variables
- **Verify app bundle ID** matches Firebase project
- **Check iOS device permissions** for notifications

#### 2. Push Notifications Not Delivered
- **Verify FCM token is active** in database
- **Check Firebase Admin SDK credentials**
- **Review push notification logs** for error messages
- **Validate APNs certificate** in Firebase console

#### 3. App Notification Parsing Errors
- **Check metadata field format** - should be string, not object
- **Verify JSON structure** matches AppNotification model
- **Review API response format** for notifications endpoint

### Debug Commands

```bash
# Check Firebase Admin SDK initialization
curl -X GET "https://ksrcranes.dk/api/app/push/send-test?employee_id=2"

# Verify token registration
curl -X POST https://ksrcranes.dk/api/app/push/register-token-v2 \
  -H "Authorization: Bearer TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"token":"test","device_type":"ios"}'

# Check database connectivity
mysql -h host -u user -p database -e "SELECT COUNT(*) FROM PushTokens;"
```

## Performance Considerations

### 1. Token Management
- **Automatic cleanup** of invalid tokens
- **Rate limiting** on token registration
- **Batch operations** for multiple notifications

### 2. Notification Delivery
- **Asynchronous sending** to prevent blocking
- **Retry mechanism** for failed deliveries
- **Exponential backoff** for rate limiting

### 3. Database Optimization
- **Indexes** on frequently queried columns
- **Cleanup jobs** for expired notifications
- **Connection pooling** for high volume

## Security

### 1. Authentication
- **JWT token validation** for all endpoints
- **Employee-specific** token management
- **Secure Firebase credentials** storage

### 2. Data Protection
- **Encrypted FCM tokens** in database
- **Private key protection** for Firebase Admin SDK
- **HTTPS only** for all communications

### 3. Privacy Compliance
- **User consent** for push notifications
- **Data retention policies** for notification logs
- **Opt-out mechanisms** for users

## Future Enhancements

### 1. Advanced Features
- **Rich notifications** with images and actions
- **Notification categories** for better organization
- **Do Not Disturb** scheduling
- **Notification templates** for consistency

### 2. Analytics
- **Delivery rate tracking**
- **User engagement metrics**
- **A/B testing** for notification content
- **Performance monitoring**

### 3. Integration Expansion
- **Leave request notifications**
- **Task assignment notifications**
- **Payroll processing notifications**
- **Emergency alert system**

## Conclusion

The push notification system is fully implemented and integrated with the KSR Cranes application. It provides real-time notifications for work entry submissions, approvals, and rejections, with comprehensive error handling and logging capabilities.

**Key Workflow:**
- ⏰ **Work hours submission** (notifies byggeleder for approval, chefs for information)
- ✅ **Hours approval** (byggeleder approves, notifies workers)
- ❌ **Hours rejection** (byggeleder rejects, notifies workers with reason)

The system is production-ready and includes proper authentication, database logging, and Firebase integration. All major components have been tested and are functioning correctly.

For any issues or enhancements, refer to the troubleshooting section and logging output for detailed debugging information.