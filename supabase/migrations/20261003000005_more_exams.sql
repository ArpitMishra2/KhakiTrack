-- More exams need two things the first two did not:
--  * age-banded standards (Delhi Police: race and jumps depend on age), and
--  * new kinds of event: counts (pull-ups) and pass/fail tests (ditch jump).

alter table public.standards
  add column age_min integer check (age_min is null or age_min between 0 and 99),
  add column age_max integer check (age_max is null or age_max between 0 and 99),
  add column reported_value numeric;  -- secondary-source value, shown nowhere as fact

alter table public.standards drop constraint standards_kind_check;
alter table public.standards add constraint standards_kind_check
  check (kind in ('time_max_seconds', 'distance_min_m', 'measure_min', 'measure_max',
                  'count_min', 'qualify'));

alter table public.standards drop constraint standards_exam_id_gender_category_event_key;
create unique index standards_unique_row on public.standards
  (exam_id, gender, category, event, coalesce(age_min, -1), coalesce(age_max, -1));

-- The official PET run distance ignores age bands (same distance, different
-- time limits).
create or replace function public.pet_distance_m(p_exam text, p_gender text)
returns integer language sql stable set search_path = public as $$
  select substring(event from 'run_(\d+)m')::integer
  from standards
  where exam_id = p_exam and gender = p_gender and verified
    and event like 'run_%' and category in ('all', 'general', 'general_obc_sc')
  order by category = 'all' desc, age_min nulls first
  limit 1
$$;
