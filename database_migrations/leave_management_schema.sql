-- KSR Cranes App - Leave Management System
-- Database Schema Migration Script
-- Compatible with existing MySQL database structure

-- =====================================================
-- 1. CREATE ENUMS (MySQL uses CHECK constraints)
-- =====================================================

-- Leave Type Enum Values: VACATION, SICK, PERSONAL, PARENTAL, COMPENSATORY, EMERGENCY
-- Leave Status Enum Values: PENDING, APPROVED, REJECTED, CANCELLED, EXPIRED

-- =====================================================
-- 2. LEAVE REQUESTS TABLE
-- =====================================================

CREATE TABLE IF NOT EXISTS LeaveRequests (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    employee_id INT UNSIGNED NOT NULL,
    type ENUM('VACATION', 'SICK', 'PERSONAL', 'PARENTAL', 'COMPENSATORY', 'EMERGENCY') NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    total_days INT NOT NULL,
    half_day BOOLEAN DEFAULT FALSE COMMENT 'true if morning/afternoon only',
    status ENUM('PENDING', 'APPROVED', 'REJECTED', 'CANCELLED', 'EXPIRED') DEFAULT 'PENDING',
    reason TEXT,
    sick_note_url VARCHAR(1024) COMMENT 'S3 URL for sick leave documentation',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    approved_by INT UNSIGNED,
    approved_at DATETIME,
    rejection_reason TEXT,
    emergency_leave BOOLEAN DEFAULT FALSE COMMENT 'for urgent sick leave',
    
    -- Foreign Key Constraints
    CONSTRAINT fk_leave_employee 
        FOREIGN KEY (employee_id) REFERENCES Employees(employee_id) 
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_leave_approver 
        FOREIGN KEY (approved_by) REFERENCES Employees(employee_id) 
        ON DELETE SET NULL ON UPDATE CASCADE,
    
    -- Indexes for performance
    INDEX idx_leave_employee_id (employee_id),
    INDEX idx_leave_status (status),
    INDEX idx_leave_dates (start_date, end_date),
    INDEX idx_leave_type (type),
    INDEX idx_leave_created (created_at),
    INDEX idx_leave_approver (approved_by),
    
    -- Business Logic Constraints
    CONSTRAINT chk_leave_dates CHECK (end_date >= start_date),
    CONSTRAINT chk_total_days CHECK (total_days > 0)
    -- Note: Approval logic validation will be handled by triggers instead of check constraint
    -- due to MySQL limitation with foreign key columns in check constraints
) ENGINE=InnoDB COMMENT='Employee leave requests (vacation, sick, personal days)';

-- =====================================================
-- 3. LEAVE BALANCE TABLE
-- =====================================================

CREATE TABLE IF NOT EXISTS LeaveBalance (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    employee_id INT UNSIGNED NOT NULL,
    year INT NOT NULL,
    vacation_days_total INT DEFAULT 25 COMMENT 'total annual vacation days (Danish standard)',
    vacation_days_used INT DEFAULT 0 COMMENT 'used vacation days',
    sick_days_used INT DEFAULT 0 COMMENT 'used sick days (tracking only)',
    personal_days_total INT DEFAULT 5 COMMENT 'personal days allowance',
    personal_days_used INT DEFAULT 0 COMMENT 'used personal days',
    carry_over_days INT DEFAULT 0 COMMENT 'carried over from previous year',
    carry_over_expires DATE COMMENT 'expiration date for carried over days',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    -- Foreign Key Constraints
    CONSTRAINT fk_balance_employee 
        FOREIGN KEY (employee_id) REFERENCES Employees(employee_id) 
        ON DELETE CASCADE ON UPDATE CASCADE,
    
    -- Unique constraint to prevent duplicate records
    UNIQUE KEY unique_employee_year (employee_id, year),
    
    -- Indexes
    INDEX idx_balance_employee (employee_id),
    INDEX idx_balance_year (year),
    
    -- Business Logic Constraints
    CONSTRAINT chk_vacation_used CHECK (vacation_days_used >= 0),
    CONSTRAINT chk_vacation_total CHECK (vacation_days_total >= 0),
    CONSTRAINT chk_sick_used CHECK (sick_days_used >= 0),
    CONSTRAINT chk_personal_used CHECK (personal_days_used >= 0),
    CONSTRAINT chk_personal_total CHECK (personal_days_total >= 0),
    CONSTRAINT chk_carry_over CHECK (carry_over_days >= 0),
    CONSTRAINT chk_balance_year CHECK (year >= 2020 AND year <= 2050)
) ENGINE=InnoDB COMMENT='Employee annual leave balances and allowances';

