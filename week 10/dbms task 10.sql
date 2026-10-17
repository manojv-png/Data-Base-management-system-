-- ============================================================
-- WEEK 10: ADVANCED SQL QUERY SYSTEM (MySQL Workbench Fixed)
-- ============================================================

-- STEP 1: Create and select the database first
-- ============================================================
CREATE DATABASE IF NOT EXISTS ecommerce_db;
USE ecommerce_db;

-- ============================================================
-- STEP 2: Drop tables in correct FK order (safe re-run)
-- ============================================================
DROP TABLE IF EXISTS Order_Details;
DROP TABLE IF EXISTS Orders;
DROP TABLE IF EXISTS Product;
DROP TABLE IF EXISTS Customer;
DROP TABLE IF EXISTS Category;

-- ============================================================
-- STEP 3: CREATE TABLES
-- ============================================================

CREATE TABLE Category (
    Category_ID   INT          PRIMARY KEY,
    Category_Name VARCHAR(100) NOT NULL
);

CREATE TABLE Product (
    Product_ID   INT           PRIMARY KEY,
    Product_Name VARCHAR(100)  NOT NULL,
    Category_ID  INT           NOT NULL,
    Price        DECIMAL(10,2) NOT NULL CHECK (Price >= 0),
    Stock        INT           NOT NULL DEFAULT 0,
    FOREIGN KEY (Category_ID) REFERENCES Category(Category_ID)
);

CREATE TABLE Customer (
    Customer_ID   INT          PRIMARY KEY,
    Customer_Name VARCHAR(100) NOT NULL,
    Email         VARCHAR(100) NOT NULL,
    City          VARCHAR(50)
);

CREATE TABLE Orders (
    Order_ID     INT           PRIMARY KEY,
    Customer_ID  INT           NOT NULL,
    Order_Date   DATE          NOT NULL,
    Total_Amount DECIMAL(10,2) NOT NULL CHECK (Total_Amount >= 0),
    Order_Status VARCHAR(20)   CHECK (Order_Status IN ('Pending','Shipped','Delivered')),
    FOREIGN KEY (Customer_ID) REFERENCES Customer(Customer_ID)
);

CREATE TABLE Order_Details (
    Order_Detail_ID INT           PRIMARY KEY,
    Order_ID        INT           NOT NULL,
    Product_ID      INT           NOT NULL,
    Quantity        INT           NOT NULL CHECK (Quantity > 0),
    Price           DECIMAL(10,2) NOT NULL CHECK (Price >= 0),
    FOREIGN KEY (Order_ID)   REFERENCES Orders(Order_ID),
    FOREIGN KEY (Product_ID) REFERENCES Product(Product_ID)
);

-- ============================================================
-- STEP 4: INSERT SAMPLE DATA
-- ============================================================

INSERT INTO Category VALUES (1,'Electronics');
INSERT INTO Category VALUES (2,'Accessories');
INSERT INTO Category VALUES (3,'Mobile Phones');
INSERT INTO Category VALUES (4,'Appliances');

INSERT INTO Product VALUES (101,'Laptop',         1, 55000.00, 30);
INSERT INTO Product VALUES (102,'Mouse',           2,   500.00,200);
INSERT INTO Product VALUES (103,'Mobile Phone',    3, 20000.00,100);
INSERT INTO Product VALUES (104,'Keyboard',        2,  1500.00,150);
INSERT INTO Product VALUES (105,'Headphones',      2,  2500.00, 80);
INSERT INTO Product VALUES (106,'Smart TV',        1, 45000.00, 20);
INSERT INTO Product VALUES (107,'Washing Machine', 4, 35000.00, 15);
INSERT INTO Product VALUES (108,'Tablet',          3, 25000.00, 50);

INSERT INTO Customer VALUES (1,'Rahul','rahul@mail.com','Chennai');
INSERT INTO Customer VALUES (2,'Priya','priya@mail.com','Mumbai');
INSERT INTO Customer VALUES (3,'Karan','karan@mail.com','Delhi');
INSERT INTO Customer VALUES (4,'Sneha','sneha@mail.com','Pune');
INSERT INTO Customer VALUES (5,'Arun', 'arun@mail.com', 'Hyderabad');
INSERT INTO Customer VALUES (6,'Meena','meena@mail.com','Chennai');

