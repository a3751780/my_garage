alter table public.maintenance_records
add column if not exists service_type text not null default 'shop'
check (service_type in ('shop', 'diy'));

comment on column public.maintenance_records.service_type
is 'Maintenance service type. shop = 店家施工, diy = 自己 DIY.';
