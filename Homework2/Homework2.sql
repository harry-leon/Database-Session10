drop table if exists orders;
drop table if exists customers;

create table customers (
    id bigint generated always as identity primary key,
    name text not null,
    credit_limit numeric(12, 2) not null check (credit_limit >= 0)
);

create table orders (
    id bigint generated always as identity primary key,
    customer_id bigint not null references customers(id),
    order_amount numeric(12, 2) not null check (order_amount >= 0)
);

create or replace function check_credit_limit()
returns trigger
language plpgsql
as $$
declare
    v_credit_limit numeric(12, 2);
    v_total_orders numeric(12, 2);
begin
    select c.credit_limit
    into v_credit_limit
    from customers c
    where c.id = new.customer_id;

    if v_credit_limit is null then
        raise exception 'customer % not found', new.customer_id;
    end if;

    select coalesce(sum(o.order_amount), 0)
    into v_total_orders
    from orders o
    where o.customer_id = new.customer_id;

    if v_total_orders + new.order_amount > v_credit_limit then
        raise exception 'credit limit exceeded for customer %: total %, new %, limit %',
            new.customer_id, v_total_orders, new.order_amount, v_credit_limit;
    end if;

    return new;
end;
$$;

drop trigger if exists trg_check_credit on orders;

create trigger trg_check_credit
before insert on orders
for each row
execute function check_credit_limit();

insert into customers (name, credit_limit)
values
    ('an', 100.00),
    ('binh', 200.00);

insert into orders (customer_id, order_amount)
values
    (1, 60.00);

insert into orders (customer_id, order_amount)
values
    (1, 30.00);

do $$
begin
    insert into orders (customer_id, order_amount)
    values
        (1, 20.00);
exception
    when others then
        raise notice '%', sqlerrm;
end;
$$;

select c.id, c.name, c.credit_limit, coalesce(sum(o.order_amount), 0) as total_orders
from customers c
left join orders o on o.customer_id = c.id
group by c.id, c.name, c.credit_limit
order by c.id;
