# Young Learners Tutorial — architecture

## Product
A cross-platform tutorial-centre platform for learners, guardians, tutors and centre administrators.
Brand: deep brown, golden yellow and warm cream. Tagline: **Every Child Can Learn.**

## Client and backend
- Flutter application: `apps/mobile/` (Android, iOS and web preview from one codebase).
- Backend: Supabase project `lvpetmhhspuagbjojlks` in the user's `demo` organisation.
- Authentication: Supabase Auth with email/password.
- Client API key: publishable key only. Never ship a service-role or secret key.
- Profile and role records: `profiles` and `user_roles`.
- New self-registrations receive `external_learner`; student, guardian, tutor and staff roles must be assigned through trusted centre administration.

## Security model
RLS is enabled on the education tables. The signup bootstrap creates a profile and a least-privilege external-learner role. The profile and role policies currently allow a user to read their own records; users may update only permitted profile fields. The remaining education tables are intentionally inaccessible until table-specific policies are reviewed and implemented.

Required access rules before production:
- Guardians can see only children with verified guardian links.
- Tutors can see only assigned classes and their learners.
- Students can see only their own enrolments, submissions, attempts and published results.
- Fee invoices and payments are restricted to authorised finance/admin staff and the relevant guardian/student views.
- Assessment answer keys must never be exposed to learners before an assessment is submitted.
- Role changes are performed by trusted administrators, not by client-supplied metadata.
- Sensitive changes are auditable.

## Current implementation status
The Flutter app has a live Supabase sign-in/sign-up flow and reads the signed-in user's profile and role. The first learner landing screen is a foundation; class, lesson, assignment, assessment, attendance, guardian, tutor and administration workflows remain staged work.

## Deployment
GitHub Actions runs Flutter tests and publishes the web preview to GitHub Pages on pushes to `young-learners-foundation`. The Android workflow builds ABI-specific APKs. The web preview link is a browser link and works on Android, iPhone and desktop.

## Release checklist
- Implement and test table-specific RLS for every education table.
- Verify sign-up, email confirmation, sign-in, sign-out and password recovery.
- Test role assignment and parent-child access with separate test accounts.
- Run Flutter tests and platform builds.
- Verify the live web preview and APK artifacts before sharing with the centre.
