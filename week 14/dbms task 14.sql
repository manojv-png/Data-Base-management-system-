-- ============================================================
-- WEEK 14: BUSINESS INTELLIGENCE AND AI DATA PREPARATION
-- ONE complete script. Needs MySQL 8.0 or newer (window functions).
--
-- HOW TO RUN
--   1. Connect to MySQL Workbench (any user that can create databases).
--   2. Open this file and press Ctrl + Shift + Enter (run ALL).
--   3. Wait a few seconds. Every row in the Output panel should have
--      a green tick. Each result tab is one report or query.
--   4. To re-run one report later, click inside that single statement and
--      press Ctrl + Enter. To rebuild everything, run the whole file again.
--
-- BUSINESS RULES USED IN EVERY REPORT
--   * A "sale" or "purchase" means an order with Order_Status = 'Completed'.
--     Pending and Cancelled orders are ignored.
--   * Money values are plain numbers in rupees (no currency symbol).
-- ============================================================

-- Version check. Expected: OK - window functions supported
SELECT VERSION() AS MySQL_Version,
       IF(CAST(SUBSTRING_INDEX(VERSION(), '.', 1) AS UNSIGNED) >= 8,
          'OK - window functions supported',
          'STOP - MySQL 8.0 or newer is required') AS Version_Check;

-- ------------------------------------------------------------
-- CLEAN START (safe to re-run)
-- ------------------------------------------------------------
DROP DATABASE IF EXISTS ecommerce_bi_db;
CREATE DATABASE ecommerce_bi_db;
USE ecommerce_bi_db;

-- ============================================================
-- PART A: E-COMMERCE SCHEMA AND SAMPLE DATA
-- ============================================================

CREATE TABLE Category (
    Category_ID   INT          PRIMARY KEY,
    Category_Name VARCHAR(100) NOT NULL
);

-- Age and City may be missing, and Customer contains a few dirty rows on
-- purpose (missing age, invalid age, duplicate customers). Task 4 cleans them.
CREATE TABLE Customer (
    Customer_ID   INT          PRIMARY KEY,
    Customer_Name VARCHAR(100) NOT NULL,
    Email         VARCHAR(100) NOT NULL,
    Age           INT          NULL,
    City          VARCHAR(50)  NULL
);

CREATE TABLE Product (
    Product_ID   INT           PRIMARY KEY,
    Product_Name VARCHAR(100)  NOT NULL,
    Category_ID  INT           NOT NULL,
    Price        DECIMAL(10,2) NOT NULL CHECK (Price >= 0),
    FOREIGN KEY (Category_ID) REFERENCES Category(Category_ID)
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
    Price           DECIMAL(10,2) NOT NULL CHECK (Price >= 0),
    FOREIGN KEY (Order_ID)   REFERENCES Orders(Order_ID),
    FOREIGN KEY (Product_ID) REFERENCES Product(Product_ID)
);

-- Customer ratings (used for the "Average rating" product feature)
CREATE TABLE Product_Review (
    Review_ID   INT AUTO_INCREMENT PRIMARY KEY,
    Product_ID  INT NOT NULL,
    Customer_ID INT NOT NULL,
    Rating      INT NOT NULL CHECK (Rating BETWEEN 1 AND 5),
    FOREIGN KEY (Product_ID)  REFERENCES Product(Product_ID),
    FOREIGN KEY (Customer_ID) REFERENCES Customer(Customer_ID)
);

-- Helper tables used only to generate sample orders
CREATE TABLE Digits (d INT PRIMARY KEY);
INSERT INTO Digits VALUES (0),(1),(2),(3),(4),(5),(6),(7),(8),(9);

CREATE TABLE Numbers (n INT PRIMARY KEY);
INSERT INTO Numbers (n)
SELECT d1.d + d2.d*10 + 1
FROM Digits d1
CROSS JOIN Digits d2;
-- Numbers now holds 1 .. 100

CREATE TABLE Stg_Lines (
    Order_ID    INT,
    Customer_ID INT,
    Order_Date  DATE,
    Product_ID  INT,
    Quantity    INT,
    Price       DECIMAL(10,2)
);

INSERT INTO Category VALUES
 (1,'Electronics'),(2,'Mobiles'),(3,'Accessories'),(4,'Wearables'),(5,'Lifestyle');

