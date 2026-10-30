-- E-Commerce Data Analytics & Data Quality Pipeline
------------------------------------------------------------------
-- 1: Create the tables in Oracle SQL
------------------------------------------------------------------
CREATE TABLE customers (
    customer_id NUMBER PRIMARY KEY,
    customer_name VARCHAR2(100) NOT NULL,
    email VARCHAR2(150) NOT NULL UNIQUE,
    registration_date DATE DEFAULT SYSDATE NOT NULL
);

CREATE TABLE products (
    product_id NUMBER PRIMARY KEY,
    product_name VARCHAR2(150) NOT NULL,
    current_price NUMBER(10,2) NOT NULL,
    stock_quantity NUMBER DEFAULT 0 NOT NULL,

    CONSTRAINT chk_product_price
        CHECK (current_price >= 0),

    CONSTRAINT chk_product_stock
        CHECK (stock_quantity >= 0)
);

CREATE TABLE orders (
    order_id NUMBER PRIMARY KEY,
    customer_id NUMBER NOT NULL,
    order_date DATE DEFAULT SYSDATE NOT NULL,
    status VARCHAR2(20) DEFAULT 'PENDING' NOT NULL,

    CONSTRAINT fk_orders_customer
        FOREIGN KEY (customer_id)
        REFERENCES customers(customer_id),

    CONSTRAINT chk_order_status
        CHECK (
            status IN (
                'PENDING',
                'SHIPPED',
                'DELIVERED',
                'CANCELLED'
            )
        )
);

CREATE TABLE order_items (
    order_id NUMBER NOT NULL,
    product_id NUMBER NOT NULL,
    quantity NUMBER NOT NULL,
    unit_price NUMBER(10,2) NOT NULL,

    CONSTRAINT pk_order_items
        PRIMARY KEY (order_id, product_id),

    CONSTRAINT fk_items_order
        FOREIGN KEY (order_id)
        REFERENCES orders(order_id),

    CONSTRAINT fk_items_product
        FOREIGN KEY (product_id)
        REFERENCES products(product_id),

    CONSTRAINT chk_item_quantity
        CHECK (quantity > 0),

    CONSTRAINT chk_item_price
        CHECK (unit_price >= 0)
);

------------------------------------------------------------------
-- 2: Insert sample data
------------------------------------------------------------------
INSERT INTO customers
    (customer_id, customer_name, email, registration_date)
VALUES
    (1, 'Mona Ali', 'mona@example.com',
     TO_DATE('2026-01-10', 'YYYY-MM-DD'));

INSERT INTO customers
    (customer_id, customer_name, email, registration_date)
VALUES
    (2, 'Omar Hassan', 'omar@example.com',
     TO_DATE('2026-01-15', 'YYYY-MM-DD'));

INSERT INTO customers
    (customer_id, customer_name, email, registration_date)
VALUES
    (3, 'Sara Ahmed', 'sara@example.com',
     TO_DATE('2026-02-02', 'YYYY-MM-DD'));

INSERT INTO customers
    (customer_id, customer_name, email, registration_date)
VALUES
    (4, 'Ali Mostafa', 'ali@example.com',
     TO_DATE('2026-02-18', 'YYYY-MM-DD'));
     
SELECT *
FROM customers
ORDER BY customer_id;

INSERT INTO products VALUES (101, 'Laptop', 25000, 10);
INSERT INTO products VALUES (102, 'Mouse', 500, 50);
INSERT INTO products VALUES (103, 'Keyboard', 1200, 30);
INSERT INTO products VALUES (104, 'Monitor', 6000, 15);

SELECT *
FROM products
ORDER BY product_id;

INSERT INTO orders
    (order_id, customer_id, order_date, status)
VALUES
    (1001, 1, TO_DATE('2026-01-20', 'YYYY-MM-DD'), 'DELIVERED');

INSERT INTO orders
    (order_id, customer_id, order_date, status)
VALUES
    (1002, 2, TO_DATE('2026-01-25', 'YYYY-MM-DD'), 'SHIPPED');

INSERT INTO orders
    (order_id, customer_id, order_date, status)
VALUES
    (1003, 1, TO_DATE('2026-02-05', 'YYYY-MM-DD'), 'DELIVERED');

INSERT INTO orders
    (order_id, customer_id, order_date, status)
VALUES
    (1004, 3, TO_DATE('2026-02-10', 'YYYY-MM-DD'), 'CANCELLED');

