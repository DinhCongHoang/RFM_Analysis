-- Create RFM segment customer table
WITH max_order_date AS (
  SELECT MAX(created_at::date) AS num
  FROM fact_orders
)

,metrics AS (
  SELECT
    customer_id
    ,(SELECT num FROM max_order_date) - MAX(created_at::date) AS recency
    ,COUNT(DISTINCT created_at::date) AS frequency
    ,SUM(subtotal) AS monetary
  FROM
    fact_orders
  GROUP BY
    customer_id
)

,rfm AS (
  SELECT
    customer_id
    ,NTILE(5) OVER(ORDER BY recency DESC) AS R
    ,NTILE(5) OVER(ORDER BY frequency ASC) AS F
    ,NTILE(5) OVER(ORDER BY monetary ASC) AS M
  FROM
    metrics
)

,scoring AS (
  SELECT
    customer_id
    ,R
    ,F
    ,M
    ,CONCAT(R, F, M) AS RFM
  FROM
    rfm
)

SELECT
  t2.customer_id AS customer_id
  ,t2.gender AS gender
  ,CASE
    WHEN (SELECT EXTRACT(YEAR FROM num) FROM max_order_date) - t2.birth_year < 18 THEN 'small students (<18)'
    WHEN (SELECT EXTRACT(YEAR FROM num) FROM max_order_date) - t2.birth_year <= 24 THEN 'big students (18-24)'
    WHEN (SELECT EXTRACT(YEAR FROM num) FROM max_order_date) - t2.birth_year <= 34 THEN 'young people (25-34)'
    WHEN (SELECT EXTRACT(YEAR FROM num) FROM max_order_date) - t2.birth_year <= 44 THEN 'middle aged (35-44)'
    ELSE 'seniors (>44)'
  END AS age_group
  ,t2.city AS city
  ,t2.preferred_device AS preferred_device
  ,t1.RFM AS rfm
  ,CASE
    WHEN R >= 4 AND F >= 4 AND M >= 4 THEN 'Champions'
    WHEN R >= 4 AND F >= 3 AND M >= 3 THEN 'Loyalists'
    WHEN R = 3 AND F >= 3 AND M >= 3 THEN 'Slipping Loyalists'
    WHEN R >= 4 AND F <= 2 THEN 'New Customers'
    WHEN R >= 3 AND F <= 2 AND M >= 4 THEN 'Whales'
    WHEN R <= 2 AND F >= 4 AND M >= 4 THEN 'Cannot lose them'
    WHEN R <= 2 AND F <= 2 AND M <= 2 THEN 'Lost'
    ELSE 'Potential / At Risk'
  END AS segmentation
FROM
  scoring t1
  LEFT JOIN dim_customer t2 ON t1.customer_id = t2.customer_id;

--GMV Percentage by RFM segments
WITH max_order_date AS (
  SELECT MAX(created_at::date) AS num
  FROM fact_orders
)

,metrics AS (
  SELECT
    customer_id
    ,(SELECT num FROM max_order_date) - MAX(created_at::date) AS recency
    ,COUNT(DISTINCT created_at::date) AS frequency
    ,SUM(subtotal) AS monetary
  FROM
    fact_orders
  GROUP BY
    customer_id
)

,rfm AS (
  SELECT
    customer_id
    ,NTILE(5) OVER(ORDER BY recency DESC) AS R
    ,NTILE(5) OVER(ORDER BY frequency ASC) AS F
    ,NTILE(5) OVER(ORDER BY monetary ASC) AS M
  FROM
    metrics
)

,scoring AS (
  SELECT
    customer_id
    ,R
    ,F
    ,M
    ,CONCAT(R, F, M) AS RFM
  FROM
    rfm
)

,segmentation AS (
  SELECT
    t2.customer_id AS customer_id
    ,t2.gender AS gender
    ,CASE
      WHEN (SELECT EXTRACT(YEAR FROM num) FROM max_order_date) - t2.birth_year < 18 THEN 'small students (<18)'
      WHEN (SELECT EXTRACT(YEAR FROM num) FROM max_order_date) - t2.birth_year <= 24 THEN 'big students (18-24)'
      WHEN (SELECT EXTRACT(YEAR FROM num) FROM max_order_date) - t2.birth_year <= 34 THEN 'young people (25-34)'
      WHEN (SELECT EXTRACT(YEAR FROM num) FROM max_order_date) - t2.birth_year <= 44 THEN 'middle aged (35-44)'
      ELSE 'seniors (>44)'
    END AS age_group
    ,t2.city AS city
    ,t2.preferred_device AS preferred_device
    ,t1.RFM AS rfm
    ,CASE
      WHEN R >= 4 AND F >= 4 AND M >= 4 THEN 'Champions'
      WHEN R >= 4 AND F >= 3 AND M >= 3 THEN 'Loyalists'
      WHEN R = 3 AND F >= 3 AND M >= 3 THEN 'Slipping Loyalists'
      WHEN R >= 4 AND F <= 2 THEN 'New Customers'
      WHEN R >= 3 AND F <= 2 AND M >= 4 THEN 'Whales'
      WHEN R <= 2 AND F >= 4 AND M >= 4 THEN 'Cannot lose them'
      WHEN R <= 2 AND F <= 2 AND M <= 2 THEN 'Lost'
      ELSE 'Potential / At Risk'
    END AS segment
  FROM
    scoring t1
    LEFT JOIN dim_customer t2 ON t1.customer_id = t2.customer_id
)

SELECT
  s.segment
  ,ROUND(SUM(subtotal) * 100.0 / (SELECT SUM(subtotal) FROM fact_orders), 2) AS segment_gmv_pct
FROM
  fact_orders fo
  LEFT JOIN segmentation s ON fo.customer_id = s.customer_id
GROUP BY
  s.segment;

