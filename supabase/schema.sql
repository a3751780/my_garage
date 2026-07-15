-- My Garage initial schema.
-- Run this in the Supabase SQL editor after enabling Auth.

create extension if not exists pgcrypto;

create table if not exists public.vehicles (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  model text not null,
  year integer not null check (year between 1900 and extract(year from now())::integer + 1),
  initial_mileage integer not null default 0 check (initial_mileage >= 0),
  current_mileage integer not null default 0 check (current_mileage >= 0),
  constraint vehicles_current_mileage_gte_initial_mileage
    check (current_mileage >= initial_mileage),
  acquisition_cost numeric(12, 2) not null default 0 check (acquisition_cost >= 0),
  cover_image_path text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists vehicles_user_id_created_at_idx
  on public.vehicles (user_id, created_at desc);

alter table public.vehicles enable row level security;

create policy "Users can view their own vehicles"
  on public.vehicles
  for select
  using (auth.uid() = user_id);

create policy "Users can create their own vehicles"
  on public.vehicles
  for insert
  with check (auth.uid() = user_id);

create policy "Users can update their own vehicles"
  on public.vehicles
  for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "Users can delete their own vehicles"
  on public.vehicles
  for delete
  using (auth.uid() = user_id);

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists set_vehicles_updated_at on public.vehicles;
create trigger set_vehicles_updated_at
before update on public.vehicles
for each row
execute function public.set_updated_at();

insert into storage.buckets (id, name, public)
values ('vehicle-covers', 'vehicle-covers', true)
on conflict (id) do nothing;

create policy "Users can upload vehicle covers"
  on storage.objects
  for insert
  with check (
    bucket_id = 'vehicle-covers'
    and auth.uid()::text = (storage.foldername(name))[1]
  );

create policy "Users can update their vehicle covers"
  on storage.objects
  for update
  using (
    bucket_id = 'vehicle-covers'
    and auth.uid()::text = (storage.foldername(name))[1]
  )
  with check (
    bucket_id = 'vehicle-covers'
    and auth.uid()::text = (storage.foldername(name))[1]
  );

create policy "Users can delete their vehicle covers"
  on storage.objects
  for delete
  using (
    bucket_id = 'vehicle-covers'
    and auth.uid()::text = (storage.foldername(name))[1]
  );

create table if not exists public.fuel_records (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  vehicle_id uuid not null references public.vehicles(id) on delete cascade,
  fueled_at date not null,
  odometer integer not null check (odometer >= 0),
  fuel_volume numeric(8, 3) not null check (fuel_volume > 0),
  amount numeric(12, 2) not null check (amount >= 0),
  fuel_type text not null,
  note text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists fuel_records_vehicle_id_fueled_at_idx
  on public.fuel_records (vehicle_id, fueled_at desc);

alter table public.fuel_records enable row level security;

create policy "Users can view their own fuel records"
  on public.fuel_records
  for select
  using (auth.uid() = user_id);

create policy "Users can create their own fuel records"
  on public.fuel_records
  for insert
  with check (
    auth.uid() = user_id
    and exists (
      select 1
      from public.vehicles
      where vehicles.id = fuel_records.vehicle_id
        and vehicles.user_id = auth.uid()
    )
  );

create policy "Users can update their own fuel records"
  on public.fuel_records
  for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "Users can delete their own fuel records"
  on public.fuel_records
  for delete
  using (auth.uid() = user_id);

drop trigger if exists set_fuel_records_updated_at on public.fuel_records;
create trigger set_fuel_records_updated_at
before update on public.fuel_records
for each row
execute function public.set_updated_at();

create table if not exists public.maintenance_records (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  vehicle_id uuid not null references public.vehicles(id) on delete cascade,
  item text not null,
  serviced_at date not null,
  odometer integer not null check (odometer >= 0),
  amount numeric(12, 2) not null default 0 check (amount >= 0),
  note text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists maintenance_records_vehicle_id_serviced_at_idx
  on public.maintenance_records (vehicle_id, serviced_at desc);

alter table public.maintenance_records enable row level security;

create policy "Users can view their own maintenance records"
  on public.maintenance_records
  for select
  using (auth.uid() = user_id);

create policy "Users can create their own maintenance records"
  on public.maintenance_records
  for insert
  with check (
    auth.uid() = user_id
    and exists (
      select 1
      from public.vehicles
      where vehicles.id = maintenance_records.vehicle_id
        and vehicles.user_id = auth.uid()
    )
  );

create policy "Users can update their own maintenance records"
  on public.maintenance_records
  for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "Users can delete their own maintenance records"
  on public.maintenance_records
  for delete
  using (auth.uid() = user_id);

drop trigger if exists set_maintenance_records_updated_at
  on public.maintenance_records;
create trigger set_maintenance_records_updated_at
before update on public.maintenance_records
for each row
execute function public.set_updated_at();
