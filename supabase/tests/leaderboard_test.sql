-- Tests leaderboard() against the real schema without leaving data behind.
-- Everything runs in one DO block that ends by raising an exception, which
-- rolls the whole transaction back; the exception message carries the
-- results as JSON ("PASS ..." or "FAIL ...").
--
-- Run: supabase/tests/run.sh leaderboard_test.sql

do $$
declare
  a uuid := gen_random_uuid();   -- Kanpur Nagar, Ghatampur block, village X
  b uuid := gen_random_uuid();   -- same village, slower
  c uuid := gen_random_uuid();   -- same district, other block
  d uuid := gen_random_uuid();   -- other district
  e uuid := gen_random_uuid();   -- same village, cheated (rejected run)
  f uuid := gen_random_uuid();   -- same village, short-target "PET"
  g uuid := gen_random_uuid();   -- same village, hidden from leaderboards
  h uuid := gen_random_uuid();   -- same village, woman (different board)
  wk timestamptz := date_trunc('week', now() at time zone 'Asia/Kolkata') at time zone 'Asia/Kolkata' + interval '1 hour';
  res jsonb := '{}';
  failures text[] := '{}';
  rows jsonb;
begin
  insert into auth.users (id, email, aud, role)
  select u, u::text || '@test.invalid', 'authenticated', 'authenticated'
  from unnest(array[a, b, c, d, e, f, g, h]) u;

  update profiles set exam_id = 'up_police_constable', gender = 'male', category = 'general',
    date_of_birth = '2004-01-01', state = 'Uttar Pradesh', district = 'kanpur_nagar',
    block = 'Ghatampur', village = 'Village X'
  where id in (a, b, c, d, e, f, g, h);
  update profiles set display_name = 'Ramesh Kumar Yadav' where id = a;
  update profiles set display_name = 'Suresh' where id = b;
  update profiles set display_name = 'Amit Singh', block = 'Bilhaur', village = 'Y' where id = c;
  update profiles set display_name = 'Vikas Pal', district = 'agra' where id = d;
  update profiles set display_name = 'Cheater One' where id = e;
  update profiles set display_name = 'Short Target' where id = f;
  update profiles set display_name = 'Hidden Person', leaderboard_visible = false where id = g;
  update profiles set display_name = 'Sunita Devi', gender = 'female' where id = h;
  -- block/village matching ignores case and spaces
  update profiles set block = ' ghatampur ', village = 'village x' where id = b;

  insert into gps_runs (user_id, exam_id, mode, started_at, target_m, distance_m, duration_s,
                        finish_seconds, verdict, rules_version, point_count)
  values
    (a, 'up_police_constable', 'mock_pet', wk, 4800, 4810, 1460, 1450, 'verified', 1, 1460),
    (a, 'up_police_constable', 'mock_pet', wk + interval '1 day', 4800, 4805, 1500, 1490, 'verified', 1, 1500),
    (a, 'up_police_constable', 'free', wk, null, 6000, 2000, null, 'verified', 1, 2000),
    (b, 'up_police_constable', 'mock_pet', wk, 4800, 4800, 1600, 1580, 'verified', 1, 1600),
    (b, 'up_police_constable', 'mock_pet', wk - interval '7 days', 4800, 4800, 1400, 1300, 'verified', 1, 1400),
    (c, 'up_police_constable', 'mock_pet', wk, 4800, 4800, 1520, 1510, 'verified', 1, 1520),
    (d, 'up_police_constable', 'mock_pet', wk, 4800, 4800, 1400, 1390, 'verified', 1, 1400),
    (e, 'up_police_constable', 'mock_pet', wk, 4800, 4800, 700, 690, 'rejected', 1, 700),
    (f, 'up_police_constable', 'mock_pet', wk, 1000, 1000, 200, 190, 'verified', 1, 200),
    (g, 'up_police_constable', 'mock_pet', wk, 4800, 4800, 1420, 1410, 'verified', 1, 1420),
    (h, 'up_police_constable', 'mock_pet', wk, 2400, 2400, 800, 790, 'verified', 1, 800);

  -- Call as user A.
  perform set_config('request.jwt.claims', json_build_object('sub', a, 'role', 'authenticated')::text, true);
  execute 'set local role authenticated';

  select coalesce(jsonb_agg(to_jsonb(l) order by l.rank), '[]') into rows from leaderboard('village', 'pet') l;
  res := res || jsonb_build_object('village_pet', rows);
  -- A (1450, best of two) then B (1580); not E (rejected), F (short target),
  -- G (hidden), H (other gender), B's faster run from last week.
  if rows <> '[{"rank":1,"name":"Ramesh K.","value":1450,"is_me":true},{"rank":2,"name":"Suresh","value":1580,"is_me":false}]'::jsonb then
    failures := failures || 'village_pet';
  end if;

  select coalesce(jsonb_agg(to_jsonb(l) order by l.rank), '[]') into rows from leaderboard('district', 'pet') l;
  res := res || jsonb_build_object('district_pet', rows);
  if jsonb_array_length(rows) <> 3 or rows->1->>'name' <> 'Amit S.' then
    failures := failures || 'district_pet';
  end if;

  select coalesce(jsonb_agg(to_jsonb(l) order by l.rank), '[]') into rows from leaderboard('state', 'pet') l;
  res := res || jsonb_build_object('state_pet', rows);
  if jsonb_array_length(rows) <> 4 or rows->0->>'name' <> 'Vikas P.' then
    failures := failures || 'state_pet';
  end if;

  select coalesce(jsonb_agg(to_jsonb(l) order by l.rank), '[]') into rows from leaderboard('village', 'distance') l;
  res := res || jsonb_build_object('village_distance', rows);
  -- A: 4.81 + 4.805 + 6.0 = 15.62 km; B: 4.8 km this week.
  if rows->0->>'value' <> '15.62' or rows->1->>'value' <> '4.80' then
    failures := failures || 'village_distance';
  end if;

  select coalesce(jsonb_agg(to_jsonb(l) order by l.rank), '[]') into rows from leaderboard('village', 'pet', 1) l;
  res := res || jsonb_build_object('last_week', rows);
  if rows <> '[{"rank":1,"name":"Suresh","value":1300,"is_me":false}]'::jsonb then
    failures := failures || 'last_week';
  end if;

  -- RLS still hides other users' runs and profiles from A directly.
  if (select count(*) from gps_runs where user_id <> a) <> 0
     or (select count(*) from profiles where id <> a) <> 0 then
    failures := failures || 'rls';
  end if;

  execute 'reset role';
  if cardinality(failures) = 0 then
    raise exception 'PASS %', res;
  else
    raise exception 'FAIL % %', failures, res;
  end if;
end $$;
