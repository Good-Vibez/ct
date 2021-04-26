create table if not exists Network (
	name text primary key
);

insert or ignore into Network (name) values
	("Main")
;

select * from Network;
