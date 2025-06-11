-- Check current database and table collations to diagnose collation conflicts
-- Run this to understand the current collation setup

-- 1. Check database default collation
SELECT 
  SCHEMA_NAME as 'Database',
  DEFAULT_CHARACTER_SET_NAME as 'Charset',
  DEFAULT_COLLATION_NAME as 'Collation'
FROM information_schema.SCHEMATA 
WHERE SCHEMA_NAME = DATABASE();

-- 2. Check all table collations
SELECT 
  TABLE_NAME,
  TABLE_COLLATION
FROM information_schema.TABLES 
WHERE TABLE_SCHEMA = DATABASE()
  AND TABLE_TYPE = 'BASE TABLE'
ORDER BY TABLE_NAME;

-- 3. Check column collations for tables used in the UNION
SELECT 
  TABLE_NAME,
  COLUMN_NAME,
  CHARACTER_SET_NAME,
  COLLATION_NAME,
  DATA_TYPE
FROM information_schema.COLUMNS 
WHERE TABLE_SCHEMA = DATABASE()
  AND TABLE_NAME IN ('LeaveRequests', 'Projects', 'Tasks', 'CalendarEvents', 'Employees', 'Customers')
  AND DATA_TYPE IN ('varchar', 'text', 'char', 'enum')
ORDER BY TABLE_NAME, COLUMN_NAME;

-- 4. Check if unified_calendar_view exists
SELECT 
  TABLE_NAME,
  TABLE_TYPE
FROM information_schema.TABLES 
WHERE TABLE_SCHEMA = DATABASE()
  AND TABLE_NAME = 'unified_calendar_view';

-- 5. Check for any existing collation conflicts
SELECT 
  'Potential collation conflicts found. Check the output above for inconsistent collations.' as Warning
WHERE EXISTS (
  SELECT 1 
  FROM information_schema.COLUMNS 
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME IN ('LeaveRequests', 'Projects', 'Tasks', 'CalendarEvents', 'Employees', 'Customers')
    AND DATA_TYPE IN ('varchar', 'text', 'char', 'enum')
  GROUP BY COLUMN_NAME
  HAVING COUNT(DISTINCT COLLATION_NAME) > 1
);