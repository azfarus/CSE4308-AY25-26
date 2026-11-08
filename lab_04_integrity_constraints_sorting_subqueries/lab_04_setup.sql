-- ==========================================
-- TABLE CREATION
-- ==========================================

CREATE TABLE Categories (
    category_id INT PRIMARY KEY,
    category_name VARCHAR(50),
    description VARCHAR(200)
);

CREATE TABLE Products (
    product_id INT PRIMARY KEY,
    product_name VARCHAR(100),
    price DECIMAL(10, 2),
    stock_quantity INT,
    category_id INT,
    CONSTRAINT fk_prod_cat FOREIGN KEY (category_id) REFERENCES Categories(category_id)
);

CREATE TABLE Customers (
    customer_id INT PRIMARY KEY,
    full_name VARCHAR(100),
    city VARCHAR(50),
    email VARCHAR(100),
    join_date DATE
);

CREATE TABLE Orders (
    order_id INT PRIMARY KEY,
    customer_id INT,
    order_date DATE,
    total_amount DECIMAL(12, 2),
    status VARCHAR(20),
    CONSTRAINT fk_ord_cust FOREIGN KEY (customer_id) REFERENCES Customers(customer_id) ON DELETE CASCADE
);

CREATE TABLE Order_Items (
    item_id INT PRIMARY KEY,
    order_id INT,
    product_id INT,
    quantity INT,
    unit_price DECIMAL(10, 2),
    CONSTRAINT fk_item_ord FOREIGN KEY (order_id) REFERENCES Orders(order_id),
    CONSTRAINT fk_item_prod FOREIGN KEY (product_id) REFERENCES Products(product_id)
);

CREATE TABLE Reviews (
    review_id INT PRIMARY KEY,
    customer_id INT,
    product_id INT,
    rating INT CHECK (rating BETWEEN 1 AND 5),
    comment_text VARCHAR(255),
    CONSTRAINT fk_rev_cust FOREIGN KEY (customer_id) REFERENCES Customers(customer_id),
    CONSTRAINT fk_rev_prod FOREIGN KEY (product_id) REFERENCES Products(product_id)
);

-- ==========================================
-- DATA INSERTION
-- ==========================================

-- 1. Insert Categories
INSERT INTO Categories VALUES (1, 'Electronics', 'Gadgets and devices');
INSERT INTO Categories VALUES (2, 'Furniture', 'Home and office furniture');
INSERT INTO Categories VALUES (3, 'Smartphones', 'Mobile phones and accessories');
INSERT INTO Categories VALUES (4, 'Laptops', 'High performance computers');
INSERT INTO Categories VALUES (5, 'Books', 'Educational and fiction');

-- 2. Insert Products (20 items)
-- Note: 'Gaming Mouse' is ID 104, Price 45.00
-- Note: 'Wireless Headphones' is ID 105
INSERT INTO Products VALUES (101, 'Dell XPS 13', 1200.00, 10, 4);
INSERT INTO Products VALUES (102, 'MacBook Pro', 2500.00, 5, 4);
INSERT INTO Products VALUES (103, 'iPhone 14', 999.00, 20, 3);
INSERT INTO Products VALUES (104, 'Gaming Mouse', 45.00, 50, 1);
INSERT INTO Products VALUES (105, 'Wireless Headphones', 150.00, 30, 1);
INSERT INTO Products VALUES (106, 'Office Chair', 200.00, 15, 2);
INSERT INTO Products VALUES (107, 'Wooden Desk', 150.00, 10, 2); -- Same price as Headphones
INSERT INTO Products VALUES (108, 'Samsung Galaxy S23', 850.00, 25, 3);
INSERT INTO Products VALUES (109, 'Mechanical Keyboard', 45.00, 40, 1); -- Same price as Mouse
INSERT INTO Products VALUES (110, 'Monitor 4K', 400.00, 12, 1);
INSERT INTO Products VALUES (111, 'Harry Potter Set', 80.00, 100, 5);
INSERT INTO Products VALUES (112, 'Learning SQL', 45.00, 60, 5); -- Same price as Mouse
INSERT INTO Products VALUES (113, 'Sofa Bed', 600.00, 4, 2);
INSERT INTO Products VALUES (114, 'Dining Table', 550.00, 0, 2); -- Out of stock
INSERT INTO Products VALUES (115, 'USB-C Cable', 15.00, 200, 3);
INSERT INTO Products VALUES (116, 'Power Bank', 35.00, 80, 3);
INSERT INTO Products VALUES (117, 'Gaming Laptop', 1800.00, 8, 4);
INSERT INTO Products VALUES (118, 'Novel: The Alchemist', 15.00, 150, 5);
INSERT INTO Products VALUES (119, 'Bookshelf', 120.00, 0, 2); -- Out of stock
INSERT INTO Products VALUES (120, 'Tablet', 300.00, 35, 1);

