USE inventory_db;

SELECT *
FROM Customers;

SELECT *
FROM Products;

SELECT Product_Name, Price
FROM Products;



SELECT *
FROM Orders;

SELECT *
FROM Payment;

SELECT Product_Name, Price
FROM Products
WHERE Price > 5000;

SELECT *
FROM Products
WHERE Product_ID IN (
    SELECT Product_ID
    FROM Inventory
    WHERE Stock_Quantity > 0
);

SELECT *
FROM Customers
WHERE City = 'Chennai';

SELECT *
FROM Orders
WHERE Order_Status = 'Completed';



SELECT
    p.Product_Name,
    r.Rating
FROM Products p
JOIN Reviews r
    ON p.Product_ID = r.Product_ID
WHERE r.Rating > 4;



SELECT *
FROM Products
ORDER BY Price ASC;



SELECT *
FROM Customers
ORDER BY Customer_Name ASC;

SELECT *
FROM Products
ORDER BY Price DESC
LIMIT 5;

SELECT *
FROM Orders
ORDER BY Order_Date DESC;

SELECT DISTINCT Category_ID
FROM Products;
SELECT DISTINCT Payment_Mode
FROM Payment;

SELECT DISTINCT City
FROM Customers;

SELECT *
FROM Products
WHERE Price BETWEEN 1000 AND 5000;

SELECT *
FROM Products
WHERE Category_ID = 1;

SELECT *
FROM Inventory
WHERE Stock_Quantity > 0;

SELECT *
FROM Products
WHERE Product_Name LIKE '%Mobile%';

SELECT *
FROM Inventory
WHERE Stock_Quantity < 10;

SELECT c.Customer_Name, o.Order_ID, o.Order_Date
FROM Customers c
JOIN Orders o ON c.Customer_ID = o.Customer_ID;

SELECT p.Product_Name, c.Category_Name
FROM Products p
JOIN Categories c ON p.Category_ID = c.Category_ID;

SELECT c.Customer_Name
FROM Customers c
JOIN Orders o ON c.Customer_ID = o.Customer_ID
JOIN Order_Details od ON o.Order_ID = od.Order_ID
WHERE od.Product_ID = 1;

SELECT c.Customer_Name, p.Product_Name
FROM Customers c
JOIN Orders o ON c.Customer_ID = o.Customer_ID
JOIN Order_Details od ON o.Order_ID = od.Order_ID
JOIN Products p ON od.Product_ID = p.Product_ID;

SELECT *
FROM Products
WHERE Category_ID = 1 AND Price > 10000;

SELECT *
FROM Customers
WHERE City IN ('Chennai', 'Bangalore');

SELECT *
FROM Products
WHERE Product_Name LIKE '%Mobile%';

SELECT *
FROM Orders
WHERE Order_Date BETWEEN '2025-01-01' AND '2025-12-31';

SELECT Product_Name, Price, Stock_Quantity
FROM Products;

SELECT COUNT(*) AS Total_Customers
FROM Customers;

SELECT City, COUNT(*) AS Customer_Count
FROM Customers
GROUP BY City;

SELECT *
FROM Customers
ORDER BY Created_At DESC;

SELECT COUNT(*) AS Total_Orders
FROM Orders;

SELECT Product_Name, Price
FROM Products
ORDER BY Price DESC
LIMIT 5;

SELECT p.Product_Name, COUNT(r.Review_ID) AS Reviews
FROM Products p
JOIN Reviews r ON p.Product_ID = r.Product_ID
GROUP BY p.Product_ID, p.Product_Name
ORDER BY Reviews DESC;

SELECT *
FROM Inventory
WHERE Stock_Quantity > 0;