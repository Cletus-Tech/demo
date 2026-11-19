# Young Learners Tutorial — Application Guide

**Product:** Young Learners Tutorial  
**Tagline:** Every Child Can Learn.  
**Learner levels:** Primary 1–6, JSS 1–3 and SS 1–3  
**Document purpose:** Explain the product, its users, major workflows, technology and current preview boundaries.

## 1. Product overview

Young Learners Tutorial is a digital tutorial and learning platform for Nigerian learners. It is designed to connect learners with lessons, learning materials, classroom activities, assignments, assessments and academic feedback while giving parents, tutors and centre administrators the tools they need to support that learning.

The platform is intended to support learning outside the traditional classroom and to help a tutorial centre coordinate its academic and administrative activities.

It is not a formal school-management platform, an examination board, or a JAMB/WAEC/NECO registration portal. It does not issue official examination certificates.

## 2. Learner categories

The academic structure covers:

- **Primary:** Primary 1, Primary 2, Primary 3, Primary 4, Primary 5 and Primary 6.
- **Junior Secondary:** JSS 1, JSS 2 and JSS 3.
- **Senior Secondary:** SS 1, SS 2 and SS 3.

The centre is responsible for maintaining the active class and subject catalogue and assigning relevant learning programmes, tutors and resources.

## 3. User roles and responsibilities

### Learner
A learner signs in to their own account and uses the academic areas made available to that account. Depending on class and access approval, the learner can:
- View their class and available subjects.
- Request access to a learning programme.
- Redeem an issued classroom PIN.
- Open published lessons and classroom resources.
- Read classroom notices and updates.
- View assignments and classwork, submit work and read tutor feedback.
- Practise through available CBT/assessment content.
- View results after the centre releases them.
- Receive in-app notifications.

Learners must not be able to view another learner's private profile, submissions, results or access records.

### Parent or guardian
A parent/guardian account is linked to a learner through the centre's verification process. Once linked and authorised, the parent/guardian can view permitted child information such as progress, assignments, attendance, released results and classroom updates. A guardian account is not a learner account and should not inherit unrestricted learner or administrator permissions.

### Tutor
A tutor is reviewed and approved by the centre. Approved tutors work only with the classes and subjects assigned to them. Their work areas support:
- Assigned class and subject views.
- Classroom resources and updates.
- Attendance activities.
- Assignment and classwork creation.
- Learner submission review, marking and feedback.

Tutor access must remain limited to assigned classes and subjects.

### Staff and administrator
Centre staff access depends on the permissions granted to their account. Administrative areas support the management of:
- Learner profiles and class records.
- Classes and subjects.
- Learning programmes and access requests.
- Payment review and classroom PIN issuance.
- Tutor applications and assignments.
- Lessons, classroom content and resources.
- Assignments, assessments and results.
- Attendance, announcements and notifications.
- Centre communication and operational records.

Not every staff member should automatically receive every administrator permission.

### Owner
The owner oversees the centre, administrator accounts and permission allocation. Owner-level access is intended for trusted account holders only.

## 4. Core workflows

### 4.1 Programme access and classroom PIN

The current access model uses manual centre review:

1. The learner chooses a programme and submits an access request.
2. The learner follows the payment instructions provided by the centre.
3. The learner submits payment information/evidence through the app.
4. An authorised administrator reviews the request and records approval or rejection.
5. For an approved request, an authorised administrator issues a unique classroom PIN.
6. The learner receives the PIN from the centre and redeems it in the app.
7. Successful redemption unlocks the approved programme's permitted classroom content.

Security notes:
- Payment evidence is reviewed manually; this is not an automated payment gateway.
- PINs are stored as hashes rather than plaintext.
- The plaintext PIN is returned to the authorised administrator at issuance; it should be delivered privately to the intended learner.
- Redemption is tied to the approved request and learner.
- Revoked, already-used or invalid passes must not grant access.
- A learner's redeemed pass must not expose another learner's programme or classroom data.

### 4.2 Lessons and learning resources

Administrators/tutors with the relevant permission publish lessons and resources to the appropriate class/programme. Learners see only content published and authorised for their access. Some resources may be stored privately and opened through protected links.

### 4.3 Assignments and classwork

