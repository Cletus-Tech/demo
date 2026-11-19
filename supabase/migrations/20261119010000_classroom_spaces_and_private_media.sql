-- Dedicated class notice board and private media storage for Young Learners Tutorial.
create table if not exists public.classroom_posts (
  id uuid primary key default gen_random_uuid(),
  class_id uuid not null references public.classes(id) on delete cascade,
  author_id uuid not null references public.profiles(id) on delete restrict,
  post_type text not null default 'notice'
    check (post_type in ('notice','explanation','resource','whiteboard')),
  title text not null check (length(btrim(title)) between 3 and 160),
  body text,
  media_path text,
  media_url text,
  is_published boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint classroom_posts_media_source_check
    check (media_path is null or media_url is null)
);
create index if not exists classroom_posts_class_published_idx
  on public.classroom_posts(class_id, is_published, created_at desc);
alter table public.classroom_posts enable row level security;
revoke all on public.classroom_posts from anon;
grant select, insert, update, delete on public.classroom_posts to authenticated;

drop policy if exists classroom_posts_read_class on public.classroom_posts;
create policy classroom_posts_read_class on public.classroom_posts
for select to authenticated
using (
  (is_published and (
    exists (select 1 from public.learning_access_requests r
      join public.learning_programmes p on p.id = r.programme_id
      where r.user_id = (select auth.uid()) and r.status = 'approved' and p.class_id = classroom_posts.class_id)
    or exists (select 1 from public.students st
      join public.student_guardians sg on sg.student_id = st.id
      join public.guardians g on g.id = sg.guardian_id
      join public.learning_access_requests r on r.user_id = st.user_id and r.status = 'approved'
      join public.learning_programmes p on p.id = r.programme_id
      where g.user_id = (select auth.uid()) and p.class_id = classroom_posts.class_id)
  ))
  or private.has_permission('academics.manage')
  or exists (select 1 from public.class_tutors ct
    where ct.class_id = classroom_posts.class_id and ct.tutor_id = (select auth.uid()))
);
drop policy if exists classroom_posts_staff_insert on public.classroom_posts;
create policy classroom_posts_staff_insert on public.classroom_posts
for insert to authenticated
with check (
  author_id = (select auth.uid()) and (
    private.has_permission('academics.manage')
    or exists (select 1 from public.class_tutors ct
      where ct.class_id = classroom_posts.class_id and ct.tutor_id = (select auth.uid()))
  )
);
drop policy if exists classroom_posts_staff_update on public.classroom_posts;
create policy classroom_posts_staff_update on public.classroom_posts
for update to authenticated
using (
  private.has_permission('academics.manage')
  or (author_id = (select auth.uid()) and exists (select 1 from public.class_tutors ct
    where ct.class_id = classroom_posts.class_id and ct.tutor_id = (select auth.uid())))
)
with check (
  private.has_permission('academics.manage')
  or (author_id = (select auth.uid()) and exists (select 1 from public.class_tutors ct
    where ct.class_id = classroom_posts.class_id and ct.tutor_id = (select auth.uid())))
);
drop policy if exists classroom_posts_staff_delete on public.classroom_posts;
create policy classroom_posts_staff_delete on public.classroom_posts
for delete to authenticated
using (
  private.has_permission('academics.manage')
  or (author_id = (select auth.uid()) and exists (select 1 from public.class_tutors ct
    where ct.class_id = classroom_posts.class_id and ct.tutor_id = (select auth.uid())))
);

-- Private bucket: files are stored under <class UUID>/<random filename>.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('classroom-resources', 'classroom-resources', false, 104857600,
  array['image/jpeg','image/png','image/webp','image/gif','video/mp4','video/webm','video/quicktime','application/pdf'])
on conflict (id) do update set
  public = false,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

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
    or exists (select 1 from public.students st
      join public.student_guardians sg on sg.student_id = st.id
      join public.guardians g on g.id = sg.guardian_id
      join public.learning_access_requests r on r.user_id = st.user_id and r.status = 'approved'
      join public.learning_programmes p on p.id = r.programme_id
      where g.user_id = (select auth.uid()) and p.class_id = ((storage.foldername(name))[1])::uuid)
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
      where ct.tutor_id = (select auth.uid())
        and ct.class_id = ((storage.foldername(name))[1])::uuid)
  )
);
drop policy if exists classroom_media_staff_update on storage.objects;
create policy classroom_media_staff_update on storage.objects
for update to authenticated
using (
  bucket_id = 'classroom-resources'
  and (private.has_permission('academics.manage')
    or exists (select 1 from public.class_tutors ct
      where ct.tutor_id = (select auth.uid())
        and ct.class_id = ((storage.foldername(name))[1])::uuid))
)
with check (
  bucket_id = 'classroom-resources'
  and (private.has_permission('academics.manage')
    or exists (select 1 from public.class_tutors ct
      where ct.tutor_id = (select auth.uid())
        and ct.class_id = ((storage.foldername(name))[1])::uuid))
);
drop policy if exists classroom_media_staff_delete on storage.objects;
create policy classroom_media_staff_delete on storage.objects
for delete to authenticated
using (
  bucket_id = 'classroom-resources'
  and (private.has_permission('academics.manage')
    or exists (select 1 from public.class_tutors ct
      where ct.tutor_id = (select auth.uid())
        and ct.class_id = ((storage.foldername(name))[1])::uuid))
);
