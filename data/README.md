# Exam standards data

Versioned files holding physical standards for each exam, gender and category.

Rules:
- Every value must carry a `source_url` to the official recruitment notification, plus a `source_ref` (page and paragraph).
- `verified: true` means the value was read directly from that official document. A value that cannot be sourced is `"verified": false` with `value: null`. Never guess.
- Arpit verifies all numbers before anything ships. `owner_review.reviewed` records that sign-off per file.

## File format
- `sources`: each official document with title, URL, SHA-256 of the PDF as downloaded, and retrieval date. Government sites move or delete files, so the hash lets us prove which document a value came from.
- `notes`: rules from the notice that are not numbers (exemptions, how measurements are taken).
- `standards`: one row per (gender, category, event). This maps one to one onto the `public.standards` table.
  - `kind`: `measure_min` (height, chest, weight), `time_max_seconds` (runs).
  - `event`: `height_cm`, `chest_unexpanded_cm`, `chest_expanded_cm`, `chest_expansion_cm`, `weight_kg`, `run_<metres>m`.
  - `category`: `all` applies to every category. Otherwise the most specific matching category wins; a candidate with no specific match uses `general` (SSC GD) or `general_obc_sc` (UP Police).

## Age bands and event kinds
- Rows may carry `age_min` / `age_max` (completed years, inclusive) when a notice sets different limits by age (Delhi Police race and jumps).
- `kind`: `time_max_seconds` (runs), `measure_min` (height, chest, weight, jumps in feet: 3.75 = 3'9"), `count_min` (pull-ups), `qualify` (pass/fail events such as the 9 ft ditch).
- Unverified rows keep `value: null` and may record `reported_value` from a secondary source; the app shows them as not confirmed and never as fact.

## Current state
Version `1.0` of both files is sourced from official notices, retrieved 2026-10-02:
- UP Police Constable 2025: UPPRPB DV/PST procedure notice (10-08-2026) and PET procedure notice (23-09-2026).
- SSC GD 2026: SSC notice published 01-12-2025, paras 12.4 and 12.5.

Arpit reviewed both files against the PDFs on 2026-10-02 (`owner_review.reviewed: true`).


Added 2026-10-03:
- `delhi_police_constable.json` (1.0): SSC notice for Constable (Executive) in Delhi Police Examination 2025, paras 12.13-12.19, all values sourced. Arpit to review.
- `agniveer_army_gd.json` (1.0, 2026-10-03): Physical Fitness Test read from official Army Recruiting Office notices (Secunderabad 2027, Tiruchirappalli 2025-26, Dehradun 2022: the same table in all three). joinindianarmy.nic.in itself is behind a captcha and was not used. Run limit 6:15 is the slowest time that earns marks (the notice does not call it a pass mark); pull-ups 6 is the lowest count with marks; ditch and zig-zag balance are 'need to qualify'. Height, chest and weight are region based and not included. Arpit to review.
