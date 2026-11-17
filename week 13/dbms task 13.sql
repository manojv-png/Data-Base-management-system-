-- ============================================================
-- WEEK 13: DATABASE SECURITY AND PERFORMANCE OPTIMIZATION
-- ONE complete script. Works on MySQL 5.7 and 8.0+.
--
-- HOW TO RUN
--   1. Connect to MySQL Workbench as ROOT.
--   2. Open this file and press Ctrl + Shift + Enter (run ALL).
--   3. Wait about 1 minute. Every row in the Output panel should
--      show a green tick. The result tabs show the reports.
--   4. Access tests for each user are at the very END of this file
--      (commented out on purpose, see instructions there).
-- ============================================================

-- ------------------------------------------------------------
-- CLEAN START (safe to re-run)
-- ------------------------------------------------------------
DROP USER IF EXISTS 'admin_user'@'localhost';
DROP USER IF EXISTS 'sales_user'@'localhost';
DROP USER IF EXISTS 'inventory_user'@'localhost';
DROP USER IF EXISTS 'support_user'@'localhost';

DROP DATABASE IF EXISTS ecommerce_sec_db;
CREATE DATABASE ecommerce_sec_db;
USE ecommerce_sec_db;

-- ============================================================
-- PART A: E-COMMERCE SCHEMA AND TEST DATA
-- NOTE: Product.Category_ID and Orders.Customer_ID get their
-- FOREIGN KEY only AFTER the "before index" timing test. MySQL
-- silently creates an index for every foreign key, which would
-- hide the "no index" case we want to measure.
-- ============================================================

CREATE TABLE Category (
    Category_ID   INT          PRIMARY KEY,
    Category_Name VARCHAR(100) NOT NULL
);

CREATE TABLE Customer (
    Customer_ID   INT          PRIMARY KEY,
    Customer_Name VARCHAR(100) NOT NULL,
    Email         VARCHAR(100) NOT NULL,
    Phone         VARCHAR(15),
    City          VARCHAR(50)
);

CREATE TABLE Product (
    Product_ID   INT           PRIMARY KEY,
    Product_Name VARCHAR(100)  NOT NULL,
    Category_ID  INT           NOT NULL,
    Price        DECIMAL(10,2) NOT NULL CHECK (Price >= 0)
);

CREATE TABLE Inventory (
    Product_ID     INT PRIMARY KEY,
    Stock_Quantity INT NOT NULL CHECK (Stock_Quantity >= 0),
    FOREIGN KEY (Product_ID) REFERENCES Product(Product_ID)
);

CREATE TABLE Orders (
    Order_ID     INT           PRIMARY KEY,
    Customer_ID  INT           NOT NULL,
    Order_Date   DATE          NOT NULL,
    Total_Amount DECIMAL(10,2) NOT NULL CHECK (Total_Amount >= 0),
    Order_Status VARCHAR(20)   NOT NULL
                 CHECK (Order_Status IN ('Pending','Completed','Cancelled'))
);

CREATE TABLE Order_Details (
    Order_Detail_ID INT           AUTO_INCREMENT PRIMARY KEY,
    Order_ID        INT           NOT NULL,
    Product_ID      INT           NOT NULL,
    Quantity        INT           NOT NULL CHECK (Quantity > 0),
    Price           DECIMAL(10,2) NOT NULL CHECK (Price >= 0),
    FOREIGN KEY (Order_ID)   REFERENCES Orders(Order_ID),
    FOREIGN KEY (Product_ID) REFERENCES Product(Product_ID)
);

CREATE TABLE Payment (
    Payment_ID     INT         PRIMARY KEY,
    Order_ID       INT         NOT NULL,
    Payment_Method VARCHAR(20) NOT NULL,
    Payment_Status VARCHAR(20) NOT NULL
                   CHECK (Payment_Status IN ('Success','Failed','Pending')),
    FOREIGN KEY (Order_ID) REFERENCES Orders(Order_ID)
);

-- Records every GRANT / REVOKE we perform (used by Report 3)
CREATE TABLE Security_Log (
    Log_ID         INT          AUTO_INCREMENT PRIMARY KEY,
    Action_Type    VARCHAR(10)  NOT NULL CHECK (Action_Type IN ('GRANT','REVOKE')),
    Grantee        VARCHAR(60)  NOT NULL,
    Privilege_Name VARCHAR(100) NOT NULL,
    Object_Name    VARCHAR(150) NOT NULL,
    Reason         VARCHAR(200),
    Logged_At      TIMESTAMP    DEFAULT CURRENT_TIMESTAMP
);

