-- Before writing any query, answer these for EACH exercise:
--
-- 1. What is the business question?
-- 2. What is the exact definition? (Include every filter, every join)
-- 3. What are the edge cases? (NULLs, cancelled tasks, unassigned tasks, etc.)
-- 4. What is the unit? (Count, percentage, hours, dollars?)
-- 5. What would make this metric misleading?

-- ============================================================
-- EXERCISE 1: Define "Team Velocity"
-- ============================================================
--
-- Business context: Management wants to compare how fast each team
-- completes work. They ask for "team velocity."
--
-- YOUR TASK:
-- 1. Define the KPI contract in comments. What EXACTLY does "velocity" mean?
--    Is it tasks completed per day? Per person? Per story point?
--    (We do not have story points — how does that change the definition?)
-- 2. Write a query that shows each team's velocity with your chosen definition.
-- 3. Add a column that flags teams with velocity below the overall average.
--
-- Edge case to consider: The Product team has fewer people than Engineering.
-- Should velocity be normalized per team member? What are the pros and cons?

-- 1. What is the business question?
-- What is the velocity of the team
-- What is the exact definition? (Include every filter, every join)
-- Velocity = completed tasks / number of team members
-- 3. What are the edge cases? (NULLs, cancelled tasks, unassigned tasks, etc.)
-- Teams with zero completed tasks
-- Teams with zero users
-- 4. What is the unit? (Count, percentage, hours, dollars?)
-- Completed tasks per team member
-- 5. What would make this metric misleading?
-- The complexity of the tasks and the time range of the tasks
-- [Write your query below]

SELECT
    t.name AS team_name,
    ROUND(
        COUNT(CASE WHEN ts.status = 'completed' THEN ts.id END)
        / COUNT(DISTINCT u.id),
        2
    ) AS team_velocity
FROM teams t
LEFT JOIN users u
       ON u.team_id = t.id
LEFT JOIN tasks ts
       ON ts.assigned_to = u.id
GROUP BY t.name
ORDER BY team_velocity DESC;

-- ============================================================
-- EXERCISE 2: Define "On-Time Delivery Rate"
-- ============================================================
--
-- Business context: The product manager wants to know: "Do we meet
-- our deadlines?" They ask for an "on-time delivery rate."
--
-- YOUR TASK:
-- 1. Define the KPI contract in comments. What does "on-time" mean?
--    Is it completed before due_date? Before end-of-day on due_date?
--    What about tasks with no due_date?
-- 2. Write a query that calculates the on-time delivery rate.
-- 3. Break it down by priority (critical, high, medium, low).
-- 4. Add a column showing the average "lateness" in hours for overdue tasks.
--
-- Edge case to consider: A task completed at 23:59 on the due date
-- vs. 00:01 the next day. Should both be "late"? Neither? Only one?
-- How does your choice affect the metric?

-- [Write your contract here as a SQL comment]
-- 1. What is the business question?
-- Percentage of task completed on time
-- 2. What is the exact definition? (Include every filter, every join)
-- TaskCompleted% = (CompletedTasksInTime/NumberOfTasks) *100
-- 3. What are the edge cases? (NULLs, cancelled tasks, unassigned tasks, etc.)
-- Task which have not meet the deadline
-- Tasks without a deadline
-- 4. What is the unit? (Count, percentage, hours, dollars?)
-- Percentage
-- 5. What would make this metric misleading?
-- A task is change its state after  the deadline

-- [Write your query below]

SELECT
    COUNT(*) AS total_completed_tasks,
    COUNT(
        CASE
            WHEN completed_at <= CAST(due_date + 1 AS TIMESTAMP)
            THEN 1
        END
    ) AS completed_on_time,
    ROUND(
        COUNT(
            CASE
                WHEN completed_at <= CAST(due_date + 1 AS TIMESTAMP)
                THEN 1
            END
        ) * 100 / COUNT(*),
        2
    ) AS on_time_delivery_rate,
    ROUND(
        AVG(
            CASE
                WHEN completed_at > CAST(due_date + 1 AS TIMESTAMP)
                THEN
                    (CAST(completed_at AS DATE) - due_date) * 24
            END
        ),
        2
    ) AS avg_lateness_hours
