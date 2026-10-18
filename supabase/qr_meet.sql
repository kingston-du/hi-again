-- hi again. — A8 QR meet (paste after schema.sql)
-- Requires: Anonymous sign-ins ON in Supabase Auth → Providers → Anonymous.
-- Adds profiles.slug, public_badge (anon), meet_via_web (authenticated / anon sessions).
-- A9 fields (bio, tiktok, phone, discord, email) expected on profiles; see profile_bio_contacts.sql.

-- ---------------------------------------------------------------------------
-- Slug column + backfill
-- ---------------------------------------------------------------------------

alter table public.profiles
  add column if not exists slug text;

create unique index if not exists profiles_slug_uidx
  on public.profiles (slug)
  where slug is not null;

create or replace function public.generate_profile_slug()
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  chars text := 'abcdefghijklmnopqrstuvwxyz0123456789';
  candidate text;
  i int;
begin
  loop
    candidate := '';
    for i in 1..8 loop
      candidate := candidate || substr(chars, 1 + floor(random() * 36)::int, 1);
    end loop;
    exit when not exists (
      select 1 from public.profiles p where p.slug = candidate
    );
  end loop;
  return candidate;
end;
$$;

revoke all on function public.generate_profile_slug() from public;

-- Backfill existing rows missing a slug
update public.profiles
set slug = public.generate_profile_slug()
where slug is null;

create or replace function public.profiles_ensure_slug()
returns trigger
language plpgsql
as $$
begin
  if new.slug is null or length(trim(new.slug)) = 0 then
    new.slug := public.generate_profile_slug();
  else
    new.slug := lower(left(trim(new.slug), 8));
  end if;
  return new;
end;
$$;

drop trigger if exists profiles_ensure_slug_trg on public.profiles;
create trigger profiles_ensure_slug_trg
  before insert or update on public.profiles
  for each row
  execute function public.profiles_ensure_slug();

-- ---------------------------------------------------------------------------
-- public_badge — readable without signing in
-- ---------------------------------------------------------------------------