--Persona score of RFM segments. From here, determining the best customers group.
WITH max_order_date AS (
  SELECT MAX(created_at::date) AS num
  FROM fact_orders
)

,metrics AS (
  SELECT
    customer_id
    ,(SELECT num FROM max_order_date) - MAX(created_at::date) AS recency
    ,COUNT(DISTINCT created_at::date) AS frequency
    ,SUM(subtotal) AS monetary
  FROM
    fact_orders
  GROUP BY
    customer_id
)

,rfm AS (
  SELECT
    customer_id
    ,NTILE(5) OVER(ORDER BY recency DESC) AS R
    ,NTILE(5) OVER(ORDER BY frequency ASC) AS F
    ,NTILE(5) OVER(ORDER BY monetary ASC) AS M
  FROM
    metrics
)

,scoring AS (
  SELECT
    customer_id
    ,R
    ,F
    ,M
    ,CONCAT(R, F, M) AS RFM
  FROM
    rfm
)

,segmentation AS (
  SELECT
    t2.customer_id AS customer_id
    ,t2.gender AS gender
    ,CASE
      WHEN (SELECT EXTRACT(YEAR FROM num) FROM max_order_date) - t2.birth_year < 18 THEN 'small students (<18)'
      WHEN (SELECT EXTRACT(YEAR FROM num) FROM max_order_date) - t2.birth_year <= 24 THEN 'big students (18-24)'
      WHEN (SELECT EXTRACT(YEAR FROM num) FROM max_order_date) - t2.birth_year <= 34 THEN 'young people (25-34)'
      WHEN (SELECT EXTRACT(YEAR FROM num) FROM max_order_date) - t2.birth_year <= 44 THEN 'middle aged (35-44)'
      ELSE 'seniors (>44)'
    END AS age_group
    ,t2.city AS city
    ,t2.preferred_device AS preferred_device
    ,t1.RFM AS rfm
    ,t1.R AS R
    ,t1.F AS F
    ,t1.M AS M
    ,CASE
      WHEN R >= 4 AND F >= 4 AND M >= 4 THEN 'Champions'
      WHEN R >= 4 AND F >= 3 AND M >= 3 THEN 'Loyalists'
      WHEN R = 3 AND F >= 3 AND M >= 3 THEN 'Slipping Loyalists'
      WHEN R >= 4 AND F <= 2 THEN 'New Customers'
      WHEN R >= 3 AND F <= 2 AND M >= 4 THEN 'Whales'
      WHEN R <= 2 AND F >= 4 AND M >= 4 THEN 'Cannot lose them'
      WHEN R <= 2 AND F <= 2 AND M <= 2 THEN 'Lost'
      ELSE 'Potential / At Risk'
    END AS segment
  FROM
    scoring t1
    LEFT JOIN dim_customer t2 ON t1.customer_id = t2.customer_id
)

,metrics_by_group AS (
  SELECT
    s.gender
    ,s.city
    ,s.age_group
    ,COUNT(DISTINCT s.customer_id) AS customers
    ,ROUND(SUM(fo.subtotal) / 27000.0) AS gmv
    ,ROUND(AVG(R), 2) AS R
    ,ROUND(AVG(F), 2) AS F
    ,ROUND(AVG(M), 2) AS M
  FROM
    fact_orders fo
    LEFT JOIN segmentation s ON fo.customer_id = s.customer_id
  GROUP BY
    s.gender
    ,s.city
    ,s.age_group
  HAVING
    COUNT(DISTINCT s.customer_id) > 50
  ORDER BY
    customers
)

,min_max_values AS (
  SELECT
    MIN(R) AS min_r, MAX(R) AS max_r,
    MIN(F) AS min_f, MAX(F) AS max_f,
    MIN(M) AS min_m, MAX(M) AS max_m,
    MIN(gmv) AS min_gmv, MAX(gmv) AS max_gmv
  FROM
    metrics_by_group
)

SELECT 
  t1.city
  ,t1.gender
  ,t1.age_group
  ,t1.customers
  ,t1.gmv
  -- Tính điểm thành phần (từ 0 đến 1)
  ,ROUND((R - min_R) / (max_R - min_R), 2) AS score_R
  ,ROUND((F - min_F) / (max_F - min_F), 2) AS score_F
  ,ROUND((M - min_M) / (max_M - min_M), 2) AS score_M
  ,ROUND((gmv - min_gmv) / (max_gmv - min_gmv), 2) AS score_GMV
  
  -- Tổng điểm có trọng số (Càng cao càng tốt)
  ,ROUND((0.1 * (R - min_R) / (max_R - min_R)) + (0.25 * (F - min_F) / (max_F - min_F)) + (0.25 * (M - min_M) / (max_M - min_M)) + (0.4 * (gmv - min_gmv) / (max_gmv - min_gmv)), 2) AS final_persona_score
FROM 
  metrics_by_group t1
  CROSS JOIN min_max_values t2
ORDER BY 
  final_persona_score DESC;

--Best product category in terms of GMV, by best persona
WITH max_order_date AS (
  SELECT MAX(created_at::date) AS num
  FROM fact_orders
)

,metrics AS (
  SELECT
    customer_id
    ,(SELECT num FROM max_order_date) - MAX(created_at::date) AS recency
    ,COUNT(DISTINCT created_at::date) AS frequency
    ,SUM(subtotal) AS monetary
  FROM
    fact_orders
  GROUP BY
    customer_id
)

,rfm AS (
  SELECT
    customer_id
    ,NTILE(5) OVER(ORDER BY recency DESC) AS R
    ,NTILE(5) OVER(ORDER BY frequency ASC) AS F
    ,NTILE(5) OVER(ORDER BY monetary ASC) AS M
  FROM
    metrics
)

,scoring AS (
  SELECT
    customer_id
    ,R
    ,F
    ,M
    ,CONCAT(R, F, M) AS RFM
  FROM
    rfm
)

