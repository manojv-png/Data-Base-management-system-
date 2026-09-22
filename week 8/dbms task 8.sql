/* =========================================================
   WEEK 8: DATABASE RELATIONSHIP ANALYSIS USING JOINS
   E-COMMERCE DATABASE
   ========================================================= */


/* =========================================================
   1. CREATE DATABASE
   ========================================================= */

DROP DATABASE IF EXISTS EcommerceDB;

CREATE DATABASE EcommerceDB;

USE EcommerceDB;


/* =========================================================
   2. CREATE CUSTOMER TABLE
   ========================================================= */

CREATE TABLE Customer (
    Customer_ID INT PRIMARY KEY,
    Customer_Name VARCHAR(100) NOT NULL,
    Email VARCHAR(100),
    City VARCHAR(50)
);


/* =========================================================
   3. CREATE PRODUCT TABLE
   ========================================================= */

CREATE TABLE Product (
    Product_ID INT PRIMARY KEY,
    Product_Name VARCHAR(100) NOT NULL,
    Price DECIMAL(10,2),
    Category_ID INT
);


/* =========================================================
   4. CREATE ORDERS TABLE
   ========================================================= */

CREATE TABLE Orders (
    Order_ID INT PRIMARY KEY,
    Customer_ID INT,
    Order_Date DATE,
    Total_Amount DECIMAL(10,2),
    Order_Status VARCHAR(30),

    FOREIGN KEY (Customer_ID)
        REFERENCES Customer(Customer_ID)
);


/* =========================================================
   5. CREATE ORDER_ITEMS TABLE
   This table connects Orders and Products
   ========================================================= */

CREATE TABLE Order_Items (
    Order_Item_ID INT PRIMARY KEY AUTO_INCREMENT,
    Order_ID INT,
    Product_ID INT,
    Quantity INT,

    FOREIGN KEY (Order_ID)
        REFERENCES Orders(Order_ID),

    FOREIGN KEY (Product_ID)
        REFERENCES Product(Product_ID)
);


/* =========================================================
   6. CREATE PAYMENT TABLE
   ========================================================= */

CREATE TABLE Payment (
    Payment_ID INT PRIMARY KEY,
    Order_ID INT,
    Payment_Mode VARCHAR(30),
    Payment_Status VARCHAR(30),

    FOREIGN KEY (Order_ID)
        REFERENCES Orders(Order_ID)
);


/* =========================================================
   7. INSERT CUSTOMER DATA
   ========================================================= */

INSERT INTO Customer
(Customer_ID, Customer_Name, Email, City)
VALUES
(1, 'Arun', 'arun@gmail.com', 'Chennai'),
(2, 'Priya', 'priya@gmail.com', 'Coimbatore'),
(3, 'Karthik', 'karthik@gmail.com', 'Madurai'),
(4, 'Divya', 'divya@gmail.com', 'Salem'),
(5, 'Rahul', 'rahul@gmail.com', 'Chennai');


/* =========================================================
   8. INSERT PRODUCT DATA
   ========================================================= */

INSERT INTO Product
(Product_ID, Product_Name, Price, Category_ID)
VALUES
(101, 'Laptop', 55000, 1),
(102, 'Mobile', 30000, 2),
(103, 'Headphones', 2500, 3),
(104, 'Keyboard', 1500, 3),
(105, 'Mouse', 800, 3);


/* =========================================================
   9. INSERT ORDER DATA
   ========================================================= */

INSERT INTO Orders
(Order_ID, Customer_ID, Order_Date, Total_Amount, Order_Status)
VALUES
(1001, 1, '2026-09-01', 55000, 'Delivered'),
(1002, 2, '2026-09-03', 30000, 'Delivered'),
(1003, 1, '2026-09-05', 2500, 'Shipped'),
(1004, 3, '2026-09-07', 1500, 'Pending');


/* =========================================================
   10. INSERT ORDER ITEMS DATA
   ========================================================= */

INSERT INTO Order_Items
(Order_ID, Product_ID, Quantity)
VALUES
(1001, 101, 1),
(1002, 102, 1),
(1003, 103, 1),
(1004, 104, 1);


/* =========================================================
   11. INSERT PAYMENT DATA
   ========================================================= */

INSERT INTO Payment
(Payment_ID, Order_ID, Payment_Mode, Payment_Status)
VALUES
(501, 1001, 'UPI', 'Success'),
(502, 1002, 'Card', 'Success'),
(503, 1003, 'UPI', 'Success'),
(504, 1004, 'Cash', 'Pending');


/* =========================================================
   12. DISPLAY ALL TABLES
   ========================================================= */

SELECT * FROM Customer;

SELECT * FROM Product;



SELECT * FROM Order_Items;

SELECT * FROM Payment;


