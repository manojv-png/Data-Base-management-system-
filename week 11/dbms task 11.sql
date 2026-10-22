-- ============================================================
-- WEEK 11: DATABASE AUTOMATION USING VIEWS AND PROCEDURES
-- E-COMMERCE DATABASE SYSTEM
-- MYSQL 8.0 - COMPLETE ERROR-FIXED CODE
-- ============================================================


-- 1. CREATE DATABASE
CREATE DATABASE IF NOT EXISTS EcommerceDB_Week11;

USE EcommerceDB_Week11;


-- ============================================================
-- 2. CREATE TABLES
-- ============================================================

CREATE TABLE Customer (
    Customer_ID INT PRIMARY KEY AUTO_INCREMENT,
    Customer_Name VARCHAR(100) NOT NULL,
    Email VARCHAR(100) UNIQUE,
    Phone VARCHAR(15)
);

CREATE TABLE Products (
    Product_ID INT PRIMARY KEY AUTO_INCREMENT,
    Product_Name VARCHAR(100) NOT NULL,
    Price DECIMAL(12,2) NOT NULL,
    Stock INT NOT NULL DEFAULT 0,
    CHECK (Price >= 0),
    CHECK (Stock >= 0)
);

CREATE TABLE Orders (
    Order_ID INT PRIMARY KEY AUTO_INCREMENT,
    Customer_ID INT NOT NULL,
    Order_Date DATETIME DEFAULT CURRENT_TIMESTAMP,
    Total_Amount DECIMAL(12,2) NOT NULL DEFAULT 0,
    Order_Status ENUM(
        'Pending',
        'Shipped',
        'Delivered',
        'Cancelled'
    ) DEFAULT 'Pending',
    FOREIGN KEY (Customer_ID)
        REFERENCES Customer(Customer_ID)
);

CREATE TABLE Order_Items (
    Order_Item_ID INT PRIMARY KEY AUTO_INCREMENT,
    Order_ID INT NOT NULL,
    Product_ID INT NOT NULL,
    Quantity INT NOT NULL,
    Unit_Price DECIMAL(12,2) NOT NULL,
    FOREIGN KEY (Order_ID)
        REFERENCES Orders(Order_ID),
    FOREIGN KEY (Product_ID)
        REFERENCES Products(Product_ID),
    CHECK (Quantity > 0),
    CHECK (Unit_Price >= 0)
);

CREATE TABLE Payments (
    Payment_ID INT PRIMARY KEY AUTO_INCREMENT,
    Order_ID INT NOT NULL,
    Payment_Mode VARCHAR(30),
    Payment_Status ENUM(
        'Pending',
        'Completed',
        'Failed',
        'Refunded'
    ) DEFAULT 'Pending',
    Transaction_Amount DECIMAL(12,2) NOT NULL,
    Payment_Date DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (Order_ID)
        REFERENCES Orders(Order_ID)
);

CREATE TABLE Inventory_Supplies (
    Supply_ID INT PRIMARY KEY AUTO_INCREMENT,
    Product_ID INT NOT NULL,
    Quantity_Added INT NOT NULL,
    Supply_Date DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (Product_ID)
        REFERENCES Products(Product_ID),
    CHECK (Quantity_Added > 0)
);


-- ============================================================
-- 3. INSERT SAMPLE DATA
-- ============================================================

INSERT INTO Customer
    (Customer_Name, Email, Phone)
VALUES
    ('Arun', 'arun@example.com', '9876543210'),
    ('Rahul', 'rahul@example.com', '9876543211'),
    ('Priya', 'priya@example.com', '9876543212');

INSERT INTO Products
    (Product_Name, Price, Stock)
VALUES
    ('Laptop', 50000.00, 25),
    ('Mobile', 15000.00, 5),
    ('Headphones', 2000.00, 30),
    ('Keyboard', 1000.00, 20);

INSERT INTO Orders
    (Customer_ID, Order_Date, Total_Amount, Order_Status)
