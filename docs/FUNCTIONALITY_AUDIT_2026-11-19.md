# Young Learners Tutorial — Repository and functionality audit

**Audit date:** 19 November 2026  
**Audit status:** In progress — first verified defect fixed; full role-based audit remains open.  
**Application branch:** `young-learners-foundation`  
**Supabase project:** `lvpetmhhspuagbjojlks`

## Repository / branch findings

- The repository has six branches: `main`, `young-learners-foundation`, `work/dashboard-foundation-review`, `work/full-functionality-upgrade`, `laravel-conversion-from-original-demo`, and `laravel-native-starter`.
- `main` remains the original Demo Broker project. Young Learners Tutorial is developed separately on `young-learners-foundation`; the two branches have diverged.
- Pull request #5 (Young Learners Tutorial) is still open and marked draft. Its description is stale: it says Supabase integration is not enabled, while the current app source does initialise Supabase and calls live tables/RPCs.
- The Laravel and older work branches are separate Demo Broker work. They must not be merged into the tutorial app without a deliberate migration plan.
- Do not merge or force-reset branches as part of this audit.

## Verified architecture / test gaps

- `apps/mobile/lib/main.dart` is a very large single source file (approximately 7,800 lines) containing navigation, role screens, Supabase calls, classroom workflows and dashboard features. This concentration makes cross-feature regressions harder to isolate.
- The current Flutter test file had only one sign-in-screen smoke test. It did not test classroom access, payments, assignments, results, notifications, tutor/parent flows or authorization boundaries.
- The Android workflow runs `flutter test` and builds release APKs, but does not run `flutter analyze`. A successful APK build is not proof that user journeys work.
- The web workflow is a web preview/deployment workflow, not an iOS IPA/TestFlight build.
- The live app has real Supabase calls, but the test suite does not mock or exercise these flows.

## Classroom PIN defect — identified and fixed in source

**Root cause:** `classroom_access_passes.request_id` is UNIQUE, making the relationship from `learning_access_requests` to `classroom_access_passes` one-to-one. PostgREST returns a single JSON object for this relationship. The learner classroom directory treated the related value as a List only:

```dart
if (passes is! List) return false;
```

Consequently, a valid approved request with a redeemed PIN could still be rejected by the app's classroom-directory filter. The live database currently contains one approved SS 3 access request with a redeemed, non-revoked pass, so this was a real mismatch between the data shape and the UI assumption.

**Correction committed to `young-learners-foundation`:**
- Added `hasRedeemedClassroomPass`, which accepts both the correct one-to-one Map shape and a List shape.
- Updated `ClassroomDirectoryPage` to use the shared predicate.
- Added regression tests for one-to-one Map, List, missing, unredeemed and revoked pass values.
- CI runs for the code/test change are pending; do not call the fix build-verified until they complete.
- The user must still verify the result in an authenticated student session on a device.

## Classroom pass data and permissions

- Live data check: one approved access request; it points to the active SS 3 class and has a redeemed, non-revoked pass.
- The original migration grants only the four pass columns needed by the classroom directory (`request_id`, `user_id`, `redeemed_at`, `revoked_at`) and keeps `pin_hash` and `failed_attempts` inaccessible.
- During diagnosis, a table-level SELECT grant was briefly applied based on an incorrect interpretation of `has_table_privilege`. It was promptly revoked and the intended column-level grants were restored. Verified: no broad table SELECT; the directory's redemption columns are readable; PIN hashes and attempt counters are not readable by authenticated clients.
- A new corrective migration is committed to preserve this least-privilege state.

## Other connected-workflow observations

- Payment submission and review are manual bank-transfer workflows. Approval and PIN issuance are separate operations: the approval RPC changes the request to approved and notifies the learner; an authorised staff member then issues the PIN. This is a deliberate manual checkpoint in the current implementation, not automatic payment-gateway confirmation.
- Classroom page loading currently groups lessons, posts and assignments into one `Future.wait`. If any one request fails, the entire classroom content future fails. This is a resilience defect to address after the PIN-directory correction is verified.
- The classroom page and lesson/material access policies must be tested with actual student, tutor and administrator identities; service-role SQL inspection cannot prove client RLS behaviour.

## Required audit coverage

1. Authentication, account creation, session persistence, password reset and account type.
2. Student profile and class selection.
3. Programme request → payment submission → review → PIN issuance → PIN redemption → classroom directory → classroom content.
4. Lesson publishing, completion, attachments and private media access.
5. Tutor application → approval → class/subject assignment → tutor workspace.
6. Assignments/classwork → submission → marking/feedback → student record.
7. CBT/question bank → attempt → scoring → history/feedback.
8. Attendance → tutor/admin register → student/parent history.
9. Results → release → student and parent visibility.
10. Parent verification/linking → child progress and classroom visibility.
11. Dashboard announcements → notification generation → notification badge → exact destination.
12. Messaging, staff room, files, countdowns and admin content management.
13. RLS, SQL grants, RPC execute grants, storage policies and negative cross-account tests.
14. Build/release workflows, branch/PR alignment and migration source drift.

## Verification boundary

This is an initial audit snapshot, not a final sign-off. A workflow is complete only after source review, database review, automated tests and authenticated role-based end-to-end verification. No public-launch readiness is claimed.
