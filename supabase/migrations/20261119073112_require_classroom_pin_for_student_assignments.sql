create or replace function private.student_assignments()
returns jsonb language plpgsql security definer set search_path = ''
as $$
declare v_student_id uuid; v_rows jsonb;
begin
  if auth.uid() is null then raise exception 'Authentication required'; end if;
  select s.id into v_student_id from public.students s
  where s.user_id=auth.uid() and s.status='active' limit 1;
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
  left join public.assignment_submissions ss on ss.assignment_id=a.id and ss.student_id=v_student_id
  where a.published_at is not null and a.published_at<=now()
    and exists (
      select 1 from public.learning_access_requests r
      join public.learning_programmes p on p.id=r.programme_id
      join public.classroom_access_passes cap on cap.request_id=r.id
      where r.user_id=auth.uid() and r.status='approved'
        and p.class_id=a.class_id and cap.redeemed_at is not null and cap.revoked_at is null
    );
  return v_rows;
end;
$$;