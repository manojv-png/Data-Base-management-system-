-- ============================================================
-- WEEK 12: TRANSACTION MANAGEMENT SYSTEM (MySQL Workbench)
-- Run the whole script with Ctrl + Shift + Enter (not Ctrl + Enter)
-- Needs MySQL 8.0.16 or newer for CHECK constraints to be enforced
-- ============================================================

CREATE DATABASE IF NOT EXISTS ecommerce_txn_db;
USE ecommerce_txn_db;

-- Drop in reverse foreign-key order so the script can be re-run
DROP PROCEDURE IF EXISTS sp_place_order;
DROP TABLE IF EXISTS Inventory_Log;
DROP TABLE IF EXISTS Payment;
DROP TABLE IF EXISTS Order_Details;
DROP TABLE IF EXISTS Orders;
DROP TABLE IF EXISTS Inventory;
DROP TABLE IF EXISTS Product;
DROP TABLE IF EXISTS Customer;

-- ============================================================
-- SETUP: TABLES
-- ============================================================

CREATE TABLE Customer (
    Customer_ID   INT          PRIMARY KEY,
    Customer_Name VARCHAR(100) NOT NULL,
    Email         VARCHAR(100) NOT NULL,
    City          VARCHAR(50)
);

CREATE TABLE Product (
    Product_ID   INT           PRIMARY KEY,
    Product_Name VARCHAR(100)  NOT NULL,
    Price        DECIMAL(10,2) NOT NULL CHECK (Price >= 0)
);

-- Stock can never go negative (Consistency)
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

CREATE TABLE Payment (
    Payment_ID     INT         PRIMARY KEY,
    Order_ID       INT         NOT NULL,
    Payment_Method VARCHAR(20) NOT NULL,
    Payment_Status VARCHAR(20) NOT NULL
                   CHECK (Payment_Status IN ('Success','Failed','Pending')),
    Payment_Date   TIMESTAMP   DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (Order_ID) REFERENCES Orders(Order_ID)
);

-- Stock movement history (used for Report 3 and for the consistency checks)
CREATE TABLE Inventory_Log (
    Log_ID           INT         AUTO_INCREMENT PRIMARY KEY,
    Product_ID       INT         NOT NULL,
    Order_ID         INT         NOT NULL,
    Action_Type      VARCHAR(10) NOT NULL CHECK (Action_Type IN ('SOLD','RESTORED')),
    Previous_Stock   INT         NOT NULL,
    Current_Stock    INT         NOT NULL,
    Quantity_Changed INT         NOT NULL,
    Log_Time         TIMESTAMP   DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (Product_ID) REFERENCES Product(Product_ID),
    FOREIGN KEY (Order_ID)   REFERENCES Orders(Order_ID)
);

-- ============================================================
-- SETUP: SAMPLE DATA
-- ============================================================

INSERT INTO Customer VALUES (101, 'Rahul', 'rahul@mail.com', 'Chennai');
INSERT INTO Customer VALUES (102, 'Priya', 'priya@mail.com', 'Mumbai');
INSERT INTO Customer VALUES (103, 'Karan', 'karan@mail.com', 'Delhi');

INSERT INTO Product VALUES (10, 'Laptop',       55000.00);
INSERT INTO Product VALUES (11, 'Mobile Phone', 20000.00);
INSERT INTO Product VALUES (12, 'Mouse',          500.00);
INSERT INTO Product VALUES (13, 'Tablet',       25000.00);

INSERT INTO Inventory VALUES (10, 10);
INSERT INTO Inventory VALUES (11, 50);
INSERT INTO Inventory VALUES (12, 200);
INSERT INTO Inventory VALUES (13, 0);

-- ============================================================
-- TASK 1: ORDER PLACEMENT TRANSACTION
-- "A customer purchases a laptop and pays using UPI"
-- ============================================================

START TRANSACTION;

-- Step 1: Check availability and lock the stock row (Isolation)
SELECT Stock_Quantity INTO @prev_stock
FROM Inventory
WHERE Product_ID = 10
FOR UPDATE;