INSERT INTO Orders VALUES (5001,1,'2024-01-10',56000.00,'Delivered');
INSERT INTO Orders VALUES (5002,2,'2024-01-15',20000.00,'Shipped');
INSERT INTO Orders VALUES (5003,3,'2024-01-20', 2000.00,'Delivered');
INSERT INTO Orders VALUES (5004,1,'2024-02-05',21500.00,'Delivered');
INSERT INTO Orders VALUES (5005,4,'2024-02-10',55000.00,'Shipped');
INSERT INTO Orders VALUES (5006,2,'2024-02-20',17500.00,'Delivered');
INSERT INTO Orders VALUES (5007,5,'2024-03-01', 3000.00,'Pending');
INSERT INTO Orders VALUES (5008,1,'2024-03-10',15000.00,'Delivered');
INSERT INTO Orders VALUES (5009,6,'2024-03-15',22500.00,'Delivered');
INSERT INTO Orders VALUES (5010,3,'2024-03-20', 2500.00,'Shipped');
INSERT INTO Orders VALUES (5011,2,'2024-04-01',45000.00,'Delivered');
INSERT INTO Orders VALUES (5012,1,'2024-04-10',35000.00,'Delivered');

INSERT INTO Order_Details VALUES (1, 5001,101,1,55000.00);
INSERT INTO Order_Details VALUES (2, 5001,102,2,  500.00);
INSERT INTO Order_Details VALUES (3, 5002,103,1,20000.00);
INSERT INTO Order_Details VALUES (4, 5003,102,2,  500.00);
INSERT INTO Order_Details VALUES (5, 5003,104,1, 1500.00);
INSERT INTO Order_Details VALUES (6, 5004,103,1,20000.00);
INSERT INTO Order_Details VALUES (7, 5004,104,1, 1500.00);
INSERT INTO Order_Details VALUES (8, 5005,101,1,55000.00);
INSERT INTO Order_Details VALUES (9, 5006,103,1,20000.00);
INSERT INTO Order_Details VALUES (10,5006,105,3, 2500.00);
INSERT INTO Order_Details VALUES (11,5007,102,2,  500.00);
INSERT INTO Order_Details VALUES (12,5007,105,1, 2500.00);
INSERT INTO Order_Details VALUES (13,5008,106,1,15000.00);
INSERT INTO Order_Details VALUES (14,5009,103,1,20000.00);
INSERT INTO Order_Details VALUES (15,5009,104,1, 1500.00);
INSERT INTO Order_Details VALUES (16,5009,105,1, 2500.00);
INSERT INTO Order_Details VALUES (17,5010,105,1, 2500.00);
INSERT INTO Order_Details VALUES (18,5011,106,1,45000.00);
INSERT INTO Order_Details VALUES (19,5012,107,1,35000.00);

-- ============================================================
-- TASK 1: SUBQUERY CONCEPT EXAMPLES
-- ============================================================

-- Single-Row Subquery
SELECT Product_Name, Price
FROM Product
WHERE Price > (SELECT AVG(Price) FROM Product);


SELECT Customer_Name
FROM Customer
WHERE Customer_ID IN (
    SELECT Customer_ID FROM Orders
    WHERE Total_Amount > (SELECT AVG(Total_Amount) FROM Orders)
);

-- Nested Subquery
SELECT Product_Name
FROM Product
WHERE Product_ID IN (
    SELECT DISTINCT Product_ID FROM Order_Details
);

-- ============================================================
-- TASK 2: PRODUCTS ABOVE AVERAGE PRICE
-- ============================================================

-- 2.1 Products above average price
SELECT Product_Name, Price
FROM Product
WHERE Price > (SELECT AVG(Price) FROM Product)
ORDER BY Price DESC;

-- 2.2 Product name, category, price
SELECT P.Product_Name, C.Category_Name, P.Price
FROM Product P
JOIN Category C ON P.Category_ID = C.Category_ID
WHERE P.Price > (SELECT AVG(Price) FROM Product)
ORDER BY P.Price DESC;

-- 2.3 Expensive products within their own category
SELECT P.Product_Name, C.Category_Name, P.Price
FROM Product P
JOIN Category C ON P.Category_ID = C.Category_ID
WHERE P.Price > (
    SELECT AVG(P2.Price)
    FROM Product P2
    WHERE P2.Category_ID = P.Category_ID
)
ORDER BY C.Category_Name, P.Price DESC;