/* =========================================================
   13. INNER JOIN
   Display customer details along with their orders
   ========================================================= */

SELECT
    Customer.Customer_Name,
    Orders.Order_ID,
    Orders.Order_Date,
    Orders.Total_Amount,
    Orders.Order_Status
FROM Customer
INNER JOIN Orders
ON Customer.Customer_ID = Orders.Customer_ID;


/* =========================================================
   14. INNER JOIN
   Display order details with payment information
   ========================================================= */

SELECT
    Orders.Order_ID,
    Orders.Order_Date,
    Orders.Total_Amount,
    Payment.Payment_Mode,
    Payment.Payment_Status
FROM Orders
INNER JOIN Payment
ON Orders.Order_ID = Payment.Order_ID;


/* =========================================================
   15. INNER JOIN
   Retrieve products purchased by customers
   ========================================================= */

SELECT
    Customer.Customer_Name,
    Orders.Order_ID,
    Product.Product_Name,
    Order_Items.Quantity,
    Product.Price
FROM Customer
INNER JOIN Orders
    ON Customer.Customer_ID = Orders.Customer_ID
INNER JOIN Order_Items
    ON Orders.Order_ID = Order_Items.Order_ID
INNER JOIN Product
    ON Order_Items.Product_ID = Product.Product_ID;


/* =========================================================
   16. LEFT JOIN
   Display all customers including customers
   who have not placed orders
   ========================================================= */

SELECT
    Customer.Customer_ID,
    Customer.Customer_Name,
    Orders.Order_ID,
    Orders.Order_Date,
    Orders.Total_Amount
FROM Customer
LEFT JOIN Orders
ON Customer.Customer_ID = Orders.Customer_ID;


/* =========================================================
   17. LEFT JOIN
   Find customers without purchases
   ========================================================= */

SELECT
    Customer.Customer_ID,
    Customer.Customer_Name,
    Customer.Email
FROM Customer
LEFT JOIN Orders
ON Customer.Customer_ID = Orders.Customer_ID
WHERE Orders.Order_ID IS NULL;


/* =========================================================
   18. LEFT JOIN
   Display all products including products with no sales
   ========================================================= */

SELECT
    Product.Product_ID,
    Product.Product_Name,
    Product.Price,
    Order_Items.Order_ID,
    Order_Items.Quantity
FROM Product
LEFT JOIN Order_Items
ON Product.Product_ID = Order_Items.Product_ID;


/* =========================================================
   19. RIGHT JOIN
   Display all orders with customer information
   ========================================================= */

SELECT
    Customer.Customer_Name,
    Orders.Order_ID,
    Orders.Order_Date,
    Orders.Total_Amount
FROM Customer
RIGHT JOIN Orders
ON Customer.Customer_ID = Orders.Customer_ID;


/* =========================================================
   20. RIGHT JOIN
   Find orders where customer details are missing
   ========================================================= */

SELECT
    Orders.Order_ID,
    Orders.Order_Date,
    Orders.Total_Amount
FROM Customer
RIGHT JOIN Orders
ON Customer.Customer_ID = Orders.Customer_ID
WHERE Customer.Customer_ID IS NULL;


/* =========================================================
   21. RIGHT JOIN
   Display all payments with order details
   ========================================================= */

SELECT
    Payment.Payment_ID,
    Payment.Order_ID,
    Payment.Payment_Mode,
    Payment.Payment_Status,
    Orders.Order_Date,
    Orders.Total_Amount
FROM Orders
RIGHT JOIN Payment
ON Orders.Order_ID = Payment.Order_ID;


/* =========================================================
   22. COMPLETE ORDER DETAILS
   Customer + Product + Quantity + Date +
   Amount + Payment Status
   ========================================================= */

SELECT
    Customer.Customer_Name,
    Product.Product_Name,
    Order_Items.Quantity,
    Orders.Order_Date,
    Orders.Total_Amount,
    Payment.Payment_Status
FROM Customer
INNER JOIN Orders
    ON Customer.Customer_ID = Orders.Customer_ID
INNER JOIN Order_Items
    ON Orders.Order_ID = Order_Items.Order_ID
INNER JOIN Product
    ON Order_Items.Product_ID = Product.Product_ID
INNER JOIN Payment
    ON Orders.Order_ID = Payment.Order_ID;


/* =========================================================
   23. CUSTOMER PURCHASE HISTORY
   All products purchased by each customer
   ========================================================= */

SELECT
    Customer.Customer_Name,
    Product.Product_Name,
    Order_Items.Quantity,
    Orders.Order_Date
FROM Customer
INNER JOIN Orders
    ON Customer.Customer_ID = Orders.Customer_ID
INNER JOIN Order_Items
    ON Orders.Order_ID = Order_Items.Order_ID
INNER JOIN Product
    ON Order_Items.Product_ID = Product.Product_ID
