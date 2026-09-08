CREATE DATABASE ProductCategoryDB;
USE ProductCategoryDB;

-- CATEGORY TABLE
CREATE TABLE Category (
    Category_ID INT PRIMARY KEY,
    Category_Name VARCHAR(50) NOT NULL UNIQUE,
    Description VARCHAR(255)
); 

-- PRODUCT TABLE
CREATE TABLE Product (
    Product_ID INT PRIMARY KEY,
    Product_Name VARCHAR(100) NOT NULL UNIQUE,
    Category_ID INT NOT NULL,
    Price DECIMAL(10,2) NOT NULL CHECK (Price > 0),
    Stock_Quantity INT NOT NULL CHECK (Stock_Quantity >= 0),

    FOREIGN KEY (Category_ID)
        REFERENCES Category(Category_ID)
);

-- INSERT CATEGORIES
INSERT INTO Category VALUES
(1, 'Electronics', 'Electronic devices and accessories'),
(2, 'Clothing', 'Clothes and fashion products'),
(3, 'Books', 'Books and study materials'),
(4, 'Home Appliances', 'Appliances used at home');

-- INSERT PRODUCTS
INSERT INTO Product VALUES
(101, 'Laptop', 1, 55000, 20),
(102, 'Smartphone', 1, 25000, 35),
(103, 'Headphones', 1, 2500, 50),
(104, 'T-Shirt', 2, 800, 40),
(105, 'Jeans', 2, 1800, 30),
(106, 'Python Programming', 3, 650, 25),
(107, 'Data Structures', 3, 750, 20),
(108, 'Refrigerator', 4, 45000, 10),
(109, 'Washing Machine', 4, 35000, 8),
(110, 'Microwave Oven', 4, 12000, 15);

-- DISPLAY DATA
SELECT * FROM Category;
SELECT * FROM Product;

-- INSERT
INSERT INTO Product
VALUES (111, 'Smart Watch', 1, 5000, 25);

-- UPDATE PRICE
UPDATE Product
SET Price = 52000
WHERE Product_ID = 101;

-- UPDATE STOCK
UPDATE Product
SET Stock_Quantity = Stock_Quantity + 10
WHERE Product_ID = 101;

-- DELETE
DELETE FROM Product
WHERE Product_ID = 111;

-- PRODUCTS UNDER EACH CATEGORY
SELECT
    c.Category_Name,
    p.Product_ID,
    p.Product_Name,
    p.Price,
    p.Stock_Quantity
FROM Category c
JOIN Product p
ON c.Category_ID = p.Category_ID
ORDER BY c.Category_Name;

-- PRODUCT COUNT
SELECT
    c.Category_Name,
    COUNT(p.Product_ID) AS Product_Count
FROM Category c
LEFT JOIN Product p
ON c.Category_ID = p.Category_ID
GROUP BY c.Category_ID, c.Category_Name;

-- HIGHEST PRICE
SELECT
    c.Category_Name,
    MAX(p.Price) AS Highest_Price
FROM Category c
JOIN Product p
ON c.Category_ID = p.Category_ID
GROUP BY c.Category_ID, c.Category_Name;

-- CATEGORIES WITH MORE THAN 5 PRODUCTS
SELECT
    c.Category_Name,
    COUNT(p.Product_ID) AS Product_Count
FROM Category c
JOIN Product p
ON c.Category_ID = p.Category_ID
GROUP BY c.Category_ID, c.Category_Name
HAVING COUNT(p.Product_ID) > 5;


SELECT
    c.Category_Name,
    AVG(p.Price) AS Average_Price
FROM Category c
JOIN Product p
ON c.Category_ID = p.Category_ID
GROUP BY c.Category_ID, c.Category_Name;