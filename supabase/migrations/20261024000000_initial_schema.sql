create table public.profiles (
  id text primary key,
  full_name text not null,
  email text not null unique,
  phone text not null default '',
  role text not null default 'resident'
    check (role in ('resident', 'rider', 'admin')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.pickup_requests (
  id text primary key,
  waste_type text not null
    check (waste_type in ('household', 'tradingCenter', 'unknown')),
  description text not null,
  submitted_at timestamptz not null,
  status text not null default 'requested'
    check (
      status in (
        'requested',
        'collected',
        'awaitingVerification',
        'paid',
        'cancelled'
      )
    ),
  sack_count integer not null default 1 check (sack_count > 0),
  price_ugx integer not null default 1500 check (price_ugx >= 0),
  is_instant boolean not null default true,
  zone text not null default 'north'
    check (zone in ('north', 'south', 'east', 'west')),
  address text not null default 'Arua Central',
  latitude double precision check (latitude between -90 and 90),
  longitude double precision check (longitude between -180 and 180),
  resident_name text not null,
  resident_phone text not null,
  resident_id text not null references public.profiles (id) on delete cascade,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index pickup_requests_resident_submitted_idx
  on public.pickup_requests (resident_id, submitted_at desc);
create index pickup_requests_status_zone_submitted_idx
  on public.pickup_requests (status, zone, submitted_at desc);

create or replace function public.set_updated_at()
returns trigger
language plpgsql
set search_path = public, pg_temp
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger profiles_set_updated_at
before update on public.profiles
for each row execute function public.set_updated_at();

create trigger pickup_requests_set_updated_at
before update on public.pickup_requests
for each row execute function public.set_updated_at();

alter table public.profiles enable row level security;
alter table public.pickup_requests enable row level security;

-- Firebase owns identity and authorization; only a trusted sync service writes
-- the secondary reporting copy using its server-side service-role credential.
revoke all on public.profiles from anon, authenticated;
revoke all on public.pickup_requests from anon, authenticated;
grant all on public.profiles to service_role;
grant all on public.pickup_requests to service_role;