create or replace function public.public_badge(p_slug text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_slug text := lower(nullif(trim(p_slug), ''));
  v_row public.profiles%rowtype;
begin
  if v_slug is null or length(v_slug) > 8 then
    return null;
  end if;

  select * into v_row
  from public.profiles p
  where p.slug = v_slug;

  if not found then
    return null;
  end if;

  return jsonb_build_object(
    'first_name', v_row.first_name,
    'last_name', v_row.last_name,
    'badge_color', v_row.badge_color,
    'bio', v_row.bio,
    'instagram', v_row.instagram,
    'snapchat', v_row.snapchat,
    'linkedin', v_row.linkedin,
    'tiktok', v_row.tiktok,
    'phone', v_row.phone,
    'discord', v_row.discord,
    'email', v_row.email
  );
end;
$$;

revoke all on function public.public_badge(text) from public;
grant execute on function public.public_badge(text) to anon, authenticated;

-- ---------------------------------------------------------------------------
-- meet_via_web — guest (anon session) adds themselves to host's People
-- ---------------------------------------------------------------------------

drop function if exists public.meet_via_web(text, text, text, text, text, text, text);

create or replace function public.meet_via_web(
  p_slug text,
  p_first_name text,
  p_last_name text,
  p_badge_color text,
  p_instagram text,
  p_snapchat text,
  p_linkedin text,
  p_tiktok text default null,
  p_phone text default null,
  p_discord text default null,
  p_email text default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_guest uuid := auth.uid();
  v_host uuid;
  v_slug text := lower(nullif(trim(p_slug), ''));
  v_first text := nullif(left(trim(coalesce(p_first_name, '')), 40), '');
  v_last text := nullif(left(trim(coalesce(p_last_name, '')), 40), '');
  v_color text := lower(nullif(trim(coalesce(p_badge_color, '')), ''));
  v_ig text := nullif(left(trim(coalesce(p_instagram, '')), 64), '');
  v_sc text := nullif(left(trim(coalesce(p_snapchat, '')), 64), '');
  v_li text := nullif(left(trim(coalesce(p_linkedin, '')), 64), '');
  v_tt text := nullif(left(trim(coalesce(p_tiktok, '')), 64), '');
  v_phone text := nullif(left(trim(coalesce(p_phone, '')), 32), '');
  v_discord text := nullif(left(trim(coalesce(p_discord, '')), 64), '');
  v_email text := nullif(left(lower(trim(coalesce(p_email, ''))), 120), '');
  v_meeting_id uuid;
  v_times_met int;
  v_now timestamptz := now();
  v_profile jsonb;
begin
  if v_guest is null then
    raise exception 'not authenticated';
  end if;

  if v_slug is null then
    return jsonb_build_object('status', 'not_found');
  end if;

  if v_first is null then
    raise exception 'first_name required';
  end if;

  if v_color is null or v_color not in ('red', 'blue', 'green', 'yellow', 'pink', 'black') then
    v_color := 'red';
  end if;

  -- Strip leading @ if present
  if v_ig is not null then v_ig := ltrim(v_ig, '@'); end if;
  if v_sc is not null then v_sc := ltrim(v_sc, '@'); end if;
  if v_li is not null then v_li := ltrim(v_li, '@'); end if;
  if v_tt is not null then v_tt := ltrim(v_tt, '@'); end if;
  if v_discord is not null then v_discord := ltrim(v_discord, '@'); end if;

  select p.id into v_host
  from public.profiles p
  where p.slug = v_slug;

  if v_host is null then
    return jsonb_build_object('status', 'not_found');
  end if;

  if v_host = v_guest then
    return jsonb_build_object('status', 'self');
  end if;

  insert into public.profiles as pr (
    id, first_name, last_name, badge_color,
    instagram, snapchat, linkedin, tiktok, phone, discord, email
  ) values (
    v_guest, v_first, v_last, v_color,
    v_ig, v_sc, v_li, v_tt, v_phone, v_discord, v_email
  )
  on conflict (id) do update set
    first_name = excluded.first_name,
    last_name = excluded.last_name,
    badge_color = excluded.badge_color,
    instagram = excluded.instagram,
    snapchat = excluded.snapchat,
    linkedin = excluded.linkedin,
    tiktok = excluded.tiktok,
    phone = excluded.phone,
    discord = excluded.discord,
    email = excluded.email;

  -- Dedupe: same pair within 2 minutes → return existing (status already)
  select m.id into v_meeting_id
  from public.meetings m
  where m.owner_id = v_host and m.other_id = v_guest
    and m.met_at > v_now - interval '2 minutes'
  order by m.met_at desc
  limit 1;

  if v_meeting_id is not null then
    select count(*)::int into v_times_met
    from public.meetings
    where owner_id = v_host and other_id = v_guest;

    select jsonb_build_object(
      'id', p.id, 'first_name', p.first_name, 'last_name', p.last_name,
      'badge_color', p.badge_color, 'bio', p.bio,
      'instagram', p.instagram, 'snapchat', p.snapchat, 'linkedin', p.linkedin,
      'tiktok', p.tiktok, 'phone', p.phone, 'discord', p.discord, 'email', p.email,
      'slug', p.slug
    ) into v_profile
    from public.profiles p
    where p.id = v_guest;

    return jsonb_build_object(
      'status', 'already',
      'meeting_id', v_meeting_id,
      'times_met', v_times_met,
      'profile', v_profile
    );
  end if;

  insert into public.meetings (owner_id, other_id, met_at, place_name)
  values (v_host, v_guest, v_now, 'QR code')
  returning id into v_meeting_id;

  insert into public.meetings (owner_id, other_id, met_at, place_name)
  values (v_guest, v_host, v_now, 'QR code');

  select count(*)::int into v_times_met
  from public.meetings
  where owner_id = v_host and other_id = v_guest;

  select jsonb_build_object(
    'id', p.id, 'first_name', p.first_name, 'last_name', p.last_name,
    'badge_color', p.badge_color, 'bio', p.bio,
    'instagram', p.instagram, 'snapchat', p.snapchat, 'linkedin', p.linkedin,
    'tiktok', p.tiktok, 'phone', p.phone, 'discord', p.discord, 'email', p.email,
    'slug', p.slug
  ) into v_profile
  from public.profiles p
  where p.id = v_guest;

  return jsonb_build_object(
    'status', 'met',
    'meeting_id', v_meeting_id,
    'times_met', v_times_met,
    'profile', v_profile
  );
end;
$$;

revoke all on function public.meet_via_web(text, text, text, text, text, text, text, text, text, text, text) from public;
grant execute on function public.meet_via_web(text, text, text, text, text, text, text, text, text, text, text) to authenticated;
