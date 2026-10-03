# Maidan: one-page pitch

Physical-test preparation for government recruitment, built for candidates in small towns. Hindi first, English one tap away.

## The problem
- The physical tests (run, jumps, pull-ups, height and chest) decide who is selected, and the standards differ by exam, gender, age and category. They sit in long PDF notices.
- Most candidates train without a plan, a timer they can trust, or anyone to compare against.
- Times people report to each other cannot be trusted, so there is no honest benchmark.

## What Maidan does
| For the candidate | How |
|---|---|
| Knows exactly what is required | Standards for UP Police, SSC GD, Delhi Police and Army Agniveer, each value read from the official notice with page and paragraph. Unconfirmed values are shown as "not yet confirmed", never guessed |
| Trains safely | A week-by-week plan built around their level, time and pain or health answers. Hard safety rules are enforced in code (rest day, no back-to-back hard days, gradual increase, doctor-first flag) |
| Tests like the real thing | GPS mock PET over the official distance with auto-stop, a Hindi voice coach, vibration when behind pace, and a clear "you would qualify / borderline" verdict with a GPS-error margin |
| Cannot cheat | The same cheat-detection rules run on the phone and again on the server (fake location, teleport, vehicle speed). Only verified runs count |
| Competes locally | Weekly rankings by village, ground or friends' group, PET time or distance, with a share button for WhatsApp |
| Stays motivated | Streaks and badges |
| Runs in real conditions | Live weather and air quality where they are, a plain verdict, what to carry or wear, best time to run |
| Works on poor networks | Cached standards, offline run queue, low-data mode, small 20 MB install |

## Why it is hard to copy quickly
- A **sourced data pipeline**: every number traces to a notice PDF (with its hash). New exams are added the same way.
- **Server-verified rankings**: trust in the leaderboard is the product.
- **Safety-checked AI plans**: the model writes, the code can veto.
- Hindi-first design for the audience, not a translation.

## Where it stands (October 2026)
- Working Android app, tested on a real phone; about 150 automated tests; CI on every change.
- Exams: UP Police Constable, SSC GD, Delhi Police Constable (all sourced), Army Agniveer GD (fitness test sourced; height, chest and weight vary by region and are not yet included).
- Not yet on the Play Store. Account deletion, an About page and a draft privacy policy are ready.
- Runs on a managed backend (Supabase), so there is no server to maintain.

## Costs to run (rough, for a public launch)
- Google Play registration: $25 once.
- Backend: about $25 a month once it is live (free tier pauses when idle).
- Weather: free for non-commercial use; $29 a month for a commercial licence.
- AI plans: pay per plan, not yet measured at scale; a smaller model cuts it sharply.

## What an organisation could do with it
These are options, not commitments:
- **Academies and coaching centres:** run their batch as a private group with its own ranking and invite code.
- **Institutions:** white-label with their name and exams.
- **Buyers of the whole product:** the app, backend schema, data pipeline, tests and documentation come together.

## Next
More exams and regions, Agniveer women's notice, a coach view for academies, daily reminders, and an iOS build.
