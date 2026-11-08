-- ================================================================
-- DATABASE SCHEMA: CAMPUS SECURITY & OPS
-- Context: University management system with dirty data,
-- security logs, and mixed-case entries.
-- ================================================================

DROP TABLE IF EXISTS Enrollments;
DROP TABLE IF EXISTS Course_Catalog;
DROP TABLE IF EXISTS Gate_Logs;
DROP TABLE IF EXISTS Server_Logs;
DROP TABLE IF EXISTS Faculty;
DROP TABLE IF EXISTS Students;

-- 1. Students (Contains mixed case names for INITCAP/UPPER tasks)
CREATE TABLE Students (
    student_id SERIAL PRIMARY KEY,
    full_name VARCHAR(100),
    email_addr VARCHAR(100),
    enrollment_date DATE
);

INSERT INTO Students (student_id, full_name, email_addr, enrollment_date) VALUES
(1001, 'ALICE pendergast', 'alice.p@university.edu', '2020-09-01'),
(1002, 'bob VANCE', 'bob.vance@gmail.com', '2021-01-15'),
(1003, 'charlie DAY', 'charlie.day@university.edu', '2022-09-01'),
(1004, 'david WALLACE', 'd.wallace@yahoo.com', '2023-02-10'),
(1005, 'eve POLASTRI', 'eve.polastri@mi6.org', '2023-09-01'),
(1006, 'frank REYNOLDS', 'frank.r@university.edu', '2024-01-20');

-- 2. Faculty (For Tenure/AGE calculations)
CREATE TABLE Faculty (
    faculty_id SERIAL PRIMARY KEY,
    name VARCHAR(100),
    department VARCHAR(50),
    hired_date DATE,
    salary INT
);

INSERT INTO Faculty (faculty_id, name, department, hired_date, salary) VALUES
(501, 'Dr. Gregory House', 'Medicine', '2015-06-01', 150000),
(502, 'Prof. Severus Snape', 'Chemistry', '2010-08-15', 85000),
(503, 'Ross Geller', 'Paleontology', '2018-01-10', 65000),
(504, 'Walter White', 'Chemistry', '2019-05-20', 75000);

-- 3. Course Catalog
CREATE TABLE Course_Catalog (
    course_code VARCHAR(10) PRIMARY KEY,
    title VARCHAR(100),
    credits INT
);

INSERT INTO Course_Catalog VALUES 
('CS101', 'Intro to CS', 3),
('CS102', 'Data Structures', 4),
('CHEM201', 'Organic Chemistry', 4),
('HIST101', 'World History', 2);

-- 4. Enrollments (For Set Operations)
CREATE TABLE Enrollments (
    student_id INT REFERENCES Students(student_id),
    course_code VARCHAR(10) REFERENCES Course_Catalog(course_code),
    semester VARCHAR(20)
);

INSERT INTO Enrollments VALUES
(1001, 'CS101', 'Fall 2023'),
(1001, 'CS102', 'Spring 2024'),
(1002, 'CS101', 'Fall 2023'),
(1003, 'HIST101', 'Fall 2023'),
(1004, 'CS102', 'Spring 2024'), -- Taking CS102
(1004, 'CHEM201', 'Spring 2024'), -- Taking CHEM201
(1005, 'CS102', 'Spring 2024'), -- Taking CS102
(1005, 'CHEM201', 'Spring 2024'); -- Taking CHEM201 (Overlap with 1004)

-- 5. Gate Logs (For Set Operators & Date Extraction)
CREATE TABLE Gate_Logs (
    log_id SERIAL PRIMARY KEY,
    person_id INT, -- Refers to Student or Faculty
    location VARCHAR(50),
    entry_time TIMESTAMP
);

INSERT INTO Gate_Logs (person_id, location, entry_time) VALUES
(1001, 'Library Main', '2024-12-10 08:30:00'),
(1002, 'Cafeteria', '2024-12-10 12:15:00'),
(1004, 'Server Room', '2024-12-10 14:00:00'), -- Student in Server Room
(502, 'Chemistry Lab', '2024-12-10 09:00:00'),
(504, 'Chemistry Lab', '2024-12-10 09:15:00'),
(1004, 'Chemistry Lab', '2024-12-11 10:00:00'), -- Same student, diff location
(1005, 'Server Room', '2024-12-11 14:05:00'); 

-- 6. Server Logs (Dirty strings for TRIM/REPLACE)
CREATE TABLE Server_Logs (
    id SERIAL PRIMARY KEY,
    raw_msg TEXT
);

INSERT INTO Server_Logs (raw_msg) VALUES
('   [WARN] Disk_Space_Low   '),
('##CRITICAL_FAILURE##'),
('__User_Admin_Login__'),
('   [INFO] System_Update_Complete '),
('Error_404_Page_Not_Found');