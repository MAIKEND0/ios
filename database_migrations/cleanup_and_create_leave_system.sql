-- KSR Cranes App - Leave Management System
-- CLEANUP AND FRESH INSTALL Script
-- Run this to completely clean and recreate the leave system

-- =====================================================
-- 1. CLEANUP - Remove all existing objects
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

-- =====================================================
-- 2. CREATE TABLES
-- =====================================================

CREATE TABLE PublicHolidays (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    date DATE NOT NULL UNIQUE,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    year INT NOT NULL,
    is_national BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX idx_holiday_date (date),
    INDEX idx_holiday_year (year),
    CONSTRAINT chk_holiday_year CHECK (year >= 2020 AND year <= 2050)
) ENGINE=InnoDB;

CREATE TABLE LeaveRequests (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    employee_id INT UNSIGNED NOT NULL,
    type ENUM('VACATION', 'SICK', 'PERSONAL', 'PARENTAL', 'COMPENSATORY', 'EMERGENCY') NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    total_days INT NOT NULL,
    half_day BOOLEAN DEFAULT FALSE,
    status ENUM('PENDING', 'APPROVED', 'REJECTED', 'CANCELLED', 'EXPIRED') DEFAULT 'PENDING',
    reason TEXT,
    sick_note_url VARCHAR(1024),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    approved_by INT UNSIGNED,
    approved_at DATETIME,
    rejection_reason TEXT,
    emergency_leave BOOLEAN DEFAULT FALSE,
    
    CONSTRAINT fk_leave_employee 
        FOREIGN KEY (employee_id) REFERENCES Employees(employee_id) 
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_leave_approver 
        FOREIGN KEY (approved_by) REFERENCES Employees(employee_id) 
        ON DELETE SET NULL ON UPDATE CASCADE,
    
    INDEX idx_leave_employee_id (employee_id),
    INDEX idx_leave_status (status),
    INDEX idx_leave_dates (start_date, end_date),
    INDEX idx_leave_type (type),
    CONSTRAINT chk_leave_dates CHECK (end_date >= start_date),
    CONSTRAINT chk_total_days CHECK (total_days > 0)
) ENGINE=InnoDB;

CREATE TABLE LeaveBalance (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    employee_id INT UNSIGNED NOT NULL,
    year INT NOT NULL,
    vacation_days_total INT DEFAULT 25,
    vacation_days_used INT DEFAULT 0,
    sick_days_used INT DEFAULT 0,
    personal_days_total INT DEFAULT 5,
    personal_days_used INT DEFAULT 0,
    carry_over_days INT DEFAULT 0,
    carry_over_expires DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    CONSTRAINT fk_balance_employee 
        FOREIGN KEY (employee_id) REFERENCES Employees(employee_id) 
        ON DELETE CASCADE ON UPDATE CASCADE,
    
    UNIQUE KEY unique_employee_year (employee_id, year),
    INDEX idx_balance_employee (employee_id),
    INDEX idx_balance_year (year),
    
    CONSTRAINT chk_vacation_used CHECK (vacation_days_used >= 0),
    CONSTRAINT chk_vacation_total CHECK (vacation_days_total >= 0),
    CONSTRAINT chk_sick_used CHECK (sick_days_used >= 0),
    CONSTRAINT chk_personal_used CHECK (personal_days_used >= 0),
    CONSTRAINT chk_personal_total CHECK (personal_days_total >= 0),
    CONSTRAINT chk_carry_over CHECK (carry_over_days >= 0),
    CONSTRAINT chk_balance_year CHECK (year >= 2020 AND year <= 2050)
) ENGINE=InnoDB;

-- =====================================================
-- 3. CREATE SIMPLE FUNCTION (without complex logic for now)
-- =====================================================

DELIMITER //

CREATE FUNCTION CalculateWorkDays(p_start_date DATE, p_end_date DATE)
RETURNS INT
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE v_work_days INT DEFAULT 0;
    DECLARE v_current_date DATE DEFAULT p_start_date;
    DECLARE v_day_of_week INT;
    
    WHILE v_current_date <= p_end_date DO
        SET v_day_of_week = DAYOFWEEK(v_current_date);
        
        -- Count only weekdays (Monday=2 to Friday=6)
        IF v_day_of_week BETWEEN 2 AND 6 THEN
            SET v_work_days = v_work_days + 1;
        END IF;
        
        SET v_current_date = DATE_ADD(v_current_date, INTERVAL 1 DAY);
    END WHILE;
    
    RETURN v_work_days;
