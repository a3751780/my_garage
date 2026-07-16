alter table public.maintenance_records
add column if not exists maintenance_type text not null default 'general'
check (maintenance_type in ('general', 'oil_change'));

update public.maintenance_records
set maintenance_type = 'oil_change'
where maintenance_type = 'general'
  and item like '%機油%';

comment on column public.maintenance_records.maintenance_type
is 'Maintenance record type. general = 一般保養, oil_change = 機油更換.';
