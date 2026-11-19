-- Structured Nigerian examination question-bank metadata and learner bookmarks.
alter table public.assessments
  add column if not exists is_past_question boolean not null default false,
  add column if not exists exam_body text,
  add column if not exists exam_year smallint,
  add column if not exists exam_name text,
  add column if not exists topic text,
  add column if not exists source_note text;

alter table public.assessments drop constraint if exists assessments_exam_body_check;
alter table public.assessments add constraint assessments_exam_body_check
  check (exam_body is null or exam_body in ('WAEC','NECO','JAMB','NABTEB','NBAIS','NCEE','BECE'));
alter table public.assessments drop constraint if exists assessments_exam_year_check;
alter table public.assessments add constraint assessments_exam_year_check
  check (exam_year is null or exam_year between 1990 and 2100);

create index if not exists assessments_question_bank_idx
  on public.assessments (exam_body, exam_year, subject_id, class_id)
  where is_past_question = true and is_published = true;

create table if not exists public.assessment_bookmarks (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  assessment_id uuid not null references public.assessments(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique (user_id, assessment_id)
);
alter table public.assessment_bookmarks enable row level security;
drop policy if exists assessment_bookmarks_read_own on public.assessment_bookmarks;
create policy assessment_bookmarks_read_own on public.assessment_bookmarks
  for select to authenticated using ((select auth.uid()) = user_id);
drop policy if exists assessment_bookmarks_add_own on public.assessment_bookmarks;
create policy assessment_bookmarks_add_own on public.assessment_bookmarks
  for insert to authenticated with check (
    (select auth.uid()) = user_id and exists (
      select 1 from public.students s
      where s.user_id = (select auth.uid()) and s.status = 'active'
    )
  );
drop policy if exists assessment_bookmarks_remove_own on public.assessment_bookmarks;
create policy assessment_bookmarks_remove_own on public.assessment_bookmarks
  for delete to authenticated using ((select auth.uid()) = user_id);
grant select, insert, delete on public.assessment_bookmarks to authenticated;
revoke all on public.assessment_bookmarks from anon;

create or replace function private.student_available_assessments()
returns jsonb language plpgsql security definer set search_path = ''
as $$
declare v_student_id uuid; v_items jsonb;
begin
  if auth.uid() is null then raise exception 'Authentication required'; end if;
  select s.id into v_student_id from public.students s
  where s.user_id=auth.uid() and s.status='active' limit 1;
  if v_student_id is null then return '[]'::jsonb; end if;
  select coalesce(jsonb_agg(jsonb_build_object(
    'id',a.id,'title',a.title,'assessment_type',a.assessment_type,
    'starts_at',a.starts_at,'duration_minutes',a.duration_minutes,
    'total_marks',a.total_marks,'subject_name',sub.name,'class_name',c.name,
    'question_count',(select count(*) from public.questions q where q.assessment_id=a.id),
    'is_past_question',a.is_past_question,'exam_body',a.exam_body,
    'exam_year',a.exam_year,'exam_name',a.exam_name,'topic',a.topic
  ) order by a.starts_at nulls last,a.created_at desc),'[]'::jsonb)
  into v_items from public.assessments a
  join public.classes c on c.id=a.class_id
  join public.subjects sub on sub.id=a.subject_id
  where a.is_published=true and exists (
    select 1 from public.learning_access_requests r
    join public.learning_programmes p on p.id=r.programme_id
    where r.user_id=auth.uid() and r.status='approved' and p.class_id=a.class_id
  );
  return v_items;
end;
$$;
revoke all on function private.student_available_assessments() from public, anon;
grant execute on function private.student_available_assessments() to authenticated;
