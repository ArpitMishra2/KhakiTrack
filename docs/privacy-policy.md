# Maidan privacy policy (DRAFT)

> Draft written from what the app actually does today. Fill in the bracketed parts and have it read by someone qualified before you publish it or hand it to a customer. It is not legal advice.

Last updated: [date]

## Who we are
Maidan ("we") is an app that helps candidates prepare for the physical tests of government recruitment (for example UP Police, SSC GD, Delhi Police, Army Agniveer). Maidan is not connected to any government department or recruitment board.

Contact for privacy questions: [contact email]

## Who can use it
Maidan is for people aged 18 or over. You enter your date of birth and the app does not let you continue if you are under 18.

## What we collect and why

| What | Why | Where it goes |
|---|---|---|
| Google account name and email (when you sign in with Google) | To sign you in and to pre-fill your name | Our database (Supabase). We do not read your Google contacts, files or anything else |
| Name, date of birth, gender, social category, chosen exam | To show the right physical standards for you (they differ by gender, age and category) | Our database |
| Answers to the plan questions: running level, experience, weekly distance, days and time available, pain or injury, medical conditions, optional weight and height | To build a training plan that is safe for you | Our database, and the answers (including any free-text note you write about pain) are sent to an AI service that writes the plan (see below) |
| Your runs: GPS route, distance, time, and the result of our cheat check | To time your mock PET, show progress and rank you | Our database. Routes are not shown to other people |
| Session logs, time trials, streak | Your plan and progress | Our database |
| Rough location (rounded to about 100 m) | To show live weather and advice where you are | Sent to Open-Meteo for that one request. We do not store it |
| Language and low-data choice | Remember your settings | Your phone only |

We do not sell your data. We do not show ads. We do not train AI models on your data. [Check your AI provider's own terms on retention and training before keeping this line.]

## Rankings
If you take part in rankings, other people in the same ranking see your first name and the first letter of your surname, and your result. You can switch your name off in the communities screen.

## Services we use
- **Supabase** (database, sign-in, server functions), hosted by Supabase.
- **Google Sign-In**, to log you in.
- **Open-Meteo**, for weather and air-quality. It receives rounded coordinates, nothing that identifies you.
- **An AI provider** ([Groq / Anthropic: fill in the one in use]) receives your plan answers and your age, gender and exam, but not your name or email, to write your plan.

## How long we keep it
Until you delete your account. Deleting your account (Settings > Delete account, or the page described in `delete-account.md`) erases your profile, plans, logs, trials, runs and memberships. Communities you started that other people still use stay, handed to another member. Backups held by our hosting provider are overwritten on their normal schedule.

## Your choices
- See and change your profile in the app.
- Turn off location permission at any time; runs and weather then do not work, everything else does.
- Delete your account in the app at any time.

## Health information
Plans and weather tips are general guidance and not medical advice. The pain and medical answers you give are used only to make the plan gentler or to tell you to see a doctor first.

## Security
Data travels over HTTPS. Each account can read and change only its own rows (row-level security in the database). No system is perfectly secure, so please do not put anything in the app you would not want stored.

## Changes
If this policy changes in a way that matters, we will say so in the app.

## India
We process personal data in line with the Digital Personal Data Protection Act, 2023: we ask only for what the app needs, tell you why, let you withdraw by deleting your account, and keep it only as long as the account exists. [Add grievance contact details here.]
