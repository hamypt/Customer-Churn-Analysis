-- 1. SUMMARY

-- 1.1. NUMBER OF CUSTOMERS BY CITY

SELECT 
	city AS 'City',
	COUNT(*) AS 'Total Customers'
FROM customers
GROUP BY city
ORDER BY COUNT(*) DESC;

-- 1.2. AVERAGE REVENUE PER USER

SELECT
	AVG(total_charges) AS 'Average Revenue per User'
FROM customers;

-- 1.3. ACTIVE VS CHURNED CUSTOMERS

SELECT
	CASE
		WHEN churn_label = 1 THEN 'Churned'
        ELSE 'Active'
	END AS 'Status',
	COUNT(*) AS 'Number of Customers'
FROM customers
GROUP BY churn_label;

-- 1.4. MONTHLY REVENUE OVER TIME

SELECT 
	DATE_FORMAT(s.usage_date, '%Y-%m') AS 'Month', 
    SUM(c.monthly_charge) AS 'Total Revenue'
FROM customers AS c
JOIN service_usage AS s ON c.customer_id = s.customer_id
GROUP BY `Month`
ORDER BY `Month`;

-- 1.5. CUSTOMER LIFETIME VALUE

SELECT
    CASE 
        WHEN cltv < 3000 THEN 'Low'
        WHEN cltv BETWEEN 3000 AND 5000 THEN 'Medium'
        ELSE 'High'
    END AS 'CLTV Category', 
    COUNT(*) AS 'Total Customers'
FROM customers
GROUP BY `CLTV Category`;


-- 2. SUBSCRIPTION PLANS

-- 2.1. MOST POPULAR PLANS

SELECT 
	plan_type AS 'Plan Type',
    COUNT(*) AS 'Total Customers'
FROM subscriptions
GROUP BY plan_type
ORDER BY COUNT(*) DESC;

-- 2.2. AVERAGE TENURE BY PLANS

SELECT 
	s.plan_type AS 'Plan Type',
    AVG(c.tenure) AS 'Average Tenure'
FROM customers AS c
INNER JOIN subscriptions AS s ON c.customer_id = s.customer_id
GROUP BY s.plan_type
ORDER BY AVG(c.tenure) DESC;


-- 3. CHURN ANALYSIS

-- 3.1. OVERALL CHURN RATE

SELECT
	SUM(CASE WHEN churn_label = 1 THEN 1 ELSE 0 END) / COUNT(customer_id) * 100 AS 'Churn Rate'
FROM customers;

-- 3.2. MONTHLY CHURN RATE

WITH churned_customers AS (
    SELECT
        DATE_FORMAT(end_date, '%Y-%m') AS churn_month,
        COUNT(customer_id) AS churned_count
    FROM subscriptions
    WHERE status = 'Cancelled'
    GROUP BY churn_month
),
active_customers AS (
    SELECT
        DATE_FORMAT(start_date, '%Y-%m') AS active_month,
        COUNT(customer_id) AS active_count
    FROM subscriptions
    WHERE status IN ('Active', 'Inactive')
    GROUP BY active_month
)
SELECT
    ac.active_month AS 'Month',
    ac.active_count AS active_customers,
    IFNULL(cc.churned_count, 0) AS 'Churned Customers',
    ROUND((IFNULL(cc.churned_count, 0) / ac.active_count) * 100, 2) AS 'Churn Rate'
FROM active_customers AS ac
LEFT JOIN churned_customers AS cc ON ac.active_month = cc.churn_month
ORDER BY ac.active_month;

-- 3.3. MOST COMMON CHURN REASONS

SELECT
	churn_reason AS 'Churn Reason',
    COUNT(*) AS 'Total Churned Customers'
FROM customers
WHERE churn_label = 1
GROUP BY churn_reason
ORDER BY COUNT(*) DESC;


-- 4. CUSTOMER SUPPORT PERFORMANCE

-- 4.1. MOST COMMON ISSUES

SELECT
	issue_type AS 'Issue Type',
    COUNT(*) AS 'Total Tickets'
FROM support
GROUP BY issue_type
ORDER BY COUNT(*) DESC;

-- 4.2. RESOLUTION TIME BY ISSUES

SELECT
	issue_type AS 'Issue Type',
    AVG(resolution_time) AS 'Average Resolution Time'
FROM support
GROUP BY issue_type
ORDER BY AVG(resolution_time);

-- 4.3. RESOLUTION TIME AND SATISFACTION SCORE

SELECT 
	resolution_time, 
    AVG(satisfaction_score) AS 'Average Satisfaction'
FROM support
GROUP BY resolution_time
ORDER BY resolution_time;

-- 4.4. RESOLUTION TIME AND CHURN RELATIONSHIP

SELECT 
    s.customer_id AS 'Customer ID', 
    AVG(s.resolution_time) AS 'Average Resolution Time', 
    CASE WHEN c.churn_label = 1 THEN 'Churned' ELSE 'Active' END AS 'Churn Label'
FROM support AS s
JOIN customers AS c ON s.customer_id = c.customer_id
GROUP BY s.customer_id, c.churn_label
ORDER BY AVG(s.resolution_time) DESC;

-- 4.5. ISSUE TYPES AND CHURN STATUS

SELECT
	s.issue_type AS 'Issue Type',
    CASE WHEN c.churn_label = 1 THEN 'Churned' ELSE 'Active' END AS 'Churn Status',
    AVG(s.satisfaction_score) AS 'Average Satisfaction Score',
    AVG(s.resolution_time) AS 'Average Resolution Time',
    COUNT(*) AS 'Total Tickets'
FROM support AS s
JOIN customers AS c ON s.customer_id = c.customer_id
GROUP BY s.issue_type, c.churn_label
ORDER BY s.issue_type, c.churn_label;


-- 5. SERVICE USAGE

-- 5.1 MOST USED SERVICES

SELECT
	feature_used AS 'Service Type',
    COUNT(*) AS 'Times Used',
    SUM(duration) AS 'Duration'
FROM service_usage
GROUP BY feature_used
ORDER BY COUNT(*) DESC;

-- 5.2. AVERAGE DURATION OF SERVICES

SELECT
	feature_used AS 'Service Type',
    AVG(duration) AS 'Average Duration'
FROM service_usage
GROUP BY feature_used
ORDER BY AVG(duration) DESC;


-- 6. PAYMENTS

-- 6.1. TOTAL REVENUES

SELECT
	SUM(total_charges) AS 'Total Revenues'
FROM customers;

-- 6.2. DISTRIBUTION OF PAYMENT METHODS

SELECT
	payment_method AS 'Payment Method',
    SUM(total_charges) AS 'Total Revenues'
FROM customers
GROUP BY payment_method
ORDER BY SUM(total_charges) DESC;


-- 7. CUSTOMER LIFETIME VALUE ANALYSIS

-- 7.1. CHURNED VS RETAINED CLTV

SELECT
	CASE 
		WHEN churn_label = 1 THEN 'Churned' 
        ELSE 'Active' 
	END AS 'Churn Label',
    AVG(cltv) AS 'Average CLTV',
    COUNT(customer_id) AS 'Total Customers'
FROM customers
GROUP BY churn_label;

-- 7.2. CHURN REASON BY CLTV

SELECT
	churn_reason AS 'Churn Reason',
    AVG(cltv) AS 'Average CLTV',
    COUNT(customer_id) AS 'Total Customers'
FROM customers
WHERE churn_label = 1
GROUP BY churn_reason
ORDER BY AVG(cltv) DESC;
