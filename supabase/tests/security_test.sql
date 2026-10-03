-- Tests the protections from the 2026-10-03 security audit.
-- Ends by raising PASS/FAIL, which rolls back everything it created.
-- Run: bash supabase/tests/run.sh security_test.sql

do $$
declare
  a uuid := gen_random_uuid();
  b uuid := gen_random_uuid();
  s1 uuid; s2 uuid; s3 uuid; s4 uuid; s5 uuid;
  grp bigint;
  asm bigint;
  plan bigint;
  code text;
  r bigint;
  i integer;
  failures text[] := '{}';
begin
  insert into auth.users (id, email, aud, role)
  select u, u::text || '@test.invalid', 'authenticated', 'authenticated' from unnest(array[a, b]) u;
  update profiles set exam_id = 'up_police_constable', gender = 'male', category = 'general',
    date_of_birth = '2004-01-01', display_name = 'Tester' where id in (a, b);

  -- Signed-out (anon) callers see nothing.
  execute 'set local role anon';
  begin perform 1 from profiles limit 1; failures := failures || 'anon_reads_profiles';
  exception when insufficient_privilege then null; end;
  begin perform 1 from standards limit 1; failures := failures || 'anon_reads_standards';
  exception when insufficient_privilege then null; end;
  begin perform leaderboard(null, 'pet', 0); failures := failures || 'anon_leaderboard';
  exception when insufficient_privilege then null; end;
  execute 'reset role';

  execute 'set local role authenticated';
  perform set_config('request.jwt.claims', json_build_object('sub', a, 'role', 'authenticated')::text, true);

  -- Everything the app and the edge functions do as a signed-in user still works.
  perform 1 from exams limit 1;
  perform 1 from standards limit 1;
  perform 1 from profiles where id = a;
  perform 1 from gps_runs where user_id = a;
  perform 1 from communities limit 1;
  perform 1 from community_members where user_id = a;
  update profiles set locale = 'en', leaderboard_visible = true where id = a;
  insert into training_assessments (user_id, exam_id, answers)
    values (a, 'up_police_constable', '{}'::jsonb) returning id into asm;
  update training_plans set status = 'archived' where user_id = a and status = 'active';
  insert into training_plans (user_id, exam_id, assessment_id, language, run_distance_m, target_seconds,
                              start_date, weeks_total, outline, model)
    values (a, 'up_police_constable', asm, 'hi', 4800, 1500, current_date, 8, '{}'::jsonb, 'test')
    returning id into plan;
  insert into plan_weeks (plan_id, user_id, week_number, sessions, model)
    values (plan, a, 1, '{}'::jsonb, 'test');
  insert into session_logs (user_id, plan_id, week_number, session_index, status)
    values (a, plan, 1, 0, 'done');
  update session_logs set status = 'partial' where plan_id = plan;
  delete from session_logs where plan_id = plan;
  insert into time_trials (user_id, exam_id, distance_m, duration_seconds, source)
    values (a, 'up_police_constable', 4800, 1490, 'assessment');
  delete from time_trials where user_id = a and source = 'assessment';

  -- Users cannot change reference data or write runs.
  begin insert into exams (id, name_hi, name_en, data_version) values ('x', 'x', 'x', 'x');
    failures := failures || 'user_wrote_exam'; exception when insufficient_privilege then null; end;
  begin update standards set value = 1; failures := failures || 'user_wrote_standard';
  exception when insufficient_privilege then null; end;
  begin
    insert into gps_runs (user_id, exam_id, mode, started_at, distance_m, duration_s, verdict, rules_version, point_count)
    values (a, 'up_police_constable', 'free', now(), 5000, 1500, 'verified', 1, 100);
    failures := failures || 'user_wrote_run';
  exception when insufficient_privilege then null; end;
  begin insert into community_members (community_id, user_id) values (1, a);
    failures := failures || 'user_joined_directly'; exception when insufficient_privilege then null; end;

  -- A manual time trial is fine; a forged GPS one is not.
  insert into time_trials (user_id, exam_id, distance_m, duration_seconds, source)
    values (a, 'up_police_constable', 4800, 1500, 'manual');
  begin
    insert into time_trials (user_id, exam_id, distance_m, duration_seconds, source)
      values (a, 'up_police_constable', 4800, 1000, 'gps');
    failures := failures || 'forged_gps_trial';
  exception when insufficient_privilege then null; end;
  begin update time_trials set source = 'gps' where user_id = a;
    failures := failures || 'upgraded_to_gps'; exception when insufficient_privilege then null; end;

  -- Over-long names are refused.
  begin update profiles set display_name = repeat('x', 61) where id = a;
    failures := failures || 'long_name'; exception when check_violation then null; end;

  -- AI slots: three per day, parallel claims count, users cannot touch the ledger.
  s1 := claim_ai_slot('plan', 3); s2 := claim_ai_slot('plan', 3); s3 := claim_ai_slot('plan', 3);
  if s1 is null or s2 is null or s3 is null then failures := failures || 'slots_denied'; end if;
  if claim_ai_slot('plan', 3) is not null then failures := failures || 'slot_limit'; end if;
  if claim_ai_slot('week', 3) is null then failures := failures || 'kinds_separate'; end if;
  begin delete from ai_usage; failures := failures || 'ledger_deleted';
  exception when insufficient_privilege then null; end;
  begin update ai_usage set created_at = now() - interval '9 days';
    failures := failures || 'ledger_backdated'; exception when insufficient_privilege then null; end;
  begin perform 1 from ai_usage; failures := failures || 'ledger_read';
  exception when insufficient_privilege then null; end;
  -- A failed generation gives its slot back; a finished one stays counted.
  perform release_ai_slot(s3);
  s4 := claim_ai_slot('plan', 3);
  if s4 is null then failures := failures || 'release_failed'; end if;
  perform finish_ai_slot(s4);
  perform release_ai_slot(s4);
  if claim_ai_slot('plan', 3) is not null then failures := failures || 'finished_slot_released'; end if;
  -- Other users have their own allowance.
  perform set_config('request.jwt.claims', json_build_object('sub', b, 'role', 'authenticated')::text, true);
  if claim_ai_slot('plan', 3) is null then failures := failures || 'shared_allowance'; end if;
  begin perform claim_ai_slot('plan', 999); failures := failures || 'huge_max';
  exception when others then null; end;

  -- Private group code: right code joins, wrong codes are counted and stop after 15.
  perform set_config('request.jwt.claims', json_build_object('sub', a, 'role', 'authenticated')::text, true);
  grp := create_community('Security Test Group', 'group', true);
  select invite_code into code from communities where id = grp;
  if code !~ '^[A-HJ-NP-Z2-9]{6}$' then failures := failures || 'code_format'; end if;
  perform set_config('request.jwt.claims', json_build_object('sub', b, 'role', 'authenticated')::text, true);
  for i in 1..15 loop
    r := join_community(null, 'ZZZZZ' || (i % 9 + 2)::text);
    if r <> -1 then failures := failures || 'wrong_code_joined'; end if;
  end loop;
  begin
    perform join_community(null, code);
    failures := failures || 'brute_force_allowed';
  exception when others then
    if sqlerrm <> 'rate_limited' then failures := failures || ('unexpected_' || sqlerrm); end if;
  end;

  -- Someone who has not guessed wrongly can still join with the right code.
  perform set_config('request.jwt.claims', json_build_object('sub', a, 'role', 'authenticated')::text, true);
  if join_community(null, lower(code)) <> grp then failures := failures || 'owner_code_join'; end if;

  if array_length(failures, 1) is null then
    raise exception 'PASS security';
  else
    raise exception 'FAIL security: %', failures;
  end if;
end $$;
