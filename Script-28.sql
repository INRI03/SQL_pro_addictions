--Задание 1

create or replace view payment_new as
	select p.payment_id as payment,
		   a.address || ', ' || c2.city || ', ' || c3.country as customer_address,
		   f.title || ', ' || f.release_year as films,
		   sum(p.amount) over (partition by date_part('month', p.payment_date)) as sum_at_month,
		   sum(p.amount) over (partition by date_part('week', p.payment_date)) as sum_at_week,
		   s.store_id as store,
		   s2.last_name || ' ' || s2.first_name as staff_name 
	from payment p
		join customer c on c.customer_id = p.customer_id
		join store s on s.store_id = c.store_id
		join address a on a.address_id = c.address_id
		join city c2 on c2.city_id = a.city_id
		join country c3 on c3.country_id = c2.country_id 
		join staff s2 on s2.staff_id = s.manager_staff_id
		join rental r on r.rental_id = p.rental_id
		join inventory i on i.inventory_id = r.inventory_id
		join film f on f.film_id = i.film_id 
	group by 1,2,3,6,7
	order by 1

	select * from payment_new
	
	
  -- Доп. задание. Что-то не работает, не пойму что. Пытаюсь внести в таблицу payment вручную новый кортеж, чтоб проверить,
  -- как отработает триггер, и выдает ошибку:
  -- "SQL Error [42601]: ОШИБКА: подзапрос должен вернуть только один столбец
  -- Где: функция PL/pgSQL add_payments(), строка 3, оператор SQL-оператор"
  -- Сначала думал, может дело в конкатенации, но даже если сделать раздельные колонки, без concat, все равно при ручном
  -- внесении в таблицу payment выходит эта же ошибка.

	
	create or replace function add_payments() returns trigger as $$
	begin
	 	insert into payment_new values
		(new.payment_id,
			(select a.address || ', ' || c2.city || ', ' || c3.country
			from payment p
			join customer c on c.customer_id = p.customer_id
			join address a on a.address_id = c.address_id
			join city c2 on c2.city_id = a.city_id
			join country c3 on c3.country_id = c2.country_id
			where p.payment_id = new.payment_id),
				(select f.title || ', ' || f.release_year
				from payment p
				join rental r on r.rental_id = p.rental_id
				join inventory i on i.inventory_id = r.inventory_id 
				join film f on f.film_id = i.film_id
				where p.payment_id = new.payment_id),
					(select sum(amount) over (partition by date_part('month', payment_date)),
						    sum(amount) over (partition by date_part('week', payment_date))
					from payment
				    where payment_id = new.payment_id),
					    (select s.store_id,
					    		s2.last_name || ' ' || s2.first_name
						from payment p
						join customer c on c.customer_id = p.customer_id
						join store s on s.store_id  = c.store_id
						join staff s2 on s2.staff_id = s.manager_staff_id 
						where p.payment_id = new.payment_id));
	end; 
$$ language plpgsql
		
					
	create trigger payment
	after insert on payment
	for each row execute function add_payments()
	

	
