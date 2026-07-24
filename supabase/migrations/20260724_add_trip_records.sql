create table if not exists public.trip_records (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  vehicle_id uuid not null references public.vehicles(id) on delete cascade,
  title text not null,
  content text,
  trip_date date not null,
  odometer integer check (odometer is null or odometer >= 0),
  location text,
  cost numeric(12, 2) not null default 0 check (cost >= 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists trip_records_user_id_trip_date_idx
  on public.trip_records (user_id, trip_date desc);

create index if not exists trip_records_vehicle_id_trip_date_idx
  on public.trip_records (vehicle_id, trip_date desc);

alter table public.trip_records enable row level security;

create policy "Users can view their own trip records"
  on public.trip_records
  for select
  using (auth.uid() = user_id);

create policy "Users can create their own trip records"
  on public.trip_records
  for insert
  with check (
    auth.uid() = user_id
    and exists (
      select 1
      from public.vehicles
      where vehicles.id = trip_records.vehicle_id
        and vehicles.user_id = auth.uid()
    )
  );

create policy "Users can update their own trip records"
  on public.trip_records
  for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "Users can delete their own trip records"
  on public.trip_records
  for delete
  using (auth.uid() = user_id);

drop trigger if exists set_trip_records_updated_at on public.trip_records;
create trigger set_trip_records_updated_at
before update on public.trip_records
for each row
execute function public.set_updated_at();

create table if not exists public.trip_record_images (
  id uuid primary key default gen_random_uuid(),
  trip_record_id uuid not null references public.trip_records(id) on delete cascade,
  image_path text not null,
  sort_order integer not null default 0 check (sort_order >= 0),
  created_at timestamptz not null default now()
);

create index if not exists trip_record_images_trip_record_id_sort_order_idx
  on public.trip_record_images (trip_record_id, sort_order);

alter table public.trip_record_images enable row level security;

create policy "Users can view their own trip record images"
  on public.trip_record_images
  for select
  using (
    exists (
      select 1
      from public.trip_records
      where trip_records.id = trip_record_images.trip_record_id
        and trip_records.user_id = auth.uid()
    )
  );

create policy "Users can create their own trip record images"
  on public.trip_record_images
  for insert
  with check (
    exists (
      select 1
      from public.trip_records
      where trip_records.id = trip_record_images.trip_record_id
        and trip_records.user_id = auth.uid()
    )
  );

create policy "Users can delete their own trip record images"
  on public.trip_record_images
  for delete
  using (
    exists (
      select 1
      from public.trip_records
      where trip_records.id = trip_record_images.trip_record_id
        and trip_records.user_id = auth.uid()
    )
  );

insert into storage.buckets (id, name, public)
values ('trip-record-images', 'trip-record-images', true)
on conflict (id) do nothing;

create policy "Users can upload trip record images"
  on storage.objects
  for insert
  with check (
    bucket_id = 'trip-record-images'
    and auth.uid()::text = (storage.foldername(name))[1]
  );

create policy "Users can update their trip record images"
  on storage.objects
  for update
  using (
    bucket_id = 'trip-record-images'
    and auth.uid()::text = (storage.foldername(name))[1]
  )
  with check (
    bucket_id = 'trip-record-images'
    and auth.uid()::text = (storage.foldername(name))[1]
  );

create policy "Users can delete their trip record images"
  on storage.objects
  for delete
  using (
    bucket_id = 'trip-record-images'
    and auth.uid()::text = (storage.foldername(name))[1]
  );
