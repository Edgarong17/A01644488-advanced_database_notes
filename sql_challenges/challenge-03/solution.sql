--SQL BOLT Lesson 10
SELECT MAX(years_employed) FROM employees;

SELECT role,AVG(years_employed) FROM employees
group by role;

SELECT building,sum(years_employed) FROM employees
group by building;

--SQL BOLT Lesson 11
SELECT count(name) FROM employees
where role = 'Artist';

SELECT role,count(name) FROM employees
group by role;

SELECT sum(years_employed) FROM employees
WHERE role = 'Engineer';

--Oracle

select count(Distinct(shape)) number_of_shapes,
       Stddev(Distinct(WEIGHT))distinct_weight_stddev
from   bricks;

select shape, sum(weight) shape_weight
from   bricks
group by Shape
order by shape asc;

select shape, sum ( weight )
from   bricks
group  by Shape
having Shape = 'cuboid';