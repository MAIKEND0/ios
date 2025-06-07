import { PrismaClient } from '@prisma/client';
import { initializeApp, getApps, cert } from 'firebase-admin/app';
import { getMessaging } from 'firebase-admin/messaging';

const prisma = new PrismaClient();

// Initialize Firebase Admin SDK
if (!getApps().length) {
  // You'll need to set these environment variables
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
      console.log('[PushNotificationService] Sending notification to employee:', data.employee_id);
      
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
      
      // Get push settings for this notification type
      const employee = await prisma.employees.findUnique({
        where: { employee_id: data.employee_id },
        select: { role: true }
      });
      
      if (!employee) {
        console.error('[PushNotificationService] Employee not found:', data.employee_id);
        return false;
      }
      
      const pushSettings = await prisma.notificationPushSettings.findFirst({
        where: {
          notification_type: data.notification_type,
          target_role: employee.role as any
        }
      });
      
      // Check if push notifications are enabled for this type
      if (pushSettings && !pushSettings.send_push) {
        console.log('[PushNotificationService] Push disabled for type:', data.notification_type);
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
      
      console.log('[PushNotificationService] FCM Response:', {
        successCount: response.successCount,
        failureCount: response.failureCount
      });
      
      // Log push notification
      await this.logPushNotification(data, response.successCount > 0);
      
      // Handle failed tokens
      if (response.failureCount > 0) {
        await this.handleFailedTokens(tokens, response.responses);
      }
      
      return response.successCount > 0;
      
    } catch (error) {
      console.error('[PushNotificationService] Error sending notification:', error);
      await this.logPushNotification(data, false, error.message);
      return false;
    }
  }
  
  static async sendToRole(role: string, data: Omit<PushNotificationData, 'employee_id'>): Promise<number> {
    try {
      console.log('[PushNotificationService] Sending notification to role:', role);
      
      // Get all employees with this role
      const employees = await prisma.employees.findMany({
        where: {
          role: role as any,
          is_activated: true
        },
        select: { employee_id: true }
      });
      
      let successCount = 0;
      
      // Send to each employee
      for (const employee of employees) {
        const success = await this.sendToEmployee({
          ...data,
          employee_id: employee.employee_id
        });
        
        if (success) successCount++;
      }
      
      console.log('[PushNotificationService] Sent to role:', role, 'Success count:', successCount);
      return successCount;
      
    } catch (error) {
      console.error('[PushNotificationService] Error sending to role:', error);
      return 0;
    }
  }
  
  private static mapPriority(priority: string): string {
    switch (priority) {
      case 'URGENT':
      case 'HIGH':
        return 'high';
      case 'NORMAL':
      case 'LOW':
      default:
        return 'normal';
    }
  }
  
  private static async getUnreadCount(employee_id: number): Promise<number> {
    try {
      const count = await prisma.notifications.count({
        where: {
          employee_id: employee_id,
          is_read: false
        }
      });
      return count;
    } catch (error) {
      console.error('[PushNotificationService] Error getting unread count:', error);
      return 0;
    }
  }
  
  private static async logPushNotification(
    data: PushNotificationData, 
    success: boolean, 
    errorMessage?: string
  ): Promise<void> {
    try {
      await prisma.pushNotifications.create({
        data: {
          employee_id: data.employee_id,
          title: data.title,
          message: data.message,
          notification_type: data.notification_type as any,
          priority: (data.priority || 'NORMAL') as any,
          category: (data.category || 'GENERAL') as any,
          action_required: data.action_required || false,
          status: success ? 'SENT' : 'FAILED',
          error_message: errorMessage,
          sent_at: new Date(),
          expires_at: data.priority === 'URGENT' ? 
            new Date(Date.now() + 24 * 60 * 60 * 1000) : // 24 hours
            new Date(Date.now() + 7 * 24 * 60 * 60 * 1000) // 7 days
        }
      });
    } catch (error) {
      console.error('[PushNotificationService] Error logging push notification:', error);
    }
  }
  
  private static async handleFailedTokens(tokens: any[], responses: any[]): Promise<void> {
    try {
      for (let i = 0; i < responses.length; i++) {
        const response = responses[i];
        if (!response.success && response.error) {
          const token = tokens[i];
          
          // Deactivate invalid tokens
          if (response.error.code === 'messaging/registration-token-not-registered' ||
              response.error.code === 'messaging/invalid-registration-token') {
            
            await prisma.pushTokens.update({
              where: { token_id: token.token_id },
              data: { 
                is_active: false,
                updated_at: new Date()
              }
            });
            
            console.log('[PushNotificationService] Deactivated invalid token:', token.token_id);
          }
        }
      }
    } catch (error) {
      console.error('[PushNotificationService] Error handling failed tokens:', error);
    }
  }
}

// Helper function to integrate with existing notification system
export async function sendPushForNotification(notificationId: number): Promise<boolean> {
  try {
    const notification = await prisma.notifications.findUnique({
      where: { notification_id: notificationId },
      include: {
        Employees: {
          select: { employee_id: true, role: true, name: true }
        }
      }
    });
    
    if (!notification || !notification.Employees) {
      console.error('[PushNotificationService] Notification not found:', notificationId);
      return false;
    }
    
    return await PushNotificationService.sendToEmployee({
      employee_id: notification.employee_id!,
      title: notification.title || notification.notification_type.replace(/_/g, ' '),
      message: notification.message,
      notification_type: notification.notification_type,
      priority: notification.priority as any,
      category: notification.category || undefined,
      action_required: notification.action_required || false,
      metadata: notification.metadata,
      notification_id: notificationId
    });
    
  } catch (error) {
    console.error('[PushNotificationService] Error sending push for notification:', error);
    return false;
  }
}