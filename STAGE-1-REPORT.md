# Young Learners Tutorial — implementation report

**Project reset:** The legacy finance/trading frontend and its SQL scripts have been removed from this branch. The education database in the Supabase `demo` organisation is the backend target.

## Completed in this pass
- Confirmed the live Supabase project and its education-centre schema.
- Added an Auth signup trigger that creates a profile and assigns only `external_learner` by default.
- Added own-profile read/update and own-role read policies with restricted column grants.
- Added the Flutter Supabase client dependency.
- Replaced the static-only app entry point with email/password sign-in and sign-up, account loading, role display and sign-out.
- Configured the web preview and Android APK workflows to use the project's public publishable key.
- Removed legacy finance/trading HTML, JavaScript, Laravel conversion files, finance SQL and finance-specific tests.

## Verified
- Live signup trigger exists on `auth.users`.
- `profiles` has RLS enabled with two own-account policies.
- `user_roles` has RLS enabled with one own-account policy.
- Previous GitHub Pages run completed successfully.
- New web-preview and Android workflows were triggered after the Supabase integration commits; their final outcomes still need checking.

## Remaining before real centre use
- The security advisor still reports 24 education tables with RLS enabled but no policies. They remain locked rather than exposed.
- Implement role-specific policies for students, guardians, tutors, classes, lessons, materials, attendance, assignments, assessments, results, announcements, invoices and payments.
- Build centre admin and tutor/guardian workspaces.
- Add password recovery, account verification UX, consent/safeguarding workflows and production email delivery.
- Test the new Flutter build on real Android and iPhone devices.
- Confirm the first administrator account and controlled role-provisioning process.

## Important
This is an active foundation build, not a completed production school-management system. Do not enter real children's records or financial data until the outstanding role policies and workflows have been tested.
