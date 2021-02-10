create database `CECS535Project`;
use `CECS535Project`;

create user 'cecs535'@'localhost' identified by 'taforever';
grant all privileges on * . * to 'cecs535'@'localhost';
flush privileges;

create table `Customer`
(
    id int,
    name varchar(256),
    address varchar(256),
    city varchar(64),
    zip char(5),
    state char(2),
    `credit-card` char(16),
    primary key(id)
);

create table `Bike`
(
    bnumber int,
    make varchar(64),
    color varchar(8),
    year int,
    primary key(bnumber)
);

create table `Rack`
(
    id int,
    location varchar(256),
    `num-holds` int,
    primary key(id)
);

create table `Available`
(
    bnumber int,
    `rack-id` int,
    primary key(bnumber),
    foreign key(bnumber) references `Bike`(bnumber),
    foreign key(`rack-id`) references `Rack`(id)
);

create table `Rental`
(	
    bnumber int,
    `cust-id` int,
    src int,
    date date,
    time time,
    primary key(bnumber, `cust-id`, date, time),
    foreign key(bnumber) references `Bike`(bnumber),
    foreign key(`cust-id`) references `Customer`(id),
    foreign key(src) references `Rack`(id)
);

create table `Trips`
(
    bnumber int,
    cid int,
    `init-date` date,
    `init-time` time,
    `end-date` date,
    `end-time` time,
    `origin-rack` int,
    `destination-rack` int,
    cost int,
    primary key(bnumber, cid, `init-date`, `init-time`),
    foreign key(bnumber) references `Bike`(bnumber),
    foreign key(cid) references `Customer`(id),
    foreign key(`origin-rack`) references `Rack`(id),
    foreign key(`destination-rack`) references `Rack`(id)
);

insert into `Customer`(id, name, address, city, zip, state, `credit-card`)
values
(1, 'Bobby', '600 Ruggles Place', 'Louisville', '40292', 'KY', '1234567891234567'),
(2, 'Madi', '1234 Spicy Drive', 'Louisville', '40292', 'KY', '2345678912345678'),
(3, 'Jeri', '283 Arugala Lane', 'Evansville', '47714', 'IN', '3456789123456789'),
(4, 'Synthia', '321 Orchard Lane', 'Newburgh', '47630', 'IN', '4567891234567891'),
(5, 'Charlie', '4554 Bridgestone Place', 'Denver', '80014', 'CO', '5678912345678912');


/* trigger for part a */
delimiter $$
create trigger insert_bike after insert on `Bike`
for each row 
begin
	if (Select count(id) from `Rack`) = 0 then
		signal sqlstate '45001' set message_text = "Sorry, cannot insert! No racks!";
    elseif (Select count(`rack-id`) from `Available`) < (Select count(id) from `Rack`) then
		insert into `Available`
        set bnumber = new.bnumber,
		   `rack-id` = (select max(id)
						from `Rack`
						where NOT EXISTS (Select * from (Select `rack-id` 
										  from `Available`
										  where id = `rack-id`) as a));
	elseif (select max(open_spots) 
		    from(select id, `num-holds`-count(`rack-id`) as open_spots
				 from `Available`, `Rack`
				 where id = `rack-id`
				 group by id) as a) = 0 then 
		signal sqlstate '45001' set message_text = "Sorry, cannot insert! All racks full!";
	else
		insert into `Available`
        SET bnumber = new.bnumber, 
			`rack-id` = (select max(selected_id) from(
						 select id as selected_id, open_spots
						 from (select id, `num-holds`-count(`rack-id`) as open_spots
							   from `Available`, `Rack`
							   where id = `rack-id`
							   group by id) as a
						inner join
						(select max(open_spots) as most_open
						 from(select id, `num-holds`-count(`rack-id`) as open_spots
							  from `Available`, `Rack`
							  where id = `rack-id`
							  group by id) as b) as c
					   on open_spots = most_open) as d);
	end if;
end $$;
delimiter ;

/*trigger for part b*/
delimiter $$
create trigger delete_bike before delete on `Bike`
for each row
begin
	if old.bnumber in (select bnumber from `Rental`) then
		signal sqlstate '45001' set message_text = "Sorry, cannot delete! Bike is out with a customer!";
	else
		delete from `Available` where bnumber = old.bnumber;
	end if;
end $$;    
delimiter ;
