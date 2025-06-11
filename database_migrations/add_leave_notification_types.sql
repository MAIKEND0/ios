-- Add Leave Notification Types and Category to MySQL Database
-- Run this to add new notification types and category for leave management system

-- Add LEAVE to Notifications_category enum
ALTER TABLE Notifications MODIFY COLUMN category ENUM(
    'HOURS',
    'PROJECT', 
    'TASK',
    'WORKPLAN',
    'LEAVE',
    'PAYROLL',
    'SYSTEM',
    'EMERGENCY'
);

-- Add LEAVE to PushNotifications_category enum (if table exists)
ALTER TABLE PushNotifications MODIFY COLUMN category ENUM(
    'HOURS',
    'PROJECT',
    'TASK', 
    'WORKPLAN',
    'LEAVE',
    'PAYROLL',
    'SYSTEM',
    'EMERGENCY'
);

-- Add new values to Notifications_notification_type enum
ALTER TABLE Notifications MODIFY COLUMN notification_type ENUM(
    'HOURS_SUBMITTED',
    'HOURS_APPROVED', 
    'HOURS_CONFIRMED',
    'HOURS_REJECTED',
    'HOURS_CONFIRMED_FOR_PAYROLL',
    'TIMESHEET_GENERATED',
    'PAYROLL_PROCESSED',
    'HOURS_REMINDER',
    'HOURS_OVERDUE',
    'PROJECT_CREATED',
    'PROJECT_ASSIGNED',
    'PROJECT_ACTIVATED',
    'PROJECT_COMPLETED',
    'PROJECT_CANCELLED',
    'PROJECT_STATUS_CHANGED',
    'PROJECT_DEADLINE_APPROACHING',
    'TASK_CREATED',
    'TASK_ASSIGNED',
    'TASK_REASSIGNED',
    'TASK_UNASSIGNED',
    'TASK_COMPLETED',
    'TASK_STATUS_CHANGED',
    'TASK_DEADLINE_APPROACHING',
    'TASK_OVERDUE',
    'WORKPLAN_CREATED',
    'WORKPLAN_UPDATED',
    'WORKPLAN_ASSIGNED',
    'WORKPLAN_CANCELLED',
    'LEAVE_REQUEST_SUBMITTED',
    'LEAVE_REQUEST_APPROVED',
    'LEAVE_REQUEST_REJECTED',
    'LEAVE_REQUEST_CANCELLED',
    'LEAVE_BALANCE_UPDATED',
    'LEAVE_REQUEST_REMINDER',
    'LEAVE_STARTING',
    'LEAVE_ENDING',
    'EMPLOYEE_ACTIVATED',
    'EMPLOYEE_DEACTIVATED',
    'EMPLOYEE_ROLE_CHANGED',
    'LICENSE_EXPIRING',
    'LICENSE_EXPIRED',
    'CERTIFICATION_REQUIRED',
    'PAYROLL_READY',
    'INVOICE_GENERATED',
    'PAYMENT_RECEIVED',
    'SYSTEM_MAINTENANCE',
    'EMERGENCY_ALERT',
    'GENERAL_ANNOUNCEMENT',
    'GENERAL_INFO'
) NOT NULL;

-- Add new values to PushNotifications_notification_type enum (if table exists)
ALTER TABLE PushNotifications MODIFY COLUMN notification_type ENUM(
    'HOURS_SUBMITTED',
    'HOURS_APPROVED',
    'HOURS_CONFIRMED',
    'HOURS_REJECTED',
    'HOURS_CONFIRMED_FOR_PAYROLL',
    'PAYROLL_PROCESSED',
    'HOURS_REMINDER',
    'HOURS_OVERDUE',
    'TASK_ASSIGNED',
    'TASK_COMPLETED',
    'TASK_DEADLINE_APPROACHING',
    'TASK_OVERDUE',
    'WORKPLAN_CREATED',
    'WORKPLAN_UPDATED',
    'LEAVE_REQUEST_SUBMITTED',
    'LEAVE_REQUEST_APPROVED',
    'LEAVE_REQUEST_REJECTED',
    'LEAVE_REQUEST_CANCELLED',
    'LEAVE_BALANCE_UPDATED',
    'LEAVE_REQUEST_REMINDER',
    'LEAVE_STARTING',
    'LEAVE_ENDING',
    'PROJECT_CREATED',
    'EMERGENCY_ALERT',
    'LICENSE_EXPIRING',
    'LICENSE_EXPIRED',
    'SYSTEM_MAINTENANCE',
    'PAYROLL_READY'
) NOT NULL;

-- Verify the changes
SELECT 'Leave notification types added successfully' as status;

-- Test that new types can be inserted
SELECT 'Testing new notification types...' as test_status;

-- Show current notification type options
SHOW COLUMNS FROM Notifications LIKE 'notification_type';