# Young Learners Tutorial — Application User Guide

**Tagline:** Every Child Can Learn.  
**Document date:** 19 November 2026

This guide explains the current application navigation and the main workflows for learners, parents/guardians, tutors, staff, administrators and the owner. Available pages depend on the signed-in role and assigned permissions.

## 1. Getting started
1. Open the Android app or browser preview.
2. Choose **Sign Up** and enter the requested account details, or choose **Sign In** with an existing account.
3. Use the account type that applies to you. Administrator, tutor and parent privileges must be assigned or verified by authorised centre personnel; they are not granted simply by creating an account.
4. Learners should select the correct class level when prompted or when class setup is available.
5. Use the bell icon for notifications. Open **Profile** to view account details, switch light/dark appearance or sign out.

## 2. Main navigation
- **Home:** Main landing page, welcome area, centre information and announcement billboard. Role-specific shortcuts may be shown.
- **Learning:** Learning programmes, classrooms, lessons, assignments, examination preparation, attendance and messaging options available to the account.
- **Analytics:** Learner activity and progress; parent accounts are directed to the parent dashboard, while the owner can view centre overview information.
- **Profile:** Account name, email, account type, appearance setting and sign-out control.
- **Refresh:** Pull down on pages with a refresh indicator to reload current records.

## 3. Learner workflow
### Request programme access
1. Open **Learning Programmes**.
2. Review the available programme, class level and fee.
3. Select a programme and submit the request.
4. Follow the centre's displayed payment instructions and submit the requested payment reference/evidence.
5. Wait for an administrator to review and approve the request. Classroom access is made available according to the approved programme.

### Use a classroom
1. Open **Classrooms** and choose an active classroom available to your approved programme.
2. Review the **Class Signboard**, published lessons and assignments.
3. Open a lesson to read notes, check the schedule, open a live-class link if provided and access available learning materials.
4. Mark the lesson completed after studying it.
5. Open **My Assignments**, check instructions and due date, submit the work and review tutor feedback.
6. Open **My Attendance** to view recorded attendance.
7. Open **My Released Results** to see results published by the centre, including subject scores, grades, remarks and available teacher comments.

### Assessments and examination preparation
Use available practice questions and timed assessments, and submit before the time limit. The examination-preparation directory covers relevant Nigerian examinations such as WAEC, NECO, JAMB, NABTEB, NBAIS and entrance examinations. It is a learning resource, not an official registration portal.

### Message the Centre
Use **Message the Centre** where available to send a private message to authorised centre staff. Do not share passwords or one-time codes in chat.

## 4. Parent / guardian workflow
1. Register using **Parent / Guardian** where offered.
2. Submit a child-link request using the learner's registered details and relationship information.
3. Wait for the centre to verify the relationship.
4. Open the parent dashboard and select a verified linked child.
5. Review the child's available progress, attendance, assignments, published results and academic updates. Multiple children can be linked after each relationship is verified.

Parents should only see children whose links have been approved by the centre.

## 5. Tutor workflow
- Sign in with the account authorised by the centre.
- Confirm that assigned classes and subjects appear. If not, contact the administrator.
- Open an assigned classroom to view the class board, lessons, assignments and resources.
- Prepare lessons with a title, description, notes, subject, class, schedule and optional live-class link; publish when ready.
- Create assignments, review submissions, enter marks and feedback, or return work for correction.
- For attendance, choose the class and date, mark learners present, absent, late or excused, then save.
- Tutors should only access classes and learners assigned to their tutor account.

## 6. Administrator dashboard
Sign in with an authorised administrator account and open **Centre Portal** from Home. The owner sees **Owner Portal**. Menu items are permission-based; an administrator may not see every module.

### Dashboard overview
Live counts summarise records such as students, tutors, classes, lessons and announcements. A dash can mean that the account lacks permission to read the count or that data is unavailable.

### Learning Access & Payments
Create or maintain programmes, set class level, price and duration, configure payment instructions, review submitted payment details and approve or reject learner requests. Add an admin note where clarification is needed.

### Registered Accounts
Search and review registered learner, parent and staff accounts.

### Parent Link Requests
Review the submitted learner details and relationship. Verify before approving or rejecting a parent-child link.