-- 2.4 Products above Electronics category average
SELECT P.Product_Name, C.Category_Name, P.Price
FROM Product P
JOIN Category C ON P.Category_ID = C.Category_ID
WHERE P.Price > (
    SELECT AVG(P2.Price)
    FROM Product P2
    WHERE P2.Category_ID = (
        SELECT Category_ID FROM Category WHERE Category_Name = 'Electronics'
    )
)
ORDER BY P.Price DESC;

-- ============================================================
-- TASK 3: CUSTOMERS WITH MAXIMUM PURCHASES
-- ============================================================

-- 3.1 Highest spending customer
SELECT C.Customer_Name, SUM(O.Total_Amount) AS Total_Spending
FROM Customer C
JOIN Orders O ON C.Customer_ID = O.Customer_ID
GROUP BY C.Customer_ID, C.Customer_Name
HAVING SUM(O.Total_Amount) = (
    SELECT MAX(ts) FROM (
        SELECT SUM(Total_Amount) AS ts
        FROM Orders GROUP BY Customer_ID
   
 ) AS MaxSub
);
-- 3.2 Customer with maximum number of orders
SELECT C.Customer_Name, COUNT(O.Order_ID) AS Total_Orders
FROM Customer C
JOIN Orders O ON C.Customer_ID = O.Customer_ID
GROUP BY C.Customer_ID, C.Customer_Name
HAVING COUNT(O.Order_ID) = (
    SELECT MAX(oc) FROM (
        SELECT COUNT(Order_ID) AS oc
        FROM Orders GROUP BY Customer_ID
    ) AS MaxCount
);

-- 3.3 Customers spending above average
SELECT C.Customer_Name, SUM(O.Total_Amount) AS Total_Spending
FROM Customer C
JOIN Orders O ON C.Customer_ID = O.Customer_ID
GROUP BY C.Customer_ID, C.Customer_Name
HAVING SUM(O.Total_Amount) > (
    SELECT AVG(ct) FROM (
        SELECT SUM(Total_Amount) AS ct
        FROM Orders GROUP BY Customer_ID
    ) AS AvgSub
)
ORDER BY Total_Spending DESC;

-- 3.4 Top 5 valuable customers
SELECT C.Customer_Name,
       COUNT(O.Order_ID)   AS Total_Orders,
       SUM(O.Total_Amount) AS Total_Spending
FROM Customer C
JOIN Orders O ON C.Customer_ID = O.Customer_ID
GROUP BY C.Customer_ID, C.Customer_Name
ORDER BY Total_Spending DESC
LIMIT 5;

-- ============================================================
-- TASK 4: COMPLEX BUSINESS QUERIES
-- ============================================================

-- Q1: Best-Selling Product
SELECT P.Product_Name,
       SUM(OD.Quantity)            AS Total_Quantity_Sold,
       SUM(OD.Quantity * OD.Price) AS Total_Revenue_Generated
FROM Product P
JOIN Order_Details OD ON P.Product_ID = OD.Product_ID
GROUP BY P.Product_ID, P.Product_Name
ORDER BY Total_Quantity_Sold DESC;

-- Q2: High-Value Customers
SELECT C.Customer_Name, SUM(O.Total_Amount) AS Total_Purchase
FROM Customer C
JOIN Orders O ON C.Customer_ID = O.Customer_ID
GROUP BY C.Customer_ID, C.Customer_Name
HAVING SUM(O.Total_Amount) > (
    SELECT AVG(ct) FROM (
        SELECT SUM(Total_Amount) AS ct
        FROM Orders GROUP BY Customer_ID
    ) AS Sub
)
ORDER BY Total_Purchase DESC;

-- Q3: Category Performance Analysis
SELECT C.Category_Name,
       SUM(OD.Quantity)            AS Total_Products_Sold,
       SUM(OD.Quantity * OD.Price) AS Total_Revenue,
       AVG(P.Price)                AS Avg_Product_Price
FROM Category C
JOIN Product P        ON C.Category_ID = P.Category_ID
JOIN Order_Details OD ON P.Product_ID  = OD.Product_ID
GROUP BY C.Category_ID, C.Category_Name
ORDER BY Total_Revenue DESC;

