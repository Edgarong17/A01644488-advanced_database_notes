-- Ejercicio 1

SELECT title FROM movies;

SELECT director FROM movies;

SELECT title,director FROM movies;

SELECT title,year FROM movies;

SELECT * FROM movies;

--Ejercicio 2

SELECT * FROM movies
where id = 6;

SELECT * FROM movies
where year >= 2000 AND year <= 2010;

SELECT * FROM movies
where year < 2000 OR year > 2010;

SELECT * FROM movies
limit 5 ;

--Ejercicio 3
SELECT * FROM movies
where title like('%Toy Story%');

SELECT * FROM movies
where Director like('John Lasseter');

SELECT * FROM movies
where Director not like('John Lasseter');

SELECT * FROM movies
where Title like('WALL-%');

--Ejercicio 4
SELECT distinct Director FROM movies
order by Director asc;

SELECT * FROM movies
order by year desc
limit 4;

SELECT * FROM movies
order by title asc
limit 5;

SELECT * FROM movies
order by title asc
limit 5 offset 5;

--Ejercicio 5
SELECT * FROM north_american_cities
where country like ('Canada');

SELECT * FROM north_american_cities
where country like ('United%')
order by latitude desc;

SELECT City FROM north_american_cities
where longitude < 
    (Select longitude from north_american_cities
        where city like ('Chicago')
    )
order by longitude asc;

SELECT * FROM north_american_cities
where country like ('Mexico')
order by population desc
limit 2;

SELECT * FROM north_american_cities
where country like ('united%')
order by population desc
limit 2 offset 2;