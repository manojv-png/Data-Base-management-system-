SELECT *
FROM Customers;

<img width="696" height="212" alt="image" src="https://github.com/user-attachments/assets/f1a2fd3f-ad9d-49c4-ac80-c183c1543f7c" />

SELECT *
FROM Products;

<img width="683" height="218" alt="image" src="https://github.com/user-attachments/assets/025a44a0-5142-4b74-85a7-0404cc77e1c9" />

SELECT Product_Name, Price
FROM Products;

<img width="685" height="209" alt="image" src="https://github.com/user-attachments/assets/9fe4a5d8-0dc5-40b9-a400-e7a0ca1931d2" />

SELECT *
FROM Orders;

<img width="686" height="214" alt="image" src="https://github.com/user-attachments/assets/23e9bed4-daba-42ce-aebd-624abdb75361" />

SELECT *
FROM Payment;

<img width="684" height="180" alt="image" src="https://github.com/user-attachments/assets/bd1820d9-b669-426d-af4f-11f0e5b1f29c" />

SELECT *
FROM Customers
WHERE City = 'Chennai';

<img width="685" height="206" alt="image" src="https://github.com/user-attachments/assets/bdec32b3-9702-486e-bcd5-815bc37b991b" />

SELECT *
FROM Products
ORDER BY Price ASC;

<img width="684" height="194" alt="image" src="https://github.com/user-attachments/assets/705655ce-a2f8-454c-b397-4137a886f1f2" />

SELECT *
FROM Customers
ORDER BY Customer_Name ASC;

<img width="685" height="211" alt="image" src="https://github.com/user-attachments/assets/c3bf05ae-696f-4968-84f0-a087686720d8" />

SELECT *
FROM Products
ORDER BY Price DESC
LIMIT 5;

<img width="680" height="216" alt="image" src="https://github.com/user-attachments/assets/6a56f863-a6ee-4843-8ee5-6c153cb23bf1" />

SELECT *
FROM Products
ORDER BY Price DESC
LIMIT 5;

<img width="685" height="226" alt="image" src="https://github.com/user-attachments/assets/05234227-0efa-47cf-aa3c-e8a39d1cf58f" />

SELECT *
FROM Orders
ORDER BY Order_Date DESC;

<img width="682" height="216" alt="image" src="https://github.com/user-attachments/assets/787b98bb-db2b-4fdf-b155-7d8f8b602cc9" />

SELECT *
FROM Products
WHERE Price BETWEEN 1000 AND 5000;

<img width="686" height="186" alt="image" src="https://github.com/user-attachments/assets/ba0695c4-994f-4a45-a371-247ba8f2eeb4" />

SELECT *
FROM Products
WHERE Category_ID = 1;

<img width="683" height="208" alt="image" src="https://github.com/user-attachments/assets/3ea84e71-f8aa-46a0-bf44-1322d6c9f3e4" />

SELECT c.Customer_Name, o.Order_ID, o.Order_Date
FROM Customers c
JOIN Orders o ON c.Customer_ID = o.Customer_ID;

<img width="684" height="189" alt="image" src="https://github.com/user-attachments/assets/066207c9-5dd1-4645-92ee-bb5834f99d90" />

SELECT p.Product_Name, c.Category_Name
FROM Products p
JOIN Categories c ON p.Category_ID = c.Category_ID;

<img width="682" height="186" alt="image" src="https://github.com/user-attachments/assets/b006a6e6-4649-44e8-8594-a568e394625b" />


SELECT c.Customer_Name
FROM Customers c
JOIN Orders o ON c.Customer_ID = o.Customer_ID
JOIN Order_Details od ON o.Order_ID = od.Order_ID
WHERE od.Product_ID = 1;

<img width="681" height="192" alt="image" src="https://github.com/user-attachments/assets/b6a866bc-46d5-4ed4-9b2b-c664cf390915" />

SELECT c.Customer_Name, p.Product_Name
FROM Customers c
JOIN Orders o ON c.Customer_ID = o.Customer_ID
JOIN Order_Details od ON o.Order_ID = od.Order_ID
JOIN Products p ON od.Product_ID = p.Product_ID;

<img width="624" height="217" alt="image" src="https://github.com/user-attachments/assets/456b391f-d7e8-45e5-a4ac-57370867a1e8" />

SELECT Product_Name, Price, Stock_Quantity
FROM Products;

<img width="685" height="220" alt="image" src="https://github.com/user-attachments/assets/9bceaa18-02db-4e9c-86cc-af39e99054c0" />

SELECT Product_Name, Price
FROM Products
ORDER BY Price DESC
LIMIT 5;

<img width="649" height="186" alt="image" src="https://github.com/user-attachments/assets/ab4227ed-8e8b-4e3b-8fe9-b382dd96959f" />




