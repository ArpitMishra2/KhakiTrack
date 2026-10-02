-- Hyperlocal weekly leaderboards. Only server-verified GPS runs count.
--
-- Users can never read each other's runs or profiles directly; the
-- leaderboard() function below (security definer) returns only ranks,
-- shortened names and values for the caller's own exam, gender and area.

create table public.districts (
  id text primary key,                -- e.g. kanpur_nagar
  state text not null,
  name_en text not null,
  name_hi text not null
);
alter table public.districts enable row level security;
create policy "districts readable" on public.districts for select using (true);

alter table public.profiles
  add column leaderboard_visible boolean not null default true;

-- The official PET run distance for an exam and gender, from the verified
-- standards (the all-candidates or default category row).
create function public.pet_distance_m(p_exam text, p_gender text)
returns integer language sql stable set search_path = public as $$
  select substring(event from 'run_(\d+)m')::integer
  from standards
  where exam_id = p_exam and gender = p_gender and verified
    and event like 'run_%' and category in ('all', 'general', 'general_obc_sc')
  order by category = 'all' desc
  limit 1
$$;

-- p_scope: village | block | district | state
-- p_metric: pet (best verified mock PET time over the official distance,
--           lower is better) | distance (verified km this week, higher is better)
-- p_week_offset: 0 = this week, 1 = last week. Weeks run Monday to Sunday, IST.
create function public.leaderboard(p_scope text, p_metric text, p_week_offset integer default 0)
returns table (rank bigint, name text, value numeric, is_me boolean)
language plpgsql stable security definer set search_path = public as $$
declare
  me profiles%rowtype;
  week_start timestamptz;
  pet_m integer;
begin
  if p_scope not in ('village', 'block', 'district', 'state')
     or p_metric not in ('pet', 'distance')
     or p_week_offset not between 0 and 52 then
    raise exception 'invalid leaderboard arguments';
  end if;

  select * into me from profiles where id = auth.uid();
  if me.id is null or me.exam_id is null or me.gender is null then
    return;
  end if;
  if p_scope <> 'state' and me.district is null then return; end if;
  if p_scope in ('block', 'village') and me.block is null then return; end if;
  if p_scope = 'village' and me.village is null then return; end if;

  week_start := (date_trunc('week', now() at time zone 'Asia/Kolkata')
                 - make_interval(weeks => p_week_offset)) at time zone 'Asia/Kolkata';
  pet_m := pet_distance_m(me.exam_id, me.gender);

  return query
  with peers as (
    select p.id, p.display_name
    from profiles p
    where p.exam_id = me.exam_id
      and p.gender = me.gender
      and (p.leaderboard_visible or p.id = me.id)
      and coalesce(p.state, 'Uttar Pradesh') = coalesce(me.state, 'Uttar Pradesh')
      and (p_scope = 'state' or p.district = me.district)
      and (p_scope not in ('block', 'village') or lower(trim(p.block)) = lower(trim(me.block)))
      and (p_scope <> 'village' or lower(trim(p.village)) = lower(trim(me.village)))
  ),
  scores as (
    select r.user_id,
      case when p_metric = 'pet' then min(r.finish_seconds)
           else round(sum(r.distance_m) / 1000, 2) end as score
    from gps_runs r
    join peers on peers.id = r.user_id
    where r.verdict = 'verified'
      and r.exam_id = me.exam_id
      and r.started_at >= week_start
      and r.started_at < week_start + interval '7 days'
      and (p_metric = 'distance'
           or (r.mode = 'mock_pet' and r.target_m = pet_m and r.finish_seconds is not null))
    group by r.user_id
  ),
  ranked as (
    select s.user_id, s.score,
      rank() over (order by case when p_metric = 'pet' then s.score else -s.score end) as rk
    from scores s
    where s.score is not null and (p_metric = 'pet' or s.score > 0)
  )
  select ranked.rk,
    -- First name and initial only.
    trim(split_part(trim(coalesce(peers.display_name, '')), ' ', 1) || ' ' ||
         coalesce(left(nullif(split_part(trim(peers.display_name), ' ', 2), ''), 1) || '.', '')),
    ranked.score,
    ranked.user_id = me.id
  from ranked join peers on peers.id = ranked.user_id
  where ranked.rk <= 50 or ranked.user_id = me.id
  order by ranked.rk, peers.display_name;
end $$;

revoke all on function public.leaderboard(text, text, integer) from public, anon;
grant execute on function public.leaderboard(text, text, integer) to authenticated;