END //

DELIMITER ;

-- =====================================================
-- 4. CREATE SIMPLE PROCEDURE
-- =====================================================

DELIMITER //

CREATE PROCEDURE UpdateLeaveBalance(
    IN p_employee_id INT UNSIGNED,
    IN p_leave_type VARCHAR(20),
    IN p_days INT,
    IN p_year INT
)
BEGIN
    -- Simple version without complex error handling
    INSERT IGNORE INTO LeaveBalance (employee_id, year) 
    VALUES (p_employee_id, p_year);
    
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
END //

DELIMITER ;

-- =====================================================
-- 5. CREATE SIMPLE TRIGGERS
-- =====================================================

DELIMITER //

CREATE TRIGGER tr_leave_request_calculate_days
BEFORE INSERT ON LeaveRequests
FOR EACH ROW
BEGIN
    SET NEW.total_days = CalculateWorkDays(NEW.start_date, NEW.end_date);
    
    IF NEW.half_day = TRUE THEN
        SET NEW.total_days = GREATEST(1, FLOOR(NEW.total_days / 2));
    END IF;
END //

CREATE TRIGGER tr_leave_request_approved
AFTER UPDATE ON LeaveRequests
FOR EACH ROW
BEGIN
    IF OLD.status != 'APPROVED' AND NEW.status = 'APPROVED' THEN
        CALL UpdateLeaveBalance(
            NEW.employee_id, 
            NEW.type, 
            NEW.total_days, 
            YEAR(NEW.start_date)
        );
    END IF;
    
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
-- 6. INSERT DANISH HOLIDAYS 2025
-- =====================================================

INSERT IGNORE INTO PublicHolidays (date, name, description, year, is_national) VALUES
('2025-01-01', 'Nytårsdag', 'New Year\'s Day', 2025, TRUE),
('2025-04-17', 'Skærtorsdag', 'Maundy Thursday', 2025, TRUE),
('2025-04-18', 'Langfredag', 'Good Friday', 2025, TRUE),
('2025-04-20', 'Påskedag', 'Easter Sunday', 2025, TRUE),
('2025-04-21', 'Anden påskedag', 'Easter Monday', 2025, TRUE),
('2025-05-16', 'Store bededag', 'Great Prayer Day', 2025, TRUE),
('2025-05-29', 'Kristi himmelfartsdag', 'Ascension Day', 2025, TRUE),
('2025-06-08', 'Pinsedag', 'Whit Sunday', 2025, TRUE),
('2025-06-09', 'Anden pinsedag', 'Whit Monday', 2025, TRUE),
('2025-12-24', 'Juleaftensdag', 'Christmas Eve', 2025, TRUE),
('2025-12-25', 'Juledag', 'Christmas Day', 2025, TRUE),
('2025-12-26', 'Anden juledag', 'Boxing Day', 2025, TRUE),
('2025-12-31', 'Nytårsaftensdag', 'New Year\'s Eve', 2025, TRUE);

-- =====================================================
-- 7. INITIALIZE LEAVE BALANCES FOR EXISTING EMPLOYEES
-- =====================================================

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
-- 8. CREATE VIEWS
-- =====================================================

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
-- INSTALLATION COMPLETE
-- =====================================================

SELECT 'Leave Management System Installation Complete!' as status;
SELECT COUNT(*) as leave_requests_table FROM information_schema.tables WHERE table_schema = DATABASE() AND table_name = 'LeaveRequests';
SELECT COUNT(*) as leave_balance_table FROM information_schema.tables WHERE table_schema = DATABASE() AND table_name = 'LeaveBalance';
SELECT COUNT(*) as public_holidays_table FROM information_schema.tables WHERE table_schema = DATABASE() AND table_name = 'PublicHolidays';
SELECT COUNT(*) as danish_holidays_2025 FROM PublicHolidays WHERE year = 2025;