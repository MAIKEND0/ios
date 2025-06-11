-- Fix Leave Balance - Recalculate used days based on approved leave requests
-- Run this to sync LeaveBalance with actual approved LeaveRequests

-- First, let's see current state
SELECT 'Current sick days discrepancies:' as info;
SELECT 
    e.name,
    lb.year,
    lb.sick_days_used as balance_sick_days,
    COALESCE((SELECT SUM(lr.total_days) FROM LeaveRequests lr WHERE lr.employee_id = lb.employee_id AND lr.type = 'SICK' AND lr.status = 'APPROVED' AND YEAR(lr.start_date) = lb.year), 0) as actual_sick_days
FROM LeaveBalance lb
JOIN Employees e ON e.employee_id = lb.employee_id
WHERE lb.sick_days_used != COALESCE((SELECT SUM(lr.total_days) FROM LeaveRequests lr WHERE lr.employee_id = lb.employee_id AND lr.type = 'SICK' AND lr.status = 'APPROVED' AND YEAR(lr.start_date) = lb.year), 0);

-- Update sick_days_used based on approved SICK leave requests
UPDATE LeaveBalance lb
SET sick_days_used = (
    SELECT COALESCE(SUM(lr.total_days), 0)
    FROM LeaveRequests lr
    WHERE lr.employee_id = lb.employee_id
    AND lr.type = 'SICK'
    AND lr.status = 'APPROVED'
    AND YEAR(lr.start_date) = lb.year
);

-- Update vacation_days_used based on approved VACATION leave requests
UPDATE LeaveBalance lb
SET vacation_days_used = (
    SELECT COALESCE(SUM(lr.total_days), 0)
    FROM LeaveRequests lr
    WHERE lr.employee_id = lb.employee_id
    AND lr.type = 'VACATION'
    AND lr.status = 'APPROVED'
    AND YEAR(lr.start_date) = lb.year
);

-- Update personal_days_used based on approved PERSONAL leave requests
UPDATE LeaveBalance lb
SET personal_days_used = (
    SELECT COALESCE(SUM(lr.total_days), 0)
    FROM LeaveRequests lr
    WHERE lr.employee_id = lb.employee_id
    AND lr.type = 'PERSONAL'
    AND lr.status = 'APPROVED'
    AND YEAR(lr.start_date) = lb.year
);

-- Create missing LeaveBalance records for employees who have approved leave requests but no balance record
INSERT INTO LeaveBalance (employee_id, year, vacation_days_total, vacation_days_used, sick_days_used, personal_days_total, personal_days_used, carry_over_days)
SELECT DISTINCT 
    lr.employee_id,
    YEAR(lr.start_date) as year,
    25 as vacation_days_total,
    COALESCE((SELECT SUM(lr2.total_days) FROM LeaveRequests lr2 WHERE lr2.employee_id = lr.employee_id AND lr2.type = 'VACATION' AND lr2.status = 'APPROVED' AND YEAR(lr2.start_date) = YEAR(lr.start_date)), 0) as vacation_days_used,
    COALESCE((SELECT SUM(lr2.total_days) FROM LeaveRequests lr2 WHERE lr2.employee_id = lr.employee_id AND lr2.type = 'SICK' AND lr2.status = 'APPROVED' AND YEAR(lr2.start_date) = YEAR(lr.start_date)), 0) as sick_days_used,
    5 as personal_days_total,
    COALESCE((SELECT SUM(lr2.total_days) FROM LeaveRequests lr2 WHERE lr2.employee_id = lr.employee_id AND lr2.type = 'PERSONAL' AND lr2.status = 'APPROVED' AND YEAR(lr2.start_date) = YEAR(lr.start_date)), 0) as personal_days_used,
    0 as carry_over_days
FROM LeaveRequests lr
WHERE lr.status = 'APPROVED'
AND NOT EXISTS (
    SELECT 1 FROM LeaveBalance lb 
    WHERE lb.employee_id = lr.employee_id 
    AND lb.year = YEAR(lr.start_date)
);

-- Verification query - show the results after fix
SELECT 'Fixed results:' as info;
SELECT 
    e.name,
    lb.year,
    lb.vacation_days_used,
    lb.sick_days_used,
    lb.personal_days_used,
    (SELECT COUNT(*) FROM LeaveRequests lr WHERE lr.employee_id = lb.employee_id AND lr.type = 'SICK' AND lr.status = 'APPROVED' AND YEAR(lr.start_date) = lb.year) as approved_sick_requests,
    (SELECT COUNT(*) FROM LeaveRequests lr WHERE lr.employee_id = lb.employee_id AND lr.type = 'VACATION' AND lr.status = 'APPROVED' AND YEAR(lr.start_date) = lb.year) as approved_vacation_requests
FROM LeaveBalance lb
JOIN Employees e ON e.employee_id = lb.employee_id
ORDER BY e.name, lb.year;