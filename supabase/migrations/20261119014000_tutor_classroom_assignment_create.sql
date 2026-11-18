drop policy if exists assignments_tutor_class_insert on public.assignments;
create policy assignments_tutor_class_insert on public.assignments
for insert to authenticated
with check (
  tutor_id = (select auth.uid())
  and exists (
    select 1 from public.class_tutors ct
    where ct.class_id = assignments.class_id
      and ct.tutor_id = (select auth.uid())
  )
);