-- Stores query timings (used by Report 2)
CREATE TABLE Perf_Log (
    Log_ID      INT           AUTO_INCREMENT PRIMARY KEY,
    Query_Name  VARCHAR(60)   NOT NULL,
    Phase       VARCHAR(10)   NOT NULL,
    Runs        INT           NOT NULL,
    Avg_Time_ms DECIMAL(12,3) NOT NULL,
    Logged_At   TIMESTAMP     DEFAULT CURRENT_TIMESTAMP
);

-- Helper tables used only to generate test rows
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

INSERT INTO Category VALUES
 (1,'Electronics'),(2,'Mobiles'),(3,'Accessories'),(4,'Appliances'),(5,'Books'),
 (6,'Clothing'),(7,'Footwear'),(8,'Toys'),(9,'Sports'),(10,'Grocery'),
 (11,'Furniture'),(12,'Beauty'),(13,'Health'),(14,'Automotive'),(15,'Stationery'),
 (16,'Kitchen'),(17,'Garden'),(18,'Music'),(19,'Gaming'),(20,'Jewellery');

-- 20,000 customers
INSERT INTO Customer (Customer_ID, Customer_Name, Email, Phone, City)
SELECT n,
       CONCAT('Customer ', n),
       CONCAT('customer', n, '@mail.com'),
       CONCAT('9', LPAD(n, 9, '0')),
       ELT(1 + MOD(n, 6), 'Chennai','Mumbai','Delhi','Pune','Hyderabad','Kolkata')
FROM Numbers
WHERE n <= 20000;

-- 20,000 generated products plus 3 named products
INSERT INTO Product (Product_ID, Product_Name, Category_ID, Price)
SELECT n,
       CONCAT('Product ', n),
       1 + MOD(n, 20),
       100 + MOD(n * 7919, 49900)
FROM Numbers
WHERE n <= 20000;

INSERT INTO Product (Product_ID, Product_Name, Category_ID, Price) VALUES
 (20001, 'Laptop',       1, 55000.00),
 (20002, 'Mobile Phone', 2, 20000.00),
 (20003, 'Mouse',        3,   500.00);

INSERT INTO Inventory (Product_ID, Stock_Quantity)
SELECT Product_ID, 10 + MOD(Product_ID * 13, 200)
FROM Product;

-- 100,000 orders (dates from 2024-01-01 to 2025-12-30)
INSERT INTO Orders (Order_ID, Customer_ID, Order_Date, Total_Amount, Order_Status)
SELECT n,
       1 + MOD(n * 7, 20000),
       DATE_ADD('2024-01-01', INTERVAL MOD(n, 730) DAY),
       500 + MOD(n * 131, 60000),
       CASE MOD(n, 10) WHEN 0 THEN 'Cancelled' WHEN 1 THEN 'Pending' ELSE 'Completed' END
FROM Numbers;

-- 150,000 order lines (every order has line 1, even orders also have line 2)
INSERT INTO Order_Details (Order_ID, Product_ID, Quantity, Price)
SELECT o.Order_ID, p.Product_ID, 1 + MOD(o.Order_ID, 5), p.Price
FROM Orders o
JOIN Product p ON p.Product_ID = 1 + MOD(o.Order_ID * 17, 20000);

INSERT INTO Order_Details (Order_ID, Product_ID, Quantity, Price)
SELECT o.Order_ID, p.Product_ID, 1 + MOD(o.Order_ID, 3), p.Price
FROM Orders o
JOIN Product p ON p.Product_ID = 1 + MOD(o.Order_ID * 29 + 7, 20000)
WHERE MOD(o.Order_ID, 2) = 0;

-- Payments for the first 2,000 orders that were completed
INSERT INTO Payment (Payment_ID, Order_ID, Payment_Method, Payment_Status)
SELECT Order_ID, Order_ID, ELT(1 + MOD(Order_ID, 3), 'UPI','Card','NetBanking'), 'Success'
FROM Orders
WHERE Order_ID <= 2000 AND Order_Status = 'Completed';

DROP TABLE Numbers;
DROP TABLE Digits;

ANALYZE TABLE Product, Customer, Orders, Order_Details;

-- Row count check. Expected: 20000 | 20003 | 100000 | 150000 | 1600
SELECT (SELECT COUNT(*) FROM Customer)      AS Customers,
       (SELECT COUNT(*) FROM Product)       AS Products,
       (SELECT COUNT(*) FROM Orders)        AS Orders_Count,
       (SELECT COUNT(*) FROM Order_Details) AS Order_Lines,
       (SELECT COUNT(*) FROM Payment)       AS Payments;

-- A safe view for reporting: no email, phone or payment data
CREATE OR REPLACE VIEW v_sales_report AS
SELECT O.Order_ID,
       O.Order_Date,
       C.Customer_Name,
       P.Product_Name,
       OD.Quantity,
       OD.Price                 AS Unit_Price,
       (OD.Quantity * OD.Price) AS Line_Total,
       O.Order_Status