INSERT INTO orders
    (order_id, customer_id, order_date, status)
VALUES
    (1005, 4, TO_DATE('2026-02-20', 'YYYY-MM-DD'), 'PENDING');

INSERT INTO orders
    (order_id, customer_id, order_date, status)
VALUES
    (1006, 2, TO_DATE('2026-03-03', 'YYYY-MM-DD'), 'DELIVERED');
    
SELECT order_id, customer_id, order_date, status
FROM orders
ORDER BY order_date;

-- Order 1001: Delivered
INSERT INTO order_items VALUES (1001, 101, 1, 25000);
INSERT INTO order_items VALUES (1001, 102, 2, 500);

-- Order 1002: Shipped
INSERT INTO order_items VALUES (1002, 103, 1, 1200);
INSERT INTO order_items VALUES (1002, 102, 1, 500);

-- Order 1003: Delivered
INSERT INTO order_items VALUES (1003, 104, 2, 6000);

-- Order 1004: Cancelled
INSERT INTO order_items VALUES (1004, 102, 3, 500);

-- Order 1005: Pending
INSERT INTO order_items VALUES (1005, 103, 2, 1200);

-- Order 1006: Delivered
INSERT INTO order_items VALUES (1006, 101, 1, 24500);
INSERT INTO order_items VALUES (1006, 104, 1, 6000);

----------------------------------------------------------------

COMMIT;

----------------------------------------------------------------

SELECT 'CUSTOMERS' AS table_name, COUNT(*) AS row_count
FROM customers
UNION ALL
SELECT 'PRODUCTS', COUNT(*) FROM products
UNION ALL
SELECT 'ORDERS', COUNT(*) FROM orders
UNION ALL
SELECT 'ORDER_ITEMS', COUNT(*) FROM order_items;

-----------------------------------------------------------------
-- revenue analytics
-- ??? Business Query: ???? ???? ?? Order
SELECT
    order_id,
    SUM(quantity * unit_price) AS order_total
FROM order_items
GROUP BY order_id
ORDER BY order_id;

-- ?????? ??? Revenue ?? ??????? ??? DELIVERED ???
SELECT
    oi.order_id,
    SUM(oi.quantity * oi.unit_price) AS order_total
FROM order_items oi
JOIN orders o
    ON oi.order_id = o.order_id
WHERE o.status = 'DELIVERED'
GROUP BY oi.order_id
ORDER BY oi.order_id;

-- How much revenue did the store generate each month?
SELECT
    TO_CHAR(TRUNC(o.order_date, 'MM'), 'YYYY-MM')
        AS revenue_month,
    SUM(oi.quantity * oi.unit_price) AS total_revenue
FROM orders o
JOIN order_items oi
    ON o.order_id = oi.order_id
WHERE o.status = 'DELIVERED'
GROUP BY TRUNC(o.order_date, 'MM')
ORDER BY TRUNC(o.order_date, 'MM');

-- Which products generated the highest revenue from delivered orders?
SELECT
    p.product_id,
    p.product_name,
    SUM(oi.quantity * oi.unit_price) AS total_revenue
FROM products p
JOIN order_items oi
    ON p.product_id = oi.product_id
JOIN orders o
    ON oi.order_id = o.order_id
WHERE o.status = 'DELIVERED'
GROUP BY
    p.product_id,
    p.product_name
ORDER BY total_revenue DESC;

-- ?????? ???? ?? ????????? ??? ???????? ???? ??????? ?? ????? ?? ????? DELIVERED? ????? ????????? 0 ??? ?? ?????
SELECT
    p.product_id,
    p.product_name,
    COALESCE(
        SUM(
            CASE
                WHEN o.status = 'DELIVERED'
                THEN oi.quantity * oi.unit_price
                ELSE 0
            END
        ),
        0
    ) AS total_revenue
FROM products p
LEFT JOIN order_items oi
    ON p.product_id = oi.product_id
LEFT JOIN orders o
    ON oi.order_id = o.order_id
GROUP BY
    p.product_id,
    p.product_name
ORDER BY total_revenue DESC;

-------------------------------------------------------------------
-- 3: Data Quality Checks
-------------------------------------------------------------------
-- Check 1 — Completeness — ???????? ?? ?????
-- ????? ?? ????? ??????? NULL ?? ??????? ????????
SELECT 'CUSTOMERS' AS table_name,
       COUNT(*) AS total_rows,
       SUM(CASE WHEN customer_name IS NULL
                THEN 1 ELSE 0 END) AS missing_names,
       SUM(CASE WHEN email IS NULL
                THEN 1 ELSE 0 END) AS missing_emails
