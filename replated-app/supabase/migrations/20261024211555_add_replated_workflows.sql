-- RePlated role workflows: offer declines/rematches, rider evidence, NGO inspection and audits.
alter table public.profiles add column if not exists phone text;
alter table public.profiles add column if not exists organization text;
alter table public.profiles add column if not exists address text;

update public.profiles p set
  phone = coalesce(p.phone, u.raw_user_meta_data->>'phone'),
  organization = coalesce(p.organization, u.raw_user_meta_data->>'organization'),
  address = coalesce(p.address, u.raw_user_meta_data->>'address'),
  display_name = coalesce(nullif(p.display_name, 'Member'), u.raw_user_meta_data->>'display_name', p.display_name)
from auth.users u where u.id = p.id;

create or replace function public.create_replated_profile()
returns trigger language plpgsql security definer set search_path = ''
as $$
begin
  insert into public.profiles (id, display_name, role, phone, organization, address)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'display_name','Member'),
    'donor',
    new.raw_user_meta_data->>'phone',
    new.raw_user_meta_data->>'organization',
    new.raw_user_meta_data->>'address'
  ) on conflict (id) do nothing;
  return new;
end;
$$;

alter table public.food_listings add column if not exists donor_phone text;
alter table public.food_listings add column if not exists donor_photo text;
alter table public.food_listings add column if not exists pickup_photo text;
alter table public.food_listings add column if not exists dropoff_photo text;
alter table public.food_listings add column if not exists reject_reason text;

alter table public.food_listings drop constraint if exists food_listings_status_check;
alter table public.food_listings add constraint food_listings_status_check check (status in (
  'Safety review','Ready to match','Awaiting NGO','Recipient confirmed','NGO declined',
  'Rider needed','Rider assigned','Picked up','In transit','Almost complete',
  'Awaiting NGO inspection','Delivered','Rejected'
));
alter table public.food_listings drop constraint if exists food_listings_id_format_check;
create or replace function public.validate_replated_batch_code()
returns trigger language plpgsql set search_path = ''
as $$ begin
  if new.id !~ '^[A-Z]{2}[0-9]{3}[A-Z]$' then
    raise exception 'Batch code must have two letters, three digits and one letter';
  end if;
  return new;
end; $$;
drop trigger if exists validate_replated_batch_code on public.food_listings;
create trigger validate_replated_batch_code before insert on public.food_listings
for each row execute procedure public.validate_replated_batch_code();

create table if not exists public.food_listing_declines (
  id bigint generated always as identity primary key,
  listing_id text not null references public.food_listings(id) on delete cascade,
  donor_id uuid not null references public.profiles(id),
  recipient_id uuid not null references public.profiles(id),
  reason text not null check (length(trim(reason)) between 3 and 500),
  created_at timestamptz not null default now(),
  unique (listing_id, recipient_id)
);

create table if not exists public.food_reviews (
  id bigint generated always as identity primary key,
  listing_id text not null references public.food_listings(id) on delete cascade,
  recipient_id uuid not null references public.profiles(id),
  freshness smallint not null check (freshness between 1 and 5),
  quality smallint not null check (quality between 1 and 5),
  packaging smallint not null check (packaging between 1 and 5),
  health_issue text not null default '',
  note text not null default '',
  created_at timestamptz not null default now(),
  unique (listing_id, recipient_id)
);

create table if not exists public.complaints (
  id bigint generated always as identity primary key,
  listing_id text references public.food_listings(id) on delete set null,
  reporter_id uuid not null references public.profiles(id),
  details text not null check (length(trim(details)) between 5 and 3000),
  created_at timestamptz not null default now()
);

alter table public.food_listing_declines enable row level security;
alter table public.food_reviews enable row level security;
alter table public.complaints enable row level security;