,segmentation AS (
  SELECT
    t2.customer_id AS customer_id
    ,t2.gender AS gender
    ,CASE
      WHEN (SELECT EXTRACT(YEAR FROM num) FROM max_order_date) - t2.birth_year < 18 THEN 'small students (<18)'
      WHEN (SELECT EXTRACT(YEAR FROM num) FROM max_order_date) - t2.birth_year <= 24 THEN 'big students (18-24)'
      WHEN (SELECT EXTRACT(YEAR FROM num) FROM max_order_date) - t2.birth_year <= 34 THEN 'young people (25-34)'
      WHEN (SELECT EXTRACT(YEAR FROM num) FROM max_order_date) - t2.birth_year <= 44 THEN 'middle aged (35-44)'
      ELSE 'seniors (>44)'
    END AS age_group
    ,t2.city AS city
    ,t2.preferred_device AS preferred_device
    ,t1.RFM AS rfm
    ,t1.R AS R
    ,t1.F AS F
    ,t1.M AS M
    ,CASE
      WHEN R >= 4 AND F >= 4 AND M >= 4 THEN 'Champions'
      WHEN R >= 4 AND F >= 3 AND M >= 3 THEN 'Loyalists'
      WHEN R = 3 AND F >= 3 AND M >= 3 THEN 'Slipping Loyalists'
      WHEN R >= 4 AND F <= 2 THEN 'New Customers'
      WHEN R >= 3 AND F <= 2 AND M >= 4 THEN 'Whales'
      WHEN R <= 2 AND F >= 4 AND M >= 4 THEN 'Cannot lose them'
      WHEN R <= 2 AND F <= 2 AND M <= 2 THEN 'Lost'
      ELSE 'Potential / At Risk'
    END AS segment
  FROM
    scoring t1
    LEFT JOIN dim_customer t2 ON t1.customer_id = t2.customer_id
)

,metrics_by_group AS (
  SELECT
    s.gender
    ,s.city
    ,s.age_group
    ,COUNT(DISTINCT s.customer_id) AS customers
    ,ROUND(SUM(fo.subtotal) / 27000.0) AS gmv
    ,ROUND(AVG(R), 2) AS R
    ,ROUND(AVG(F), 2) AS F
    ,ROUND(AVG(M), 2) AS M
  FROM
    fact_orders fo
    LEFT JOIN segmentation s ON fo.customer_id = s.customer_id
  GROUP BY
    s.gender
    ,s.city
    ,s.age_group
  HAVING
    COUNT(DISTINCT s.customer_id) > 50
  ORDER BY
    customers
)

,min_max_values AS (
  SELECT
    MIN(R) AS min_r, MAX(R) AS max_r,
    MIN(F) AS min_f, MAX(F) AS max_f,
    MIN(M) AS min_m, MAX(M) AS max_m,
    MIN(gmv) AS min_gmv, MAX(gmv) AS max_gmv
  FROM
    metrics_by_group
)

,persona_score_cte AS (
  SELECT 
    t1.city
    ,t1.gender
    ,t1.age_group
    ,t1.customers
    ,t1.gmv
    -- Tính điểm thành phần (từ 0 đến 1)
    ,ROUND((R - min_R) / (max_R - min_R), 2) AS score_R
    ,ROUND((F - min_F) / (max_F - min_F), 2) AS score_F
    ,ROUND((M - min_M) / (max_M - min_M), 2) AS score_M
    ,ROUND((gmv - min_gmv) / (max_gmv - min_gmv), 2) AS score_GMV
    
    -- Tổng điểm có trọng số (Càng cao càng tốt)
    ,ROUND((0.1 * (R - min_R) / (max_R - min_R)) + (0.25 * (F - min_F) / (max_F - min_F)) + (0.25 * (M - min_M) / (max_M - min_M)) + (0.4 * (gmv - min_gmv) / (max_gmv - min_gmv)), 2) AS final_persona_score
  FROM 
    metrics_by_group t1
    CROSS JOIN min_max_values t2
  ORDER BY 
    final_persona_score DESC
)

,best_persona_cte AS (
  SELECT
    city
    ,gender
    ,age_group
  FROM  
    persona_score_cte
  WHERE
    final_persona_score >= 0.69
)

,best_customers AS (
SELECT
  s.customer_id
  ,CONCAT(s.city, ', ', s.gender, ', ', s.age_group) AS cust_group
FROM
  segmentation s
  INNER JOIN best_persona_cte b
    ON s.city = b.city
      AND s.gender = b.gender
      AND s.age_group = b.age_group
)

--Top categories của từng persona
,gmv_by_persona AS (
SELECT
  cust_group
  ,dp.cat1_name
  ,ROUND(SUM(foi.line_total) / 27000.0) AS gmv
  ,ROW_NUMBER() OVER(PARTITION BY cust_group ORDER BY ROUND(SUM(foi.line_total) / 27000.0) DESC) AS gmv_rank
FROM
  fact_orders fo
  INNER JOIN best_customers b ON fo.customer_id = b.customer_id --inner join để chỉ lấy best customers
  LEFT JOIN fact_order_items foi ON fo.order_id = foi.order_id
  LEFT JOIN dim_product dp ON foi.product_id = dp.product_id
GROUP BY
  cust_group
  ,dp.cat1_name
)

SELECT
  *
FROM
  gmv_by_persona
WHERE
  gmv_rank = 1;

--Hourly Total GMV by customer best persona
WITH max_order_date AS (
  SELECT MAX(created_at::date) AS num
  FROM fact_orders
)

,metrics AS (
  SELECT
    customer_id
    ,(SELECT num FROM max_order_date) - MAX(created_at::date) AS recency
    ,COUNT(DISTINCT created_at::date) AS frequency
    ,SUM(subtotal) AS monetary
  FROM
    fact_orders
  GROUP BY
    customer_id
)

