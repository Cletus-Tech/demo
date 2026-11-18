-- A parent can view detailed progress only for a learner that has an
-- approved student_guardians relationship with their guardian account.

create or replace function private.guardian_child_details(p_student_id uuid)
returns jsonb language plpgsql security definer set search_path = ''
as $$
declare v_guardian_id uuid; v_child jsonb; v_assignments jsonb; v_results jsonb; v_attendance jsonb;
begin
  if auth.uid() is null then raise exception 'Sign in to view learner details'; end if;
  select g.id into v_guardian_id from public.guardians g where g.user_id=auth.uid();
  if v_guardian_id is null or not exists (
    select 1 from public.student_guardians sg
    where sg.guardian_id=v_guardian_id and sg.student_id=p_student_id
  ) then
    raise exception 'This learner is not linked to your parent account';
  end if;

  select jsonb_build_object('student_id',st.id,'name',pr.full_name,'level',st.level)
  into v_child
  from public.students st join public.profiles pr on pr.id=st.user_id
  where st.id=p_student_id;

  select coalesce(jsonb_agg(jsonb_build_object(
    'title',a.title,'subject',su.name,'due_at',a.due_at,
    'status',coalesce(ss.status::text,'not_submitted'),
    'score',ss.score,'max_score',a.max_score,
    'feedback',ss.tutor_feedback,'submitted_at',ss.submitted_at
  ) order by a.due_at nulls last,a.created_at desc),'[]'::jsonb)
  into v_assignments
  from public.assignments a
  join public.subjects su on su.id=a.subject_id
  left join public.assignment_submissions ss on ss.assignment_id=a.id and ss.student_id=p_student_id
  where a.published_at is not null and a.published_at<=now()
    and exists (
      select 1 from public.students st
      join public.learning_access_requests r on r.user_id=st.user_id and r.status='approved'
      join public.learning_programmes p on p.id=r.programme_id and p.is_active=true
      where st.id=p_student_id and p.class_id=a.class_id
    );

  select coalesce(jsonb_agg(jsonb_build_object(
    'subject',su.name,'score',res.score,'grade',res.grade,
    'comment',res.tutor_comment,'published_at',res.published_at
  ) order by res.published_at desc),'[]'::jsonb)
  into v_results
  from public.results res join public.subjects su on su.id=res.subject_id
  where res.student_id=p_student_id and res.published_at is not null;

  select coalesce(jsonb_agg(jsonb_build_object(
    'date',ar.attendance_date,'status',ar.status,'note',ar.note
  ) order by ar.attendance_date desc),'[]'::jsonb)
  into v_attendance
  from (
    select * from public.attendance_records
    where student_id=p_student_id
    order by attendance_date desc limit 30
  ) ar;

  return jsonb_build_object(
    'child',coalesce(v_child,'{}'::jsonb),
    'assignments',v_assignments,
    'results',v_results,
    'attendance',v_attendance
  );
end;
$$;

create or replace function public.guardian_child_details(p_student_id uuid)
returns jsonb language sql set search_path = '' as $$
  select private.guardian_child_details(p_student_id);
$$;
revoke all on function public.guardian_child_details(uuid) from public,anon;
grant execute on function public.guardian_child_details(uuid) to authenticated;
