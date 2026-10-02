-- GPS runs. Rows are written only by the submit-run edge function after it
-- re-analyses the raw points on the server, so users cannot record their own
-- verdict: they can read their runs but have no insert/update policy.

create table public.gps_runs (
  id bigint generated always as identity primary key,
  user_id uuid not null references auth.users (id) on delete cascade,
  exam_id text not null references public.exams (id),
  mode text not null check (mode in ('free', 'mock_pet', 'session')),
  plan_id bigint references public.training_plans (id) on delete set null,
  week_number integer,
  session_index integer,
  started_at timestamptz not null,
  target_m integer,
  distance_m numeric not null,
  duration_s numeric not null,
  finish_seconds numeric,
  verdict text not null check (verdict in ('verified', 'suspicious', 'rejected')),
  flags text[] not null default '{}',
  client_verdict text,
  rules_version integer not null,
  point_count integer not null,
  -- Downsampled [lat, lon, seconds] for drawing the route.
  route jsonb not null default '[]',
  created_at timestamptz not null default now()
);

-- Raw points kept apart so listing runs never loads them; used for audits
-- of leaderboard entries and for re-analysis when the rules change.
create table public.gps_run_points (
  run_id bigint primary key references public.gps_runs (id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade,
  points jsonb not null
);

create index on public.gps_runs (user_id, created_at desc);
create index on public.gps_runs (exam_id, verdict, created_at desc);

alter table public.gps_runs enable row level security;
alter table public.gps_run_points enable row level security;

create policy "own runs readable" on public.gps_runs
  for select using (auth.uid() = user_id);
create policy "own run points readable" on public.gps_run_points
  for select using (auth.uid() = user_id);