FROM tasks
WHERE status = 'completed'
  AND due_date IS NOT NULL;


-- ============================================================
-- PART B: Improve the Class KPIs
-- ============================================================
-- The KPIs from 03_kpi_queries.sql work, but they can be better.
-- For each exercise, identify the flaw and rewrite the query.


-- ============================================================
-- EXERCISE 3: Improve "Tasks per Team" (KPI 2 from class)
-- ============================================================
--
-- FLAW: The original query counts ALL tasks assigned to users in a team,
-- including completed and cancelled tasks. A team with 50 completed tasks
-- and 0 open tasks looks "busy" but has no current workload.
--
-- YOUR TASK:
-- 1. Rewrite the query to show THREE columns per team:
--    - total_tasks (all time)
--    - active_tasks (open + in_progress + blocked)
--    - completion_rate (completed / total, excluding cancelled)
-- 2. Add a "health score" column: a CASE expression that labels each team
--    as 'Overloaded' (active_tasks > 10), 'Healthy' (5-10), or 'Underutilized' (< 5).
-- 3. Order by active_tasks DESC so the busiest teams appear first.

-- Original (from 03_kpi_queries.sql — KPI 2):
-- SELECT t.name AS team_name,
--        COUNT(ts.id) AS task_count
-- FROM   teams t
-- LEFT   JOIN users u ON u.team_id = t.id
-- LEFT   JOIN tasks ts ON ts.assigned_to = u.id
-- GROUP  BY t.id, t.name
-- ORDER  BY task_count DESC;
--
-- Technique: LEFT JOIN chain. We start from teams (the dimension table)
-- and LEFT JOIN through users to tasks. This ensures teams with zero
-- tasks still appear (count = 0), which an INNER JOIN would hide.

-- [Write your improved query below]
SELECT 
    t.name AS team_name,
    COUNT(ts.id) AS total_tasks,
    COUNT(CASE WHEN ts.status IN ('open', 'in_progress', 'blocked') THEN 1 END) AS active_tasks,
    ROUND(
        (COUNT(CASE WHEN ts.status = 'completed' THEN 1 END) / 
        NULLIF(COUNT(CASE WHEN ts.status != 'cancelled' THEN 1 END), 0)) * 100, 1
    ) AS completion_rate,
    CASE 
        WHEN COUNT(CASE WHEN ts.status IN ('open', 'in_progress', 'blocked') THEN 1 END) > 10 THEN 'Overloaded'
        WHEN COUNT(CASE WHEN ts.status IN ('open', 'in_progress', 'blocked') THEN 1 END) BETWEEN 5 AND 10 THEN 'Healthy'
        ELSE 'Underutilized'
    END AS health_score
FROM teams t
LEFT JOIN users u ON u.team_id = t.id
LEFT JOIN tasks ts ON ts.assigned_to = u.id
GROUP BY t.id, t.name
ORDER BY active_tasks DESC;

-- ============================================================
-- EXERCISE 4: Improve "Average Resolution Time" (KPI 5 from class)
-- ============================================================
--
-- FLAW: The original query averages ALL completed tasks together.
-- A critical bug fixed in 2 hours and a documentation update fixed in
-- 40 hours are averaged together. The metric hides priority differences.
--
-- YOUR TASK:
-- 1. Rewrite the query to show average resolution time BY PRIORITY.
-- 2. Add a column showing the MEDIAN resolution time per priority.
--    (Hint: Oracle 23ai supports PERCENTILE_CONT. Research it.)
-- 3. Add a column showing the FASTEST and SLOWEST resolution time per priority.
--    (Hint: MIN and MAX, but only if you want simple extremes.)
-- 4. Add a "target met" column: For each priority, define a target SLA
--    (critical = 24h, high = 72h, medium = 168h, low = 336h) and flag
--    whether the average meets the target.
--
-- Edge case: What if a priority has only 1 completed task? Is the average meaningful?
-- How should you communicate that in the result?

