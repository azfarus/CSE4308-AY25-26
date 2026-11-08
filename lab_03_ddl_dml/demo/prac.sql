

SELECT * FROM STUDENTS;

ALTER TABLE STUDENTS ADD COLUMN major VARCHAR(30);

ALTER TABLE STUDENTS ADD COLUMN gpa NUMERIC(3,2);

ALTER TABLE STUDENTS ADD CONSTRAINT gpa_check CHECK (gpa >= 0.0 AND gpa <= 4.0);

UPDATE STUDENTS SET major = 'CSE' where first_name = 'Liam';

UPDATE STUDENTS SET major = 'CSE' ;


INSERT INTO STUDENTS VALUES (
    DEFAULT, 'Samnun' , 'Azfar', 'samnunazfar@iut-dhaka.edu', '2021-06-07','CSE',3.9 
);

INSERT INTO STUDENTS (student_id, first_name,last_name, gpa) VALUES (
    DEFAULT, 'Samnun','Azfar' , 3.9 
) ,(
    DEFAULT, 'Samia', 'Nawsheen',3.95
);

INSERT INTO STUDENTS ( first_name,last_name, gpa) VALUES (
     'Samnun','Azfar' , 3.9 
),(
     'Samia', 'Nawsheen',3.95
);

DELETE FROM STUDENTS WHERE first_name='Samnun';

UPDATE STUDENTS
SET major='ARTS'
WHERE gpa=3.5

SELECT first_name,email from students where gpa=NULL or gpa > 3.9;
