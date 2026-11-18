-- ============================================================
-- WEEK 15: INDUSTRY CAPSTONE PROJECT
-- E-COMMERCE INTELLIGENCE PLATFORM
-- ONE complete script. Needs MySQL 8.0 or newer.
--
-- HOW TO RUN
--   1. Connect to MySQL Workbench as ROOT (triggers and functions
--      need extra privileges that root has).
--   2. Open this file and press Ctrl + Shift + Enter (run ALL).
--   3. Wait about 1 minute. Every row in the Output panel should have
--      a green tick. Each result tab is one query or report.
--   4. To re-run one query later: click inside that single statement
--      and press Ctrl + Enter. To rebuild everything: run the file again.
--   If you ever see error 1418 or 1419 while creating functions or
--   triggers, run this once and then run the file again:
--      SET GLOBAL log_bin_trust_function_creators = 1;
--
-- BUSINESS RULES USED IN EVERY REPORT
--   * A "sale" means an order with Order_Status = 'Completed'.
--   * Money values are plain numbers in rupees.
--
-- CONTENTS
--   Task 1  Integrated modules
--   Task 2  ER diagram, keys, relationships, normalization
--   Task 3  Realistic business data and data-quality checks
--   Task 4  Basic, intermediate and advanced SQL queries
--   Task 5  Views, procedures, functions, triggers
--   Task 6  Indexes, EXPLAIN and query timing
--   Task 7  Business instelligence reports
--   Task 8  Live demonstration of the automation
-- ============================================================

-- Version check. Expected: OK - MySQL 8.0 or newer detected
SELECT VERSION() AS MySQL_Version,
       IF(CAST(SUBSTRING_INDEX(VERSION(), '.', 1) AS UNSIGNED) >= 8,
          'OK - MySQL 8.0 or newer detected',
          'STOP - MySQL 8.0 or newer is required') AS Version_Check;

DROP DATABASE IF EXISTS ecommerce_capstone_db;
CREATE DATABASE ecommerce_capstone_db;
USE ecommerce_capstone_db;

-- ============================================================
-- TASK 1: INTEGRATE ALL DATABASE MODULES
-- Every module from the earlier weeks lives in one connected database.
--
--   Module                          Tables
--   Customer Management             Customer
--   Product and Category Mgmt       Product, Category
--   Seller Management               Seller
--   Inventory Management            Inventory
--   Order Management                Orders, Order_Details
--   Payment Management              Payment
--   Product Review and Rating       Review
--   Sales Analytics                 views, procedures, reports (Tasks 5 and 7)
--   Security / audit (Week 13)      Audit_Log, filled automatically by triggers
-- ============================================================

-- ============================================================
-- TASK 2: ER DIAGRAM, KEYS, RELATIONSHIPS AND NORMALIZATION
-- ============================================================
--
-- RELATIONSHIPS (final ER diagram in text form)
--   Category 1 ---- * Product        a category has many products
--   Seller   1 ---- * Product        a seller lists many products
--   Product  1 ---- 1 Inventory      one stock record per product
--   Customer 1 ---- * Orders         a customer places many orders
--   Orders   1 ---- * Order_Details  an order has many lines
--   Product  1 ---- * Order_Details  a product appears in many lines
--   Orders   1 ---- 1 Payment        one payment record per order
--   Customer 1 ---- * Review         a customer writes many reviews
--   Product  1 ---- * Review         a product receives many reviews
--   Orders   * ---- * Product        many-to-many, resolved by Order_Details
--   Audit_Log                        no foreign keys, written by triggers
--
-- TO DRAW THE ER DIAGRAM IN WORKBENCH (needed for the report):
--   Database menu -> Reverse Engineer -> pick ecommerce_capstone_db -> Next
--   until the EER diagram appears, then File -> Export -> PNG/PDF.
--
-- NORMALIZATION
--   Starting point (unnormalized), one flat sheet:
--     Orders_Flat(Order_ID, Order_Date, Customer_Name, Customer_Email,
--       Customer_City, Products, Quantities, Category, Seller, Seller_City,
--       Payment_Method, Payment_Status)
--     Problems: several products in one cell, repeated customer and seller
--     data, update and delete anomalies.
--
--   1NF (atomic values, no repeating groups)
--     Every cell holds one value. The "Products" and "Quantities" lists
--     become one row per product in an order (Order_Details). Every table
--     has a primary key.
--
--   2NF (no partial dependency on part of a composite key)
--     In Order_Details the key is (Order_ID, Product_ID). Product_Name,
--     Category and Seller depend only on Product_ID, and Order_Date and
--     the customer depend only on Order_ID. They moved to Product and
--     Orders, so every non-key column depends on the whole key.
--
--   3NF (no transitive dependency)
--     Customer_City depends on Customer_ID, not on Order_ID -> Customer.
--     Category_Name depends on Category_ID, not on Product_ID -> Category.
--     Seller_Name and Seller_City depend on Seller_ID -> Seller.
--     Payment details depend on the payment, not on the order -> Payment.
--
--   Two deliberate design choices that are NOT violations:
--     * Order_Details.Price is a snapshot of the price at purchase time,
--       so old orders keep their history when the product price changes.
--     * Orders.Total_Amount is a stored total kept for fast reporting. It is
--       always calculated from the order lines (loader, sp_place_order).