-- Original (from 03_kpi_queries.sql — KPI 5):
-- SELECT ROUND(AVG(
--            EXTRACT(DAY FROM (completed_at - created_at)) * 24 +
--            EXTRACT(HOUR FROM (completed_at - created_at)) +
--            EXTRACT(MINUTE FROM (completed_at - created_at)) / 60
--        ), 1) AS avg_resolution_hours,
--        COUNT(*) AS completed_task_count
-- FROM   tasks
-- WHERE  status = 'completed'
--   AND  completed_at IS NOT NULL;
--
-- Technique: EXTRACT from INTERVAL. Oracle timestamp subtraction
-- returns a DAY TO SECOND interval. We break it into components.
-- We also report the count — an average of 2 tasks is not meaningful.

-- [Write your improved query below]
SELECT 
    priority,
    COUNT(*) AS completed_task_count,
    ROUND(AVG(
        EXTRACT(DAY FROM (completed_at - created_at)) * 24 +
        EXTRACT(HOUR FROM (completed_at - created_at)) +
        EXTRACT(MINUTE FROM (completed_at - created_at)) / 60
    ), 1) AS avg_resolution_hours,
    ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (
        ORDER BY (
            EXTRACT(DAY FROM (completed_at - created_at)) * 24 +
            EXTRACT(HOUR FROM (completed_at - created_at)) +
            EXTRACT(MINUTE FROM (completed_at - created_at)) / 60
        )
    ), 1) AS median_resolution_hours,
    ROUND(MIN(
        EXTRACT(DAY FROM (completed_at - created_at)) * 24 +
        EXTRACT(HOUR FROM (completed_at - created_at)) +
        EXTRACT(MINUTE FROM (completed_at - created_at)) / 60
    ), 1) AS fastest_resolution_hours,
    ROUND(MAX(
        EXTRACT(DAY FROM (completed_at - created_at)) * 24 +
        EXTRACT(HOUR FROM (completed_at - created_at)) +
        EXTRACT(MINUTE FROM (completed_at - created_at)) / 60
    ), 1) AS slowest_resolution_hours,
    CASE 
        WHEN priority = 'critical' AND AVG(EXTRACT(DAY FROM (completed_at - created_at))*24) <= 24  THEN 'TARGET MET'
        WHEN priority = 'high'     AND AVG(EXTRACT(DAY FROM (completed_at - created_at))*24) <= 72  THEN 'TARGET MET'
        WHEN priority = 'medium'   AND AVG(EXTRACT(DAY FROM (completed_at - created_at))*24) <= 168 THEN 'TARGET MET'
        WHEN priority = 'low'      AND AVG(EXTRACT(DAY FROM (completed_at - created_at))*24) <= 336 THEN 'TARGET MET'
        ELSE 'SLA BREACH'
    END AS target_sla_status
FROM tasks
WHERE status = 'completed'
  AND completed_at IS NOT NULL
GROUP BY priority
ORDER BY avg_resolution_hours ASC;

-- ============================================================
-- EXERCISE 5: Improve "Overdue Tasks" (KPI 7 from class)
-- ============================================================
--
-- FLAW: The original query is a simple COUNT. It tells you HOW MANY
-- tasks are overdue, but not HOW OVERDUE, WHO owns them, or WHAT
-- the business impact is. A critical task 1 day late is different
-- from a low-priority task 30 days late.
--
-- YOUR TASK:
-- 1. Rewrite the query as a detailed report (not just a count).
--    Include: task title, assignee, team, priority, due_date,
--    days_overdue (calculated), and a "severity" column.
-- 2. Define severity as:
--    - 'CRITICAL': priority = 'critical' AND days_overdue > 0
--    - 'HIGH': priority = 'high' AND days_overdue > 2
--    - 'MEDIUM': priority = 'medium' AND days_overdue > 5
--    - 'LOW': everything else overdue
-- 3. Order by severity (most urgent first), then by days_overdue DESC.
-- 4. Add a summary row at the bottom (using ROLLUP or UNION) showing
--    total overdue count and average days overdue per severity level.

