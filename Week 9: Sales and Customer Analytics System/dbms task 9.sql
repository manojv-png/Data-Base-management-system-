-- =====================================================================
-- Week 9: Sales and Customer Analytics System
-- SQL Aggregate Functions: COUNT, SUM, AVG, MIN, MAX
-- Database: E-Commerce (MySQL syntax)
--
-- ASSUMED SCHEMA (rename columns if yours differ):
--   Customer(Customer_ID, Customer_Name, ...)
--   Orders(Order_ID, Customer_ID, Order_Date, Total_Amount)
--   Order_Details(Order_ID, Product_ID, Quantity)
--   Product(Product_ID, Product_Name, Price, Category_ID)
--   Category(Category_ID, Category_Name)
-- =====================================================================


-- =====================================================================
-- 2. GENERATE TOTAL SALES REPORTS
-- =====================================================================

-- 2.1 Total number of orders placed
SELECT COUNT(Order_ID) AS Total_Orders
FROM Orders;

-- 2.2 Total revenue generated from sales
SELECT SUM(Total_Amount) AS Total_Revenue
FROM Orders;

-- 2.3 Average order value
SELECT AVG(Total_Amount) AS Average_Order_Value
FROM Orders;

-- 2.4 Highest and lowest order amount
SELECT MAX(Total_Amount) AS Highest_Order_Amount,
       MIN(Total_Amount) AS Lowest_Order_Amount
FROM Orders;

-- 2.5 Total sales for a specific period (change the dates as needed)
SELECT SUM(Total_Amount) AS Total_Sales_For_Period
FROM Orders
WHERE Order_Date BETWEEN '2025-01-01' AND '2025-12-31';

-- Expected Report (Total Orders, Total Revenue, Average Order Value)
SELECT COUNT(Order_ID)    AS Total_Orders,
       SUM(Total_Amount)  AS Total_Revenue,
       AVG(Total_Amount)  AS Average_Order_Value
FROM Orders;


-- =====================================================================
-- 3. CUSTOMER PURCHASE ANALYSIS
-- =====================================================================

-- 3.1 Total number of orders placed by each customer
SELECT Customer_ID,
       COUNT(Order_ID) AS Total_Orders
FROM Orders
GROUP BY Customer_ID;

-- 3.2 Total amount spent by each customer
SELECT Customer_ID,
       SUM(Total_Amount) AS Total_Spending
FROM Orders
GROUP BY Customer_ID;

-- 3.3 Average spending per customer
SELECT Customer_ID,
       AVG(Total_Amount) AS Average_Spending
FROM Orders
GROUP BY Customer_ID;

-- 3.4 Customers with maximum purchase amount
SELECT Customer_ID,
       MAX(Total_Amount) AS Max_Purchase_Amount
FROM Orders
GROUP BY Customer_ID
ORDER BY Max_Purchase_Amount DESC;

-- 3.5 Customers with fewer purchases (fewest orders first)
SELECT Customer_ID,
       COUNT(Order_ID) AS Total_Orders
FROM Orders
GROUP BY Customer_ID
ORDER BY Total_Orders ASC
LIMIT 5;


-- =====================================================================
-- 4. FIND TOP CUSTOMERS BASED ON PURCHASE AMOUNT
-- =====================================================================

-- 4.1 Top 5 customers based on total spending
SELECT Customer_ID,
       SUM(Total_Amount) AS Spending
FROM Orders
GROUP BY Customer_ID
ORDER BY Spending DESC
LIMIT 5;

-- 4.2 Customers with maximum number of orders
SELECT Customer_ID,
       COUNT(Order_ID) AS Total_Orders
FROM Orders
GROUP BY Customer_ID
ORDER BY Total_Orders DESC
LIMIT 5;

-- 4.3 Frequent customers (placed more than 3 orders; adjust threshold)
SELECT Customer_ID,
       COUNT(Order_ID) AS Order_Count
FROM Orders
GROUP BY Customer_ID
HAVING COUNT(Order_ID) > 3
ORDER BY Order_Count DESC;

-- 4.4 High-value customers (total spending above the average customer spending)
SELECT Customer_ID,
       SUM(Total_Amount) AS Total_Spending
FROM Orders
GROUP BY Customer_ID
HAVING SUM(Total_Amount) > (
        SELECT AVG(Customer_Total)
        FROM (SELECT SUM(Total_Amount) AS Customer_Total
              FROM Orders
              GROUP BY Customer_ID) AS t
      )
ORDER BY Total_Spending DESC;