-- =====================================================
-- 4. PUBLIC HOLIDAYS TABLE
-- =====================================================

CREATE TABLE IF NOT EXISTS PublicHolidays (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    date DATE NOT NULL,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    year INT NOT NULL,
    is_national BOOLEAN DEFAULT TRUE COMMENT 'true for national holidays, false for company-specific',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    -- Unique constraint to prevent duplicate holidays
    UNIQUE KEY unique_holiday_date (date),
    
    -- Indexes
    INDEX idx_holiday_date (date),
    INDEX idx_holiday_year (year),
    INDEX idx_holiday_national (is_national),
    
    -- Business Logic Constraints
    CONSTRAINT chk_holiday_year CHECK (year >= 2020 AND year <= 2050)
) ENGINE=InnoDB COMMENT='Public holidays and company-specific non-working days';

-- =====================================================
-- 5. LEAVE AUDIT LOG TABLE (Optional - for compliance)
-- =====================================================

CREATE TABLE IF NOT EXISTS LeaveAuditLog (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    leave_request_id INT UNSIGNED,
    employee_id INT UNSIGNED NOT NULL,
    action ENUM('CREATED', 'APPROVED', 'REJECTED', 'CANCELLED', 'MODIFIED', 'DELETED') NOT NULL,
    old_values JSON COMMENT 'previous values in JSON format',
    new_values JSON COMMENT 'new values in JSON format',
    performed_by INT UNSIGNED NOT NULL,
    performed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ip_address VARCHAR(45),
    user_agent VARCHAR(500),
    notes TEXT,
    
    -- Foreign Key Constraints
    CONSTRAINT fk_audit_leave_request 
        FOREIGN KEY (leave_request_id) REFERENCES LeaveRequests(id) 
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_audit_employee 
        FOREIGN KEY (employee_id) REFERENCES Employees(employee_id) 
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_audit_performer 
        FOREIGN KEY (performed_by) REFERENCES Employees(employee_id) 
        ON DELETE CASCADE ON UPDATE CASCADE,
    
    -- Indexes
    INDEX idx_audit_leave_request (leave_request_id),
    INDEX idx_audit_employee (employee_id),
    INDEX idx_audit_performed_by (performed_by),
    INDEX idx_audit_action (action),
    INDEX idx_audit_date (performed_at)
) ENGINE=InnoDB COMMENT='Audit trail for all leave-related actions';

-- =====================================================
-- 6. INITIAL DATA - DANISH PUBLIC HOLIDAYS 2025
-- =====================================================

INSERT IGNORE INTO PublicHolidays (date, name, description, year, is_national) VALUES
-- 2025 Danish Public Holidays
('2025-01-01', 'Nytårsdag', 'New Year\'s Day', 2025, TRUE),
('2025-04-17', 'Skærtorsdag', 'Maundy Thursday', 2025, TRUE),
('2025-04-18', 'Langfredag', 'Good Friday', 2025, TRUE),
('2025-04-20', 'Påskedag', 'Easter Sunday', 2025, TRUE),
('2025-04-21', 'Anden påskedag', 'Easter Monday', 2025, TRUE),
('2025-05-16', 'Store bededag', 'Great Prayer Day', 2025, TRUE),
('2025-05-29', 'Kristi himmelfartsdag', 'Ascension Day', 2025, TRUE),
('2025-06-08', 'Pinsedag', 'Whit Sunday', 2025, TRUE),
('2025-06-09', 'Anden pinsedag', 'Whit Monday', 2025, TRUE),
('2025-12-24', 'Juleaftensdag', 'Christmas Eve (half day)', 2025, TRUE),
('2025-12-25', 'Juledag', 'Christmas Day', 2025, TRUE),
('2025-12-26', 'Anden juledag', 'Boxing Day', 2025, TRUE),
('2025-12-31', 'Nytårsaftensdag', 'New Year\'s Eve (half day)', 2025, TRUE);

