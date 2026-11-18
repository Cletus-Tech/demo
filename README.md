# Young Learners Tutorial

**Every Child Can Learn.**

A cross-platform tutorial-centre and learning platform for students, parents/guardians, tutors, centre administrators and external learners.

## Current build
The first Flutter foundation is in `apps/mobile`. The first review target is Android APK; iOS, Windows and Web follow from the same Flutter app, with a separate web administration portal planned as the platform grows.

## Product areas
- Student learning: subjects, lessons, materials, classes, assignments, CBT, results and progress.
- Parent portal: linked children, attendance, academic reports, fee/payment status and announcements.
- Tutor workspace: classes, teaching materials, attendance, assignments, grading and feedback.
- Centre administration: enrolment, users, classes, academic sessions, timetable, assessments, finance and reporting.
- External learners: public course discovery and enrolment.
- Hybrid delivery: physical classes, virtual classes and self-paced learning.

## Brand
Deep brown, golden yellow and warm cream. Tagline: **Every Child Can Learn.**

## Development
Install Flutter stable, then:
```sh
cd apps/mobile
flutter pub get
flutter run
flutter test
flutter build apk --debug
```

## Backend and security
The intended backend is the existing Supabase project in the **demo** organisation. No production database migration is applied by this starter. Before connecting real users, the schema will be reviewed and built with explicit Data API grants, Row Level Security on exposed tables, role-based access, parent/guardian relationships, auditability and child-safety controls. Never put a Supabase service-role key in a mobile or web client.

## Build status
This repository branch is a foundation, not a finished production platform. Authentication, role provisioning, database migrations, payment integrations, virtual classrooms and offline sync are subsequent implementation milestones.
