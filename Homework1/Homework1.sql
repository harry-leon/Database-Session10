drop table if exists products;

create table products (
    id bigint generated always as identity primary key,
    name text not null,
    price numeric(12, 2) not null check (price >= 0),
    last_modified timestamptz not null default current_timestamp
);

create or replace function update_last_modified()
returns trigger
language plpgsql
as $$
begin
    new.last_modified := current_timestamp;
    return new;
end;
$$;

drop trigger if exists trg_update_last_modified on products;

create trigger trg_update_last_modified
before update on products
for each row
execute function update_last_modified();

insert into products (name, price)
values
    ('laptop', 1500.00),
    ('mouse', 25.50),
    ('keyboard', 45.00);

select id, name, price, last_modified
from products
order by id;

update products
set price = price + 10.00
where name in ('mouse', 'keyboard');

select id, name, price, last_modified
from products
order by id;