-- Step 2: Insert order (status Pending)
INSERT INTO Orders (Order_ID, Customer_ID, Order_Date, Total_Amount, Order_Status)
VALUES (5001, 101, '2026-07-22', 55000, 'Pending');

-- Step 3: Insert ordered product
INSERT INTO Order_Details (Order_ID, Product_ID, Quantity, Price)
VALUES (5001, 10, 1, 55000);

-- Step 4: Reduce inventory stock and log the movement
UPDATE Inventory
SET Stock_Quantity = Stock_Quantity - 1
WHERE Product_ID = 10;

INSERT INTO Inventory_Log
    (Product_ID, Order_ID, Action_Type, Previous_Stock, Current_Stock, Quantity_Changed)
VALUES (10, 5001, 'SOLD', @prev_stock, @prev_stock - 1, 1);

-- Step 5: Insert payment details
INSERT INTO Payment (Payment_ID, Order_ID, Payment_Method, Payment_Status)
VALUES (9001, 5001, 'UPI', 'Success');

-- Step 6: Update order status
UPDATE Orders
SET Order_Status = 'Completed'
WHERE Order_ID = 5001;

COMMIT;

-- Verify the successful transaction
SELECT O.Order_ID, O.Order_Status, P.Payment_Status, I.Stock_Quantity AS Laptop_Stock
FROM Orders O
JOIN Payment P   ON O.Order_ID = P.Order_ID
JOIN Inventory I ON I.Product_ID = 10
WHERE O.Order_ID = 5001;
-- Expected: Completed | Success | 9

-- ============================================================
-- TASK 2: COMMIT AND ROLLBACK
-- Successful scenario = the transaction above (ended with COMMIT)
-- Failed scenario below: payment fails, so ROLLBACK cancels everything
-- ============================================================

START TRANSACTION;

SELECT Stock_Quantity INTO @prev_stock
FROM Inventory
WHERE Product_ID = 11
FOR UPDATE;

INSERT INTO Orders (Order_ID, Customer_ID, Order_Date, Total_Amount, Order_Status)
VALUES (5002, 102, '2026-07-22', 20000, 'Pending');

INSERT INTO Order_Details (Order_ID, Product_ID, Quantity, Price)
VALUES (5002, 11, 1, 20000);

UPDATE Inventory
SET Stock_Quantity = Stock_Quantity - 1
WHERE Product_ID = 11;

INSERT INTO Inventory_Log
    (Product_ID, Order_ID, Action_Type, Previous_Stock, Current_Stock, Quantity_Changed)
VALUES (11, 5002, 'SOLD', @prev_stock, @prev_stock - 1, 1);

INSERT INTO Payment (Payment_ID, Order_ID, Payment_Method, Payment_Status)
VALUES (9002, 5002, 'Card', 'Failed');

-- State INSIDE the transaction (not yet saved)
SELECT 'Before ROLLBACK' AS Stage,
       (SELECT COUNT(*) FROM Orders  WHERE Order_ID = 5002)   AS Order_Rows,
       (SELECT COUNT(*) FROM Payment WHERE Payment_ID = 9002) AS Payment_Rows,
       (SELECT Stock_Quantity FROM Inventory WHERE Product_ID = 11) AS Mobile_Stock;
-- Expected: 1 | 1 | 49

-- Payment failed -> cancel the whole transaction
ROLLBACK;

SELECT 'After ROLLBACK' AS Stage,
       (SELECT COUNT(*) FROM Orders  WHERE Order_ID = 5002)   AS Order_Rows,
       (SELECT COUNT(*) FROM Payment WHERE Payment_ID = 9002) AS Payment_Rows,
       (SELECT Stock_Quantity FROM Inventory WHERE Product_ID = 11) AS Mobile_Stock;
-- Expected: 0 | 0 | 50  (order removed, payment removed, stock restored)

-- ============================================================
-- TASK 3: ACID PROPERTIES
-- ============================================================

