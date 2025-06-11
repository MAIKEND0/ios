-- Fix Leave Management Triggers - Remove Transaction Control
-- This fixes MySQL 1422 error by removing COMMIT/ROLLBACK from triggers

-- =====================================================
-- 1. DROP PROBLEMATIC TRIGGERS AND PROCEDURES
-- =====================================================

DROP TRIGGER IF EXISTS tr_leave_request_approved;
DROP PROCEDURE IF EXISTS UpdateLeaveBalance;

-- =====================================================
-- 2. CREATE FIXED TRIGGERS WITHOUT TRANSACTION CONTROL
-- =====================================================

-- Trigger to automatically calculate total_days when inserting leave requests
DROP TRIGGER IF EXISTS tr_leave_request_calculate_days;

DELIMITER //

CREATE TRIGGER tr_leave_request_calculate_days
BEFORE INSERT ON LeaveRequests
FOR EACH ROW
BEGIN
    SET NEW.total_days = CalculateWorkDays(NEW.start_date, NEW.end_date);
    
    -- If half day, reduce by 0.5
    IF NEW.half_day = TRUE THEN
        SET NEW.total_days = GREATEST(1, NEW.total_days / 2);
    END IF;
    
    -- Validate approval logic (since we can't use check constraint)
    IF NEW.status = 'APPROVED' AND (NEW.approved_by IS NULL OR NEW.approved_at IS NULL) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Approved leave requests must have approved_by and approved_at values';
    END IF;
END //

-- Trigger for validation on updates
DROP TRIGGER IF EXISTS tr_leave_request_validate_update;

CREATE TRIGGER tr_leave_request_validate_update
BEFORE UPDATE ON LeaveRequests
FOR EACH ROW
BEGIN
    -- Validate approval logic
    IF NEW.status = 'APPROVED' AND (NEW.approved_by IS NULL OR NEW.approved_at IS NULL) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Approved leave requests must have approved_by and approved_at values';
    END IF;
    
    -- Auto-set approved_at when status changes to APPROVED
    IF OLD.status != 'APPROVED' AND NEW.status = 'APPROVED' AND NEW.approved_at IS NULL THEN
        SET NEW.approved_at = NOW();
    END IF;
END //

-- Fixed trigger to update leave balance - NO TRANSACTION CONTROL
CREATE TRIGGER tr_leave_request_balance_update
AFTER UPDATE ON LeaveRequests
FOR EACH ROW
BEGIN
    -- Only process if status changed to APPROVED
    IF OLD.status != 'APPROVED' AND NEW.status = 'APPROVED' THEN
        -- Ensure leave balance record exists (without transaction)
        INSERT IGNORE INTO LeaveBalance (
            employee_id, 
            year, 
            vacation_days_total, 
            vacation_days_used, 
            sick_days_used,
            personal_days_total, 
            personal_days_used, 
            carry_over_days,
            created_at,
            updated_at
        ) VALUES (
            NEW.employee_id, 
            YEAR(NEW.start_date),
            25,  -- Default vacation days
            0,   -- Initial used days
            0,   -- Initial sick days
            5,   -- Default personal days
            0,   -- Initial personal used
            0,   -- Initial carry over
            NOW(),
            NOW()
        );
        
        -- Update appropriate balance based on leave type (direct UPDATE, no stored procedure)
        IF NEW.type = 'VACATION' THEN
            UPDATE LeaveBalance 
            SET vacation_days_used = vacation_days_used + NEW.total_days,
                updated_at = NOW()
            WHERE employee_id = NEW.employee_id AND year = YEAR(NEW.start_date);
                
        ELSEIF NEW.type = 'PERSONAL' THEN
            UPDATE LeaveBalance 
            SET personal_days_used = personal_days_used + NEW.total_days,
                updated_at = NOW()
            WHERE employee_id = NEW.employee_id AND year = YEAR(NEW.start_date);
                
        ELSEIF NEW.type = 'SICK' THEN
            UPDATE LeaveBalance 
            SET sick_days_used = sick_days_used + NEW.total_days,
                updated_at = NOW()
            WHERE employee_id = NEW.employee_id AND year = YEAR(NEW.start_date);
        END IF;
    END IF;
    
    -- If status changed from APPROVED to something else, reverse the balance
    IF OLD.status = 'APPROVED' AND NEW.status != 'APPROVED' THEN
        -- Reverse the balance update
        IF NEW.type = 'VACATION' THEN
            UPDATE LeaveBalance 
            SET vacation_days_used = GREATEST(0, vacation_days_used - NEW.total_days),
                updated_at = NOW()
            WHERE employee_id = NEW.employee_id AND year = YEAR(NEW.start_date);
                
        ELSEIF NEW.type = 'PERSONAL' THEN
            UPDATE LeaveBalance 
            SET personal_days_used = GREATEST(0, personal_days_used - NEW.total_days),
                updated_at = NOW()
            WHERE employee_id = NEW.employee_id AND year = YEAR(NEW.start_date);
                
        ELSEIF NEW.type = 'SICK' THEN
            UPDATE LeaveBalance 
            SET sick_days_used = GREATEST(0, sick_days_used - NEW.total_days),
                updated_at = NOW()
            WHERE employee_id = NEW.employee_id AND year = YEAR(NEW.start_date);
        END IF;
    END IF;
END //

DELIMITER ;

-- =====================================================
-- 3. VERIFICATION
-- =====================================================

-- Verify triggers are created
SELECT 
    TRIGGER_NAME,
    EVENT_MANIPULATION,
    EVENT_OBJECT_TABLE,
    ACTION_TIMING
FROM INFORMATION_SCHEMA.TRIGGERS 
WHERE TRIGGER_SCHEMA = DATABASE() 
  AND EVENT_OBJECT_TABLE = 'LeaveRequests'
ORDER BY ACTION_TIMING, EVENT_MANIPULATION;

-- Check that problematic stored procedure is removed
SELECT 
    ROUTINE_NAME,
    ROUTINE_TYPE
FROM INFORMATION_SCHEMA.ROUTINES 
WHERE ROUTINE_SCHEMA = DATABASE() 
  AND ROUTINE_NAME = 'UpdateLeaveBalance';

SELECT 'Leave triggers fixed - removed transaction control statements' as status;