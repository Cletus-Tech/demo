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
- The Android release workflow completed successfully for commit `933dc4d8cef327b3a2643412fefb9344b2cb63a2`, and its architecture-specific APK artifact was uploaded. The artifact is a QA/sideload build, not a production-signed Play Store release.
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

### 3. Classroom PIN workflow — Implemented, awaiting end-to-end verification

A first implementation is now connected to the approved payment workflow. An authorised finance/student administrator can issue or reset a unique 10-character classroom PIN for an approved programme request. Only a SHA-256 hash is stored; the plaintext is returned once to the administrator. The learner enters the PIN in the Learning Programmes screen; successful redemption unlocks published lessons for that learner/programme. Failed attempts are capped at five per issued pass, and each programme can have its own pass.

The database migration and learner/admin UI are committed. This workflow still needs authenticated role-based testing (issue, redeem, wrong PIN, reuse, multiple programmes, and cross-account denial) before public release.

### 4. Tutor application → tutor workspace — Connected, awaiting end-to-end verification

The tutor application form already captured selected class levels and subjects, but approval previously created an active tutor account without converting those selections into `class_tutors` records. That left approved applicants with no assigned classrooms. The approval RPC now activates the tutor role and automatically creates matching class/subject assignments from the submitted selections. The administrator receives a result showing how many class/subject combinations were connected; unmatched catalogue selections are explicitly flagged for manual correction. Reversing an approved application also deactivates the tutor record and removes the tutor role.

The review dropdown now includes the initial `submitted` stage, preventing the first review dialog from receiving a value absent from its options.

### 5. Classroom access — PIN enforced across learner surfaces

Learner classroom directory entries now appear only after a classroom PIN has been redeemed. Published classroom posts and learner assignment lists also require a redeemed, non-revoked PIN for the relevant programme/class. Published lessons already use the same gate. Parent supervised classroom access and assigned tutor access remain separate paths.

These are backend and UI connection fixes. They still require authenticated tests for learner, guardian, tutor and administrator roles, including wrong/reused PINs and cross-account access denial.

### 6. Payments — Limited scope

The current workflow is manual payment submission and administrator review. A live payment gateway/automated payment confirmation is not configured. This must be clearly labelled as manual payment in the first release unless a payment provider is integrated.

### 7. Native release packaging — Critical before store release

- Android APK workflow builds release-mode APKs, but no production signing keystore is configured in the workflow. Treat the artifact as a QA/sideload build, not a Play Store-ready signed release.
- No iOS build workflow or IPA/TestFlight configuration is present.
- The Android workflow generates platform scaffolding during CI rather than maintaining a reviewed native project configuration in source control.

**Required:** branded Android application ID, launcher icon/splash, release keystore and signing secrets; iOS project, Apple signing/provisioning and TestFlight workflow.

### 8. Database migration source drift — Critical for reproducible deployment

The live Supabase migration history and repository migration files are not aligned: **60 migrations are applied in Supabase, while this branch contains 46 migration files; 28 applied migration names have no matching source file, 14 local migration files are not represented in the live history, and 25 same-name migrations have different version timestamps.** Do not run a blanket `supabase db push` or reset against production until this is reconciled.

The recent hardening changes are now recorded as migrations:
- `20261119014426_profile_fields_and_message_immutability.sql`
- `20261119014733_make_profile_avatars_private.sql`
- `20261119014912_optimise_own_row_rls_auth_checks.sql`
- `20261119014944_index_uncovered_foreign_keys.sql`

**Required:** reconcile every applied migration against its source, restore missing migration files, correct version/name mismatches safely, and verify a clean rebuild on a separate development database before production deployment. The three new classroom PIN migrations are now present in this branch.

### 9. Child-data privacy and security

- Profile photos are now private and served through short-lived signed URLs.
- Profile table update permissions are restricted to editable columns and the own-profile RLS policy.
- Direct-message UPDATE access has been removed.
- Supabase Security Advisor still reports **Leaked Password Protection Disabled**. Enable it in Supabase Auth password security settings.
- The app still needs end-to-end authorization tests for student, parent, tutor, staff, admin and owner roles, including negative tests proving users cannot read another learner's private data.

### 8. Performance and architecture

Supabase Performance Advisor now reports:
- Foreign-key index warnings have been cleared by migration `20261119014944_index_uncovered_foreign_keys.sql`.
- Own-row RLS auth-function re-evaluation warnings have been cleared by migration `20261119014912_optimise_own_row_rls_auth_checks.sql`.
- 27 multiple-permissive-policy warnings remain; most represent separate admin and own-row access paths and need careful policy review before consolidation.
- 47 unused-index notices remain. Several are newly created FK indexes and may be unused because the app has little real traffic; do not remove them without workload evidence.

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