,rfm AS (
  SELECT
    customer_id
    ,NTILE(5) OVER(ORDER BY recency DESC) AS R
    ,NTILE(5) OVER(ORDER BY frequency ASC) AS F
    ,NTILE(5) OVER(ORDER BY monetary ASC) AS M
  FROM
    metrics
)

,scoring AS (
  SELECT
    customer_id
    ,R
    ,F
    ,M
    ,CONCAT(R, F, M) AS RFM
  FROM
    rfm
)

,segmentation AS (
  SELECT
    t2.customer_id AS customer_id
    ,t2.gender AS gender
    ,CASE
      WHEN (SELECT EXTRACT(YEAR FROM num) FROM max_order_date) - t2.birth_year < 18 THEN 'small students (<18)'
      WHEN (SELECT EXTRACT(YEAR FROM num) FROM max_order_date) - t2.birth_year <= 24 THEN 'big students (18-24)'
      WHEN (SELECT EXTRACT(YEAR FROM num) FROM max_order_date) - t2.birth_year <= 34 THEN 'young people (25-34)'
      WHEN (SELECT EXTRACT(YEAR FROM num) FROM max_order_date) - t2.birth_year <= 44 THEN 'middle aged (35-44)'
      ELSE 'seniors (>44)'
    END AS age_group
    ,t2.city AS city
    ,t2.preferred_device AS preferred_device
    ,t1.RFM AS rfm
    ,t1.R AS R
    ,t1.F AS F
    ,t1.M AS M
    ,CASE
      WHEN R >= 4 AND F >= 4 AND M >= 4 THEN 'Champions'
      WHEN R >= 4 AND F >= 3 AND M >= 3 THEN 'Loyalists'
      WHEN R = 3 AND F >= 3 AND M >= 3 THEN 'Slipping Loyalists'
      WHEN R >= 4 AND F <= 2 THEN 'New Customers'
      WHEN R >= 3 AND F <= 2 AND M >= 4 THEN 'Whales'
      WHEN R <= 2 AND F >= 4 AND M >= 4 THEN 'Cannot lose them'
      WHEN R <= 2 AND F <= 2 AND M <= 2 THEN 'Lost'
      ELSE 'Potential / At Risk'
    END AS segment
  FROM
    scoring t1
    LEFT JOIN dim_customer t2 ON t1.customer_id = t2.customer_id
)

,metrics_by_group AS (
  SELECT
    s.gender
    ,s.city
    ,s.age_group
    ,COUNT(DISTINCT s.customer_id) AS customers
    ,ROUND(SUM(fo.subtotal) / 27000.0) AS gmv
    ,ROUND(AVG(R), 2) AS R
    ,ROUND(AVG(F), 2) AS F
    ,ROUND(AVG(M), 2) AS M
  FROM
    fact_orders fo
    LEFT JOIN segmentation s ON fo.customer_id = s.customer_id
  GROUP BY
    s.gender
    ,s.city
    ,s.age_group
  HAVING
    COUNT(DISTINCT s.customer_id) > 50
  ORDER BY
    customers
)

,min_max_values AS (
  SELECT
    MIN(R) AS min_r, MAX(R) AS max_r,
    MIN(F) AS min_f, MAX(F) AS max_f,
    MIN(M) AS min_m, MAX(M) AS max_m,
    MIN(gmv) AS min_gmv, MAX(gmv) AS max_gmv
  FROM
    metrics_by_group
)

,persona_score_cte AS (
  SELECT 
    t1.city
    ,t1.gender
    ,t1.age_group
    ,t1.customers
    ,t1.gmv
    -- Tính điểm thành phần (từ 0 đến 1)
    ,ROUND((R - min_R) / (max_R - min_R), 2) AS score_R
    ,ROUND((F - min_F) / (max_F - min_F), 2) AS score_F
    ,ROUND((M - min_M) / (max_M - min_M), 2) AS score_M
    ,ROUND((gmv - min_gmv) / (max_gmv - min_gmv), 2) AS score_GMV
    
    -- Tổng điểm có trọng số (Càng cao càng tốt)
    ,ROUND((0.1 * (R - min_R) / (max_R - min_R)) + (0.25 * (F - min_F) / (max_F - min_F)) + (0.25 * (M - min_M) / (max_M - min_M)) + (0.4 * (gmv - min_gmv) / (max_gmv - min_gmv)), 2) AS final_persona_score
  FROM 
    metrics_by_group t1
    CROSS JOIN min_max_values t2
  ORDER BY 
    final_persona_score DESC
)

,best_persona_cte AS (
  SELECT
    city
    ,gender
    ,age_group
  FROM  
    persona_score_cte
  WHERE
    final_persona_score >= 0.69
)

,best_customers AS (
SELECT
  s.customer_id
  ,true AS is_best_customer
FROM
  segmentation s
  INNER JOIN best_persona_cte b
    ON s.city = b.city
      AND s.gender = b.gender
      AND s.age_group = b.age_group
)

--Top categories của từng persona
,metrics_by_persona AS (
SELECT
  EXTRACT(HOUR FROM fo.created_at) AS hour_
  ,ROUND(SUM(foi.line_total) / 27000.0) AS gmv
  ,ROW_NUMBER() OVER(ORDER BY ROUND(SUM(foi.line_total) / 27000.0) DESC) AS gmv_rank
FROM
  fact_orders fo
  INNER JOIN best_customers b ON fo.customer_id = b.customer_id --inner join để chỉ lấy best customers
  INNER JOIN fact_order_items foi ON fo.order_id = foi.order_id
  INNER JOIN dim_product dp ON foi.product_id = dp.product_id
GROUP BY
  EXTRACT(HOUR FROM fo.created_at)
)

