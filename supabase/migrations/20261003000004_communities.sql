-- User-created communities replace the fixed district list.
--
-- A community is a region (village, area, ground: public, searchable, open
-- to join) or a group (friends, an academy batch: public, or private and
-- joined with an invite code). Leaderboards are per community, plus one for
-- everyone. Creating and joining go through security definer functions so
-- invite codes and limits are enforced on the server.

drop function if exists public.leaderboard(text, text, integer);
drop table if exists public.districts;

create table public.communities (
  id bigint generated always as identity primary key,
  name text not null check (length(trim(name)) between 3 and 60),
  kind text not null check (kind in ('region', 'group')),
  is_private boolean not null default false,
  invite_code text not null unique,
  created_by uuid not null references auth.users (id) on delete cascade,
  created_at timestamptz not null default now(),
  check (kind = 'group' or not is_private)   -- regions are always public
);

-- One public community per name and kind, ignoring case and spacing.
create unique index communities_public_name
  on public.communities (kind, lower(regexp_replace(trim(name), '\s+', ' ', 'g')))
  where not is_private;

create table public.community_members (
  community_id bigint not null references public.communities (id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade,
  role text not null default 'member' check (role in ('owner', 'member')),
  joined_at timestamptz not null default now(),
  primary key (community_id, user_id)
);
create index on public.community_members (user_id);

alter table public.communities enable row level security;
alter table public.community_members enable row level security;

-- Public communities are visible to everyone signed in (for search); private
-- ones only to their members. Invite codes of private groups are only
-- visible to members, through this same rule.
create policy "visible communities" on public.communities for select to authenticated
  using (
    not is_private
    or exists (select 1 from public.community_members m
               where m.community_id = communities.id and m.user_id = auth.uid())
  );
-- Users see their own memberships and may leave (delete their own row).
create policy "own memberships" on public.community_members for select to authenticated
  using (user_id = auth.uid());
create policy "leave community" on public.community_members for delete to authenticated
  using (user_id = auth.uid());

create function public.normalise_name(p text) returns text
language sql immutable as $$ select regexp_replace(trim(p), '\s+', ' ', 'g') $$;

-- Creates a community and makes the caller its owner. Returns its id.
-- Limits: 3 created per day, 15 communities per user.
create function public.create_community(p_name text, p_kind text, p_private boolean default false)
returns bigint language plpgsql security definer set search_path = public as $$
declare
  me uuid := auth.uid();
  new_id bigint;
  code text;
begin
  if me is null then raise exception 'not signed in'; end if;
  if p_kind not in ('region', 'group') then raise exception 'invalid kind'; end if;
  if p_kind = 'region' and p_private then raise exception 'regions are public'; end if;
  if (select count(*) from communities where created_by = me
      and created_at > now() - interval '1 day') >= 3 then
    raise exception 'create_limit' using errcode = 'P0001';
  end if;
  if (select count(*) from community_members where user_id = me) >= 15 then
    raise exception 'member_limit' using errcode = 'P0001';
  end if;
  if not p_private and exists (
    select 1 from communities where kind = p_kind and not is_private
      and lower(normalise_name(name)) = lower(normalise_name(p_name))) then
    raise exception 'name_taken' using errcode = 'P0001';
  end if;
  loop
    -- 6 letters/digits without look-alikes (0/O, 1/I/L).
    code := (select string_agg(substr('ABCDEFGHJKMNPQRSTUVWXYZ23456789', 1 + floor(random() * 31)::int, 1), '')
             from generate_series(1, 6));
    exit when not exists (select 1 from communities where invite_code = code);
  end loop;
  insert into communities (name, kind, is_private, invite_code, created_by)
    values (normalise_name(p_name), p_kind, p_private, code, me) returning id into new_id;
  insert into community_members (community_id, user_id, role) values (new_id, me, 'owner');
  return new_id;
end $$;

-- Joins a public community by id, or any community by invite code.
create function public.join_community(p_id bigint default null, p_code text default null)
returns bigint language plpgsql security definer set search_path = public as $$
declare
  me uuid := auth.uid();
  c communities%rowtype;
begin
  if me is null then raise exception 'not signed in'; end if;
  if p_code is not null then
    select * into c from communities where invite_code = upper(trim(p_code));
  else
    select * into c from communities where id = p_id and not is_private;
  end if;
  if c.id is null then raise exception 'not_found' using errcode = 'P0001'; end if;
  if exists (select 1 from community_members where community_id = c.id and user_id = me) then
    return c.id;
  end if;
  if (select count(*) from community_members where user_id = me) >= 15 then
    raise exception 'member_limit' using errcode = 'P0001';
  end if;
  insert into community_members (community_id, user_id) values (c.id, me);
  return c.id;
end $$;

-- Search public communities and list the caller's own, with member counts.
create function public.list_communities(p_query text default null, p_mine boolean default false)
returns table (id bigint, name text, kind text, is_private boolean, invite_code text,
               members bigint, is_member boolean, is_owner boolean)
language sql stable security definer set search_path = public as $$
  select c.id, c.name, c.kind, c.is_private,
    case when m.user_id is not null then c.invite_code end,
    (select count(*) from community_members x where x.community_id = c.id),
    m.user_id is not null,
    coalesce(m.role = 'owner', false)
  from communities c
  left join community_members m on m.community_id = c.id and m.user_id = auth.uid()
  where auth.uid() is not null
    and (case when p_mine then m.user_id is not null
              else not c.is_private
                and (p_query is null or c.name ilike '%' || normalise_name(p_query) || '%') end)
  order by (m.user_id is not null) desc,
    (select count(*) from community_members x where x.community_id = c.id) desc, c.name
  limit 50
$$;

-- p_community: a community the caller belongs to, or null for everyone.
-- p_metric: pet (best verified mock PET time over the official distance)
--           | distance (verified km). p_week_offset: 0 this week, 1 last week
-- (Monday to Sunday, IST). Same exam and gender as the caller only.
create function public.leaderboard(p_community bigint, p_metric text, p_week_offset integer default 0)
returns table (rank bigint, name text, value numeric, is_me boolean)
language plpgsql stable security definer set search_path = public as $$
declare
  me profiles%rowtype;
  week_start timestamptz;
  pet_m integer;
begin
  if p_metric not in ('pet', 'distance') or p_week_offset not between 0 and 52 then
    raise exception 'invalid leaderboard arguments';
  end if;
  select * into me from profiles where id = auth.uid();
  if me.id is null or me.exam_id is null or me.gender is null then return; end if;
  if p_community is not null and not exists (
    select 1 from community_members where community_id = p_community and user_id = me.id) then
    return;
  end if;

  week_start := (date_trunc('week', now() at time zone 'Asia/Kolkata')
                 - make_interval(weeks => p_week_offset)) at time zone 'Asia/Kolkata';
  pet_m := pet_distance_m(me.exam_id, me.gender);

  return query
  with peers as (
    select p.id, p.display_name
    from profiles p
    where p.exam_id = me.exam_id and p.gender = me.gender
      and (p.leaderboard_visible or p.id = me.id)
      and (p_community is null or exists (
        select 1 from community_members m where m.community_id = p_community and m.user_id = p.id))
  ),
  scores as (
    select r.user_id,
      case when p_metric = 'pet' then min(r.finish_seconds)
           else round(sum(r.distance_m) / 1000, 2) end as score
    from gps_runs r join peers on peers.id = r.user_id
    where r.verdict = 'verified' and r.exam_id = me.exam_id
      and r.started_at >= week_start and r.started_at < week_start + interval '7 days'
      and (p_metric = 'distance'
           or (r.mode = 'mock_pet' and r.target_m = pet_m and r.finish_seconds is not null))
    group by r.user_id
  ),
  ranked as (
    select s.user_id, s.score,
      rank() over (order by case when p_metric = 'pet' then s.score else -s.score end) as rk
    from scores s where s.score is not null and (p_metric = 'pet' or s.score > 0)
  )
  select ranked.rk,
    trim(split_part(trim(coalesce(peers.display_name, '')), ' ', 1) || ' ' ||
         coalesce(left(nullif(split_part(trim(peers.display_name), ' ', 2), ''), 1) || '.', '')),
    ranked.score,
    ranked.user_id = me.id
  from ranked join peers on peers.id = ranked.user_id
  where ranked.rk <= 50 or ranked.user_id = me.id
  order by ranked.rk, peers.display_name;
end $$;

revoke all on function public.create_community(text, text, boolean) from public, anon;
revoke all on function public.join_community(bigint, text) from public, anon;
revoke all on function public.list_communities(text, boolean) from public, anon;
revoke all on function public.leaderboard(bigint, text, integer) from public, anon;
grant execute on function public.create_community(text, text, boolean) to authenticated;
grant execute on function public.join_community(bigint, text) to authenticated;
grant execute on function public.list_communities(text, boolean) to authenticated;
grant execute on function public.leaderboard(bigint, text, integer) to authenticated;