-- 3. Insert Customers (15 customers)
-- Note: Alice Green is ID 203, Join Date 2023-03-10
INSERT INTO Customers VALUES (201, 'John Doe', 'New York', 'john@example.com', '2023-01-15');
INSERT INTO Customers VALUES (202, 'Jane Smith', 'Los Angeles', 'jane@test.com', '2023-02-20');
INSERT INTO Customers VALUES (203, 'Alice Green', 'Chicago', 'alice@demo.com', '2023-03-10');
INSERT INTO Customers VALUES (204, 'Bob White', 'New York', 'bob@mail.com', '2023-04-05');
INSERT INTO Customers VALUES (205, 'Charlie Brown', 'Houston', 'charlie@web.com', '2023-05-12');
INSERT INTO Customers VALUES (206, 'David Black', 'Chicago', 'david@net.com', '2023-06-01');
INSERT INTO Customers VALUES (207, 'Eve Blue', 'Phoenix', 'eve@site.com', '2023-06-15');
INSERT INTO Customers VALUES (208, 'Frank Red', 'New York', 'frank@zone.com', '2023-07-20');
INSERT INTO Customers VALUES (209, 'Grace Yellow', 'Seattle', 'grace@live.com', '2023-08-05');
INSERT INTO Customers VALUES (210, 'Hank Orange', 'Austin', 'hank@txt.com', '2023-09-10');
INSERT INTO Customers VALUES (211, 'Ivy Purple', 'Boston', 'ivy@edu.com', '2023-10-01');
INSERT INTO Customers VALUES (212, 'Jack Grey', 'Denver', 'jack@gov.com', '2023-11-15');
INSERT INTO Customers VALUES (213, 'Karen Gold', 'Miami', 'karen@biz.com', '2023-12-01');
INSERT INTO Customers VALUES (214, 'Leo Silver', 'Dallas', 'leo@org.com', '2024-01-10');
INSERT INTO Customers VALUES (215, 'Ghost User', 'Nowhere', 'ghost@void.com', '2024-02-01'); -- No orders

-- 4. Insert Orders
INSERT INTO Orders VALUES (1001, 201, '2023-03-01', 1245.00, 'Delivered');
INSERT INTO Orders VALUES (1002, 202, '2023-03-05', 45.00, 'Shipped');
INSERT INTO Orders VALUES (1003, 203, '2023-03-15', 999.00, 'Delivered');
INSERT INTO Orders VALUES (1004, 201, '2023-04-10', 50.00, 'Delivered');
INSERT INTO Orders VALUES (1005, 204, '2023-05-20', 2500.00, 'Pending');
INSERT INTO Orders VALUES (1006, 205, '2023-06-01', 150.00, 'Shipped');
INSERT INTO Orders VALUES (1007, 206, '2023-06-25', 850.00, 'Delivered');
INSERT INTO Orders VALUES (1008, 202, '2023-07-04', 200.00, 'Delivered');
INSERT INTO Orders VALUES (1009, 207, '2023-08-10', 1200.00, 'Cancelled');
INSERT INTO Orders VALUES (1010, 201, '2023-09-01', 300.00, 'Delivered');
INSERT INTO Orders VALUES (1011, 208, '2023-09-15', 1800.00, 'Pending');
INSERT INTO Orders VALUES (1012, 209, '2023-10-05', 45.00, 'Delivered');
INSERT INTO Orders VALUES (1013, 210, '2023-10-20', 600.00, 'Delivered');
INSERT INTO Orders VALUES (1014, 211, '2023-11-01', 150.00, 'Shipped');
INSERT INTO Orders VALUES (1015, 203, '2023-11-20', 120.00, 'Delivered');
INSERT INTO Orders VALUES (1016, 212, '2023-12-05', 80.00, 'Delivered');
INSERT INTO Orders VALUES (1017, 213, '2023-12-25', 2500.00, 'Delivered');
INSERT INTO Orders VALUES (1018, 201, '2024-01-05', 400.00, 'Pending');
INSERT INTO Orders VALUES (1019, 204, '2024-01-15', 15.00, 'Delivered');
INSERT INTO Orders VALUES (1020, 205, '2024-01-20', 35.00, 'Shipped');

