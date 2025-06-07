// src/lib/notificationService.ts
import { prisma } from "./prisma";
import { Notifications_target_role, PushNotifications_notification_type, Notifications_category, Notifications_priority } from "@prisma/client";
import admin from 'firebase-admin';

// Initialize Firebase Admin SDK if not already initialized
if (!admin.apps.length) {
  try {
    admin.initializeApp({
      credential: admin.credential.cert({
        projectId: process.env.FIREBASE_PROJECT_ID,
        clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
        privateKey: process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, '\n'),
      }),
    });
    console.log('[NotificationService] Firebase Admin SDK initialized');
  } catch (error) {
    console.error('[NotificationService] Firebase admin initialization error:', error);
  }
}

export interface CreateNotificationParams {
  employeeId: number;
  type: NotificationType;
  title?: string;
  message: string;
  workEntryId?: number;
  taskId?: number;
  projectId?: number;
  priority?: NotificationPriority;
  category?: NotificationCategory;
  actionRequired?: boolean;
  actionUrl?: string;
  expiresAt?: Date;
  senderId?: number;
  targetEmployeeId?: number;
  targetRole?: Notifications_target_role;
  metadata?: Record<string, any>;
}

export type NotificationType = 
  | "HOURS_SUBMITTED"
  | "HOURS_APPROVED" 
  | "HOURS_CONFIRMED"
  | "HOURS_REJECTED"
  | "HOURS_CONFIRMED_FOR_PAYROLL"
  | "TIMESHEET_GENERATED"
  | "PAYROLL_PROCESSED"
  | "HOURS_REMINDER"
  | "HOURS_OVERDUE"
  | "PROJECT_CREATED"
  | "PROJECT_ASSIGNED"
  | "PROJECT_ACTIVATED"
  | "PROJECT_COMPLETED"
  | "PROJECT_CANCELLED"
  | "PROJECT_STATUS_CHANGED"
  | "PROJECT_DEADLINE_APPROACHING"
  | "TASK_CREATED"
  | "TASK_ASSIGNED"
  | "TASK_REASSIGNED"
  | "TASK_UNASSIGNED"
  | "TASK_COMPLETED"
  | "TASK_STATUS_CHANGED"
  | "TASK_DEADLINE_APPROACHING"
  | "TASK_OVERDUE"
  | "WORKPLAN_CREATED"
  | "WORKPLAN_UPDATED"
  | "WORKPLAN_ASSIGNED"
  | "WORKPLAN_CANCELLED"
  | "LEAVE_REQUEST_SUBMITTED"
  | "LEAVE_REQUEST_APPROVED"
  | "LEAVE_REQUEST_REJECTED"
  | "LEAVE_REQUEST_CANCELLED"
  | "LEAVE_BALANCE_UPDATED"
  | "LEAVE_REQUEST_REMINDER"
  | "LEAVE_STARTING"
  | "LEAVE_ENDING"
  | "EMPLOYEE_ACTIVATED"
  | "EMPLOYEE_DEACTIVATED"
  | "EMPLOYEE_ROLE_CHANGED"
  | "LICENSE_EXPIRING"
  | "LICENSE_EXPIRED"
  | "CERTIFICATION_REQUIRED"
  | "PAYROLL_READY"
  | "INVOICE_GENERATED"
  | "PAYMENT_RECEIVED"
  | "SYSTEM_MAINTENANCE"
  | "EMERGENCY_ALERT"
  | "GENERAL_ANNOUNCEMENT"
  | "GENERAL_INFO";

export type NotificationPriority = Notifications_priority;
export type NotificationCategory = Notifications_category;

const mapNotificationType = (type: NotificationType): PushNotifications_notification_type => {
  const validPushTypes: PushNotifications_notification_type[] = [
    "HOURS_SUBMITTED",
    "HOURS_APPROVED",
    "HOURS_CONFIRMED",
    "HOURS_REJECTED",
    "HOURS_CONFIRMED_FOR_PAYROLL",
    "PAYROLL_PROCESSED",
    "HOURS_REMINDER",
    "HOURS_OVERDUE",
    "TASK_ASSIGNED",
    "TASK_COMPLETED",
    "TASK_DEADLINE_APPROACHING",
    "TASK_OVERDUE",
    "WORKPLAN_CREATED",
    "WORKPLAN_UPDATED",
    "LEAVE_REQUEST_SUBMITTED",
    "LEAVE_REQUEST_APPROVED",
    "LEAVE_REQUEST_REJECTED",
    "LEAVE_REQUEST_CANCELLED",
    "LEAVE_BALANCE_UPDATED",
    "LEAVE_REQUEST_REMINDER",
    "LEAVE_STARTING",
    "LEAVE_ENDING",
    "PROJECT_CREATED",
    "EMERGENCY_ALERT",
    "LICENSE_EXPIRING",
    "LICENSE_EXPIRED",
    "SYSTEM_MAINTENANCE",
    "PAYROLL_READY"
  ];
  return validPushTypes.includes(type as PushNotifications_notification_type)
    ? (type as PushNotifications_notification_type)
    : "SYSTEM_MAINTENANCE";
};

