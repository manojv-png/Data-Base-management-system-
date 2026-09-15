-- ============================================================
-- WEEK 6: PRODUCT REVIEW AND RATING MANAGEMENT SYSTEM
-- ============================================================

-- Create Database
CREATE DATABASE EcommerceDB;

USE EcommerceDB;


-- ============================================================
-- 1. CUSTOMER TABLE
-- ============================================================

CREATE TABLE Customer (
    Customer_ID INT PRIMARY KEY,
    Customer_Name VARCHAR(100) NOT NULL
);


-- ============================================================
-- 2. PRODUCT TABLE
-- ============================================================

CREATE TABLE Product (
    Product_ID INT PRIMARY KEY,
    Product_Name VARCHAR(100) NOT NULL
);


-- ============================================================
-- 3. INSERT CUSTOMER DATA
-- ============================================================

INSERT INTO Customer (Customer_ID, Customer_Name)
VALUES
(1, 'John'),
(2, 'Priya'),
(3, 'Arun'),
(4, 'Divya'),
(5, 'Karthik');


-- ============================================================
-- 4. INSERT PRODUCT DATA
-- ============================================================

INSERT INTO Product (Product_ID, Product_Name)
VALUES
(1, 'Laptop'),
(2, 'Mobile'),
(3, 'Headphones'),
(4, 'Smart Watch'),
(5, 'Tablet');


-- ============================================================
-- 5. CREATE REVIEW TABLE
-- ============================================================

CREATE TABLE Review (
    Review_ID VARCHAR(10) PRIMARY KEY,
    Customer_ID INT NOT NULL,
    Product_ID INT NOT NULL,
    Rating INT NOT NULL,
    Review_Text VARCHAR(500),
    Review_Date DATE NOT NULL,

    FOREIGN KEY (Customer_ID)
        REFERENCES Customer(Customer_ID),

    FOREIGN KEY (Product_ID)
        REFERENCES Product(Product_ID),

    CHECK (Rating BETWEEN 1 AND 5)
);


-- ============================================================
-- 6. INSERT REVIEW DATA
-- ============================================================

INSERT INTO Review
(Review_ID, Customer_ID, Product_ID, Rating, Review_Text, Review_Date)
VALUES
('R101', 1, 1, 5, 'Excellent performance', '2026-09-01'),

('R102', 2, 2, 4, 'Good battery life', '2026-09-02'),

('R103', 1, 2, 5, 'Very good product', '2026-09-03'),

('R104', 3, 1, 3, 'Average performance', '2026-09-04'),

('R105', 4, 3, 5, 'Excellent sound quality', '2026-09-05'),

('R106', 2, 3, 4, 'Good product', '2026-09-06'),

('R107', 5, 1, 2, 'Needs improvement', '2026-09-07'),

('R108', 3, 4, 5, 'Very useful product', '2026-09-08'),

('R109', 4, 5, 4, 'Good tablet', '2026-09-09'),

('R110', 5, 2, 3, 'Average mobile', '2026-09-10');


-- ============================================================
-- 7. DISPLAY ALL REVIEWS
-- ============================================================

SELECT *
FROM Review;


-- ============================================================
-- 8. DISPLAY ALL REVIEWS FOR A PRODUCT
-- ============================================================

SELECT
    p.Product_Name,
    r.Rating,
    r.Review_Text,
    r.Review_Date
FROM Product p
JOIN Review r
ON p.Product_ID = r.Product_ID
WHERE p.Product_ID = 1;


-- ============================================================
-- 9. DISPLAY CUSTOMER NAME WITH THEIR REVIEWS
-- ============================================================

SELECT
    c.Customer_Name,
    r.Review_ID,
    r.Rating,
    r.Review_Text,
    r.Review_Date
FROM Customer c
JOIN Review r
ON c.Customer_ID = r.Customer_ID;


-- ============================================================
-- 10. DISPLAY PRODUCT NAME WITH REVIEWS
-- ============================================================

SELECT
    p.Product_Name,
    r.Rating,
    r.Review_Text
FROM Product p
JOIN Review r
ON p.Product_ID = r.Product_ID;


-- ============================================================
-- 11. FIND PRODUCT HAVING MAXIMUM REVIEWS
-- ============================================================

SELECT
    p.Product_Name,
    COUNT(r.Review_ID) AS Number_of_Reviews
FROM Product p
JOIN Review r
ON p.Product_ID = r.Product_ID
GROUP BY p.Product_ID, p.Product_Name
ORDER BY Number_of_Reviews DESC
LIMIT 1;


-- ============================================================
-- 12. DISPLAY RECENT CUSTOMER FEEDBACK
-- ============================================================

SELECT
    r.Review_ID,
    c.Customer_Name,
    p.Product_Name,
    r.Rating,
    r.Review_Text,
    r.Review_Date
FROM Review r
JOIN Customer c
ON r.Customer_ID = c.Customer_ID
JOIN Product p
ON r.Product_ID = p.Product_ID
ORDER BY r.Review_Date DESC
LIMIT 5;


-- ============================================================
-- 13. RETRIEVE REVIEWS WITH RATING ABOVE 4
-- ============================================================

SELECT
    r.Review_ID,
    p.Product_Name,
    r.Rating,
    r.Review_Text