SELECT
  hour_
  ,gmv
FROM
  metrics_by_persona;

--Calculate statistical values (avg, median, Q1, Q3, min, max) of duration between 1st order và 2nd order of the best customer group
WITH max_order_date AS (
  SELECT MAX(created_at::date) AS num
  FROM fact_orders
)

,metrics AS (
  SELECT
    customer_id
    ,(SELECT num FROM max_order_date) - MAX(created_at::date) AS recency
    ,COUNT(DISTINCT created_at::date) AS frequency
    ,SUM(subtotal) AS monetary
  FROM
    fact_orders
  GROUP BY
    customer_id
)

,rfm AS (
  SELECT
    customer_id
    ,NTILE(5) OVER(ORDER BY recency DESC) AS R
    ,NTILE(5) OVER(ORDER BY frequency ASC) AS F
    ,NTILE(5) OVER(ORDER BY monetary ASC) AS M
  FROM
    metrics
)

,scoring AS (
  SELECT
    customer_id
    ,R
    ,F
    ,M
    ,CONCAT(R, F, M) AS RFM
  FROM
    rfm
)

,segmentation AS (
  SELECT
    t2.customer_id AS customer_id
    ,t2.gender AS gender
    ,CASE
      WHEN (SELECT EXTRACT(YEAR FROM num) FROM max_order_date) - t2.birth_year < 18 THEN 'small students (<18)'
      WHEN (SELECT EXTRACT(YEAR FROM num) FROM max_order_date) - t2.birth_year <= 24 THEN 'big students (18-24)'
      WHEN (SELECT EXTRACT(YEAR FROM num) FROM max_order_date) - t2.birth_year <= 34 THEN 'young people (25-34)'
      WHEN (SELECT EXTRACT(YEAR FROM num) FROM max_order_date) - t2.birth_year <= 44 THEN 'middle aged (35-44)'
      ELSE 'seniors (>44)'
    END AS age_group
    ,t2.city AS city
    ,t2.preferred_device AS preferred_device
    ,t1.RFM AS rfm
    ,t1.R AS R
    ,t1.F AS F
    ,t1.M AS M
    ,CASE
      WHEN R >= 4 AND F >= 4 AND M >= 4 THEN 'Champions'
      WHEN R >= 4 AND F >= 3 AND M >= 3 THEN 'Loyalists'
      WHEN R = 3 AND F >= 3 AND M >= 3 THEN 'Slipping Loyalists'
      WHEN R >= 4 AND F <= 2 THEN 'New Customers'
      WHEN R >= 3 AND F <= 2 AND M >= 4 THEN 'Whales'
      WHEN R <= 2 AND F >= 4 AND M >= 4 THEN 'Cannot lose them'
      WHEN R <= 2 AND F <= 2 AND M <= 2 THEN 'Lost'
      ELSE 'Potential / At Risk'
    END AS segment
  FROM
    scoring t1
    LEFT JOIN dim_customer t2 ON t1.customer_id = t2.customer_id
)

,metrics_by_group AS (
  SELECT
    s.gender
    ,s.city
    ,s.age_group
    ,COUNT(DISTINCT s.customer_id) AS customers
    ,ROUND(SUM(fo.subtotal) / 27000.0) AS gmv
    ,ROUND(AVG(R), 2) AS R
    ,ROUND(AVG(F), 2) AS F
    ,ROUND(AVG(M), 2) AS M
  FROM
    fact_orders fo
    LEFT JOIN segmentation s ON fo.customer_id = s.customer_id
  GROUP BY
    s.gender
    ,s.city
    ,s.age_group
  HAVING
    COUNT(DISTINCT s.customer_id) > 50
  ORDER BY
    customers
)

,min_max_values AS (
  SELECT
    MIN(R) AS min_r, MAX(R) AS max_r,
    MIN(F) AS min_f, MAX(F) AS max_f,
    MIN(M) AS min_m, MAX(M) AS max_m,
    MIN(gmv) AS min_gmv, MAX(gmv) AS max_gmv
  FROM
    metrics_by_group
)

,persona_score_cte AS (
  SELECT 
    t1.city
    ,t1.gender
    ,t1.age_group
    ,t1.customers
    ,t1.gmv
    -- Tính điểm thành phần (từ 0 đến 1)
    ,ROUND((R - min_R) / (max_R - min_R), 2) AS score_R
    ,ROUND((F - min_F) / (max_F - min_F), 2) AS score_F
    ,ROUND((M - min_M) / (max_M - min_M), 2) AS score_M
    ,ROUND((gmv - min_gmv) / (max_gmv - min_gmv), 2) AS score_GMV
    
    -- Tổng điểm có trọng số (Càng cao càng tốt)
    ,ROUND((0.1 * (R - min_R) / (max_R - min_R)) + (0.25 * (F - min_F) / (max_F - min_F)) + (0.25 * (M - min_M) / (max_M - min_M)) + (0.4 * (gmv - min_gmv) / (max_gmv - min_gmv)), 2) AS final_persona_score
  FROM 
    metrics_by_group t1
    CROSS JOIN min_max_values t2
  ORDER BY 
    final_persona_score DESC
)

,best_persona_cte AS (
  SELECT
    city
    ,gender
    ,age_group
  FROM  
    persona_score_cte
  WHERE
    final_persona_score >= 0.69
)

,best_customers AS (
SELECT
  s.customer_id
  ,true AS is_best_customer
FROM
  segmentation s
  INNER JOIN best_persona_cte b
    ON s.city = b.city
      AND s.gender = b.gender
      AND s.age_group = b.age_group
)

