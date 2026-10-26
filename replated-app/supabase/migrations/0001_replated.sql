-- RePlated schema. Run once in Supabase SQL Editor.
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null default 'Member',
  role text not null default 'donor'
    check (role in ('donor','dispatcher','recipient','rider')),
  created_at timestamptz not null default now()
);

create or replace function public.create_replated_profile()
returns trigger language plpgsql security definer set search_path = ''
as $$
begin
  insert into public.profiles (id, display_name, role)
  values (new.id, coalesce(new.raw_user_meta_data->>'display_name','Member'), 'donor');
  return new;
end;
$$;

drop trigger if exists on_auth_user_created_replated on auth.users;
create trigger on_auth_user_created_replated
  after insert on auth.users
  for each row execute procedure public.create_replated_profile();

create or replace function public.has_replated_role(required_role text)
returns boolean language sql stable security definer set search_path = ''
as $$
  select exists (
    select 1 from public.profiles p
    where p.id = (select auth.uid()) and p.role = required_role
  );
$$;

create table if not exists public.food_listings (
  id text primary key,
  donor_id uuid not null references public.profiles(id),
  donor_name text not null,
  food text not null check (length(food) between 2 and 120),
  portions integer not null check (portions between 1 and 5000),
  food_type text not null,
  allergens text not null,
  prepared_at text not null,
  pickup_deadline text not null,
  temperature_c numeric not null check (temperature_c between 0 and 100),
  unserved boolean not null check (unserved),
  packaging_confirmed boolean not null check (packaging_confirmed),
  pickup_address text not null,
  recipient_id uuid references public.profiles(id),
  rider_id uuid references public.profiles(id),
  status text not null default 'Safety review'
    check (status in ('Safety review','Ready to match','Awaiting NGO','Recipient confirmed',
      'NGO declined','Rider assigned','Picked up','In transit','Delivered','Rejected')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.food_listing_events (
  id bigint generated always as identity primary key,
  listing_id text not null references public.food_listings(id) on delete cascade,
  actor_id uuid references public.profiles(id),
  summary text not null,
  created_at timestamptz not null default now()
);

create or replace function public.audit_replated_listing()
returns trigger language plpgsql security definer set search_path = ''
as $$
begin
  if tg_op = 'INSERT' then
    insert into public.food_listing_events(listing_id,actor_id,summary)
    values(new.id,new.donor_id,'Listing submitted for operator review');
  elsif old.status is distinct from new.status then
    insert into public.food_listing_events(listing_id,actor_id,summary)
    values(new.id,(select auth.uid()),'Status changed to '||new.status);
  end if;
  return new;
end;
$$;

drop trigger if exists audit_food_listing on public.food_listings;
create trigger audit_food_listing after insert or update on public.food_listings
  for each row execute procedure public.audit_replated_listing();

create or replace function public.touch_replated_listing()
returns trigger language plpgsql set search_path = ''
as $$ begin new.updated_at = now(); return new; end; $$;
drop trigger if exists touch_food_listing on public.food_listings;
create trigger touch_food_listing before update on public.food_listings
  for each row execute procedure public.touch_replated_listing();

alter table public.profiles enable row level security;
alter table public.food_listings enable row level security;
alter table public.food_listing_events enable row level security;

revoke all on public.profiles from anon, authenticated;
grant select on public.profiles to authenticated;
create policy "read own or dispatchable profiles" on public.profiles
  for select to authenticated using (
    id = (select auth.uid()) or role in ('recipient','rider')
  );

revoke all on public.food_listings from anon, authenticated;
grant select, insert on public.food_listings to authenticated;
grant update (status, recipient_id, rider_id) on public.food_listings to authenticated;
create policy "signed in users read listings" on public.food_listings
  for select to authenticated using (
    public.has_replated_role('dispatcher') or donor_id = (select auth.uid())
    or recipient_id = (select auth.uid()) or rider_id = (select auth.uid())
  );
create policy "donors submit listings" on public.food_listings
  for insert to authenticated with check (
    donor_id = (select auth.uid()) and public.has_replated_role('donor')
    and status = 'Safety review' and recipient_id is null and rider_id is null
  );
create policy "dispatchers coordinate listings" on public.food_listings
  for update to authenticated using (public.has_replated_role('dispatcher'))
  with check (public.has_replated_role('dispatcher'));
create policy "recipient confirms assigned offer" on public.food_listings
  for update to authenticated using (
    recipient_id = (select auth.uid()) and status = 'Awaiting NGO'
    and public.has_replated_role('recipient')
  )
  with check (recipient_id = (select auth.uid()) and status in ('Recipient confirmed','NGO declined'));
create policy "assigned rider records route" on public.food_listings
  for update to authenticated using (
    rider_id = (select auth.uid()) and status in ('Rider assigned','Picked up','In transit')
    and public.has_replated_role('rider')
  )
  with check (rider_id = (select auth.uid()) and status in ('Picked up','In transit','Delivered'));

revoke all on public.food_listing_events from anon, authenticated;
grant select on public.food_listing_events to authenticated;
grant usage, select on sequence public.food_listing_events_id_seq to authenticated;
create policy "signed in users read audit events" on public.food_listing_events
  for select to authenticated using (
    exists (select 1 from public.food_listings l where l.id = listing_id)
  );

do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'food_listings'
  ) then
    alter publication supabase_realtime add table public.food_listings;
  end if;
end;
$$;

-- After registering team accounts, promote their profile roles in the SQL editor:
-- update public.profiles p set role='dispatcher'
-- from auth.users u where p.id=u.id and u.email='operator@example.com';
-- Set recipient and rider accounts the same way with role='recipient' / 'rider'.
