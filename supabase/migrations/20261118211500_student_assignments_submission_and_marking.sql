-- Learner assignment access and controlled text submissions.
create or replace function private.student_assignments()
returns jsonb language plpgsql security definer set search_path = ''
as $$
declare v_student_id uuid; v_rows jsonb;
begin
  if auth.uid() is null then raise exception 'Authentication required'; end if;
  select s.id into v_student_id from public.students s
    where s.user_id = auth.uid() and s.status = 'active' limit 1;
  if v_student_id is null then return '[]'::jsonb; end if;
  select coalesce(jsonb_agg(jsonb_build_object(
    'id',a.id,'title',a.title,'instructions',a.instructions,'due_at',a.due_at,
    'max_score',a.max_score,'class_name',c.name,'subject_name',sub.name,
    'submission_id',ss.id,'submission_status',ss.status,'answer_text',ss.answer_text,
    'score',ss.score,'tutor_feedback',ss.tutor_feedback,
    'submitted_at',ss.submitted_at,'graded_at',ss.graded_at
  ) order by a.due_at nulls last,a.created_at desc),'[]'::jsonb)
  into v_rows
  from public.assignments a
  join public.classes c on c.id=a.class_id
  join public.subjects sub on sub.id=a.subject_id
  join public.enrolments e on e.class_id=a.class_id and e.student_id=v_student_id and e.status='active'
  left join public.assignment_submissions ss on ss.assignment_id=a.id and ss.student_id=v_student_id
  where a.published_at is not null and a.published_at <= now();
  return v_rows;
end;
$$;

create or replace function private.submit_student_assignment(p_assignment_id uuid,p_answer_text text)
returns jsonb language plpgsql security definer set search_path = ''
as $$
declare v_student_id uuid; v_submission_id uuid; v_status text;
begin
  if auth.uid() is null then raise exception 'Authentication required'; end if;
  if p_answer_text is null or length(btrim(p_answer_text)) < 2 then
    raise exception 'Write your answer before submitting';
  end if;
  if length(p_answer_text) > 30000 then raise exception 'Answer is too long'; end if;
  select s.id into v_student_id from public.students s
    where s.user_id=auth.uid() and s.status='active' limit 1;
  if v_student_id is null then raise exception 'No active learner profile is linked to this account'; end if;
  if not exists (
    select 1 from public.assignments a
    join public.enrolments e on e.class_id=a.class_id
    where a.id=p_assignment_id and a.published_at is not null and a.published_at <= now()
      and e.student_id=v_student_id and e.status='active'
  ) then raise exception 'This assignment is not available for your class'; end if;

  insert into public.assignment_submissions(assignment_id,student_id,answer_text,status,submitted_at)
  values(p_assignment_id,v_student_id,btrim(p_answer_text),'submitted',now())
  on conflict(assignment_id,student_id) do update
    set answer_text=excluded.answer_text,status='submitted',submitted_at=now(),
        score=null,tutor_feedback=null,graded_at=null
    where public.assignment_submissions.status in ('draft','returned')
  returning id,status into v_submission_id,v_status;
  if v_submission_id is null then
    raise exception 'This submission has already been sent and is awaiting marking';
  end if;
  return jsonb_build_object('submission_id',v_submission_id,'status',v_status,'submitted_at',now());
end;
$$;

create or replace function public.student_assignments()
returns jsonb language sql security invoker set search_path = ''
as $$ select private.student_assignments(); $$;

create or replace function public.submit_student_assignment(p_assignment_id uuid,p_answer_text text)
returns jsonb language sql security invoker set search_path = ''
as $$ select private.submit_student_assignment(p_assignment_id,p_answer_text); $$;

revoke all on function private.student_assignments() from public,anon;
revoke all on function private.submit_student_assignment(uuid,text) from public,anon;
grant usage on schema private to authenticated;
grant execute on function private.student_assignments() to authenticated;
grant execute on function private.submit_student_assignment(uuid,text) to authenticated;
revoke all on function public.student_assignments() from public,anon;
revoke all on function public.submit_student_assignment(uuid,text) from public,anon;
grant execute on function public.student_assignments() to authenticated;
grant execute on function public.submit_student_assignment(uuid,text) to authenticated;

drop policy if exists assignment_submissions_admin_all on public.assignment_submissions;
create policy assignment_submissions_admin_all on public.assignment_submissions
for all to authenticated
using (private.has_permission('students.manage') or private.has_permission('academics.manage'))
with check (private.has_permission('students.manage') or private.has_permission('academics.manage'));
