# Security audit: 2026-10-03

Scope: every tracked file (app, database migrations and tests, both edge functions, build and CI files, repository contents and git history) plus the live Supabase auth settings. Method: read the code, then try to break each rule. No feature was changed.

## Fixed

| # | Problem | Risk | Fix |
|---|---|---|---|
| 1 | The AI plan limit (3 plans, 4 weeks a day) counted the user's own plan rows, which users could delete or back-date through the API | Unlimited AI generation, so unlimited cost | A ledger table users cannot read or write (`ai_usage`); slots are claimed through `claim_ai_slot`, parallel requests count, a failed generation gives its slot back |
| 2 | `submit-run` trusted the client's `started_at`, which decides the ranking week | A run could be dated into any week | Start must be within 7 days and the run cannot end in the future |
| 3 | The same run could be sent again and again, and counted each time on the distance board | Inflated weekly distance | Overlapping or duplicate runs are refused (409); 60 km per 24 hours; 12 runs a day instead of 30 |
| 4 | A run could point at another user's `plan_id` | Cross-account reference | The plan must belong to the caller, otherwise it is ignored |
| 5 | No request size limit on `submit-run` | Memory and storage abuse | 4 MB body limit |
| 6 | Private group codes (6 characters) had no limit on wrong guesses and used a non-secure random source | Brute-forcing a private group | 15 wrong codes an hour per account, then refused; codes from a secure random source |
| 7 | The offline run queue was not tied to an account | A run recorded by one account could be sent by the next account to sign in on the phone, and survived account deletion | Each queued run records its owner and is only sent by that account; deleting an account erases its queue |
| 8 | A queued run was thrown away on a 401 (signed out or expired token) | Silent loss of a real run | 401, 408 and 429 are retried later |
| 9 | Table privileges were wide open behind RLS (signed-out role could be granted anything by one mistaken policy) | Defence in depth | Signed-out role has no table access; users cannot write exams, standards, runs or communities, cannot join groups except through the function, cannot delete a profile |
| 10 | Users could mark their own time trial as GPS-verified | Fake "verified" results | Users can only add `manual` or `assessment` trials |
| 11 | Free-text pain and session notes went into the AI prompt unquoted | Prompt injection (limited: the output is checked by the safety rules and shown as plain text) | Quoted as data, newlines escaped, and the system prompt says to ignore instructions inside them |
| 12 | Security definer functions had `pg_temp` first on their search path | Table shadowing (not reachable through the API, but standard hardening) | `pg_temp` is searched last |
| 13 | Email and password sign-up was enabled on Supabase although the app only uses Google | Open door for spam accounts | Email provider switched off (Google sign-in unchanged; checked) |
| 14 | `AndroidManifest` allowed cloud and adb backup of app data (profile copy, GPS queue, session) | Data extraction from a phone | `allowBackup=false`, `usesCleartextTraffic=false` |
| 15 | CI used moving action tags and default token permissions | Supply-chain risk | Actions pinned to commits, `permissions: contents: read` |
| 16 | `Context_for_claude` (owner's name, college, business plan and budget) was tracked in a public repository | Privacy and business exposure, especially for a pitch | Removed from the tree and ignored. It is still in git history |
| 17 | Names had no length limit | Oversized names on rankings | 60 characters in the database and the form; file names built from ids are restricted to safe characters |

All database changes are in `supabase/migrations/20261003000007_security_hardening.sql`, with tests in `supabase/tests/security_test.sql`. Both functions were redeployed and the live settings checked from outside (no auth gives 401, email sign-up gives `email_provider_disabled`, signed-out table reads give 42501).

## Checked and fine
- No secrets in the code or the whole git history. The only key in the app is the public `anon` key, which is meant to be public. The service-role key is only read from the function environment.
- Row-level security is on for every table and every policy is scoped to `auth.uid()`; the leaderboard, community and delete functions are security definer with fixed search paths and no public execute.
- Both edge functions verify the caller's token with Supabase rather than trusting it, and the plan function acts as the user so RLS still applies.
- Supabase auth: Google nonce check on, refresh-token rotation on, no anonymous users, no phone sign-in.
- Analysis code is safe on hostile input: sorted and de-duplicated timestamps, bounded sizes, linear time, non-finite numbers rejected.
- No logging of personal data in the app, no custom certificate handling, only https, no web views or deep links.

## Still open (needs a decision or is a limit of the approach)
1. **GPS is reported by the phone.** A modified app can send a believable made-up route. The rules, the window, the duplicate and daily limits make it harder, not impossible. Next steps: Play Integrity attestation (needs a Play account), a check of steps or accelerometer against distance, a "too regular" timing rule (change Dart and TypeScript together), and spot checks of top-ranked runs (raw points are stored).
2. The average-speed limit (6.2 m/s, about a 13:25 5 km) is generous for this audience. Lowering it needs the same change in the app and the server and new golden traces.
3. A user can edit their own gender and exam, which decides which board they appear on. Fixing it needs identity checks.
4. **The repository is public.** It holds the project reference, the public keys and, in history, the file removed in fix 16. If this goes to buyers or organisations, make it private. Rewriting history is possible but is your call.
5. Rotate the credentials that were pasted into chat: the Groq key, the Google web client secret and the Supabase access token.
6. No branch protection on `main` (a repository setting only you can change).
7. Per-account AI limits can be multiplied by many Google accounts. Set a monthly spend limit in the Groq or Anthropic console as a backstop.
8. Google sign-in is in "Testing"; release builds are signed with the debug key and downloadable from CI by anyone with a GitHub account while the repository is public. Fine for demos, not for a store release (see `PUBLISHING.md`).
9. Dev and production share one Supabase project.