,metrics_by_persona AS (
SELECT
  b.customer_id
  ,ROW_NUMBER() OVER(PARTITION BY b.customer_id ORDER BY fo.created_at ASC) AS rn_order
  ,ROUND(EXTRACT(EPOCH FROM (LEAD(fo.created_at) OVER(PARTITION BY b.customer_id ORDER BY fo.created_at ASC) - fo.created_at)) / 86400.0, 4) AS diff
FROM
  fact_orders fo
  INNER JOIN best_customers b ON fo.customer_id = b.customer_id --inner join để chỉ lấy best customers
  -- INNER JOIN fact_order_items foi ON fo.order_id = foi.order_id
  -- INNER JOIN dim_product dp ON foi.product_id = dp.product_id
)

,first_order_by_best_cust AS (
  SELECT
    customer_id
    ,diff
    ,ROW_NUMBER() OVER(ORDER BY diff) AS rn_diff
  FROM
    metrics_by_persona
  WHERE
    rn_order = 1
)

,min_max_diff AS (
  SELECT
    FLOOR((MIN(rn_diff) + MAX(rn_diff)) / 2.0) AS num
  FROM
    first_order_by_best_cust
  UNION
  SELECT
    CEIL((MIN(rn_diff) + MAX(rn_diff)) / 2.0) AS num
  FROM
    first_order_by_best_cust
)

,median_diff_cte AS (
  SELECT
    AVG(t1.diff) AS diff
  FROM
    first_order_by_best_cust t1
    INNER JOIN min_max_diff t2 ON t1.rn_diff = t2.num
)

,q1_rn_diff_cte AS (
  SELECT
    FLOOR(0.75 * MIN(rn_diff) + 0.25 * MAX(rn_diff)) AS num
  FROM
    first_order_by_best_cust
  UNION
  SELECT
    CEIL(0.75 * MIN(rn_diff) + 0.25 * MAX(rn_diff)) AS num
  FROM
    first_order_by_best_cust
)

,q1_diff_cte AS (
  SELECT
    AVG(t1.diff) AS diff
  FROM
    first_order_by_best_cust t1
    INNER JOIN q1_rn_diff_cte t2 ON t1.rn_diff = t2.num
)

,q3_rn_diff_cte AS (
  SELECT
    FLOOR(0.25 * MIN(rn_diff) + 0.75 * MAX(rn_diff)) AS num
  FROM
    first_order_by_best_cust
  UNION
  SELECT
    CEIL(0.25 * MIN(rn_diff) + 0.75 * MAX(rn_diff)) AS num
  FROM
    first_order_by_best_cust
)

,q3_diff_cte AS (
  SELECT
    AVG(t1.diff) AS diff
  FROM
    first_order_by_best_cust t1
    INNER JOIN q3_rn_diff_cte t2 ON t1.rn_diff = t2.num
)

SELECT
  MIN(diff) AS min_diff
  ,MAX(diff) AS max_diff
  ,ROUND(AVG(diff), 2) AS avg_diff
  ,ROUND((SELECT diff FROM q1_diff_cte), 2) AS q1_diff
  ,ROUND((SELECT diff FROM median_diff_cte), 2) AS median_diff
  ,ROUND((SELECT diff FROM q3_diff_cte), 2) AS q3_diff
FROM
  first_order_by_best_cust;

--Voucher usage percentage of the best customer group vs. all customers
WITH max_order_date AS (
  SELECT MAX(created_at::date) AS num
  FROM fact_orders
)

,metrics AS (
  SELECT
    customer_id
    ,(SELECT num FROM max_order_date) - MAX(created_at::date) AS recency
    ,COUNT(DISTINCT created_at::date) AS frequency
    ,SUM(subtotal) AS monetary
  FROM
    fact_orders
  GROUP BY
    customer_id
)

,rfm AS (
  SELECT
    customer_id
    ,NTILE(5) OVER(ORDER BY recency DESC) AS R
    ,NTILE(5) OVER(ORDER BY frequency ASC) AS F
    ,NTILE(5) OVER(ORDER BY monetary ASC) AS M
  FROM
    metrics
)

,scoring AS (
  SELECT
    customer_id
    ,R
    ,F
    ,M
    ,CONCAT(R, F, M) AS RFM
  FROM
    rfm
)

,segmentation AS (
  SELECT
    t2.customer_id AS customer_id
    ,t2.gender AS gender
    ,CASE
      WHEN (SELECT EXTRACT(YEAR FROM num) FROM max_order_date) - t2.birth_year < 18 THEN 'small students (<18)'
      WHEN (SELECT EXTRACT(YEAR FROM num) FROM max_order_date) - t2.birth_year <= 24 THEN 'big students (18-24)'
      WHEN (SELECT EXTRACT(YEAR FROM num) FROM max_order_date) - t2.birth_year <= 34 THEN 'young people (25-34)'
      WHEN (SELECT EXTRACT(YEAR FROM num) FROM max_order_date) - t2.birth_year <= 44 THEN 'middle aged (35-44)'
      ELSE 'seniors (>44)'
    END AS age_group
    ,t2.city AS city
    ,t2.preferred_device AS preferred_device
    ,t1.RFM AS rfm
    ,t1.R AS R
    ,t1.F AS F
    ,t1.M AS M
    ,CASE
      WHEN R >= 4 AND F >= 4 AND M >= 4 THEN 'Champions'
      WHEN R >= 4 AND F >= 3 AND M >= 3 THEN 'Loyalists'
      WHEN R = 3 AND F >= 3 AND M >= 3 THEN 'Slipping Loyalists'
      WHEN R >= 4 AND F <= 2 THEN 'New Customers'
      WHEN R >= 3 AND F <= 2 AND M >= 4 THEN 'Whales'
      WHEN R <= 2 AND F >= 4 AND M >= 4 THEN 'Cannot lose them'
      WHEN R <= 2 AND F <= 2 AND M <= 2 THEN 'Lost'
      ELSE 'Potential / At Risk'
    END AS segment
  FROM
    scoring t1
    LEFT JOIN dim_customer t2 ON t1.customer_id = t2.customer_id
)

