-- =============================================================
-- File: lab_03_1a_setup.sql
-- Purpose: Create CAR_MODEL table and insert sample data (Lab 3, group 1A)
-- =============================================================

-- Drop the table if it already exists
DROP TABLE IF EXISTS CAR_MODEL CASCADE;

-- Create the CAR_MODEL table
CREATE TABLE CAR_MODEL
(
    ID INT PRIMARY KEY,
    NAME VARCHAR(50) NOT NULL,
    MANUFACTURER VARCHAR(50),
    REGION VARCHAR(30),
    PRICE INT CHECK (PRICE >= 0)
);

-- Insert records into CAR_MODEL table
INSERT INTO CAR_MODEL (ID, NAME, MANUFACTURER, REGION, PRICE) VALUES
(201, 'Corolla', 'Toyota', 'Japan', 22000),
(202, 'Land Cruiser', 'Toyota', 'Japan', 57000),
(203, 'Civic', 'Honda', 'Japan', 24000),
(204, 'Seagull', 'BYD', 'China', 11000),
(205, 'Han', 'BYD', 'China', 32000),
(206, 'ET7', 'NIO', 'China', 68000),
(207, 'Coolray', 'Geely', 'China', 18000),
(208, 'G9', 'XPeng', 'China', 0),
(209, '3 Series', 'BMW', 'Germany', 45000),
(210, 'Golf', 'Volkswagen', 'Germany', 0),
(211, 'Model 3', 'Tesla', 'USA', 39000),
(212, 'Mustang', 'Ford', 'USA', 31000),
(213, 'Ioniq 5', 'Hyundai', 'South Korea', 43000);
