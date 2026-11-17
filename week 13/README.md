-- WEEK 13: DATABASE SECURITY AND PERFORMANCE OPTIMIZATION

-- 20,000 generated products plus 3 named products

<img width="491" height="124" alt="image" src="https://github.com/user-attachments/assets/f3728331-46da-4982-b545-a0792116be8e" />

<img width="518" height="122" alt="image" src="https://github.com/user-attachments/assets/d4586908-f199-4b67-87b2-93ca11525914" />

-- 100,000 orders (dates from 2024-01-01 to 2025-12-30)

<img width="659" height="100" alt="image" src="https://github.com/user-attachments/assets/74025929-f870-485f-aabb-113bcb757b7f" />

-- 150,000 order lines (every order has line 1, even orders also have line 2)

<img width="633" height="128" alt="image" src="https://github.com/user-attachments/assets/38780e2a-c997-4ae2-8217-8abadc7292c6" />

<img width="522" height="129" alt="image" src="https://github.com/user-attachments/assets/81eb0ece-dbb0-4efe-836d-4274375cbbf9" />

-- Payments for the first 2,000 orders that were completed

<img width="529" height="123" alt="image" src="https://github.com/user-attachments/assets/f01d67f5-0159-47c0-97c5-e0db88e896eb" />

-- Row count check. Expected: 20000 | 20003 | 100000 | 150000 | 1600

<img width="573" height="97" alt="image" src="https://github.com/user-attachments/assets/c638b6e7-4687-4fa6-8c50-a8185ef7e01a" />

-- A safe view for reporting: no email, phone or payment data

<img width="637" height="122" alt="image" src="https://github.com/user-attachments/assets/5b16b13f-f500-4ac8-80d9-8fe06f8bd529" />

-- Indexes that exist right now (only PRIMARY KEYS and foreign-key helpers)

<img width="590" height="122" alt="image" src="https://github.com/user-attachments/assets/f1bdda90-a450-4675-86be-8124d4e5a107" />

-- Indexes after optimization

<img width="562" height="127" alt="image" src="https://github.com/user-attachments/assets/02a42b0b-86f3-4740-839f-ac4dad43bcdf" />

-- Query 1: Search products by category

<img width="572" height="127" alt="image" src="https://github.com/user-attachments/assets/4907d037-a4c9-40f3-8826-4afcd72c5de5" />

-- Query 2: Customer order history (newest first)

<img width="510" height="123" alt="image" src="https://github.com/user-attachments/assets/93875f48-e7c4-4f0e-9f6d-6e411291dbf4" />

-- Query 3: Sales report for March 2025 (completed orders, per day)

<img width="494" height="128" alt="image" src="https://github.com/user-attachments/assets/f5b42dcc-5868-4573-905b-bb02483d239e" />

-- Query 4: Top 10 selling products

<img width="603" height="124" alt="image" src="https://github.com/user-attachments/assets/1f8f30b8-2bc9-4bb1-89ff-af5a2fca7c0b" />

-- REPORT 1A: User Access Report - user, assigned role, permissions

<img width="560" height="110" alt="image" src="https://github.com/user-attachments/assets/be69119b-f4f1-4eb7-8749-f5f1629f0d6c" />

-- REPORT 1B: Table-level privileges actually held by each user

<img width="539" height="124" alt="image" src="https://github.com/user-attachments/assets/62774e43-ef5c-4459-a063-725c382a6191" />

-- REPORT 1C: Column-level privileges

<img width="560" height="131" alt="image" src="https://github.com/user-attachments/assets/e4434c9b-2b2c-4c6c-8f18-ca849739f342" />

-- REPORT 1D: Admin user - database-wide and global privileges

<img width="540" height="102" alt="image" src="https://github.com/user-attachments/assets/30ff9d70-5a36-4a9f-8c0f-3c1661893fe7" />

-- REPORT 2: Query Performance Report (before vs after indexes)

<img width="608" height="126" alt="image" src="https://github.com/user-attachments/assets/7f72990d-2cf1-4ed8-b724-583c33fa17fd" />

-- REPORT 3A: Database Security Report - granted and revoked permissions

<img width="654" height="107" alt="image" src="https://github.com/user-attachments/assets/c698487b-e236-47ec-b0a0-290fe9bd1c36" />

-- REPORT 3B: Database accounts that exist for this project

<img width="446" height="123" alt="image" src="https://github.com/user-attachments/assets/ba7cd4c6-eb45-407a-b27b-936379244045" />

-- Which user holds which role

<img width="512" height="119" alt="image" src="https://github.com/user-attachments/assets/c5793329-74bf-45c2-a958-63ba096f5ed6" />






























































