/**
 * Tworzy nowe powiadomienie w bazie danych
 */
export async function createNotification(params: CreateNotificationParams) {
  try {
    const notification = await prisma.notifications.create({
      data: {
        employee_id: params.employeeId,
        notification_type: params.type,
        title: params.title,
        message: params.message,
        work_entry_id: params.workEntryId || null,
        task_id: params.taskId || null,
        project_id: params.projectId || null,
        priority: params.priority || "NORMAL",
        category: params.category || "SYSTEM",
        action_required: params.actionRequired || false,
        action_url: params.actionUrl || null,
        expires_at: params.expiresAt || null,
        sender_id: params.senderId || null,
        target_employee_id: params.targetEmployeeId || null,
        target_role: params.targetRole || null,
        metadata: params.metadata || null,
        is_read: false,
      }
    });

    console.log(`[NotificationService] Created notification ${notification.notification_id} for employee ${params.employeeId}`);
    
    console.log(`[NotificationService] About to call sendPushNotificationIfEnabled for notification ${notification.notification_id}, employee ${params.employeeId}`);
    await sendPushNotificationIfEnabled(notification.notification_id, params.employeeId);
    console.log(`[NotificationService] Finished calling sendPushNotificationIfEnabled for notification ${notification.notification_id}`);
    
    return notification;
  } catch (error) {
    console.error("[NotificationService] Failed to create notification:", error);
    throw error;
  }
}

/**
 * Tworzy powiadomienie o odrzuceniu wpisu godzin
 */
export async function createRejectionNotification(
  employeeId: number, 
  workEntryId: number, 
  taskId: number, 
  rejectionReason: string,
  taskTitle?: string,
  projectId?: number
) {
  const title = taskTitle ? `Hours rejected for ${taskTitle}` : "Hours rejected";
  const message = `Your work hours have been rejected. Reason: ${rejectionReason}`;

  return createNotification({
    employeeId,
    type: "HOURS_REJECTED",
    title,
    message,
    workEntryId,
    taskId,
    projectId,
    priority: "HIGH",
    category: "HOURS",
    actionRequired: true,
  });
}

/**
 * Tworzy powiadomienie o odrzuceniu całego tygodnia
 */
export async function createWeekRejectionNotification(
  employeeId: number,
  entryIds: number[],
  taskId: number,
  rejectionReason: string,
  taskTitle: string,
  weekNumber: number,
  year: number,
  projectId?: number,
  problematicDays?: string[]
) {
  const title = `Week ${weekNumber} Hours Rejected for ${taskTitle}`;
  let message = `Your work hours for week ${weekNumber}, ${year} have been rejected. Reason: ${rejectionReason}. Affected entries: ${entryIds.length}.`;
  
  if (problematicDays && problematicDays.length > 0) {
    const formattedDays = problematicDays.map(date => new Date(date).toLocaleDateString('da-DK')).join(', ');
    message += ` Problematic days: ${formattedDays}.`;
  }

  return createNotification({
    employeeId,
    type: "HOURS_REJECTED",
    title,
    message,
    workEntryId: entryIds[0], // Pierwszy wpis jako referencja
    taskId,
    projectId,
    priority: "HIGH",
    category: "HOURS",
    actionRequired: true,
    metadata: {
      weekNumber: weekNumber.toString(),
      year: year.toString(),
      entryCount: entryIds.length.toString(),
      entryIds: JSON.stringify(entryIds),
      problematicDays: problematicDays ? JSON.stringify(problematicDays) : null
    }
  });
}

/**
 * Tworzy powiadomienie o zatwierdzeniu wpisu godzin
 */
export async function createApprovalNotification(
  employeeId: number, 
  workEntryId: number, 
  taskId: number,
  taskTitle?: string,
  projectId?: number
) {
  const title = taskTitle ? `Hours approved for ${taskTitle}` : "Hours approved";
  const message = "Your work hours have been approved and processed.";

  return createNotification({
    employeeId,
    type: "HOURS_CONFIRMED",
    title,
    message,
    workEntryId,
    taskId,
    projectId,
    priority: "NORMAL",
    category: "HOURS",
    actionRequired: false,
  });
}

/**
 * Tworzy powiadomienie o przesłaniu godzin do zatwierdzenia
 */