-- =====================================================
-- 7. INITIALIZE LEAVE BALANCES FOR EXISTING EMPLOYEES
-- =====================================================

-- Create leave balances for all existing employees for current year
INSERT IGNORE INTO LeaveBalance (employee_id, year, vacation_days_total, vacation_days_used, personal_days_total, personal_days_used)
SELECT 
    employee_id,
    YEAR(CURDATE()) as year,
    25 as vacation_days_total,
    0 as vacation_days_used,
    5 as personal_days_total,
    0 as personal_days_used
FROM Employees 
WHERE role IN ('arbejder', 'byggeleder', 'chef')
AND NOT EXISTS (
    SELECT 1 FROM LeaveBalance 
    WHERE LeaveBalance.employee_id = Employees.employee_id 
    AND LeaveBalance.year = YEAR(CURDATE())
);

-- =====================================================
-- 8. USEFUL VIEWS FOR REPORTING
-- =====================================================

-- View for current leave requests with employee details
DROP VIEW IF EXISTS CurrentLeaveRequests;
CREATE VIEW CurrentLeaveRequests AS
SELECT 
    lr.id,
    lr.employee_id,
    e.name as employee_name,
    e.email as employee_email,
    lr.type,
    lr.start_date,
    lr.end_date,
    lr.total_days,
    lr.status,
    lr.reason,
    lr.created_at,
    lr.approved_by,
    approver.name as approver_name,
    lr.approved_at
FROM LeaveRequests lr
JOIN Employees e ON lr.employee_id = e.employee_id
LEFT JOIN Employees approver ON lr.approved_by = approver.employee_id
WHERE lr.status IN ('PENDING', 'APPROVED')
ORDER BY lr.created_at DESC;

-- View for employee leave balances with remaining days
DROP VIEW IF EXISTS EmployeeLeaveBalances;
CREATE VIEW EmployeeLeaveBalances AS
SELECT 
    lb.employee_id,
    e.name as employee_name,
    e.email as employee_email,
    lb.year,
    lb.vacation_days_total,
    lb.vacation_days_used,
    (lb.vacation_days_total + lb.carry_over_days - lb.vacation_days_used) as vacation_days_remaining,
    lb.personal_days_total,
    lb.personal_days_used,
    (lb.personal_days_total - lb.personal_days_used) as personal_days_remaining,
    lb.carry_over_days,
    lb.carry_over_expires
FROM LeaveBalance lb
JOIN Employees e ON lb.employee_id = e.employee_id
WHERE lb.year = YEAR(CURDATE())
ORDER BY e.name;

-- =====================================================
-- 9. STORED PROCEDURES FOR COMMON OPERATIONS
-- =====================================================

-- Function to calculate work days between two dates (excluding weekends and holidays)
DROP FUNCTION IF EXISTS CalculateWorkDays;

DELIMITER //

CREATE FUNCTION CalculateWorkDays(p_start_date DATE, p_end_date DATE)
RETURNS INT
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE v_work_days INT DEFAULT 0;
    DECLARE v_current_date DATE DEFAULT p_start_date;
    DECLARE v_day_of_week INT;
    DECLARE v_holiday_count INT;
    
    WHILE v_current_date <= p_end_date DO
        SET v_day_of_week = DAYOFWEEK(v_current_date);
        
        -- Check if it's not weekend (Sunday = 1, Saturday = 7)
        IF v_day_of_week NOT IN (1, 7) THEN
            -- Check if it's not a public holiday
            SELECT COUNT(*) INTO v_holiday_count 
            FROM PublicHolidays 
            WHERE date = v_current_date AND is_national = TRUE;
            
            IF v_holiday_count = 0 THEN
                SET v_work_days = v_work_days + 1;
            END IF;
        END IF;
        
        SET v_current_date = DATE_ADD(v_current_date, INTERVAL 1 DAY);
    END WHILE;
    
    RETURN v_work_days;