FROM Orders O
JOIN Customer C       ON O.Customer_ID = C.Customer_ID
JOIN Order_Details OD ON O.Order_ID    = OD.Order_ID
JOIN Product P        ON OD.Product_ID = P.Product_ID;

-- ============================================================
-- TASK 1: CREATE DATABASE USERS
-- ============================================================
-- Passwords are for classroom use only. Use strong secrets in real systems.
CREATE USER 'admin_user'@'localhost'     IDENTIFIED BY 'Admin@Pass123';
CREATE USER 'sales_user'@'localhost'     IDENTIFIED BY 'Sales@Pass123';
CREATE USER 'inventory_user'@'localhost' IDENTIFIED BY 'Inv@Pass123';
CREATE USER 'support_user'@'localhost'   IDENTIFIED BY 'Support@Pass123';

-- ============================================================
-- TASK 2: GRANT AND REVOKE
-- ============================================================

-- ---------- ADMIN: create tables, change structure, manage users ----------
GRANT ALL PRIVILEGES ON ecommerce_sec_db.* TO 'admin_user'@'localhost' WITH GRANT OPTION;
GRANT CREATE USER ON *.* TO 'admin_user'@'localhost';

-- ---------- SALES: view orders and generate sales reports ----------
GRANT SELECT ON ecommerce_sec_db.Orders         TO 'sales_user'@'localhost';
GRANT SELECT ON ecommerce_sec_db.Order_Details  TO 'sales_user'@'localhost';
GRANT SELECT ON ecommerce_sec_db.Product        TO 'sales_user'@'localhost';
GRANT SELECT ON ecommerce_sec_db.Category       TO 'sales_user'@'localhost';
GRANT SELECT ON ecommerce_sec_db.v_sales_report TO 'sales_user'@'localhost';
-- Column-level grant: sales can see names and city, but NOT email or phone
GRANT SELECT (Customer_ID, Customer_Name, City) ON ecommerce_sec_db.Customer TO 'sales_user'@'localhost';

-- ---------- INVENTORY: view and update product stock ----------
GRANT SELECT ON ecommerce_sec_db.Inventory TO 'inventory_user'@'localhost';
GRANT SELECT ON ecommerce_sec_db.Product   TO 'inventory_user'@'localhost';
-- Only the Stock_Quantity column can be changed, nothing else
GRANT UPDATE (Stock_Quantity) ON ecommerce_sec_db.Inventory TO 'inventory_user'@'localhost';

-- ---------- CUSTOMER SUPPORT: view customer and order details ----------
GRANT SELECT ON ecommerce_sec_db.Customer      TO 'support_user'@'localhost';
GRANT SELECT ON ecommerce_sec_db.Orders        TO 'support_user'@'localhost';
GRANT SELECT ON ecommerce_sec_db.Order_Details TO 'support_user'@'localhost';
GRANT SELECT ON ecommerce_sec_db.Product       TO 'support_user'@'localhost';

INSERT INTO Security_Log (Action_Type, Grantee, Privilege_Name, Object_Name, Reason) VALUES
 ('GRANT', 'admin_user',     'ALL PRIVILEGES, CREATE USER', 'ecommerce_sec_db.*', 'Administrator: structure and user management'),
 ('GRANT', 'sales_user',     'SELECT', 'Orders, Order_Details, Product, Category, v_sales_report', 'View orders and build sales reports'),
 ('GRANT', 'sales_user',     'SELECT (3 columns)', 'Customer (ID, Name, City)', 'Email and phone hidden from sales'),
 ('GRANT', 'inventory_user', 'SELECT, UPDATE (Stock_Quantity)', 'Inventory, Product', 'View and update stock only'),
 ('GRANT', 'support_user',   'SELECT', 'Customer, Orders, Order_Details, Product', 'View customer and order details');

-- ---------- REVOKE DEMO 1 (the example from the task sheet) ----------
-- A privilege must be granted before it can be revoked.
GRANT INSERT ON ecommerce_sec_db.Payment TO 'sales_user'@'localhost';
SHOW GRANTS FOR 'sales_user'@'localhost';

REVOKE INSERT ON ecommerce_sec_db.Payment FROM 'sales_user'@'localhost';
SHOW GRANTS FOR 'sales_user'@'localhost';

-- ---------- REVOKE DEMO 2 ----------
GRANT SELECT ON ecommerce_sec_db.Payment TO 'support_user'@'localhost';
REVOKE SELECT ON ecommerce_sec_db.Payment FROM 'support_user'@'localhost';

INSERT INTO Security_Log (Action_Type, Grantee, Privilege_Name, Object_Name, Reason) VALUES
 ('GRANT',  'sales_user',   'INSERT', 'Payment', 'Temporary grant used to demonstrate REVOKE'),
 ('REVOKE', 'sales_user',   'INSERT', 'Payment', 'Sales staff must never write payment data'),
 ('GRANT',  'support_user', 'SELECT', 'Payment', 'Temporary grant used to demonstrate REVOKE'),
 ('REVOKE', 'support_user', 'SELECT', 'Payment', 'Support does not need payment data');