### Student Records
Search by learner name, email or class. Records are grouped by Primary, JSS and SS levels. Open a learner profile to review programme/payment history, attendance, assignment submissions, assessment activity and results. Use the spreadsheet icon to export an Excel-compatible student directory.

### Results & Report Cards
1. Select a class, subject and result period (for example, First Term).
2. Enter an academic-year label and the maximum CA and examination marks.
3. Load the class register and enter each learner's CA and examination scores. Totals and grades calculate automatically.
4. Save the scores. Repeat for the other subjects using the same result period.
5. Add class-teacher and head-teacher/coordinator comments where required.
6. Generate the learner's PDF report card.
7. Check that all required subjects and marks are present, then use **Save and release results**. Published results become visible to learners and linked parent views.

Report cards contain only marks that have actually been entered and saved. Do not release incomplete or unchecked results.

### Staff Room
Use internal staff conversations and coordinator announcements. Attachments can be shared where the attachment control is available.

### Centre Communications / Dashboard Update Board
1. Create an announcement title and message.
2. Choose whole-platform or class targeting.
3. Select a notice tone/colour.
4. Optionally attach a document or media file.
5. Set an expiry date and, if needed, enable personal notifications for affected learners.
6. Publish the update. Active notices rotate on the Home billboard, headlines animate with a typing effect, and users can move between notices using the arrows. Expired notices stop displaying.

### Learning Setup
Manage classes, subjects, lessons and assessments. Create or edit classes and subjects, add lesson content and schedules, publish lessons or return them to draft, and manage assessment settings and question banks.

### Class Attendance
Select a class and date, mark each learner's attendance status and save the register.

### Tutor Interview Centre
Review tutor applications, shortlist candidates and schedule interviews. This is an application/review workflow, not an automated AI interviewer.

### Staff Directory and Tutor/Staff Management
Maintain staff records, add tutors or staff, link authorised accounts and assign tutors to classes and subjects.

### Centre Reports & Analytics
Review centre activity such as learner access, payments, attendance, assignment activity and CBT activity, subject to report permissions.

### Administrator Access (Owner only)
Authorise administrator accounts, configure permission sets and revoke access. Grant only the permissions required for each person's duties. Never share the owner's login.

## 7. File uploads and private messaging
- Depending on the page, supported files include PDF, Word, Excel, PowerPoint, TXT, CSV, RTF, images and video.
- Attachments are available in classroom resources, Staff Room messages, centre announcements and private learner-to-centre messages where the attachment control appears.
- General platform and private-chat attachments: **up to 50 MB per file**. Classroom resources: **up to 100 MB**.
- Learners open **Message the Centre**. Administrators open **Student Records**, search for a learner, open the profile and use the chat action. Access is limited to the learner and authorised staff.
- Some private attachments open through temporary secure links.

## 8. Security and good practice
- Use a strong unique password, sign out on shared devices and never share passwords or one-time codes.
- Student records, parent links, private messages and report cards contain personal information. Access or export them only for authorised work.
- Check class, recipient, payment reference, marks and expiry dates before saving or publishing.
- A working internet connection is required for sign-in and synchronising records, messages, uploads and results.

## 9. Scope and release notes
- The application is built with Flutter and uses Supabase for authentication, database records, file storage and access controls. The same application code supports Android and a browser-based web preview.
- The examination-preparation area is not an official examination registration portal.
- A separate paid classroom PIN workflow has been discussed as a future enhancement. Do not promise a student-issued PIN unless it is implemented and verified in the submitted release.
- Before using real children's records, test each role with separate accounts, verify parent links and administrator permissions, confirm payment procedures and test the release build on target devices.

## 10. Quick workflows
- **Learner:** Register → select class → request programme → follow payment instructions → await approval → open classroom → study → submit assignments → view released results.
- **Parent:** Register → request child link → await verification → open parent dashboard → select child → review progress and results.
- **Tutor:** Sign in → confirm assigned classes → publish lessons → share resources → create and mark assignments → record attendance → provide feedback.
- **Administrator:** Sign in → Centre Portal → review programme/payment requests → verify parent links → manage learner records → configure learning content → publish updates → record attendance → enter/release results → review reports.
- **Owner:** Sign in → Owner Portal → oversee centre activity → manage programmes/payment settings → configure administrator permissions → monitor communications, academic records and reports.
