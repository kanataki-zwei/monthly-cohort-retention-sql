WITH cohort AS (
    SELECT 
        customer_id,
        MIN(DATE_TRUNC('month', purchase_date)) AS cohort_month
    FROM purchases
    GROUP BY customer_id
),
purchases_with_cohort AS (
    SELECT 
        c.cohort_month,
        DATE_TRUNC('month', p.purchase_date) AS active_month,
        p.customer_id
    FROM purchases p
    JOIN cohort c ON p.customer_id = c.customer_id
)
SELECT 
    cohort_month,
    active_month,
    COUNT(DISTINCT customer_id) AS user_count
FROM purchases_with_cohort
GROUP BY cohort_month, active_month
ORDER BY cohort_month, active_month;
