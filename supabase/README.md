# Supabase

Migrations in `migrations/`, edge functions in `functions/`.
One dev project only for now. Use the anon key and a dev-project access token.
Never commit or request the service-role key or the database password.

## Exam data seed
`seed.sql` is generated from `data/exams/*.json`; never edit it by hand. After changing the data:

    dart data/tool/build_seed.dart

Then run `seed.sql` in the SQL editor, or through the Management API (`POST /v1/projects/<ref>/database/query`) with a personal access token. It is idempotent: it upserts each exam and replaces that exam's standards.

## Edge functions
`functions/training-plan` builds a personal PET running plan with Claude (`claude-opus-5-5`, structured JSON output). It runs as the signed-in user, so row-level security applies; no service-role key is used. Every AI plan must pass the hard safety rules in `validate.ts` (rest day, hard-session limits, gradual volume increase, session length) before it is saved; one corrected retry is allowed within the 150 s limit.

Needs the Supabase secret `ANTHROPIC_API_KEY` (Dashboard > Edge Functions > Secrets).

    cd supabase/functions/training-plan && deno test --config deno.json --allow-env .
    SUPABASE_ACCESS_TOKEN=... npx supabase functions deploy training-plan --project-ref <ref> --use-api

## Database tests
`tests/*.sql` run against the dev project and leave no data behind: each test is a DO block that ends by raising `PASS ...` or `FAIL ...`, which rolls back everything it created.

    SUPABASE_ACCESS_TOKEN=... bash supabase/tests/run.sh leaderboard_test.sql

They are not in CI yet because CI has no database access token.
