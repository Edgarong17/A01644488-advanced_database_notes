--- Lesson 6 ---
SELECT * FROM movies m
Inner join Boxoffice b on m.id = b.Movie_id;

SELECT * FROM movies m
Inner join Boxoffice b on m.id = b.Movie_id
where b.international_sales > b.domestic_sales;

SELECT * FROM movies m
Inner join Boxoffice b on m.id = b.Movie_id
order by rating desc;

---leson 7 ---
SELECT Distinct(building_name) FROM buildings b
inner join employees e on b.building_name = e.building;

SELECT * FROM buildings b;

SELECT building_name, role FROM buildings b
left join employees e on b.building_name = e.building
GROUP BY b.building_name, e.role;

--And interview question:

SELECT p.page_id FROM pages  p
left JOIN page_likes pl on p.page_id = pl.page_id
where liked_date IS NULL
order by p.page_id asc;