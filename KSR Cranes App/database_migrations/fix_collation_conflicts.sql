-- Fix collation conflicts in unified_calendar_view
-- This script addresses MySQL error #1271 - Illegal mix of collations for operation 'UNION'

SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci;

-- Drop existing view if it exists
DROP VIEW IF EXISTS unified_calendar_view;

-- Recreate view with explicit COLLATE clauses to fix collation conflicts
CREATE VIEW unified_calendar_view AS
SELECT 
  CONCAT('leave-', l.id) COLLATE utf8mb4_unicode_ci as event_id,
  'LEAVE' COLLATE utf8mb4_unicode_ci as event_type,
  'WORKFORCE' COLLATE utf8mb4_unicode_ci as category,
  CONCAT(e.name, ' - ', l.type, ' Leave') COLLATE utf8mb4_unicode_ci as title,
  COALESCE(l.reason, CONCAT(l.type, ' leave')) COLLATE utf8mb4_unicode_ci as description,
  CASE WHEN l.emergency_leave = TRUE THEN 'HIGH' ELSE 'MEDIUM' END COLLATE utf8mb4_unicode_ci as priority,
  'ACTIVE' COLLATE utf8mb4_unicode_ci as status,
  l.start_date as start_date,
  l.end_date as end_date,
  NULL as start_time,
  NULL as end_time,
  l.employee_id,
  NULL as project_id,
  NULL as task_id,
  l.id as source_id,
  'leave' COLLATE utf8mb4_unicode_ci as source_type,
  l.created_at,
  l.updated_at
FROM LeaveRequests l
JOIN Employees e ON l.employee_id = e.employee_id
WHERE l.status = 'APPROVED'

UNION ALL

SELECT 
  CONCAT('project-', p.project_id) COLLATE utf8mb4_unicode_ci as event_id,
  'PROJECT' COLLATE utf8mb4_unicode_ci as event_type,
  'PROJECT' COLLATE utf8mb4_unicode_ci as category,
  p.title COLLATE utf8mb4_unicode_ci as title,
  CONCAT(COALESCE(c.name, 'Unknown Customer'), ' - ', COALESCE(p.description, '')) COLLATE utf8mb4_unicode_ci as description,
  'MEDIUM' COLLATE utf8mb4_unicode_ci as priority,
  CASE 
    WHEN p.status = 'aktiv' THEN 'ACTIVE'
    WHEN p.status = 'afsluttet' THEN 'COMPLETED'
    ELSE 'PLANNED'
  END COLLATE utf8mb4_unicode_ci as status,
  p.start_date,
  p.end_date,
  NULL as start_time,
  NULL as end_time,
  NULL as employee_id,
  p.project_id,
  NULL as task_id,
  p.project_id as source_id,
  'project' COLLATE utf8mb4_unicode_ci as source_type,
  p.created_at,
  p.created_at as updated_at
FROM Projects p
LEFT JOIN Customers c ON p.customer_id = c.customer_id
WHERE p.isActive = TRUE

UNION ALL

SELECT 
  CONCAT('task-', t.task_id) COLLATE utf8mb4_unicode_ci as event_id,
  'OPERATOR_ASSIGNMENT' COLLATE utf8mb4_unicode_ci as event_type,
  'PROJECT' COLLATE utf8mb4_unicode_ci as category,
  t.title COLLATE utf8mb4_unicode_ci as title,
  CONCAT(p.title, ' - ', COALESCE(t.description, ''), 
         CASE WHEN t.client_equipment_info IS NOT NULL 
              THEN CONCAT(' (Client Equipment: ', t.client_equipment_info, ')') 
              ELSE '' END) COLLATE utf8mb4_unicode_ci as description,
  COALESCE(t.priority, 'medium') COLLATE utf8mb4_unicode_ci as priority,
  COALESCE(t.status, 'planned') COLLATE utf8mb4_unicode_ci as status,
  COALESCE(t.start_date, t.deadline) as start_date,
  t.deadline as end_date,
  NULL as start_time,
  NULL as end_time,
  NULL as employee_id,
  t.project_id,
  t.task_id,
  t.task_id as source_id,
  'operator_assignment' COLLATE utf8mb4_unicode_ci as source_type,
  t.created_at,
  t.created_at as updated_at
FROM Tasks t
JOIN Projects p ON t.project_id = p.project_id
WHERE t.isActive = TRUE

UNION ALL

SELECT 
  CONCAT('event-', ce.event_id) COLLATE utf8mb4_unicode_ci as event_id,
  ce.event_type COLLATE utf8mb4_unicode_ci as event_type,
  ce.category COLLATE utf8mb4_unicode_ci as category,
  ce.title COLLATE utf8mb4_unicode_ci as title,
  COALESCE(ce.description, '') COLLATE utf8mb4_unicode_ci as description,
  ce.priority COLLATE utf8mb4_unicode_ci as priority,
  ce.status COLLATE utf8mb4_unicode_ci as status,
  ce.start_date,
  ce.end_date,
  ce.start_time,
  ce.end_time,
  ce.employee_id,
  ce.project_id,
  ce.task_id,
  ce.event_id as source_id,
  'calendar_event' COLLATE utf8mb4_unicode_ci as source_type,
  ce.created_at,
  ce.updated_at
FROM CalendarEvents ce;

-- Verify the view was created successfully
SHOW CREATE VIEW unified_calendar_view;

SELECT 'Collation conflicts fixed successfully!' as Status;