-- Original (from 03_kpi_queries.sql — KPI 7):
-- SELECT COUNT(*) AS overdue_count
-- FROM   tasks
-- WHERE  due_date < TRUNC(SYSDATE)
--   AND  status NOT IN ('completed', 'cancelled')
--   AND  due_date IS NOT NULL;
--
-- Technique: TRUNC(SYSDATE) gives today at midnight. We compare dates
-- without time-of-day to avoid false positives (a task due "today"
-- at 23:59 should not be flagged at 09:00).
-- NULL check is defensive — always filter out unknown due dates.

-- [Write your improved query below]

SELECT
    ts.title AS task_title,
    u.full_name AS assignee,
    t.name AS team_name,
    ts.priority,
    ts.due_date,
    TRUNC(SYSDATE - ts.due_date) AS days_overdue,
    CASE
        WHEN ts.priority = 'critical'
             AND TRUNC(SYSDATE - ts.due_date) > 0
        THEN 'CRITICAL'
        WHEN ts.priority = 'high'
             AND TRUNC(SYSDATE - ts.due_date) > 2
        THEN 'HIGH'
        WHEN ts.priority = 'medium'
             AND TRUNC(SYSDATE - ts.due_date) > 5
        THEN 'MEDIUM'
        ELSE 'LOW'
    END AS severity
FROM tasks ts
LEFT JOIN users u
    ON ts.assigned_to = u.id
LEFT JOIN teams t
    ON u.team_id = t.id
WHERE ts.due_date < TRUNC(SYSDATE)
  AND ts.status NOT IN ('completed', 'cancelled')
  AND ts.due_date IS NOT NULL
ORDER BY
    CASE
        WHEN ts.priority = 'critical' THEN 1
        WHEN ts.priority = 'high' THEN 2
        WHEN ts.priority = 'medium' THEN 3
        ELSE 4
    END,
    days_overdue DESC;



-- ============================================================
-- PART C: The "Bad KPI" Challenge
-- ============================================================
-- Below are three queries that return numbers. Each is a BAD KPI.
-- Your task: Identify WHY it is bad, then rewrite it correctly.


-- ============================================================
-- EXERCISE 6: Fix the "Productivity Score"
-- ============================================================
--
-- BAD QUERY:
-- SELECT u.full_name, COUNT(ts.id) AS productivity_score
-- FROM users u
-- JOIN tasks ts ON ts.assigned_to = u.id
-- GROUP BY u.id, u.full_name
-- ORDER BY productivity_score DESC;
--
-- PROBLEM: ____________________________________________________
-- (What is wrong with this metric? Hint: Does it distinguish between
--  creating 10 tasks and completing 10 tasks? Does it handle unassigned
--  tasks? Does it account for task complexity or priority?)
--
--The current KPI only counts the number of assigned tasks, it does not distinguish
-- completed work form uncompleted one and it also ignores dificulty and priority.
--
-- REWRITE: Write a query that measures something actually meaningful.
-- Suggestion: "Completed tasks per day, weighted by priority."

-- [Write your analysis as a SQL comment]
-- [Write your rewritten query below]

SELECT
    u.full_name,
    COUNT(ts.id) AS completed_tasks, -- We count the number of completed tasks
    SUM(
        CASE
            WHEN ts.priority = 'critical' THEN 4 -- we assign more value to task with higher priority
            WHEN ts.priority = 'high' THEN 3
            WHEN ts.priority = 'medium' THEN 2
            WHEN ts.priority = 'low' THEN 1
            ELSE 0
        END
    ) AS weighted_productivity_score

