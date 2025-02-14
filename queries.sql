SHOW DATABASES;
USE ecommerce;

SET SQL_SAFE_UPDATES = 0;


-- apply english translation of category name to product category
UPDATE products
JOIN category_translation
ON products.product_category_name = category_translation.category_name
SET products.product_category_name = category_translation.english_category_name;

SET SQL_SAFE_UPDATES = 1;



-- DATA EXPLORATION
-- How many items are in each category
SELECT product_category_name, COUNT(product_id) AS number_of_items
FROM products
GROUP BY product_category_name
ORDER BY number_of_items DESC;


DROP VIEW category_sales;
-- revenue generated by each category
CREATE VIEW category_sales AS
SELECT price, order_id, product_category_name, order_item_id, SUM(price * order_item_id) AS revenue
FROM products p
JOIN order_items o
ON p.product_id = o.product_id
GROUP BY p.product_category_name, order_item_id, order_id, price;


-- sales trend of top 3 category
SELECT s.product_category_name, 
	SUM(s.price * order_item_id) AS total_sales, 
	DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS purchase_year_month
FROM category_sales s
JOIN orders o
ON s.order_id = o.order_id
WHERE s.product_category_name = 'health_beauty' OR s.product_category_name = 'bed_bath_table' OR s.product_category_name = 'watches_gifts'
GROUP BY s.product_category_name, purchase_year_month
ORDER BY purchase_year_month ASC;


-- top 5 most ordered items in health and beauty category
SELECT
    p.product_id,
    COUNT(o.order_item_id) AS number_sold,
    SUM(o.order_item_id * o.price) AS revenue_generated
FROM order_items o
JOIN products p ON o.product_id = p.product_id
WHERE p.product_category_name = 'health_beauty'
GROUP BY p.product_id
ORDER BY number_sold DESC
LIMIT 5;


-- overall growth 
SELECT
    o.order_purchase_timestamp,
    SUM(i.price * i.order_item_id) AS monthly_sales
FROM orders o
JOIN order_items i ON o.order_id = i.order_id
GROUP BY o.order_purchase_timestamp
ORDER BY o.order_purchase_timestamp;


-- customer distribution across the country
SELECT DISTINCT
    o.customer_id,
    ROUND(SUM(i.price * i.order_item_id)OVER (PARTITION BY o.customer_id), 2) AS total_order_amount,
    COUNT(i.order_id) OVER (PARTITION BY o.customer_id) AS num_orders,
    ROUND(AVG(i.price * i.order_item_id)OVER (PARTITION BY o.customer_id), 2) AS avg_order_amount,
    customer_zip_code_prefix,
    customer_city,
    customer_state
FROM order_items i
LEFT JOIN orders o ON o.order_id = i.order_id
LEFT JOIN customers c ON c.customer_id = o.customer_id
WHERE o.customer_id IS NOT NULL
ORDER BY total_order_amount DESC;

-- monthly sales trend for each state
SELECT c.customer_state, 
	SUM(price * order_item_id) AS total_sales, 
	DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS purchase_year_month
FROM order_items i
JOIN orders o
ON i.order_id = o.order_id
JOIN customers c
ON c.customer_id = o.customer_id
GROUP BY c.customer_state, purchase_year_month
ORDER BY purchase_year_month ASC;


-- caulate average customer lifetime value
CREATE VIEW customer_dist AS
SELECT DISTINCT
    o.customer_id,
    ROUND(SUM(i.price * i.order_item_id)OVER (PARTITION BY o.customer_id), 2) AS total_order_amount,
    COUNT(i.order_id) OVER (PARTITION BY o.customer_id) AS num_orders,
    ROUND(AVG(i.price * i.order_item_id)OVER (PARTITION BY o.customer_id), 2) AS avg_order_amount,
    customer_zip_code_prefix,
    customer_city,
    customer_state
FROM order_items i
LEFT JOIN orders o ON o.order_id = i.order_id
LEFT JOIN customers c ON c.customer_id = o.customer_id
WHERE o.customer_id IS NOT NULL;

SELECT
    customer_state,
    SUM(total_order_amount) AS total_sales,
    AVG(total_order_amount) AS avg_lifetime_value
FROM customer_dist
GROUP BY customer_state
ORDER BY total_sales DESC;

-- compare ordering frequencies in the year 2017 and 2018
SELECT
    DATE_FORMAT(order_purchase_timestamp, '%m') AS purchase_month,
    COUNT(CASE WHEN YEAR(order_purchase_timestamp) = 2017 THEN 1 END) AS monthly_orders_2017,
    COUNT(CASE WHEN YEAR(order_purchase_timestamp) = 2018 THEN 1 END) AS monthly_orders_2018
FROM orders
GROUP BY purchase_month
ORDER BY purchase_month;