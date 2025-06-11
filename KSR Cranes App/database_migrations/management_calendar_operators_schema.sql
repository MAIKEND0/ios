-- Management Calendar Database Extensions for Crane Operator Staffing
-- Tailored for KSR Cranes business model: providing crane operators, not equipment

-- 1. Add missing fields to Tasks table
ALTER TABLE Tasks 
ADD COLUMN start_date DATE NULL AFTER deadline,
ADD COLUMN status ENUM('planned', 'in_progress', 'completed', 'cancelled', 'overdue') DEFAULT 'planned' AFTER isActive,
ADD COLUMN priority ENUM('low', 'medium', 'high', 'critical') DEFAULT 'medium' AFTER status,
ADD COLUMN estimated_hours DECIMAL(5,2) NULL AFTER priority,
ADD COLUMN required_operators INT DEFAULT 1 AFTER estimated_hours,
ADD COLUMN client_equipment_info TEXT NULL AFTER required_operators;

-- 1a. Extend TaskAssignments for operator scheduling
ALTER TABLE TaskAssignments
ADD COLUMN work_date DATE NULL AFTER assigned_at,
ADD COLUMN status ENUM('assigned', 'active', 'completed', 'cancelled') DEFAULT 'assigned' AFTER work_date,
ADD COLUMN notes TEXT NULL AFTER status;

-- 2. Add missing fields to Projects table  
ALTER TABLE Projects
ADD COLUMN budget DECIMAL(12,2) NULL AFTER isActive,
ADD COLUMN client_equipment_type VARCHAR(255) NULL AFTER budget,
ADD COLUMN operator_requirements TEXT NULL AFTER client_equipment_type;

-- 3. Create Calendar Events table for operator scheduling
CREATE TABLE IF NOT EXISTS CalendarEvents (
  event_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  title VARCHAR(255) NOT NULL,
  description TEXT NULL,
  event_type ENUM('operator_assignment', 'training', 'meeting', 'deadline', 'certification_check', 'client_visit', 'other') NOT NULL,
  category ENUM('workforce', 'project', 'training', 'business', 'compliance') NOT NULL,
  start_date DATE NOT NULL,
  end_date DATE NULL,
  start_time TIME NULL,
  end_time TIME NULL,
  priority ENUM('low', 'medium', 'high', 'critical') DEFAULT 'medium',
  status ENUM('planned', 'active', 'completed', 'cancelled') DEFAULT 'planned',
  location VARCHAR(255) NULL,
  
  -- Related entities
  project_id INT UNSIGNED NULL,
  task_id INT UNSIGNED NULL,
  employee_id INT UNSIGNED NULL,
  
  -- Recurrence information
  is_recurring BOOLEAN DEFAULT FALSE,
  recurrence_pattern VARCHAR(100) NULL,
  recurrence_end_date DATE NULL,
  
  -- Metadata
  created_by INT UNSIGNED NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  
  FOREIGN KEY (project_id) REFERENCES Projects(project_id) ON DELETE CASCADE,
  FOREIGN KEY (task_id) REFERENCES Tasks(task_id) ON DELETE CASCADE,
  FOREIGN KEY (employee_id) REFERENCES Employees(employee_id) ON DELETE CASCADE,
  FOREIGN KEY (created_by) REFERENCES Employees(employee_id) ON DELETE NO ACTION,
  
  INDEX idx_calendar_events_dates (start_date, end_date),
  INDEX idx_calendar_events_type (event_type),
  INDEX idx_calendar_events_category (category),
  INDEX idx_calendar_events_priority (priority),
  INDEX idx_calendar_events_status (status),
  INDEX idx_calendar_events_project (project_id),
  INDEX idx_calendar_events_task (task_id),
  INDEX idx_calendar_events_employee (employee_id),
  INDEX idx_calendar_events_recurring (is_recurring, recurrence_end_date)
);

-- 4. Create Calendar Conflicts table for operator scheduling conflicts
CREATE TABLE IF NOT EXISTS CalendarConflicts (
  conflict_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  conflict_type ENUM('operator_unavailable', 'skills_mismatch', 'capacity_exceeded', 'deadline_conflict', 'leave_conflict', 'certification_expired') NOT NULL,
  severity ENUM('low', 'medium', 'high', 'critical') NOT NULL,
  description TEXT NOT NULL,
  resolution TEXT NULL,
  
  -- Source events causing conflict
  source_type ENUM('task', 'project', 'leave', 'calendar_event', 'operator_assignment') NOT NULL,
  source_id INT UNSIGNED NOT NULL,
  
  -- Target events affected by conflict
  target_type ENUM('task', 'project', 'leave', 'calendar_event', 'operator_assignment') NOT NULL,
  target_id INT UNSIGNED NOT NULL,
  
  -- Affected operators
  affected_employee_ids JSON NULL,
  
  -- Conflict timeframe
  conflict_start_date DATE NOT NULL,
  conflict_end_date DATE NOT NULL,
  
  -- Resolution tracking
  status ENUM('detected', 'acknowledged', 'resolved', 'ignored') DEFAULT 'detected',
  resolved_by INT UNSIGNED NULL,
  resolved_at TIMESTAMP NULL,
  
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  
  FOREIGN KEY (resolved_by) REFERENCES Employees(employee_id) ON DELETE SET NULL,
  
  INDEX idx_calendar_conflicts_type (conflict_type),
  INDEX idx_calendar_conflicts_severity (severity),
  INDEX idx_calendar_conflicts_dates (conflict_start_date, conflict_end_date),
  INDEX idx_calendar_conflicts_status (status),
  INDEX idx_calendar_conflicts_source (source_type, source_id),
  INDEX idx_calendar_conflicts_target (target_type, target_id)
);

