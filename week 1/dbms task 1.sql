-- 1. Create Database
CREATE DATABASE E_Commerce;

-- Select Database
USE E_Commerce;



CREATE TABLE Customer (
    Customer_ID INT PRIMARY KEY,
    Customer_Name VARCHAR(100) NOT NULL,
    Email VARCHAR(100) NOT NULL UNIQUE,
    Phone VARCHAR(15) NOT NULL,
    Address VARCHAR(200),
    City VARCHAR(50),
    Registration_Date DATE NOT NULL
);



INSERT INTO Customer
(Customer_ID, Customer_Name, Email, Phone, Address, City, Registration_Date)
VALUES
(1, 'Arun Kumar', 'arun@gmail.com', '9876543210',
 '12 Anna Street', 'Chennai', '2026-01-10'),

(2, 'Priya Sharma', 'priya@gmail.com', '9876543211',
 '25 Gandhi Road', 'Coimbatore', '2026-01-15'),

(3, 'Rahul Raj', 'rahul@gmail.com', '9876543212',
 '18 MG Road', 'Madurai', '2026-02-05'),

(4, 'Sneha Devi', 'sneha@gmail.com', '9876543213',
 '45 Park Street', 'Chennai', '2026-02-12'),

(5, 'Vijay Kumar', 'vijay@gmail.com', '9876543214',
 '10 Main Road', 'Salem', '2026-02-20'),

(6, 'Karthik S', 'karthik@gmail.com', '9876543215',
 '32 Lake Road', 'Trichy', '2026-03-01'),

(7, 'Divya R', 'divya@gmail.com', '9876543216',
 '15 Temple Street', 'Madurai', '2026-03-10'),

(8, 'Manoj Kumar', 'manoj@gmail.com', '9876543217',
 '20 Nehru Street', 'Chennai', '2026-03-15'),

(9, 'Anjali P', 'anjali@gmail.com', '9876543218',
 '8 Market Road', 'Coimbatore', '2026-03-20'),

(10, 'Suresh Babu', 'suresh@gmail.com', '9876543219',
 '55 Railway Road', 'Salem', '2026-04-01');


-- ============================================
-- 4. READ - Display Customer Details
-- ============================================

SELECT * FROM Customer;


-- ============================================
-- 5. READ - Search Customers by City
-- ============================================

SELECT *
FROM Customer
WHERE City = 'Chennai';


-- ============================================
-- 6. UPDATE - Modify Customer Phone
-- ============================================

UPDATE Customer
SET Phone = '9000000001'
WHERE Customer_ID = 1;


-- ============================================
-- 7. UPDATE - Modify Customer Address
-- ============================================

UPDATE Customer
SET Address = '100 New Anna Street'
WHERE Customer_ID = 1;


-- Check Updated Record
SELECT *
FROM Customer
WHERE Customer_ID = 1;


-- ============================================
-- 8. DELETE - Remove Inactive Customer
-- ============================================

-- Example: Customer ID 10 is considered inactive
DELETE FROM Customer
WHERE Customer_ID = 10;


-- Check remaining customers
SELECT * FROM Customer;