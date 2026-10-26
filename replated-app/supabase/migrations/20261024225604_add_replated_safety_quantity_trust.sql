-- RePlated safety, NGO requests, quantity, trust and audit workflows.
-- These are configurable operating limits, not a certification of food safety.
create schema if not exists private;
revoke all on schema private from public, anon, authenticated;

create table if not exists public.replated_config (
  id boolean primary key default true check (id),
  config jsonb not null,
  updated_at timestamptz not null default now(),
  updated_by uuid references public.profiles(id)
);
alter table public.replated_config enable row level security;
revoke all on public.replated_config from anon, authenticated;
grant select, update on public.replated_config to authenticated;
create policy "members read operating config" on public.replated_config for select to authenticated using (true);
create policy "administrators edit operating config" on public.replated_config for update to authenticated
using (public.has_replated_role('dispatcher')) with check (public.has_replated_role('dispatcher'));
insert into public.replated_config(id, config) values (true, jsonb_build_object(
 'HOT_MIN_C',60,'COLD_MAX_C',5,'WINDOW_HIGH_RISK_H',2,'WINDOW_MEDIUM_RISK_H',3,'WINDOW_LOW_RISK_H',4,
 'NGO_ARRIVAL_BUFFER_MIN',15,'LOCATION_MISMATCH_M',200,'COMPLAINT_WINDOW_H',48,
 'ESTIMATE_PROMPT','16:00','PACK_DEADLINE','18:30','PICKUP_TIME','19:00','PACK_AUTO_CANCEL_AT','19:30',
 'QUANTITY_TOLERANCE_PCT',20,'BADGE_THRESHOLDS',jsonb_build_object('Bronze',100,'Silver',500,'Gold',1000),
 'CATEGORIES',jsonb_build_array(
  jsonb_build_object('id','rice','label','Rice dishes / biryani','risk','high','keywords',jsonb_build_array('rice','biryani','pulao','khichdi')),
  jsonb_build_object('id','curry','label','Curries / gravies / dal','risk','high','keywords',jsonb_build_array('curry','gravy','dal','sambar','rasam','korma')),
  jsonb_build_object('id','dairy','label','Dairy / paneer / egg','risk','high','keywords',jsonb_build_array('dairy','milk','paneer','cheese','cream','egg','omelette')),
  jsonb_build_object('id','meat','label','Meat / fish dishes','risk','high','keywords',jsonb_build_array('meat','chicken','mutton','fish','prawn','seafood')),
  jsonb_build_object('id','bread','label','Bread / rotis','risk','low','keywords',jsonb_build_array('bread','roti','chapati','naan','paratha')),
  jsonb_build_object('id','snacks','label','Dry snacks','risk','low','keywords',jsonb_build_array('dry snack','namkeen','mixture','chips','cracker')),
  jsonb_build_object('id','bakery','label','Bakery','risk','low','keywords',jsonb_build_array('biscuit','cookie','cake','muffin','pastry','bakery')),
  jsonb_build_object('id','prepared','label','Other prepared foods','risk','medium','keywords',jsonb_build_array('noodle','pasta','salad','fruit','vegetable'))
 ),
 'CHECKLISTS',jsonb_build_object(
  'donor',jsonb_build_array('Food was never served to customers or guests','No leftovers from plates','Covered in clean food-grade containers','Every box labelled with the batch code','Every box sealed with the sticker','Allergens listed'),
  'rider',jsonb_build_array('Box count matches','Seals intact','Packaging clean and undamaged','Delivery bag clean'),
  'ngo',jsonb_build_array('Seals intact','Looks fresh','Smells fine','Packaging intact','Quantity matches')
 )
)) on conflict(id) do nothing;

alter table public.profiles
 add column if not exists requested_role text not null default 'donor',
 add column if not exists approval_status text not null default 'approved',
 add column if not exists approval_note text, add column if not exists usual_quantity integer,
 add column if not exists points integer not null default 0, add column if not exists upheld_complaints integer not null default 0,
 add column if not exists badge_suspended boolean not null default false;