drop policy if exists "read own or dispatchable profiles" on public.profiles;
create policy "read own and related profiles" on public.profiles
  for select to authenticated using (
    id = (select auth.uid()) or exists (
      select 1 from public.food_listings l
      where (l.donor_id = (select auth.uid()) or l.recipient_id = (select auth.uid()) or l.rider_id = (select auth.uid()))
        and profiles.id in (l.donor_id, l.recipient_id, l.rider_id)
    )
  );

drop policy if exists "signed in users read listings" on public.food_listings;
create policy "participants and eligible recipients read listings" on public.food_listings
  for select to authenticated using (
    public.has_replated_role('dispatcher') or donor_id = (select auth.uid())
    or recipient_id = (select auth.uid()) or rider_id = (select auth.uid())
    or (public.has_replated_role('recipient') and status = 'Awaiting NGO' and donor_photo is not null
      and not exists (select 1 from public.food_listing_declines d where d.listing_id = food_listings.id and d.recipient_id = (select auth.uid())))
    or (public.has_replated_role('rider') and status = 'Rider needed')
  );

drop policy if exists "donors submit listings" on public.food_listings;
create policy "donors submit listings" on public.food_listings
  for insert to authenticated with check (
    donor_id = (select auth.uid()) and public.has_replated_role('donor')
    and status = 'Awaiting NGO' and recipient_id is null and rider_id is null
  );

revoke update on public.food_listings from authenticated;
grant update (status, recipient_id, rider_id, donor_photo, pickup_photo, dropoff_photo, reject_reason) on public.food_listings to authenticated;
drop policy if exists "dispatchers coordinate listings" on public.food_listings;
create policy "dispatchers coordinate listings" on public.food_listings
  for update to authenticated using (public.has_replated_role('dispatcher'))
  with check (public.has_replated_role('dispatcher'));

drop policy if exists "recipient confirms assigned offer" on public.food_listings;
create policy "recipient accepts available offer" on public.food_listings
  for update to authenticated using (
    public.has_replated_role('recipient') and status = 'Awaiting NGO' and recipient_id is null
  ) with check (
    public.has_replated_role('recipient') and recipient_id = (select auth.uid()) and status = 'Rider needed'
  );
create policy "recipient completes inspection" on public.food_listings
  for update to authenticated using (
    public.has_replated_role('recipient') and recipient_id = (select auth.uid()) and status = 'Awaiting NGO inspection'
  ) with check (
    recipient_id = (select auth.uid()) and status in ('Delivered','Rejected')
    and (status <> 'Rejected' or length(trim(coalesce(reject_reason,''))) >= 3)
  );

drop policy if exists "assigned rider records route" on public.food_listings;
create policy "riders claim available pickups" on public.food_listings
  for update to authenticated using (
    public.has_replated_role('rider') and status = 'Rider needed' and rider_id is null
  ) with check (
    public.has_replated_role('rider') and rider_id = (select auth.uid()) and status = 'Rider assigned'
  );
create policy "assigned rider records route and evidence" on public.food_listings
  for update to authenticated using (
    public.has_replated_role('rider') and rider_id = (select auth.uid())
      and status in ('Rider assigned','Picked up','In transit','Almost complete')
  ) with check (
    rider_id = (select auth.uid()) and status in ('Rider assigned','Picked up','In transit','Almost complete','Awaiting NGO inspection')
    and (status <> 'Picked up' or pickup_photo is not null)
    and (status <> 'Awaiting NGO inspection' or (pickup_photo is not null and dropoff_photo is not null))
  );
create policy "donors attach required listing photo" on public.food_listings
  for update to authenticated using (
    public.has_replated_role('donor') and donor_id = (select auth.uid())
      and status = 'Awaiting NGO' and donor_photo is null
  ) with check (
    donor_id = (select auth.uid()) and status = 'Awaiting NGO' and donor_photo is not null
  );

create policy "recipients record declined offers" on public.food_listing_declines
  for insert to authenticated with check (
    recipient_id = (select auth.uid()) and public.has_replated_role('recipient')
    and exists (select 1 from public.food_listings l where l.id = listing_id and l.status = 'Awaiting NGO' and l.donor_id = food_listing_declines.donor_id)
  );