-- 5. Enhanced Worker Skills table for crane operator certifications (Danish system)
CREATE TABLE IF NOT EXISTS WorkerSkills (
  skill_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  employee_id INT UNSIGNED NOT NULL,
  skill_name VARCHAR(100) NOT NULL,
  skill_level ENUM('beginner', 'intermediate', 'advanced', 'expert') NOT NULL,
  is_certified BOOLEAN DEFAULT FALSE,
  certification_number VARCHAR(100) NULL,
  certification_expires DATE NULL,
  years_experience INT UNSIGNED DEFAULT 0,
  crane_type_specialization VARCHAR(100) NULL, -- Mobile, Tower, Mini, etc.
  notes TEXT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  
  FOREIGN KEY (employee_id) REFERENCES Employees(employee_id) ON DELETE CASCADE,
  
  UNIQUE KEY unique_employee_skill (employee_id, skill_name),
  INDEX idx_worker_skills_employee (employee_id),
  INDEX idx_worker_skills_name (skill_name),
  INDEX idx_worker_skills_level (skill_level),
  INDEX idx_worker_skills_certified (is_certified),
  INDEX idx_worker_skills_expiring (certification_expires),
  INDEX idx_worker_skills_crane_type (crane_type_specialization)
);

-- 6. Add indexes for better calendar performance
ALTER TABLE LeaveRequests 
ADD INDEX idx_leave_calendar_dates (start_date, end_date, status),
ADD INDEX idx_leave_calendar_employee_dates (employee_id, start_date, end_date);

ALTER TABLE Tasks
ADD INDEX idx_tasks_calendar_dates (start_date, deadline),
ADD INDEX idx_tasks_calendar_status (status, priority);

ALTER TABLE Projects
ADD INDEX idx_projects_calendar_dates (start_date, end_date, status);

ALTER TABLE TaskAssignments
ADD INDEX idx_task_assignments_employee_date (employee_id, assigned_at),
ADD INDEX idx_task_assignments_work_date (work_date, status),
ADD INDEX idx_task_assignments_employee_work_date (employee_id, work_date);

-- 7. Create Calendar Settings table for user preferences
CREATE TABLE IF NOT EXISTS CalendarSettings (
  setting_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  employee_id INT UNSIGNED NOT NULL,
  default_view ENUM('month', 'week', 'timeline') DEFAULT 'month',
  show_weekends BOOLEAN DEFAULT TRUE,
  show_leave_requests BOOLEAN DEFAULT TRUE,
  show_tasks BOOLEAN DEFAULT TRUE,
  show_projects BOOLEAN DEFAULT TRUE,
  show_operator_assignments BOOLEAN DEFAULT TRUE,
  show_conflicts BOOLEAN DEFAULT TRUE,
  work_hours_start TIME DEFAULT '08:00:00',
  work_hours_end TIME DEFAULT '16:00:00',
  timezone VARCHAR(50) DEFAULT 'Europe/Copenhagen',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  
  FOREIGN KEY (employee_id) REFERENCES Employees(employee_id) ON DELETE CASCADE,
  UNIQUE KEY unique_employee_settings (employee_id)
);

-- 8. Insert default calendar settings for management roles
INSERT INTO CalendarSettings (employee_id, default_view, show_weekends, show_leave_requests, show_tasks, show_projects, show_operator_assignments, show_conflicts)
SELECT employee_id, 'month', TRUE, TRUE, TRUE, TRUE, TRUE, TRUE
FROM Employees 
WHERE role IN ('chef', 'byggeleder')
ON DUPLICATE KEY UPDATE updated_at = CURRENT_TIMESTAMP;

-- 9. Insert basic crane operator skills for existing workers (Danish crane types)
INSERT INTO WorkerSkills (employee_id, skill_name, skill_level, is_certified, years_experience, crane_type_specialization)
SELECT 
  employee_id,
  'Mobile Crane Operation',
  'advanced',
  TRUE,
  5,
  'Mobile Crane'
