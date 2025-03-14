WITH cohort_items AS 
(
SELECT 
    customer_id,
    MIN(DATE_TRUNC('month', purchase_date)) AS cohort_month
FROM purchases
    GROUP BY customer_id
),

cohort_diff AS 
(
SELECT
    a.customer_id,
    DATE_TRUNC('month', a.purchase_date) purchase_month,
    b.cohort_month,
    DATE_PART('month', AGE(a.purchase_date, b.cohort_month)) AS month_number
FROM purchases a 
LEFT JOIN cohort_items b ON a.customer_id = b.customer_id
),

cohort_size AS 
(
SELECT 
    cohort_month,
    count(customer_id) num_customers
FROm cohort_items
    GROUP BY cohort_month
),

retention_table AS
(
SELECT
    b.cohort_month,
    a.month_number,
    count(distinct a.customer_id) num_customers
FROM cohort_diff a 
LEFT JOIN cohort_items b ON  a.customer_id = b.customer_id
    GROUP BY b.cohort_month, a.month_number
)

SELECT 
    a.cohort_month,
    extract(year from a.cohort_month) cohort_yr,
    dense_rank () over (order by extract(year from a.cohort_month) asc, extract(month from a.cohort_month)asc ) cohort_yr_rnk,
    b.num_customers total_customers,
    a.month_number,
    cast(a.num_customers as numeric)/b.num_customers retention_rate
FROM retention_table a 
LEFT JOIN cohort_size b ON a.cohort_month = b.cohort_month
    WHERE a.cohort_month IS NOT NULL
    GROUP BY a.cohort_month, a.month_number, a.num_customers, b.num_customers;