VALUES
    (1, '2026-10-01 10:00:00', 100000.00, 'Delivered'),
    (2, '2026-10-05 11:00:00', 15000.00, 'Shipped'),
    (1, '2026-10-10 12:00:00', 2000.00, 'Pending');

INSERT INTO Order_Items
    (Order_ID, Product_ID, Quantity, Unit_Price)
VALUES
    (1, 1, 2, 50000.00),
    (2, 2, 1, 15000.00),
    (3, 3, 1, 2000.00);

INSERT INTO Payments
    (Order_ID, Payment_Mode, Payment_Status, Transaction_Amount)
VALUES
    (1, 'UPI', 'Completed', 100000.00),
    (2, 'Card', 'Completed', 15000.00),
    (3, 'Cash', 'Pending', 2000.00);


-- ============================================================
-- 4. CREATE VIEWS
-- ============================================================

-- 4.1 CUSTOMER ORDER REPORT

CREATE VIEW Customer_Order_Report AS
SELECT
    c.Customer_Name,
    o.Order_ID,
    o.Order_Date,
    o.Total_Amount,
    o.Order_Status
FROM Customer c
JOIN Orders o
    ON c.Customer_ID = o.Customer_ID;


-- 4.2 PRODUCT SALES REPORT

CREATE VIEW Product_Sales_Report AS
SELECT
    p.Product_ID,
    p.Product_Name,
    COALESCE(
        SUM(
            CASE
                WHEN o.Order_Status <> 'Cancelled'
                THEN oi.Quantity
                ELSE 0
            END
        ), 0
    ) AS Quantity_Sold,
    COALESCE(
        SUM(
            CASE
                WHEN o.Order_Status <> 'Cancelled'
                THEN oi.Quantity * oi.Unit_Price
                ELSE 0
            END
        ), 0
    ) AS Total_Revenue
FROM Products p
LEFT JOIN Order_Items oi
    ON p.Product_ID = oi.Product_ID
LEFT JOIN Orders o
    ON oi.Order_ID = o.Order_ID
GROUP BY
    p.Product_ID,
    p.Product_Name;


-- 4.3 PAYMENT STATUS REPORT

CREATE VIEW Payment_Status_Report AS
SELECT
    Order_ID,
    Payment_Mode,
    Payment_Status,
    Transaction_Amount
FROM Payments;


-- 4.4 LOW STOCK REPORT

CREATE VIEW Low_Stock_Products AS
SELECT
    Product_ID,
    Product_Name,
    Stock,
    'Low Stock' AS Stock_Status
FROM Products
WHERE Stock <= 5;


-- ============================================================
-- 5. CREATE STORED PROCEDURES
-- ============================================================

DELIMITER //


-- 5.1 ADD NEW CUSTOMER ORDER

CREATE PROCEDURE Add_New_Customer_Order(
    IN p_Customer_ID INT,
    IN p_Product_ID INT,
    IN p_Quantity INT,
    IN p_Payment_Mode VARCHAR(30)
)
BEGIN
    DECLARE v_Order_ID INT;
    DECLARE v_Price DECIMAL(12,2);
    DECLARE v_Stock INT;
    DECLARE v_Total DECIMAL(12,2);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    IF p_Quantity IS NULL OR p_Quantity <= 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Quantity must be greater than zero';
    END IF;

    IF p_Payment_Mode IS NULL OR p_Payment_Mode = '' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Payment mode is required';
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM Customer
        WHERE Customer_ID = p_Customer_ID
    ) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Customer not found';
    END IF;

    SET v_Price = NULL;
    SET v_Stock = NULL;

    SELECT Price, Stock
    INTO v_Price, v_Stock
    FROM Products
    WHERE Product_ID = p_Product_ID
    FOR UPDATE;

    IF v_Price IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Product not found';
    END IF;

    IF v_Stock < p_Quantity THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Insufficient stock';
    END IF;

    SET v_Total = v_Price * p_Quantity;

    INSERT INTO Orders (
        Customer_ID,
        Order_Date,
        Total_Amount,
        Order_Status
    )
    VALUES (
        p_Customer_ID,
        NOW(),
        v_Total,
        'Pending'
    );

    SET v_Order_ID = LAST_INSERT_ID();

    INSERT INTO Order_Items (
        Order_ID,
        Product_ID,
        Quantity,
        Unit_Price
    )
    VALUES (
        v_Order_ID,
        p_Product_ID,
        p_Quantity,
        v_Price
    );

    UPDATE Products
    SET Stock = Stock - p_Quantity
    WHERE Product_ID = p_Product_ID;

    INSERT INTO Payments (
        Order_ID,
        Payment_Mode,
        Payment_Status,
        Transaction_Amount
    )
    VALUES (
        v_Order_ID,
        p_Payment_Mode,
        'Pending',
        v_Total
    );

    COMMIT;

    SELECT
        v_Order_ID AS Order_ID,
        v_Total AS Total_Amount,
        'Order created successfully' AS Message;