FROM customers

UNION ALL

SELECT 'PRODUCTS',
       COUNT(*),
       SUM(CASE WHEN product_name IS NULL
                THEN 1 ELSE 0 END),
       0
FROM products

UNION ALL

SELECT 'ORDERS',
       COUNT(*),
       SUM(CASE WHEN customer_id IS NULL
                THEN 1 ELSE 0 END),
       0
FROM orders;
   
-- Check 2 — Uniqueness — ???? ????? ??? ?????
SELECT
    email,
    COUNT(*) AS duplicate_count
FROM customers
GROUP BY email
HAVING COUNT(*) > 1;

SELECT
    order_id,
    product_id,
    COUNT(*) AS duplicate_count
FROM order_items
GROUP BY order_id, product_id
HAVING COUNT(*) > 1;

-- Check 3 — Validity — ????? ??????
SELECT
    product_id,
    product_name,
    current_price,
    stock_quantity
FROM products
WHERE current_price < 0
   OR stock_quantity < 0;
   
SELECT
    order_id,
    product_id,
    quantity,
    unit_price
FROM order_items
WHERE quantity <= 0
   OR unit_price < 0;

-- Check 4 — Referential Integrity — ???????? ?????
-- Check for orders whose customer does not exist
SELECT
    o.order_id,
    o.customer_id
FROM orders o
LEFT JOIN customers c
    ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL;

-- Check for order items whose order does not exist
SELECT
    oi.order_id,
    oi.product_id
FROM order_items oi
LEFT JOIN orders o
    ON oi.order_id = o.order_id
WHERE o.order_id IS NULL;

-- Check for order items whose product does not exist
SELECT
    oi.order_id,
    oi.product_id
FROM order_items oi
LEFT JOIN products p
    ON oi.product_id = p.product_id
WHERE p.product_id IS NULL;

-- Check 5 — Freshness — ???????? ?????
SELECT
    MAX(order_date) AS latest_order_date,
    TRUNC(SYSDATE) - TRUNC(MAX(order_date))
        AS days_since_latest_order
FROM orders;

-- Pipeline Freshness:
-- 1: Create the run log
CREATE TABLE pipeline_run_log (
    run_id NUMBER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    pipeline_name VARCHAR2(100) NOT NULL,
    run_status VARCHAR2(20) NOT NULL,
    started_at TIMESTAMP NOT NULL,
    finished_at TIMESTAMP,
    rows_processed NUMBER DEFAULT 0,
    CONSTRAINT chk_pipeline_status
        CHECK (run_status IN ('SUCCESS', 'FAILED', 'RUNNING'))
);

-- 2: Add a simulated successful run (this does not execute an automated pipeline)
INSERT INTO pipeline_run_log (
    pipeline_name,
    run_status,
    started_at,
    finished_at,
    rows_processed
)
VALUES (
    'ecommerce_pipeline',
    'SUCCESS',
    SYSTIMESTAMP - INTERVAL '2' HOUR,
    SYSTIMESTAMP - INTERVAL '1' HOUR,
    23
);

COMMIT;

-- 3: Check pipeline-log freshness using the simulated run above
SELECT
    pipeline_name,
    MAX(finished_at) AS last_successful_run,
    ROUND(
        (CAST(SYSTIMESTAMP AS DATE) -
         CAST(MAX(finished_at) AS DATE)) * 24,
        2
    ) AS hours_since_last_success
FROM pipeline_run_log
WHERE run_status = 'SUCCESS'
GROUP BY pipeline_name;

-------------------------------------------------------------------
-- 4: Staging Tables
-- ??? Staging Table ?? ????? ??????? ???? ???????? ????? ??? ?? ?????? ??????? ??? tables ????????
-------------------------------------------------------------------
-- Step 1: Create the staging table
CREATE TABLE stg_customers (
    customer_id NUMBER,
    customer_name VARCHAR2(100),
    email VARCHAR2(150),
    registration_date DATE,
    source_updated_at TIMESTAMP
);

-- Step 2: Insert sample raw data
INSERT INTO stg_customers VALUES (
    10, '  Mona Ali  ', 'mona10@example.com',
    DATE '2026-03-01',
    TIMESTAMP '2026-03-01 10:00:00'
);