alter table public.profiles add constraint profiles_approval_status_check check(approval_status in('pending','approved','rejected'));
alter table public.profiles add constraint profiles_requested_role_check check(requested_role in('donor','recipient','rider','dispatcher'));
grant update(role,requested_role,approval_status,approval_note,usual_quantity,badge_suspended) on public.profiles to authenticated;
create policy "administrators approve profiles" on public.profiles for update to authenticated
using(public.has_replated_role('dispatcher')) with check(public.has_replated_role('dispatcher'));
create policy "administrators read all profiles" on public.profiles for select to authenticated using(public.has_replated_role('dispatcher'));
create or replace function public.has_replated_role(required_role text)
returns boolean language sql stable security definer set search_path=''
as $$ select exists(select 1 from public.profiles p where p.id=(select auth.uid()) and p.role=required_role and p.approval_status='approved'); $$;

create table if not exists public.food_requests (
 id uuid primary key default gen_random_uuid(), ngo_id uuid not null references public.profiles(id),
 required_qty integer not null check(required_qty between 1 and 5000), food_preferences text not null default '',
 allergy_exclusions text not null default '', foods_to_avoid text not null default '', notes text not null default '',
 pickup_address text not null, target_date date not null default current_date, target_pickup_time time not null default time '19:00',
 status text not null default 'Open' check(status in('Open','Matched','Cancelled','Complete')),
 created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create index if not exists food_requests_open_idx on public.food_requests(created_at desc) where status='Open';
alter table public.food_listings
 add column if not exists request_id uuid references public.food_requests(id), add column if not exists batch_status text not null default 'Normal',
 add column if not exists packed_at timestamptz, add column if not exists safe_until timestamptz, add column if not exists delivered_at timestamptz,
 add column if not exists estimated_qty integer, add column if not exists updated_qty integer, add column if not exists final_qty integer,
 add column if not exists accepted_qty integer, add column if not exists pack_deadline timestamptz, add column if not exists pickup_target_at timestamptz,
 add column if not exists declaration jsonb not null default '{}'::jsonb, add column if not exists donor_lat double precision,
 add column if not exists donor_lng double precision, add column if not exists arrival_temperature_c numeric,
 add column if not exists ngo_inspection_note text not null default '', add column if not exists complaint_deadline timestamptz;
alter table public.food_listings drop constraint if exists food_listings_status_check;
alter table public.food_listings add constraint food_listings_status_check check(status in(
 'Safety review','Ready to match','Awaiting donor','Packing','Packed','Awaiting NGO','Recipient confirmed','NGO declined',
 'Rider needed','Rider assigned','Picked up','In transit','Almost complete','Awaiting NGO inspection',
 'Delivered','Expired','Cancelled','Rejected','Under review'));
alter table public.food_listings add constraint food_listings_batch_status_check check(batch_status in('Normal','Under review'));

create table if not exists public.food_listing_items (
 id bigint generated always as identity primary key, listing_id text not null references public.food_listings(id) on delete cascade,
 line_no smallint not null, dish_name text not null check(length(trim(dish_name)) between 2 and 120),
 category_id text not null default 'prepared', category_label text not null default 'Other prepared foods',
 risk_level text not null default 'medium' check(risk_level in('high','medium','low')),
 allergens text not null default 'None declared', prepared_at time not null,
 temperature_c numeric not null check(temperature_c between 0 and 100),
 temperature_state text not null default 'danger-zone' check(temperature_state in('hot-held','cold-held','danger-zone')),
 estimated_qty integer check(estimated_qty between 0 and 5000), updated_qty integer check(updated_qty between 0 and 5000),
 final_qty integer check(final_qty between 0 and 5000), packed_at timestamptz, safe_until timestamptz,
 item_status text not null default 'active' check(item_status in('active','expired','withdrawn','accepted','rejected')),
 created_at timestamptz not null default now(), unique(listing_id,line_no)
);
create index if not exists food_listing_items_expiry_idx on public.food_listing_items(safe_until) where item_status='active';

create table if not exists public.food_listing_checklists (
 id bigint generated always as identity primary key, listing_id text not null references public.food_listings(id) on delete cascade,
 step text not null check(step in('donor-packed','rider-pickup','ngo-inspection')),
 actor_id uuid not null references public.profiles(id), result jsonb not null, issue_note text not null default '',
 completed_at timestamptz not null default now(), unique(listing_id,step,actor_id)
);
create table if not exists public.food_listing_captures (
 id uuid primary key default gen_random_uuid(), listing_id text not null references public.food_listings(id) on delete cascade,
 step text not null check(step in('donor-packed','donor-thermometer','rider-pickup','rider-dropoff','ngo-inspection','complaint')),
 actor_id uuid not null references public.profiles(id), storage_path text not null,
 sha256 text not null check(sha256 ~ '^[a-f0-9]{64}$'), server_time timestamptz not null default now(),
 latitude double precision, longitude double precision, expected_latitude double precision, expected_longitude double precision,
 location_flag text check(location_flag in('location_mismatch','no_location'))
);
create index if not exists food_listing_captures_hash_idx on public.food_listing_captures(sha256);
create table if not exists public.replated_flags (
 id bigint generated always as identity primary key, order_id text not null references public.food_listings(id) on delete cascade,
 flag_type text not null, flagged_at timestamptz not null default now(), status text not null default 'open' check(status in('open','reviewed')),
 note text not null default '', source_key text not null default '', reviewed_by uuid references public.profiles(id),
 reviewed_at timestamptz, unique(order_id,flag_type,source_key)
);
create index if not exists replated_flags_open_idx on public.replated_flags(flagged_at desc) where status='open';
alter table public.complaints add column if not exists category text not null default 'Other',
 add column if not exists photo_path text, add column if not exists status text not null default 'open',
 add column if not exists resolution text, add column if not exists resolved_by uuid references public.profiles(id), add column if not exists resolved_at timestamptz;
alter table public.complaints add constraint replated_complaint_category_check check(category in('Health issue','Food quality','Packaging','Other'));
alter table public.complaints add constraint replated_complaint_status_check check(status in('open','upheld','dismissed'));

create table if not exists public.profile_audit_notes (
 id bigint generated always as identity primary key, profile_id uuid not null references public.profiles(id) on delete cascade,
 auditor_id uuid not null references public.profiles(id), auditor_name text not null, licence_or_id text not null,
 result text not null check(result in('Pass','Fail')), comment text not null check(length(trim(comment)) between 2 and 1000),
 created_at timestamptz not null default now()
);
create table if not exists public.replated_notifications (
 id bigint generated always as identity primary key, user_id uuid not null references public.profiles(id) on delete cascade,
 order_id text references public.food_listings(id) on delete cascade, title text not null, body text not null,
 created_at timestamptz not null default now(), read_at timestamptz
);
create index if not exists replated_notifications_user_idx on public.replated_notifications(user_id,created_at desc);
create table if not exists public.replated_audit_notes (
 id bigint generated always as identity primary key, order_id text not null references public.food_listings(id) on delete cascade,
 admin_id uuid not null references public.profiles(id), note text not null check(length(trim(note)) between 2 and 2000), created_at timestamptz not null default now()
);

create or replace function public.classify_replated_food(p_dish text)
returns table(category_id text,category_label text,risk_level text) language plpgsql stable set search_path=''
as $$ declare cfg jsonb;c jsonb;kw text;found boolean;begin
 select config->'CATEGORIES' into cfg from public.replated_config where id=true;
 if cfg is null then return query select 'prepared','Other prepared foods','high';return;end if;
 for c in select value from jsonb_array_elements(cfg) loop if c->>'risk'='high' then
  found:=false;for kw in select jsonb_array_elements_text(c->'keywords') loop if lower(coalesce(p_dish,'')) like '%'||lower(kw)||'%' then found:=true;exit;end if;end loop;
  if found then return query select c->>'id',c->>'label',c->>'risk';return;end if;end if;end loop;
 for c in select value from jsonb_array_elements(cfg) loop if c->>'risk' in('medium','low') then
  found:=false;for kw in select jsonb_array_elements_text(c->'keywords') loop if lower(coalesce(p_dish,'')) like '%'||lower(kw)||'%' then found:=true;exit;end if;end loop;
  if found then return query select c->>'id',c->>'label',c->>'risk';return;end if;end if;end loop;
 return query select 'prepared','Other prepared foods','high';end$$;
revoke all on function public.classify_replated_food(text) from public,anon;
grant execute on function public.classify_replated_food(text) to authenticated;

create or replace function public.stamp_replated_item()
returns trigger language plpgsql security definer set search_path=''
as $$ declare c record;cfg jsonb;hot numeric;cold numeric;begin
 select * into c from public.classify_replated_food(new.dish_name);new.category_id:=c.category_id;new.category_label:=c.category_label;new.risk_level:=c.risk_level;
 select config into cfg from public.replated_config where id=true;hot:=coalesce((cfg->>'HOT_MIN_C')::numeric,60);cold:=coalesce((cfg->>'COLD_MAX_C')::numeric,5);
 new.temperature_state:=case when new.temperature_c>=hot then 'hot-held' when new.temperature_c<=cold then 'cold-held' else 'danger-zone' end;
 if new.packed_at is not null then new.safe_until:=new.packed_at+make_interval(hours=>case new.risk_level
  when 'high' then coalesce((cfg->>'WINDOW_HIGH_RISK_H')::int,2) when 'low' then coalesce((cfg->>'WINDOW_LOW_RISK_H')::int,4)
  else coalesce((cfg->>'WINDOW_MEDIUM_RISK_H')::int,3) end);end if;return new;end$$;
create trigger stamp_replated_item before insert or update of dish_name,temperature_c,packed_at on public.food_listing_items for each row execute function public.stamp_replated_item();

create or replace function public.stamp_replated_order()
returns trigger language plpgsql security definer set search_path=''
as $$ declare cfg jsonb;hot numeric;cold numeric;window_h integer;risk text;category record;packed_now boolean:=false;begin
 select config into cfg from public.replated_config where id=true;
 packed_now:=new.donor_photo is not null and new.packed_at is null and (tg_op='INSERT' or old.donor_photo is distinct from new.donor_photo or new.status='Packed');
 if packed_now then
  hot:=coalesce((cfg->>'HOT_MIN_C')::numeric,60);cold:=coalesce((cfg->>'COLD_MAX_C')::numeric,5);
  if exists(select 1 from public.food_listing_items i where i.listing_id=new.id and i.risk_level='high' and i.temperature_c>cold and i.temperature_c<hot) then
   raise exception using message='Food is in the temperature danger zone. Reheat it or leave it out of the donation.',errcode='23514';end if;
   if not exists(select 1 from public.food_listing_items where listing_id=new.id) then
    select * into category from public.classify_replated_food(new.food);risk:=coalesce(category.risk_level,'high');
    if risk='high' and new.temperature_c>cold and new.temperature_c<hot then
     raise exception using message='Food is in the temperature danger zone. Reheat it or leave it out of the donation.',errcode='23514';end if;
   end if;
  new.packed_at:=clock_timestamp();
   select min(case risk_level when 'high' then coalesce((cfg->>'WINDOW_HIGH_RISK_H')::int,2) when 'low' then coalesce((cfg->>'WINDOW_LOW_RISK_H')::int,4)
    else coalesce((cfg->>'WINDOW_MEDIUM_RISK_H')::int,3) end) into window_h from public.food_listing_items where listing_id=new.id;
   if window_h is null then window_h:=case risk when 'high' then coalesce((cfg->>'WINDOW_HIGH_RISK_H')::int,2) when 'low' then coalesce((cfg->>'WINDOW_LOW_RISK_H')::int,4) else coalesce((cfg->>'WINDOW_MEDIUM_RISK_H')::int,3) end;end if;
  new.safe_until:=new.packed_at+make_interval(hours=>window_h);new.final_qty:=coalesce(new.final_qty,new.portions);
  update public.food_listing_items set packed_at=new.packed_at where listing_id=new.id;
 end if;
 if new.status='Awaiting NGO inspection' and old.status is distinct from new.status then new.delivered_at:=clock_timestamp();end if;
 if new.status='Delivered' and old.status is distinct from new.status then new.complaint_deadline:=clock_timestamp()+make_interval(hours=>coalesce((cfg->>'COMPLAINT_WINDOW_H')::int,48));end if;
 return new;end$$;
drop trigger if exists stamp_replated_order on public.food_listings;
create trigger stamp_replated_order before insert or update of status,donor_photo on public.food_listings for each row execute function public.stamp_replated_order();
revoke all on function public.stamp_replated_order() from public,anon,authenticated;

create or replace function private.flag_replated_capture()
returns trigger language plpgsql security definer set search_path=''
as $$ declare cfg jsonb;dist double precision;begin
 if auth.uid() is not null and auth.uid() is distinct from new.actor_id then raise exception 'Capture actor must match signed-in user';end if;
 select config into cfg from public.replated_config where id=true;
 if new.latitude is null or new.longitude is null then new.location_flag:='no_location';
 elsif new.expected_latitude is not null and new.expected_longitude is not null then
  dist:=2*6371000*asin(sqrt(power(sin(radians(new.latitude-new.expected_latitude)/2),2)+cos(radians(new.expected_latitude))*cos(radians(new.latitude))*power(sin(radians(new.longitude-new.expected_longitude)/2),2)));
  if dist>coalesce((cfg->>'LOCATION_MISMATCH_M')::numeric,200) then new.location_flag:='location_mismatch';end if;end if;
 if new.location_flag is not null then insert into public.replated_flags(order_id,flag_type,source_key,note) values(new.listing_id,new.location_flag,new.id::text,'Capture saved; compare location with expected handoff.') on conflict do nothing;end if;
 if exists(select 1 from public.food_listing_captures x where x.sha256=new.sha256 and x.listing_id<>new.listing_id) then
  insert into public.replated_flags(order_id,flag_type,source_key,note) values(new.listing_id,'duplicate_photo',new.id::text,'Image hash also appears on another order.') on conflict do nothing;end if;
 return new;end$$;
revoke all on function private.flag_replated_capture() from public,anon,authenticated;
create trigger flag_replated_capture before insert on public.food_listing_captures for each row execute function private.flag_replated_capture();
create or replace function private.flag_replated_checklist() returns trigger language plpgsql security definer set search_path=''
as $$begin
 if exists(select 1 from jsonb_each(coalesce(new.result,'{}'::jsonb)) e where e.value->>'ok'='false') then
  insert into public.replated_flags(order_id,flag_type,source_key,note) values(new.listing_id,'checklist_issue',new.step||':'||new.actor_id::text,new.issue_note) on conflict do nothing;end if;return new;end$$;
revoke all on function private.flag_replated_checklist() from public,anon,authenticated;
create trigger flag_replated_checklist after insert or update on public.food_listing_checklists for each row execute function private.flag_replated_checklist();

alter table public.food_requests enable row level security;alter table public.food_listing_items enable row level security;
alter table public.food_listing_checklists enable row level security;alter table public.food_listing_captures enable row level security;
alter table public.replated_flags enable row level security;alter table public.profile_audit_notes enable row level security;
alter table public.replated_notifications enable row level security;alter table public.replated_audit_notes enable row level security;
revoke all on public.food_requests,public.food_listing_items,public.food_listing_checklists,public.food_listing_captures,public.replated_flags,public.profile_audit_notes,public.replated_notifications,public.replated_audit_notes from anon,authenticated;
grant select,insert,update on public.food_requests to authenticated;
grant select,insert,update on public.food_listing_items,public.food_listing_checklists to authenticated;
grant select,insert on public.food_listing_captures to authenticated;grant select,update on public.replated_flags to authenticated;
grant select,insert on public.profile_audit_notes,public.replated_audit_notes to authenticated;grant select,insert,update on public.replated_notifications to authenticated;
grant usage,select on all sequences in schema public to authenticated;
create policy "request parties and eligible donors read" on public.food_requests for select to authenticated
using(ngo_id=(select auth.uid()) or public.has_replated_role('dispatcher') or (status='Open' and public.has_replated_role('donor')));
create policy "NGOs create requests" on public.food_requests for insert to authenticated with check(ngo_id=(select auth.uid()) and public.has_replated_role('recipient'));
create policy "NGOs update requests" on public.food_requests for update to authenticated using(ngo_id=(select auth.uid()) and public.has_replated_role('recipient')) with check(ngo_id=(select auth.uid()));
create policy "participants read item lines" on public.food_listing_items for select to authenticated using(exists(select 1 from public.food_listings l where l.id=listing_id and
(l.donor_id=(select auth.uid()) or l.recipient_id=(select auth.uid()) or l.rider_id=(select auth.uid()) or public.has_replated_role('dispatcher') or (public.has_replated_role('recipient') and l.status in('Awaiting donor','Awaiting NGO','Packed')))));
create policy "donors edit lines before packed" on public.food_listing_items for all to authenticated
using(exists(select 1 from public.food_listings l where l.id=listing_id and l.donor_id=(select auth.uid()) and l.status in('Awaiting donor','Packing')))
with check(exists(select 1 from public.food_listings l where l.id=listing_id and l.donor_id=(select auth.uid()) and l.status in('Awaiting donor','Packing')));
create policy "participants read checklists" on public.food_listing_checklists for select to authenticated using(exists(select 1 from public.food_listings l where l.id=listing_id and (l.donor_id=(select auth.uid()) or l.recipient_id=(select auth.uid()) or l.rider_id=(select auth.uid()) or public.has_replated_role('dispatcher'))));
create policy "actors save checklists" on public.food_listing_checklists for insert to authenticated with check(actor_id=(select auth.uid()) and exists(select 1 from public.food_listings l where l.id=listing_id and ((step='donor-packed' and l.donor_id=(select auth.uid())) or (step='rider-pickup' and l.rider_id=(select auth.uid())) or (step='ngo-inspection' and l.recipient_id=(select auth.uid())))));
create policy "participants read captures" on public.food_listing_captures for select to authenticated using(exists(select 1 from public.food_listings l where l.id=listing_id and (l.donor_id=(select auth.uid()) or l.recipient_id=(select auth.uid()) or l.rider_id=(select auth.uid()) or public.has_replated_role('dispatcher'))));
create policy "participants add captures" on public.food_listing_captures for insert to authenticated with check(actor_id=(select auth.uid()) and exists(select 1 from public.food_listings l where l.id=listing_id and (l.donor_id=(select auth.uid()) or l.recipient_id=(select auth.uid()) or l.rider_id=(select auth.uid()))));
create policy "admins read flags" on public.replated_flags for select to authenticated using(public.has_replated_role('dispatcher'));
create policy "admins review flags" on public.replated_flags for update to authenticated using(public.has_replated_role('dispatcher')) with check(public.has_replated_role('dispatcher'));
create policy "participants read profile checks" on public.profile_audit_notes for select to authenticated using(profile_id=(select auth.uid()) or public.has_replated_role('dispatcher') or exists(select 1 from public.food_listings l where (l.donor_id=(select auth.uid()) or l.recipient_id=(select auth.uid())) and profile_id in(l.donor_id,l.recipient_id)));
create policy "admins create profile checks" on public.profile_audit_notes for insert to authenticated with check(auditor_id=(select auth.uid()) and public.has_replated_role('dispatcher'));
create policy "users read notifications" on public.replated_notifications for select to authenticated using(user_id=(select auth.uid()) or public.has_replated_role('dispatcher'));
create policy "users mark own notifications" on public.replated_notifications for update to authenticated using(user_id=(select auth.uid())) with check(user_id=(select auth.uid()));
create policy "participants read order audit notes" on public.replated_audit_notes for select to authenticated using(public.has_replated_role('dispatcher') or exists(select 1 from public.food_listings l where l.id=order_id and (l.donor_id=(select auth.uid()) or l.recipient_id=(select auth.uid()))));
create policy "admins create order notes" on public.replated_audit_notes for insert to authenticated with check(admin_id=(select auth.uid()) and public.has_replated_role('dispatcher'));

drop policy if exists "members file own complaints" on public.complaints;
create policy "members file own complaints" on public.complaints for insert to authenticated with check(reporter_id=(select auth.uid()) and exists(select 1 from public.food_listings l where l.id=listing_id and
((l.recipient_id=(select auth.uid()) and l.status='Delivered' and now()<=coalesce(l.complaint_deadline,l.delivered_at+interval '48 hours'))
 or l.donor_id=(select auth.uid()) or l.rider_id=(select auth.uid()))));
create policy "admins resolve complaints" on public.complaints for update to authenticated using(public.has_replated_role('dispatcher')) with check(public.has_replated_role('dispatcher') and resolved_by=(select auth.uid()));

create or replace function private.process_replated_deadlines()
returns void language plpgsql security definer set search_path=''
as $$begin
 update public.food_listing_items set item_status='expired' where item_status='active' and safe_until<=clock_timestamp();
 update public.food_listings l set status='Expired' where l.status not in('Delivered','Rejected','Cancelled','Expired') and l.safe_until<=clock_timestamp()
  and not exists(select 1 from public.food_listing_items i where i.listing_id=l.id and i.item_status='active');
 insert into public.replated_flags(order_id,flag_type,source_key,note) select id,'expired','system','All active lines passed safe_until.' from public.food_listings where status='Expired' on conflict do nothing;
 insert into public.replated_flags(order_id,flag_type,source_key,note) select id,'delivered_after_safe_until','system','Delivery occurred after safe_until.' from public.food_listings where delivered_at>safe_until on conflict do nothing;
 insert into public.replated_flags(order_id,flag_type,source_key,note) select id,'rejected_after_delivery','system','NGO rejected after rider delivery.' from public.food_listings where status='Rejected' and delivered_at is not null on conflict do nothing;
 update public.food_listings set status='Cancelled' where status in('Awaiting donor','Packing') and pack_deadline is not null and clock_timestamp()>=pack_deadline;
 insert into public.replated_flags(order_id,flag_type,source_key,note) select id,'late_packing','auto-cancel','Not packed by configured deadline; order cancelled.' from public.food_listings where status='Cancelled' and packed_at is null on conflict do nothing;
end$$;
revoke all on function private.process_replated_deadlines() from public,anon,authenticated;
-- Request approval is a review queue only; user-supplied metadata never grants a role.
create or replace function public.create_replated_profile()
returns trigger language plpgsql security definer set search_path=''
as $$ begin
 insert into public.profiles(id,display_name,role,requested_role,approval_status,phone,organization,address)
 values(new.id,coalesce(new.raw_user_meta_data->>'display_name','Member'),'donor',
  case when new.raw_user_meta_data->>'requested_role' in('recipient','rider') then new.raw_user_meta_data->>'requested_role' else 'donor' end,
  'pending',new.raw_user_meta_data->>'phone',new.raw_user_meta_data->>'organization',new.raw_user_meta_data->>'address')
 on conflict(id) do nothing;return new;end$$;

alter table public.food_listings add column if not exists ngo_accepted_at timestamptz,
 add column if not exists quantity_reconfirm_deadline timestamptz;
alter table public.food_listings drop constraint food_listings_status_check;
alter table public.food_listings add constraint food_listings_status_check check(status in(
 'Safety review','Ready to match','Awaiting donor','Packing','Packed','Awaiting NGO','Awaiting NGO quantity confirmation',
 'Recipient confirmed','NGO declined','Rider needed','Rider assigned','Picked up','In transit','Almost complete',
 'Awaiting NGO inspection','Delivered','Expired','Cancelled','Rejected','Under review'));

-- Admin-only trust profile audit entries immediately suspend a badge on failure.
create or replace function private.suspend_replated_badge_on_fail()
returns trigger language plpgsql security definer set search_path=''
as $$begin if new.result='Fail' then update public.profiles set badge_suspended=true where id=new.profile_id;end if;return new;end$$;
revoke all on function private.suspend_replated_badge_on_fail() from public,anon,authenticated;
create trigger suspend_replated_badge_on_fail after insert on public.profile_audit_notes
for each row execute function private.suspend_replated_badge_on_fail();

-- Final NGO acceptance is the single source of donor points and completion notifications.
create or replace function private.award_replated_completion()
returns trigger language plpgsql security definer set search_path=''
as $$begin
 if old.status is distinct from 'Delivered' and new.status='Delivered' then
  update public.profiles set points=points+100 where id=new.donor_id;
  insert into public.replated_notifications(user_id,order_id,title,body)
   values(new.donor_id,new.id,'Delivery completed','The NGO accepted your batch. 100 points were added to your profile.');
 end if;return new;end$$;
revoke all on function private.award_replated_completion() from public,anon,authenticated;
create trigger award_replated_completion after update of status on public.food_listings
for each row execute function private.award_replated_completion();

-- Health reports place a recall-style hold, alert the donor/admin, and warn recent recipient NGOs.
create or replace function private.notify_replated_health_report()
returns trigger language plpgsql security definer set search_path=''
as $$declare donor uuid;batch_codes text;begin
 if new.listing_id is null then return new;end if;
 select donor_id into donor from public.food_listings where id=new.listing_id;
 insert into public.replated_flags(order_id,flag_type,source_key,note)
  values(new.listing_id,case when new.category='Health issue' then 'health_complaint' else 'complaint' end,new.id::text,new.details) on conflict do nothing;
 if new.category='Health issue' then
  update public.food_listings set batch_status='Under review' where id=new.listing_id;
  insert into public.replated_notifications(user_id,order_id,title,body)
   select distinct p.id,new.listing_id,'Health concern reported','Pause service and inspect the Food Safety Passport for batch '||new.listing_id||'.'
   from public.profiles p where p.id=donor or p.role='dispatcher';
  select string_agg(id,', ' order by created_at) into batch_codes from public.food_listings
   where donor_id=donor and recipient_id is not null and created_at>=now()-interval '24 hours';
  insert into public.replated_notifications(user_id,order_id,title,body)
   select distinct recipient_id,new.listing_id,'Precautionary food notice',
    'A health concern was reported on food from this donor. Please check batch codes '||coalesce(batch_codes,new.listing_id)||' before serving.'
   from public.food_listings where donor_id=donor and recipient_id is not null and created_at>=now()-interval '24 hours';
 end if;return new;end$$;
revoke all on function private.notify_replated_health_report() from public,anon,authenticated;
create trigger notify_replated_health_report after insert on public.complaints
for each row execute function private.notify_replated_health_report();

create or replace function private.resolve_replated_complaint()
returns trigger language plpgsql security definer set search_path=''
as $$declare donor uuid;begin
 if auth.uid() is not null and new.resolved_by is distinct from auth.uid() then raise exception 'Reviewer must be the signed-in administrator';end if;
 if old.status='open' and new.status in('upheld','dismissed') then
  select donor_id into donor from public.food_listings where id=new.listing_id;
  if new.status='upheld' then
   update public.profiles set points=greatest(0,points-100),upheld_complaints=upheld_complaints+1 where id=donor;
   insert into public.replated_audit_notes(order_id,admin_id,note)
    values(new.listing_id,new.resolved_by,'Complaint upheld: reversed 100 points and incremented upheld complaint count.');
   insert into public.replated_notifications(user_id,order_id,title,body)
    values(donor,new.listing_id,'Complaint upheld','100 points were reversed after this complaint was upheld.');
  elsif not exists(select 1 from public.complaints c where c.id<>new.id and c.listing_id=new.listing_id and c.category='Health issue' and c.status='open') then
   update public.food_listings set batch_status='Normal' where id=new.listing_id;
   insert into public.replated_audit_notes(order_id,admin_id,note)
    values(new.listing_id,new.resolved_by,'Complaint dismissed; health hold cleared.');
  end if;
 end if;return new;end$$;
revoke all on function private.resolve_replated_complaint() from public,anon,authenticated;
create trigger resolve_replated_complaint after update of status on public.complaints
for each row execute function private.resolve_replated_complaint();

create or replace view public.replated_trust_stats with (security_invoker=true) as
select p.id,p.role,
 count(l.id) filter(where p.role='donor' and l.status='Delivered') as donor_deliveries,
 case when count(l.id) filter(where p.role='donor')=0 then 0 else
  round(100.0*(count(l.id) filter(where p.role='donor' and l.recipient_id is not null))/
  nullif(count(l.id) filter(where p.role='donor'),0),1) end as ngo_acceptance_pct,
 p.upheld_complaints,p.points,p.badge_suspended,
 count(l.id) filter(where p.role='recipient' and l.status='Delivered') as ngo_received,
 count(l.id) filter(where p.role='rider' and l.status='Delivered') as rider_deliveries,
 count(l.id) filter(where p.role='rider' and l.status='Delivered' and l.delivered_at<=l.safe_until) as rider_on_time
from public.profiles p left join public.food_listings l
 on (p.role='donor' and l.donor_id=p.id) or (p.role='recipient' and l.recipient_id=p.id) or (p.role='rider' and l.rider_id=p.id)
group by p.id;
revoke all on public.replated_trust_stats from anon,authenticated;
grant select on public.replated_trust_stats to authenticated;

-- Schedule minute-level expiry / 19:30 cancellation where pg_cron is available.
do $$begin
 if exists(select 1 from pg_available_extensions where name='pg_cron') then
  execute 'create extension if not exists pg_cron with schema pg_catalog';
  execute 'select cron.schedule(''replated-safety-deadlines'',''* * * * *'',''select private.process_replated_deadlines()'')';
 end if;
exception when others then raise notice 'Schedule private.process_replated_deadlines() with Supabase Cron: %',sqlerrm;
end$$;
