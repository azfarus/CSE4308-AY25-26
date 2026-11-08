-- =============================================================
-- File: lab_03_2b_setup.sql
-- Purpose: Create MOVIE table and insert sample data (Lab 3, group 2B)
-- =============================================================

-- Drop the table if it already exists
DROP TABLE IF EXISTS MOVIE CASCADE;

-- Create the MOVIE table
CREATE TABLE MOVIE
(
    ID INT PRIMARY KEY,
    NAME VARCHAR(50) NOT NULL,
    GENRE VARCHAR(30),
    BOX_OFFICE INT CHECK (BOX_OFFICE >= 0)
);

-- Insert records into MOVIE table
INSERT INTO MOVIE (ID, NAME, GENRE, BOX_OFFICE) VALUES
(101, 'Inception', 'Sci-Fi', 837),
(102, 'The Dark Knight', 'Action', 1006),
(103, 'Mad Max: Fury Road', 'Action', 380),
(104, 'The Hangover', 'Comedy', 469),
(105, 'Get Out', 'Horror', 255),
(106, 'Avengers: Endgame', 'Action', 2799),
(107, 'Superbad', 'Comedy', 170),
(108, 'It', 'Horror', 701),
(109, 'Interstellar', 'Sci-Fi', 731),
(110, 'Skyfall', 'Action', 1109),
(111, 'Untitled Space Saga', 'Sci-Fi', 0),
(112, 'The Conjuring', 'Horror', 320),
(113, 'Midnight Laughs', 'Comedy', 0);
