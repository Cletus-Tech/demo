drop policy if exists attendance_read_own on public.attendance_records;
create policy attendance_read_own on public.attendance_records
for select to authenticated
using (exists (
  select 1 from public.students s
  where s.id=attendance_records.student_id and s.user_id=(select auth.uid())
));
create index if not exists attendance_records_lesson_id_idx on public.attendance_records(lesson_id);
create index if not exists attendance_records_marked_by_idx on public.attendance_records(marked_by);