FROM Review r
JOIN Product p
ON r.Product_ID = p.Product_ID
WHERE r.Rating > 4;


-- ============================================================
-- 14. CALCULATE AVERAGE RATING FOR EACH PRODUCT
-- ============================================================

SELECT
    Product_ID,
    AVG(Rating) AS Average_Rating
FROM Review
GROUP BY Product_ID;


-- ============================================================
-- 15. COUNT REVIEWS FOR EACH PRODUCT
-- ============================================================

SELECT
    Product_ID,
    COUNT(*) AS Number_of_Reviews
FROM Review
GROUP BY Product_ID;


-- ============================================================
	-- 16. FIND HIGHEST-RATED PRODUCTS
-- ============================================================

SELECT
    p.Product_Name,
    ROUND(AVG(r.Rating), 2) AS Average_Rating
FROM Product p
JOIN Review r
ON p.Product_ID = r.Product_ID
GROUP BY p.Product_ID, p.Product_Name
ORDER BY Average_Rating DESC;


-- ============================================================
-- 17. PRODUCTS WITH AVERAGE RATING ABOVE 4
-- ============================================================

SELECT
    p.Product_Name,
    ROUND(AVG(r.Rating), 2) AS Average_Rating
FROM Product p
JOIN Review r
ON p.Product_ID = r.Product_ID
GROUP BY p.Product_ID, p.Product_Name
HAVING AVG(r.Rating) > 4;


-- ============================================================
-- 18. PRODUCT RATING ANALYSIS REPORT
-- ============================================================

SELECT
    p.Product_Name,
    COUNT(r.Review_ID) AS Number_of_Reviews,
    ROUND(AVG(r.Rating), 2) AS Average_Rating
FROM Product p
LEFT JOIN Review r
ON p.Product_ID = r.Product_ID
GROUP BY p.Product_ID, p.Product_Name
ORDER BY Average_Rating DESC;


-- ============================================================
-- 19. CUSTOMER FEEDBACK ANALYSIS
-- ============================================================

SELECT
    p.Product_Name,
    COUNT(r.Review_ID) AS Number_of_Reviews,
    ROUND(AVG(r.Rating), 2) AS Average_Rating
FROM Product p
JOIN Review r
ON p.Product_ID = r.Product_ID
GROUP BY p.Product_ID, p.Product_Name
ORDER BY Number_of_Reviews DESC;


-- ============================================================
-- 20. HIGHLY RATED PRODUCTS
-- ============================================================

SELECT
    p.Product_Name,
    ROUND(AVG(r.Rating), 2) AS Average_Rating
FROM Product p
JOIN Review r
ON p.Product_ID = r.Product_ID
GROUP BY p.Product_ID, p.Product_Name
HAVING AVG(r.Rating) >= 4
ORDER BY Average_Rating DESC;


-- ============================================================
-- 21. PRODUCTS REQUIRING IMPROVEMENT
-- ============================================================

SELECT
    p.Product_Name,
    ROUND(AVG(r.Rating), 2) AS Average_Rating
FROM Product p
JOIN Review r
ON p.Product_ID = r.Product_ID
GROUP BY p.Product_ID, p.Product_Name
HAVING AVG(r.Rating) < 3;


-- ============================================================
-- 22. NUMBER OF 5-STAR RATINGS
-- ============================================================

SELECT
    COUNT(*) AS Five_Star_Ratings
FROM Review
WHERE Rating = 5;


-- ============================================================
-- 23. NUMBER OF 4-STAR RATINGS
-- ============================================================

SELECT
    COUNT(*) AS Four_Star_Ratings
FROM Review
WHERE Rating = 4;


-- ============================================================
-- 24. NUMBER OF LOW-RATED REVIEWS
-- ============================================================

SELECT
    COUNT(*) AS Low_Rated_Reviews
FROM Review
WHERE Rating <= 2;


-- ============================================================
-- 25. RATING DISTRIBUTION
-- ============================================================

SELECT
    Rating,
    COUNT(*) AS Number_of_Ratings
FROM Review
GROUP BY Rating
ORDER BY Rating DESC;


-- ============================================================
-- 26. UPDATE REVIEW
-- ============================================================

UPDATE Review
SET
    Rating = 4,
    Review_Text = 'Good performance'
WHERE Review_ID = 'R104';


-- ============================================================
-- 27. REMOVE INAPPROPRIATE REVIEW
-- ============================================================

DELETE FROM Review
WHERE Review_ID = 'R107';


-- ============================================================
-- 28. FINAL REVIEW REPORT
-- ============================================================

SELECT
    r.Review_ID,
    c.Customer_Name,
    p.Product_Name,
    r.Rating,
    r.Review_Text,
    r.Review_Date
FROM Review r
JOIN Customer c
ON r.Customer_ID = c.Customer_ID
JOIN Product p
ON r.Product_ID = p.Product_ID
ORDER BY r.Review_Date DESC;


-- ============================================================
-- 29. FINAL PRODUCT RATING REPORT
-- ============================================================

SELECT
    p.Product_Name,
    COUNT(r.Review_ID) AS Number_of_Reviews,
    ROUND(AVG(r.Rating), 2) AS Average_Rating
FROM Product p
LEFT JOIN Review r
ON p.Product_ID = r.Product_ID
GROUP BY p.Product_ID, p.Product_Name
ORDER BY Average_Rating DESC;