
-- Task 1
INSERT INTO students (student_id, name, major, gpa)
VALUES (104, 'David', 'ME', 3.60);

INSERT INTO courses (course_id, course_name, credits)
VALUES (4, 'Machine Learning', 3);


SELECT * FROM students;
SELECT * FROM courses;

--Task 2
SELECT name, gpa FROM students WHERE major = 'CSE';
SELECT course_name FROM courses WHERE credits = 3;
SELECT * FROM students ORDER BY gpa DESC;


--Task 3
UPDATE students
SET gpa = 3.55
WHERE name = 'Bob';

UPDATE courses
SET credits = 4
WHERE course_name = 'Operating Systems';


SELECT * FROM students;
SELECT * FROM courses;


--Task 4
DELETE FROM students
WHERE name = 'Charlie';

DELETE FROM courses
WHERE course_name = 'Digital Electronics';

-- Task 5
SELECT * FROM students;
SELECT * FROM courses;

