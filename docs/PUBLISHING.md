# Publishing on Google Play: checklist (for when you are ready)

Costs and rules checked on 2026-10-03; Google changes them, so re-check at the time.

## Account
- Play Console registration: **$25 once**. New personal accounts need government ID and address verification.
- A personal account created after November 2023 must run a **closed test with at least 12 testers for 14 days** before production. Organisation accounts do not have that rule but need a D-U-N-S number.
- Expect about 3 to 4 weeks: account and verification, the 14-day test, then Google's first review.

## Code side (done)
- Delete account in the app and on the server (`delete_my_account`), About page, privacy policy draft (`privacy-policy.md`), deletion page (`delete-account.md`), release signing wiring (`app/android/key.properties.example`).

## Code side (still to do when you decide to publish)
- Choose the **final app name and package name** (`app.maidan.android` cannot change after publishing).
- Create the release keystore and `android/key.properties` (see the example file). Back the keystore up. Turn on Play App Signing.
- Build an app bundle: `flutter build appbundle --release`. New apps must target Android 16 (API 36) from 31 August 2026; the project follows Flutter's default, so check it when you build.
- Google sign-in: add an Android OAuth client for the Play signing key's SHA-1 and move the consent screen from **Testing** to **Production**.
- A separate production Supabase project, crash reporting, and rotate the keys that were pasted into chat.

## Play Console forms
- Privacy policy URL and the deletion page URL (host `docs/` on GitHub Pages, free).
- Data safety form: name, email, date of birth, gender, location (GPS routes), health-related answers, shared with the AI provider and Open-Meteo.
- Location: foreground-service location declaration with a short demo video of a run.
- Content rating, target audience 18+, no ads.
- App access: give reviewers a test Google account (demo mode helps).
- Make clear the app is independent: no government emblems, "not affiliated" in the listing.
- Listing: 512 px icon, 1024x500 banner, phone screenshots (`docs/pitch/` has ready ones), Hindi and English text.

## Running costs
- Supabase Pro about $25 a month once live. Open-Meteo commercial licence $29 a month (the free tier is for non-commercial use). AI plans per use. Shorebird code push optional ($0 up to 5,000 patch installs a month).
