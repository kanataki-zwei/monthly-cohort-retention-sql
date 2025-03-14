# Monthly Cohort Retention Analysis (PostgreSQL + Docker)

This project calculates **monthly cohort retention** for customer purchases using **PostgreSQL inside Docker**. The data is expected in CSV format, and PostgreSQL automatically loads it into a database.

---

## **Getting Started**

### **1️⃣ Clone the Repository**
```sh
git clone https://github.com/kanataki-zwei/monthly-cohort-retention-sql.git
cd monthly-cohort-retention-sql
```

---

## **2️⃣ Prepare Dummy Data**
Since the dataset is **not included** in this repository, you must provide your own **dummy CSV file** with the following structure:

#### **Expected CSV Format**    
The data should be stored in the following location: `data/sample_purchase_data.csv`.    
The data format should be as follows:     
| purchase_date | customer_id | purchase_amount |
|--------------|------------|----------------|
| 2024-01-01  | 1001       | 200.50         |
| 2024-01-05  | 1002       | 50.75          |
| 2024-01-10  | 1003       | 300.00         |

#### **CSV Column Details**
- `purchase_date` → **Date** in `YYYY-MM-DD` format (when the purchase happened).
- `customer_id` → **Integer** representing a unique customer ID.
- `purchase_amount` → **Decimal** (amount spent in the transaction).

🔹 **Put this CSV file inside the `data/` folder before running the project.**

---

## **Running the Project with Docker**     
This project assumes you already have docker set up in your machine.

### **3️⃣ Build the Docker Image**
```sh
docker build -t cohort-retention -f docker/Dockerfile .
```

### **4️⃣ Run the PostgreSQL Container**
```sh
docker run -p 5432:5432 -d --name cohort-db cohort-retention
```
🔹 If port **5432 is already in use**, use a different port such as:
```sh
docker run -p 5433:5432 -d --name cohort-db cohort-retention
```

---

## 🛠 **Using the PostgreSQL Database**
### **5️⃣ Connect to PostgreSQL Inside the Docker Container**
```sh
docker exec -it cohort-db psql -U cohort_user -d cohort_db
```
Now, check if the data is loaded:
```sql
SELECT * FROM purchases LIMIT 5;
```

---

## **Running Cohort Retention Analysis**
### **6️⃣ Execute Cohort Query**
Run the SQL file containing the retention query:
```sh
docker exec -it cohort-db psql -U cohort_user -d cohort_db -f /docker-entrypoint-initdb.d/init.sql
```
or manually inside PostgreSQL by copying the query:
```sql
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
```

✅ This will return the **cohort retention matrix**, showing how many users remain active in each month after their first purchase.

---

## **Restarting & Removing the Container**
If you need to **restart** the container:
```sh
docker restart cohort-db
```
If you need to **stop and remove everything**:
```sh
docker stop cohort-db
docker rm cohort-db
docker rmi cohort-retention
```

---

## **Folder Structure**
```
monthly-cohort-retention/
│-- data/                 # (Place your sample CSV data here)
│   ├── sample_purchase_data.csv
│-- docker/               # (Docker setup)
│   ├── Dockerfile
│   ├── init.sql
│-- sql/                  # (SQL queries)
│   ├── schema.sql
│   ├── cohort_retention.sql
│-- .gitignore
│-- README.md
```

---

## **Troubleshooting**
### **1️⃣ PostgreSQL Port Conflict**
If you get an error **"Port 5432 already in use"**, change the port:
```sh
docker run -p 5433:5432 -d --name cohort-db cohort-retention
```

### **2️⃣ No Data in Purchases Table**
If `SELECT * FROM purchases LIMIT 5;` returns **0 rows**, manually load the CSV:
```sql
COPY purchases (customer_id, purchase_date, purchase_amount)
FROM '/docker-entrypoint-initdb.d/sample_purchase_data.csv'
DELIMITER ',' CSV HEADER;
```
---

**Happy Tweaking!** 😊