INSERT INTO Customer (Customer_ID, Customer_Name, Email, Age, City) VALUES
 (1,  'Arun',    'arun@mail.com',    34,   'Chennai'),
 (2,  'Priya',   'priya@mail.com',   28,   'Mumbai'),
 (3,  'Karan',   'karan@mail.com',   41,   'Delhi'),
 (4,  'Sneha',   'sneha@mail.com',   NULL, 'Pune'),
 (5,  'Rahul',   'rahul@mail.com',   25,   'Hyderabad'),
 (6,  'Meena',   'meena@mail.com',   37,   'Chennai'),
 (7,  'Vikram',  'vikram@mail.com',  45,   'Bengaluru'),
 (8,  'Divya',   'divya@mail.com',   31,   'Kochi'),
 (9,  'Anil',    'anil@mail.com',    NULL, 'Jaipur'),
 (10, 'Kavya',   'kavya@mail.com',   23,   'Mysuru'),
 (11, 'Suresh',  'suresh@mail.com',  52,   'Madurai'),
 (12, 'Lakshmi', 'lakshmi@mail.com', 0,    'Salem'),
 (13, 'Manoj',   'manoj@mail.com',   NULL, NULL),
 (14, 'Nisha',   'nisha@mail.com',   29,   'Kolkata'),
 (15, 'Ravi',    'ravi@mail.com',    39,   'Pune'),
 -- duplicate sign-ups of Priya (different case, trailing space) and Rahul
 (16, 'Priya',   'PRIYA@mail.com ',  28,   'Mumbai'),
 (17, 'Rahul K', 'rahul@mail.com',   25,   'Hyderabad');

INSERT INTO Product (Product_ID, Product_Name, Category_ID, Price) VALUES
 (1,  'Laptop',       1, 55000.00),
 (2,  'Smartphone',   2, 20000.00),
 (3,  'Headphones',   3,  2500.00),
 (4,  'Smart TV',     1, 45000.00),
 (5,  'Keyboard',     3,  1500.00),
 (6,  'Mouse',        3,   500.00),
 (7,  'Tablet',       2, 25000.00),
 (8,  'Smart Watch',  4,  8000.00),
 (9,  'Backpack',     5,  1800.00),
 (10, 'Water Bottle', 5,   600.00);

INSERT INTO Inventory (Product_ID, Stock_Quantity) VALUES
 (1,12),(2,45),(3,0),(4,8),(5,150),(6,300),(7,20),(8,5),(9,60),(10,0);

-- 60 orders. Customers 1..10 buy (customer 1 buys most); 11..15 never buy.
-- Line 1 exists for every order, line 2 for even-numbered orders.
INSERT INTO Stg_Lines (Order_ID, Customer_ID, Order_Date, Product_ID, Quantity, Price)
SELECT N.n,
       CAST(ELT(1 + MOD(N.n, 20), 1,1,1,1,1,2,2,2,2,3,3,3,4,4,5,6,7,8,9,10) AS UNSIGNED),
       DATE_ADD('2025-01-01', INTERVAL N.n * 6 DAY),
       P.Product_ID,
       1 + MOD(N.n * 5, 7),
       P.Price
FROM Numbers N
JOIN Product P ON P.Product_ID = 1 + MOD(N.n * 3, 10)
WHERE N.n <= 60;

INSERT INTO Stg_Lines (Order_ID, Customer_ID, Order_Date, Product_ID, Quantity, Price)
SELECT N.n,
       CAST(ELT(1 + MOD(N.n, 20), 1,1,1,1,1,2,2,2,2,3,3,3,4,4,5,6,7,8,9,10) AS UNSIGNED),
       DATE_ADD('2025-01-01', INTERVAL N.n * 6 DAY),
       P.Product_ID,
       1 + MOD(N.n * 3, 4),
       P.Price
FROM Numbers N
JOIN Product P ON P.Product_ID = 1 + MOD(N.n * 7 + 2, 10)
WHERE N.n <= 60 AND MOD(N.n, 2) = 0;

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
FROM Stg_Lines;


INSERT INTO Product_Review (Product_ID, Customer_ID, Rating)
SELECT 1 + MOD(n, 9), 1 + MOD(n, 10), 1 + MOD(n * 3, 5)
FROM Numbers
WHERE n <= 36;

-- The helper tables Digits, Numbers and Stg_Lines are kept on purpose, so any
-- single statement in the data-loading section can be selected and run on
-- its own without a 'table doesn't exist' error. No report uses them.

-- Row count check. Expected: 17 | 10 | 60 | 90 | 36
SELECT (SELECT COUNT(*) FROM Customer)       AS Customers,
       (SELECT COUNT(*) FROM Product)        AS Products,
       (SELECT COUNT(*) FROM Orders)         AS Orders_Count,
       (SELECT COUNT(*) FROM Order_Details)  AS Order_Lines,
       (SELECT COUNT(*) FROM Product_Review) AS Reviews;

-- ============================================================
-- PART B: REUSABLE VIEWS
-- ============================================================

