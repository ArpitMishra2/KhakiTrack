-- Security hardening found in the full code audit of 2026-10-03.
-- No feature changes: every app and edge-function call keeps working.

-- 1. Least privilege on tables. Row-level security was already on; this makes
--    sure a policy added by mistake later cannot open more than intended.
revoke all on all tables in schema public from anon;
revoke all on all sequences in schema public from anon;
revoke truncate, references, trigger on all tables in schema public from authenticated;
-- Reference data is read-only for users.
revoke insert, update, delete on public.exams, public.standards from authenticated;
-- Written only by server code (edge function with the service role, or the
-- security definer functions below).
revoke insert, update, delete on public.gps_runs, public.gps_run_points, public.communities
  from authenticated;
-- Members join through join_community() and may only leave directly.
revoke insert, update on public.community_members from authenticated;
-- A profile is removed only by deleting the account.
revoke delete on public.profiles from authenticated;

-- 2. Time trials: users may add manual or assessment entries, but cannot mark
--    one as GPS-verified (only the server writes source = 'gps').
drop policy "own time trials" on public.time_trials;
create policy "own time trials read" on public.time_trials
  for select using (auth.uid() = user_id);
create policy "own time trials add" on public.time_trials
  for insert with check (auth.uid() = user_id and source in ('manual', 'assessment'));
create policy "own time trials change" on public.time_trials
  for update using (auth.uid() = user_id)
  with check (auth.uid() = user_id and source in ('manual', 'assessment'));
create policy "own time trials delete" on public.time_trials
  for delete using (auth.uid() = user_id);

-- 3. Sanity limits on stored values (new and changed rows only).
alter table public.profiles
  add constraint profiles_display_name_len
  check (display_name is null or length(display_name) <= 60) not valid;
alter table public.gps_runs
  add constraint gps_runs_sane
  check (distance_m between 0 and 150000 and duration_s between 0 and 86400) not valid;

-- 4. AI usage ledger. The plan function limited how many plans a user could
--    make by counting the user's own plan rows, which users can delete or
--    back-date. This ledger cannot be touched by users at all: they can only
--    claim a slot through the function, which counts for them.
create table public.ai_usage (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  kind text not null check (kind in ('plan', 'week')),
  status text not null default 'pending' check (status in ('pending', 'done')),
  created_at timestamptz not null default now()
);
create index on public.ai_usage (user_id, kind, created_at desc);
alter table public.ai_usage enable row level security;
revoke all on public.ai_usage from anon, authenticated;

-- Returns a slot id, or null when the caller is over [p_max] in the last day.
-- Pending slots count too, so parallel requests cannot all get through.
create function public.claim_ai_slot(p_kind text, p_max integer) returns uuid
language plpgsql security definer set search_path = public, pg_temp as $$
declare
  me uuid := auth.uid();
  used integer;
  slot uuid;
begin
  if me is null then raise exception 'not signed in'; end if;
  if p_kind not in ('plan', 'week') or p_max not between 1 and 50 then
    raise exception 'invalid arguments';
  end if;
  perform pg_advisory_xact_lock(hashtextextended(me::text || p_kind, 0));
  -- A request that died before finishing frees its slot after ten minutes.
  delete from ai_usage where user_id = me and status = 'pending'
    and created_at < now() - interval '10 minutes';
  delete from ai_usage where user_id = me and created_at < now() - interval '30 days';
  select count(*) into used from ai_usage
    where user_id = me and kind = p_kind and created_at > now() - interval '1 day';
  if used >= p_max then return null; end if;
  insert into ai_usage (user_id, kind) values (me, p_kind) returning id into slot;
  return slot;
end $$;

create function public.finish_ai_slot(p_id uuid) returns void
language sql security definer set search_path = public, pg_temp as $$
  update ai_usage set status = 'done' where id = p_id and user_id = auth.uid()
$$;

