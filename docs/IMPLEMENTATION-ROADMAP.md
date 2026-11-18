# Implementation roadmap

## Phase 1 — Android foundation
- Flutter app shell and brand system.
- Authentication and role-aware navigation.
- Student dashboard and account profile.
- Supabase connection using a publishable key supplied through build configuration.
- First APK artifact for review.

## Phase 2 — Centre operations
- Student, guardian and tutor records.
- Guardian-to-student links with consent and safeguarding checks.
- Classes, subjects, terms, enrolments and timetables.
- Attendance and announcements.

## Phase 3 — Learning
- Lessons, downloadable materials and progress tracking.
- Assignments, submissions, grading and tutor feedback.
- CBT question banks, timed attempts and results.
- Low-bandwidth caching and safe sync.

## Phase 4 — Parent and tutor portals
- Parent multi-child overview, reports, fees and attendance.
- Tutor class workspace, resources, attendance, marking and feedback.

## Phase 5 — Virtual and commercial services
- Virtual classroom integration.
- External learner catalogue and enrolment.
- Payment provider integration after business details and settlement account are configured.

## Phase 6 — Web, iOS and Windows
- Public admissions website and web admin portal.
- iOS and Windows builds from the shared Flutter app.
- Release signing, store preparation, monitoring and backups.

## Security requirements
- RLS enabled for every exposed table.
- Explicit least-privilege grants; do not rely on automatic Data API exposure.
- Roles assigned by trusted server-side administration, never user-editable profile metadata.
- Parent access only to verified linked children.
- Tutors access only to assigned classes and learners.
- Audit sensitive admin actions.
- No public directory of minors; controlled communication and consent.
- Secrets stay in server-side configuration and GitHub Actions secrets.
