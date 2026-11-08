-- ==========================================
-- CLASS SETUP: UNIVERSITY DATABASE
-- ==========================================

-- 1. Clean up previous runs (Idempotency)
DROP TABLE IF EXISTS STUDENTS CASCADE;

-- 2. Create the initial table structure
-- We are intentionally missing 'major' and 'gpa' to demonstrate ALTER later.
CREATE TABLE STUDENTS (
    student_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE,
    enrollment_date DATE
);

-- 3. Insert Initial Data (Seeding)
-- Note: These are "existing" students. 
-- We verify that we can insert data before the table structure changes.
INSERT INTO STUDENTS (first_name, last_name, email, enrollment_date)
VALUES 
    ('Liam', 'Nelson', 'liam.n@uni.edu', '2022-03-10'),
    ('Olivia', 'Martinez', 'olivia.m@uni.edu', '2022-03-12'),
    ('Noah', 'Gupta', 'noah.g@uni.edu', '2022-04-01');