,metrics_by_group AS (
  SELECT
    s.gender
    ,s.city
    ,s.age_group
    ,COUNT(DISTINCT s.customer_id) AS customers
    ,ROUND(SUM(fo.subtotal) / 27000.0) AS gmv
    ,ROUND(AVG(R), 2) AS R
    ,ROUND(AVG(F), 2) AS F
    ,ROUND(AVG(M), 2) AS M
  FROM
    fact_orders fo
    LEFT JOIN segmentation s ON fo.customer_id = s.customer_id
  GROUP BY
    s.gender
    ,s.city
    ,s.age_group
  HAVING
    COUNT(DISTINCT s.customer_id) > 50
  ORDER BY
    customers
)

,min_max_values AS (
  SELECT
    MIN(R) AS min_r, MAX(R) AS max_r,
    MIN(F) AS min_f, MAX(F) AS max_f,
    MIN(M) AS min_m, MAX(M) AS max_m,
    MIN(gmv) AS min_gmv, MAX(gmv) AS max_gmv
  FROM
    metrics_by_group
)

,persona_score_cte AS (
  SELECT 
    t1.city
    ,t1.gender
    ,t1.age_group
    ,t1.customers
    ,t1.gmv
    -- Tính điểm thành phần (từ 0 đến 1)
    ,ROUND((R - min_R) / (max_R - min_R), 2) AS score_R
    ,ROUND((F - min_F) / (max_F - min_F), 2) AS score_F
    ,ROUND((M - min_M) / (max_M - min_M), 2) AS score_M
    ,ROUND((gmv - min_gmv) / (max_gmv - min_gmv), 2) AS score_GMV
    
    -- Tổng điểm có trọng số (Càng cao càng tốt)
    ,ROUND((0.1 * (R - min_R) / (max_R - min_R)) + (0.25 * (F - min_F) / (max_F - min_F)) + (0.25 * (M - min_M) / (max_M - min_M)) + (0.4 * (gmv - min_gmv) / (max_gmv - min_gmv)), 2) AS final_persona_score
  FROM 
    metrics_by_group t1
    CROSS JOIN min_max_values t2
  ORDER BY 
    final_persona_score DESC
)

,best_persona_cte AS (
  SELECT
    city
    ,gender
    ,age_group
  FROM  
    persona_score_cte
  WHERE
    final_persona_score >= 0.69
)

,best_customers AS (
SELECT
  s.customer_id
  ,true AS is_best_customer
FROM
  segmentation s
  INNER JOIN best_persona_cte b
    ON s.city = b.city
      AND s.gender = b.gender
      AND s.age_group = b.age_group
)

,metrics_by_persona AS (
SELECT
  ROUND(SUM(CASE WHEN platform_voucher > 0 THEN 1 END) * 1.0 / COUNT(fo.order_id), 4) AS platform_voucher_usage_pct
  ,ROUND(SUM(CASE WHEN shop_discount > 0 THEN 1 END) * 1.0 / COUNT(fo.order_id), 4) AS shop_discount_usage_pct
  ,ROUND(SUM(CASE WHEN shipping_discount > 0 THEN 1 END) * 1.0 / COUNT(fo.order_id), 4) AS shipping_discount_usage_pct
  ,ROUND(SUM(CASE WHEN platform_voucher > 0 OR shop_discount > 0 THEN 1 END) * 1.0 / COUNT(fo.order_id), 4) AS product_voucher_usage_pct
  -- ,ROUND(SUM(CASE WHEN platform_voucher > 0 OR shop_discount > 0 OR shipping_discount > 0 THEN 1 END) * 1.0 / COUNT(fo.order_id), 4) AS overall_voucher_usage_pct
FROM
  fact_orders fo
  INNER JOIN best_customers b ON fo.customer_id = b.customer_id --inner join để chỉ lấy best customers
  -- INNER JOIN fact_order_items foi ON fo.order_id = foi.order_id
  -- INNER JOIN dim_product dp ON foi.product_id = dp.product_id
UNION
SELECT
  ROUND(SUM(CASE WHEN platform_voucher > 0 THEN 1 END) * 1.0 / COUNT(fo.order_id), 4) AS platform_voucher_usage_pct
  ,ROUND(SUM(CASE WHEN shop_discount > 0 THEN 1 END) * 1.0 / COUNT(fo.order_id), 4) AS shop_discount_usage_pct
  ,ROUND(SUM(CASE WHEN shipping_discount > 0 THEN 1 END) * 1.0 / COUNT(fo.order_id), 4) AS shipping_discount_usage_pct
  ,ROUND(SUM(CASE WHEN platform_voucher > 0 OR shop_discount > 0 THEN 1 END) * 1.0 / COUNT(fo.order_id), 4) AS product_voucher_usage_pct
FROM
  fact_orders fo
)

SELECT
  *
FROM
  metrics_by_persona;

--GMV, AOV by sales day by best customer group
WITH max_order_date AS (
  SELECT MAX(created_at::date) AS num
  FROM fact_orders
)

,metrics AS (
  SELECT
    customer_id
    ,(SELECT num FROM max_order_date) - MAX(created_at::date) AS recency
    ,COUNT(DISTINCT created_at::date) AS frequency
    ,SUM(subtotal) AS monetary
  FROM
    fact_orders
  GROUP BY
    customer_id
)

,rfm AS (
  SELECT
    customer_id
    ,NTILE(5) OVER(ORDER BY recency DESC) AS R
    ,NTILE(5) OVER(ORDER BY frequency ASC) AS F
    ,NTILE(5) OVER(ORDER BY monetary ASC) AS M
  FROM
    metrics
)

,scoring AS (
  SELECT
    customer_id
    ,R
    ,F
    ,M
    ,CONCAT(R, F, M) AS RFM
  FROM
    rfm
)

