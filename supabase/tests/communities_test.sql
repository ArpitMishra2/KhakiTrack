-- Tests communities and per-community leaderboards against the real schema.
-- Ends by raising PASS/FAIL, which rolls back everything it created.
-- Run: bash supabase/tests/run.sh communities_test.sql

do $$
declare
  a uuid := gen_random_uuid();
  b uuid := gen_random_uuid();
  c uuid := gen_random_uuid();
  d uuid := gen_random_uuid();   -- woman, same village community
  wk timestamptz := date_trunc('week', now() at time zone 'Asia/Kolkata') at time zone 'Asia/Kolkata' + interval '1 hour';
  village bigint;
  friends bigint;
  code text;
  n bigint;
  rows jsonb;
  failures text[] := '{}';
  res jsonb := '{}';
  err text;

begin
  insert into auth.users (id, email, aud, role)
  select u, u::text || '@test.invalid', 'authenticated', 'authenticated' from unnest(array[a, b, c, d]) u;
  update profiles set exam_id = 'up_police_constable', gender = 'male', category = 'general',
    date_of_birth = '2004-01-01' where id in (a, b, c, d);
  update profiles set display_name = 'Ramesh Kumar' where id = a;
  update profiles set display_name = 'Suresh Pal' where id = b;
  update profiles set display_name = 'Amit' where id = c;
  update profiles set display_name = 'Sunita Devi', gender = 'female' where id = d;

  insert into gps_runs (user_id, exam_id, mode, started_at, target_m, distance_m, duration_s,
                        finish_seconds, verdict, rules_version, point_count)
  values
    (a, 'up_police_constable', 'mock_pet', wk, 4800, 4800, 1460, 1450, 'verified', 1, 1460),
    (b, 'up_police_constable', 'mock_pet', wk, 4800, 4800, 1530, 1520, 'verified', 1, 1530),
    (c, 'up_police_constable', 'mock_pet', wk, 4800, 4800, 1400, 1390, 'verified', 1, 1400),
    (d, 'up_police_constable', 'mock_pet', wk, 2400, 2400, 800, 790, 'verified', 1, 800);

  execute 'set local role authenticated';

  -- A creates a public region; the name is tidied.
  perform set_config('request.jwt.claims', json_build_object('sub', a, 'role', 'authenticated')::text, true);
  village := create_community('  Ghatampur   Ground ', 'region', false);
  if (select name from communities where id = village) <> 'Ghatampur Ground' then
    failures := failures || 'name_tidy';
  end if;
  -- A creates a private friends group.
  friends := create_community('Subah Ki Daud', 'group', true);
  select invite_code into code from communities where id = friends;
  if code !~ '^[A-HJ-NP-Z2-9]{6}$' then failures := failures || 'code_format'; end if;

  -- B: a duplicate public name is refused (case and spacing ignored).
  perform set_config('request.jwt.claims', json_build_object('sub', b, 'role', 'authenticated')::text, true);
  begin
    perform create_community('ghatampur ground', 'region', false);
    failures := failures || 'duplicate_allowed';
  exception when others then
    if sqlerrm <> 'name_taken' then failures := failures || ('duplicate_error:' || sqlerrm); end if;
  end;
  -- B cannot see the private group or join it by id, but can with the code.
  if exists (select 1 from communities where id = friends) then failures := failures || 'private_visible'; end if;
  if (select count(*) from list_communities('subah', false)) <> 0 then failures := failures || 'private_searchable'; end if;
  begin
    perform join_community(friends, null);
    failures := failures || 'private_join_by_id';
  exception when others then null;
  end;
  perform join_community(null, lower(code));        -- code is case-insensitive
  perform join_community(village, null);
  perform join_community(village, null);             -- joining twice is harmless
  if (select members from list_communities(null, true) where id = village) <> 2 then
    failures := failures || 'member_count';
  end if;
  if (select invite_code from list_communities(null, true) where id = friends) <> code then
    failures := failures || 'member_sees_code';
  end if;
  -- Search finds the public region with a partial name.
  if not exists (select 1 from list_communities('ghatam', false) where id = village) then
    failures := failures || 'search';
  end if;

  -- D (woman) joins the village; C joins nothing.
  perform set_config('request.jwt.claims', json_build_object('sub', d, 'role', 'authenticated')::text, true);
  perform join_community(village, null);

  -- Leaderboards as A.
  perform set_config('request.jwt.claims', json_build_object('sub', a, 'role', 'authenticated')::text, true);
  select coalesce(jsonb_agg(to_jsonb(l) order by l.rank), '[]') into rows from leaderboard(village, 'pet') l;
  res := res || jsonb_build_object('village', rows);
  if rows <> '[{"rank":1,"name":"Ramesh K.","value":1450,"is_me":true},{"rank":2,"name":"Suresh P.","value":1520,"is_me":false}]'::jsonb then
    failures := failures || 'village_board';
  end if;
  select coalesce(jsonb_agg(to_jsonb(l) order by l.rank), '[]') into rows from leaderboard(null, 'pet') l;
  res := res || jsonb_build_object('everyone', rows);
  if jsonb_array_length(rows) <> 3 or rows->0->>'name' <> 'Amit' then failures := failures || 'everyone_board'; end if;

  -- C is not a member: the village board is empty for C.
  perform set_config('request.jwt.claims', json_build_object('sub', c, 'role', 'authenticated')::text, true);
  if (select count(*) from leaderboard(village, 'pet')) <> 0 then failures := failures || 'non_member_board'; end if;

  -- B leaves the group by deleting its own membership; cannot remove A.
  perform set_config('request.jwt.claims', json_build_object('sub', b, 'role', 'authenticated')::text, true);
  delete from community_members where community_id = friends and user_id = b;
  delete from community_members where community_id = friends and user_id = a;
  get diagnostics n = row_count;
  if n <> 0 then failures := failures || 'removed_other'; end if;
  if exists (select 1 from list_communities(null, true) where id = friends) then failures := failures || 'leave'; end if;

  -- Daily create limit: 3.
  perform set_config('request.jwt.claims', json_build_object('sub', c, 'role', 'authenticated')::text, true);
  perform create_community('Group One', 'group', true);
  perform create_community('Group Two', 'group', true);
  perform create_community('Group Three', 'group', true);
  begin
    perform create_community('Group Four', 'group', true);
    failures := failures || 'create_limit';
  exception when others then
    if sqlerrm <> 'create_limit' then failures := failures || ('create_limit_error:' || sqlerrm); end if;
  end;

  -- Users still cannot insert memberships or communities directly.
  begin
    insert into community_members (community_id, user_id) values (village, c);
    failures := failures || 'direct_insert';
  exception when insufficient_privilege then null;
  end;

  execute 'reset role';
  if cardinality(failures) = 0 then raise exception 'PASS %', res;
  else raise exception 'FAIL % %', failures, res; end if;
end $$;
