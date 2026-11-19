-- Use the current paid classroom-access model for the roster. Keep legacy
-- active enrolments as a compatibility path while the old table is retired.
create or replace function private.admin_assignment_submissions(p_assignment_id uuid)
returns jsonb language plpgsql stable security definer set search_path = '' as $$
declare v_rows jsonb;
begin
  if auth.uid() is null or not (private.has_permission('academics.manage') or private.has_permission('students.manage')) then
    raise exception 'You are not authorised to review class submissions';
  end if;
  if not exists (select 1 from public.assignments a where a.id=p_assignment_id) then
    raise exception 'Assignment or classwork item not found';
  end if;
  with eligible_students as (
    select e.student_id,e.class_id
    from public.enrolments e where e.status::text='active'
    union
    select st.id,lp.class_id
    from public.learning_access_requests r
    join public.learning_programmes lp on lp.id=r.programme_id
    join public.classroom_access_passes cap on cap.request_id=r.id
    join public.students st on st.user_id=r.user_id
    where r.status='approved' and lp.class_id is not null
      and cap.redeemed_at is not null and cap.revoked_at is null
  )
  select coalesce(jsonb_agg(jsonb_build_object(
    'id',ss.id,'student_id',st.id,'student_name',coalesce(p.full_name,'Learner'),
    'student_level',st.level,'answer_text',ss.answer_text,
    'status',coalesce(ss.status::text,'not_submitted'),'score',ss.score,
    'tutor_feedback',ss.tutor_feedback,'submitted_at',ss.submitted_at,'graded_at',ss.graded_at
  ) order by p.full_name nulls last,st.created_at),'[]'::jsonb)
  into v_rows
  from public.assignments a
  join eligible_students es on es.class_id=a.class_id
  join public.students st on st.id=es.student_id and st.status::text='active'
  left join public.profiles p on p.id=st.user_id
  left join public.assignment_submissions ss on ss.assignment_id=a.id and ss.student_id=st.id
  where a.id=p_assignment_id;
  return v_rows;
end; $$;

create or replace function private.tutor_assignment_submissions(p_assignment_id uuid)
returns jsonb language plpgsql stable security definer set search_path = '' as $$
declare v_tutor_id uuid; v_rows jsonb;
begin
  if auth.uid() is null then raise exception 'Authentication required'; end if;
  select t.id into v_tutor_id from public.tutors t
    where t.user_id=auth.uid() and t.status::text='active' limit 1;
  if v_tutor_id is null then raise exception 'No active tutor profile is linked to this account'; end if;
  if not exists (
    select 1 from public.assignments a join public.class_tutors ct
      on ct.class_id=a.class_id and ct.subject_id=a.subject_id
    where a.id=p_assignment_id and a.tutor_id=v_tutor_id and ct.tutor_id=v_tutor_id
  ) then raise exception 'This work is not assigned to your tutor account'; end if;
  with eligible_students as (
    select e.student_id,e.class_id from public.enrolments e where e.status::text='active'
    union
    select st.id,lp.class_id
    from public.learning_access_requests r
    join public.learning_programmes lp on lp.id=r.programme_id
    join public.classroom_access_passes cap on cap.request_id=r.id
    join public.students st on st.user_id=r.user_id
    where r.status='approved' and lp.class_id is not null
      and cap.redeemed_at is not null and cap.revoked_at is null
  )
  select coalesce(jsonb_agg(jsonb_build_object(
    'id',ss.id,'student_id',st.id,'student_name',coalesce(p.full_name,'Learner'),
    'student_level',st.level,'answer_text',ss.answer_text,
    'status',coalesce(ss.status::text,'not_submitted'),'score',ss.score,
    'tutor_feedback',ss.tutor_feedback,'submitted_at',ss.submitted_at,'graded_at',ss.graded_at
  ) order by p.full_name nulls last,st.created_at),'[]'::jsonb)
  into v_rows
  from public.assignments a
  join eligible_students es on es.class_id=a.class_id
  join public.students st on st.id=es.student_id and st.status::text='active'
  left join public.profiles p on p.id=st.user_id
  left join public.assignment_submissions ss on ss.assignment_id=a.id and ss.student_id=st.id
  where a.id=p_assignment_id;
  return v_rows;
end; $$;
revoke all on function private.admin_assignment_submissions(uuid) from public,anon;
grant execute on function private.admin_assignment_submissions(uuid) to authenticated;
revoke all on function private.tutor_assignment_submissions(uuid) from public,anon;
grant execute on function private.tutor_assignment_submissions(uuid) to authenticated;