-- One row per customer who has completed orders
CREATE OR REPLACE VIEW v_customer_orders AS
SELECT Customer_ID,
       COUNT(Order_ID)             AS Total_Orders,
       SUM(Total_Amount)           AS Total_Spending,
       ROUND(AVG(Total_Amount), 2) AS Avg_Order_Value,
       MIN(Order_Date)             AS First_Order_Date,
       MAX(Order_Date)             AS Last_Order_Date,
       -- Purchase frequency = orders per month between first and last order
       ROUND(COUNT(Order_ID) /
             (TIMESTAMPDIFF(MONTH, MIN(Order_Date), MAX(Order_Date)) + 1), 2) AS Purchase_Frequency
FROM Orders
WHERE Order_Status = 'Completed'
GROUP BY Customer_ID;

-- Most purchased category of every customer (by quantity, ties -> lowest Category_ID)
CREATE OR REPLACE VIEW v_preferred_category AS
SELECT T.Customer_ID, T.Category_Name
FROM (
    SELECT O.Customer_ID,
           C.Category_Name,
           ROW_NUMBER() OVER (PARTITION BY O.Customer_ID
                              ORDER BY SUM(OD.Quantity) DESC, C.Category_ID) AS Category_Pos
    FROM Orders O
    JOIN Order_Details OD ON OD.Order_ID   = O.Order_ID
    JOIN Product P        ON P.Product_ID  = OD.Product_ID
    JOIN Category C       ON C.Category_ID = P.Category_ID
    WHERE O.Order_Status = 'Completed'
    GROUP BY O.Customer_ID, C.Category_ID, C.Category_Name
) T
WHERE T.Category_Pos = 1;

-- Customer segments (the business rule lives here, in one place)
--   Premium    : at least 10 orders AND spending of Rs 100,000 or more
--   Regular    : 5 or more orders
--   Low Value  : 1 to 4 orders
--   Inactive   : no completed orders
-- Duplicate customer rows (same e-mail) are left out.
CREATE OR REPLACE VIEW v_customer_segments AS
SELECT C.Customer_ID,
       C.Customer_Name,
       COALESCE(V.Total_Spending, 0)     AS Total_Purchase,
       COALESCE(V.Total_Orders, 0)       AS Total_Orders,
       COALESCE(V.Purchase_Frequency, 0) AS Purchase_Frequency,
       V.Last_Order_Date,
       CASE
           WHEN COALESCE(V.Total_Orders, 0) >= 10
            AND COALESCE(V.Total_Spending, 0) >= 100000 THEN 'Premium'
           WHEN COALESCE(V.Total_Orders, 0) >= 5        THEN 'Regular'
           WHEN COALESCE(V.Total_Orders, 0) >= 1        THEN 'Low Value'
           ELSE 'Inactive'
       END AS Segment
FROM Customer C
LEFT JOIN v_customer_orders V ON V.Customer_ID = C.Customer_ID
WHERE C.Customer_ID IN (
    SELECT MIN(Customer_ID) FROM Customer GROUP BY LOWER(TRIM(Email))
);

-- ============================================================
-- TASK 1: ANALYTICAL REPORTS USING SQL
-- ============================================================

-- ---------- 1A. SALES PERFORMANCE REPORT ----------
-- Total sales, number of orders, average order value
SELECT SUM(Total_Amount)           AS Total_Sales,
       COUNT(*)                    AS Number_of_Orders,
       ROUND(AVG(Total_Amount), 2) AS Average_Order_Value
FROM Orders
WHERE Order_Status = 'Completed';

-- Monthly revenue with a running (cumulative) total
SELECT M.Sales_Month,
       M.Order_Count,
       M.Monthly_Revenue,
       SUM(M.Monthly_Revenue) OVER (ORDER BY M.Sales_Month) AS Running_Revenue
FROM (
    SELECT DATE_FORMAT(Order_Date, '%Y-%m') AS Sales_Month,
           COUNT(*)                         AS Order_Count,
           SUM(Total_Amount)                AS Monthly_Revenue
    FROM Orders
    WHERE Order_Status = 'Completed'
    GROUP BY DATE_FORMAT(Order_Date, '%Y-%m')
) M
ORDER BY M.Sales_Month;

-- ---------- 1B. CUSTOMER ANALYSIS REPORT ----------
SELECT C.Customer_Name,
       V.Total_Spending   AS Total_Purchases,
       V.Total_Orders     AS Number_of_Orders,
       V.Last_Order_Date  AS Last_Purchase_Date
FROM v_customer_orders V
JOIN Customer C ON C.Customer_ID = V.Customer_ID
ORDER BY V.Total_Spending DESC;

-- ---------- 1C. PRODUCT PERFORMANCE REPORT ----------
SELECT P.Product_Name,
       SUM(OD.Quantity)            AS Quantity_Sold,
       SUM(OD.Quantity * OD.Price) AS Revenue_Generated,
       RANK() OVER (ORDER BY SUM(OD.Quantity * OD.Price) DESC) AS Revenue_Rank
