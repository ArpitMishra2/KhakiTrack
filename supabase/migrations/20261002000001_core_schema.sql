-- Core schema: profiles, exams, physical standards. Users are 18+ only.

create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  display_name text,
  gender text check (gender in ('male', 'female')),
  date_of_birth date check (date_of_birth <= current_date - interval '18 years'),
  category text check (category in ('general', 'obc', 'sc', 'st', 'ews', 'ex_serviceman')),
  exam_id text,
  village text,
  block text,
  district text,
  state text default 'Uttar Pradesh',
  locale text not null default 'hi' check (locale in ('hi', 'en')),
  created_at timestamptz not null default now()
);

create table public.exams (
  id text primary key,
  name_hi text not null,
  name_en text not null,
  notification_url text,
  data_version text not null
);

alter table public.profiles
  add constraint profiles_exam_fk foreign key (exam_id) references public.exams (id);

-- One row per exam / gender / category / event. Every value carries its source.
create table public.standards (
  id bigint generated always as identity primary key,
  exam_id text not null references public.exams (id),
  gender text not null check (gender in ('male', 'female')),
  category text not null,
  event text not null,          -- e.g. run_1600m, run_800m, long_jump, high_jump, shot_put, height_cm, chest_cm
  kind text not null check (kind in ('time_max_seconds', 'distance_min_m', 'measure_min', 'measure_max')),
  value numeric,                -- null when unverified
  source_url text,
  verified boolean not null default false,
  unique (exam_id, gender, category, event)
);

alter table public.profiles enable row level security;
alter table public.exams enable row level security;
alter table public.standards enable row level security;

create policy "own profile read" on public.profiles for select using (auth.uid() = id);
create policy "own profile insert" on public.profiles for insert with check (auth.uid() = id);
create policy "own profile update" on public.profiles for update using (auth.uid() = id);

create policy "exams readable" on public.exams for select using (true);
create policy "standards readable" on public.standards for select using (true);

-- Create an empty profile row whenever a user signs up.
create function public.handle_new_user() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id) values (new.id);
  return new;
end $$;

create trigger on_auth_user_created after insert on auth.users
  for each row execute function public.handle_new_user();