FROM Employees 
WHERE role = 'arbejder' AND is_activated = TRUE
LIMIT 5
ON DUPLICATE KEY UPDATE updated_at = CURRENT_TIMESTAMP;

INSERT INTO WorkerSkills (employee_id, skill_name, skill_level, is_certified, years_experience, crane_type_specialization)
SELECT 
  employee_id,
  'Tower Crane Operation',
  'intermediate',
  TRUE,
  3,
  'Tower Crane'
FROM Employees 
WHERE role = 'arbejder' AND is_activated = TRUE
LIMIT 3
ON DUPLICATE KEY UPDATE updated_at = CURRENT_TIMESTAMP;

INSERT INTO WorkerSkills (employee_id, skill_name, skill_level, is_certified, years_experience, crane_type_specialization)
SELECT 
  employee_id,
  'Telehandler Operation',
  'advanced',
  TRUE,
  4,
  'Telehandler'
FROM Employees 
WHERE role = 'arbejder' AND is_activated = TRUE
LIMIT 4
ON DUPLICATE KEY UPDATE updated_at = CURRENT_TIMESTAMP;

-- 10. Create view for unified calendar data focused on operator scheduling
CREATE OR REPLACE VIEW unified_calendar_view AS
SELECT 
  CONCAT('leave-', l.id) as event_id,
  'LEAVE' as event_type,
  'WORKFORCE' as category,
  CONCAT(e.name, ' - ', l.type, ' Leave') as title,
  COALESCE(l.reason, CONCAT(l.type, ' leave')) as description,
  CASE WHEN l.emergency_leave = TRUE THEN 'HIGH' ELSE 'MEDIUM' END as priority,
  'ACTIVE' as status,
  l.start_date as start_date,
  l.end_date as end_date,
  NULL as start_time,
  NULL as end_time,
  l.employee_id,
  NULL as project_id,
  NULL as task_id,
  l.id as source_id,
  'leave' as source_type,
  l.created_at,
  l.updated_at
FROM LeaveRequests l
JOIN Employees e ON l.employee_id = e.employee_id
WHERE l.status = 'APPROVED'

UNION ALL

SELECT 
  CONCAT('project-', p.project_id) as event_id,
  'PROJECT' as event_type,
  'PROJECT' as category,
  p.title as title,
  CONCAT(COALESCE(c.name, 'Unknown Customer'), ' - ', COALESCE(p.description, '')) as description,
  'MEDIUM' as priority,
  CASE 
    WHEN p.status = 'aktiv' THEN 'ACTIVE'
    WHEN p.status = 'afsluttet' THEN 'COMPLETED'
    ELSE 'PLANNED'
  END as status,
  p.start_date,
  p.end_date,
  NULL as start_time,
  NULL as end_time,
  NULL as employee_id,
  p.project_id,
  NULL as task_id,
  p.project_id as source_id,
  'project' as source_type,
  p.created_at,
  p.created_at as updated_at
FROM Projects p
LEFT JOIN Customers c ON p.customer_id = c.customer_id
WHERE p.isActive = TRUE

UNION ALL

SELECT 
  CONCAT('task-', t.task_id) as event_id,
  'OPERATOR_ASSIGNMENT' as event_type,
  'PROJECT' as category,
  t.title as title,
  CONCAT(p.title, ' - ', COALESCE(t.description, ''), 
         CASE WHEN t.client_equipment_info IS NOT NULL 
              THEN CONCAT(' (Client Equipment: ', t.client_equipment_info, ')') 
              ELSE '' END) as description,
  COALESCE(t.priority, 'medium') as priority,
  COALESCE(t.status, 'planned') as status,
  COALESCE(t.start_date, t.deadline) as start_date,
  t.deadline as end_date,
  NULL as start_time,
  NULL as end_time,
  NULL as employee_id,
  t.project_id,
  t.task_id,
  t.task_id as source_id,
  'operator_assignment' as source_type,
  t.created_at,
  t.created_at as updated_at
FROM Tasks t
JOIN Projects p ON t.project_id = p.project_id
WHERE t.isActive = TRUE

UNION ALL

SELECT 
  CONCAT('event-', ce.event_id) as event_id,
  ce.event_type as event_type,
  ce.category,
  ce.title,
  COALESCE(ce.description, '') as description,
  ce.priority,
  ce.status,
  ce.start_date,
  ce.end_date,
  ce.start_time,
  ce.end_time,
  ce.employee_id,
  ce.project_id,
  ce.task_id,
  ce.event_id as source_id,
  'calendar_event' as source_type,
  ce.created_at,
  ce.updated_at
FROM CalendarEvents ce;

COMMIT;

-- Migration completed successfully
SELECT 'Management Calendar schema migration for crane operator staffing completed successfully!' as Status;