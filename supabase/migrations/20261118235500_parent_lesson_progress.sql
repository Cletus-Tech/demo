create or replace function private.guardian_portal_summary()
returns jsonb language plpgsql security definer set search_path=''
as $$
declare v_guardian_id uuid; v_children jsonb; v_requests jsonb;
begin
  if auth.uid() is null then raise exception 'Sign in to view your parent dashboard'; end if;
  select g.id into v_guardian_id from public.guardians g where g.user_id=auth.uid();
  if v_guardian_id is null then return jsonb_build_object('children','[]'::jsonb,'requests','[]'::jsonb); end if;
  select coalesce(jsonb_agg(jsonb_build_object(
    'student_id',st.id,'name',pr.full_name,'email',pr.email,'level',st.level,
    'relationship',sg.relationship,'status',st.status,
    'attendance_total',(select count(*) from public.attendance_records ar where ar.student_id=st.id),
    'attendance_rate',(select case when count(*)=0 then null else round((count(*) filter(where ar.status in ('present','late'))::numeric/count(*))*100,1) end from public.attendance_records ar where ar.student_id=st.id),
    'assignments_submitted',(select count(*) from public.assignment_submissions ass where ass.student_id=st.id and ass.submitted_at is not null),
    'lessons_completed',(select count(*) from public.lesson_completions lc join public.lessons l on l.id=lc.lesson_id
      where lc.user_id=st.user_id and l.is_published=true and exists(select 1 from public.learning_access_requests r join public.learning_programmes p on p.id=r.programme_id where r.user_id=st.user_id and r.status='approved' and p.class_id=l.class_id)),
    'lessons_available',(select count(*) from public.lessons l where l.is_published=true and exists(select 1 from public.learning_access_requests r join public.learning_programmes p on p.id=r.programme_id where r.user_id=st.user_id and r.status='approved' and p.class_id=l.class_id)),
    'latest_result',(select res.score from public.results res where res.student_id=st.id and res.published_at is not null order by res.published_at desc limit 1),
    'latest_subject',(select su.name from public.results res join public.subjects su on su.id=res.subject_id where res.student_id=st.id and res.published_at is not null order by res.published_at desc limit 1),
    'latest_comment',(select res.tutor_comment from public.results res where res.student_id=st.id and res.published_at is not null order by res.published_at desc limit 1)
  ) order by pr.full_name),'[]'::jsonb)
  into v_children from public.student_guardians sg join public.students st on st.id=sg.student_id
  join public.profiles pr on pr.id=st.user_id where sg.guardian_id=v_guardian_id;
  select coalesce(jsonb_agg(jsonb_build_object('id',q.id,'requested_email',q.requested_email,'relationship',q.relationship,'status',q.status,'admin_note',q.admin_note,'created_at',q.created_at) order by q.created_at desc),'[]'::jsonb)
  into v_requests from public.guardian_link_requests q where q.guardian_user_id=auth.uid();
  return jsonb_build_object('children',v_children,'requests',v_requests);
end;
$$;

create or replace function private.guardian_child_details(p_student_id uuid)
returns jsonb language plpgsql security definer set search_path=''
as $$
declare v_guardian_id uuid; v_child jsonb; v_assignments jsonb; v_results jsonb; v_attendance jsonb; v_lessons jsonb; v_completed integer; v_available integer;
begin
  if auth.uid() is null then raise exception 'Sign in to view learner details'; end if;
  select g.id into v_guardian_id from public.guardians g where g.user_id=auth.uid();
  if v_guardian_id is null or not exists(select 1 from public.student_guardians sg where sg.guardian_id=v_guardian_id and sg.student_id=p_student_id) then raise exception 'This learner is not linked to your parent account'; end if;
  select jsonb_build_object('student_id',st.id,'name',pr.full_name,'level',st.level) into v_child
  from public.students st join public.profiles pr on pr.id=st.user_id where st.id=p_student_id;
  select coalesce(jsonb_agg(jsonb_build_object('title',a.title,'subject',su.name,'due_at',a.due_at,'status',coalesce(ss.status::text,'not_submitted'),'score',ss.score,'max_score',a.max_score,'feedback',ss.tutor_feedback,'submitted_at',ss.submitted_at) order by a.due_at nulls last,a.created_at desc),'[]'::jsonb)
  into v_assignments from public.assignments a join public.subjects su on su.id=a.subject_id
  left join public.assignment_submissions ss on ss.assignment_id=a.id and ss.student_id=p_student_id
  where a.published_at is not null and a.published_at<=now() and exists(
    select 1 from public.students st join public.learning_access_requests r on r.user_id=st.user_id and r.status='approved'
    join public.learning_programmes p on p.id=r.programme_id where st.id=p_student_id and p.class_id=a.class_id);
  select coalesce(jsonb_agg(jsonb_build_object('subject',su.name,'score',res.score,'grade',res.grade,'comment',res.tutor_comment,'published_at',res.published_at) order by res.published_at desc),'[]'::jsonb)
  into v_results from public.results res join public.subjects su on su.id=res.subject_id where res.student_id=p_student_id and res.published_at is not null;
  select coalesce(jsonb_agg(jsonb_build_object('date',ar.attendance_date,'status',ar.status,'note',ar.note) order by ar.attendance_date desc),'[]'::jsonb)
  into v_attendance from (select * from public.attendance_records where student_id=p_student_id order by attendance_date desc limit 30) ar;
  select count(*) into v_available from public.lessons l join public.students st on st.id=p_student_id
  where l.is_published=true and exists(select 1 from public.learning_access_requests r join public.learning_programmes p on p.id=r.programme_id where r.user_id=st.user_id and r.status='approved' and p.class_id=l.class_id);
  select count(*) into v_completed from public.lesson_completions lc join public.lessons l on l.id=lc.lesson_id join public.students st on st.user_id=lc.user_id
  where st.id=p_student_id and l.is_published=true and exists(select 1 from public.learning_access_requests r join public.learning_programmes p on p.id=r.programme_id where r.user_id=st.user_id and r.status='approved' and p.class_id=l.class_id);
  select coalesce(jsonb_agg(jsonb_build_object('title',l.title,'subject',su.name,'status','Completed','date',lc.completed_at) order by lc.completed_at desc),'[]'::jsonb)
  into v_lessons from public.lesson_completions lc join public.lessons l on l.id=lc.lesson_id left join public.subjects su on su.id=l.subject_id
  join public.students st on st.user_id=lc.user_id where st.id=p_student_id and l.is_published=true
  and exists(select 1 from public.learning_access_requests r join public.learning_programmes p on p.id=r.programme_id where r.user_id=st.user_id and r.status='approved' and p.class_id=l.class_id);
  return jsonb_build_object('child',coalesce(v_child,'{}'::jsonb),'assignments',v_assignments,'results',v_results,'attendance',v_attendance,
    'lesson_progress',jsonb_build_object('completed',v_completed,'available',v_available,'items',coalesce(v_lessons,'[]'::jsonb)));
end;
$$;
