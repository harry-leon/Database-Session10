drop table if exists employees_log;
drop table if exists employees;

create table employees (
    id bigint generated always as identity primary key,
    name text not null,
    position text not null,
    salary numeric(12, 2) not null check (salary >= 0)
);

create table employees_log (
    employee_id bigint not null,
    operation text not null,
    old_data jsonb,
    new_data jsonb,
    change_time timestamptz not null default current_timestamp
);

create or replace function log_employees_changes()
returns trigger
language plpgsql
as $$
begin
    if tg_op = 'INSERT' then
        insert into employees_log (employee_id, operation, old_data, new_data, change_time)
        values (new.id, tg_op, null, to_jsonb(new), clock_timestamp());
        return new;
    end if;

    if tg_op = 'UPDATE' then
        insert into employees_log (employee_id, operation, old_data, new_data, change_time)
        values (new.id, tg_op, to_jsonb(old), to_jsonb(new), clock_timestamp());
        return new;
    end if;

    insert into employees_log (employee_id, operation, old_data, new_data, change_time)
    values (old.id, tg_op, to_jsonb(old), null, clock_timestamp());
    return old;
end;
$$;

drop trigger if exists trg_employees_log on employees;

create trigger trg_employees_log
after insert or update or delete on employees
for each row
execute function log_employees_changes();

insert into employees (name, position, salary)
values
    ('an', 'developer', 1500.00),
    ('binh', 'tester', 900.00);

update employees
set salary = salary + 200.00, position = 'senior developer'
where name = 'an';

delete from employees
where name = 'binh';

select employee_id, operation, old_data, new_data, change_time
from employees_log
order by change_time, employee_id;