-- =====================================================================
-- 5. IDENTIFY BEST-SELLING PRODUCTS
-- =====================================================================

-- 5.1 Products with maximum sales quantity
SELECT Product_ID,
       SUM(Quantity) AS Total_Sold
FROM Order_Details
GROUP BY Product_ID
ORDER BY Total_Sold DESC;

-- 5.2 Products generating highest revenue
SELECT p.Product_ID,
       p.Product_Name,
       SUM(p.Price * od.Quantity) AS Revenue
FROM Product p
JOIN Order_Details od ON p.Product_ID = od.Product_ID
GROUP BY p.Product_ID, p.Product_Name
ORDER BY Revenue DESC
LIMIT 5;

-- 5.3 Least-selling products
SELECT Product_ID,
       SUM(Quantity) AS Total_Sold
FROM Order_Details
GROUP BY Product_ID
ORDER BY Total_Sold ASC
LIMIT 5;

-- 5.4 Products requiring promotion (sold below the average quantity per product)
SELECT p.Product_ID,
       p.Product_Name,
       SUM(od.Quantity) AS Total_Sold
FROM Product p
JOIN Order_Details od ON p.Product_ID = od.Product_ID
GROUP BY p.Product_ID, p.Product_Name
HAVING SUM(od.Quantity) < (
        SELECT AVG(Product_Total)
        FROM (SELECT SUM(Quantity) AS Product_Total
              FROM Order_Details
              GROUP BY Product_ID) AS t
      )
ORDER BY Total_Sold ASC;


-- =====================================================================
-- 6. CATEGORY-WISE SALES ANALYSIS
-- =====================================================================

-- 6.1 Total sales generated by each category
SELECT Category_ID,
       SUM(Price * Quantity) AS Category_Sales
FROM Product
JOIN Order_Details
  ON Product.Product_ID = Order_Details.Product_ID
GROUP BY Category_ID;

-- 6.2 Number of products sold in each category
SELECT Category_ID,
       SUM(Quantity) AS Total_Products_Sold
FROM Product
JOIN Order_Details
  ON Product.Product_ID = Order_Details.Product_ID
GROUP BY Category_ID;

-- 6.3 Highest revenue-generating category
SELECT Category_ID,
       SUM(Price * Quantity) AS Category_Sales
FROM Product
JOIN Order_Details
  ON Product.Product_ID = Order_Details.Product_ID
GROUP BY Category_ID
ORDER BY Category_Sales DESC
LIMIT 1;

-- 6.4 Average sales per category
SELECT Category_ID,
       AVG(Price * Quantity) AS Average_Category_Sales
FROM Product
JOIN Order_Details
  ON Product.Product_ID = Order_Details.Product_ID
GROUP BY Category_ID;


-- =====================================================================
-- 7. BUSINESS ANALYTICS REPORTS
-- =====================================================================

-- Report 1: Sales Performance Report
SELECT SUM(Total_Amount)  AS Total_Sales,
       COUNT(Order_ID)    AS Number_of_Orders,
       AVG(Total_Amount)  AS Average_Order_Value,
       MAX(Total_Amount)  AS Highest_Order_Value
FROM Orders;

-- Report 2: Customer Analytics Report
SELECT c.Customer_Name,
       COUNT(o.Order_ID)    AS Number_of_Orders,
       SUM(o.Total_Amount)  AS Total_Spending,
       COUNT(o.Order_ID)    AS Purchase_Frequency
FROM Customer c
JOIN Orders o ON c.Customer_ID = o.Customer_ID
GROUP BY c.Customer_ID, c.Customer_Name
ORDER BY Total_Spending DESC;

-- Report 3: Product Performance Report
SELECT p.Product_Name,
       SUM(od.Quantity)            AS Quantity_Sold,
       SUM(p.Price * od.Quantity)  AS Revenue_Generated
FROM Product p
JOIN Order_Details od ON p.Product_ID = od.Product_ID
GROUP BY p.Product_ID, p.Product_Name
ORDER BY Revenue_Generated DESC;

-- Report 4: Category Analysis Report
SELECT cat.Category_Name,
       SUM(od.Quantity)            AS Total_Products_Sold,
       SUM(p.Price * od.Quantity)  AS Total_Revenue
FROM Category cat
JOIN Product p        ON cat.Category_ID = p.Category_ID
JOIN Order_Details od ON p.Product_ID   = od.Product_ID
GROUP BY cat.Category_ID, cat.Category_Name
ORDER BY Total_Revenue DESC;