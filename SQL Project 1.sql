CREATE SCHEMA dannys_diner;

CREATE TABLE sales (
  customer_id VARCHAR(1),
  order_date DATE,
  product_id INTEGER
);

INSERT INTO sales
  (customer_id, order_date, product_id)
VALUES
  ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3');
 

CREATE TABLE menu (
  product_id INTEGER,
  product_name VARCHAR(5),
  price INTEGER
);

INSERT INTO menu
  (product_id, product_name, price)
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
  

CREATE TABLE members (
  customer_id VARCHAR(1),
  join_date DATE
);

INSERT INTO members
  (customer_id, join_date)
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');
  
  
  select * from members;
  select * from menu;
  select * from sales;
  
  ##Q1- What is the total amount each customer spent at the restaurant?
  
  SELECT customer_id,sum(price) Total_amt
  FROM sales T1
  join menu T2 ON
  T1.product_id = T2.product_id
  group by customer_id;
  
  ##Q2-How many days has each customer visited the restaurant?
  
  SELECT distinct(customer_id) as cust,
  count(order_date) days_visit
  FROM sales
  GROUP BY cust;
  
 ##Q3- What was the first item from the menu purchased by each customer
 
SELECT product_name
FROM menu
WHERE product_id = 1;
  
  
##Q4-What is the most purchased item on the menu and how many times was it purchased by all customers?

 select * from members;
  select * from menu;
  select * from sales;
  
  SELECT product_id, max(distinct(product_id)) from sales
  group by product_id;
  
SELECT product_name,count(*) as purchase_count
FROM menu T1
JOIN sales T2 ON T1.product_id = T2.product_id
GROUP BY product_name
order by purchase_count desc limit 1;

##Q5-Which item was the most popular for each customer?
  
  WITH ItemRank AS (
  SELECT 
	s.customer_id,
	s.product_id,
	COUNT(s.product_id) AS total_quantity,
	RANK() OVER (PARTITION BY s.customer_id ORDER BY COUNT(s.product_id) DESC) AS ranks
    FROM sales s
    GROUP BY s.customer_id, s.product_id
)
SELECT 
    ir.customer_id, 
    m.product_name, 
    ir.total_quantity
FROM ItemRank ir
JOIN menu m ON ir.product_id = m.product_id
WHERE ir.ranks = 1;


##Q6-Which item was purchased first by the customer after they became a member?

WITH FirstPurchase AS (
    SELECT 
        s.customer_id,
        s.product_id,
        s.order_date,
        ROW_NUMBER() OVER (PARTITION BY s.customer_id ORDER BY s.order_date) AS rn
    FROM sales s
    JOIN members m ON s.customer_id = m.customer_id
    WHERE s.order_date >= m.join_date
)
SELECT 
    fp.customer_id, 
    m.product_name, 
    fp.order_date
FROM FirstPurchase fp
JOIN menu m ON fp.product_id = m.product_id
WHERE fp.rn = 1;


##Q7-Which item was purchased just before the customer became a member

WITH LastPurchaseBeforeJoin AS (
    SELECT 
        s.customer_id,
        s.product_id,
        s.order_date,
        ROW_NUMBER() OVER (PARTITION BY s.customer_id ORDER BY s.order_date DESC) AS rn
    FROM sales s
    JOIN members m ON s.customer_id = m.customer_id
    WHERE s.order_date < m.join_date
)
SELECT 
    lp.customer_id, 
    m.product_name, 
    lp.order_date
FROM LastPurchaseBeforeJoin lp
JOIN menu m ON lp.product_id = m.product_id
WHERE lp.rn = 1;

##Q8-What is the total items and amount spent for each member before they became a member
 SELECT 
    m.customer_id,
    COUNT(s.product_id) AS total_items,
    SUM(s.product_id * menu.price) AS total_amount_spent
FROM sales s
JOIN members m ON s.customer_id = m.customer_id
JOIN menu ON s.product_id = menu.product_id
WHERE s.order_date < m.join_date
GROUP BY m.customer_id;

##Q9-If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

WITH PointsBeforeJoin AS (
    SELECT 
        s.customer_id,
        s.product_id,
        menu.price,
        s.quantity,
        CASE
            WHEN menu.product_name = 'sushi' THEN (s.quantity * menu.price * 10 * 2)  -- 2x multiplier for sushi
            ELSE (s.quantity * menu.price * 10)  -- Regular points calculation
        END AS points
    FROM sales s
    JOIN members m ON s.customer_id = m.customer_id
    JOIN menu ON s.product_id = menu.product_id
    WHERE s.order_date < m.join_date
)
SELECT 
    customer_id,
    SUM(points) AS total_points
FROM PointsBeforeJoin
GROUP BY customer_id;



##Q10-In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

WITH PointsCalculation AS (
    SELECT 
        s.customer_id,
        s.product_id,
        menu.price,
        s.order_date,
        m.join_date,
        -- Check if the purchase is within the first week of the join date
        CASE
            WHEN s.order_date >= m.join_date AND s.order_date <= m.join_date + "INTERVAL" -- '7 days' 
            THEN (s.product_id * menu.price * 10 * 2)  -- 2x points for the first week
            ELSE (s.product_id * menu.price * 10)      -- Regular points after the first week
        END AS points
    FROM sales s
    JOIN members m ON s.customer_id = m.customer_id
    JOIN menu ON s.product_id = menu.product_id
    WHERE s.order_date <= '2021-01-31'  -- Filter for January
)
SELECT 
    customer_id,
    SUM(points) AS total_points
FROM PointsCalculation
GROUP BY customer_id;
