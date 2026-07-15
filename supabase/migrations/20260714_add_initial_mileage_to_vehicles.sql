alter table public.vehicles
add column if not exists initial_mileage integer not null default 0
check (initial_mileage >= 0);

update public.vehicles
set initial_mileage = least(initial_mileage, current_mileage)
where initial_mileage > current_mileage;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'vehicles_current_mileage_gte_initial_mileage'
  ) then
    alter table public.vehicles
    add constraint vehicles_current_mileage_gte_initial_mileage
    check (current_mileage >= initial_mileage);
  end if;
end;
$$;
