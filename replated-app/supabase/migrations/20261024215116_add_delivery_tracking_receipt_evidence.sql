-- Active delivery tracking, receipt evidence, and donor-visible decline feedback.
alter table public.food_listings add column if not exists ngo_received_photo text;
alter table public.food_listing_declines add column if not exists recipient_name text;

drop policy if exists "recipient completes inspection" on public.food_listings;
create policy "recipient completes inspection" on public.food_listings
  for update to authenticated using (
    public.has_replated_role('recipient') and recipient_id = (select auth.uid()) and status = 'Awaiting NGO inspection'
  ) with check (
    recipient_id = (select auth.uid()) and status in ('Delivered','Rejected')
    and (status <> 'Delivered' or ngo_received_photo is not null)
    and (status <> 'Rejected' or length(trim(coalesce(reject_reason,''))) >= 3)
  );
grant update (ngo_received_photo) on public.food_listings to authenticated;

create table if not exists public.food_listing_locations (
  listing_id text primary key references public.food_listings(id) on delete cascade,
  rider_id uuid not null references public.profiles(id),
  latitude double precision not null check (latitude between -90 and 90),
  longitude double precision not null check (longitude between -180 and 180),
  updated_at timestamptz not null default now()
);
alter table public.food_listing_locations enable row level security;
revoke all on public.food_listing_locations from anon, authenticated;
grant select, insert, update on public.food_listing_locations to authenticated;
create policy "participants view active delivery locations" on public.food_listing_locations
  for select to authenticated using (exists (
    select 1 from public.food_listings l where l.id = listing_id
      and (l.donor_id = (select auth.uid()) or l.recipient_id = (select auth.uid()) or l.rider_id = (select auth.uid()))
  ));
create policy "assigned riders share active delivery location" on public.food_listing_locations
  for insert to authenticated with check (
    rider_id = (select auth.uid()) and public.has_replated_role('rider') and exists (
      select 1 from public.food_listings l where l.id = listing_id and l.rider_id = (select auth.uid())
        and l.status in ('Picked up','In transit','Almost complete')
    )
  );
create policy "assigned riders update active delivery location" on public.food_listing_locations
  for update to authenticated using (
    rider_id = (select auth.uid()) and exists (
      select 1 from public.food_listings l where l.id = listing_id and l.rider_id = (select auth.uid())
        and l.status in ('Picked up','In transit','Almost complete')
    )
  ) with check (rider_id = (select auth.uid()));

-- Only the assigned recipient may upload the fresh arrival photo into their own evidence folder.
drop policy if exists "participants upload listing evidence" on storage.objects;
create policy "participants upload listing evidence" on storage.objects
  for insert to authenticated with check (
    bucket_id = 'food-evidence' and split_part(name,'/',1) = (select auth.uid())::text
    and exists (
      select 1 from public.food_listings l where l.id = split_part(name,'/',2)
       and (l.donor_id = (select auth.uid()) or l.rider_id = (select auth.uid())
         or (l.recipient_id = (select auth.uid()) and l.status = 'Awaiting NGO inspection'))
    )
  );

do $$
begin
  if not exists (select 1 from pg_publication_tables where pubname='supabase_realtime' and schemaname='public' and tablename='food_listing_locations') then
    alter publication supabase_realtime add table public.food_listing_locations;
  end if;
end;
$$;
create policy "recipient attaches arrival evidence" on public.food_listings
  for update to authenticated using (
    public.has_replated_role('recipient') and recipient_id = (select auth.uid()) and status = 'Awaiting NGO inspection'
      and ngo_received_photo is null
  ) with check (
    recipient_id = (select auth.uid()) and status = 'Awaiting NGO inspection' and ngo_received_photo is not null
  );
create or replace function public.stamp_decline_recipient_name()
returns trigger language plpgsql security definer set search_path = ''
as $$
begin
  select p.display_name into new.recipient_name from public.profiles p where p.id = new.recipient_id;
  return new;
end;
$$;
drop trigger if exists stamp_decline_recipient_name on public.food_listing_declines;
create trigger stamp_decline_recipient_name before insert on public.food_listing_declines
for each row execute procedure public.stamp_decline_recipient_name();
