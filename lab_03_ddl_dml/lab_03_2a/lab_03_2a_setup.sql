-- =============================================================
-- File: lab_03_2a_setup.sql
-- Purpose: Create GPU_SALE table and insert sample data (Lab 3, group 2A)
-- =============================================================

-- Drop the table if it already exists
DROP TABLE IF EXISTS GPU_SALE CASCADE;

-- Create the GPU_SALE table
CREATE TABLE GPU_SALE
(
    TXN_ID INT PRIMARY KEY,
    SALE_DATE DATE NOT NULL,
    PRICE INT CHECK (PRICE >= 0),
    MODEL VARCHAR(50)
);

-- Insert records into GPU_SALE table
INSERT INTO GPU_SALE (TXN_ID, SALE_DATE, PRICE, MODEL) VALUES
(1001, '2026-01-14', 1850, 'RTX 4090'),
(1002, '2026-01-20', 999, 'RTX 4080'),
(1003, '2026-02-03', 920, 'RX 7900 XTX'),
(1004, '2025-12-28', 1720, 'RTX 4090'),
(1005, '2026-02-11', 0, 'RTX 4080'),
(1006, '2026-03-05', 549, 'RTX 4070'),
(1007, '2026-01-02', 1990, 'RTX 4090'),
(1008, '2026-02-25', 879, 'RX 7900 XTX'),
(1009, '2026-03-18', 1800, 'RTX 4090'),
(1010, '2026-03-01', 0, 'RX 7900 XTX'),
(1011, '2025-11-30', 1060, 'RTX 4080'),
(1012, '2026-02-14', 2100, 'RTX 4090'),
(1013, '2026-03-22', 529, 'RTX 4070');
