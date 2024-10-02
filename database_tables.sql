CREATE TABLE customers (
    customer_id VARCHAR(50) PRIMARY KEY,
    country VARCHAR(50),
    state VARCHAR(50),
    city VARCHAR(50),
    zip_code VARCHAR(10),
    gender VARCHAR(10),
    senior_citizen ENUM('Yes', 'No'),
    partner ENUM('Yes', 'No'),
    dependents ENUM('Yes', 'No'),
    tenure INT,
    phone_service ENUM('Yes', 'No'),
    multiple_lines ENUM('Yes', 'No'),
    internet_service VARCHAR(20),
    online_security ENUM('Yes', 'No'),
    online_backup ENUM('Yes', 'No'),
    device_protection ENUM('Yes', 'No'),
    tech_support ENUM('Yes', 'No'),
    streaming_tv ENUM('Yes', 'No'),
    streaming_movies ENUM('Yes', 'No'),
    contract VARCHAR(20),
    paperless_billing ENUM('Yes', 'No'),
    payment_method VARCHAR(50),
    monthly_charge DECIMAL(10, 2),
    total_charges DECIMAL(10, 2) DEFAULT NULL,
    churn_label BOOLEAN,
    churn_score INT,
    cltv INT,
    churn_reason VARCHAR(255) DEFAULT NULL
);

CREATE TABLE support (
    ticket_id INT PRIMARY KEY AUTO_INCREMENT,
    customer_id VARCHAR(50),
    issue_date DATE,
    issue_type VARCHAR(50),
    resolution_time INT,
    satisfaction_score INT,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

CREATE TABLE service_usage (
    usage_id INT PRIMARY KEY AUTO_INCREMENT,
    customer_id VARCHAR(50),
    usage_date DATE,
    feature_used VARCHAR(100),
    duration INT,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

CREATE TABLE subscriptions (
    subscription_id INT PRIMARY KEY AUTO_INCREMENT,
    customer_id VARCHAR(50),
    plan_type VARCHAR(50),
    start_date DATE,
    end_date DATE,
    status VARCHAR(20),
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);


-- IMPORT DATA FROM CSV FILE INTO TABLE 'CUSTOMERS'

LOAD DATA LOCAL INFILE '/pathname/Telco_customer_churn.csv'
INTO TABLE customers
FIELDS TERMINATED BY ',' 
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(customer_id, country, state, city, zip_code, gender, senior_citizen, partner, dependents, tenure, 
phone_service, multiple_lines, internet_service, online_security, online_backup, device_protection, 
tech_support, streaming_tv, streaming_movies, contract, paperless_billing, payment_method, 
monthly_charge, @total_charges, churn_label, churn_score, cltv, churn_reason)
SET total_charges = NULLIF(@total_charges, ' ');


-- GENERATE SYNTHETIC DATA FOR THE OTHER 3 TABLES WITH THE 'WHERE' CLAUSE

INSERT INTO support (customer_id, issue_date, issue_type, resolution_time, satisfaction_score)
SELECT 
    customer_id, 
    CURDATE() - INTERVAL FLOOR(RAND() * 365) DAY AS issue_date,
    ELT(FLOOR(1 + (RAND() * 4)), 'Billing Issue', 'Technical Issue', 'Service Issue', 'Other') AS issue_type,
    FLOOR(RAND() * 100) AS resolution_time,
    FLOOR(RAND() * 5) + 1 AS satisfaction_score
FROM customers
WHERE tech_support = 'Yes'
ORDER BY RAND()
LIMIT 7043;

INSERT INTO service_usage (customer_id, usage_date, feature_used, duration)
SELECT 
    customer_id,
    CURDATE() - INTERVAL FLOOR(RAND() * 365) DAY AS usage_date,
    ELT(FLOOR(1 + (RAND() * 6)), 'Internet', 'Phone', 'TV', 'Movies', 'Gaming', 'Streaming') AS feature_used,
    FLOOR(RAND() * 120) AS duration
FROM customers
WHERE internet_service IN ('DSL', 'Fiber Optic', 'Cable')
ORDER BY RAND()
LIMIT 7043;

INSERT INTO subscriptions (customer_id, plan_type, start_date, end_date, status)
SELECT 
    c.customer_id,
    ELT(FLOOR(1 + (RAND() * 3)), 'Basic', 'Standard', 'Premium') AS plan_type,
    sub.start_date,
    CASE 
        WHEN c.churn_label = 1 THEN sub.start_date + INTERVAL FLOOR(30 + (RAND() * 335)) DAY -- Make end date at least 30 days after start date
        ELSE sub.start_date + INTERVAL FLOOR(30 + (RAND() * 335)) DAY
    END AS end_date,
    CASE 
        WHEN c.churn_label = 1 THEN 'Cancelled' -- Set status to Cancelled for churned customers
        ELSE ELT(FLOOR(1 + (RAND() * 2)), 'Active', 'Inactive') -- Random status for active customers
    END AS status
FROM 
    customers AS c
JOIN (
    SELECT 
        customer_id, 
        DATE('2022-01-01') + INTERVAL FLOOR(RAND() * 881) DAY AS start_date -- Generate random start date within the fixed period
    FROM customers
    WHERE contract IN ('Month-to-Month', 'One Year', 'Two Year')
    ORDER BY RAND()
    LIMIT 7043
) AS sub
ON c.customer_id = sub.customer_id;