-- A - ATOMICITY
-- A transaction is completed fully or not at all.
--   Order created + Payment success -> COMMIT (Task 1, order 5001)
--   Order created + Payment failed  -> ROLLBACK (Task 2, order 5002)
-- Proof: after the ROLLBACK above, order 5002 has 0 rows.

-- C - CONSISTENCY
-- The database stays valid before and after a transaction.
-- Laptop stock was 10 before the purchase and is 9 after it.
SELECT Pr.Product_Name, I.Stock_Quantity AS Stock_After_Purchase
FROM Product Pr
JOIN Inventory I ON Pr.Product_ID = I.Product_ID
WHERE Pr.Product_ID = 10;
-- The CHECK (Stock_Quantity >= 0) rule blocks negative stock.
-- Uncomment to see error 3819 (do NOT run it inside the main script run):
-- UPDATE Inventory SET Stock_Quantity = Stock_Quantity - 100 WHERE Product_ID = 10;

-- I - ISOLATION
-- Two customers buying the last item at the same time.
-- Open TWO query tabs in Workbench (two separate sessions) and run:
--   Session 1:  START TRANSACTION;
--               SELECT Stock_Quantity FROM Inventory WHERE Product_ID = 13 FOR UPDATE;
--   Session 2:  START TRANSACTION;
--               SELECT Stock_Quantity FROM Inventory WHERE Product_ID = 13 FOR UPDATE;
--               (Session 2 WAITS because Session 1 holds the row lock)
--   Session 1:  COMMIT;   (Session 2 now continues and sees the latest stock)
-- To see the isolation level:  SELECT @@transaction_isolation;
-- MySQL default is REPEATABLE READ.

-- D - DURABILITY
-- Committed data stays saved, even after a restart or crash.
SELECT Order_ID, Order_Status, Total_Amount
FROM Orders
WHERE Order_ID = 5001;
-- InnoDB writes committed changes to its redo log. This setting
-- (value 1 = flush to disk on every COMMIT) gives full durability:
SHOW VARIABLES LIKE 'innodb_flush_log_at_trx_commit';

-- ============================================================
-- TASK 4: PAYMENT AND STOCK UPDATE TRANSACTIONS
-- ============================================================

-- ---------- SCENARIO 1: SUCCESSFUL PURCHASE (2 Mouse, Card) ----------
START TRANSACTION;

-- 1. Check product availability (must show 200, which is >= 2)
SELECT Stock_Quantity INTO @prev_stock
FROM Inventory
WHERE Product_ID = 12
FOR UPDATE;

-- 2. Create order
INSERT INTO Orders (Order_ID, Customer_ID, Order_Date, Total_Amount, Order_Status)
VALUES (5003, 103, '2026-07-22', 1000, 'Pending');

INSERT INTO Order_Details (Order_ID, Product_ID, Quantity, Price)
VALUES (5003, 12, 2, 500);

-- 3. Reduce stock
UPDATE Inventory
SET Stock_Quantity = Stock_Quantity - 2
WHERE Product_ID = 12;

INSERT INTO Inventory_Log
    (Product_ID, Order_ID, Action_Type, Previous_Stock, Current_Stock, Quantity_Changed)
VALUES (12, 5003, 'SOLD', @prev_stock, @prev_stock - 2, 2);

-- 4. Store payment details
INSERT INTO Payment (Payment_ID, Order_ID, Payment_Method, Payment_Status)
VALUES (9003, 5003, 'Card', 'Success');

-- 5. Confirm order
UPDATE Orders
SET Order_Status = 'Completed'
WHERE Order_ID = 5003;

COMMIT;
-- Expected: Order = Completed, Payment = Success, Mouse stock 200 -> 198

-- ---------- SCENARIO 2: FAILED PAYMENT (order cancelled, stock restored) ----------
-- This version keeps an audit trail: Order Cancelled + Payment Failed
-- + Stock Restored are all saved, so the Failed Transaction Report can show them.
START TRANSACTION;