END //


-- 5.2 UPDATE ORDER STATUS

CREATE PROCEDURE Update_Order_Status(
    IN p_Order_ID INT,
    IN p_New_Status VARCHAR(20)
)
BEGIN
    IF p_New_Status IS NULL OR p_New_Status NOT IN (
        'Pending',
        'Shipped',
        'Delivered',
        'Cancelled'
    ) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Invalid order status';
    END IF;

    UPDATE Orders
    SET Order_Status = p_New_Status
    WHERE Order_ID = p_Order_ID;

    IF ROW_COUNT() = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Order not found or status unchanged';
    END IF;

    SELECT Order_ID, Order_Status
    FROM Orders
    WHERE Order_ID = p_Order_ID;
END //


-- 5.3 CUSTOMER PURCHASE HISTORY

CREATE PROCEDURE Get_Customer_Purchase_History(
    IN p_Customer_ID INT
)
BEGIN
    SELECT
        c.Customer_ID,
        c.Customer_Name,
        o.Order_ID,
        o.Order_Date,
        o.Total_Amount AS Purchase_Amount,
        o.Order_Status
    FROM Customer c
    JOIN Orders o
        ON c.Customer_ID = o.Customer_ID
    WHERE c.Customer_ID = p_Customer_ID
    ORDER BY o.Order_Date DESC;
END //

DELIMITER ;


-- ============================================================
-- 6. CREATE FUNCTIONS
-- ============================================================

DELIMITER //


-- 6.1 CALCULATE TOTAL SALES

CREATE FUNCTION Calculate_Total_Sales(
    p_Start_Date DATE,
    p_End_Date DATE
)
RETURNS DECIMAL(14,2)
NOT DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_Total_Sales DECIMAL(14,2);

    IF p_Start_Date IS NULL
       OR p_End_Date IS NULL
       OR p_Start_Date > p_End_Date THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Invalid date range';
    END IF;

    SELECT COALESCE(SUM(Total_Amount), 0)
    INTO v_Total_Sales
    FROM Orders
    WHERE Order_Date >= p_Start_Date
      AND Order_Date < DATE_ADD(p_End_Date, INTERVAL 1 DAY)
      AND Order_Status <> 'Cancelled';

    RETURN v_Total_Sales;
END //


-- 6.2 CUSTOMER TOTAL SPENDING

CREATE FUNCTION Calculate_Customer_Total_Spending(
    p_Customer_ID INT
)
RETURNS DECIMAL(14,2)
NOT DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_Total_Spending DECIMAL(14,2);

    SELECT COALESCE(SUM(Total_Amount), 0)
    INTO v_Total_Spending
    FROM Orders
    WHERE Customer_ID = p_Customer_ID
      AND Order_Status <> 'Cancelled';

    RETURN v_Total_Spending;
END //


-- 6.3 PRODUCT REVENUE