export async function createSubmissionNotification(
  managerId: number,
  workEntryId: number,
  taskId: number,
  workerName: string,
  taskTitle?: string,
  projectId?: number
) {
  const title = `New hours submitted by ${workerName}`;
  const message = taskTitle 
    ? `${workerName} has submitted work hours for ${taskTitle}. Please review and approve.`
    : `${workerName} has submitted work hours for approval. Please review and approve.`;

  return createNotification({
    employeeId: managerId,
    type: "HOURS_SUBMITTED",
    title,
    message,
    workEntryId,
    taskId,
    projectId,
    priority: "NORMAL",
    category: "HOURS",
    actionRequired: true,
  });
}

/**
 * Tworzy powiadomienie o przypisaniu zadania
 */
export async function createTaskAssignmentNotification(
  employeeId: number,
  taskId: number,
  taskTitle: string,
  projectId?: number,
  assignedBy?: number
) {
  const title = "New task assigned";
  const message = `You have been assigned to task: ${taskTitle}. Please review the task details.`;

  return createNotification({
    employeeId,
    type: "TASK_ASSIGNED",
    title,
    message,
    taskId,
    projectId,
    priority: "NORMAL",
    category: "TASK",
    actionRequired: true,
    senderId: assignedBy,
  });
}

/**
 * Tworzy powiadomienie o wygasającym uprawnieniu
 */
export async function createLicenseExpiryNotification(
  employeeId: number,
  licenseType: string,
  expiryDate: Date,
  daysUntilExpiry: number
) {
  const title = "License expiring soon";
  const message = `Your ${licenseType} expires in ${daysUntilExpiry} days. Please renew it to continue operations.`;

  return createNotification({
    employeeId,
    type: "LICENSE_EXPIRING",
    title,
    message,
    priority: daysUntilExpiry <= 7 ? "HIGH" : "NORMAL",
    category: "SYSTEM",
    actionRequired: true,
    expiresAt: expiryDate,
  });
}

/**
 * Tworzy powiadomienie alarmowe
 */
export async function createEmergencyNotification(
  employeeIds: number[],
  title: string,
  message: string,
  projectId?: number,
  expiresAt?: Date
) {
  const notifications = employeeIds.map(employeeId => 
    createNotification({
      employeeId,
      type: "EMERGENCY_ALERT",
      title,
      message,
      projectId,
      priority: "URGENT",
      category: "EMERGENCY",
      actionRequired: true,
      expiresAt,
    })
  );

  return Promise.all(notifications);
}

/**
 * Tworzy powiadomienie o utworzeniu planu pracy
 */
export async function createWorkPlanNotification(
  employeeId: number,
  taskId: number,
  taskTitle: string,
  weekNumber: number,
  year: number,
  projectId?: number
) {
  const title = "Work plan created";
  const message = `A new work plan has been created for ${taskTitle} (Week ${weekNumber}, ${year}). Please review your schedule.`;

  return createNotification({
    employeeId,
    type: "WORKPLAN_CREATED",
    title,
    message,
    taskId,
    projectId,
    priority: "NORMAL",
    category: "WORKPLAN",
    actionRequired: false,
  });
}

/**
 * Tworzy powiadomienie o przetworzeniu listy płac
 */
export async function createPayrollNotification(
  employeeId: number,
  month: string,
  amount?: number
) {
  const title = "Payroll processed";
  const message = amount 
    ? `Your payroll for ${month} has been processed (${amount} DKK). Payment will be transferred within 24 hours.`
    : `Your payroll for ${month} has been processed. Payment will be transferred within 24 hours.`;

  return createNotification({
    employeeId,
    type: "PAYROLL_PROCESSED",
    title,
    message,
    priority: "NORMAL",
    category: "PAYROLL",
    actionRequired: false,
  });
}

/**
 * Wysyła push notification jeśli jest włączone
 */
