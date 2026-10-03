-- Tests delete_my_account: everything of the user goes, other people's data
-- stays, a shared community survives under a new owner.
-- Ends by raising PASS/FAIL, which rolls back everything it created.
-- Run: bash supabase/tests/run.sh delete_account_test.sql

do $$
declare
  a uuid := gen_random_uuid();   -- deletes their account
  b uuid := gen_random_uuid();   -- stays
  shared bigint;
  alone bigint;
  failures text[] := '{}';
begin
  insert into auth.users (id, email, aud, role)
  select u, u::text || '@test.invalid', 'authenticated', 'authenticated' from unnest(array[a, b]) u;
  update profiles set exam_id = 'up_police_constable', gender = 'male', category = 'general',
    date_of_birth = '2004-01-01', display_name = 'Leaver' where id = a;
  update profiles set exam_id = 'up_police_constable', gender = 'male', category = 'general',
    date_of_birth = '2004-01-01', display_name = 'Stayer' where id = b;

  insert into gps_runs (user_id, exam_id, mode, started_at, target_m, distance_m, duration_s,
                        finish_seconds, verdict, rules_version, point_count)
  values
    (a, 'up_police_constable', 'mock_pet', now(), 4800, 4800, 1460, 1450, 'verified', 1, 1460),
    (b, 'up_police_constable', 'mock_pet', now(), 4800, 4800, 1530, 1520, 'verified', 1, 1530);
  insert into time_trials (user_id, exam_id, distance_m, duration_seconds, recorded_on, source)
  values (a, 'up_police_constable', 4800, 1500, current_date, 'manual');

  execute 'set local role authenticated';
  perform set_config('request.jwt.claims', json_build_object('sub', a, 'role', 'authenticated')::text, true);
  shared := create_community('Shared Ground Test', 'region', false);
  alone := create_community('Alone Group Test', 'group', true);

  perform set_config('request.jwt.claims', json_build_object('sub', b, 'role', 'authenticated')::text, true);
  perform join_community(shared);

  -- Not signed in: refused.
  perform set_config('request.jwt.claims', '{}', true);
  begin
    perform delete_my_account();
    failures := failures || 'anon_allowed';
  exception when others then
    null;
  end;

  -- A leaves.
  perform set_config('request.jwt.claims', json_build_object('sub', a, 'role', 'authenticated')::text, true);
  perform delete_my_account();

  execute 'reset role';
  if exists (select 1 from auth.users where id = a) then failures := failures || 'user_left'; end if;
  if exists (select 1 from profiles where id = a) then failures := failures || 'profile_left'; end if;
  if exists (select 1 from gps_runs where user_id = a) then failures := failures || 'runs_left'; end if;
  if exists (select 1 from time_trials where user_id = a) then failures := failures || 'trials_left'; end if;
  if not exists (select 1 from auth.users where id = b) then failures := failures || 'b_gone'; end if;
  if not exists (select 1 from gps_runs where user_id = b) then failures := failures || 'b_runs_gone'; end if;
  if not exists (select 1 from communities where id = shared) then failures := failures || 'shared_gone'; end if;
  if (select created_by from communities where id = shared) is distinct from b then failures := failures || 'not_handed_over'; end if;
  if (select role from community_members where community_id = shared and user_id = b) is distinct from 'owner' then failures := failures || 'not_owner'; end if;
  if exists (select 1 from communities where id = alone) then failures := failures || 'alone_left'; end if;

  if array_length(failures, 1) is null then
    raise exception 'PASS delete_account';
  else
    raise exception 'FAIL delete_account: %', failures;
  end if;
end $$;
