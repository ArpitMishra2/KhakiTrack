# Progress and handoff notes

Factual status for a new session. Read this, then `Context_for_claude` (project decisions). Last updated 2026-10-02.

## Done (all merged to main)
1. Monorepo layout: `app/` (Flutter, Android only), `supabase/`, `data/`, `docs/`.
2. Flutter app `maidan`, Android id `app.maidan.android` (`in.` is a Java keyword, so it is not used). Hindi default locale, English second, strings in `app/lib/l10n/*.arb`. Placeholder home screen listing the two exams. One widget test.
3. CI (`.github/workflows/ci.yml`): analyze, test, build debug APK, upload artifact. Green on main.
4. Supabase client initialised in `app/lib/main.dart`. Dev project ref `kduqwkutzyxljhlktuwi`, URL `https://kduqwkutzyxljhlktuwi.supabase.co`. The public anon key is in `app/lib/config.dart`.
5. Migration `supabase/migrations/20261002000001_core_schema.sql`: profiles (18+ check), exams, standards, row-level security, auto-profile trigger. Arpit reports he applied it by hand in the Supabase SQL editor. Not verified from the cloud session.
6. Draft exam data `data/exams/up_police_constable.json` and `ssc_gd.json`, version `0.1-unverified`. Values came from coaching sites, not official notifications.

## Blocked / open
- Official sources were unreachable (network egress policy). Arpit says he has allowed `uppbpb.gov.in` and `ssc.gov.in`; a running session did not pick it up, a new one should. Also wanted: `api.supabase.com` and `*.supabase.co`.
- UP Police run times are doubtful: sites say 4.8 km in 25 min (men) and 2.4 km in 14 min (women); earlier notifications may have said 28 min for men. Left `value: null` with `reported_value` until confirmed from the official notification.
- Postgres port 5432 is blocked and the direct DB host is IPv6-only. Options: Supabase Management API over HTTPS (needs a personal access token) or the SQL editor.
- Google sign-in needs a Google Cloud OAuth client and the Google provider enabled in Supabase; only Arpit can do that.
- App name is still "Maidan" (placeholder). A privacy policy is needed before any public release.
- Credentials were pasted in an earlier chat and should be treated as exposed and rotated by Arpit. None are in the repo.

## Next steps
1. Test network access to `uppbpb.gov.in`, `ssc.gov.in`, `api.supabase.com`.
2. Fetch the official UP Police constable and SSC GD notifications. Replace draft values with sourced ones, store `source_url` per value, set `verified: true` only when read from the official document. Flag anything unconfirmed.
3. Check the migration exists in the dev DB, then seed `exams` and `standards` from `data/`.
4. Exam selection screen reading from Supabase, then Google sign-in and profile setup (gender, category, DOB 18+).
5. Build order step 3 onward: training plans, progress tracker, GPS logging with cheat detection (tested on recorded traces), leaderboards.

## Environment notes
- Flutter is not preinstalled in cloud sessions: `git clone --depth 1 -b stable https://github.com/flutter/flutter.git /opt/flutter`, then use `/opt/flutter/bin`. No Android SDK, so APK builds happen only in CI.
- Force-push and rebase of existing branches were blocked by the permission system; use new branches and normal pushes.
- GitHub access is via MCP tools, not `gh`.