-- ---------- STUDENT QUESTIONS ----------
-- 1. Why should all users not have full database access?
--    Least privilege: each person gets only what the job needs. Full
--    access lets a typo (DROP TABLE, UPDATE without WHERE) destroy data,
--    lets insiders read or change records they should not touch, and
--    means one stolen password (or one SQL injection) exposes everything.
--    It also makes audits hard because nobody can say who may do what.
--
-- 2. What risks occur if payment data is accessible to everyone?
--    Fraud and identity theft, tampering (marking an unpaid order as
--    paid or changing amounts), privacy-law and PCI-DSS violations with
--    heavy fines (for example India's DPDP Act 2023 or GDPR), loss of
--    customer trust, and a much larger damage if any one account leaks.
--
-- 3. How does role-based access improve security?
--    Permissions are attached to a role such as "Sales", and people are
--    only assigned a role. New staff get the right access in one step,
--    changing a role updates everyone in it at once, forgotten per-user
--    grants are avoided, least privilege is applied the same way for
--    every person, and auditing is simple because you review a few
--    roles instead of every individual user.

-- ============================================================
-- TASK 3: ACCESS CONTROL (role matrix and verification)
-- ============================================================
--   Role              User             Allowed operations
--   Admin             admin_user       Full access: create tables, alter structure, manage users
--   Sales Staff       sales_user       View Orders and reports (SELECT only; no email or phone)
--   Inventory Staff   inventory_user   View stock and update Stock_Quantity only
--   Customer Support  support_user     View customer and order details (SELECT only)
--
-- Permissions of each user as stored by the server:
SHOW GRANTS FOR 'admin_user'@'localhost';
SHOW GRANTS FOR 'sales_user'@'localhost';
SHOW GRANTS FOR 'inventory_user'@'localhost';
SHOW GRANTS FOR 'support_user'@'localhost';
-- Authorized, unauthorized and permission-error tests are at the END
-- of this file (they must be run while logged in AS each user).

-- ============================================================
-- TASK 5 (PART 1): QUERY PERFORMANCE BEFORE INDEXES
-- ============================================================

-- Benchmark helper: runs a statement p_runs times and stores the
-- average time in milliseconds in Perf_Log.
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

-- Indexes that exist right now (only PRIMARY KEYS and foreign-key helpers)
SELECT TABLE_NAME, INDEX_NAME,
       GROUP_CONCAT(COLUMN_NAME ORDER BY SEQ_IN_INDEX) AS Indexed_Columns
FROM information_schema.STATISTICS
WHERE TABLE_SCHEMA = 'ecommerce_sec_db'
  AND TABLE_NAME IN ('Product', 'Customer', 'Orders', 'Order_Details')
GROUP BY TABLE_NAME, INDEX_NAME
ORDER BY TABLE_NAME, INDEX_NAME;

-- Execution plans BEFORE indexing (look for type = ALL and key = NULL)
EXPLAIN SELECT * FROM Product WHERE Product_Name = 'Laptop';
EXPLAIN SELECT * FROM Product WHERE Category_ID = 7;
EXPLAIN SELECT Order_ID, Order_Date, Total_Amount, Order_Status
        FROM Orders WHERE Customer_ID = 12345 ORDER BY Order_Date DESC LIMIT 50;
EXPLAIN SELECT Order_Date, COUNT(*) AS Total_Orders, SUM(Total_Amount) AS Daily_Sales
        FROM Orders
        WHERE Order_Date BETWEEN '2025-03-01' AND '2025-03-31' AND Order_Status = 'Completed'
        GROUP BY Order_Date;
EXPLAIN SELECT P.Product_Name, SUM(OD.Quantity) AS Total_Sold
        FROM Order_Details OD JOIN Product P ON P.Product_ID = OD.Product_ID
        GROUP BY P.Product_ID, P.Product_Name ORDER BY Total_Sold DESC LIMIT 10;
EXPLAIN SELECT * FROM Customer WHERE Email = 'customer15000@mail.com';
EXPLAIN SELECT * FROM Customer WHERE Phone = '9000015000';

-- Timing BEFORE indexing (each query runs 5 times, average is stored)
CALL sp_bench('Product Search by Name', 'BEFORE',
  "SELECT COUNT(*) INTO @rows FROM (SELECT * FROM Product WHERE Product_Name = 'Laptop') AS q", 5);

CALL sp_bench('Q1 Products by Category', 'BEFORE',
  "SELECT COUNT(*) INTO @rows FROM (SELECT * FROM Product WHERE Category_ID = 7) AS q", 5);

CALL sp_bench('Q2 Customer Order History', 'BEFORE',
  "SELECT COUNT(*) INTO @rows FROM (SELECT Order_ID, Order_Date, Total_Amount, Order_Status FROM Orders WHERE Customer_ID = 12345 ORDER BY Order_Date DESC LIMIT 50) AS q", 5);

CALL sp_bench('Q3 Sales Report (Mar 2025)', 'BEFORE',
  "SELECT COUNT(*) INTO @rows FROM (SELECT Order_Date, COUNT(*) AS Total_Orders, SUM(Total_Amount) AS Daily_Sales FROM Orders WHERE Order_Date BETWEEN '2025-03-01' AND '2025-03-31' AND Order_Status = 'Completed' GROUP BY Order_Date) AS q", 5);

CALL sp_bench('Q4 Top-Selling Products', 'BEFORE',
  "SELECT COUNT(*) INTO @rows FROM (SELECT P.Product_Name, SUM(OD.Quantity) AS Total_Sold FROM Order_Details OD JOIN Product P ON P.Product_ID = OD.Product_ID GROUP BY P.Product_ID, P.Product_Name ORDER BY Total_Sold DESC LIMIT 10) AS q", 5);

CALL sp_bench('Customer Search by Email', 'BEFORE',
  "SELECT COUNT(*) INTO @rows FROM (SELECT * FROM Customer WHERE Email = 'customer15000@mail.com') AS q", 5);

CALL sp_bench('Customer Search by Phone', 'BEFORE',
  "SELECT COUNT(*) INTO @rows FROM (SELECT * FROM Customer WHERE Phone = '9000015000') AS q", 5);

-- ============================================================
-- TASK 4: CREATE INDEXES FOR FASTER SEARCHING
-- ============================================================

-- Product search
CREATE INDEX idx_product_name     ON Product(Product_Name);
CREATE INDEX idx_product_category ON Product(Category_ID);

-- Customer search
CREATE INDEX idx_customer_email   ON Customer(Email);
CREATE INDEX idx_customer_phone   ON Customer(Phone);

-- Order search
CREATE INDEX idx_orders_date      ON Orders(Order_Date);
CREATE INDEX idx_orders_customer  ON Orders(Customer_ID);

-- Extra optimization indexes
-- Customer + date together: finds a customer's orders already sorted by date
CREATE INDEX idx_orders_cust_date ON Orders(Customer_ID, Order_Date);
-- Covering index: top-selling query reads only this index, not the table
CREATE INDEX idx_od_product_qty   ON Order_Details(Product_ID, Quantity);

-- Now add the foreign keys that were postponed. They reuse the indexes above.
ALTER TABLE Product
    ADD CONSTRAINT fk_product_category
    FOREIGN KEY (Category_ID) REFERENCES Category(Category_ID);

ALTER TABLE Orders
    ADD CONSTRAINT fk_orders_customer
    FOREIGN KEY (Customer_ID) REFERENCES Customer(Customer_ID);

ANALYZE TABLE Product, Customer, Orders, Order_Details;

-- Indexes after optimization
SELECT TABLE_NAME, INDEX_NAME,
       GROUP_CONCAT(COLUMN_NAME ORDER BY SEQ_IN_INDEX) AS Indexed_Columns
FROM information_schema.STATISTICS
WHERE TABLE_SCHEMA = 'ecommerce_sec_db'
  AND TABLE_NAME IN ('Product', 'Customer', 'Orders', 'Order_Details')
GROUP BY TABLE_NAME, INDEX_NAME
ORDER BY TABLE_NAME, INDEX_NAME;

-- ============================================================
-- TASK 5 (PART 2): QUERY PERFORMANCE AFTER INDEXES
-- ============================================================

-- Execution plans AFTER indexing (look for type = ref/range and a key name)
EXPLAIN SELECT * FROM Product WHERE Product_Name = 'Laptop';
EXPLAIN SELECT * FROM Product WHERE Category_ID = 7;
EXPLAIN SELECT Order_ID, Order_Date, Total_Amount, Order_Status
        FROM Orders WHERE Customer_ID = 12345 ORDER BY Order_Date DESC LIMIT 50;
EXPLAIN SELECT Order_Date, COUNT(*) AS Total_Orders, SUM(Total_Amount) AS Daily_Sales
        FROM Orders
        WHERE Order_Date BETWEEN '2025-03-01' AND '2025-03-31' AND Order_Status = 'Completed'
        GROUP BY Order_Date;
EXPLAIN SELECT P.Product_Name, SUM(OD.Quantity) AS Total_Sold
        FROM Order_Details OD JOIN Product P ON P.Product_ID = OD.Product_ID
        GROUP BY P.Product_ID, P.Product_Name ORDER BY Total_Sold DESC LIMIT 10;
EXPLAIN SELECT * FROM Customer WHERE Email = 'customer15000@mail.com';
EXPLAIN SELECT * FROM Customer WHERE Phone = '9000015000';

-- Timing AFTER indexing
CALL sp_bench('Product Search by Name', 'AFTER',
  "SELECT COUNT(*) INTO @rows FROM (SELECT * FROM Product WHERE Product_Name = 'Laptop') AS q", 5);

CALL sp_bench('Q1 Products by Category', 'AFTER',
  "SELECT COUNT(*) INTO @rows FROM (SELECT * FROM Product WHERE Category_ID = 7) AS q", 5);

CALL sp_bench('Q2 Customer Order History', 'AFTER',
  "SELECT COUNT(*) INTO @rows FROM (SELECT Order_ID, Order_Date, Total_Amount, Order_Status FROM Orders WHERE Customer_ID = 12345 ORDER BY Order_Date DESC LIMIT 50) AS q", 5);

CALL sp_bench('Q3 Sales Report (Mar 2025)', 'AFTER',
  "SELECT COUNT(*) INTO @rows FROM (SELECT Order_Date, COUNT(*) AS Total_Orders, SUM(Total_Amount) AS Daily_Sales FROM Orders WHERE Order_Date BETWEEN '2025-03-01' AND '2025-03-31' AND Order_Status = 'Completed' GROUP BY Order_Date) AS q", 5);

CALL sp_bench('Q4 Top-Selling Products', 'AFTER',
  "SELECT COUNT(*) INTO @rows FROM (SELECT P.Product_Name, SUM(OD.Quantity) AS Total_Sold FROM Order_Details OD JOIN Product P ON P.Product_ID = OD.Product_ID GROUP BY P.Product_ID, P.Product_Name ORDER BY Total_Sold DESC LIMIT 10) AS q", 5);

CALL sp_bench('Customer Search by Email', 'AFTER',
  "SELECT COUNT(*) INTO @rows FROM (SELECT * FROM Customer WHERE Email = 'customer15000@mail.com') AS q", 5);

CALL sp_bench('Customer Search by Phone', 'AFTER',
  "SELECT COUNT(*) INTO @rows FROM (SELECT * FROM Customer WHERE Phone = '9000015000') AS q", 5);

-- ---------- The four optimized queries with real output ----------

-- Query 1: Search products by category
SELECT P.Product_ID, P.Product_Name, C.Category_Name, P.Price
FROM Product P
JOIN Category C ON P.Category_ID = C.Category_ID
WHERE P.Category_ID = 7
ORDER BY P.Product_ID
LIMIT 10;

-- Query 2: Customer order history (newest first)
SELECT O.Order_ID, O.Order_Date, O.Total_Amount, O.Order_Status
FROM Orders O
WHERE O.Customer_ID = 12345
ORDER BY O.Order_Date DESC
LIMIT 50;

-- Query 3: Sales report for March 2025 (completed orders, per day)
SELECT Order_Date, COUNT(*) AS Total_Orders, SUM(Total_Amount) AS Daily_Sales
FROM Orders
WHERE Order_Date BETWEEN '2025-03-01' AND '2025-03-31'
  AND Order_Status = 'Completed'
GROUP BY Order_Date
ORDER BY Order_Date;

-- Query 4: Top 10 selling products
SELECT P.Product_Name, SUM(OD.Quantity) AS Total_Sold
FROM Order_Details OD
JOIN Product P ON P.Product_ID = OD.Product_ID
GROUP BY P.Product_ID, P.Product_Name
ORDER BY Total_Sold DESC
LIMIT 10;

-- ============================================================
-- REPORTS
-- ============================================================

-- REPORT 1A: User Access Report - user, assigned role, permissions
SELECT 'admin_user' AS User_Name, 'Admin' AS Assigned_Role,
       'Full access: create tables, alter structure, manage users' AS Permission_Summary
UNION ALL
SELECT 'sales_user', 'Sales Staff',
       'View orders and reports (SELECT only, no email or phone)'
UNION ALL
SELECT 'inventory_user', 'Inventory Staff',
       'View stock and update Stock_Quantity only'
UNION ALL
SELECT 'support_user', 'Customer Support',
       'View customer and order details (SELECT only)';

-- REPORT 1B: Table-level privileges actually held by each user
SELECT GRANTEE AS User_Name,
       TABLE_NAME,
       GROUP_CONCAT(PRIVILEGE_TYPE ORDER BY PRIVILEGE_TYPE SEPARATOR ', ') AS Permissions
FROM information_schema.TABLE_PRIVILEGES
WHERE TABLE_SCHEMA = 'ecommerce_sec_db'
  AND GRANTEE IN ("'admin_user'@'localhost'", "'sales_user'@'localhost'",
                  "'inventory_user'@'localhost'", "'support_user'@'localhost'")
GROUP BY GRANTEE, TABLE_NAME
ORDER BY GRANTEE, TABLE_NAME;

-- REPORT 1C: Column-level privileges
SELECT GRANTEE AS User_Name, TABLE_NAME, COLUMN_NAME, PRIVILEGE_TYPE
FROM information_schema.COLUMN_PRIVILEGES
WHERE TABLE_SCHEMA = 'ecommerce_sec_db'
  AND GRANTEE IN ("'admin_user'@'localhost'", "'sales_user'@'localhost'",
                  "'inventory_user'@'localhost'", "'support_user'@'localhost'")
ORDER BY GRANTEE, TABLE_NAME, COLUMN_NAME;

-- REPORT 1D: Admin user - database-wide and global privileges
SELECT GRANTEE AS User_Name,
       TABLE_SCHEMA AS Scope,
       GROUP_CONCAT(PRIVILEGE_TYPE ORDER BY PRIVILEGE_TYPE SEPARATOR ', ') AS Permissions
FROM information_schema.SCHEMA_PRIVILEGES
WHERE GRANTEE = "'admin_user'@'localhost'"
GROUP BY GRANTEE, TABLE_SCHEMA
UNION ALL
SELECT GRANTEE, '*.* (global)',
       GROUP_CONCAT(PRIVILEGE_TYPE ORDER BY PRIVILEGE_TYPE SEPARATOR ', ')
FROM information_schema.USER_PRIVILEGES
WHERE GRANTEE = "'admin_user'@'localhost'" AND PRIVILEGE_TYPE <> 'USAGE'
GROUP BY GRANTEE;

-- REPORT 2: Query Performance Report (before vs after indexes)
-- Times are measured on YOUR machine, so the numbers will differ.
SELECT B.Query_Name                                                    AS Query_Name,
       B.Avg_Time_ms                                                   AS Before_Index_ms,
       A.Avg_Time_ms                                                   AS After_Index_ms,
       ROUND(B.Avg_Time_ms / NULLIF(A.Avg_Time_ms, 0), 1)              AS Times_Faster,
       ROUND((B.Avg_Time_ms - A.Avg_Time_ms) / B.Avg_Time_ms * 100, 1) AS Improvement_Percent
FROM Perf_Log B
JOIN Perf_Log A ON A.Query_Name = B.Query_Name AND A.Phase = 'AFTER'
WHERE B.Phase = 'BEFORE'
ORDER BY B.Log_ID;

-- REPORT 3A: Database Security Report - granted and revoked permissions
SELECT Log_ID, Action_Type, Grantee, Privilege_Name, Object_Name, Reason, Logged_At
FROM Security_Log
ORDER BY Log_ID;

-- REPORT 3B: Database accounts that exist for this project
SELECT User, Host
FROM mysql.user
WHERE User IN ('admin_user', 'sales_user', 'inventory_user', 'support_user')
ORDER BY User;

-- ============================================================
-- BONUS (MySQL 8.0 and newer ONLY): REAL ROLES
-- Kept at the very end so an older MySQL version is never blocked by it.
-- Roles group privileges; users then receive the role.
-- ============================================================
DROP ROLE IF EXISTS role_admin;
DROP ROLE IF EXISTS role_sales;
DROP ROLE IF EXISTS role_inventory;
DROP ROLE IF EXISTS role_support;

CREATE ROLE role_admin;
CREATE ROLE role_sales;
CREATE ROLE role_inventory;
CREATE ROLE role_support;

GRANT ALL PRIVILEGES ON ecommerce_sec_db.* TO role_admin;
GRANT SELECT ON ecommerce_sec_db.Orders         TO role_sales;
GRANT SELECT ON ecommerce_sec_db.Order_Details  TO role_sales;
GRANT SELECT ON ecommerce_sec_db.v_sales_report TO role_sales;
GRANT SELECT ON ecommerce_sec_db.Inventory      TO role_inventory;
GRANT UPDATE (Stock_Quantity) ON ecommerce_sec_db.Inventory TO role_inventory;
GRANT SELECT ON ecommerce_sec_db.Customer       TO role_support;
GRANT SELECT ON ecommerce_sec_db.Orders         TO role_support;

GRANT role_admin     TO 'admin_user'@'localhost';
GRANT role_sales     TO 'sales_user'@'localhost';
GRANT role_inventory TO 'inventory_user'@'localhost';
GRANT role_support   TO 'support_user'@'localhost';

SET DEFAULT ROLE role_admin     TO 'admin_user'@'localhost';
SET DEFAULT ROLE role_sales     TO 'sales_user'@'localhost';
SET DEFAULT ROLE role_inventory TO 'inventory_user'@'localhost';
SET DEFAULT ROLE role_support   TO 'support_user'@'localhost';

-- Which user holds which role
SELECT CONCAT(TO_USER, '@', TO_HOST) AS User_Name, FROM_USER AS Assigned_Role
FROM mysql.role_edges
WHERE TO_USER IN ('admin_user', 'sales_user', 'inventory_user', 'support_user')
ORDER BY TO_USER;

-- ============================================================
-- ACCESS CONTROL TESTS (COMMENTED OUT ON PURPOSE)
-- Running them as root would succeed and prove nothing. They only make
-- sense when you are logged in AS the user being tested.
--
-- HOW TO USE
--  1. Workbench Home -> click + next to "MySQL Connections". Create four
--     connections (Hostname 127.0.0.1, Port 3306) with these logins:
--         admin_user      Admin@Pass123
--         sales_user      Sales@Pass123
--         inventory_user  Inv@Pass123
--         support_user    Support@Pass123
--  2. Open one connection, open a NEW query tab, copy that user's block
--     below into it, remove the leading "-- " (select the lines and
--     press Ctrl + /), then run the lines ONE AT A TIME with Ctrl + Enter.
--     Several are SUPPOSED to fail. That error is the proof of security.
--  3. If login fails with "Access denied", use hostname localhost.
-- ============================================================

-- ################ SALES USER (connect as sales_user) ################
-- USE ecommerce_sec_db;
--
-- -- AUTHORIZED (must work)
-- SELECT * FROM Orders LIMIT 5;
-- SELECT * FROM v_sales_report LIMIT 5;
-- SELECT Customer_ID, Customer_Name, City FROM Customer LIMIT 5;
--
-- -- UNAUTHORIZED (each must fail)
-- SELECT * FROM Payment LIMIT 5;            -- ERROR 1142 SELECT command denied for table Payment
-- SELECT Email, Phone FROM Customer LIMIT 5;-- ERROR 1143 SELECT command denied for column Email
-- DELETE FROM Orders WHERE Order_ID = 0;    -- ERROR 1142 DELETE command denied
-- CREATE TABLE hacker_test (id INT);        -- ERROR 1142 CREATE command denied
-- CREATE USER 'hacker'@'localhost' IDENTIFIED BY 'Hack@Pass123';  -- ERROR 1227 need CREATE USER privilege

-- ################ INVENTORY USER (connect as inventory_user) ################
-- USE ecommerce_sec_db;
--
-- -- AUTHORIZED (must work)
-- SELECT * FROM Inventory LIMIT 5;
-- UPDATE Inventory SET Stock_Quantity = Stock_Quantity + 5 WHERE Product_ID = 20001;
--
-- -- UNAUTHORIZED (each must fail)
-- UPDATE Product SET Price = 1 WHERE Product_ID = 0;              -- ERROR 1142 UPDATE command denied for table Product
-- UPDATE Inventory SET Product_ID = 1 WHERE Product_ID = 0;       -- ERROR 1143 UPDATE command denied for column Product_ID
-- DELETE FROM Inventory WHERE Product_ID = 0;                     -- ERROR 1142 DELETE command denied
-- SELECT * FROM Orders LIMIT 5;                                   -- ERROR 1142 SELECT command denied for table Orders
-- SELECT * FROM Customer LIMIT 5;                                 -- ERROR 1142 SELECT command denied for table Customer

-- ################ CUSTOMER SUPPORT USER (connect as support_user) ################
-- USE ecommerce_sec_db;
--
-- -- AUTHORIZED (must work)
-- SELECT Customer_Name, Email, Phone, City FROM Customer WHERE Customer_ID = 100;
-- SELECT Order_ID, Order_Date, Order_Status FROM Orders WHERE Customer_ID = 100;
--
-- -- UNAUTHORIZED (each must fail)
-- UPDATE Customer SET City = 'Test' WHERE Customer_ID = 0;  -- ERROR 1142 UPDATE command denied
-- DELETE FROM Orders WHERE Order_ID = 0;                    -- ERROR 1142 DELETE command denied
-- SELECT * FROM Payment LIMIT 5;                            -- ERROR 1142 SELECT command denied for table Payment
-- SELECT * FROM Inventory LIMIT 5;                          -- ERROR 1142 SELECT command denied for table Inventory

-- ################ ADMIN USER (connect as admin_user) ################
-- USE ecommerce_sec_db;
--
-- -- AUTHORIZED (all must work)
-- CREATE TABLE test_admin (id INT PRIMARY KEY);
-- ALTER TABLE test_admin ADD COLUMN note VARCHAR(20);
-- SELECT * FROM Payment LIMIT 5;
-- DROP TABLE test_admin;
-- CREATE USER 'temp_user'@'localhost' IDENTIFIED BY 'Temp@Pass123';
-- DROP USER 'temp_user'@'localhost';