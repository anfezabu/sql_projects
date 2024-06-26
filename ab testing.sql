--We are running an experiment at an item-level, which means all users who visit will see the same page, but the layout of different item pages may differ.
--Compare this table to the assignment events we captured for user_level_testing.
--Does this table have everything you need to compute metrics like 30-day view-binary?
-- No, it doesn't. I need the test_start_date and the created_at variable.
SELECT 
  * 
FROM 
  dsv1069.final_assignments_qa 


--Reformat the final_assignments_qa to look like the final_assignments table, filling in any missing values with a placeholder of the appropriate data type.

--I used the union function to create a table with the different tests inside rows and not columns. 
-- Also, I assigned a different date to each test.

SELECT 
  item_id,
  test_a AS test_assignment,
  (CASE
       WHEN test_a IS NOT NULL THEN 'test_a'
       ELSE NULL
   END) AS test_number,
  (CASE
       WHEN test_a IS NOT NULL THEN CAST ('2020-06-01' AS DATE)
       ELSE NULL
   END) AS test_start_date
FROM 
  dsv1069.final_assignments_qa
UNION
SELECT
  item_id,
  test_b AS test_assignment,
  (CASE
       WHEN test_b IS NOT NULL THEN 'test_b'
       ELSE NULL
   END) AS test_number,
  (CASE
       WHEN test_b IS NOT NULL THEN CAST('2020-09-01' AS DATE)
       ELSE NULL
   END) AS test_start_date
FROM 
  dsv1069.final_assignments_qa
UNION
SELECT 
  item_id,
  test_c AS test_assignment,
  (CASE
       WHEN test_c IS NOT NULL THEN 'test_c'
       ELSE NULL
   END) AS test_number,
  (CASE
       WHEN test_c IS NOT NULL THEN CAST('2020-12-01' AS DATE)
       ELSE NULL
   END) AS test_start_date
FROM 
  dsv1069.final_assignments_qa
UNION
SELECT 
  item_id,
  test_d AS test_assignment,
  (CASE
       WHEN test_d IS NOT NULL THEN 'test_d'
       ELSE NULL
   END) AS test_number,
  (CASE
       WHEN test_d IS NOT NULL THEN CAST('2021-03-01' AS DATE)
       ELSE NULL
  END) AS test_start_date
FROM 
  dsv1069.final_assignments_qa
UNION
SELECT 
  item_id,
  test_e AS test_assignment,
  (CASE
       WHEN test_e IS NOT NULL THEN 'test_e'
       ELSE NULL
   END) AS test_number,
  (CASE
       WHEN test_e IS NOT NULL THEN CAST('2021-06-01' AS DATE)
       ELSE NULL
  END) AS test_start_date
FROM 
  dsv1069.final_assignments_qa
UNION
SELECT 
  item_id,
  test_f AS test_assignment,
  (CASE
       WHEN test_f IS NOT NULL THEN 'test_f'
       ELSE NULL
   END) AS test_number,
  (CASE
       WHEN test_f IS NOT NULL THEN CAST('2021-09-01' AS DATE)
       ELSE NULL
  END) AS test_start_date
FROM 
  dsv1069.final_assignments_qa;


-- Use this table to 
-- compute order_binary for the 30 day window after the test_start_date
-- for the test named item_test_2
SELECT 
  test_assignment,
  COUNT(DISTINCT item_id) AS total_items,
  SUM(orders_binary) AS items_ordered_within_30_days
FROM
  (SELECT 
    item_id,
    test_assignment,
    test_number,
    test_start_date,
    created_at,
    MAX(CASE
          WHEN created_at > test_start_date
          AND DATE_PART('day', created_at - test_start_date) <= 30 THEN 1
          ELSE 0
          END) AS orders_binary
  FROM 
    (SELECT 
      f.*,
      DATE(o.created_at) AS created_at
    FROM 
      dsv1069.final_assignments f
    LEFT JOIN 
      dsv1069.orders o
    ON 
    o.item_id = f.item_id
    WHERE 
      test_number = 'item_test_2') AS item_test_2
  GROUP BY 
    item_id,
    test_assignment,
    test_number,
    test_start_date,
    created_at) AS item_test_2_part_2
GROUP BY 
  test_assignment


-- Use the final_assignments table to calculate the view binary, and
-- average views for the 30 day window after the test assignment for
-- item_test_2. (You may include the day the test started)
SELECT 
  test_assignment,
  COUNT(item_id),
  SUM(view_binary) total_views,
  AVG(view_binary) AS avg_views_within_30_days,
  STDDEV(view_binary) AS stddev_view_binary
FROM 
  (SELECT 
    item_id,
    test_assignment,
    MAX(CASE 
          WHEN view_time > test_start_date 
          AND DATE_PART('day', view_time - test_start_date) <= 30 THEN 1
          ELSE 0
          END) AS view_binary
  FROM
    (SELECT 
      f.*,
      DATE(event_time) AS view_time
    FROM
      dsv1069.final_assignments f
    LEFT JOIN 
      dsv1069.events e
    ON 
      CAST(e.parameter_value AS INT) = f.item_id
    WHERE 
      parameter_name = 'item_id'
    AND 
      test_number = 'item_test_2') AS item_view_time
  GROUP BY 
    item_id,
    test_assignment) AS view_binary
GROUP BY 
  test_assignment


--Use the https://thumbtack.github.io/abba/demo/abba.html to compute the lifts in metrics and the p-values for the binary metrics ( 30 day order binary and 30 day view binary) using a interval 95% confidence. 

--Both metrics:total orders per item and total views per item by group (control and treatment)
--are not statistically significant.

-- 30 day order binary (p-value = 0.93) > 0,05 (the null hypothesis is not rejected)