ORDER BY Customer.Customer_Name;


/* =========================================================
   24. TOTAL AMOUNT SPENT BY EACH CUSTOMER
   ========================================================= */

SELECT
    Customer.Customer_Name,
    SUM(Orders.Total_Amount) AS Total_Spent
FROM Customer
INNER JOIN Orders
ON Customer.Customer_ID = Orders.Customer_ID
GROUP BY Customer.Customer_ID, Customer.Customer_Name;


/* =========================================================
   25. NUMBER OF ORDERS PLACED BY EACH CUSTOMER
   ========================================================= */

SELECT
    Customer.Customer_Name,
    COUNT(Orders.Order_ID) AS Total_Orders
FROM Customer
LEFT JOIN Orders
ON Customer.Customer_ID = Orders.Customer_ID
GROUP BY Customer.Customer_ID, Customer.Customer_Name;


/* =========================================================
   26. LATEST PURCHASE DETAILS OF CUSTOMERS
   ========================================================= */

SELECT
    Customer.Customer_Name,
    Orders.Order_ID,
    Orders.Order_Date,
    Orders.Total_Amount
FROM Customer
INNER JOIN Orders
ON Customer.Customer_ID = Orders.Customer_ID
WHERE Orders.Order_Date = (
    SELECT MAX(O2.Order_Date)
    FROM Orders O2
    WHERE O2.Customer_ID = Customer.Customer_ID
);


/* =========================================================
   27. REPORT 1 – CUSTOMER ORDER REPORT
   ========================================================= */

SELECT
    Customer.Customer_Name,
    Orders.Order_ID,
    Orders.Order_Date,
    Orders.Order_Status
FROM Customer
INNER JOIN Orders
ON Customer.Customer_ID = Orders.Customer_ID;


/* =========================================================
   28. REPORT 2 – SALES REPORT
   Product name + Quantity sold + Total revenue
   ========================================================= */

SELECT
    Product.Product_Name,
    SUM(Order_Items.Quantity) AS Quantity_Sold,
    SUM(Order_Items.Quantity * Product.Price) AS Total_Revenue
FROM Product
INNER JOIN Order_Items
ON Product.Product_ID = Order_Items.Product_ID
GROUP BY Product.Product_ID, Product.Product_Name;


/* =========================================================
   29. REPORT 3 – PAYMENT ANALYSIS REPORT
   ========================================================= */

SELECT
    Payment_Mode,
    COUNT(Payment_ID) AS Number_of_Transactions,
    SUM(
        CASE
            WHEN Payment_Status = 'Success'
            THEN 1
            ELSE 0
        END
    ) AS Successful_Payments
FROM Payment
GROUP BY Payment_Mode;


/* =========================================================
   30. REPORT 4 – TOP PURCHASING CUSTOMERS
   ========================================================= */

SELECT
    Customer.Customer_Name,
    SUM(Orders.Total_Amount) AS Total_Spending
FROM Customer
INNER JOIN Orders
ON Customer.Customer_ID = Orders.Customer_ID
GROUP BY Customer.Customer_ID, Customer.Customer_Name
ORDER BY Total_Spending DESC;


/* =========================================================
   31. CUSTOMERS WITH MAXIMUM ORDERS
   ========================================================= */

SELECT
    Customer.Customer_Name,
    COUNT(Orders.Order_ID) AS Total_Orders
FROM Customer
INNER JOIN Orders
ON Customer.Customer_ID = Orders.Customer_ID
GROUP BY Customer.Customer_ID, Customer.Customer_Name
ORDER BY Total_Orders DESC;


/* =========================================================
   32. CUSTOMERS WITH HIGHEST SPENDING
   ========================================================= */

SELECT
    Customer.Customer_Name,
    SUM(Orders.Total_Amount) AS Total_Spending
FROM Customer
INNER JOIN Orders
ON Customer.Customer_ID = Orders.Customer_ID
GROUP BY Customer.Customer_ID, Customer.Customer_Name
ORDER BY Total_Spending DESC;


/* =========================================================
   33. COMPLETE MULTI-TABLE REPORT
   ========================================================= */

SELECT
    c.Customer_ID,
    c.Customer_Name,
    c.City,
    o.Order_ID,
    o.Order_Date,
    p.Product_Name,
    oi.Quantity,
    p.Price,
    o.Total_Amount,
    pay.Payment_Mode,
    pay.Payment_Status
FROM Customer c
INNER JOIN Orders o
    ON c.Customer_ID = o.Customer_ID
INNER JOIN Order_Items oi
    ON o.Order_ID = oi.Order_ID
INNER JOIN Product p
    ON oi.Product_ID = p.Product_ID
LEFT JOIN Payment pay
    ON o.Order_ID = pay.Order_ID;