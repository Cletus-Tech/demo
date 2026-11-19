# Young Learners Tutorial

**Every Child Can Learn.**

Young Learners Tutorial is a learning and tutorial-management platform designed for Nigerian learners from **Primary 1 to SS3**. It brings learners, parents and guardians, tutors, centre staff and administrators into one connected learning environment.

The platform supports guided learning, classroom resources, assignments, assessments, student progress and communication. It is a tutorial service—not a formal school, school-management system, or examination-registration body.

## Project at a glance

| Item | Details |
|---|---|
| Product | Young Learners Tutorial |
| Tagline | Every Child Can Learn. |
| Learner range | Primary 1–6, JSS 1–3, SS 1–3 |
| Application | Flutter (Android and web preview) |
| Backend | Supabase (Auth, PostgreSQL, Row Level Security, Realtime and Storage) |
| Active development branch | `young-learners-foundation` |
| Repository | [Cletus-Tech/demo](https://github.com/Cletus-Tech/demo) |
| Current web preview | [Open the web preview](https://cletus-tech.github.io/demo/) |

## Who uses the platform?

- **Learners** access their class, approved learning programmes, lessons, resources, assignments, CBT practice, released results and notifications.
- **Parents and guardians** can link to a learner through the centre's verification process and view the child's permitted learning information.
- **Tutors** work with their assigned classes and subjects, share classroom resources, manage attendance, set assignments and review learner submissions.
- **Centre staff and administrators** manage learner records, classes, subjects, programme requests, classroom access, results, announcements and tutor applications according to their permissions.
- **The owner** oversees the centre and administrator permissions.

Role permissions are enforced through application checks and Supabase Row Level Security. The actual access granted depends on the signed-in account and its approved role.

## Main application areas

### Learning and classroom
- Class and subject organisation for Primary, Junior Secondary and Senior Secondary levels.
- Learning programme access and published lessons.
- Classroom updates, learning resources and lesson links.
- Assignments and classwork, learner submissions, tutor marking and feedback.
- CBT practice and question-bank infrastructure.
- Learning progress and released results.

### Centre operations
- Learner, class and subject records.
- Tutor applications and administrator review.
- Tutor class/subject assignments.
- Attendance workflows.
- Programme/payment request review and classroom PIN issuance.
- Results management and release.
- Announcements, notifications and communication tools.
- Staff and administration work areas.

### Parent and guardian access
- Verified parent/guardian-to-learner linking.
- Permitted child progress, attendance, assignment and result views.
- Classroom information where the account is authorised.

See [the application guide](docs/APP_OVERVIEW.md) for the fuller feature and role explanation.

## Learning access and payment process

The current programme-access process is a **manual review workflow**:

1. A learner submits a request for a learning programme.
2. The learner follows the centre's displayed payment instructions and submits the required payment evidence/details.
3. An authorised administrator reviews the request and records the decision.
4. Once approved, an authorised administrator issues a unique classroom access PIN.
5. The learner redeems the PIN in the app to unlock the approved programme's classroom resources.

This is not automated payment-gateway verification. A payment submission is not treated as confirmed until the centre has reviewed it. PINs are stored as hashes; the issued plaintext PIN is shown to the authorised administrator at issuance and must be passed securely to the learner.

## Technology

- **Flutter / Dart** — application UI and Android/web builds.
- **Supabase Auth** — sign-in and session management.
- **Supabase PostgreSQL** — application data.
- **Row Level Security (RLS)** — database-level access controls.
- **Supabase Realtime** — live in-app updates such as notification changes.
- **Supabase Storage** — uploaded and protected learning/profile files.

The client application uses a Supabase publishable/anonymous key. Never put a Supabase service-role key or other privileged secret in Flutter source, web assets, or a public repository.

## Preview and build links

- [Web preview](https://cletus-tech.github.io/demo/)
- [Android build workflow](https://github.com/Cletus-Tech/demo/actions/workflows/android-apk.yml)
- [Web preview workflow](https://github.com/Cletus-Tech/demo/actions/workflows/ios-web-preview.yml)
- [Repository functionality audit](docs/FUNCTIONALITY_AUDIT_2026-11-19.md)
- [First-release readiness audit](docs/FIRST_RELEASE_AUDIT.md)

The Android workflow produces architecture-specific release-mode APKs for controlled installation and QA. It is not yet a production-signed Google Play release. An iOS IPA/TestFlight pipeline is not configured. The web build can be opened in a mobile browser, including Safari on iPhone, but it is not a native iOS app.

## Development setup

Install the Flutter stable SDK and ensure Flutter is available on your PATH.

```bash
cd apps/mobile
flutter pub get
flutter test
flutter run
```

Build locally:

```bash
# Android
flutter build apk --release

# Web
flutter build web --release
```

The CI workflows supply the Supabase URL and publishable key using Dart compile-time defines. For a local build, provide the same public client configuration through your local environment/build command. Do not commit privileged secrets.

## Preview and release status

This project is being prepared for a controlled client preview. A successful CI build confirms that the code compiles and the automated tests in that workflow pass; it does not prove that every live workflow has been tested with real learner, guardian, tutor and administrator accounts.

Before a public launch, the project still requires:
- Complete role-based end-to-end and cross-account permission testing.
- A populated and quality-checked learning catalogue, lesson resources and CBT question bank.
- Reconciliation of the live Supabase migration history with the repository migration files.
- Supabase Auth leaked-password protection to be enabled.
- A documented privacy policy, terms and child-data handling process.
- Production Android signing and store-release configuration.
- iOS project signing and IPA/TestFlight configuration if a native iOS app is required.

Read [the first-release audit](docs/FIRST_RELEASE_AUDIT.md) and [the client preview guide](docs/CLIENT_PREVIEW.md) before sharing a preview.

---

**Product promise:** Every Child Can Learn.
