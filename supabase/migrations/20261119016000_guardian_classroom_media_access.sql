create or replace function private.guardian_has_class_access(p_class_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $function$
  select auth.uid() is not null and exists (
    select 1
    from public.guardians g
    join public.student_guardians sg on sg.guardian_id = g.id
    join public.students st on st.id = sg.student_id
    join public.learning_access_requests r on r.user_id = st.user_id and r.status = 'approved'
    join public.learning_programmes p on p.id = r.programme_id
    where g.user_id = auth.uid() and p.class_id = p_class_id
  );
$function$;
revoke all on function private.guardian_has_class_access(uuid) from public, anon;
grant execute on function private.guardian_has_class_access(uuid) to authenticated;

drop policy if exists classroom_posts_read_class on public.classroom_posts;
create policy classroom_posts_read_class on public.classroom_posts
for select to authenticated
using (
  (is_published and (
    exists (select 1 from public.learning_access_requests r
      join public.learning_programmes p on p.id = r.programme_id
      where r.user_id = (select auth.uid()) and r.status = 'approved' and p.class_id = classroom_posts.class_id)
    or private.guardian_has_class_access(classroom_posts.class_id)
  ))
  or private.has_permission('academics.manage')
  or exists (select 1 from public.class_tutors ct
    where ct.class_id = classroom_posts.class_id and ct.tutor_id = (select auth.uid()))
);

drop policy if exists classroom_media_read_authorized on storage.objects;
create policy classroom_media_read_authorized on storage.objects
for select to authenticated
using (
  bucket_id = 'classroom-resources'
  and (
    private.has_permission('academics.manage')
    or exists (select 1 from public.learning_access_requests r
      join public.learning_programmes p on p.id = r.programme_id
      where r.user_id = (select auth.uid()) and r.status = 'approved'
        and p.class_id = ((storage.foldername(name))[1])::uuid)
    or exists (select 1 from public.class_tutors ct
      where ct.tutor_id = (select auth.uid())
        and ct.class_id = ((storage.foldername(name))[1])::uuid)
    or private.guardian_has_class_access(((storage.foldername(name))[1])::uuid)
  )
);