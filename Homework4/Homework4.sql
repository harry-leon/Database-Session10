drop table if exists orders;
drop table if exists products;

create table products (
    id bigint generated always as identity primary key,
    name text not null,
    stock integer not null check (stock >= 0)
);

create table orders (
    id bigint generated always as identity primary key,
    product_id bigint not null references products(id),
    quantity integer not null check (quantity > 0)
);

create or replace function apply_stock_change(p_product_id bigint, p_delta integer)
returns void
language plpgsql
as $$
declare
    v_stock integer;
begin
    select p.stock
    into v_stock
    from products p
    where p.id = p_product_id
    for update;

    if not found then
        raise exception 'product % not found', p_product_id;
    end if;

    if v_stock + p_delta < 0 then
        raise exception 'insufficient stock for product %: stock %, change %', p_product_id, v_stock, p_delta;
    end if;

    update products
    set stock = stock + p_delta
    where id = p_product_id;
end;
$$;

create or replace function update_product_stock()
returns trigger
language plpgsql
as $$
declare
    v_delta integer;
begin
    if tg_op = 'INSERT' then
        perform apply_stock_change(new.product_id, -new.quantity);
        return new;
    end if;

    if tg_op = 'DELETE' then
        perform apply_stock_change(old.product_id, old.quantity);
        return old;
    end if;

    if old.product_id is distinct from new.product_id then
        perform apply_stock_change(old.product_id, old.quantity);
        perform apply_stock_change(new.product_id, -new.quantity);
        return new;
    end if;

    v_delta := new.quantity - old.quantity;
    if v_delta <> 0 then
        perform apply_stock_change(new.product_id, -v_delta);
    end if;

    return new;
end;
$$;

drop trigger if exists trg_update_stock on orders;

create trigger trg_update_stock
after insert or update or delete on orders
for each row
execute function update_product_stock();

insert into products (name, stock)
values
    ('iphone', 10),
    ('ipad', 5);

select id, name, stock
from products
order by id;

insert into orders (product_id, quantity)
values
    (1, 3);

select id, name, stock
from products
order by id;

update orders
set quantity = 5
where id = 1;

select id, name, stock
from products
order by id;

update orders
set product_id = 2, quantity = 2
where id = 1;

select id, name, stock
from products
order by id;

delete from orders
where id = 1;

select id, name, stock
from products
order by id;

do $$
begin
    insert into orders (product_id, quantity)
    values
        (2, 999);
exception
    when others then
        raise notice '%', sqlerrm;
end;
$$;

select id, name, stock
from products
order by id;
