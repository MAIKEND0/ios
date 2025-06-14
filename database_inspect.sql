-- MySQL Database Inspection Script (Compatible with MySQL 5.7+)
-- Run this to see all triggers, procedures, and constraints that might affect LeaveRequests table

-- 1. Show all triggers in the database
SELECT 
    TRIGGER_NAME,
    EVENT_MANIPULATION,
    EVENT_OBJECT_TABLE,
    ACTION_TIMING,
    ACTION_STATEMENT,
    CREATED,
    DEFINER
FROM INFORMATION_SCHEMA.TRIGGERS 
WHERE TRIGGER_SCHEMA = DATABASE()
ORDER BY EVENT_OBJECT_TABLE, ACTION_TIMING, EVENT_MANIPULATION;

-- 2. Show triggers specifically on LeaveRequests table
SELECT 
    TRIGGER_NAME,
    EVENT_MANIPULATION,
    ACTION_TIMING,
    ACTION_STATEMENT
FROM INFORMATION_SCHEMA.TRIGGERS 
WHERE TRIGGER_SCHEMA = DATABASE() 
  AND EVENT_OBJECT_TABLE = 'LeaveRequests';

-- 3. Show all stored procedures and functions
SELECT 
    ROUTINE_NAME,
    ROUTINE_TYPE,
    ROUTINE_DEFINITION,
    CREATED,
    LAST_ALTERED
FROM INFORMATION_SCHEMA.ROUTINES 
WHERE ROUTINE_SCHEMA = DATABASE();

-- 4. Show foreign key constraints on LeaveRequests (MySQL 5.7 compatible)
SELECT 
    CONSTRAINT_NAME,
    TABLE_NAME,
    COLUMN_NAME,
    REFERENCED_TABLE_NAME,
    REFERENCED_COLUMN_NAME
FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE 
WHERE TABLE_SCHEMA = DATABASE() 
  AND (TABLE_NAME = 'LeaveRequests' OR REFERENCED_TABLE_NAME = 'LeaveRequests')
  AND REFERENCED_TABLE_NAME IS NOT NULL;

-- 4b. Get foreign key rules from REFERENTIAL_CONSTRAINTS (if available)
SELECT 
    rc.CONSTRAINT_NAME,
    rc.TABLE_NAME,
    rc.REFERENCED_TABLE_NAME,
    rc.UPDATE_RULE,
    rc.DELETE_RULE
FROM INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS rc
WHERE rc.CONSTRAINT_SCHEMA = DATABASE() 
  AND (rc.TABLE_NAME = 'LeaveRequests' OR rc.REFERENCED_TABLE_NAME = 'LeaveRequests');

-- 5. Show all constraints on LeaveRequests table
SELECT 
    CONSTRAINT_NAME,
    CONSTRAINT_TYPE,
    TABLE_NAME,
    COLUMN_NAME
FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS tc
LEFT JOIN INFORMATION_SCHEMA.KEY_COLUMN_USAGE kcu 
  ON tc.CONSTRAINT_NAME = kcu.CONSTRAINT_NAME
WHERE tc.TABLE_SCHEMA = DATABASE() 
  AND tc.TABLE_NAME = 'LeaveRequests';

-- 6. Show table structure for LeaveRequests
DESCRIBE LeaveRequests;

-- 7. Show indexes on LeaveRequests
SHOW INDEX FROM LeaveRequests;

-- 8. Show any events (scheduled tasks)
SELECT 
    EVENT_NAME,
    EVENT_DEFINITION,
    STATUS,
    CREATED,
    LAST_ALTERED
FROM INFORMATION_SCHEMA.EVENTS 
WHERE EVENT_SCHEMA = DATABASE();

-- 9. Check for any views that might depend on LeaveRequests
SELECT 
    TABLE_NAME,
    VIEW_DEFINITION
FROM INFORMATION_SCHEMA.VIEWS 
WHERE TABLE_SCHEMA = DATABASE() 
  AND VIEW_DEFINITION LIKE '%LeaveRequests%';

-- 10. Check current database name and version
SELECT DATABASE() as current_database, VERSION() as mysql_version;

-- 11. Show any CHECK constraints (MySQL 8.0+ only, will error in 5.7)
-- SELECT 
--     CONSTRAINT_NAME,
--     TABLE_NAME,
--     CHECK_CLAUSE
-- FROM INFORMATION_SCHEMA.CHECK_CONSTRAINTS 
-- WHERE CONSTRAINT_SCHEMA = DATABASE() 
--   AND TABLE_NAME = 'LeaveRequests';

-- 12. Show table creation statement (if you have SHOW CREATE TABLE permissions)
-- SHOW CREATE TABLE LeaveRequests;

-- 13. Quick check for any obvious triggers that might cause issues
SELECT 
    TRIGGER_NAME,
    EVENT_OBJECT_TABLE,
    ACTION_TIMING,
    EVENT_MANIPULATION,
    CASE 
        WHEN ACTION_STATEMENT LIKE '%COMMIT%' THEN 'CONTAINS_COMMIT'
        WHEN ACTION_STATEMENT LIKE '%ROLLBACK%' THEN 'CONTAINS_ROLLBACK'
        WHEN ACTION_STATEMENT LIKE '%START TRANSACTION%' THEN 'CONTAINS_TRANSACTION'
        ELSE 'NO_TRANSACTION_KEYWORDS'
    END as TRANSACTION_ANALYSIS
FROM INFORMATION_SCHEMA.TRIGGERS 
WHERE TRIGGER_SCHEMA = DATABASE();

-- 14. Show processlist to see if there are any blocking queries
SHOW PROCESSLIST;