FROM Order_Details OD
JOIN Orders O  ON O.Order_ID   = OD.Order_ID AND O.Order_Status = 'Completed'
JOIN Product P ON P.Product_ID = OD.Product_ID
GROUP BY P.Product_ID, P.Product_Name
ORDER BY Revenue_Rank;

-- ============================================================
-- TASK 2: WINDOW FUNCTIONS (RANK, ROW_NUMBER, DENSE_RANK)
-- ============================================================
-- RANK()       : equal values share a rank, the next rank is skipped (1,2,2,4)
-- DENSE_RANK() : equal values share a rank, no rank is skipped      (1,2,2,3)
-- ROW_NUMBER() : always unique numbers, ties are broken arbitrarily (1,2,3,4)

-- ---------- 2.1 RANK PRODUCTS BASED ON SALES ----------
-- The example from the task sheet
SELECT Product_ID,
       SUM(Quantity) AS Total_Sales,
       RANK() OVER (ORDER BY SUM(Quantity) DESC) AS Sales_Rank
FROM Order_Details
GROUP BY Product_ID;

-- Same idea with product names, best-selling product first
SELECT P.Product_Name,
       SUM(OD.Quantity) AS Total_Sales,
       RANK() OVER (ORDER BY SUM(OD.Quantity) DESC) AS Sales_Rank
FROM Order_Details OD
JOIN Product P ON P.Product_ID = OD.Product_ID
GROUP BY P.Product_ID, P.Product_Name
ORDER BY Sales_Rank;

-- Top selling product inside every category (PARTITION BY)
SELECT Q.Category_Name, Q.Product_Name, Q.Revenue, Q.Rank_In_Category
FROM (
    SELECT C.Category_Name,
           P.Product_Name,
           SUM(OD.Quantity * OD.Price) AS Revenue,
           RANK() OVER (PARTITION BY C.Category_Name
                        ORDER BY SUM(OD.Quantity * OD.Price) DESC) AS Rank_In_Category
    FROM Order_Details OD
    JOIN Orders O   ON O.Order_ID    = OD.Order_ID AND O.Order_Status = 'Completed'
    JOIN Product P  ON P.Product_ID  = OD.Product_ID
    JOIN Category C ON C.Category_ID = P.Category_ID
    GROUP BY C.Category_ID, C.Category_Name, P.Product_ID, P.Product_Name
) Q
ORDER BY Q.Category_Name, Q.Rank_In_Category;

-- ---------- 2.2 RANK CUSTOMERS BASED ON PURCHASE AMOUNT ----------
SELECT C.Customer_Name,
       SUM(O.Total_Amount) AS Total_Spent,
       RANK() OVER (ORDER BY SUM(O.Total_Amount) DESC) AS Spending_Rank
FROM Customer C
JOIN Orders O ON O.Customer_ID = C.Customer_ID
WHERE O.Order_Status = 'Completed'
GROUP BY C.Customer_ID, C.Customer_Name
ORDER BY Spending_Rank;

-- Top 5 customers
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

-- RANK vs DENSE_RANK vs ROW_NUMBER on customers with the SAME order count.
-- Look at customers with 3 orders: they tie, so the three functions differ.
SELECT C.Customer_Name,
       COUNT(O.Order_ID) AS Order_Count,
       RANK()       OVER (ORDER BY COUNT(O.Order_ID) DESC) AS Rank_Value,
       DENSE_RANK() OVER (ORDER BY COUNT(O.Order_ID) DESC) AS Dense_Rank_Value,
       ROW_NUMBER() OVER (ORDER BY COUNT(O.Order_ID) DESC, C.Customer_ID) AS Row_Number_Value
FROM Customer C
JOIN Orders O ON O.Customer_ID = C.Customer_ID
WHERE O.Order_Status = 'Completed'
GROUP BY C.Customer_ID, C.Customer_Name
ORDER BY Row_Number_Value;

-- ---------- 2.3 LATEST ORDER SEQUENCE (ROW_NUMBER) ----------
-- Order number of every order, newest order of each customer = 1
SELECT O.Customer_ID,
       C.Customer_Name,
       O.Order_ID,
       O.Order_Date,
       O.Total_Amount,
       ROW_NUMBER() OVER (PARTITION BY O.Customer_ID
                          ORDER BY O.Order_Date DESC, O.Order_ID DESC) AS Order_Sequence
FROM Orders O
JOIN Customer C ON C.Customer_ID = O.Customer_ID
ORDER BY O.Customer_ID, Order_Sequence;