create policy "participants read declined offers" on public.food_listing_declines
  for select to authenticated using (
    recipient_id = (select auth.uid()) or donor_id = (select auth.uid()) or public.has_replated_role('dispatcher')
  );

create policy "recipient records post delivery review" on public.food_reviews
  for insert to authenticated with check (
    recipient_id = (select auth.uid()) and public.has_replated_role('recipient')
    and exists (select 1 from public.food_listings l where l.id = listing_id and l.recipient_id = (select auth.uid()) and l.status = 'Delivered')
  );
create policy "participants read food reviews" on public.food_reviews
  for select to authenticated using (exists (
    select 1 from public.food_listings l where l.id = listing_id
      and (l.donor_id = (select auth.uid()) or l.recipient_id = (select auth.uid()) or l.rider_id = (select auth.uid()))
  ));

create policy "members file own complaints" on public.complaints
  for insert to authenticated with check (
    reporter_id = (select auth.uid()) and (listing_id is null or exists (
      select 1 from public.food_listings l where l.id = listing_id
       and (l.donor_id = (select auth.uid()) or l.recipient_id = (select auth.uid()) or l.rider_id = (select auth.uid()))
    ))
  );
create policy "members and dispatchers read complaints" on public.complaints
  for select to authenticated using (reporter_id = (select auth.uid()) or public.has_replated_role('dispatcher'));

revoke all on public.food_listing_declines, public.food_reviews, public.complaints from anon, authenticated;
grant select, insert on public.food_listing_declines to authenticated;
revoke update (status, recipient_id, rider_id) on public.food_listings from authenticated;
grant update (status, recipient_id, rider_id, donor_photo, pickup_photo, dropoff_photo, reject_reason) on public.food_listings to authenticated;
grant usage, select on sequence public.food_listing_declines_id_seq to authenticated;
grant select, insert on public.food_reviews to authenticated;
grant usage, select on sequence public.food_reviews_id_seq to authenticated;
grant select, insert on public.complaints to authenticated;
grant usage, select on sequence public.complaints_id_seq to authenticated;

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('food-evidence','food-evidence',false,10485760,array['image/jpeg','image/png'])
on conflict (id) do nothing;
create policy "participants upload listing evidence" on storage.objects
  for insert to authenticated with check (
    bucket_id = 'food-evidence' and split_part(name,'/',1) = (select auth.uid())::text
    and exists (
      select 1 from public.food_listings l where l.id = split_part(name,'/',2)
       and (l.donor_id = (select auth.uid()) or l.rider_id = (select auth.uid()))
    )
  );
create policy "participants view listing evidence" on storage.objects
  for select to authenticated using (
    bucket_id = 'food-evidence' and exists (
      select 1 from public.food_listings l where l.id = split_part(name,'/',2)
       and (l.donor_id = (select auth.uid()) or l.recipient_id = (select auth.uid()) or l.rider_id = (select auth.uid()))
    )
  );

do $$
begin
  if not exists (select 1 from pg_publication_tables where pubname='supabase_realtime' and schemaname='public' and tablename='food_listing_declines') then
    alter publication supabase_realtime add table public.food_listing_declines;
  end if;
  if not exists (select 1 from pg_publication_tables where pubname='supabase_realtime' and schemaname='public' and tablename='food_reviews') then
    alter publication supabase_realtime add table public.food_reviews;
  end if;
end;
$$;

-- Apply to fresh/demo flow inserts and existing clients that use the updated UI.
drop policy if exists "audit read signed in" on public.food_listing_events;
create policy "audit read signed in" on public.food_listing_events
  for select to authenticated using (exists (
    select 1 from public.food_listings l where l.id = listing_id
      and (l.donor_id = (select auth.uid()) or l.recipient_id = (select auth.uid()) or l.rider_id = (select auth.uid()) or public.has_replated_role('dispatcher'))
  ));
