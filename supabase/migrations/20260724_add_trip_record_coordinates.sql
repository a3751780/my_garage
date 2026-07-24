alter table public.trip_records
  add column if not exists location_latitude double precision,
  add column if not exists location_longitude double precision;

alter table public.trip_records
  drop constraint if exists trip_records_location_latitude_range,
  add constraint trip_records_location_latitude_range
    check (
      location_latitude is null
      or location_latitude between -90 and 90
    );

alter table public.trip_records
  drop constraint if exists trip_records_location_longitude_range,
  add constraint trip_records_location_longitude_range
    check (
      location_longitude is null
      or location_longitude between -180 and 180
    );