CREATE FUNCTION Calculate_Product_Revenue(
    p_Product_ID INT
)
RETURNS DECIMAL(14,2)
NOT DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_Revenue DECIMAL(14,2);

  
  

    RETURN v_Revenue;
END //

DELIMITER ;


-- ============================================================
-- 7. INVENTORY AUTOMATION TRIGGER
-- ============================================================

DELIMITER //

CREATE TRIGGER After_Inventory_Supply_Insert
AFTER INSERT ON Inventory_Supplies
FOR EACH ROW
BEGIN
    UPDATE Products
    SET Stock = Stock + NEW.Quantity_Added
    WHERE Product_ID = NEW.Product_ID;
END //

DELIMITER ;


-- ============================================================
-- 8. TEST VIEWS
-- ============================================================

SELECT * FROM Customer_Order_Report;

SELECT * FROM Product_Sales_Report;

SELECT * FROM Payment_Status_Report;

SELECT * FROM Low_Stock_Products;


-- ============================================================
-- 9. TEST STORED PROCEDURES
-- ============================================================

CALL Add_New_Customer_Order(1, 1, 2, 'UPI');

CALL Update_Order_Status(1, 'Shipped');

CALL Get_Customer_Purchase_History(1);


-- ============================================================
-- 10. TEST FUNCTIONS
-- ============================================================

SELECT Calculate_Total_Sales(
    '2026-10-01',
    '2026-10-31'
) AS Total_Sales;

SELECT Calculate_Customer_Total_Spending(1)
AS Customer_Total_Spending;

SELECT Calculate_Product_Revenue(1)
AS Product_Revenue;


-- ============================================================
-- 11. TEST INVENTORY AUTOMATION
-- ============================================================

INSERT INTO Inventory_Supplies (
    Product_ID,
    Quantity_Added
)
VALUES (1, 10);

SELECT Product_ID, Product_Name, Stock
FROM Products;

SELECT * FROM Low_Stock_Products;


-- ============================================================
-- 12. DAILY SALES REPORT
-- ============================================================

SELECT
    DATE(Order_Date) AS Sales_Date,
    COUNT(*) AS Total_Orders,
    SUM(Total_Amount) AS Total_Revenue
FROM Orders
WHERE Order_Date >= CURDATE()
  AND Order_Date < CURDATE() + INTERVAL 1 DAY
  AND Order_Status <> 'Cancelled'
GROUP BY DATE(Order_Date);


-- ============================================================
-- 13. MONTHLY REVENUE REPORT
-- ============================================================

SELECT
    YEAR(Order_Date) AS Sales_Year,
    MONTH(Order_Date) AS Sales_Month,
    COUNT(*) AS Total_Orders,
    SUM(Total_Amount) AS Monthly_Revenue
FROM Orders
WHERE Order_Status <> 'Cancelled'
GROUP BY
    YEAR(Order_Date),
    MONTH(Order_Date)
ORDER BY Sales_Year, Sales_Month;


-- ============================================================
-- 14. CUSTOMER PURCHASE REPORT
-- ============================================================

SELECT
    c.Customer_Name,
    COUNT(o.Order_ID) AS Total_Orders,
    COALESCE(SUM(o.Total_Amount), 0) AS Total_Amount
FROM Customer c
LEFT JOIN Orders o
    ON c.Customer_ID = o.Customer_ID
    AND o.Order_Status <> 'Cancelled'
GROUP BY
    c.Customer_ID,
    c.Customer_Name
ORDER BY Total_Amount DESC;


-- ============================================================
-- 15. DISPLAY TABLE DATA
-- ============================================================

SELECT * FROM Customer;

SELECT * FROM Products;

SELECT * FROM Orders;

SELECT * FROM Order_Items;

SELECT * FROM Payments;

SELECT * FROM Inventory_Supplies;


-- ============================================================
-- END OF WEEK 11 ASSIGNMENT
-- ============================================================