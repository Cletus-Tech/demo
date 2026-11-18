drop policy if exists assignments_tutor_class_read on public.assignments;
create policy assignments_tutor_class_read on public.assignments
for select to authenticated
using (
  exists (
    select 1 from public.class_tutors ct
    where ct.class_id = assignments.class_id
      and ct.tutor_id = (select auth.uid())
  )
);