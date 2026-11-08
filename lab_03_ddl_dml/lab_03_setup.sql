-- =============================================================
-- File: employee.sql
-- Purpose: Create EMPLOYEE table and insert sample data
-- =============================================================

-- Drop the table if it already exists
DROP TABLE IF EXISTS EMPLOYEE CASCADE;

-- Create the EMPLOYEE table
CREATE TABLE EMPLOYEE
(
    ID INT PRIMARY KEY,
    NAME VARCHAR(50) NOT NULL,
    DEPT_NAME VARCHAR(50),
    SALARY INT CHECK (SALARY >= 0)
);

-- Insert records into EMPLOYEE table
INSERT INTO EMPLOYEE (ID, NAME, DEPT_NAME, SALARY) VALUES
(128, 'Zhang', 'Machinery', 1060),
(12345, 'Shankar', 'Finance', 3200),
(19991, 'Brandt', 'Finance', 80000),
(23121, 'Chavez', 'Sales', 11000),
(44553, 'Peltier', 'Machinery', 5750),
(45678, 'Levy', 'Sales', 460),
(54321, 'Williams', 'Finance', 45000),
(55739, 'Sanchez', 'Research', 38100),
(70557, 'Snow', 'Machinery', 0),
(76543, 'Brown', 'Research', 5800),
(76653, 'Aoi', 'Research', 0),
(98765, 'Bourikas', 'Sales', 9000),
(98988, 'Tanaka', 'Machinery', 1200);