-- 5. Insert Order_Items
-- 1001: Dell XPS (101) + Mouse (104)
INSERT INTO Order_Items VALUES (1, 1001, 101, 1, 1200.00);
INSERT INTO Order_Items VALUES (2, 1001, 104, 1, 45.00);
-- 1002: Mouse (104)
INSERT INTO Order_Items VALUES (3, 1002, 104, 1, 45.00);
-- 1003: iPhone 14 (103)
INSERT INTO Order_Items VALUES (4, 1003, 103, 1, 999.00);
-- 1004: Learning SQL (112)
INSERT INTO Order_Items VALUES (5, 1004, 112, 1, 45.00);
-- 1005: MacBook Pro (102)
INSERT INTO Order_Items VALUES (6, 1005, 102, 1, 2500.00);
-- 1006: Wireless Headphones (105) - User 205 bought this
INSERT INTO Order_Items VALUES (7, 1006, 105, 1, 150.00);
-- 1007: Galaxy S23 (108)
INSERT INTO Order_Items VALUES (8, 1007, 108, 1, 850.00);
-- 1008: Office Chair (106)
INSERT INTO Order_Items VALUES (9, 1008, 106, 1, 200.00);
-- 1009: Dell XPS (101)
INSERT INTO Order_Items VALUES (10, 1009, 101, 1, 1200.00);
-- 1010: Tablet (120)
INSERT INTO Order_Items VALUES (11, 1010, 120, 1, 300.00);
-- 1011: Gaming Laptop (117)
INSERT INTO Order_Items VALUES (12, 1011, 117, 1, 1800.00);
-- 1012: Mechanical Keyboard (109)
INSERT INTO Order_Items VALUES (13, 1012, 109, 1, 45.00);
-- 1013: Sofa Bed (113)
INSERT INTO Order_Items VALUES (14, 1013, 113, 1, 600.00);
-- 1014: Wooden Desk (107) - User 211 bought this
INSERT INTO Order_Items VALUES (15, 1014, 107, 1, 150.00);
-- 1015: Bookshelf (119)
INSERT INTO Order_Items VALUES (16, 1015, 119, 1, 120.00);
-- 1016: Harry Potter (111)
INSERT INTO Order_Items VALUES (17, 1016, 111, 1, 80.00);
-- 1017: MacBook Pro (102)
INSERT INTO Order_Items VALUES (18, 1017, 102, 1, 2500.00);
-- 1018: Monitor 4K (110)
INSERT INTO Order_Items VALUES (19, 1018, 110, 1, 400.00);
-- 1019: USB-C Cable (115)
INSERT INTO Order_Items VALUES (20, 1019, 115, 1, 15.00);
-- 1020: Power Bank (116)
INSERT INTO Order_Items VALUES (21, 1020, 116, 1, 35.00);

-- 6. Insert Reviews
INSERT INTO Reviews VALUES (1, 201, 101, 5, 'Excellent Laptop');
INSERT INTO Reviews VALUES (2, 201, 104, 4, 'Good mouse');
INSERT INTO Reviews VALUES (3, 202, 104, 5, 'Best budget mouse');
INSERT INTO Reviews VALUES (4, 203, 103, 4, 'Great phone but expensive');
INSERT INTO Reviews VALUES (5, 205, 105, 5, 'Sound quality is amazing'); -- Wireless Headphones
INSERT INTO Reviews VALUES (6, 204, 102, 5, 'Powerful machine');
INSERT INTO Reviews VALUES (7, 208, 117, 4, 'Runs hot but fast');
INSERT INTO Reviews VALUES (8, 201, 110, 3, 'Okay display');
INSERT INTO Reviews VALUES (9, 210, 113, 2, 'Uncomfortable to sleep on');
INSERT INTO Reviews VALUES (10, 211, 107, 5, 'Solid wood desk');
INSERT INTO Reviews VALUES (11, 201, 104, 3, 'Scroll wheel broke after a month');
INSERT INTO Reviews VALUES (12, 209, 109, 5, 'Clicky keys love it');