create table payment(
Payment_ID int auto_increment,
Order_ID int NOT NULL,
Payment_Date timestamp default current_timestamp,
Payment_Mode VARCHAR(100),
Payment_Status VARCHAR(100),
Transaction_Amount decimal(10,2),

constraint pk_key primary key (Payment_ID),
constraint chk_amt CHECK(Transaction_Amount >0),
constraint fk_key foreign key (Order_ID) references orders(Order_ID)
);

select * FROM Orders;

insert into payment(Order_ID, Payment_Mode, Payment_Status, Transaction_Amount) values
(1, "UPI", "pending",450),
(2, "credit card", "successfull",450),
(3, "debit card", "successfull",450),
(4, "Cash on delivery", "successfull",1450),
(5, "debit card", "failed",5000);


select * FROM payment;

-- Display all successful payments.

select * from payment where Payment_Status = "successfull";

-- Find failed transactions.

select * from payment where Payment_Status = "failed";

-- Count total successful and failed payments.

select
count(*) as Number_of_Transcations, Payment_Mode
from payment group by Payment_Mode;

select
count(*) as Number_of_Transcations, Payment_Status
from payment group by Payment_Status;

select * from payment where Payment_Status = "failed";

-- Update failed payments after retry.

update payment set Payment_Status = "Successful" where Payment_ID = 10;

-- Identify pending transactions.

select * from payment where Payment_Status = "Pending";

 -- REPORT 1: PAYMENT MODE ANALYSIS
SELECT
    SUM(Payment_Mode = 'UPI') AS UPI_Transactions,
    SUM(Payment_Mode = 'CREDIT CARD') AS Card_Payments,
    (
        SELECT Payment_Mode
        FROM Payment
        GROUP BY Payment_Mode
        ORDER BY COUNT(*) DESC
        LIMIT 1
    ) AS Most_Preferred_Payment_Method
FROM Payment;

-- REPORT 2: REVENUE ANALYSIS
SELECT
    SUM(Transaction_Amount) AS Total_Revenue,
    AVG(Transaction_Amount) AS Average_Transaction_Amount,
    SUM(CASE WHEN Payment_Mode = 'UPI'
             THEN Transaction_Amount ELSE 0 END) AS UPI_Revenue,
    SUM(CASE WHEN Payment_Mode = 'CREDIT CARD'
             THEN Transaction_Amount ELSE 0 END) AS Card_Revenue,
    SUM(CASE WHEN Payment_Mode IN ('COD', 'CASH ON DELIVERY')
             THEN Transaction_Amount ELSE 0 END) AS COD_Revenue
FROM Payment
WHERE Payment_Status = 'SUCCESSFUL';

-- REPORT 3: CUSTOMER PAYMENT HISTORY
SELECT
    c.Customer_Name,
    o.Order_ID,
    p.Payment_Mode,
    p.Transaction_Amount AS Amount,
    p.Payment_Status
FROM Customers c
JOIN Orders o
    ON c.Customer_ID = o.Customer_ID
JOIN Payment p
    ON o.Order_ID = p.Order_ID
ORDER BY c.Customer_Name;