async function sendPushNotificationIfEnabled(notificationId: number, employeeId: number) {
  console.log(`[NotificationService] 🚀 sendPushNotificationIfEnabled called for notification ${notificationId}, employee ${employeeId}`);
  try {
    // Sprawdź czy employee ma aktywne push tokeny
    const pushTokens = await prisma.pushTokens.findMany({
      where: {
        employee_id: employeeId,
        is_active: true
      }
    });

    console.log(`[NotificationService] Found ${pushTokens.length} active push tokens for employee ${employeeId}`);

    if (pushTokens.length === 0) {
      console.log(`[NotificationService] No active push tokens for employee ${employeeId}`);
      return;
    }

    // Pobierz szczegóły powiadomienia
    const notification = await prisma.notifications.findUnique({
      where: { notification_id: notificationId }
    });

    if (!notification) {
      console.error(`[NotificationService] Notification ${notificationId} not found`);
      return;
    }

    // Zapisz push notification w bazie
    const pushNotification = await prisma.pushNotifications.create({
      data: {
        employee_id: employeeId,
        title: notification.title || "New notification",
        message: notification.message,
        priority: notification.priority || "NORMAL",
        category: notification.category || "SYSTEM",
        action_required: notification.action_required || false,
        notification_type: mapNotificationType(notification.notification_type),
        status: "PENDING"
      }
    });

    // Wyślij faktyczne push notifications przez Firebase
    const results = await Promise.all(
      pushTokens.map(async (token) => {
        try {
          const pushMessage = {
            notification: {
              title: notification.title || "New notification",
              body: notification.message
            },
            data: {
              notification_id: notificationId.toString(),
              notification_type: notification.notification_type,
              category: notification.category || '',
              priority: notification.priority || 'NORMAL',
              project_id: notification.project_id?.toString() || '',
              task_id: notification.task_id?.toString() || '',
              work_entry_id: notification.work_entry_id?.toString() || ''
            },
            token: token.token,
            apns: {
              payload: {
                aps: {
                  'mutable-content': 1,
                  sound: 'default',
                  badge: 1,
                  'thread-id': notification.category || 'general'
                }
              },
              headers: {
                'apns-priority': notification.priority === 'URGENT' ? '10' : '5'
              }
            }
          };

          console.log(`[NotificationService] About to send push message to token ${token.token_id}`, pushMessage);
          const response = await admin.messaging().send(pushMessage);
          console.log(`[NotificationService] Push sent successfully to token ${token.token_id}:`, response);
          
          // Update last_used_at for token
          await prisma.pushTokens.update({
            where: { token_id: token.token_id },
            data: { last_used_at: new Date() }
          });

          // Update push notification status
          await prisma.pushNotifications.update({
            where: { notification_id: pushNotification.notification_id },
            data: { 
              status: 'SENT',
              token_id: token.token_id 
            }
          });

          return { token_id: token.token_id, success: true };
        } catch (error: any) {
          console.error(`[NotificationService] Failed to send push to token ${token.token_id}:`, error);
          
          // If token is invalid, deactivate it
          if (error.code === 'messaging/invalid-registration-token' || 
              error.code === 'messaging/registration-token-not-registered') {
            await prisma.pushTokens.update({
              where: { token_id: token.token_id },
              data: { is_active: false }
            });
          }

          return { token_id: token.token_id, success: false, error: error.message };
        }
      })
    );

    const successCount = results.filter(r => r.success).length;
    console.log(`[NotificationService] Sent push notification to ${successCount}/${pushTokens.length} devices for employee ${employeeId}`);
    
  } catch (error) {
    console.error("[NotificationService] Failed to send push notification:", error);
  }
  console.log(`[NotificationService] 🏁 sendPushNotificationIfEnabled completed for notification ${notificationId}, employee ${employeeId}`);
}

/**
 * Oznacza powiadomienia jako przeczytane
 */
export async function markNotificationsAsRead(notificationIds: number[], employeeId: number) {
  try {
    const result = await prisma.notifications.updateMany({
      where: {
        notification_id: { in: notificationIds },
        employee_id: employeeId,
        is_read: false
      },
      data: {
        is_read: true,
        read_at: new Date()
      }
    });

    console.log(`[NotificationService] Marked ${result.count} notifications as read for employee ${employeeId}`);
    return result;
  } catch (error) {
    console.error("[NotificationService] Failed to mark notifications as read:", error);
    throw error;
  }
}

/**
 * Usuwa wygasłe powiadomienia
 */
export async function cleanupExpiredNotifications() {
  try {
    const result = await prisma.notifications.deleteMany({
      where: {
        expires_at: {
          lt: new Date()
        }
      }
    });

    console.log(`[NotificationService] Cleaned up ${result.count} expired notifications`);
    return result;
  } catch (error) {
    console.error("[NotificationService] Failed to cleanup expired notifications:", error);
    throw error;
  }
}

/**
 * Pobiera statystyki powiadomień dla pracownika
 */
export async function getNotificationStats(employeeId: number) {
  try {
    const [unreadCount, totalCount, urgentCount] = await Promise.all([
      prisma.notifications.count({
        where: { employee_id: employeeId, is_read: false }
      }),
      prisma.notifications.count({
        where: { employee_id: employeeId }
      }),
      prisma.notifications.count({
        where: { 
          employee_id: employeeId, 
          is_read: false,
          priority: "URGENT"
        }
      })
    ]);

    return {
      unreadCount,
      totalCount,
      urgentCount
    };
  } catch (error) {
    console.error("[NotificationService] Failed to get notification stats:", error);
    throw error;
  }
}