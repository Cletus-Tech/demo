# Young Learners Tutorial — First-release audit

**Audit status:** In progress  
**Audit date:** 19 November 2026  
**Branch:** `young-learners-foundation`  
**Backend project:** `lvpetmhhspuagbjojlks`

## Current verdict

The project is suitable for controlled internal review, but it is **not yet ready for a public first release**. The main Flutter app builds, and the core database has RLS enabled, but real-user journeys are not covered by adequate automated tests, the live content catalogue is empty, native release packaging is incomplete, and the repository's migration history needs reconciliation.

A visible screen is not counted as a working feature until its complete workflow has been tested.

## Verified strengths

- The live database has 39 public tables and RLS is enabled on all of them.
- Parent/guardian linking, student records, tutor workspaces, classroom posts, assignments, CBT, attendance, results, staff room, communications, notifications and reporting have implementation and database infrastructure.
- The dashboard announcement publishing function accepts all 14 configured billboard themes.
- The latest web preview workflow completed successfully for commit `933dc4d8cef327b3a2643412fefb9344b2cb63a2`.
- The previous Android release workflow completed successfully for commit `8941438d3f87fed5cf40d375dd01e0cb91877814`; the newer Android build for the profile privacy changes is still being checked.
- Profile editing now uses column-level update grants; users can update their own optional profile fields but cannot change protected account type/status fields.
- Direct-message rows are now immutable after insertion; authenticated clients have no UPDATE privilege.
- Profile photos are now stored in a private bucket and loaded through signed URLs. Storage policies restrict read/write/delete to the owner's folder.

## Release blockers and high-priority gaps

### 1. Automated test coverage — Critical

The current test suite contains one widget smoke test that checks the sign-in screen. It does not exercise authentication, student class setup, parent-child linking, payments, classroom access, CBT, assignment submission, attendance, results, profile uploads, billboard publishing or role-specific access.

**Required:** add integration tests for each primary role and critical data workflow, plus static analysis in CI.

### 2. Live learning content — Critical for learner launch

Current live database counts:

| Area | Current records |
|---|---:|
| Active classes | 12 |
| Active subjects | 22 |
| Active learning programmes | 0 |
| Published lessons | 0 |
| Learning materials | 0 |
| Assessments | 0 |
| Question bank questions | 0 |
| Assignments / submissions | 0 / 0 |
| Result periods / results | 0 / 0 |
| Attendance records | 0 |
| Active tutors / staff | 0 / 0 |
| Active announcements | 2 |

The learning catalogue and assessment features therefore have infrastructure but no content to serve. A learner launch requires configured programmes, lessons/materials, assessment questions, and at least one assigned tutor/class workflow.

### 3. Classroom PIN requirement — Not implemented

The planned unique classroom access PIN issued by an administrator after payment approval is not present. The current system uses programme access requests and manual payment review/approval. Do not advertise PIN-based classroom entry until it is built and tested.

### 4. Payments — Limited scope

The current workflow is manual payment submission and administrator review. A live payment gateway/automated payment confirmation is not configured. This must be clearly labelled as manual payment in the first release unless a payment provider is integrated.

### 5. Native release packaging — Critical before store release

- Android APK workflow builds release-mode APKs, but no production signing keystore is configured in the workflow. Treat the artifact as a QA/sideload build, not a Play Store-ready signed release.
- No iOS build workflow or IPA/TestFlight configuration is present.
- The Android workflow generates platform scaffolding during CI rather than maintaining a reviewed native project configuration in source control.

**Required:** branded Android application ID, launcher icon/splash, release keystore and signing secrets; iOS project, Apple signing/provisioning and TestFlight workflow.

### 6. Database migration source drift — Critical for reproducible deployment

The live Supabase migration history and repository migration files are not aligned: **58 migrations are applied in Supabase, while this branch contains 44 migration files; 28 applied migration names have no matching source file, 14 local migration files are not represented in the live history, and 25 same-name migrations have different version timestamps.** Do not run a blanket `supabase db push` or reset against production until this is reconciled.

The two recent hardening changes are now recorded as migrations:
- `20261119014426_profile_fields_and_message_immutability.sql`
- `20261119014733_make_profile_avatars_private.sql`

**Required:** reconcile every applied migration against its source, restore missing migration files, correct version/name mismatches safely, and verify a clean rebuild on a separate development database before production deployment.

### 7. Child-data privacy and security

- Profile photos are now private and served through short-lived signed URLs.
- Profile table update permissions are restricted to editable columns and the own-profile RLS policy.
- Direct-message UPDATE access has been removed.
- Supabase Security Advisor still reports **Leaked Password Protection Disabled**. Enable it in Supabase Auth password security settings.
- The app still needs end-to-end authorization tests for student, parent, tutor, staff, admin and owner roles, including negative tests proving users cannot read another learner's private data.

### 8. Performance and architecture

Supabase Performance Advisor currently reports:
- 27 foreign keys without covering indexes;
- 8 RLS policies with avoidable auth-function re-evaluation;
- 27 multiple-permissive-policy warnings;
- 20 unused indexes (these may simply be unused because the project has little real traffic; do not remove them without workload evidence).

The primary app implementation is concentrated in a very large `main.dart` file. This is maintainability debt and increases regression risk. Refactor by feature after the workflows are covered by tests, not as a blind rewrite.

## Next remediation order

1. Finish and verify the private profile-photo workflow on web and Android.
2. Reconcile migration history and establish a reproducible development database.
3. Add role-based integration tests and negative authorization tests.
4. Build the classroom PIN access workflow and connect it to payment approval.
5. Populate and verify the first learning programme, lessons, resources and CBT question bank.
6. Complete Android release signing and iOS/TestFlight setup.
7. Resolve high-value database performance warnings and enable leaked-password protection.
8. Update user documentation and publish a release checklist.

## Verification boundary

CI build success proves that the code compiles and the current widget test passes. It does not prove that every live Supabase workflow has been exercised by a real student, parent, tutor or administrator account. Those end-to-end checks remain open.
