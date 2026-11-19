# Young Learners Tutorial

**Every Child Can Learn.**

Young Learners Tutorial is a cross-platform tutoring and learning platform for Nigerian learners from Primary 1 to SS3, with separate experiences for learners, parents/guardians, tutors, staff, centre administrators and the owner.

## Product areas

- **Learner:** class profile, learning programmes, lessons and resources, classroom, assignments, timed CBT, question bank, results, progress and notifications.
- **Parent / guardian:** verified child linking, child learning progress, assignments, attendance, released results and classroom updates.
- **Tutor:** assigned classes and subjects, classroom resources, attendance, assignments, student submissions and marking.
- **Centre team:** student records, classes, subjects, learning programmes, access/payment review, results, announcements, staff room and tutor applications.
- **Owner:** centre overview, administrator access and permission management.

The product is a tutorial platform, not a formal school-management or examination-registration system.

## Brand and interface

- Deep brown, warm gold and cream; optional dark theme.
- Tagline: **Every Child Can Learn.**
- Responsive Flutter application.

## Current review targets

- Web preview: https://cletus-tech.github.io/demo/
- Android release workflow: https://github.com/Cletus-Tech/demo/actions/workflows/android-apk.yml
- Web preview workflow: https://github.com/Cletus-Tech/demo/actions/workflows/ios-web-preview.yml
- First-release audit: [docs/FIRST_RELEASE_AUDIT.md](docs/FIRST_RELEASE_AUDIT.md)

The Android workflow currently produces QA/sideload APK artifacts. Production signing and Play Store release configuration are not complete. An iOS IPA/TestFlight workflow is not yet configured.

## Backend

The live backend uses Supabase for authentication, Postgres, Row Level Security, Realtime and Storage. Exposed application tables have RLS enabled. Do not put a Supabase service-role key in a client application.

**Important:** the live database migration history and the migration files in this branch still need reconciliation. Do not run a production reset or blanket `supabase db push` until the first-release audit's migration-reconciliation task is complete.

## Current feature boundaries

- Learning access currently uses administrator-reviewed programme/payment requests. The planned unique classroom PIN workflow has not yet been implemented.
- Payments currently use a manual submission and administrator review process; no live payment gateway is configured.
- Lessons, programmes, learning materials, assessments and CBT questions must be configured by the centre before learners can use those areas meaningfully.
- Notifications are available in the app; native push-notification delivery is not configured.

## Local development

Install Flutter stable, then:

```sh
cd apps/mobile
flutter pub get
flutter run
flutter test
flutter build apk --debug
```

See [docs/FIRST_RELEASE_AUDIT.md](docs/FIRST_RELEASE_AUDIT.md) for the current release-readiness findings and remediation order.
