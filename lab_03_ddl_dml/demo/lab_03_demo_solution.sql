-- ======================================================
-- LECTURE DEMO: DDL & DML OPERATIONS
-- ======================================================

-- STEP 1: INSPECT THE INITIAL STATE
-- "We start with the data already in our system."
SELECT * FROM STUDENTS;
-- Point out: We have IDs, names, and dates, but no grades yet.

-- [QUESTION 1] "Look at the output. We have 3 students (Liam, Olivia, Noah). We are about to add a major column. What will be the major for these three existing students after I run the command? Will it be empty? 'Undeclared'? Or an error?"

-- Answer: It will be NULL (empty), because we haven't specified a default value.



-- ======================================================
-- PART A: ALTERING THE SCHEMA (DDL)
-- ======================================================

-- "We need to track Major and GPA. Let's change the structure."

-- A1. ADD COLUMNS
ALTER TABLE STUDENTS ADD COLUMN major VARCHAR(30);

ALTER TABLE STUDENTS ADD COLUMN gpa NUMERIC(3,2);

-- A2. ADD CONSTRAINTS
-- "We want to ensure no one enters a GPA like -5.0 or 10.0"
ALTER TABLE STUDENTS ADD CONSTRAINT gpa_check CHECK (gpa >= 0.0 AND gpa <= 4.0);


-- "Let's look at the table now. Notice the empty fields (NULL)."
SELECT * FROM STUDENTS;

-- [QUESTION 2] "I just added a constraint that GPA must be between 0.0 and 4.0. However, our existing students currently have NULL GPAs. Did the command fail? Does NULL violate the rule 'Must be between 0 and 4'?"

-- Answer: It did not fail. In SQL, NULL represents 'unknown'. It is not a number, so it technically bypasses the numeric check unless we also added NOT NULL.

-- ======================================================
-- PART B: UPDATING LEGACY DATA (DML)
-- ======================================================

-- "Because we added columns later, our old students (Liam, Olivia, Noah) 
-- have NULL majors. We must fix (backfill) this data."

-- B1. Update Liam
UPDATE STUDENTS SET major = 'Mathematics', gpa = 3.5 WHERE first_name = 'Liam';
-- [QUESTION 3 - CRITICAL] "If I accidentally  just the first line—UPDATE STUDENTS SET major = 'Mathematics'—and forgot the WHERE clause... what would happen to Liam, Olivia and Noah?"

-- Answer: Everyone in the database would become a Mathematics major. Always check your WHERE clause!


-- B2. Update Olivia
UPDATE STUDENTS SET major = 'Computer Science', gpa = 3.9 WHERE first_name = 'Olivia';

-- B3. Update Noah
UPDATE STUDENTS SET major = 'Physics', gpa = 2.8 WHERE first_name = 'Noah';

-- "Now our existing data is clean."
SELECT * FROM STUDENTS;


-- ======================================================
-- PART C: INSERTING NEW DATA (DML)
-- ======================================================

-- "Now let's add NEW students using the new structure."

-- C1. Positional Notation (Risky)
-- "We must match the new column order: ID, First, Last, Email, Date, Major, GPA"
INSERT INTO STUDENTS VALUES (DEFAULT, 'John', 'Doe', 'john.doe@uni.edu', '2023-09-01', 'Computer Science', 3.2);
-- [QUESTION 4] "I am inserting Jane Smith. Notice I did not provide a student_id. How does the database know what ID to give her? Will it be 1?"

-- Answer: It uses the SERIAL type we defined at the start. It will look at the last ID used (3) and automatically assign her 4.

-- C2. Named Notation (Recommended)
INSERT INTO STUDENTS (first_name, last_name, email, enrollment_date, major, gpa) VALUES ('Jane', 'Smith', 'jane.s@uni.edu', '2023-09-01', 'Art', 3.8);

-- C3. Bulk Insert
INSERT INTO STUDENTS (first_name, last_name, email, enrollment_date, major, gpa) VALUES ('Bob', 'White', 'bob.w@uni.edu', '2024-01-15', 'History', 1.8), ('Diana', 'Prince', 'diana.p@uni.edu', '2021-09-01', 'Physics', 0.0);

-- [QUESTION 5] "Here is a student with a 5.0 GPA. What happens when I run this?"

-- Answer: It fails. The CHECK (gpa <= 4.0) constraint we added in Part A will block this entry to protect data quality.
INSERT INTO STUDENTS (first_name, last_name, email, enrollment_date, major, gpa)  VALUES ('Bad', 'Student', 'bad@uni.edu', '2023-09-01', 'Physics', 5.0);


SELECT * FROM STUDENTS;


-- ======================================================
-- PART D: DELETING & MODIFYING (DML)
-- ======================================================

-- "Diana decided to drop out, and Jane is switching majors."

-- D1. DELETE
DELETE FROM STUDENTS WHERE email = 'diana.p@uni.edu';
-- [QUESTION 6] "We are deleting Diana (who was ID 6). If I add a new student right after this, will that new student get ID 6 (recycling the number), or ID 7?"

-- Answer: ID 7. Databases generally do not recycle auto-increment IDs once they are used, even if the row is deleted. This ensures historical consistency.
INSERT INTO STUDENTS (first_name, last_name, email, enrollment_date, major, gpa) VALUES ('Abrar', 'Hasan', 'abh.s@uni.edu', '2023-09-01', 'Science', 5.0);


-- D2. UPDATE with a Condition
-- "Change Jane's major from Art to History"
UPDATE STUDENTS SET major = 'History' WHERE email = 'jane.s@uni.edu';


-- ======================================================
-- PART E: SELECTION & LOGIC (SELECT)
-- ======================================================

-- "Now let's query our mix of old and new students."

-- E1. Simple Filter
-- "Show students with a GPA higher than 3.0"
SELECT first_name, major, gpa FROM STUDENTS WHERE gpa > 3.0;

-- E2. AND Operator (Intersection)
-- "Computer Science majors with high grades"
SELECT * FROM STUDENTS WHERE major = 'Computer Science' AND gpa > 3.5;

-- E3. OR Operator (Union)
-- "Show me students in Physics OR History"
SELECT first_name, last_name, major FROM STUDENTS WHERE major = 'Physics' OR major = 'History';