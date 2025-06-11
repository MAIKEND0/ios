-- KSR Cranes App - CLEANUP ONLY
-- Run this FIRST to remove all existing leave system objects

-- =====================================================
-- CLEANUP - Remove all existing objects
-- =====================================================

-- Drop all triggers first
DROP TRIGGER IF EXISTS tr_leave_request_calculate_days;
DROP TRIGGER IF EXISTS tr_leave_request_validate_update;
DROP TRIGGER IF EXISTS tr_leave_request_approved;

-- Drop all procedures and functions
DROP PROCEDURE IF EXISTS UpdateLeaveBalance;
DROP FUNCTION IF EXISTS CalculateWorkDays;

-- Drop all views
DROP VIEW IF EXISTS CurrentLeaveRequests;
DROP VIEW IF EXISTS EmployeeLeaveBalances;

-- Drop all tables (in reverse dependency order)
DROP TABLE IF EXISTS LeaveAuditLog;
DROP TABLE IF EXISTS LeaveBalance;
DROP TABLE IF EXISTS LeaveRequests;
DROP TABLE IF EXISTS PublicHolidays;

SELECT 'Cleanup completed successfully!' as status;