CREATE TABLE Category (
    Category_ID   INT          AUTO_INCREMENT PRIMARY KEY,
    Category_Name VARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE Seller (
    Seller_ID   INT          AUTO_INCREMENT PRIMARY KEY,
    Seller_Name VARCHAR(100) NOT NULL UNIQUE,
    Email       VARCHAR(100) NOT NULL UNIQUE,
    Phone       VARCHAR(15)  NOT NULL,
    City        VARCHAR(50)  NOT NULL,
    Joined_Date DATE         NOT NULL
);

CREATE TABLE Customer (
    Customer_ID       INT          AUTO_INCREMENT PRIMARY KEY,
    Customer_Name     VARCHAR(100) NOT NULL,
    Email             VARCHAR(100) NOT NULL UNIQUE,
    Phone             VARCHAR(15)  NOT NULL UNIQUE,
    City              VARCHAR(50)  NOT NULL,
    Registration_Date DATE         NOT NULL
);

CREATE TABLE Product (
    Product_ID   INT           AUTO_INCREMENT PRIMARY KEY,
    Product_Name VARCHAR(150)  NOT NULL,
    Category_ID  INT           NOT NULL,
    Seller_ID    INT           NOT NULL,
    Price        DECIMAL(10,2) NOT NULL CHECK (Price > 0),
    FOREIGN KEY (Category_ID) REFERENCES Category(Category_ID),
    FOREIGN KEY (Seller_ID)   REFERENCES Seller(Seller_ID)
);

CREATE TABLE Inventory (
    Product_ID     INT  PRIMARY KEY,
    Stock_Quantity INT  NOT NULL CHECK (Stock_Quantity >= 0),
    Reorder_Level  INT  NOT NULL DEFAULT 20 CHECK (Reorder_Level >= 0),
    Last_Restocked DATE NOT NULL,
    FOREIGN KEY (Product_ID) REFERENCES Product(Product_ID)
);

CREATE TABLE Orders (
    Order_ID     INT           AUTO_INCREMENT PRIMARY KEY,
    Customer_ID  INT           NOT NULL,
    Order_Date   DATE          NOT NULL,
    Total_Amount DECIMAL(12,2) NOT NULL CHECK (Total_Amount >= 0),
    Order_Status VARCHAR(20)   NOT NULL
                 CHECK (Order_Status IN ('Pending','Completed','Cancelled')),
    FOREIGN KEY (Customer_ID) REFERENCES Customer(Customer_ID)
);

CREATE TABLE Order_Details (
    Order_Detail_ID INT           AUTO_INCREMENT PRIMARY KEY,
    Order_ID        INT           NOT NULL,
    Product_ID      INT           NOT NULL,
    Quantity        INT           NOT NULL CHECK (Quantity > 0),
    Price           DECIMAL(10,2) NOT NULL CHECK (Price > 0),
    UNIQUE KEY uq_order_product (Order_ID, Product_ID),
    FOREIGN KEY (Order_ID)   REFERENCES Orders(Order_ID),
    FOREIGN KEY (Product_ID) REFERENCES Product(Product_ID)
);

CREATE TABLE Payment (
    Payment_ID     INT           AUTO_INCREMENT PRIMARY KEY,
    Order_ID       INT           NOT NULL,
    Payment_Method VARCHAR(20)   NOT NULL
                   CHECK (Payment_Method IN ('UPI','Credit Card','Debit Card','Net Banking')),
    Amount         DECIMAL(12,2) NOT NULL CHECK (Amount >= 0),
    Payment_Status VARCHAR(20)   NOT NULL
                   CHECK (Payment_Status IN ('Success','Failed','Pending')),
    Payment_Date   DATE          NOT NULL,
    UNIQUE KEY uq_payment_order (Order_ID),
    FOREIGN KEY (Order_ID) REFERENCES Orders(Order_ID)
);

CREATE TABLE Review (
    Review_ID   INT          AUTO_INCREMENT PRIMARY KEY,
    Product_ID  INT          NOT NULL,
    Customer_ID INT          NOT NULL,
    Rating      INT          NOT NULL CHECK (Rating BETWEEN 1 AND 5),
    Review_Text VARCHAR(255),
    Review_Date DATE         NOT NULL,
    UNIQUE KEY uq_review (Product_ID, Customer_ID),
    FOREIGN KEY (Product_ID)  REFERENCES Product(Product_ID),
    FOREIGN KEY (Customer_ID) REFERENCES Customer(Customer_ID)
);

-- Filled automatically by triggers (Task 5)
CREATE TABLE Audit_Log (
    Audit_ID    INT          AUTO_INCREMENT PRIMARY KEY,
    Table_Name  VARCHAR(30)  NOT NULL,
    Action_Type VARCHAR(20)  NOT NULL,
    Record_ID   INT          NOT NULL,
    Old_Value   VARCHAR(100),
    New_Value   VARCHAR(100),
    Changed_By  VARCHAR(100) NOT NULL,
    Changed_At  TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Helper tables used only to generate sample data (safe to ignore)
CREATE TABLE Digits (d INT PRIMARY KEY);
INSERT INTO Digits VALUES (0),(1),(2),(3),(4),(5),(6),(7),(8),(9);

CREATE TABLE Numbers (n INT PRIMARY KEY);
INSERT INTO Numbers (n)
SELECT d1.d + d2.d*10 + d3.d*100 + d4.d*1000 + d5.d*10000 + 1
FROM Digits d1
CROSS JOIN Digits d2
CROSS JOIN Digits d3
CROSS JOIN Digits d4
CROSS JOIN Digits d5;
-- Numbers now holds 1 .. 100000

CREATE TABLE Stg_Products (
    Product_ID   INT,
    Product_Name VARCHAR(150),
    Category_ID  INT,
    Price        DECIMAL(10,2)
);

CREATE TABLE Stg_Lines (
    Order_ID    INT,
    Customer_ID INT,
    Order_Date  DATE,
    Product_ID  INT,
    Quantity    INT,
    Price       DECIMAL(10,2)
);

-- ---------- Schema documentation straight from the database ----------

-- Entities, attributes and key type (PRI = primary key, UNI = unique, MUL = indexed)
SELECT TABLE_NAME     AS Entity,
       COLUMN_NAME    AS Attribute,
       COLUMN_TYPE    AS Data_Type,
       IS_NULLABLE    AS Nullable,
       COLUMN_KEY     AS Key_Type
FROM information_schema.COLUMNS
WHERE TABLE_SCHEMA = 'ecommerce_capstone_db'
  AND TABLE_NAME IN ('Category','Seller','Customer','Product','Inventory',
                     'Orders','Order_Details','Payment','Review','Audit_Log')
ORDER BY TABLE_NAME, ORDINAL_POSITION;

-- Primary keys
SELECT TABLE_NAME AS Entity,
       GROUP_CONCAT(COLUMN_NAME ORDER BY ORDINAL_POSITION) AS Primary_Key
FROM information_schema.KEY_COLUMN_USAGE
WHERE TABLE_SCHEMA = 'ecommerce_capstone_db'
  AND CONSTRAINT_NAME = 'PRIMARY'
  AND TABLE_NAME IN ('Category','Seller','Customer','Product','Inventory',
                     'Orders','Order_Details','Payment','Review','Audit_Log')
GROUP BY TABLE_NAME
ORDER BY TABLE_NAME;

-- Foreign keys = the relationships of the ER diagram
SELECT TABLE_NAME             AS Child_Table,
       COLUMN_NAME            AS Foreign_Key,
       REFERENCED_TABLE_NAME  AS Parent_Table,
       REFERENCED_COLUMN_NAME AS Parent_Key
FROM information_schema.KEY_COLUMN_USAGE
WHERE TABLE_SCHEMA = 'ecommerce_capstone_db'
  AND REFERENCED_TABLE_NAME IS NOT NULL
ORDER BY TABLE_NAME, COLUMN_NAME;

-- ============================================================
-- TASK 3: REALISTIC BUSINESS DATA
-- 50 customers, 100 products, 20 sellers, 100 orders, 100 payments, 50 reviews
-- ============================================================

INSERT INTO Category (Category_ID, Category_Name) VALUES
 (1,'Smartphones'),(2,'Laptops'),(3,'Audio'),(4,'Televisions'),(5,'Home Appliances'),
 (6,'Wearables'),(7,'Cameras'),(8,'Gaming'),(9,'Computer Accessories'),(10,'Kitchen Appliances');

-- 20 sellers
INSERT INTO Seller (Seller_ID, Seller_Name, Email, Phone, City, Joined_Date) VALUES
 (1,  'TechWorld Retail',      'contact@techworld.example.com',          '9840010001', 'Chennai',       '2022-03-15'),
 (2,  'Digital Bazaar',        'sales@digitalbazaar.example.com',        '9820010002', 'Mumbai',        '2022-04-02'),
 (3,  'Gadget Galaxy',         'hello@gadgetgalaxy.example.com',         '9880010003', 'Bengaluru',     '2022-05-20'),
 (4,  'Metro Electronics',     'info@metroelectronics.example.com',      '9810010004', 'Delhi',         '2022-06-11'),
 (5,  'Smart Choice Traders',  'care@smartchoice.example.com',           '9848010005', 'Hyderabad',     '2022-07-08'),
 (6,  'Prime Mobiles',         'orders@primemobiles.example.com',        '9822010006', 'Pune',          '2022-08-19'),
 (7,  'Elite Appliances',      'support@eliteappliances.example.com',    '9830010007', 'Kolkata',       '2022-09-23'),
 (8,  'HomeNeeds Store',       'team@homeneeds.example.com',             '9847010008', 'Kochi',         '2022-10-30'),
 (9,  'Vision Electronics',    'sales@visionelectronics.example.com',    '9828010009', 'Jaipur',        '2022-11-14'),
 (10, 'Sound Station',         'shop@soundstation.example.com',          '9825010010', 'Ahmedabad',     '2022-12-05'),
 (11, 'Compu Hub',             'contact@compuhub.example.com',           '9843010011', 'Coimbatore',    '2023-01-17'),
 (12, 'Zenith Retail',         'hello@zenithretail.example.com',         '9839010012', 'Lucknow',       '2023-02-09'),
 (13, 'Urban Gadgets',         'info@urbangadgets.example.com',          '9815010013', 'Chandigarh',    '2023-03-21'),
 (14, 'Bright Home Mart',      'sales@brighthome.example.com',           '9842010014', 'Madurai',       '2023-04-12'),
 (15, 'Nova Tech Solutions',   'care@novatech.example.com',              '9849010015', 'Visakhapatnam', '2023-05-26'),
 (16, 'Pixel Point',           'orders@pixelpoint.example.com',          '9845010016', 'Mysuru',        '2023-06-30'),
 (17, 'Everyday Electronics',  'support@everydayelectronics.example.com','9823010017', 'Nagpur',        '2023-07-18'),
 (18, 'Mega Mart Online',      'team@megamart.example.com',              '9826010018', 'Indore',        '2023-08-24'),
 (19, 'Kitchen Kingdom',       'shop@kitchenkingdom.example.com',        '9824010019', 'Surat',         '2023-09-15'),
 (20, 'Future Tech Traders',   'contact@futuretech.example.com',         '9827010020', 'Bhopal',        '2023-10-28');

-- 50 customers: 10 first names x 5 last names = 50 different people
INSERT INTO Customer (Customer_ID, Customer_Name, Email, Phone, City, Registration_Date)
SELECT X.n,
       CONCAT(X.First_Name, ' ', X.Last_Name),
       CONCAT(LOWER(X.First_Name), '.', LOWER(X.Last_Name), '@example.com'),
       CONCAT('9', LPAD(10000000 + X.n * 12345, 9, '0')),
       ELT(1 + MOD(X.n, 10), 'Chennai','Mumbai','Delhi','Bengaluru','Hyderabad',
                             'Pune','Kolkata','Kochi','Jaipur','Ahmedabad'),
       DATE_ADD('2023-01-01', INTERVAL X.n * 13 DAY)
FROM (
    SELECT n,
           ELT(1 + MOD(n - 1, 10), 'Arun','Priya','Karan','Sneha','Rahul',
                                   'Meena','Vikram','Divya','Anil','Kavya') AS First_Name,
           ELT(1 + ((n - 1) DIV 10), 'Kumar','Sharma','Reddy','Iyer','Nair')  AS Last_Name
    FROM Numbers
    WHERE n <= 50
) X;

-- 100 products (loaded through a staging table, then given a seller)
INSERT INTO Stg_Products (Product_ID, Product_Name, Category_ID, Price) VALUES
 (1, 'Samsung Galaxy S23 128GB', 1, 74999.00),
 (2, 'Apple iPhone 14 128GB', 1, 69900.00),
 (3, 'OnePlus 11 5G', 1, 56999.00),
 (4, 'Redmi Note 12 Pro', 1, 24999.00),
 (5, 'Realme 11 Pro', 1, 23999.00),
 (6, 'Vivo V27 5G', 1, 32999.00),
 (7, 'Google Pixel 7a', 1, 43999.00),
 (8, 'Nothing Phone 2', 1, 44999.00),
 (9, 'Motorola Edge 40', 1, 29999.00),
 (10, 'iQOO Neo 7', 1, 29999.00),
 (11, 'Dell Inspiron 15 3520', 2, 52990.00),
 (12, 'HP Pavilion 14', 2, 61990.00),
 (13, 'Lenovo IdeaPad Slim 3', 2, 44990.00),
 (14, 'Apple MacBook Air M2', 2, 104900.00),
 (15, 'ASUS VivoBook 15', 2, 41990.00),
 (16, 'Acer Aspire 5', 2, 47990.00),
 (17, 'MSI Modern 14', 2, 39990.00),
 (18, 'Lenovo ThinkPad E14', 2, 68990.00),
 (19, 'HP Victus Gaming 15', 2, 75990.00),
 (20, 'Samsung Galaxy Book3', 2, 59990.00),
 (21, 'Sony WH-1000XM5 Headphones', 3, 29990.00),
 (22, 'boAt Rockerz 450', 3, 1499.00),
 (23, 'JBL Tune 760NC', 3, 6999.00),
 (24, 'Apple AirPods Pro 2', 3, 24900.00),
 (25, 'Sennheiser HD 450BT', 3, 8990.00),
 (26, 'Bose QuietComfort 45', 3, 27900.00),
 (27, 'Noise Buds VS104', 3, 1299.00),
 (28, 'Marshall Emberton II Speaker', 3, 14999.00),
 (29, 'JBL Flip 6 Speaker', 3, 9999.00),
 (30, 'boAt Stone 1200 Speaker', 3, 3499.00),
 (31, 'Sony Bravia 43 inch 4K TV', 4, 54990.00),
 (32, 'Samsung 55 inch Crystal 4K TV', 4, 47990.00),
 (33, 'LG 50 inch UHD TV', 4, 41990.00),
 (34, 'Mi 43 inch 4K TV', 4, 28999.00),
 (35, 'OnePlus Y1S Pro 50 inch TV', 4, 31999.00),
 (36, 'TCL 55 inch QLED TV', 4, 37990.00),
 (37, 'Panasonic 43 inch Full HD TV', 4, 27990.00),
 (38, 'Vu 55 inch GloLED TV', 4, 39990.00),
 (39, 'Hisense 65 inch 4K TV', 4, 59990.00),
 (40, 'Acer 43 inch I Series TV', 4, 25999.00),
 (41, 'LG 7 kg Front Load Washing Machine', 5, 33990.00),
 (42, 'Samsung 253L Double Door Refrigerator', 5, 27990.00),
 (43, 'Whirlpool 1.5 Ton Split AC', 5, 38990.00),
 (44, 'Voltas 1.5 Ton Window AC', 5, 31990.00),
 (45, 'Bosch 8 kg Washing Machine', 5, 41990.00),
 (46, 'Haier 240L Refrigerator', 5, 24990.00),
 (47, 'Daikin 1 Ton Inverter AC', 5, 36990.00),
 (48, 'IFB 6.5 kg Top Load Washer', 5, 22990.00),
 (49, 'Godrej 185L Refrigerator', 5, 15990.00),
 (50, 'Panasonic 1.5 Ton Inverter AC', 5, 40990.00),
 (51, 'Apple Watch SE', 6, 29900.00),
 (52, 'Samsung Galaxy Watch5', 6, 27999.00),
 (53, 'Noise ColorFit Pro 4', 6, 3499.00),
 (54, 'boAt Wave Call', 6, 1799.00),
 (55, 'Fire-Boltt Ninja Call Pro', 6, 1499.00),
 (56, 'Amazfit GTS 4 Mini', 6, 7999.00),
 (57, 'Garmin Venu Sq 2', 6, 24990.00),
 (58, 'Fitbit Charge 5', 6, 14999.00),
 (59, 'Xiaomi Smart Band 8', 6, 3999.00),
 (60, 'OnePlus Nord Watch', 6, 4999.00),
 (61, 'Canon EOS 1500D DSLR', 7, 38995.00),
 (62, 'Nikon D3500 DSLR', 7, 34995.00),
 (63, 'Sony Alpha ZV-E10', 7, 61990.00),
 (64, 'GoPro HERO11 Black', 7, 39990.00),
 (65, 'Canon EOS R50', 7, 67995.00),
 (66, 'Fujifilm Instax Mini 12', 7, 7999.00),
 (67, 'Sony Cyber-shot HX400V', 7, 28990.00),
 (68, 'DJI Osmo Action 3', 7, 29990.00),
 (69, 'Insta360 X3', 7, 39990.00),
 (70, 'Panasonic Lumix G7', 7, 44990.00),
 (71, 'Sony PlayStation 5 Console', 8, 49990.00),
 (72, 'Xbox Series S', 8, 34990.00),
 (73, 'Nintendo Switch OLED', 8, 32999.00),
 (74, 'Sony DualSense Controller', 8, 5999.00),
 (75, 'Logitech G102 Gaming Mouse', 8, 1295.00),
 (76, 'Razer Kraken X Headset', 8, 3999.00),
 (77, 'HyperX Cloud Stinger Headset', 8, 4499.00),
 (78, 'Redragon K552 Keyboard', 8, 2799.00),
 (79, 'Xbox Wireless Controller', 8, 4999.00),
 (80, 'ASUS ROG Ally', 8, 69990.00),
 (81, 'Logitech MX Master 3S Mouse', 9, 9995.00),
 (82, 'Dell KB216 Keyboard', 9, 899.00),
 (83, 'HP 24 inch Full HD Monitor', 9, 9499.00),
 (84, 'Samsung 27 inch Curved Monitor', 9, 15999.00),
 (85, 'SanDisk 1TB Portable SSD', 9, 7999.00),
 (86, 'Seagate 2TB External HDD', 9, 5499.00),
 (87, 'TP-Link Archer AX23 Router', 9, 3999.00),
 (88, 'Anker 65W GaN Charger', 9, 3999.00),
 (89, 'Logitech C920 Webcam', 9, 6495.00),
 (90, 'Epson EcoTank L3250 Printer', 9, 14999.00),
 (91, 'Philips Air Fryer HD9200', 10, 7999.00),
 (92, 'Prestige Induction Cooktop', 10, 2499.00),
 (93, 'Bajaj Mixer Grinder 750W', 10, 3199.00),
 (94, 'Morphy Richards OTG 28L', 10, 7490.00),
 (95, 'Havells Instanio Water Heater', 10, 8490.00),
 (96, 'Pigeon Electric Kettle 1.5L', 10, 699.00),
 (97, 'Butterfly 3 Burner Gas Stove', 10, 5999.00),
 (98, 'Kent Grand RO Water Purifier', 10, 18500.00),
 (99, 'Philips Mixer Grinder 750W', 10, 4299.00),
 (100, 'Borosil Microwave Oven 25L', 10, 8990.00);

INSERT INTO Product (Product_ID, Product_Name, Category_ID, Seller_ID, Price)
SELECT Product_ID, Product_Name, Category_ID, 1 + MOD(Product_ID * 7, 20), Price
FROM Stg_Products;

-- Stock between 0 and 149 units, reorder level 20 for every product
INSERT INTO Inventory (Product_ID, Stock_Quantity, Reorder_Level, Last_Restocked)
SELECT Product_ID,
       MOD(Product_ID * 37, 150),
       20,
       DATE_ADD('2025-01-15', INTERVAL MOD(Product_ID * 5, 90) DAY)
FROM Product;

-- 100 orders. Customers 1..8 are repeat buyers. Every order has line 1;
-- even orders also have line 2; every fifth order has line 3.
-- The three products inside one order are always different.
INSERT INTO Stg_Lines (Order_ID, Customer_ID, Order_Date, Product_ID, Quantity, Price)
SELECT N.n,
       CASE WHEN N.n <= 70 THEN 1 + MOD(N.n * 7, 50) ELSE 1 + MOD(N.n, 8) END,
       DATE_ADD('2025-01-01', INTERVAL N.n * 3 DAY),
       P.Product_ID,
       1 + MOD(N.n, 3),
       P.Price
FROM Numbers N
JOIN Product P ON P.Product_ID = 1 + MOD(N.n * 13, 100)
WHERE N.n <= 100;

INSERT INTO Stg_Lines (Order_ID, Customer_ID, Order_Date, Product_ID, Quantity, Price)
SELECT N.n,
       CASE WHEN N.n <= 70 THEN 1 + MOD(N.n * 7, 50) ELSE 1 + MOD(N.n, 8) END,
       DATE_ADD('2025-01-01', INTERVAL N.n * 3 DAY),
       P.Product_ID,
       1 + MOD(N.n + 1, 2),
       P.Price
FROM Numbers N
JOIN Product P ON P.Product_ID = 1 + MOD(N.n * 13 + 37, 100)
WHERE N.n <= 100 AND MOD(N.n, 2) = 0;

INSERT INTO Stg_Lines (Order_ID, Customer_ID, Order_Date, Product_ID, Quantity, Price)
SELECT N.n,
       CASE WHEN N.n <= 70 THEN 1 + MOD(N.n * 7, 50) ELSE 1 + MOD(N.n, 8) END,
       DATE_ADD('2025-01-01', INTERVAL N.n * 3 DAY),
       P.Product_ID,
       1,
       P.Price
FROM Numbers N
JOIN Product P ON P.Product_ID = 1 + MOD(N.n * 13 + 71, 100)
WHERE N.n <= 100 AND MOD(N.n, 5) = 0;

-- Order totals are calculated from the lines, so they always match
INSERT INTO Orders (Order_ID, Customer_ID, Order_Date, Total_Amount, Order_Status)
SELECT Order_ID, Customer_ID, Order_Date, SUM(Quantity * Price),
       CASE WHEN MOD(Order_ID, 15) = 0 THEN 'Cancelled'
            WHEN MOD(Order_ID, 12) = 0 THEN 'Pending'
            ELSE 'Completed' END
FROM Stg_Lines
GROUP BY Order_ID, Customer_ID, Order_Date;

INSERT INTO Order_Details (Order_ID, Product_ID, Quantity, Price)
SELECT Order_ID, Product_ID, Quantity, Price
FROM Stg_Lines
ORDER BY Order_ID, Product_ID;

-- 100 payments, one per order. Status follows the order.
INSERT INTO Payment (Payment_ID, Order_ID, Payment_Method, Amount, Payment_Status, Payment_Date)
SELECT Order_ID,
       Order_ID,
       ELT(1 + MOD(Order_ID, 4), 'UPI','Credit Card','Debit Card','Net Banking'),
       Total_Amount,
       CASE Order_Status WHEN 'Completed' THEN 'Success'
                         WHEN 'Cancelled' THEN 'Failed'
                         ELSE 'Pending' END,
       Order_Date
FROM Orders;

-- 50 reviews, always from a customer who really bought the product
INSERT INTO Review (Product_ID, Customer_ID, Rating, Review_Text, Review_Date)
SELECT R.Product_ID,
       R.Customer_ID,
       R.Rating,
       ELT(R.Rating, 'Poor quality, stopped working within weeks.',
                     'Not satisfied, quality could be better.',
                     'Average product, okay for the price.',
                     'Good product, works as described.',
                     'Excellent quality, totally worth the price.'),
       R.Review_Date
FROM (
    SELECT OD.Product_ID,
           O.Customer_ID,
           CAST(ELT(1 + MOD(MIN(OD.Order_Detail_ID), 10), 5,4,5,3,4,5,2,4,5,1) AS UNSIGNED) AS Rating,
           DATE_ADD(MIN(O.Order_Date), INTERVAL 7 DAY) AS Review_Date
    FROM Order_Details OD
    JOIN Orders O ON O.Order_ID = OD.Order_ID
    WHERE O.Order_Status = 'Completed'
    GROUP BY OD.Product_ID, O.Customer_ID
    ORDER BY MIN(OD.Order_Detail_ID)
    LIMIT 50
) R;

-- ---------- Data requirement check (every row must say PASS) ----------
SELECT 'Customer' AS Table_Name, COUNT(*) AS Records, 50 AS Minimum_Required,
       IF(COUNT(*) >= 50, 'PASS', 'FAIL') AS Result FROM Customer
UNION ALL SELECT 'Product',  COUNT(*), 100, IF(COUNT(*) >= 100, 'PASS', 'FAIL') FROM Product
UNION ALL SELECT 'Seller',   COUNT(*), 20,  IF(COUNT(*) >= 20,  'PASS', 'FAIL') FROM Seller
UNION ALL SELECT 'Orders',   COUNT(*), 100, IF(COUNT(*) >= 100, 'PASS', 'FAIL') FROM Orders
UNION ALL SELECT 'Payment',  COUNT(*), 100, IF(COUNT(*) >= 100, 'PASS', 'FAIL') FROM Payment
UNION ALL SELECT 'Review',   COUNT(*), 50,  IF(COUNT(*) >= 50,  'PASS', 'FAIL') FROM Review;

-- ---------- Data quality check: no duplicates, valid relationships ----------
-- Every row must say PASS
SELECT 'No duplicate customer e-mails' AS Quality_Check,
       IF(COUNT(*) = COUNT(DISTINCT LOWER(Email)), 'PASS', 'FAIL') AS Result
FROM Customer
UNION ALL
SELECT 'No duplicate product names',
       IF(COUNT(*) = COUNT(DISTINCT Product_Name), 'PASS', 'FAIL')
FROM Product
UNION ALL
SELECT 'Exactly one payment per order',
       IF((SELECT COUNT(*) FROM Orders) = (SELECT COUNT(DISTINCT Order_ID) FROM Payment), 'PASS', 'FAIL')
UNION ALL
SELECT 'Every order has at least one line',
       IF((SELECT COUNT(*) FROM Orders O WHERE NOT EXISTS
            (SELECT 1 FROM Order_Details OD WHERE OD.Order_ID = O.Order_ID)) = 0, 'PASS', 'FAIL')
UNION ALL
SELECT 'Order totals equal the sum of their lines',
       IF((SELECT COUNT(*) FROM Orders O
           WHERE O.Total_Amount <> (SELECT SUM(OD.Quantity * OD.Price)
                                    FROM Order_Details OD WHERE OD.Order_ID = O.Order_ID)) = 0, 'PASS', 'FAIL')
UNION ALL
SELECT 'Payment status matches order status',
       IF((SELECT COUNT(*) FROM Orders O JOIN Payment P ON P.Order_ID = O.Order_ID
           WHERE (O.Order_Status = 'Completed' AND P.Payment_Status <> 'Success')
              OR (O.Order_Status = 'Cancelled' AND P.Payment_Status <> 'Failed')
              OR (O.Order_Status = 'Pending'   AND P.Payment_Status <> 'Pending')) = 0, 'PASS', 'FAIL')
UNION ALL
SELECT 'Every review comes from a verified buyer',
       IF((SELECT COUNT(*) FROM Review RV WHERE NOT EXISTS
            (SELECT 1 FROM Orders O JOIN Order_Details OD ON OD.Order_ID = O.Order_ID
             WHERE O.Customer_ID = RV.Customer_ID AND OD.Product_ID = RV.Product_ID
               AND O.Order_Status = 'Completed')) = 0, 'PASS', 'FAIL')
UNION ALL
SELECT 'Stock is never negative',
       IF((SELECT COUNT(*) FROM Inventory WHERE Stock_Quantity < 0) = 0, 'PASS', 'FAIL');

-- ============================================================
-- TASK 4: SQL QUERIES
-- ============================================================

-- ---------------- BASIC QUERIES ----------------

-- SELECT
SELECT Customer_ID, Customer_Name, City FROM Customer LIMIT 10;

-- WHERE

SELECT Product_ID, Product_Name, Price
FROM Product
WHERE Price > 50000
ORDER BY Price DESC;
-- ORDER BY
SELECT Product_Name, Price
FROM Product
ORDER BY Price DESC, Product_Name
LIMIT 10;

-- DISTINCT
SELECT DISTINCT City FROM Customer ORDER BY City;

-- LIKE
SELECT Product_ID, Product_Name, Price
FROM Product
WHERE Product_Name LIKE '%Samsung%' OR Product_Name LIKE 'Sony%'
ORDER BY Product_Name;

-- BETWEEN (price range and date range)
SELECT Product_Name, Price
FROM Product
WHERE Price BETWEEN 10000 AND 30000
ORDER BY Price;

SELECT Order_ID, Customer_ID, Order_Date, Total_Amount
FROM Orders
WHERE Order_Date BETWEEN '2025-03-01' AND '2025-03-31'
ORDER BY Order_Date;

-- ---------------- INTERMEDIATE QUERIES ----------------

-- INNER JOIN: customer orders
SELECT C.Customer_Name, O.Order_ID, O.Order_Date, O.Total_Amount, O.Order_Status
FROM Customer C
JOIN Orders O ON O.Customer_ID = C.Customer_ID
ORDER BY O.Order_Date, O.Order_ID
LIMIT 20;

-- Multi-table join: what was bought, from which category and seller
SELECT O.Order_ID, C.Customer_Name, P.Product_Name, Cat.Category_Name,
       S.Seller_Name, OD.Quantity, OD.Price,
       (OD.Quantity * OD.Price) AS Line_Total
FROM Orders O
JOIN Customer C       ON C.Customer_ID  = O.Customer_ID
JOIN Order_Details OD ON OD.Order_ID    = O.Order_ID
JOIN Product P        ON P.Product_ID   = OD.Product_ID
JOIN Category Cat     ON Cat.Category_ID = P.Category_ID
JOIN Seller S         ON S.Seller_ID    = P.Seller_ID
ORDER BY O.Order_ID, P.Product_Name
LIMIT 20;

-- LEFT JOIN: products that have no reviews yet
SELECT P.Product_ID, P.Product_Name
FROM Product P
LEFT JOIN Review R ON R.Product_ID = P.Product_ID
WHERE R.Review_ID IS NULL
ORDER BY P.Product_ID
LIMIT 15;

-- Aggregate functions: COUNT, SUM, AVG, MIN, MAX
SELECT COUNT(*)                    AS Completed_Orders,
       SUM(Total_Amount)           AS Total_Revenue,
       ROUND(AVG(Total_Amount), 2) AS Avg_Order_Value,
       MIN(Total_Amount)           AS Smallest_Order,
       MAX(Total_Amount)           AS Largest_Order
FROM Orders
WHERE Order_Status = 'Completed';

-- GROUP BY: revenue per category
SELECT Cat.Category_Name,
       SUM(OD.Quantity)            AS Units_Sold,
       SUM(OD.Quantity * OD.Price) AS Revenue
FROM Order_Details OD
JOIN Orders O     ON O.Order_ID = OD.Order_ID AND O.Order_Status = 'Completed'
JOIN Product P    ON P.Product_ID = OD.Product_ID
JOIN Category Cat ON Cat.Category_ID = P.Category_ID
GROUP BY Cat.Category_ID, Cat.Category_Name
ORDER BY Revenue DESC;

-- GROUP BY + HAVING: customers with 3 or more completed orders
SELECT C.Customer_Name,
       COUNT(O.Order_ID)   AS Completed_Orders,
       SUM(O.Total_Amount) AS Total_Spent
FROM Customer C
JOIN Orders O ON O.Customer_ID = C.Customer_ID
WHERE O.Order_Status = 'Completed'
GROUP BY C.Customer_ID, C.Customer_Name
HAVING COUNT(O.Order_ID) >= 3
ORDER BY Total_Spent DESC;

-- GROUP BY + HAVING: sellers with more than 300,000 revenue
SELECT S.Seller_Name,
       COUNT(DISTINCT P.Product_ID) AS Products_Sold,
       SUM(OD.Quantity * OD.Price)  AS Revenue
FROM Seller S
JOIN Product P        ON P.Seller_ID  = S.Seller_ID
JOIN Order_Details OD ON OD.Product_ID = P.Product_ID
JOIN Orders O         ON O.Order_ID   = OD.Order_ID AND O.Order_Status = 'Completed'
GROUP BY S.Seller_ID, S.Seller_Name
HAVING SUM(OD.Quantity * OD.Price) > 300000
ORDER BY Revenue DESC;

-- ---------------- ADVANCED QUERIES ----------------

-- Subquery: products priced above the average price
SELECT Product_Name, Price
FROM Product
WHERE Price > (SELECT AVG(Price) FROM Product)
ORDER BY Price DESC
LIMIT 10;

-- Nested subquery: customers who bought from the Smartphones category
SELECT C.Customer_Name
FROM Customer C
WHERE C.Customer_ID IN (
    SELECT O.Customer_ID
    FROM Orders O
    JOIN Order_Details OD ON OD.Order_ID = O.Order_ID
    JOIN Product P        ON P.Product_ID = OD.Product_ID
    WHERE P.Category_ID = (SELECT Category_ID FROM Category WHERE Category_Name = 'Smartphones')
)
ORDER BY C.Customer_Name;

-- Nested subquery in HAVING: customers who spent more than the average customer
SELECT C.Customer_Name, SUM(O.Total_Amount) AS Total_Spent
FROM Customer C
JOIN Orders O ON O.Customer_ID = C.Customer_ID
WHERE O.Order_Status = 'Completed'
GROUP BY C.Customer_ID, C.Customer_Name
HAVING SUM(O.Total_Amount) > (
    SELECT AVG(T.Customer_Total)
    FROM (SELECT SUM(Total_Amount) AS Customer_Total
          FROM Orders
          WHERE Order_Status = 'Completed'
          GROUP BY Customer_ID) T
)
ORDER BY Total_Spent DESC;

-- Correlated subquery: products priced above the average of their own category
SELECT P.Product_Name, Cat.Category_Name, P.Price
FROM Product P
JOIN Category Cat ON Cat.Category_ID = P.Category_ID
WHERE P.Price > (SELECT AVG(P2.Price) FROM Product P2 WHERE P2.Category_ID = P.Category_ID)
ORDER BY Cat.Category_Name, P.Price DESC;

-- EXISTS: customers who have at least one cancelled order
SELECT C.Customer_Name
FROM Customer C
WHERE EXISTS (SELECT 1 FROM Orders O
              WHERE O.Customer_ID = C.Customer_ID AND O.Order_Status = 'Cancelled')
ORDER BY C.Customer_Name;

-- Window functions: RANK and DENSE_RANK of products by revenue
SELECT P.Product_Name,
       SUM(OD.Quantity * OD.Price) AS Revenue,
       RANK()       OVER (ORDER BY SUM(OD.Quantity * OD.Price) DESC) AS Revenue_Rank,
       DENSE_RANK() OVER (ORDER BY SUM(OD.Quantity * OD.Price) DESC) AS Dense_Revenue_Rank
FROM Order_Details OD
JOIN Orders O  ON O.Order_ID = OD.Order_ID AND O.Order_Status = 'Completed'
JOIN Product P ON P.Product_ID = OD.Product_ID
GROUP BY P.Product_ID, P.Product_Name
ORDER BY Revenue_Rank
LIMIT 10;

-- Ranking query: top 5 customers by spending
SELECT R.Customer_Name, R.Total_Spent, R.Spending_Rank
FROM (
    SELECT C.Customer_Name,
           SUM(O.Total_Amount) AS Total_Spent,
           RANK() OVER (ORDER BY SUM(O.Total_Amount) DESC) AS Spending_Rank
    FROM Customer C
    JOIN Orders O ON O.Customer_ID = C.Customer_ID
    WHERE O.Order_Status = 'Completed'
    GROUP BY C.Customer_ID, C.Customer_Name
) R
WHERE R.Spending_Rank <= 5
ORDER BY R.Spending_Rank;

-- Ranking query: top 3 products inside every category (ROW_NUMBER + PARTITION BY)
SELECT T.Category_Name, T.Product_Name, T.Revenue, T.Category_Rank
FROM (
    SELECT Cat.Category_Name,
           P.Product_Name,
           SUM(OD.Quantity * OD.Price) AS Revenue,
           ROW_NUMBER() OVER (PARTITION BY Cat.Category_Name
                              ORDER BY SUM(OD.Quantity * OD.Price) DESC) AS Category_Rank
    FROM Order_Details OD
    JOIN Orders O     ON O.Order_ID = OD.Order_ID AND O.Order_Status = 'Completed'
    JOIN Product P    ON P.Product_ID = OD.Product_ID
    JOIN Category Cat ON Cat.Category_ID = P.Category_ID
    GROUP BY Cat.Category_ID, Cat.Category_Name, P.Product_ID, P.Product_Name
) T
WHERE T.Category_Rank <= 3
ORDER BY T.Category_Name, T.Category_Rank;

-- Window functions: running total and month-over-month growth
SELECT M.Sales_Month,
       M.Revenue,
       SUM(M.Revenue) OVER (ORDER BY M.Sales_Month) AS Running_Revenue,
       ROUND((M.Revenue - LAG(M.Revenue) OVER (ORDER BY M.Sales_Month))
             / LAG(M.Revenue) OVER (ORDER BY M.Sales_Month) * 100, 1) AS Growth_Percent
FROM (
    SELECT DATE_FORMAT(Order_Date, '%Y-%m') AS Sales_Month,
           SUM(Total_Amount)                AS Revenue
    FROM Orders
    WHERE Order_Status = 'Completed'
    GROUP BY DATE_FORMAT(Order_Date, '%Y-%m')
) M
ORDER BY M.Sales_Month;

-- Window function: latest order of every customer (ROW_NUMBER)
SELECT L.Customer_Name, L.Order_ID, L.Order_Date, L.Total_Amount
FROM (
    SELECT C.Customer_Name, O.Order_ID, O.Order_Date, O.Total_Amount,
           ROW_NUMBER() OVER (PARTITION BY O.Customer_ID
                              ORDER BY O.Order_Date DESC, O.Order_ID DESC) AS Order_Sequence
    FROM Orders O
    JOIN Customer C ON C.Customer_ID = O.Customer_ID
) L
WHERE L.Order_Sequence = 1
ORDER BY L.Order_Date DESC
LIMIT 10;

-- ============================================================
-- TASK 5: DATABASE OBJECTS
-- ============================================================

-- ---------------- VIEWS ----------------

-- Customer order history
CREATE OR REPLACE VIEW v_customer_order_history AS
SELECT C.Customer_ID,
       C.Customer_Name,
       O.Order_ID,
       O.Order_Date,
       O.Total_Amount,
       O.Order_Status,
       P.Payment_Method,
       P.Payment_Status
FROM Customer C
JOIN Orders O       ON O.Customer_ID = C.Customer_ID
LEFT JOIN Payment P ON P.Order_ID    = O.Order_ID;

-- Sales report (one row per month, completed orders)
CREATE OR REPLACE VIEW v_sales_report AS
SELECT DATE_FORMAT(Order_Date, '%Y-%m') AS Sales_Month,
       COUNT(*)                         AS Total_Orders,
       SUM(Total_Amount)                AS Revenue,
       ROUND(AVG(Total_Amount), 2)      AS Avg_Order_Value
FROM Orders
WHERE Order_Status = 'Completed'
GROUP BY DATE_FORMAT(Order_Date, '%Y-%m');

-- Product performance (sales, rating and stock of every product)
CREATE OR REPLACE VIEW v_product_performance AS
SELECT P.Product_ID,
       P.Product_Name,
       Cat.Category_Name,
       S.Seller_Name,
       P.Price,
       COALESCE(SA.Units_Sold, 0)    AS Units_Sold,
       COALESCE(SA.Revenue, 0)       AS Revenue,
       COALESCE(RV.Avg_Rating, 0)    AS Avg_Rating,
       COALESCE(RV.Review_Count, 0)  AS Review_Count,
       I.Stock_Quantity,
       I.Reorder_Level
FROM Product P
JOIN Category Cat ON Cat.Category_ID = P.Category_ID
JOIN Seller S     ON S.Seller_ID     = P.Seller_ID
JOIN Inventory I  ON I.Product_ID    = P.Product_ID
LEFT JOIN (
    SELECT OD.Product_ID,
           SUM(OD.Quantity)            AS Units_Sold,
           SUM(OD.Quantity * OD.Price) AS Revenue
    FROM Order_Details OD
    JOIN Orders O ON O.Order_ID = OD.Order_ID
    WHERE O.Order_Status = 'Completed'
    GROUP BY OD.Product_ID
) SA ON SA.Product_ID = P.Product_ID
LEFT JOIN (
    SELECT Product_ID, ROUND(AVG(Rating), 2) AS Avg_Rating, COUNT(*) AS Review_Count
    FROM Review
    GROUP BY Product_ID
) RV ON RV.Product_ID = P.Product_ID;

-- Customer segments (used by the Customer Intelligence report)
--   Premium   : 4 or more orders AND spending of 250,000 or more
--   Regular   : 2 or more orders
--   Low Value : exactly 1 order
--   Inactive  : no completed order
CREATE OR REPLACE VIEW v_customer_segments AS
SELECT C.Customer_ID,
       C.Customer_Name,
       C.City,
       COALESCE(V.Total_Orders, 0)       AS Total_Orders,
       COALESCE(V.Total_Spending, 0)     AS Total_Spending,
       COALESCE(V.Purchase_Frequency, 0) AS Purchase_Frequency,
       V.Last_Order_Date,
       CASE
           WHEN COALESCE(V.Total_Orders, 0) >= 4
            AND COALESCE(V.Total_Spending, 0) >= 250000 THEN 'Premium'
           WHEN COALESCE(V.Total_Orders, 0) >= 2        THEN 'Regular'
           WHEN COALESCE(V.Total_Orders, 0) >= 1        THEN 'Low Value'
           ELSE 'Inactive'
       END AS Segment
FROM Customer C
LEFT JOIN (
    SELECT Customer_ID,
           COUNT(*)         AS Total_Orders,
           SUM(Total_Amount) AS Total_Spending,
           MAX(Order_Date)  AS Last_Order_Date,
           -- orders per month between the first and the last order
           ROUND(COUNT(*) / (TIMESTAMPDIFF(MONTH, MIN(Order_Date), MAX(Order_Date)) + 1), 2) AS Purchase_Frequency
    FROM Orders
    WHERE Order_Status = 'Completed'
    GROUP BY Customer_ID
) V ON V.Customer_ID = C.Customer_ID;

-- ---------------- FUNCTIONS ----------------
DELIMITER $$

CREATE FUNCTION fn_customer_total_spending(p_customer_id INT)
RETURNS DECIMAL(12,2)
READS SQL DATA
BEGIN
    DECLARE v_total DECIMAL(12,2) DEFAULT 0;

    SELECT COALESCE(SUM(Total_Amount), 0) INTO v_total
    FROM Orders
    WHERE Customer_ID = p_customer_id
      AND Order_Status = 'Completed';

    RETURN v_total;
END$$

CREATE FUNCTION fn_product_revenue(p_product_id INT)
RETURNS DECIMAL(14,2)
READS SQL DATA
BEGIN
    DECLARE v_revenue DECIMAL(14,2) DEFAULT 0;

    SELECT COALESCE(SUM(OD.Quantity * OD.Price), 0) INTO v_revenue
    FROM Order_Details OD
    JOIN Orders O ON O.Order_ID = OD.Order_ID
    WHERE OD.Product_ID = p_product_id
      AND O.Order_Status = 'Completed';

    RETURN v_revenue;
END$$

-- ---------------- STORED PROCEDURES ----------------

-- Order placement: checks stock, creates order + line + payment in ONE transaction.
-- The triggers below reduce the stock and mark the order Completed.
CREATE PROCEDURE sp_place_order(
    IN  p_customer_id INT,
    IN  p_product_id  INT,
    IN  p_quantity    INT,
    IN  p_method      VARCHAR(20),
    OUT p_order_id    INT,
    OUT p_message     VARCHAR(150)
)
proc_main: BEGIN
    DECLARE v_found INT DEFAULT 0;
    DECLARE v_stock INT DEFAULT 0;
    DECLARE v_price DECIMAL(10,2) DEFAULT 0;
    DECLARE v_total DECIMAL(12,2) DEFAULT 0;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_order_id = 0;
        SET p_message = 'ROLLBACK: SQL error, order not placed';
    END;

    SET p_order_id = 0;

    SELECT COUNT(*) INTO v_found FROM Customer WHERE Customer_ID = p_customer_id;
    IF v_found = 0 THEN
        SET p_message = 'REJECTED: unknown customer';
        LEAVE proc_main;
    END IF;

    SELECT COUNT(*) INTO v_found FROM Product WHERE Product_ID = p_product_id;
    IF v_found = 0 THEN
        SET p_message = 'REJECTED: unknown product';
        LEAVE proc_main;
    END IF;

    IF p_quantity IS NULL OR p_quantity <= 0 THEN
        SET p_message = 'REJECTED: quantity must be greater than zero';
        LEAVE proc_main;
    END IF;

    START TRANSACTION;

    SELECT I.Stock_Quantity, P.Price INTO v_stock, v_price
    FROM Inventory I
    JOIN Product P ON P.Product_ID = I.Product_ID
    WHERE I.Product_ID = p_product_id
    FOR UPDATE;

    IF v_stock < p_quantity THEN
        ROLLBACK;
        SET p_message = CONCAT('REJECTED: not enough stock (available ', v_stock, ')');
        LEAVE proc_main;
    END IF;

    SET v_total = v_price * p_quantity;

    INSERT INTO Orders (Customer_ID, Order_Date, Total_Amount, Order_Status)
    VALUES (p_customer_id, CURDATE(), v_total, 'Pending');
    SET p_order_id = LAST_INSERT_ID();

    -- trigger trg_order_details_after_insert reduces the stock
    INSERT INTO Order_Details (Order_ID, Product_ID, Quantity, Price)
    VALUES (p_order_id, p_product_id, p_quantity, v_price);

    -- trigger trg_payment_after_insert marks the order Completed
    INSERT INTO Payment (Order_ID, Payment_Method, Amount, Payment_Status, Payment_Date)
    VALUES (p_order_id, p_method, v_total, 'Success', CURDATE());

    COMMIT;
    SET p_message = CONCAT('COMMIT: order ', p_order_id, ' completed');
END$$

-- Stock update: add stock (positive number) or remove stock (negative number)
CREATE PROCEDURE sp_update_stock(
    IN  p_product_id INT,
    IN  p_change     INT,
    OUT p_message    VARCHAR(150)
)
proc_stock: BEGIN
    DECLARE v_found INT DEFAULT 0;
    DECLARE v_stock INT DEFAULT 0;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_message = 'ROLLBACK: SQL error, stock not changed';
    END;

    SELECT COUNT(*) INTO v_found FROM Inventory WHERE Product_ID = p_product_id;
    IF v_found = 0 THEN
        SET p_message = 'REJECTED: unknown product';
        LEAVE proc_stock;
    END IF;

    START TRANSACTION;

    SELECT Stock_Quantity INTO v_stock
    FROM Inventory
    WHERE Product_ID = p_product_id
    FOR UPDATE;

    IF v_stock + p_change < 0 THEN
        ROLLBACK;
        SET p_message = CONCAT('REJECTED: stock would become negative (current stock ', v_stock, ')');
        LEAVE proc_stock;
    END IF;

    UPDATE Inventory
    SET Stock_Quantity = Stock_Quantity + p_change,
        Last_Restocked = IF(p_change > 0, CURDATE(), Last_Restocked)
    WHERE Product_ID = p_product_id;

    COMMIT;
    SET p_message = CONCAT('OK: stock changed from ', v_stock, ' to ', v_stock + p_change);
END$$

-- Sales calculation for any date range
CREATE PROCEDURE sp_calculate_sales(IN p_start DATE, IN p_end DATE)
BEGIN
    SELECT p_start                          AS From_Date,
           p_end                            AS To_Date,
           COUNT(*)                         AS Completed_Orders,
           COALESCE(SUM(Total_Amount), 0)   AS Total_Revenue,
           COALESCE(ROUND(AVG(Total_Amount), 2), 0) AS Avg_Order_Value
    FROM Orders
    WHERE Order_Status = 'Completed'
      AND Order_Date BETWEEN p_start AND p_end;
END$$

-- ---------------- TRIGGERS ----------------
-- Created AFTER the sample data was loaded, so loading is not affected.

-- Audit record for every new order
CREATE TRIGGER trg_orders_after_insert
AFTER INSERT ON Orders
FOR EACH ROW
BEGIN
    INSERT INTO Audit_Log (Table_Name, Action_Type, Record_ID, Old_Value, New_Value, Changed_By)
    VALUES ('Orders', 'INSERT', NEW.Order_ID, NULL,
            CONCAT('Customer ', NEW.Customer_ID, ' | ', NEW.Order_Status, ' | ', NEW.Total_Amount),
            USER());
END$$

-- Reduce stock after an order line is placed
CREATE TRIGGER trg_order_details_after_insert
AFTER INSERT ON Order_Details
FOR EACH ROW
BEGIN
    UPDATE Inventory
    SET Stock_Quantity = Stock_Quantity - NEW.Quantity
    WHERE Product_ID = NEW.Product_ID;
END$$

-- Update the order status after payment (Success -> Completed, Failed -> Cancelled)
CREATE TRIGGER trg_payment_after_insert
AFTER INSERT ON Payment
FOR EACH ROW
BEGIN
    IF NEW.Payment_Status = 'Success' THEN
        UPDATE Orders SET Order_Status = 'Completed' WHERE Order_ID = NEW.Order_ID;
    ELSEIF NEW.Payment_Status = 'Failed' THEN
        UPDATE Orders SET Order_Status = 'Cancelled' WHERE Order_ID = NEW.Order_ID;
    END IF;

    INSERT INTO Audit_Log (Table_Name, Action_Type, Record_ID, Old_Value, New_Value, Changed_By)
    VALUES ('Payment', 'INSERT', NEW.Payment_ID, NULL,
            CONCAT('Order ', NEW.Order_ID, ' | ', NEW.Payment_Method, ' | ', NEW.Payment_Status),
            USER());
END$$

-- Audit every status change, and give the stock back when an order is cancelled
CREATE TRIGGER trg_orders_after_update
AFTER UPDATE ON Orders
FOR EACH ROW
BEGIN
    IF OLD.Order_Status <> NEW.Order_Status THEN
        INSERT INTO Audit_Log (Table_Name, Action_Type, Record_ID, Old_Value, New_Value, Changed_By)
        VALUES ('Orders', 'STATUS CHANGE', NEW.Order_ID, OLD.Order_Status, NEW.Order_Status, USER());

        IF NEW.Order_Status = 'Cancelled' THEN
            UPDATE Inventory I
            JOIN Order_Details OD ON OD.Product_ID = I.Product_ID
            SET I.Stock_Quantity = I.Stock_Quantity + OD.Quantity
            WHERE OD.Order_ID = NEW.Order_ID;
        END IF;
    END IF;
END$$

-- Audit record when an order is deleted
CREATE TRIGGER trg_orders_after_delete
AFTER DELETE ON Orders
FOR EACH ROW
BEGIN
    INSERT INTO Audit_Log (Table_Name, Action_Type, Record_ID, Old_Value, New_Value, Changed_By)
    VALUES ('Orders', 'DELETE', OLD.Order_ID,
            CONCAT('Customer ', OLD.Customer_ID, ' | ', OLD.Order_Status, ' | ', OLD.Total_Amount),
            NULL, USER());
END$$

DELIMITER ;

-- ============================================================
-- TASK 6: PERFORMANCE OPTIMIZATION
-- ============================================================

-- ---------- Indexes on the real tables ----------
-- Customer lookup by e-mail or phone is already indexed by the UNIQUE keys.
-- Product search
CREATE INDEX idx_product_name           ON Product(Product_Name);
CREATE INDEX idx_product_category_price ON Product(Category_ID, Price);
-- Customer lookup
CREATE INDEX idx_customer_name          ON Customer(Customer_Name);
CREATE INDEX idx_customer_city          ON Customer(City);
-- Order retrieval
CREATE INDEX idx_orders_customer_date   ON Orders(Customer_ID, Order_Date);
CREATE INDEX idx_orders_date_status     ON Orders(Order_Date, Order_Status);

-- All indexes of the project
SELECT TABLE_NAME, INDEX_NAME,
       GROUP_CONCAT(COLUMN_NAME ORDER BY SEQ_IN_INDEX) AS Indexed_Columns
FROM information_schema.STATISTICS
WHERE TABLE_SCHEMA = 'ecommerce_capstone_db'
  AND TABLE_NAME IN ('Category','Seller','Customer','Product','Inventory',
                     'Orders','Order_Details','Payment','Review')
GROUP BY TABLE_NAME, INDEX_NAME
ORDER BY TABLE_NAME, INDEX_NAME;

-- EXPLAIN on real queries (look at the key column to see which index is used)
EXPLAIN SELECT * FROM Product WHERE Product_Name = 'Sony WH-1000XM5 Headphones';
EXPLAIN SELECT * FROM Orders WHERE Customer_ID = 8 ORDER BY Order_Date DESC;
EXPLAIN SELECT C.Customer_Name, O.Order_ID, O.Total_Amount
        FROM Customer C JOIN Orders O ON O.Customer_ID = C.Customer_ID
        WHERE C.Email = 'arun.kumar@example.com';

-- ---------- Timing test on large copies of the tables ----------
-- The real tables are too small to show a time difference, so we test on
-- three large tables: 20,000 customers, 20,000 products, 100,000 orders.
CREATE TABLE Perf_Log (
    Log_ID      INT           AUTO_INCREMENT PRIMARY KEY,
    Query_Name  VARCHAR(60)   NOT NULL,
    Phase       VARCHAR(10)   NOT NULL,
    Runs        INT           NOT NULL,
    Avg_Time_ms DECIMAL(12,3) NOT NULL,
    Logged_At   TIMESTAMP     DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE Perf_Customers (
    Customer_ID   INT PRIMARY KEY,
    Customer_Name VARCHAR(100) NOT NULL,
    Email         VARCHAR(100) NOT NULL,
    City          VARCHAR(50)  NOT NULL
);

CREATE TABLE Perf_Products (
    Product_ID   INT PRIMARY KEY,
    Product_Name VARCHAR(100)  NOT NULL,
    Category_ID  INT           NOT NULL,
    Price        DECIMAL(10,2) NOT NULL
);

CREATE TABLE Perf_Orders (
    Order_ID     INT PRIMARY KEY,
    Customer_ID  INT           NOT NULL,
    Order_Date   DATE          NOT NULL,
    Total_Amount DECIMAL(12,2) NOT NULL
);

INSERT INTO Perf_Customers (Customer_ID, Customer_Name, Email, City)
SELECT n,
       CONCAT('Customer ', n),
       CONCAT('customer', n, '@example.com'),
       ELT(1 + MOD(n, 10), 'Chennai','Mumbai','Delhi','Bengaluru','Hyderabad',
                           'Pune','Kolkata','Kochi','Jaipur','Ahmedabad')
FROM Numbers
WHERE n <= 20000;

INSERT INTO Perf_Products (Product_ID, Product_Name, Category_ID, Price)
SELECT n, CONCAT('Product ', n), 1 + MOD(n, 20), 100 + MOD(n * 7919, 49900)
FROM Numbers
WHERE n <= 20000;

INSERT INTO Perf_Orders (Order_ID, Customer_ID, Order_Date, Total_Amount)
SELECT n,
       1 + MOD(n * 7, 20000),
       DATE_ADD('2024-01-01', INTERVAL MOD(n, 730) DAY),
       500 + MOD(n * 131, 60000)
FROM Numbers;

ANALYZE TABLE Perf_Customers, Perf_Products, Perf_Orders;

-- Benchmark helper: runs a statement p_runs times and stores the average
-- time in milliseconds in Perf_Log.
DELIMITER $$

CREATE PROCEDURE sp_bench(
    IN p_name  VARCHAR(60),
    IN p_phase VARCHAR(10),
    IN p_sql   TEXT,
    IN p_runs  INT
)
BEGIN
    DECLARE v_i     INT DEFAULT 0;
    DECLARE v_start DATETIME(6);

    SET @bench_sql = p_sql;
    PREPARE bench_stmt FROM @bench_sql;

    SET v_start = SYSDATE(6);
    WHILE v_i < p_runs DO
        EXECUTE bench_stmt;
        SET v_i = v_i + 1;
    END WHILE;

    INSERT INTO Perf_Log (Query_Name, Phase, Runs, Avg_Time_ms)
    VALUES (p_name, p_phase, p_runs,
            TIMESTAMPDIFF(MICROSECOND, v_start, SYSDATE(6)) / 1000 / p_runs);

    DEALLOCATE PREPARE bench_stmt;
END$$

DELIMITER ;

-- Execution plans BEFORE indexing (type = ALL and key = NULL means a full table scan)
EXPLAIN SELECT * FROM Perf_Customers WHERE Email = 'customer15000@example.com';
EXPLAIN SELECT * FROM Perf_Products  WHERE Product_Name = 'Product 15000';
EXPLAIN SELECT * FROM Perf_Products  WHERE Category_ID = 7;
EXPLAIN SELECT * FROM Perf_Orders    WHERE Customer_ID = 12345;
EXPLAIN SELECT * FROM Perf_Orders    WHERE Order_Date BETWEEN '2025-03-01' AND '2025-03-31';

-- Timing BEFORE indexing (each query runs 5 times, the average is stored)
CALL sp_bench('Customer lookup by e-mail', 'BEFORE',
  "SELECT COUNT(*) INTO @rows FROM (SELECT * FROM Perf_Customers WHERE Email = 'customer15000@example.com') AS q", 5);
CALL sp_bench('Product search by name', 'BEFORE',
  "SELECT COUNT(*) INTO @rows FROM (SELECT * FROM Perf_Products WHERE Product_Name = 'Product 15000') AS q", 5);
CALL sp_bench('Product search by category', 'BEFORE',
  "SELECT COUNT(*) INTO @rows FROM (SELECT * FROM Perf_Products WHERE Category_ID = 7) AS q", 5);
CALL sp_bench('Order retrieval by customer', 'BEFORE',
  "SELECT COUNT(*) INTO @rows FROM (SELECT * FROM Perf_Orders WHERE Customer_ID = 12345) AS q", 5);
CALL sp_bench('Orders in a date range', 'BEFORE',
  "SELECT COUNT(*) INTO @rows FROM (SELECT * FROM Perf_Orders WHERE Order_Date BETWEEN '2025-03-01' AND '2025-03-31') AS q", 5);

-- Create the indexes
CREATE INDEX idx_perf_customer_email ON Perf_Customers(Email);
CREATE INDEX idx_perf_product_name   ON Perf_Products(Product_Name);
CREATE INDEX idx_perf_product_cat    ON Perf_Products(Category_ID);
CREATE INDEX idx_perf_orders_cust    ON Perf_Orders(Customer_ID);
CREATE INDEX idx_perf_orders_date    ON Perf_Orders(Order_Date);

ANALYZE TABLE Perf_Customers, Perf_Products, Perf_Orders;

-- Execution plans AFTER indexing (type = ref or range and a key name)
EXPLAIN SELECT * FROM Perf_Customers WHERE Email = 'customer15000@example.com';
EXPLAIN SELECT * FROM Perf_Products  WHERE Product_Name = 'Product 15000';
EXPLAIN SELECT * FROM Perf_Products  WHERE Category_ID = 7;
EXPLAIN SELECT * FROM Perf_Orders    WHERE Customer_ID = 12345;
EXPLAIN SELECT * FROM Perf_Orders    WHERE Order_Date BETWEEN '2025-03-01' AND '2025-03-31';

-- Timing AFTER indexing
CALL sp_bench('Customer lookup by e-mail', 'AFTER',
  "SELECT COUNT(*) INTO @rows FROM (SELECT * FROM Perf_Customers WHERE Email = 'customer15000@example.com') AS q", 5);
CALL sp_bench('Product search by name', 'AFTER',
  "SELECT COUNT(*) INTO @rows FROM (SELECT * FROM Perf_Products WHERE Product_Name = 'Product 15000') AS q", 5);
CALL sp_bench('Product search by category', 'AFTER',
  "SELECT COUNT(*) INTO @rows FROM (SELECT * FROM Perf_Products WHERE Category_ID = 7) AS q", 5);
CALL sp_bench('Order retrieval by customer', 'AFTER',
  "SELECT COUNT(*) INTO @rows FROM (SELECT * FROM Perf_Orders WHERE Customer_ID = 12345) AS q", 5);
CALL sp_bench('Orders in a date range', 'AFTER',
  "SELECT COUNT(*) INTO @rows FROM (SELECT * FROM Perf_Orders WHERE Order_Date BETWEEN '2025-03-01' AND '2025-03-31') AS q", 5);

-- QUERY PERFORMANCE REPORT (times are measured on YOUR machine)
SELECT B.Query_Name,
       B.Avg_Time_ms                                                   AS Before_Index_ms,
       A.Avg_Time_ms                                                   AS After_Index_ms,
       ROUND(B.Avg_Time_ms / NULLIF(A.Avg_Time_ms, 0), 1)              AS Times_Faster,
       ROUND((B.Avg_Time_ms - A.Avg_Time_ms) / B.Avg_Time_ms * 100, 1) AS Improvement_Percent
FROM Perf_Log B
JOIN Perf_Log A ON A.Query_Name = B.Query_Name AND A.Phase = 'AFTER'
WHERE B.Phase = 'BEFORE'
ORDER BY B.Log_ID;

-- ============================================================
-- TASK 7: BUSINESS INTELLIGENCE REPORTS
-- ============================================================

-- ---------------- SALES INTELLIGENCE REPORT ----------------

-- Total revenue
SELECT SUM(Total_Amount)           AS Total_Revenue,
       COUNT(*)                    AS Completed_Orders,
       ROUND(AVG(Total_Amount), 2) AS Avg_Order_Value
FROM Orders
WHERE Order_Status = 'Completed';

-- Monthly sales trend with running total and growth
SELECT Sales_Month,
       Total_Orders,
       Revenue,
       SUM(Revenue) OVER (ORDER BY Sales_Month) AS Running_Revenue,
       ROUND((Revenue - LAG(Revenue) OVER (ORDER BY Sales_Month))
             / LAG(Revenue) OVER (ORDER BY Sales_Month) * 100, 1) AS Growth_Percent
FROM v_sales_report
ORDER BY Sales_Month;

-- Best-selling products
SELECT Product_Name, Category_Name, Units_Sold, Revenue,
       RANK() OVER (ORDER BY Units_Sold DESC) AS Sales_Rank
FROM v_product_performance
ORDER BY Sales_Rank, Product_Name
LIMIT 10;

-- Top revenue categories
SELECT Category_Name,
       SUM(Units_Sold) AS Units_Sold,
       SUM(Revenue)    AS Revenue,
       RANK() OVER (ORDER BY SUM(Revenue) DESC) AS Revenue_Rank
FROM v_product_performance
GROUP BY Category_Name
ORDER BY Revenue_Rank;

-- ---------------- CUSTOMER INTELLIGENCE REPORT ----------------

-- High-value customers (top 10 by spending)
SELECT Customer_Name, City, Total_Orders, Total_Spending, Segment,
       RANK() OVER (ORDER BY Total_Spending DESC) AS Spending_Rank
FROM v_customer_segments
ORDER BY Spending_Rank, Customer_Name
LIMIT 10;

-- Customer purchase frequency (orders per month)
SELECT Customer_Name, Total_Orders, Purchase_Frequency, Last_Order_Date, Segment
FROM v_customer_segments
WHERE Total_Orders > 0
ORDER BY Purchase_Frequency DESC, Total_Orders DESC, Customer_ID
LIMIT 15;

-- Customer segmentation summary
SELECT Segment                                                    AS Customer_Segment,
       COUNT(*)                                                   AS Customers,
       ROUND(COUNT(*) * 100 / (SELECT COUNT(*) FROM Customer), 1) AS Share_Of_Customers_Pct,
       ROUND(AVG(Total_Orders), 1)                                AS Avg_Orders,
       SUM(Total_Spending)                                        AS Total_Spending
FROM v_customer_segments
GROUP BY Segment
ORDER BY FIELD(Segment, 'Premium', 'Regular', 'Low Value', 'Inactive');

-- ---------------- INVENTORY INTELLIGENCE REPORT ----------------

-- Stock health summary
SELECT T.Stock_Status, COUNT(*) AS Products
FROM (
    SELECT CASE
               WHEN Stock_Quantity <= Reorder_Level     THEN 'Low stock'
               WHEN Stock_Quantity >= 5 * Reorder_Level THEN 'Overstocked'
               ELSE 'Healthy'
           END AS Stock_Status
    FROM Inventory
) T
GROUP BY T.Stock_Status
ORDER BY Products DESC;

-- Low-stock products (stock at or below the reorder level)
SELECT Product_Name, Category_Name, Seller_Name, Stock_Quantity, Reorder_Level,
       Reorder_Level - Stock_Quantity AS Shortfall
FROM v_product_performance
WHERE Stock_Quantity <= Reorder_Level
ORDER BY Stock_Quantity, Product_Name;

-- Fast-moving products (the top quarter by units sold)
SELECT F.Product_Name, F.Category_Name, F.Units_Sold, F.Stock_Quantity
FROM (
    SELECT Product_Name, Category_Name, Units_Sold, Stock_Quantity,
           NTILE(4) OVER (ORDER BY Units_Sold DESC, Product_ID) AS Speed_Quartile
    FROM v_product_performance
) F
WHERE F.Speed_Quartile = 1
ORDER BY F.Units_Sold DESC, F.Product_Name;

-- Overstocked products (5 times the reorder level or more) with their sales
SELECT Product_Name, Category_Name, Stock_Quantity, Units_Sold
FROM v_product_performance
WHERE Stock_Quantity >= 5 * Reorder_Level
ORDER BY Units_Sold, Stock_Quantity DESC
LIMIT 15;

-- ---------------- PRODUCT INTELLIGENCE REPORT ----------------

-- Highest-rated products
SELECT Product_Name, Category_Name, Avg_Rating, Review_Count, Units_Sold
FROM v_product_performance
WHERE Review_Count >= 1
ORDER BY Avg_Rating DESC, Review_Count DESC, Product_Name
LIMIT 10;

-- Poor-performing products (low rating or almost no sales)
SELECT Product_Name, Category_Name, Units_Sold, Revenue, Avg_Rating, Review_Count,
       CASE
           WHEN Review_Count > 0 AND Avg_Rating <= 2.5 THEN 'Low customer rating'
           ELSE 'Very low sales'
       END AS Problem
FROM v_product_performance
WHERE (Review_Count > 0 AND Avg_Rating <= 2.5) OR Units_Sold <= 1
ORDER BY Revenue, Product_Name
LIMIT 15;

-- Customer feedback trend: reviews and average rating per month
SELECT DATE_FORMAT(Review_Date, '%Y-%m') AS Review_Month,
       COUNT(*)                          AS Reviews,
       ROUND(AVG(Rating), 2)             AS Avg_Rating
FROM Review
GROUP BY DATE_FORMAT(Review_Date, '%Y-%m')
ORDER BY Review_Month;

-- Customer feedback: rating distribution
SELECT Rating,
       COUNT(*)                                                 AS Reviews,
       ROUND(COUNT(*) * 100 / (SELECT COUNT(*) FROM Review), 1) AS Share_Pct
FROM Review
GROUP BY Rating
ORDER BY Rating DESC;

-- ---------------- DECISION-MAKING RECOMMENDATIONS ----------------
SELECT 'Inventory' AS Area,
       CONCAT((SELECT COUNT(*) FROM Inventory WHERE Stock_Quantity <= Reorder_Level),
              ' products are at or below their reorder level') AS Finding,
       'Raise purchase orders with the sellers named in the low-stock report' AS Recommendation
UNION ALL
SELECT 'Inventory',
       CONCAT((SELECT COUNT(*) FROM Inventory WHERE Stock_Quantity >= 5 * Reorder_Level),
              ' products hold 5 times the reorder level or more'),
       'Run discounts or bundles to clear overstocked items'
UNION ALL
SELECT 'Customers',
       CONCAT((SELECT COUNT(*) FROM v_customer_segments WHERE Segment = 'Premium'),
              ' Premium customers generate ',
              (SELECT ROUND(SUM(Total_Spending) * 100 /
                            (SELECT SUM(Total_Amount) FROM Orders WHERE Order_Status = 'Completed'), 1)
               FROM v_customer_segments WHERE Segment = 'Premium'),
              ' percent of revenue'),
       'Protect them with loyalty rewards and priority support'
UNION ALL
SELECT 'Customers',
       CONCAT((SELECT COUNT(*) FROM v_customer_segments WHERE Segment = 'Inactive'),
              ' customers have never completed an order'),
       'Send welcome offers to turn them into buyers'
UNION ALL
SELECT 'Sales',
       CONCAT('Top revenue category: ',
              (SELECT Category_Name FROM v_product_performance
               GROUP BY Category_Name ORDER BY SUM(Revenue) DESC LIMIT 1)),
       'Increase stock and marketing for this category'
UNION ALL
SELECT 'Payments',
       CONCAT((SELECT COUNT(*) FROM Payment WHERE Payment_Status = 'Failed'),
              ' of ', (SELECT COUNT(*) FROM Payment), ' payments failed'),
       'Offer payment retry and more payment options to recover these sales';

-- ============================================================
-- TASK 8: LIVE DEMONSTRATION OF THE AUTOMATION
-- Run these blocks in order during the presentation.
-- ============================================================

-- ---------- Functions ----------
SELECT Customer_ID, Customer_Name,
       fn_customer_total_spending(Customer_ID) AS Total_Spending
FROM Customer
WHERE Customer_ID <= 5;

SELECT Product_ID, Product_Name,
       fn_product_revenue(Product_ID) AS Revenue
FROM Product
WHERE Product_ID <= 5;

-- ---------- Procedure: order placement (successful order) ----------
-- Customer 1 buys 2 x Samsung Galaxy S23 (product 1)
SELECT Stock_Quantity AS Stock_Before FROM Inventory WHERE Product_ID = 1;

CALL sp_place_order(1, 1, 2, 'UPI', @new_order, @msg);
SELECT @new_order AS New_Order_ID, @msg AS Result;

SELECT Stock_Quantity AS Stock_After FROM Inventory WHERE Product_ID = 1;
SELECT Order_ID, Order_Status, Total_Amount FROM Orders  WHERE Order_ID = @new_order;
SELECT Payment_ID, Payment_Status           FROM Payment WHERE Order_ID = @new_order;

-- ---------- Procedure: order placement (rejected, not enough stock) ----------
-- Product 73 (Nintendo Switch OLED) has only 1 unit in stock
CALL sp_place_order(2, 73, 5, 'UPI', @new_order, @msg);
SELECT @new_order AS New_Order_ID, @msg AS Result;

-- ---------- Procedure: stock update ----------
CALL sp_update_stock(5, 25, @msg);
SELECT @msg AS Result;
CALL sp_update_stock(5, -9999, @msg);
SELECT @msg AS Result;
SELECT Product_ID, Stock_Quantity, Last_Restocked FROM Inventory WHERE Product_ID = 5;

-- ---------- Procedure: sales calculation ----------
CALL sp_calculate_sales('2025-01-01', '2025-12-31');
CALL sp_calculate_sales('2025-01-01', '2025-03-31');

-- ---------- Triggers: failed payment cancels the order and restores stock ----------
SELECT Stock_Quantity AS Stock_Before FROM Inventory WHERE Product_ID = 2;

INSERT INTO Orders (Customer_ID, Order_Date, Total_Amount, Order_Status)
VALUES (2, CURDATE(), 69900.00, 'Pending');
SET @demo_order = LAST_INSERT_ID();

-- trigger reduces the stock
INSERT INTO Order_Details (Order_ID, Product_ID, Quantity, Price)
VALUES (@demo_order, 2, 1, 69900.00);
SELECT Stock_Quantity AS Stock_After_Order FROM Inventory WHERE Product_ID = 2;

-- trigger cancels the order and gives the stock back
INSERT INTO Payment (Order_ID, Payment_Method, Amount, Payment_Status, Payment_Date)
VALUES (@demo_order, 'Credit Card', 69900.00, 'Failed', CURDATE());

SELECT Order_ID, Order_Status FROM Orders WHERE Order_ID = @demo_order;
SELECT Stock_Quantity AS Stock_After_Failed_Payment FROM Inventory WHERE Product_ID = 2;

-- ---------- Triggers: audit records created automatically ----------
SELECT Audit_ID, Table_Name, Action_Type, Record_ID, Old_Value, New_Value, Changed_At
FROM Audit_Log
ORDER BY Audit_ID DESC
LIMIT 15;

-- ---------- Views ----------
SELECT * FROM v_customer_order_history WHERE Customer_ID = 1 ORDER BY Order_Date;
SELECT * FROM v_sales_report ORDER BY Sales_Month;
SELECT * FROM v_product_performance ORDER BY Revenue DESC LIMIT 10;

-- ---------- Project inventory: everything that was built ----------
SELECT 'Tables' AS Object_Type, COUNT(*) AS Total
FROM information_schema.TABLES
WHERE TABLE_SCHEMA = 'ecommerce_capstone_db' AND TABLE_TYPE = 'BASE TABLE'
  AND TABLE_NAME IN ('Category','Seller','Customer','Product','Inventory',
                     'Orders','Order_Details','Payment','Review','Audit_Log')
UNION ALL
SELECT 'Views', COUNT(*) FROM information_schema.VIEWS
WHERE TABLE_SCHEMA = 'ecommerce_capstone_db'
UNION ALL
SELECT 'Stored procedures', COUNT(*) FROM information_schema.ROUTINES
WHERE ROUTINE_SCHEMA = 'ecommerce_capstone_db' AND ROUTINE_TYPE = 'PROCEDURE'
  AND ROUTINE_NAME <> 'sp_bench'
UNION ALL
SELECT 'Functions', COUNT(*) FROM information_schema.ROUTINES
WHERE ROUTINE_SCHEMA = 'ecommerce_capstone_db' AND ROUTINE_TYPE = 'FUNCTION'
UNION ALL
SELECT 'Triggers', COUNT(*) FROM information_schema.TRIGGERS
WHERE TRIGGER_SCHEMA = 'ecommerce_capstone_db';

SELECT TRIGGER_NAME, ACTION_TIMING, EVENT_MANIPULATION, EVENT_OBJECT_TABLE
FROM information_schema.TRIGGERS
WHERE TRIGGER_SCHEMA = 'ecommerce_capstone_db'
ORDER BY EVENT_OBJECT_TABLE, TRIGGER_NAME;

-- Optional cleanup of the helper and test tables (run only when you are finished):
-- DROP TABLE Stg_Lines;
-- DROP TABLE Stg_Products;
-- DROP TABLE Perf_Orders;
-- DROP TABLE Perf_Products;
-- DROP TABLE Perf_Customers;
-- DROP TABLE Numbers;
-- DROP TABLE Digits;