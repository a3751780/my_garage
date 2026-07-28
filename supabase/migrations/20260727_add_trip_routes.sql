create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create table if not exists public.trip_routes (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  name text not null,
  description text,
  travel_mode text not null default 'two-wheeler'
    check (travel_mode in ('two-wheeler', 'driving')),
  distance_meters integer check (
    distance_meters is null
    or distance_meters >= 0
  ),
  duration_seconds integer check (
    duration_seconds is null
    or duration_seconds >= 0
  ),
  encoded_polyline text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists trip_routes_user_id_created_at_idx
  on public.trip_routes (user_id, created_at desc);

alter table public.trip_routes enable row level security;

drop policy if exists "Users can view their own trip routes"
  on public.trip_routes;
create policy "Users can view their own trip routes"
  on public.trip_routes
  for select
  using (auth.uid() = user_id);

drop policy if exists "Users can create their own trip routes"
  on public.trip_routes;
create policy "Users can create their own trip routes"
  on public.trip_routes
  for insert
  with check (auth.uid() = user_id);

drop policy if exists "Users can update their own trip routes"
  on public.trip_routes;
create policy "Users can update their own trip routes"
  on public.trip_routes
  for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists "Users can delete their own trip routes"
  on public.trip_routes;
create policy "Users can delete their own trip routes"
  on public.trip_routes
  for delete
  using (auth.uid() = user_id);

drop trigger if exists set_trip_routes_updated_at on public.trip_routes;
create trigger set_trip_routes_updated_at
before update on public.trip_routes
for each row
execute function public.set_updated_at();

create table if not exists public.trip_route_stops (
  id uuid primary key default gen_random_uuid(),
  route_id uuid not null references public.trip_routes(id) on delete cascade,
  stop_order integer not null check (stop_order >= 0),
  name text not null,
  place_id text,
  address text,
  latitude double precision not null,
  longitude double precision not null,
  is_origin boolean not null default false,
  is_destination boolean not null default false,
  created_at timestamptz not null default now(),
  constraint trip_route_stops_latitude_range
    check (latitude between -90 and 90),
  constraint trip_route_stops_longitude_range
    check (longitude between -180 and 180)
);

create index if not exists trip_route_stops_route_id_stop_order_idx
  on public.trip_route_stops (route_id, stop_order);

alter table public.trip_route_stops enable row level security;

drop policy if exists "Users can view their own trip route stops"
  on public.trip_route_stops;
create policy "Users can view their own trip route stops"
  on public.trip_route_stops
  for select
  using (
    exists (
      select 1
      from public.trip_routes
      where trip_routes.id = trip_route_stops.route_id
        and trip_routes.user_id = auth.uid()
    )
  );

drop policy if exists "Users can create their own trip route stops"
  on public.trip_route_stops;
create policy "Users can create their own trip route stops"
  on public.trip_route_stops
  for insert
  with check (
    exists (
      select 1
      from public.trip_routes
      where trip_routes.id = trip_route_stops.route_id
        and trip_routes.user_id = auth.uid()
    )
  );

drop policy if exists "Users can update their own trip route stops"
  on public.trip_route_stops;
create policy "Users can update their own trip route stops"
  on public.trip_route_stops
  for update
  using (
    exists (
      select 1
      from public.trip_routes
      where trip_routes.id = trip_route_stops.route_id
        and trip_routes.user_id = auth.uid()
    )
  )
  with check (
    exists (
      select 1
      from public.trip_routes
      where trip_routes.id = trip_route_stops.route_id
        and trip_routes.user_id = auth.uid()
    )
  );

drop policy if exists "Users can delete their own trip route stops"
  on public.trip_route_stops;
create policy "Users can delete their own trip route stops"
  on public.trip_route_stops
  for delete
  using (
    exists (
      select 1
      from public.trip_routes
      where trip_routes.id = trip_route_stops.route_id
        and trip_routes.user_id = auth.uid()
    )
  );
