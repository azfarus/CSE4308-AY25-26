-- =============================================================
-- LAB 2: INITIAL TABLE CREATION AND SAMPLE DATA
-- DATABASE: cse4308_12345   (Replace with your full ID)
-- USER: alice              (Replace with your lowercase name)
-- =============================================================

-- Drop tables if they already exist (safety)
DROP TABLE IF EXISTS students CASCADE;
DROP TABLE IF EXISTS courses CASCADE;

-- =============================================================
-- Create Tables
-- =============================================================

CREATE TABLE students (
    student_id INT PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    major VARCHAR(10),
    gpa NUMERIC(3,2)
);

CREATE TABLE courses (
    course_id INT PRIMARY KEY,
    course_name VARCHAR(100) NOT NULL,
    credits INT
);

-- =============================================================
-- Insert Sample Records
-- =============================================================

INSERT INTO students (student_id, name, major, gpa) VALUES
(101, 'Alice', 'CSE', 3.80),
(102, 'Bob', 'EEE', 3.45),
(103, 'Charlie', 'CSE', 3.10);

INSERT INTO courses (course_id, course_name, credits) VALUES
(1, 'Database Systems', 3),
(2, 'Operating Systems', 3),
(3, 'Digital Electronics', 2);

-- =============================================================
-- Verification Queries (Optional)
-- =============================================================

-- \dt              -- List tables
-- SELECT * FROM students;
-- SELECT * FROM courses;

-- End of lab2.sql