SELECT Stock_Quantity INTO @prev_stock
FROM Inventory
WHERE Product_ID = 11
FOR UPDATE;

-- 1. Create temporary order and reserve stock
INSERT INTO Orders (Order_ID, Customer_ID, Order_Date, Total_Amount, Order_Status)
VALUES (5004, 102, '2026-07-22', 20000, 'Pending');

INSERT INTO Order_Details (Order_ID, Product_ID, Quantity, Price)
VALUES (5004, 11, 1, 20000);

UPDATE Inventory
SET Stock_Quantity = Stock_Quantity - 1
WHERE Product_ID = 11;

INSERT INTO Inventory_Log
    (Product_ID, Order_ID, Action_Type, Previous_Stock, Current_Stock, Quantity_Changed)
VALUES (11, 5004, 'SOLD', @prev_stock, @prev_stock - 1, 1);

-- 2. Payment fails
INSERT INTO Payment (Payment_ID, Order_ID, Payment_Method, Payment_Status)
VALUES (9004, 5004, 'UPI', 'Failed');

-- 3. Cancel order
UPDATE Orders
SET Order_Status = 'Cancelled'
WHERE Order_ID = 5004;

-- 4. Restore stock
UPDATE Inventory
SET Stock_Quantity = Stock_Quantity + 1
WHERE Product_ID = 11;

INSERT INTO Inventory_Log
    (Product_ID, Order_ID, Action_Type, Previous_Stock, Current_Stock, Quantity_Changed)
VALUES (11, 5004, 'RESTORED', @prev_stock - 1, @prev_stock, 1);

COMMIT;
-- Expected: Order = Cancelled, Payment = Failed, Mobile stock back to 50

-- ---------- REUSABLE STORED PROCEDURE (handles every case) ----------
-- Success          -> order Completed, stock reduced, COMMIT
-- Stock unavailable-> ROLLBACK, nothing is saved
-- Payment failed   -> order Cancelled, payment Failed, stock restored, COMMIT
-- SQL error        -> automatic ROLLBACK through the exit handler

DELIMITER $$

CREATE PROCEDURE sp_place_order(
    IN  p_order_id       INT,
    IN  p_customer_id    INT,
    IN  p_product_id     INT,
    IN  p_quantity       INT,
    IN  p_method         VARCHAR(20),
    IN  p_payment_id     INT,
    IN  p_payment_result VARCHAR(10),
    OUT p_message        VARCHAR(100)
)
proc_main: BEGIN
    DECLARE v_stock INT DEFAULT 0;
    DECLARE v_price DECIMAL(10,2) DEFAULT 0;
    DECLARE v_total DECIMAL(10,2) DEFAULT 0;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_message = 'ROLLBACK: SQL error, nothing was saved';
    END;

    START TRANSACTION;

    SELECT Stock_Quantity INTO v_stock
    FROM Inventory
    WHERE Product_ID = p_product_id
    FOR UPDATE;

    SELECT Price INTO v_price
    FROM Product
    WHERE Product_ID = p_product_id;

    -- Stock check
    IF v_stock < p_quantity THEN
        ROLLBACK;
        SET p_message = 'ROLLBACK: stock unavailable, order not created';
        LEAVE proc_main;
    END IF;

    SET v_total = v_price * p_quantity;

    INSERT INTO Orders (Order_ID, Customer_ID, Order_Date, Total_Amount, Order_Status)
    VALUES (p_order_id, p_customer_id, CURDATE(), v_total, 'Pending');

    INSERT INTO Order_Details (Order_ID, Product_ID, Quantity, Price)
    VALUES (p_order_id, p_product_id, p_quantity, v_price);

    UPDATE Inventory
    SET Stock_Quantity = Stock_Quantity - p_quantity
    WHERE Product_ID = p_product_id;

    INSERT INTO Inventory_Log
        (Product_ID, Order_ID, Action_Type, Previous_Stock, Current_Stock, Quantity_Changed)
    VALUES (p_product_id, p_order_id, 'SOLD', v_stock, v_stock - p_quantity, p_quantity);

    IF p_payment_result = 'Success' THEN
        INSERT INTO Payment (Payment_ID, Order_ID, Payment_Method, Payment_Status)
        VALUES (p_payment_id, p_order_id, p_method, 'Success');

        UPDATE Orders
        SET Order_Status = 'Completed'
        WHERE Order_ID = p_order_id;

        COMMIT;
        SET p_message = 'COMMIT: order completed';
    ELSE
        INSERT INTO Payment (Payment_ID, Order_ID, Payment_Method, Payment_Status)
        VALUES (p_payment_id, p_order_id, p_method, 'Failed');

        UPDATE Orders
        SET Order_Status = 'Cancelled'
        WHERE Order_ID = p_order_id;

        UPDATE Inventory
        SET Stock_Quantity = Stock_Quantity + p_quantity
        WHERE Product_ID = p_product_id;

        INSERT INTO Inventory_Log
            (Product_ID, Order_ID, Action_Type, Previous_Stock, Current_Stock, Quantity_Changed)
        VALUES (p_product_id, p_order_id, 'RESTORED', v_stock - p_quantity, v_stock, p_quantity);

        COMMIT;
        SET p_message = 'COMMIT: payment failed, order cancelled, stock restored';
    END IF;