-- Only the latest order of each customer
SELECT L.Customer_Name, L.Order_ID, L.Order_Date, L.Total_Amount
FROM (
    SELECT C.Customer_Name,
           O.Order_ID,
           O.Order_Date,
           O.Total_Amount,
           ROW_NUMBER() OVER (PARTITION BY O.Customer_ID
                              ORDER BY O.Order_Date DESC, O.Order_ID DESC) AS Order_Sequence
    FROM Orders O
    JOIN Customer C ON C.Customer_ID = O.Customer_ID
) L
WHERE L.Order_Sequence = 1
ORDER BY L.Order_Date DESC;

	
SELECT ROW_NUMBER() OVER (ORDER BY Order_Date, Order_ID) AS Order_Number,
       Order_ID, Customer_ID, Order_Date
FROM Orders
ORDER BY Order_Number
LIMIT 10;

-- ============================================================

-- Rules (see v_customer_segments):
--   Premium   = 10+ orders AND spending of Rs 100,000 or more  (High Value)
--   Regular   = 5 or more orders                               (Moderate)
--   Low Value = 1 to 4 orders                                  (Less frequent)
--   Inactive  = no completed orders
-- ============================================================
SELECT Customer_Name AS Customer,
       Total_Purchase,
       Total_Orders  AS Orders,
       Segment
FROM v_customer_segments
ORDER BY FIELD(Segment, 'Premium', 'Regular', 'Low Value', 'Inactive'),
         Total_Purchase DESC;

-- How many customers fall into each segment
SELECT Segment, COUNT(*) AS Customers
FROM v_customer_segments
GROUP BY Segment
ORDER BY FIELD(Segment, 'Premium', 'Regular', 'Low Value', 'Inactive');

-- ============================================================
-- TASK 4: PREPARE THE AI-READY DATASET
-- Pipeline (each step is stored in its own table so you can inspect it):
--   Step 1 Combine tables -> Step 2 Remove duplicates -> Step 3 Handle
--   missing values -> Step 4 Encode categories -> Step 5 Final dataset
-- ============================================================

-- ---------- STEP 1: COMBINE DATA FROM MULTIPLE TABLES ----------
-- Customer + Orders + Order_Details + Product + Category in one row per customer
CREATE TABLE ML_Step1_Combined AS
SELECT C.Customer_ID,
       C.Customer_Name,
       C.Email,
       C.Age,
       V.Total_Orders       AS Total_Purchases,
       V.Total_Spending,
       V.Avg_Order_Value,
       V.Purchase_Frequency,
       V.Last_Order_Date,
       PC.Category_Name     AS Preferred_Category
FROM Customer C
LEFT JOIN v_customer_orders    V  ON V.Customer_ID  = C.Customer_ID
LEFT JOIN v_preferred_category PC ON PC.Customer_ID = C.Customer_ID;

SELECT * FROM ML_Step1_Combined ORDER BY Customer_ID;

-- ---------- STEP 2: REMOVE DUPLICATE RECORDS ----------
-- Same e-mail (ignoring upper/lower case and spaces) = same person.
-- ROW_NUMBER() keeps the row with the lowest Customer_ID.
CREATE TABLE ML_Step2_Deduplicated AS
SELECT D.Customer_ID, D.Customer_Name, D.Email, D.Age,
       D.Total_Purchases, D.Total_Spending, D.Avg_Order_Value,
       D.Purchase_Frequency, D.Last_Order_Date, D.Preferred_Category
FROM (
    SELECT S.*,
           ROW_NUMBER() OVER (PARTITION BY LOWER(TRIM(S.Email))
                              ORDER BY S.Customer_ID) AS Duplicate_Pos
    FROM ML_Step1_Combined S
) D
WHERE D.Duplicate_Pos = 1;

-- Rows that were removed as duplicates (expected: customers 16 and 17)
SELECT S1.Customer_ID, S1.Customer_Name, S1.Email
FROM ML_Step1_Combined S1
WHERE S1.Customer_ID NOT IN (SELECT Customer_ID FROM ML_Step2_Deduplicated);

-- ---------- STEP 3: HANDLE MISSING VALUES ----------
--   Age missing or outside 15..100 -> average age of the valid ages
--   No purchases yet               -> 0 for counts and amounts
--   No preferred category          -> 'Unknown'
CREATE TABLE ML_Step3_Cleaned AS
SELECT D.Customer_ID,
       D.Customer_Name,
       CAST(COALESCE(CASE WHEN D.Age BETWEEN 15 AND 100 THEN D.Age END, A.Avg_Age) AS SIGNED) AS Age,
       COALESCE(D.Total_Purchases, 0)     AS Total_Purchases,
       COALESCE(D.Total_Spending, 0)      AS Total_Spending,
       COALESCE(D.Avg_Order_Value, 0)     AS Average_Order_Value,
       COALESCE(D.Purchase_Frequency, 0)  AS Purchase_Frequency,
       COALESCE(D.Preferred_Category, 'Unknown') AS Preferred_Category
