-- hi again. — Part 3 schema
-- Paste into Supabase → SQL Editor and run once.

create extension if not exists "pgcrypto";

-- ---------------------------------------------------------------------------
-- Tables
-- ---------------------------------------------------------------------------

create table if not exists public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  first_name text not null,
  last_name text,
  badge_color text not null default 'red',
  bio text,
  instagram text,
  snapchat text,
  linkedin text,
  tiktok text,
  phone text,
  discord text,
  email text,
  created_at timestamptz not null default now()
);

create table if not exists public.cards (
  card_hash text primary key,
  user_id uuid not null unique references public.profiles (id) on delete cascade,
  claimed_at timestamptz not null default now()
);

create table if not exists public.meetings (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references public.profiles (id) on delete cascade,
  other_id uuid not null references public.profiles (id) on delete cascade,
  met_at timestamptz not null default now(),
  lat float8,
  lng float8,
  place_name text,
  note text
);

create index if not exists meetings_owner_id_idx on public.meetings (owner_id);
create index if not exists meetings_other_id_idx on public.meetings (other_id);
create index if not exists meetings_owner_other_idx on public.meetings (owner_id, other_id);

-- ---------------------------------------------------------------------------
-- Row Level Security
-- ---------------------------------------------------------------------------

alter table public.profiles enable row level security;
alter table public.cards enable row level security;
alter table public.meetings enable row level security;

-- profiles: read own or anyone you have a meeting with; insert/update own only
drop policy if exists "profiles_select" on public.profiles;
create policy "profiles_select" on public.profiles
  for select to authenticated
  using (
    id = (select auth.uid())
    or exists (
      select 1
      from public.meetings m
      where m.owner_id = (select auth.uid())
        and m.other_id = profiles.id
    )
  );

drop policy if exists "profiles_insert" on public.profiles;
create policy "profiles_insert" on public.profiles
  for insert to authenticated
  with check (id = (select auth.uid()));

drop policy if exists "profiles_update" on public.profiles;
create policy "profiles_update" on public.profiles
  for update to authenticated
  using (id = (select auth.uid()))
  with check (id = (select auth.uid()));

-- cards: no direct access (no policies). Only claim_card / scan_card touch it.

-- meetings: read/update/delete own rows; no direct inserts
drop policy if exists "meetings_select" on public.meetings;
create policy "meetings_select" on public.meetings
  for select to authenticated
  using (owner_id = (select auth.uid()));

drop policy if exists "meetings_update" on public.meetings;
create policy "meetings_update" on public.meetings
  for update to authenticated
  using (owner_id = (select auth.uid()))
  with check (owner_id = (select auth.uid()));

drop policy if exists "meetings_delete" on public.meetings;
create policy "meetings_delete" on public.meetings
  for delete to authenticated
  using (owner_id = (select auth.uid()));

-- ---------------------------------------------------------------------------
-- Grants (Data API). Cards stay locked down.
-- ---------------------------------------------------------------------------

grant usage on schema public to authenticated;

grant select, insert, update on public.profiles to authenticated;
grant select, delete on public.meetings to authenticated;
-- Only the note is editable. Changing other_id would let someone read any profile
-- through profiles_select, so table-wide UPDATE (and Supabase's default INSERT) is revoked.
revoke insert, update on public.meetings from anon, authenticated;
grant update (note) on public.meetings to authenticated;
revoke all on public.profiles, public.meetings from anon;

revoke all on public.cards from public, anon, authenticated;

-- ---------------------------------------------------------------------------
-- Functions (security definer; only authenticated may execute)
-- ---------------------------------------------------------------------------

create or replace function public.claim_card(p_hash text)
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  existing_user uuid;
begin
  if auth.uid() is null then
    raise exception 'not authenticated';
  end if;

  select c.user_id into existing_user
  from public.cards c
  where c.card_hash = p_hash;

  if existing_user is not null then
    if existing_user = auth.uid() then
      return 'already_yours';
    end if;
    return 'taken';
  end if;

  delete from public.cards where user_id = auth.uid();

  insert into public.cards (card_hash, user_id)
  values (p_hash, auth.uid());

  return 'linked';
end;
$$;

create or replace function public.scan_card(
  p_hash text,
  p_lat float8,
  p_lng float8,
  p_place text
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_card_user uuid;
  v_meeting_id uuid;
  v_times_met int;
  v_profile jsonb;
  v_now timestamptz := now();
begin
  if auth.uid() is null then
    raise exception 'not authenticated';
  end if;

  select c.user_id into v_card_user
  from public.cards c
  where c.card_hash = p_hash;

  if v_card_user is null then
    return jsonb_build_object('status', 'unknown');
  end if;

  if v_card_user = auth.uid() then
    return jsonb_build_object('status', 'self');
  end if;

  -- The scanner writes the other person's row too, so keep its content sane.
  if p_lat is null or p_lng is null or p_lat not between -90 and 90 or p_lng not between -180 and 180 then
    p_lat := null; p_lng := null;
  end if;
  p_place := nullif(left(trim(p_place), 80), '');

  -- A double tap within 2 minutes returns the same meeting instead of adding rows.
  select m.id into v_meeting_id
  from public.meetings m
  where m.owner_id = auth.uid() and m.other_id = v_card_user
    and m.met_at > v_now - interval '2 minutes'
  order by m.met_at desc
  limit 1;

  if v_meeting_id is null then
    insert into public.meetings (owner_id, other_id, met_at, lat, lng, place_name)
    values (auth.uid(), v_card_user, v_now, p_lat, p_lng, p_place)
    returning id into v_meeting_id;

    insert into public.meetings (owner_id, other_id, met_at, lat, lng, place_name)
    values (v_card_user, auth.uid(), v_now, p_lat, p_lng, p_place);
  end if;

  select count(*)::int into v_times_met
  from public.meetings
  where owner_id = auth.uid()
    and other_id = v_card_user;

  select jsonb_build_object(
    'id', p.id, 'first_name', p.first_name, 'last_name', p.last_name, 'badge_color', p.badge_color,
    'bio', p.bio,
    'instagram', p.instagram, 'snapchat', p.snapchat, 'linkedin', p.linkedin,
    'tiktok', p.tiktok, 'phone', p.phone, 'discord', p.discord, 'email', p.email
  ) into v_profile
  from public.profiles p
  where p.id = v_card_user;

  return jsonb_build_object(
    'status', 'met',
    'meeting_id', v_meeting_id,
    'times_met', v_times_met,
    'profile', v_profile
  );
end;
$$;

create or replace function public.unlink_card()
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then
    raise exception 'not authenticated';
  end if;
  delete from public.cards where user_id = auth.uid();
end;
$$;

revoke all on function public.unlink_card() from public, anon;
grant execute on function public.unlink_card() to authenticated;

revoke all on function public.claim_card(text) from public, anon;
revoke all on function public.scan_card(text, float8, float8, text) from public, anon;

grant execute on function public.claim_card(text) to authenticated;
grant execute on function public.scan_card(text, float8, float8, text) to authenticated;
