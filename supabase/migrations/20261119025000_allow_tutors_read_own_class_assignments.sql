drop policy if exists tutors_read_own on public.tutors;
create policy tutors_read_own on public.tutors
for select to authenticated
using (user_id = (select auth.uid()));

drop policy if exists class_tutors_read_own on public.class_tutors;
create policy class_tutors_read_own on public.class_tutors
for select to authenticated
using (
  exists (
    select 1 from public.tutors t
    where t.id = class_tutors.tutor_id and t.user_id = (select auth.uid())
  )
);