FROM users u

LEFT JOIN tasks ts
    ON ts.assigned_to = u.id

WHERE ts.status = 'completed'

GROUP BY u.id, u.full_name

ORDER BY weighted_productivity_score DESC; -- We order the productivity score of each member.

-- ============================================================
-- EXERCISE 7: Fix the "Team Efficiency"
-- ============================================================
--
-- BAD QUERY:
-- SELECT t.name, AVG(ts.id) AS avg_task_id
-- FROM teams t
-- JOIN users u ON u.team_id = t.id
-- JOIN tasks ts ON ts.assigned_to = u.id
-- GROUP BY t.id, t.name;
--
-- PROBLEM: The problem is that the average task id does not mean anything of rthe business
-- they are only identifiers, not performance metrics
-- (What is mathematically wrong here? What does "average task ID" mean?)
--
-- REWRITE: Write a query that measures actual team efficiency.
-- Suggestion: "Ratio of completed tasks to total tasks, per team."

-- [Write your analysis as a SQL comment]
-- [Write your rewritten query below]

SELECT
    t.name AS team_name,
    COUNT(ts.id) AS total_tasks, -- We count the number of tasks
    SUM(
        CASE
            WHEN ts.status = 'completed' THEN 1 -- We obtain the completed tasks
            ELSE 0
        END
    ) AS completed_tasks,
    CASE
        WHEN COUNT(ts.id) = 0 THEN 0
        ELSE ROUND(
            SUM(
                CASE
                    WHEN ts.status = 'completed' THEN 1 
                    ELSE 0
                END
            ) / COUNT(ts.id), -- eficient ratio using the number of tasks and the completed tasks
            2
        )
    END AS efficiency_ratio
FROM teams t
LEFT JOIN users u
    ON u.team_id = t.id
LEFT JOIN tasks ts
    ON ts.assigned_to = u.id
GROUP BY t.id, t.name


-- ============================================================
-- EXERCISE 8: Fix the "Urgency Index"
-- ============================================================
--
-- BAD QUERY:
-- SELECT title, priority * 10 + DUE_DATE AS urgency_index
-- FROM tasks
-- ORDER BY urgency_index DESC;
--
-- PROBLEM: It is trying to add a numeric and a string value which is not valid
-- or will result on an unintended behaivior form the bd. 
-- (What is wrong with adding a string and a number? What is wrong with
--  multiplying a VARCHAR by 10? What should the query actually do?)
--
-- REWRITE: Write a query that creates a real urgency score.
-- Suggestion: Assign numeric weights to priority (critical=4, high=3,
-- medium=2, low=1) and add days_until_due (negative if overdue).
-- A higher score = more urgent.

-- [Write your analysis as a SQL comment]
-- [Write your rewritten query below]

SELECT
    title,
    priority,
    due_date,
    TRUNC(due_date - SYSDATE) AS days_until_due,
    CASE
        WHEN priority = 'critical' THEN 4 -- We assign values to different states
        WHEN priority = 'high' THEN 3
        WHEN priority = 'medium' THEN 2
        WHEN priority = 'low' THEN 1
        ELSE 0
    END AS priority_weight,
    (
        CASE
            WHEN priority = 'critical' THEN 4
            WHEN priority = 'high' THEN 3
            WHEN priority = 'medium' THEN 2
            WHEN priority = 'low' THEN 1
            ELSE 0
        END
        * 10
    )
    -
    TRUNC(due_date - SYSDATE) AS urgency_score -- The urgency score uses the due date and the numeric priority multiplied
FROM tasks
WHERE due_date IS NOT NULL
  AND status NOT IN ('completed', 'cancelled')
ORDER BY urgency_score DESC;