-- Frees a slot whose generation failed. Only pending slots can be released,
-- so a finished plan always stays counted.
create function public.release_ai_slot(p_id uuid) returns void
language sql security definer set search_path = public, pg_temp as $$
  delete from ai_usage where id = p_id and user_id = auth.uid() and status = 'pending'
$$;

revoke all on function public.claim_ai_slot(text, integer) from public, anon;
revoke all on function public.finish_ai_slot(uuid) from public, anon;
revoke all on function public.release_ai_slot(uuid) from public, anon;
grant execute on function public.claim_ai_slot(text, integer) to authenticated;
grant execute on function public.finish_ai_slot(uuid) to authenticated;
grant execute on function public.release_ai_slot(uuid) to authenticated;

-- 5. Invite codes: stronger randomness, and a limit on wrong guesses so a
--    private group's 6-character code cannot be brute-forced.
create table public.join_failures (
  user_id uuid not null references auth.users (id) on delete cascade,
  at timestamptz not null default now()
);
create index on public.join_failures (user_id, at desc);
alter table public.join_failures enable row level security;
revoke all on public.join_failures from anon, authenticated;

create or replace function public.create_community(p_name text, p_kind text, p_private boolean default false)
returns bigint language plpgsql security definer set search_path = public, pg_temp as $$
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
    -- 6 letters/digits without look-alikes (0/O, 1/I/L), from a secure source.
    code := (select string_agg(substr('ABCDEFGHJKMNPQRSTUVWXYZ23456789', 1 + (get_byte(b.bytes, i) % 31), 1), '')
             from (select decode(replace(gen_random_uuid()::text, '-', ''), 'hex') as bytes) b,
                  generate_series(0, 5) i);
    exit when not exists (select 1 from communities where invite_code = code);
  end loop;
  insert into communities (name, kind, is_private, invite_code, created_by)
    values (normalise_name(p_name), p_kind, p_private, code, me) returning id into new_id;
  insert into community_members (community_id, user_id, role) values (new_id, me, 'owner');
  return new_id;
end $$;

-- Joins a public community by id, or any community by invite code. A wrong
-- code returns -1 (not an error, so the failed try is still recorded) and
-- after 15 wrong codes in an hour further tries are refused.
create or replace function public.join_community(p_id bigint default null, p_code text default null)
returns bigint language plpgsql security definer set search_path = public, pg_temp as $$
declare
  me uuid := auth.uid();
  c communities%rowtype;
begin
  if me is null then raise exception 'not signed in'; end if;
  if p_code is not null then
    if (select count(*) from join_failures where user_id = me
        and at > now() - interval '1 hour') >= 15 then
      raise exception 'rate_limited' using errcode = 'P0001';
    end if;
    select * into c from communities where invite_code = upper(trim(p_code));
    if c.id is null then
      insert into join_failures (user_id) values (me);
      delete from join_failures where user_id = me and at < now() - interval '1 day';
      return -1;
    end if;
  else
    select * into c from communities where id = p_id and not is_private;
    if c.id is null then raise exception 'not_found' using errcode = 'P0001'; end if;
  end if;
  if exists (select 1 from community_members where community_id = c.id and user_id = me) then
    return c.id;
  end if;
  if (select count(*) from community_members where user_id = me) >= 15 then
    raise exception 'member_limit' using errcode = 'P0001';
  end if;
  insert into community_members (community_id, user_id) values (c.id, me);
  return c.id;
end $$;

-- 6. Security definer functions: put pg_temp last so a temporary table can
--    never shadow a real one inside them.
alter function public.handle_new_user() set search_path = public, pg_temp;
alter function public.pet_distance_m(text, text) set search_path = public, pg_temp;
alter function public.list_communities(text, boolean) set search_path = public, pg_temp;
alter function public.leaderboard(bigint, text, integer) set search_path = public, pg_temp;
alter function public.delete_my_account() set search_path = public, auth, pg_temp;
