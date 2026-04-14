-- ============================================================
-- Lesson 03 — Indexes: Class Exercises
-- Work through these before looking at the hints
-- ============================================================

-- ============================================================
-- Exercise 1 — Find the slow query
--
-- Run this query. Look at the execution plan.
-- Is Oracle using an index? Should it?
-- ============================================================

SELECT * FROM patient_visits WHERE site_id = 3;

-- Questions:
-- a) What scan type do you see? A full table scan,  Why? Because it reads all the table and then it perform the filter of site_id
-- b) site_id has values 1–5. Is this high or low cardinality? Low
-- c) Would adding an index on site_id help? Why or why not? It can not help a lot because it has a low cardinality, so the separation would be too little for the amount of information.

-- ============================================================
-- Exercise 2 — Create an index and see if it helps
--
-- Create an index on visit_date.
-- Then run the range query below and check the plan.
-- ============================================================

-- Step 1: Create it
-- (write the CREATE INDEX statement here)

CREATE INDEX idx_visit_date
ON patient_visits (visit_date);

-- Step 2: Gather stats
BEGIN
    DBMS_STATS.GATHER_TABLE_STATS(USER, 'PATIENT_VISITS', cascade => TRUE);
END;
/

-- Step 3: Run the range query and check the plan
SELECT * FROM patient_visits
WHERE visit_date BETWEEN SYSDATE - 30 AND SYSDATE;

-- Questions:
-- a) Does Oracle use the index for this range? no, it uses full table scan
-- b) Change the range to the last 7 days. Does the plan change? no, 
-- c) Change to the last 700 days. What happens? Bo, it return the full table scan as it needs to return allmost all the table
-- d) Why does the range size affect whether Oracle uses the index? It should affect, because it is searching for more specific data and doing a INDEX RANGE SCAN search should be more efficient.
-- but because the amount of data is to little it does not change.

-- ============================================================
-- Exercise 3 — Composite index
--
-- You often query by both patient_id AND visit_date together:
--   WHERE patient_id = 1234 AND visit_date > SYSDATE - 90
--
-- Two options:
--   Option A: Two separate indexes (one per column)
--   Option B: One composite index (patient_id, visit_date)
--
-- Create the composite index and test the query.
-- ============================================================

CREATE INDEX idx_pv_patient_date ON patient_visits(patient_id, visit_date);

BEGIN
    DBMS_STATS.GATHER_TABLE_STATS(USER, 'PATIENT_VISITS', cascade => TRUE);
END;
/

SELECT * FROM patient_visits
WHERE patient_id = 1234
  AND visit_date > SYSDATE - 90;

-- Questions:
-- a) Does the plan use the composite index? yes, it is using a  INDEX RANGE SCAN over IDX_PV_PATIENT_DATE
-- b) Now try querying ONLY on visit_date (no patient_id).
--    Does the composite index get used? Why not? No, because for the composite index to get used, it is required that the query uses the leading column which is patient_id.
-- c) What's the rule about column order in composite indexes? The rule is that the order does matter, because it forst searches on the first column and then passes throught the other one.
-- In other words for using the index it is requiered that the left coulmn is used on the search.

SELECT * FROM patient_visits WHERE patient_id = 1234;

-- Trailing column only (index cannot be used from the middle):
SELECT * FROM patient_visits WHERE visit_date > SYSDATE - 90;

-- ============================================================
-- Exercise 4 — Function that breaks an index
--
-- There IS an index on patient_id (from lesson 03).
-- Predict what happens when you wrap the column in a function.
-- ============================================================

-- This query CAN use the index:
SELECT * FROM patient_visits WHERE patient_id = 5432;
-- This one cannot — why?
SELECT * FROM patient_visits WHERE TO_CHAR(patient_id) = '5432';

-- Questions:
-- a) What scan type did the second query use? It uses a table access full
-- b) Why does wrapping a column in a function break index use? Because for the index to work it needs to use the same value and in here we are performing a comparison of char
-- c) How would you rewrite the second query to allow index use?
-- SELECT * FROM patient_visits WHERE patient_id = TO_NUMBER('5432');
-- The other option is to create the index
-- CREATE INDEX idx_func_patient_id
-- ON patient_visits (TO_CHAR(patient_id));

-- ============================================================
-- Exercise 5 — Discussion: real-world scenarios
--
-- For each scenario below, decide:
--   a) Would you add an index?
--   b) On which column(s)?
--   c) Any concerns?
-- ============================================================

-- Scenario A:
-- A reporting table gets loaded once per night (batch ETL).
-- During the day, analysts run SELECT queries by date range.
-- The table has 50 million rows.
-- → Index on date? Yes/No, why? Yes, becuase the amount of date is to large and the index is on date which is the same as the analytics run.

-- Scenario B:
-- An OLTP orders table gets 10,000 inserts per minute.
-- Support staff look up orders by customer_id or order_status.
-- order_status has 4 values: pending, processing, shipped, cancelled.
-- → What indexes would you add? I would add an index for customer_id because there are a lot of request and it has a high cardinality which orer_status does not has.
-- I would also consider a compund index where customer_id is the primary and order_status the secondary

-- Scenario C:
-- A patient table has an email column (unique per patient).
-- There are 5 million patients.
-- The app frequently does: WHERE email = 'user@example.com'
-- → What kind of index would be best here? An unique index would be the best because the mails are always diferent pero client and beciase there are a lot of registries.

-- ============================================================
-- Cleanup — remove indexes created in these exercises
-- ============================================================
DROP INDEX idx_pv_patient_date;
-- If you created an index on visit_date in Exercise 2, drop it here:
-- DROP INDEX idx_pv_visit_date;

Este tema está cerrado para comentarios.