END$$

DELIMITER ;

-- Test 1: successful order (2 Mobile Phones)
CALL sp_place_order(5005, 101, 11, 2, 'Card', 9005, 'Success', @msg);
SELECT @msg AS Result;

-- Test 2: stock unavailable (Tablet has 0 stock) -> ROLLBACK
CALL sp_place_order(5006, 103, 13, 1, 'UPI', 9006, 'Success', @msg);
SELECT @msg AS Result;

-- Test 3: failed payment (5 Mouse) -> cancelled + stock restored
CALL sp_place_order(5007, 102, 12, 5, 'UPI', 9007, 'Failed', @msg);
SELECT @msg AS Result;

-- ============================================================
-- TASK 5: DATABASE CONSISTENCY CHECKS
-- Each query should return ZERO rows when the database is consistent
-- ============================================================

-- 1. Orders must have valid customer IDs
SELECT O.Order_ID, O.Customer_ID
FROM Orders O
LEFT JOIN Customer C ON O.Customer_ID = C.Customer_ID
WHERE C.Customer_ID IS NULL;

-- 2. Payments must have valid order IDs
SELECT P.Payment_ID, P.Order_ID
FROM Payment P
LEFT JOIN Orders O ON P.Order_ID = O.Order_ID
WHERE O.Order_ID IS NULL;

-- 3. Stock quantity must not be negative
SELECT Product_ID, Stock_Quantity
FROM Inventory
WHERE Stock_Quantity < 0;

-- 4. Completed orders must have a successful payment
SELECT O.Order_ID, O.Order_Status
FROM Orders O
WHERE O.Order_Status = 'Completed'
  AND NOT EXISTS (
        SELECT 1 FROM Payment P
        WHERE P.Order_ID = O.Order_ID AND P.Payment_Status = 'Success'
  );

-- 5. Cancelled orders must not reduce inventory
--    (quantity sold must equal quantity restored for every cancelled order)

-- Summary of all five checks (every row should say PASS)
SELECT '1. Orders have valid customers' AS Check_Name,
       CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END AS Result
FROM Orders O
LEFT JOIN Customer C ON O.Customer_ID = C.Customer_ID
WHERE C.Customer_ID IS NULL
UNION ALL
SELECT '2. Payments have valid orders',
       CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END
FROM Payment P
LEFT JOIN Orders O ON P.Order_ID = O.Order_ID
WHERE O.Order_ID IS NULL
UNION ALL
SELECT '3. No negative stock',
       CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END
FROM Inventory
WHERE Stock_Quantity < 0
UNION ALL
SELECT '4. Completed orders have successful payment',
       CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END
