-- KSR Cranes App - SIMPLE Leave Management Tables Only
-- Basic tables without stored procedures or complex triggers

-- =====================================================
-- 1. PUBLIC HOLIDAYS TABLE
-- =====================================================

CREATE TABLE IF NOT EXISTS PublicHolidays (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    date DATE NOT NULL UNIQUE,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    year INT NOT NULL,
    is_national BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    INDEX idx_holiday_date (date),
    INDEX idx_holiday_year (year)
) ENGINE=InnoDB;

-- =====================================================
-- 2. LEAVE REQUESTS TABLE
-- =====================================================

CREATE TABLE IF NOT EXISTS LeaveRequests (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    employee_id INT UNSIGNED NOT NULL,
    type ENUM('VACATION', 'SICK', 'PERSONAL', 'PARENTAL', 'COMPENSATORY', 'EMERGENCY') NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    total_days INT NOT NULL DEFAULT 1,
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
    
    -- Foreign Keys
    FOREIGN KEY (employee_id) REFERENCES Employees(employee_id) ON DELETE CASCADE,
    FOREIGN KEY (approved_by) REFERENCES Employees(employee_id) ON DELETE SET NULL,
    
    -- Indexes
    INDEX idx_leave_employee_id (employee_id),
    INDEX idx_leave_status (status),
    INDEX idx_leave_dates (start_date, end_date),
    INDEX idx_leave_type (type)
) ENGINE=InnoDB;

-- =====================================================
-- 3. LEAVE BALANCE TABLE
-- =====================================================

CREATE TABLE IF NOT EXISTS LeaveBalance (
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
    
    -- Foreign Key
    FOREIGN KEY (employee_id) REFERENCES Employees(employee_id) ON DELETE CASCADE,
    
    -- Unique constraint
    UNIQUE KEY unique_employee_year (employee_id, year),
    
    -- Indexes
    INDEX idx_balance_employee (employee_id),
    INDEX idx_balance_year (year)
) ENGINE=InnoDB;

-- =====================================================
-- 4. INSERT DANISH HOLIDAYS 2025
-- =====================================================

INSERT IGNORE INTO PublicHolidays (date, name, description, year, is_national) VALUES
('2025-01-01', 'Nytårsdag', 'New Year Day', 2025, TRUE),
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
('2025-12-31', 'Nytårsaftensdag', 'New Year Eve', 2025, TRUE);

-- =====================================================
-- 5. INITIALIZE LEAVE BALANCES FOR EXISTING EMPLOYEES
-- =====================================================

INSERT IGNORE INTO LeaveBalance (employee_id, year, vacation_days_total, vacation_days_used, personal_days_total, personal_days_used)
SELECT 
    employee_id,
    2025 as year,
    25 as vacation_days_total,
    0 as vacation_days_used,
    5 as personal_days_total,
    0 as personal_days_used
FROM Employees 
WHERE role IN ('arbejder', 'byggeleder', 'chef');

-- =====================================================
-- 6. SIMPLE VIEWS FOR BASIC FUNCTIONALITY
-- =====================================================

CREATE OR REPLACE VIEW CurrentLeaveRequests AS
SELECT 
    lr.id,
    lr.employee_id,
    e.name as employee_name,
    lr.type,
    lr.start_date,
    lr.end_date,
    lr.total_days,
    lr.status,
    lr.created_at,
    approver.name as approver_name
FROM LeaveRequests lr
JOIN Employees e ON lr.employee_id = e.employee_id
LEFT JOIN Employees approver ON lr.approved_by = approver.employee_id
ORDER BY lr.created_at DESC;

CREATE OR REPLACE VIEW EmployeeLeaveBalances AS
SELECT 
    lb.employee_id,
    e.name as employee_name,
    lb.year,
    lb.vacation_days_total,
    lb.vacation_days_used,
    (lb.vacation_days_total - lb.vacation_days_used) as vacation_days_remaining,
    lb.personal_days_total,
    lb.personal_days_used,
    (lb.personal_days_total - lb.personal_days_used) as personal_days_remaining
FROM LeaveBalance lb
JOIN Employees e ON lb.employee_id = e.employee_id
WHERE lb.year = 2025
ORDER BY e.name;

-- =====================================================
-- VERIFICATION
-- =====================================================

SELECT 'Basic Leave Management System Created Successfully!' as status;
SELECT COUNT(*) as holidays_count FROM PublicHolidays WHERE year = 2025;
SELECT COUNT(*) as leave_balances_count FROM LeaveBalance WHERE year = 2025;