,segmentation AS (
  SELECT
    t2.customer_id AS customer_id
    ,t2.gender AS gender
    ,CASE
      WHEN (SELECT EXTRACT(YEAR FROM num) FROM max_order_date) - t2.birth_year < 18 THEN 'small students (<18)'
      WHEN (SELECT EXTRACT(YEAR FROM num) FROM max_order_date) - t2.birth_year <= 24 THEN 'big students (18-24)'
      WHEN (SELECT EXTRACT(YEAR FROM num) FROM max_order_date) - t2.birth_year <= 34 THEN 'young people (25-34)'
      WHEN (SELECT EXTRACT(YEAR FROM num) FROM max_order_date) - t2.birth_year <= 44 THEN 'middle aged (35-44)'
      ELSE 'seniors (>44)'
    END AS age_group
    ,t2.city AS city
    ,t2.preferred_device AS preferred_device
    ,t1.RFM AS rfm
    ,t1.R AS R
    ,t1.F AS F
    ,t1.M AS M
    ,CASE
      WHEN R >= 4 AND F >= 4 AND M >= 4 THEN 'Champions'
      WHEN R >= 4 AND F >= 3 AND M >= 3 THEN 'Loyalists'
      WHEN R = 3 AND F >= 3 AND M >= 3 THEN 'Slipping Loyalists'
      WHEN R >= 4 AND F <= 2 THEN 'New Customers'
      WHEN R >= 3 AND F <= 2 AND M >= 4 THEN 'Whales'
      WHEN R <= 2 AND F >= 4 AND M >= 4 THEN 'Cannot lose them'
      WHEN R <= 2 AND F <= 2 AND M <= 2 THEN 'Lost'
      ELSE 'Potential / At Risk'
    END AS segment
  FROM
    scoring t1
    LEFT JOIN dim_customer t2 ON t1.customer_id = t2.customer_id
)

,metrics_by_group AS (
  SELECT
    s.gender
    ,s.city
    ,s.age_group
    ,COUNT(DISTINCT s.customer_id) AS customers
    ,ROUND(SUM(fo.subtotal) / 27000.0) AS gmv
    ,ROUND(AVG(R), 2) AS R
    ,ROUND(AVG(F), 2) AS F
    ,ROUND(AVG(M), 2) AS M
  FROM
    fact_orders fo
    LEFT JOIN segmentation s ON fo.customer_id = s.customer_id
  GROUP BY
    s.gender
    ,s.city
    ,s.age_group
  HAVING
    COUNT(DISTINCT s.customer_id) > 50
  ORDER BY
    customers
)

,min_max_values AS (
  SELECT
    MIN(R) AS min_r, MAX(R) AS max_r,
    MIN(F) AS min_f, MAX(F) AS max_f,
    MIN(M) AS min_m, MAX(M) AS max_m,
    MIN(gmv) AS min_gmv, MAX(gmv) AS max_gmv
  FROM
    metrics_by_group
)

,persona_score_cte AS (
  SELECT 
    t1.city
    ,t1.gender
    ,t1.age_group
    ,t1.customers
    ,t1.gmv
    -- Tính điểm thành phần (từ 0 đến 1)
    ,ROUND((R - min_R) / (max_R - min_R), 2) AS score_R
    ,ROUND((F - min_F) / (max_F - min_F), 2) AS score_F
    ,ROUND((M - min_M) / (max_M - min_M), 2) AS score_M
    ,ROUND((gmv - min_gmv) / (max_gmv - min_gmv), 2) AS score_GMV
    
    -- Tổng điểm có trọng số (Càng cao càng tốt)
    ,ROUND((0.1 * (R - min_R) / (max_R - min_R)) + (0.25 * (F - min_F) / (max_F - min_F)) + (0.25 * (M - min_M) / (max_M - min_M)) + (0.4 * (gmv - min_gmv) / (max_gmv - min_gmv)), 2) AS final_persona_score
  FROM 
    metrics_by_group t1
    CROSS JOIN min_max_values t2
  ORDER BY 
    final_persona_score DESC
)

,best_persona_cte AS (
  SELECT
    city
    ,gender
    ,age_group
  FROM  
    persona_score_cte
  WHERE
    final_persona_score >= 0.69
)

,best_customers AS (
SELECT
  s.customer_id
  ,true AS is_best_customer
FROM
  segmentation s
  INNER JOIN best_persona_cte b
    ON s.city = b.city
      AND s.gender = b.gender
      AND s.age_group = b.age_group
)

,metrics_by_persona AS (
SELECT
  CASE
    WHEN EXTRACT(DAY FROM fo.created_at) = EXTRACT(MONTH FROM fo.created_at) THEN 'Double Day'
    WHEN EXTRACT(DAY FROM fo.created_at) = 25 THEN 'EOM Sale Day'
    ELSE 'Normal Day'
  END AS day_type
  ,ROUND(SUM(subtotal) / 27000.0 / COUNT(DISTINCT fo.order_date_key)) AS adgmv
  ,ROUND(SUM(subtotal) / 27000.0 / COUNT(order_id)) AS aov
FROM
  fact_orders fo
  INNER JOIN best_customers b ON fo.customer_id = b.customer_id --inner join để chỉ lấy best customers
  -- INNER JOIN fact_order_items foi ON fo.order_id = foi.order_id
  -- INNER JOIN dim_product dp ON foi.product_id = dp.product_id
GROUP BY
  CASE
    WHEN EXTRACT(DAY FROM fo.created_at) = EXTRACT(MONTH FROM fo.created_at) THEN 'Double Day'
    WHEN EXTRACT(DAY FROM fo.created_at) = 25 THEN 'EOM Sale Day'
    ELSE 'Normal Day'
  END
)

SELECT
  *
FROM
  metrics_by_persona
