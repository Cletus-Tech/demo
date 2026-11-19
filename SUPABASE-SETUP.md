# Supabase setup — Young Learners Tutorial

The education app is connected to the Supabase project in the user's `demo` organisation.

## Client configuration
The Flutter app uses the project URL and the **publishable** API key through Dart build defines. The publishable key is designed for client use. Never place a Supabase secret or service-role key in Flutter, web assets, GitHub Actions build arguments or a public repository.

## New account behaviour
- A user signs up with full name, email and password.
- Supabase Auth creates the account.
- A database trigger creates the matching `profiles` row.
- A second row in `user_roles` assigns `external_learner`.
- The user cannot select an administrator, tutor, guardian or student role during self-registration.
- The user can read their own profile and role. They can update only their own name, phone and avatar URL.

## Centre administration
A trusted administrator must provision verified student, guardian and tutor records and assign their roles. Do not use editable user metadata as an authorisation source. Do not grant guardian access until the child relationship is verified.

## Security status
RLS is enabled across the education schema. At the time of this report, the security advisor still identifies 24 tables without policies. Those tables must remain unavailable to client roles until table-specific access policies have been implemented and tested.

## Build commands
```sh
cd apps/mobile
flutter pub get
flutter test
flutter run
flutter build apk --release
flutter build web --release --base-href /demo/
```

## Production requirements
Before entering real learner records: implement and test RLS for every table; configure email confirmation and reliable SMTP; add password recovery; verify guardian-child links; test tutor class scoping; review assessment answer-key access; and establish backups and incident response.