-- Q4: Customer Purchase History + Most Purchased Product
SELECT C.Customer_Name,
       COUNT(DISTINCT O.Order_ID)  AS Number_Of_Orders,
       SUM(O.Total_Amount)         AS Total_Purchase_Amount,
       (
           SELECT P.Product_Name
           FROM Order_Details OD2
           JOIN Orders O2 ON OD2.Order_ID   = O2.Order_ID
           JOIN Product P ON OD2.Product_ID = P.Product_ID
           WHERE O2.Customer_ID = C.Customer_ID
           GROUP BY P.Product_ID, P.Product_Name
           ORDER BY SUM(OD2.Quantity) DESC
           LIMIT 1
       ) AS Most_Purchased_Product
FROM Customer C
JOIN Orders O ON C.Customer_ID = O.Customer_ID
GROUP BY C.Customer_ID, C.Customer_Name
ORDER BY Total_Purchase_Amount DESC;

-- ============================================================
-- TASK 5: ADVANCED REPORTS
-- ============================================================

-- Report 1: Premium Product Report
SELECT P.Product_Name,
       C.Category_Name AS Category,
       P.Price,
       P.Stock         AS Stock_Availability
FROM Product P
JOIN Category C ON P.Category_ID = C.Category_ID
WHERE P.Price > (SELECT AVG(Price) FROM Product)
ORDER BY P.Price DESC;

-- Report 2: Customer Value Report
SELECT C.Customer_Name,
       COUNT(O.Order_ID)   AS Total_Orders,
       SUM(O.Total_Amount) AS Total_Spending,
       CASE
           WHEN SUM(O.Total_Amount) >= 100000 THEN 'Premium'
           WHEN SUM(O.Total_Amount) >=  50000 THEN 'Regular'
           ELSE                                    'Occasional'
       END AS Customer_Category
FROM Customer C
JOIN Orders O ON C.Customer_ID = O.Customer_ID
GROUP BY C.Customer_ID, C.Customer_Name
ORDER BY Total_Spending DESC;

-- Report 3: Sales Performance with RANK
SELECT Product_Name,
       Category_Name,
       Total_Quantity_Sold,
       Product_Revenue,
       RANK() OVER (ORDER BY Total_Quantity_Sold DESC) AS Sales_Rank
FROM (
    SELECT P.Product_Name,
           C.Category_Name,
           SUM(OD.Quantity)            AS Total_Quantity_Sold,
           SUM(OD.Quantity * OD.Price) AS Product_Revenue
    FROM Product P
    JOIN Category C       ON P.Category_ID = C.Category_ID
    JOIN Order_Details OD ON P.Product_ID  = OD.Product_ID
    GROUP BY P.Product_ID, P.Product_Name, C.Category_Name
) AS SalesSub
ORDER BY Product_Revenue DESC;

-- Report 4A: High-Performing Products
SELECT P.Product_Name,
       SUM(OD.Quantity * OD.Price) AS Total_Revenue,
       'High Performing'           AS Performance_Label
FROM Product P
JOIN Order_Details OD ON P.Product_ID = OD.Product_ID
GROUP BY P.Product_ID, P.Product_Name
HAVING SUM(OD.Quantity * OD.Price) > (
    SELECT AVG(pr) FROM (
        SELECT SUM(OD2.Quantity * OD2.Price) AS pr
        FROM Order_Details OD2
        GROUP BY OD2.Product_ID
    ) AS RevSub
)
ORDER BY Total_Revenue DESC;

-- Report 4B: Low-Performing Products
SELECT P.Product_Name,
       SUM(OD.Quantity * OD.Price) AS Total_Revenue,
       'Needs Promotion'           AS Performance_Label
FROM Product P
JOIN Order_Details OD ON P.Product_ID = OD.Product_ID
GROUP BY P.Product_ID, P.Product_Name
HAVING SUM(OD.Quantity * OD.Price) < (
    SELECT AVG(pr) FROM (
        SELECT SUM(OD2.Quantity * OD2.Price) AS pr
        FROM Order_Details OD2
        GROUP BY OD2.Product_ID
    ) AS RevSub
)
ORDER BY Total_Revenue ASC;

-- Report 4C: Monthly Revenue Trends
SELECT DATE_FORMAT(Order_Date, '%Y-%m') AS Month,
       COUNT(Order_ID)                  AS Total_Orders,
       SUM(Total_Amount)                AS Monthly_Revenue,
       AVG(Total_Amount)                AS Avg_Order_Value
FROM Orders
GROUP BY DATE_FORMAT(Order_Date, '%Y-%m')
ORDER BY Month ASC;