FROM ML_Step2_Deduplicated D
CROSS JOIN (
    SELECT ROUND(AVG(Age)) AS Avg_Age
    FROM ML_Step2_Deduplicated
    WHERE Age BETWEEN 15 AND 100
) A;


-- Label encoding: one integer code per category (0 = Unknown)
-- One-hot encoding: one 0/1 column per category
CREATE TABLE ML_Step4_Encoded AS
SELECT Customer_ID,
       Age,
       Total_Purchases,
       Total_Spending,
       Average_Order_Value,
       Purchase_Frequency,
       Preferred_Category,
       CASE Preferred_Category
            WHEN 'Electronics' THEN 1
            WHEN 'Mobiles'     THEN 2
            WHEN 'Accessories' THEN 3
            WHEN 'Wearables'   THEN 4
            WHEN 'Lifestyle'   THEN 5
            ELSE 0
       END AS Preferred_Category_Code,
       CASE WHEN Preferred_Category = 'Electronics' THEN 1 ELSE 0 END AS Pref_Electronics,
       CASE WHEN Preferred_Category = 'Mobiles'     THEN 1 ELSE 0 END AS Pref_Mobiles,
       CASE WHEN Preferred_Category = 'Accessories' THEN 1 ELSE 0 END AS Pref_Accessories,
       CASE WHEN Preferred_Category = 'Wearables'   THEN 1 ELSE 0 END AS Pref_Wearables,
       CASE WHEN Preferred_Category = 'Lifestyle'   THEN 1 ELSE 0 END AS Pref_Lifestyle
FROM ML_Step3_Cleaned;

-- ---------- STEP 5: FINAL ML-READY DATASET ----------
-- Numeric columns only. Adds min-max scaled copies (0 to 1) and the
-- Segment_Label (3 Premium, 2 Regular, 1 Low Value, 0 Inactive) that a
-- classification model can learn to predict.
CREATE TABLE AI_Customer_Dataset AS
SELECT E.Customer_ID,
       E.Age,
       E.Total_Purchases,
       E.Total_Spending,
       E.Average_Order_Value,
       E.Purchase_Frequency,
       E.Preferred_Category_Code,
       E.Pref_Electronics,
       E.Pref_Mobiles,
       E.Pref_Accessories,
       E.Pref_Wearables,
       E.Pref_Lifestyle,
       ROUND(COALESCE((E.Age - MIN(E.Age) OVER ())
             / NULLIF(MAX(E.Age) OVER () - MIN(E.Age) OVER (), 0), 0), 4) AS Age_Scaled,
       ROUND(COALESCE((E.Total_Purchases - MIN(E.Total_Purchases) OVER ())
             / NULLIF(MAX(E.Total_Purchases) OVER () - MIN(E.Total_Purchases) OVER (), 0), 0), 4) AS Purchases_Scaled,
       ROUND(COALESCE((E.Total_Spending - MIN(E.Total_Spending) OVER ())
             / NULLIF(MAX(E.Total_Spending) OVER () - MIN(E.Total_Spending) OVER (), 0), 0), 4) AS Spending_Scaled,
       CASE S.Segment
            WHEN 'Premium'   THEN 3
            WHEN 'Regular'   THEN 2
            WHEN 'Low Value' THEN 1
            ELSE 0
       END AS Segment_Label
FROM ML_Step4_Encoded E
LEFT JOIN v_customer_segments S ON S.Customer_ID = E.Customer_ID;

ALTER TABLE AI_Customer_Dataset ADD PRIMARY KEY (Customer_ID);

-- The final dataset (export it: result grid -> Export -> CSV)
SELECT * FROM AI_Customer_Dataset ORDER BY Customer_ID;

-- Quality check: no NULL values, no duplicate customers
-- Expected: Total_Rows = Unique_Customers = 15, all Null_ columns = 0
SELECT COUNT(*)                    AS Total_Rows,
       COUNT(DISTINCT Customer_ID) AS Unique_Customers,
       SUM(Age IS NULL)            AS Null_Age,
       SUM(Total_Spending IS NULL) AS Null_Spending,
       SUM(Segment_Label IS NULL)  AS Null_Label,
       MIN(Age)                    AS Min_Age,
       MAX(Age)                    AS Max_Age
FROM AI_Customer_Dataset;

-- ============================================================
-- TASK 5: FEATURE EXTRACTION USING SQL
-- ============================================================

-- ---------- CUSTOMER FEATURES ----------
-- (the example from the task sheet, completed orders only)
SELECT Customer_ID,
       COUNT(Order_ID)             AS Purchase_Count,
       SUM(Total_Amount)           AS Total_Spending,
       ROUND(AVG(Total_Amount), 2) AS Avg_Order_Value,
       MAX(Order_Date)             AS Last_Purchase_Date
