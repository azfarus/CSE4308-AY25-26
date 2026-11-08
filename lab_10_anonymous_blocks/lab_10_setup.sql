str-- 1. CLEANUP
DROP TABLE IF EXISTS employees;

-- 2. CREATE TABLE
CREATE TABLE employees (
    employee_id SERIAL PRIMARY KEY,
    first_name  VARCHAR(50),
    last_name   VARCHAR(50),
    salary      NUMERIC(10, 2),
    department  VARCHAR(50)
);

-- 3. INSERT KEY PERSONNEL (Deterministic Data)
-- We insert these specific people so we can always find them in queries
INSERT INTO employees (first_name, last_name, salary, department) VALUES 
('Alice', 'Zia', 25000.00, 'Management'),
('Bob', 'Marshall', 15000.00, 'IT'),
('Charlie', 'Uddin', 12000.00, 'Marketing'),
('Rahim', 'Scott', 4500.00, 'Operations');

select * from employees;

-- 4. BULK INSERT (Randomized Data)
-- This generates 1000 fake employees
INSERT INTO employees (first_name, last_name, salary, department)
SELECT 
    -- Pick a random first name from the array (Mixed International & Bangladeshi)
    (ARRAY[
        'John','Jane','Mike','Sara','Tom','Emily','Chris','Anna','Steve','Laura',
        'Rahim','Karim','Fatima','Ayesha','Rafiq','Jabbar','Nasrin','Monir','Sultana','Kamal'
    ])[floor(random() * 20 + 1)],
    
    -- Pick a random last name (Mixed International & Bangladeshi)
    (ARRAY[
        'Smith','Johnson','Williams','Jones','Brown','Davis','Miller','Wilson','Moore','Taylor',
        'Ahmed','Hossain','Khan','Chowdhury','Rahman','Islam','Sarker','Uddin','Ali','Hasan'
    ])[floor(random() * 20 + 1)],
    
    -- Generate random salary between 3,000 and 18,000
    ROUND((random() * 15000 + 3000)::numeric, 2),
    
    -- Pick a random department
    (ARRAY['IT', 'HR', 'Management', 'Marketing', 'Sales', 'Operations'])[floor(random() * 6 + 1)]
FROM generate_series(1, 1000);

-- 5. VERIFY
-- Should return 1004 rows
SELECT count(*) as total_employees FROM employees;