INSERT INTO stg_customers VALUES (
    11, 'Omar Hassan', 'omar11@example.com',
    DATE '2026-03-02',
    TIMESTAMP '2026-03-02 11:00:00'
);

INSERT INTO stg_customers VALUES (
    11, 'Omar Hassan Updated', 'omar11_new@example.com',
    DATE '2026-03-02',
    TIMESTAMP '2026-03-02 14:00:00'
);

INSERT INTO stg_customers VALUES (
    12, 'Sara Ahmed', NULL,
    DATE '2026-03-03',
    TIMESTAMP '2026-03-03 09:00:00'
);

COMMIT;

----------------------------------------------------------------------

SELECT *
FROM stg_customers
ORDER BY customer_id, source_updated_at;

----------------------------------------------------------------------
-- 5: Data Cleaning & Transformation
----------------------------------------------------------------------
-- Step 1: Detect missing values
SELECT *
FROM stg_customers
WHERE customer_id IS NULL
   OR customer_name IS NULL
   OR email IS NULL
   OR registration_date IS NULL;
   
-- Step 2: Detect duplicate customers
SELECT
    customer_id,
    COUNT(*) AS row_count
FROM stg_customers
GROUP BY customer_id
HAVING COUNT(*) > 1;

-- Step 3: Clean the data and deduplicate
SELECT
    customer_id,
    TRIM(customer_name) AS customer_name,
    LOWER(TRIM(email)) AS email,
    registration_date,
    source_updated_at
FROM (
    SELECT
        s.*,
        ROW_NUMBER() OVER (
            PARTITION BY customer_id
            ORDER BY source_updated_at DESC
        ) AS rn
    FROM stg_customers s
)
WHERE rn = 1
  AND customer_id IS NOT NULL
  AND customer_name IS NOT NULL
  AND email IS NOT NULL
  AND registration_date IS NOT NULL
ORDER BY customer_id;

----------------------------------------------------------------------
-- 6: Insert Clean Data into the Final Table
----------------------------------------------------------------------
MERGE INTO customers c
USING (
    SELECT
        customer_id,
        TRIM(customer_name) AS customer_name,
        LOWER(TRIM(email)) AS email,
        registration_date
    FROM (
        SELECT
            s.*,
            ROW_NUMBER() OVER (
                PARTITION BY customer_id
                ORDER BY source_updated_at DESC
            ) AS rn
        FROM stg_customers s
    )
    WHERE rn = 1
      AND customer_id IS NOT NULL
      AND customer_name IS NOT NULL
      AND email IS NOT NULL
      AND registration_date IS NOT NULL
) s
ON (c.customer_id = s.customer_id)

WHEN MATCHED THEN
    UPDATE SET
        c.customer_name = s.customer_name,
        c.email = s.email,
        c.registration_date = s.registration_date

WHEN NOT MATCHED THEN
    INSERT (
        customer_id,
        customer_name,
        email,
        registration_date
    )
    VALUES (
        s.customer_id,
        s.customer_name,
        s.email,
        s.registration_date
    );
    
COMMIT;

-----------------------------------------------------------------------

SELECT *
FROM customers
ORDER BY customer_id;

-----------------------------------------------------------------------
-- 7: Final Analytics
-----------------------------------------------------------------------
-- 1. Total delivered revenue
SELECT
    SUM(oi.quantity * oi.unit_price) AS total_revenue
FROM orders o
JOIN order_items oi
    ON o.order_id = oi.order_id
WHERE o.status = 'DELIVERED';

-- 2. Revenue by month
SELECT
    TO_CHAR(TRUNC(o.order_date, 'MM'), 'YYYY-MM') AS revenue_month,
    SUM(oi.quantity * oi.unit_price) AS total_revenue
FROM orders o
JOIN order_items oi
    ON o.order_id = oi.order_id
WHERE o.status = 'DELIVERED'
GROUP BY TRUNC(o.order_date, 'MM')
ORDER BY TRUNC(o.order_date, 'MM');

-- 3. Top-selling products by revenue
SELECT
    p.product_name,
    SUM(oi.quantity * oi.unit_price) AS total_revenue
FROM products p
JOIN order_items oi
    ON p.product_id = oi.product_id
JOIN orders o
    ON oi.order_id = o.order_id
WHERE o.status = 'DELIVERED'
GROUP BY p.product_id, p.product_name
ORDER BY total_revenue DESC;
