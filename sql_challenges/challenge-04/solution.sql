-- Analytic Functions: Databases for Developers
-- 1
select b.*,
       count(*) over (
         partition by shape
       ) bricks_per_shape,
       median ( weight ) over (
         partition by weight
       ) median_weight_per_shape
from   bricks b
order  by shape, weight, brick_id;

-- 2 
select b.brick_id, b.weight,
       round ( avg ( weight ) over (
         order by brick_id
       ), 2 ) running_average_weight
from   bricks b
order  by brick_id;

-- 3
select b.*,
       min ( colour ) over (
         order by brick_id
         rows between 2 preceding and 1 preceding
       ) first_colour_two_prev,
       count (*) over (
         order by weight
         range between 0 preceding and 1 following
       ) count_values_this_and_next
from   bricks b
order  by weight;

-- datalemur

Select d.department_name, e.NAME, e.salary
from (
  Select e.name, e.salary, e.department_id,DENSE_RANK()
    over (
      PARTITION by e.department_id
      ORDER BY e.salary DESC
      ) 
    as salary_rank from employee e 
) e
inner join department d on d.department_id = e.department_id
WHERE e.salary_rank <= 3
ORDER BY d.department_name ASC, e.salary DESC, e.name ASC; 