-- Check if crane type 2 exists
SELECT * FROM CraneTypes WHERE crane_type_id = 2;

-- Check which workers don't have crane types
SELECT e.employee_id, e.name, e.role
FROM Employees e
LEFT JOIN EmployeeCraneTypes ect ON e.employee_id = ect.employee_id
WHERE e.role IN ('arbejder', 'byggeleder')
AND ect.employee_id IS NULL;

-- Add crane type 2 to specific workers (adjust employee IDs as needed)
-- Example: Add crane type 2 to workers
INSERT INTO EmployeeCraneTypes (employee_id, crane_type_id, certification_date)
VALUES 
  -- Replace with actual employee IDs from your database
  (1, 2, NOW()),  -- Replace 1 with actual employee_id
  (2, 2, NOW()),  -- Replace 2 with actual employee_id
  (3, 2, NOW());  -- Replace 3 with actual employee_id

-- Or add crane type 2 to all workers who don't have any crane types
INSERT INTO EmployeeCraneTypes (employee_id, crane_type_id, certification_date)
SELECT e.employee_id, 2, NOW()
FROM Employees e
LEFT JOIN EmployeeCraneTypes ect ON e.employee_id = ect.employee_id
WHERE e.role IN ('arbejder', 'byggeleder')
AND ect.employee_id IS NULL;

-- Verify the assignments
SELECT e.employee_id, e.name, ct.name as crane_type_name
FROM Employees e
JOIN EmployeeCraneTypes ect ON e.employee_id = ect.employee_id
JOIN CraneTypes ct ON ect.crane_type_id = ct.crane_type_id
WHERE e.role IN ('arbejder', 'byggeleder')
ORDER BY e.name;