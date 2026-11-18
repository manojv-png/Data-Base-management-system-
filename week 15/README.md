-- WEEK 15: INDUSTRY CAPSTONE PROJECT

-- Version check. Expected: OK - MySQL 8.0 or newer detected

<img width="554" height="80" alt="image" src="https://github.com/user-attachments/assets/833cffec-9400-47af-bffd-7ffe3cff4922" />

-- ---------- Schema documentation straight from the database ----------

<img width="572" height="297" alt="image" src="https://github.com/user-attachments/assets/f3f9f374-f676-44af-ac11-b471ddeb5832" />

-- Primary keys

<img width="566" height="244" alt="image" src="https://github.com/user-attachments/assets/e91162b2-086a-48cb-b1c1-6e212cb93173" />

-- Foreign keys = the relationships of the ER diagram

<img width="581" height="201" alt="image" src="https://github.com/user-attachments/assets/9e28173b-10e5-41a9-975b-ef2bd7fbf9f3" />

-- 50 customers: 10 first names x 5 last names = 50 different people

<img width="659" height="284" alt="image" src="https://github.com/user-attachments/assets/0898d064-c035-49f8-9c85-de901992941c" />

-- 100 products (loaded through a staging table, then given a seller)

<img width="654" height="299" alt="image" src="https://github.com/user-attachments/assets/b02c3752-8327-4fc2-ad02-1fd7fa438e63" />

-- Stock between 0 and 149 units, reorder level 20 for every product

<img width="582" height="294" alt="image" src="https://github.com/user-attachments/assets/c9e541e4-fa2e-4379-8f19-eead4b8b4605" />

-- The three products inside one order are always different.

<img width="655" height="282" alt="image" src="https://github.com/user-attachments/assets/bb819bde-9f59-4033-9722-06d319c884a6" />

<img width="654" height="276" alt="image" src="https://github.com/user-attachments/assets/296a12b6-9c6f-4656-8c80-d2f6c68c4601" />

<img width="656" height="273" alt="image" src="https://github.com/user-attachments/assets/ee785030-b28f-4ea7-9d7a-52c1314c9820" />

-- Order totals are calculated from the lines, so they always match

<img width="649" height="294" alt="image" src="https://github.com/user-attachments/assets/b925e431-1a54-4541-95f8-a50d4655c819" />

<img width="558" height="295" alt="image" src="https://github.com/user-attachments/assets/99e87eec-3465-45fd-bf03-25a3378dc555" />

-- 100 payments, one per order. Status follows the order.

<img width="655" height="278" alt="image" src="https://github.com/user-attachments/assets/8d0a395a-9859-4f14-85fb-002d67093a51" />

-- 50 reviews, always from a customer who really bought the product

<img width="610" height="302" alt="image" src="https://github.com/user-attachments/assets/52aaf353-1f77-463c-9e6e-5a9f5ed195f9" />

-- ---------- Data requirement check (every row must say PASS) ----------

<img width="558" height="213" alt="image" src="https://github.com/user-attachments/assets/b0f9be95-4316-40b3-a931-4da4967caa3a" />

-- ---------- Data quality check: no duplicates, valid relationships ----------

<img width="558" height="218" alt="image" src="https://github.com/user-attachments/assets/2085ee4e-0e68-4e25-a419-67a794f81fc9" />

-- TASK 4: SQL QUERIES

<img width="569" height="233" alt="image" src="https://github.com/user-attachments/assets/f45cf26e-ab4d-4400-adc7-b982be36107c" />

<img width="614" height="286" alt="image" src="https://github.com/user-attachments/assets/344e60e2-414c-4bd5-b032-c657b5e8acbc" />

<img width="559" height="209" alt="image" src="https://github.com/user-attachments/assets/930d1e6c-2927-4c68-9ae2-283f2934d4b6" />

<img width="286" height="221" alt="image" src="https://github.com/user-attachments/assets/501ebaa8-de4c-4881-b91a-ca5214ddd6f8" />

<img width="575" height="274" alt="image" src="https://github.com/user-attachments/assets/d9927dcd-11a2-4c41-9a83-928200800246" />

<img width="542" height="298" alt="image" src="https://github.com/user-attachments/assets/240eb76e-46d2-46bf-8df8-87a6e2b7ef56" />

<img width="446" height="230" alt="image" src="https://github.com/user-attachments/assets/1a580602-8f71-485b-a1f7-7e0ea7361a1d" />

-- INNER JOIN: customer orders

<img width="570" height="291" alt="image" src="https://github.com/user-attachments/assets/bf7bab41-ebc9-43a7-b4d0-adfd73012fd2" />





































































































































































































































































