FROM Orders
WHERE Order_Status = 'Completed'
GROUP BY Customer_ID
ORDER BY Customer_ID;

-- ---------- PRODUCT FEATURES ----------
-- Average_Rating 0 means the product has no reviews yet
SELECT P.Product_ID,
       P.Product_Name,
       COALESCE(S.Total_Sales_Qty, 0) AS Total_Sales_Qty,
       COALESCE(R.Avg_Rating, 0)      AS Average_Rating,
       COALESCE(S.Revenue, 0)         AS Revenue_Generated,
       COALESCE(I.Stock_Quantity, 0)  AS Stock_Quantity,
       CASE
           WHEN COALESCE(I.Stock_Quantity, 0) = 0 THEN 'Out of Stock'
           WHEN I.Stock_Quantity <= 10            THEN 'Low Stock'
           ELSE 'In Stock'
       END AS Stock_Availability
FROM Product P
LEFT JOIN (
    SELECT OD.Product_ID,
           SUM(OD.Quantity)            AS Total_Sales_Qty,
           SUM(OD.Quantity * OD.Price) AS Revenue
    FROM Order_Details OD
    JOIN Orders O ON O.Order_ID = OD.Order_ID
    WHERE O.Order_Status = 'Completed'
    GROUP BY OD.Product_ID
) S ON S.Product_ID = P.Product_ID
LEFT JOIN (
    SELECT Product_ID, ROUND(AVG(Rating), 2) AS Avg_Rating
    FROM Product_Review
    GROUP BY Product_ID
) R ON R.Product_ID = P.Product_ID
LEFT JOIN Inventory I ON I.Product_ID = P.Product_ID
ORDER BY P.Product_ID;

-- ---------- TIME-BASED FEATURES ----------
-- Year, month, day, quarter, weekday and days since the customer's previous order
SELECT O.Order_ID,
       O.Customer_ID,
       O.Order_Date,
       YEAR(O.Order_Date)    AS Purchase_Year,
       MONTH(O.Order_Date)   AS Purchase_Month,
       DAY(O.Order_Date)     AS Purchase_Day,
       QUARTER(O.Order_Date) AS Purchase_Quarter,
       DAYNAME(O.Order_Date) AS Purchase_Weekday,
       DATEDIFF(O.Order_Date,
                LAG(O.Order_Date) OVER (PARTITION BY O.Customer_ID
                                        ORDER BY O.Order_Date, O.Order_ID)) AS Days_Since_Previous_Order
FROM Orders O
WHERE O.Order_Status = 'Completed'
ORDER BY O.Customer_ID, O.Order_Date, O.Order_ID;

-- Purchase frequency per customer (orders per month)
SELECT V.Customer_ID,
       C.Customer_Name,
       V.Total_Orders,
       V.First_Order_Date,
       V.Last_Order_Date,
       TIMESTAMPDIFF(MONTH, V.First_Order_Date, V.Last_Order_Date) + 1 AS Active_Months,
       V.Purchase_Frequency
FROM v_customer_orders V
JOIN Customer C ON C.Customer_ID = V.Customer_ID
ORDER BY V.Purchase_Frequency DESC, V.Customer_ID;

-- ============================================================
-- BUSINESS INTELLIGENCE REPORTS
-- ============================================================

	-- ---------- REPORT 1: CUSTOMER SEGMENTATION REPORT ----------
	-- Customer category, purchase frequency (orders per month), total spending
SELECT Segment                                    AS Customer_Category,
       COUNT(*)                                   AS Customers,
       ROUND(AVG(Total_Orders), 1)                AS Avg_Orders_Per_Customer,
       ROUND(AVG(Purchase_Frequency), 2)          AS Avg_Purchase_Frequency,
       SUM(Total_Purchase)                        AS Total_Spending,
       ROUND(AVG(Total_Purchase), 2)              AS Avg_Spending_Per_Customer
FROM v_customer_segments
GROUP BY Segment
ORDER BY FIELD(Segment, 'Premium', 'Regular', 'Low Value', 'Inactive');

-- ---------- REPORT 2: SALES RANKING REPORT ----------
-- Product name, total sales (units, completed orders only), revenue, rank
SELECT P.Product_Name,
       SUM(OD.Quantity)            AS Total_Sales,
       SUM(OD.Quantity * OD.Price) AS Revenue,
       RANK() OVER (ORDER BY SUM(OD.Quantity) DESC) AS Sales_Rank
FROM Order_Details OD
JOIN Orders O  ON O.Order_ID   = OD.Order_ID AND O.Order_Status = 'Completed'
JOIN Product P ON P.Product_ID = OD.Product_ID
GROUP BY P.Product_ID, P.Product_Name
ORDER BY Sales_Rank;

