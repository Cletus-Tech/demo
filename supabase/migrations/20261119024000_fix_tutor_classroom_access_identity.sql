drop policy if exists assignments_tutor_class_read on public.assignments;
create policy assignments_tutor_class_read on public.assignments
for select to authenticated
using (
  exists (
    select 1 from public.class_tutors ct
    join public.tutors t on t.id = ct.tutor_id
    where ct.class_id = assignments.class_id
      and t.user_id = (select auth.uid())
      and t.status = 'active'
  )
);

drop policy if exists assignments_tutor_class_insert on public.assignments;
create policy assignments_tutor_class_insert on public.assignments
for insert to authenticated
with check (
  exists (
    select 1 from public.tutors t
    join public.class_tutors ct on ct.tutor_id = t.id
    where t.id = assignments.tutor_id
      and t.user_id = (select auth.uid())
      and t.status = 'active'
      and ct.class_id = assignments.class_id
  )
);

drop policy if exists lessons_read_published on public.lessons;
create policy lessons_read_published on public.lessons
for select to authenticated
using (
  is_published = true
  and (
    private.has_permission('academics.manage')
    or exists (
      select 1 from public.learning_access_requests r
      join public.learning_programmes p on p.id = r.programme_id
      where r.user_id = (select auth.uid()) and r.status = 'approved'
        and p.class_id = lessons.class_id
    )
    or exists (
      select 1 from public.class_tutors ct
      join public.tutors t on t.id = ct.tutor_id
      where ct.class_id = lessons.class_id
        and t.user_id = (select auth.uid()) and t.status = 'active'
    )
  )
);

drop policy if exists classroom_posts_read_class on public.classroom_posts;
create policy classroom_posts_read_class on public.classroom_posts
for select to authenticated
using (
  (is_published and (
    exists (select 1 from public.learning_access_requests r
      join public.learning_programmes p on p.id = r.programme_id
      where r.user_id = (select auth.uid()) and r.status = 'approved'
        and p.class_id = classroom_posts.class_id)
    or private.guardian_has_class_access(classroom_posts.class_id)
  ))
  or private.has_permission('academics.manage')
  or exists (
    select 1 from public.class_tutors ct join public.tutors t on t.id = ct.tutor_id
    where ct.class_id = classroom_posts.class_id and t.user_id = (select auth.uid()) and t.status = 'active'
  )
);

drop policy if exists classroom_posts_staff_insert on public.classroom_posts;
create policy classroom_posts_staff_insert on public.classroom_posts
for insert to authenticated
with check (
  author_id = (select auth.uid())
  and (
    private.has_permission('academics.manage')
    or exists (
      select 1 from public.class_tutors ct join public.tutors t on t.id = ct.tutor_id
      where ct.class_id = classroom_posts.class_id and t.user_id = (select auth.uid()) and t.status = 'active'
    )
  )
);

drop policy if exists classroom_posts_staff_update on public.classroom_posts;
create policy classroom_posts_staff_update on public.classroom_posts
for update to authenticated
using (
  private.has_permission('academics.manage')
  or (author_id = (select auth.uid()) and exists (
    select 1 from public.class_tutors ct join public.tutors t on t.id = ct.tutor_id
    where ct.class_id = classroom_posts.class_id and t.user_id = (select auth.uid()) and t.status = 'active'
  ))
)
with check (
  private.has_permission('academics.manage')
  or (author_id = (select auth.uid()) and exists (
    select 1 from public.class_tutors ct join public.tutors t on t.id = ct.tutor_id
    where ct.class_id = classroom_posts.class_id and t.user_id = (select auth.uid()) and t.status = 'active'
  ))
);

drop policy if exists classroom_posts_staff_delete on public.classroom_posts;
create policy classroom_posts_staff_delete on public.classroom_posts
for delete to authenticated
using (
  private.has_permission('academics.manage')
  or (author_id = (select auth.uid()) and exists (
    select 1 from public.class_tutors ct join public.tutors t on t.id = ct.tutor_id
    where ct.class_id = classroom_posts.class_id and t.user_id = (select auth.uid()) and t.status = 'active'
  ))
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
      join public.tutors t on t.id = ct.tutor_id
      where t.user_id = (select auth.uid()) and t.status = 'active'
        and ct.class_id = ((storage.foldername(name))[1])::uuid)
    or private.guardian_has_class_access(((storage.foldername(name))[1])::uuid)
  )
);

drop policy if exists classroom_media_staff_upload on storage.objects;
create policy classroom_media_staff_upload on storage.objects
for insert to authenticated
with check (
  bucket_id = 'classroom-resources'
  and (
    private.has_permission('academics.manage')
    or exists (select 1 from public.class_tutors ct
      join public.tutors t on t.id = ct.tutor_id
      where t.user_id = (select auth.uid()) and t.status = 'active'
        and ct.class_id = ((storage.foldername(name))[1])::uuid)
  )
);

drop policy if exists classroom_media_staff_update on storage.objects;
create policy classroom_media_staff_update on storage.objects
for update to authenticated
using (
  bucket_id = 'classroom-resources'
  and (
    private.has_permission('academics.manage')
    or exists (select 1 from public.class_tutors ct
      join public.tutors t on t.id = ct.tutor_id
      where t.user_id = (select auth.uid()) and t.status = 'active'
        and ct.class_id = ((storage.foldername(name))[1])::uuid)
  )
)
with check (
  bucket_id = 'classroom-resources'
  and (
    private.has_permission('academics.manage')
    or exists (select 1 from public.class_tutors ct
      join public.tutors t on t.id = ct.tutor_id
      where t.user_id = (select auth.uid()) and t.status = 'active'
        and ct.class_id = ((storage.foldername(name))[1])::uuid)
  )
);

drop policy if exists classroom_media_staff_delete on storage.objects;
create policy classroom_media_staff_delete on storage.objects
for delete to authenticated
using (
  bucket_id = 'classroom-resources'
  and (
    private.has_permission('academics.manage')
    or exists (select 1 from public.class_tutors ct
      join public.tutors t on t.id = ct.tutor_id
      where t.user_id = (select auth.uid()) and t.status = 'active'
        and ct.class_id = ((storage.foldername(name))[1])::uuid)
  )
);