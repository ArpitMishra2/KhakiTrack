-- Training: questionnaire answers, AI-generated plans (outline + week-by-week
-- detail), session logs and time trials. Every row belongs to one user and is
-- visible only to that user. Plans are written by the training-plan edge
-- function acting as the signed-in user, so no service-role key is involved.

create table public.training_assessments (
  id bigint generated always as identity primary key,
  user_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  exam_id text not null references public.exams (id),
  answers jsonb not null,
  created_at timestamptz not null default now()
);

create table public.training_plans (
  id bigint generated always as identity primary key,
  user_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  exam_id text not null references public.exams (id),
  assessment_id bigint not null references public.training_assessments (id) on delete cascade,
  status text not null default 'active' check (status in ('active', 'archived')),
  language text not null check (language in ('hi', 'en')),
  run_distance_m integer not null,
  target_seconds integer not null,  -- official qualifying time for the run
  start_date date not null,
  weeks_total integer not null check (weeks_total between 2 and 26),
  outline jsonb not null,           -- assessment text, phases, per-week outline
  model text not null,
  created_at timestamptz not null default now()
);

-- At most one active plan per user.
create unique index training_plans_one_active
  on public.training_plans (user_id) where status = 'active';

create table public.plan_weeks (
  id bigint generated always as identity primary key,
  plan_id bigint not null references public.training_plans (id) on delete cascade,
  user_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  week_number integer not null check (week_number >= 1),
  sessions jsonb not null,
  model text not null,
  created_at timestamptz not null default now(),
  unique (plan_id, week_number)
);

create table public.session_logs (
  id bigint generated always as identity primary key,
  user_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  plan_id bigint not null references public.training_plans (id) on delete cascade,
  week_number integer not null,
  session_index integer not null,
  status text not null check (status in ('done', 'partial', 'missed')),
  distance_km numeric check (distance_km is null or distance_km between 0 and 100),
  duration_seconds integer check (duration_seconds is null or duration_seconds between 0 and 36000),
  effort smallint check (effort is null or effort between 1 and 5),  -- 1 very easy .. 5 very hard
  pain boolean not null default false,
  note text check (note is null or length(note) <= 500),
  logged_at timestamptz not null default now(),
  unique (plan_id, week_number, session_index)
);

create table public.time_trials (
  id bigint generated always as identity primary key,
  user_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  exam_id text not null references public.exams (id),
  distance_m integer not null check (distance_m between 100 and 42195),
  duration_seconds integer not null check (duration_seconds between 10 and 36000),
  recorded_on date not null default current_date,
  source text not null default 'manual' check (source in ('manual', 'assessment', 'plan', 'gps')),
  created_at timestamptz not null default now()
);

create index on public.training_plans (user_id);
create index on public.plan_weeks (plan_id);
create index on public.session_logs (plan_id);
create index on public.time_trials (user_id, exam_id, recorded_on);

alter table public.training_assessments enable row level security;
alter table public.training_plans enable row level security;
alter table public.plan_weeks enable row level security;
alter table public.session_logs enable row level security;
alter table public.time_trials enable row level security;

create policy "own assessments" on public.training_assessments
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "own plans" on public.training_plans
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "own plan weeks" on public.plan_weeks
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "own session logs" on public.session_logs
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "own time trials" on public.time_trials
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