-- ---------- REPORT 3: AI DATASET REPORT ----------
-- 3A. Selected features
SELECT 'Customer_ID'          AS Feature, 'Customer'                      AS Source_Table, 'Unique customer identifier'                 AS Description
UNION ALL SELECT 'Age',                  'Customer',                      'Customer age (cleaned)'
UNION ALL SELECT 'Total_Purchases',      'Orders',                        'Number of completed orders'
UNION ALL SELECT 'Total_Spending',       'Orders',                        'Total amount spent'
UNION ALL SELECT 'Average_Order_Value',  'Orders',                        'Total spending divided by orders'
UNION ALL SELECT 'Purchase_Frequency',   'Orders',                        'Orders per month between first and last order'
UNION ALL SELECT 'Preferred_Category',   'Order_Details, Product, Category', 'Most purchased category (encoded as code and one-hot columns)'
UNION ALL SELECT 'Segment_Label',        'v_customer_segments',           'Target label: 3 Premium, 2 Regular, 1 Low Value, 0 Inactive';

-- 3B. Data cleaning steps and how many rows each step touched
SELECT 1 AS Step_No,
       'Combine Customer, Orders, Order_Details, Product and Category' AS Cleaning_Step,
       (SELECT COUNT(*) FROM ML_Step1_Combined) AS Rows_Affected,
       'One row per customer with order totals and preferred category' AS Details
UNION ALL
SELECT 2,
       'Remove duplicate customers (same e-mail, ignoring case and spaces)',
       (SELECT COUNT(*) FROM ML_Step1_Combined) - (SELECT COUNT(*) FROM ML_Step2_Deduplicated),
       'Kept the row with the lowest Customer_ID for every e-mail'
UNION ALL
SELECT 3,
       'Replace missing or invalid Age (valid range 15 to 100) with the average age',
       (SELECT COUNT(*) FROM ML_Step2_Deduplicated WHERE Age IS NULL OR Age NOT BETWEEN 15 AND 100),
       'NULL ages and the impossible age 0'
UNION ALL
SELECT 4,
       'Fill purchase features with 0 and Preferred_Category with Unknown',
       (SELECT COUNT(*) FROM ML_Step2_Deduplicated WHERE Total_Purchases IS NULL),
       'Customers who never completed an order'
UNION ALL
SELECT 5,
       'Encode Preferred_Category (label code plus one-hot columns)',
       (SELECT COUNT(*) FROM ML_Step4_Encoded),
       '6 new numeric columns'
UNION ALL
SELECT 6,
       'Scale numeric features (min-max, 0 to 1) and add Segment_Label',
       (SELECT COUNT(*) FROM AI_Customer_Dataset),
       'Final table: AI_Customer_Dataset';

-- 3C. Final dataset structure
SELECT ORDINAL_POSITION AS Column_No,
       COLUMN_NAME,
       COLUMN_TYPE,
       IS_NULLABLE
FROM information_schema.COLUMNS
WHERE TABLE_SCHEMA = 'ecommerce_bi_db'
  AND TABLE_NAME = 'AI_Customer_Dataset'
ORDER BY ORDINAL_POSITION;

-- ---------- REPORT 4: BUSINESS INSIGHTS SUMMARY ----------
SELECT 'Best-selling product (units)' AS Insight,
       (SELECT P.Product_Name
        FROM Order_Details OD
        JOIN Orders O  ON O.Order_ID = OD.Order_ID AND O.Order_Status = 'Completed'
        JOIN Product P ON P.Product_ID = OD.Product_ID
        GROUP BY P.Product_ID, P.Product_Name
        ORDER BY SUM(OD.Quantity) DESC, P.Product_ID
        LIMIT 1) AS Result
UNION ALL
SELECT 'Highest revenue product',
       (SELECT P.Product_Name
        FROM Order_Details OD
        JOIN Orders O  ON O.Order_ID = OD.Order_ID AND O.Order_Status = 'Completed'
        JOIN Product P ON P.Product_ID = OD.Product_ID
        GROUP BY P.Product_ID, P.Product_Name
        ORDER BY SUM(OD.Quantity * OD.Price) DESC, P.Product_ID
        LIMIT 1)
UNION ALL
SELECT 'Top customer by spending',
       (SELECT Customer_Name FROM v_customer_segments
        ORDER BY Total_Purchase DESC, Customer_ID LIMIT 1)
UNION ALL
SELECT 'Best revenue month',
       (SELECT DATE_FORMAT(Order_Date, '%Y-%m')
        FROM Orders
        WHERE Order_Status = 'Completed'
        GROUP BY DATE_FORMAT(Order_Date, '%Y-%m')
        ORDER BY SUM(Total_Amount) DESC
        LIMIT 1);