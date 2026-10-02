# Supabase

Migrations in `migrations/`, edge functions in `functions/`.
One dev project only for now. Use the anon key and a dev-project access token.
Never commit or request the service-role key or the database password.

## Exam data seed
`seed.sql` is generated from `data/exams/*.json`; never edit it by hand. After changing the data:

    dart data/tool/build_seed.dart

Then run `seed.sql` in the SQL editor, or through the Management API (`POST /v1/projects/<ref>/database/query`) with a personal access token. It is idempotent: it upserts each exam and replaces that exam's standards.