END //

-- Procedure to update leave balance after approval
DROP PROCEDURE IF EXISTS UpdateLeaveBalance;

DELIMITER //

CREATE PROCEDURE UpdateLeaveBalance(
    IN p_employee_id INT UNSIGNED,
    IN p_leave_type VARCHAR(20),
    IN p_days INT,
    IN p_year INT
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
    
    START TRANSACTION;
    
    -- Ensure leave balance record exists
    INSERT IGNORE INTO LeaveBalance (employee_id, year) 
    VALUES (p_employee_id, p_year);
    
    -- Update appropriate balance based on leave type
    IF p_leave_type = 'VACATION' THEN
        UPDATE LeaveBalance 
        SET vacation_days_used = vacation_days_used + p_days,
            updated_at = CURRENT_TIMESTAMP
        WHERE employee_id = p_employee_id AND year = p_year;
            
    ELSEIF p_leave_type = 'PERSONAL' THEN
        UPDATE LeaveBalance 
        SET personal_days_used = personal_days_used + p_days,
            updated_at = CURRENT_TIMESTAMP
        WHERE employee_id = p_employee_id AND year = p_year;
            
    ELSEIF p_leave_type = 'SICK' THEN
        UPDATE LeaveBalance 
        SET sick_days_used = sick_days_used + p_days,
            updated_at = CURRENT_TIMESTAMP
        WHERE employee_id = p_employee_id AND year = p_year;
    END IF;
    
    COMMIT;
END //

DELIMITER ;

-- =====================================================
-- 10. TRIGGERS FOR AUTOMATIC UPDATES
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

DELIMITER //

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

-- Trigger to update leave balance when leave request is approved
DROP TRIGGER IF EXISTS tr_leave_request_approved;

DELIMITER //

CREATE TRIGGER tr_leave_request_approved
AFTER UPDATE ON LeaveRequests
FOR EACH ROW
BEGIN
    -- Only process if status changed to APPROVED
    IF OLD.status != 'APPROVED' AND NEW.status = 'APPROVED' THEN
        CALL UpdateLeaveBalance(
            NEW.employee_id, 
            NEW.type, 
            NEW.total_days, 
            YEAR(NEW.start_date)
        );
    END IF;
    
    -- If status changed from APPROVED to something else, reverse the balance
    IF OLD.status = 'APPROVED' AND NEW.status != 'APPROVED' THEN
        CALL UpdateLeaveBalance(
            NEW.employee_id, 
            NEW.type, 
            -NEW.total_days, 
            YEAR(NEW.start_date)
        );
    END IF;
END //

DELIMITER ;

-- =====================================================
-- 11. SAMPLE DATA FOR TESTING (Optional)
-- =====================================================

-- Uncomment below to insert sample leave requests for testing

/*
-- Sample leave requests (replace employee_ids with actual values from your database)
INSERT INTO LeaveRequests (employee_id, type, start_date, end_date, status, reason) VALUES
(1, 'VACATION', '2025-07-01', '2025-07-05', 'PENDING', 'Summer vacation'),
(2, 'SICK', '2025-06-10', '2025-06-12', 'APPROVED', 'Flu symptoms'),
(1, 'PERSONAL', '2025-06-20', '2025-06-20', 'APPROVED', 'Family appointment');
*/

-- =====================================================
-- MIGRATION COMPLETE
-- =====================================================

-- Verify the migration
SELECT 'Leave Management Schema Migration Complete' as status;
SELECT COUNT(*) as leave_requests_table FROM information_schema.tables WHERE table_name = 'LeaveRequests';
SELECT COUNT(*) as leave_balance_table FROM information_schema.tables WHERE table_name = 'LeaveBalance';
SELECT COUNT(*) as public_holidays_table FROM information_schema.tables WHERE table_name = 'PublicHolidays';
SELECT COUNT(*) as danish_holidays_2025 FROM PublicHolidays WHERE year = 2025;