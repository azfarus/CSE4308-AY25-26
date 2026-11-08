-- ============================================================
-- LAB 5: THE SQL MURDER MYSTERY (QUESTION BANK EDITION)
-- Plot: The Grade Sheet Database was wiped.
-- ============================================================

-- 1. CLEANUP
DROP TABLE IF EXISTS access_logs CASCADE;
DROP TABLE IF EXISTS cafeteria_orders CASCADE;
DROP TABLE IF EXISTS library_records CASCADE;
DROP TABLE IF EXISTS locations CASCADE;
DROP TABLE IF EXISTS suspects CASCADE;

-- 2. CREATE TABLES

-- Table: Suspects
CREATE TABLE suspects (
    suspect_id SERIAL PRIMARY KEY,
    name VARCHAR(50),
    occupation VARCHAR(50), -- Exam Controller, Student, System Admin, Lab Attendant, Research Assistant
    height_cm INT,
    access_level INT -- 1 (Low) to 5 (High)
);

-- Table: Locations
CREATE TABLE locations (
    location_id SERIAL PRIMARY KEY,
    location_name VARCHAR(100),
    floor_number INT
);

-- Table: Access_Logs (Swipe card data)
CREATE TABLE access_logs (
    log_id SERIAL PRIMARY KEY,
    suspect_id INT,
    location_id INT,
    entry_time TIMESTAMP,
    CONSTRAINT fk_log_suspect FOREIGN KEY (suspect_id) 
        REFERENCES suspects(suspect_id) ON DELETE CASCADE,
    CONSTRAINT fk_log_loc FOREIGN KEY (location_id) 
        REFERENCES locations(location_id) ON DELETE CASCADE
);

-- Table: Cafeteria_Orders (Financial trail)
CREATE TABLE cafeteria_orders (
    order_id SERIAL PRIMARY KEY,
    suspect_id INT,
    item_name VARCHAR(100),
    price NUMERIC(10, 2),
    order_date DATE,
    CONSTRAINT fk_cafe_suspect FOREIGN KEY (suspect_id) 
        REFERENCES suspects(suspect_id) ON DELETE CASCADE
);

-- Table: Library_Records (Reading habits/Alibis)
CREATE TABLE library_records (
    record_id SERIAL PRIMARY KEY,
    suspect_id INT,
    book_title VARCHAR(100),
    borrow_date DATE,
    return_date DATE, -- NULL if not returned
    CONSTRAINT fk_lib_suspect FOREIGN KEY (suspect_id) 
        REFERENCES suspects(suspect_id) ON DELETE CASCADE
);

-- 3. INSERT EVIDENCE

-- Suspects
INSERT INTO suspects (name, occupation, height_cm, access_level) VALUES
('Zahid', 'Exam Controller', 178, 5),   -- High access to Grade Sheets
('Nafis', 'Student', 170, 1),
('Tabib', 'Research Assistant', 175, 4),  
('Sieam', 'Student', 168, 1),
('Muhaimin', 'System Admin', 182, 5),     -- The actual IT Admin
('Nibir', 'Lab Attendant', 165, 3);

-- Locations
INSERT INTO locations (location_name, floor_number) VALUES
('Server Room', 3),     -- The Crime Scene
('North Canteen', 1),
('IUT Library', 2),
('Games Room', 1),
('Faculty Lounge', 3);

-- Access Logs (Crime Time: 2024-12-01 between 14:00 and 16:00)
INSERT INTO access_logs (suspect_id, location_id, entry_time) VALUES
(1, 1, '2024-12-01 14:15:00'), -- Zahid in Server Room (Suspect!)
(2, 4, '2024-12-01 14:00:00'), -- Nafis in Games Room
(3, 5, '2024-12-01 13:50:00'), -- Tabib in Faculty Lounge
(4, 2, '2024-12-01 14:10:00'), -- Sieam in Canteen
(5, 1, '2024-12-01 09:00:00'), -- Muhaimin in Server Room (Too early)
(6, 2, '2024-12-01 12:00:00'), -- Nibir in Canteen
(1, 2, '2024-12-01 15:00:00'), -- Zahid went to canteen after crime
(3, 1, '2024-12-02 08:00:00'); -- Tabib entered next day

-- Cafeteria Orders
INSERT INTO cafeteria_orders (suspect_id, item_name, price, order_date) VALUES
(1, 'Double Espresso', 150.00, '2024-12-01'), -- Zahid needs energy
(1, 'Pizza', 450.00, '2024-12-01'),
(2, 'Singara', 10.00, '2024-12-01'),
(2, 'Coke', 25.00, '2024-12-01'),
(4, 'Burger', 120.00, '2024-12-01'),
(5, 'Coffee', 30.00, '2024-12-02'),
(6, 'Tea', 10.00, '2024-12-01');
-- Note: Tabib (Suspect 3) bought nothing

-- Library Records
INSERT INTO library_records (suspect_id, book_title, borrow_date, return_date) VALUES
(1, 'Advanced Hacking', '2024-11-20', NULL), -- Zahid reading suspicious books
(2, 'Intro to DB', '2024-11-25', '2024-11-30'),
(3, 'Teaching Methodologies', '2024-11-10', NULL),
(5, 'Linux Admin', '2024-10-01', '2024-10-15'),
(6, 'Lab Safety', '2024-09-01', NULL);
-- Note: Sieam (Suspect 4) has no books