-- Cache auth.uid() once per statement in frequently evaluated own-row policies.
drop policy if exists students_read_own on public.students;
create policy students_read_own on public.students
for select to authenticated
using (user_id = (select auth.uid()));

drop policy if exists enrolments_read_own on public.enrolments;
create policy enrolments_read_own on public.enrolments
for select to authenticated
using (exists (
  select 1 from public.students s
  where s.id = enrolments.student_id
    and s.user_id = (select auth.uid())
));

drop policy if exists submissions_read_own on public.assignment_submissions;
create policy submissions_read_own on public.assignment_submissions
for select to authenticated
using (exists (
  select 1 from public.students s
  where s.id = assignment_submissions.student_id
    and s.user_id = (select auth.uid())
));

drop policy if exists attempts_read_own on public.assessment_attempts;
create policy attempts_read_own on public.assessment_attempts
for select to authenticated
using (exists (
  select 1 from public.students s
  where s.id = assessment_attempts.student_id
    and s.user_id = (select auth.uid())
));

drop policy if exists invoices_read_own on public.invoices;
create policy invoices_read_own on public.invoices
for select to authenticated
using (exists (
  select 1 from public.students s
  where s.id = invoices.student_id
    and s.user_id = (select auth.uid())
));

drop policy if exists payments_read_own on public.payments;
create policy payments_read_own on public.payments
for select to authenticated
using (exists (
  select 1
  from public.invoices i
  join public.students s on s.id = i.student_id
  where i.id = payments.invoice_id
    and s.user_id = (select auth.uid())
));

drop policy if exists notifications_read_own on public.notifications;
create policy notifications_read_own on public.notifications
for select to authenticated
using (user_id = (select auth.uid()));

drop policy if exists notifications_update_own on public.notifications;
create policy notifications_update_own on public.notifications
for update to authenticated
using (user_id = (select auth.uid()))
with check (user_id = (select auth.uid()));