Tutors or authorised staff publish work for the relevant class. Learners view their own work and submit responses. Tutors review submissions, record marks and feedback, and may return work for correction where the workflow supports it. Student records should reflect only the learner's own results and authorised academic history.

### 4.4 CBT and assessments

The platform includes assessment and question-bank infrastructure for practice and evaluation. Actual availability depends on the centre adding questions, configuring assessments and publishing them. A screen or menu existing in the app does not mean a usable question set has already been loaded.

### 4.5 Attendance

Attendance tools support centre/tutor recording and permitted learner/guardian viewing. Attendance history depends on the centre creating and maintaining attendance records.

### 4.6 Results

The centre manages result periods and result records. Results are visible to learners and linked guardians only when the relevant result period has been released and the account is authorised.

### 4.7 Announcements and notifications

Centre announcements are published to the dashboard. In-app notifications can show an unread badge and open the relevant destination when the notification is linked to a supported update or workflow. Native push notification delivery is not currently configured; users receive notifications inside the app.

## 5. Design and user experience

The visual identity uses a professional brown, warm gold and cream palette, with a dark theme option. The interface is intended to be clear and approachable for learners while remaining suitable for parents, tutors and centre staff.

The application is built with Flutter. The current web build is intended for browser-based preview and can be opened on desktop or mobile browsers. A browser preview is not the same as a signed native iOS application.

## 6. Technical architecture

### Client
- Flutter and Dart.
- Responsive layouts for web and mobile form factors.
- Android release-mode APK build workflow.
- Flutter web build workflow.

### Backend
- Supabase Authentication for user identity and sessions.
- PostgreSQL for application records.
- Row Level Security policies and SQL grants for access boundaries.
- Supabase Realtime for selected live updates.
- Supabase Storage for uploaded files and protected assets.
- Database functions/RPCs for selected privileged workflows.

### Security principles
- Use the publishable client key in the app; never embed a service-role key.
- Keep privileged operations behind permission checks and database policies/functions.
- Apply least-privilege table/column grants and RLS.
- Keep private files in private buckets and use short-lived signed URLs where required.
- Test both allowed and denied access for each role.
- Never rely only on hiding a button in the UI to protect data.

## 7. Current preview limitations

The client preview should be treated as a controlled review build, not a public production launch.

Known boundaries:
- Programme payments are manually reviewed; no live payment gateway is configured.
- Learning programmes, published lessons, materials, assessment questions, assignments, attendance and results must be populated by the centre before those features can demonstrate their full value.
- In-app notifications are implemented; native push delivery is not configured.
- Android APKs are available for QA/sideload testing; production signing and Play Store release configuration remain outstanding.
- iOS IPA/TestFlight signing and distribution are not configured. The web preview is the browser-based option for iPhone review.
- Role-based end-to-end testing and cross-account privacy testing remain necessary.
- Supabase migration history must be reconciled with the branch's migration source files before routine production migration deployment.
- Privacy policy, terms and child-data handling documentation must be completed before public launch.

## 8. Preview reviewer checklist

A client reviewing the preview should focus on:
- Whether the app opens and displays correctly on their device/browser.
- Whether the navigation and screen labels are understandable.
- Whether the learner, guardian, tutor and administrator journeys make sense.
- Whether the programme request and classroom PIN instructions are clear.
- Whether the classroom, lesson, assignment, result and notification screens are easy to understand.
- Any layout problems, confusing wording, dead controls, errors or slow-loading areas.

The reviewer should use only the test account and access details supplied specifically for the preview. Do not share administrator credentials or real children's personal information for demonstration.

## 9. Feedback and issue reporting

For every issue, record:
1. The account role being used (learner, guardian, tutor, staff or administrator).
2. Device and browser/app version.
3. The screen or feature.
4. The steps taken immediately before the issue.
5. What was expected.
6. What actually happened.
7. A screenshot or screen recording, with private learner information hidden.

## 10. Release-readiness statement

The project has a working Flutter codebase, Supabase integration and automated Android/web build workflows. Successful CI builds confirm compilation and the automated checks included in those workflows. They do not certify every feature as fully tested.

The project should move from client preview to public release only after the outstanding content, security, migration, role-based end-to-end, privacy/legal and native distribution requirements have been completed.
