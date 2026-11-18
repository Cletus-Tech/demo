drop policy if exists invoices_student_admin_read on public.invoices;
create policy invoices_student_admin_read on public.invoices
for select to authenticated
using (private.has_permission('students.manage'));

drop policy if exists payments_student_admin_read on public.payments;
create policy payments_student_admin_read on public.payments
for select to authenticated
using (private.has_permission('students.manage'));