FROM Orders O
WHERE O.Order_Status = 'Completed'
  AND NOT EXISTS (
        SELECT 1 FROM Payment P
        WHERE P.Order_ID = O.Order_ID AND P.Payment_Status = 'Success'
  )
UNION ALL
SELECT '5. Cancelled orders did not reduce stock',
       CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END
FROM (
    SELECT O.Order_ID
    FROM Orders O
    JOIN Inventory_Log L ON O.Order_ID = L.Order_ID
    WHERE O.Order_Status = 'Cancelled'
    GROUP BY O.Order_ID
    HAVING SUM(CASE WHEN L.Action_Type = 'SOLD' THEN L.Quantity_Changed ELSE 0 END)
        <> SUM(CASE WHEN L.Action_Type = 'RESTORED' THEN L.Quantity_Changed ELSE 0 END)
) AS Bad_Orders;

-- ============================================================
-- TRANSACTION REPORTS
-- ============================================================

-- REPORT 1: Order Transaction Report
SELECT O.Order_ID,
       C.Customer_Name,
       O.Total_Amount                          AS Amount,
       COALESCE(P.Payment_Status, 'No Payment') AS Payment_Status,
       O.Order_Status
FROM Orders O
JOIN Customer C   ON O.Customer_ID = C.Customer_ID
LEFT JOIN Payment P ON O.Order_ID = P.Order_ID
ORDER BY O.Order_ID;

-- REPORT 2A: Failed payments
SELECT P.Payment_ID,
       P.Order_ID,
       C.Customer_Name,
       P.Payment_Method,
       P.Payment_Status,
       P.Payment_Date
FROM Payment P
JOIN Orders O   ON P.Order_ID = O.Order_ID
JOIN Customer C ON O.Customer_ID = C.Customer_ID
WHERE P.Payment_Status = 'Failed'
ORDER BY P.Payment_ID;

-- REPORT 2B: Cancelled orders
SELECT O.Order_ID,
       C.Customer_Name,
       O.Order_Date,
       O.Total_Amount,
       O.Order_Status
FROM Orders O
JOIN Customer C ON O.Customer_ID = C.Customer_ID
WHERE O.Order_Status = 'Cancelled'
ORDER BY O.Order_ID;

-- REPORT 2C: Stock restoration details
SELECT L.Order_ID,
       Pr.Product_Name,
       L.Previous_Stock   AS Stock_Before_Restore,
       L.Current_Stock    AS Stock_After_Restore,
       L.Quantity_Changed AS Quantity_Restored,
       L.Log_Time
FROM Inventory_Log L
JOIN Product Pr ON L.Product_ID = Pr.Product_ID
WHERE L.Action_Type = 'RESTORED'
ORDER BY L.Log_ID;

-- REPORT 3A: Inventory update report (every stock movement)
SELECT L.Log_ID,
       Pr.Product_Name,
       L.Order_ID,
       L.Action_Type,
       L.Previous_Stock,
       L.Current_Stock,
       L.Quantity_Changed
FROM Inventory_Log L
JOIN Product Pr ON L.Product_ID = Pr.Product_ID
ORDER BY L.Log_ID;

-- REPORT 3B: Inventory update report (summary per product)
-- Quantity_Sold = units sold minus units restored by cancelled orders
SELECT Pr.Product_Name,
       I.Stock_Quantity + COALESCE(N.Net_Sold, 0) AS Previous_Stock,
       I.Stock_Quantity                           AS Current_Stock,
       COALESCE(N.Net_Sold, 0)                    AS Quantity_Sold
FROM Product Pr
JOIN Inventory I ON Pr.Product_ID = I.Product_ID
LEFT JOIN (
    SELECT Product_ID,
           SUM(CASE WHEN Action_Type = 'SOLD' THEN Quantity_Changed
                    ELSE -Quantity_Changed END) AS Net_Sold
    FROM Inventory_Log
    GROUP BY Product_ID
) N ON Pr.Product_ID = N.Product_ID
ORDER BY Pr.Product_ID;