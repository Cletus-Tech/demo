-- Expand the parent portal's supervised, read-only view of each approved child.
-- Access is still limited to a guardian-child relationship verified by the centre.
create or replace function private.guardian_child_details(p_student_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_guardian_id uuid;
  v_child jsonb;
  v_assignments jsonb;
  v_results jsonb;
  v_attendance jsonb;
  v_lessons jsonb;
  v_upcoming_lessons jsonb;
  v_materials jsonb;
  v_assessments jsonb;
  v_classroom_board jsonb;
  v_completed integer;
  v_available integer;
begin
  if auth.uid() is null then raise exception 'Sign in to view learner details'; end if;
  select g.id into v_guardian_id from public.guardians g where g.user_id = auth.uid();
  if v_guardian_id is null or not exists (
    select 1 from public.student_guardians sg
    where sg.guardian_id = v_guardian_id and sg.student_id = p_student_id
  ) then raise exception 'This learner is not linked to your parent account'; end if;

  select jsonb_build_object('student_id', st.id, 'name', pr.full_name, 'level', st.level,
    'class_name', coalesce(c.name, st.level))
  into v_child
  from public.students st join public.profiles pr on pr.id = st.user_id
  left join public.learning_access_requests r on r.user_id = st.user_id and r.status = 'approved'
  left join public.learning_programmes p on p.id = r.programme_id
  left join public.classes c on c.id = p.class_id
  where st.id = p_student_id order by r.updated_at desc nulls last limit 1;

  select coalesce(jsonb_agg(jsonb_build_object('title', a.title, 'subject', su.name,
    'due_at', a.due_at, 'status', coalesce(ss.status::text, 'not_submitted'),
    'score', ss.score, 'max_score', a.max_score, 'feedback', ss.tutor_feedback,
    'submitted_at', ss.submitted_at) order by a.due_at nulls last, a.created_at desc), '[]'::jsonb)
  into v_assignments
  from public.assignments a join public.subjects su on su.id = a.subject_id
  left join public.assignment_submissions ss on ss.assignment_id = a.id and ss.student_id = p_student_id
  where a.published_at is not null and a.published_at <= now()
    and exists (select 1 from public.students st
      join public.learning_access_requests r on r.user_id = st.user_id and r.status = 'approved'
      join public.learning_programmes p on p.id = r.programme_id
      where st.id = p_student_id and p.class_id = a.class_id);

  select coalesce(jsonb_agg(jsonb_build_object('subject', su.name, 'score', res.score,
    'grade', res.grade, 'comment', res.tutor_comment, 'published_at', res.published_at)
    order by res.published_at desc), '[]'::jsonb)
  into v_results from public.results res join public.subjects su on su.id = res.subject_id
  where res.student_id = p_student_id and res.published_at is not null;

  select coalesce(jsonb_agg(jsonb_build_object('date', ar.attendance_date,
    'status', ar.status, 'note', ar.note) order by ar.attendance_date desc), '[]'::jsonb)
  into v_attendance from (select * from public.attendance_records
    where student_id = p_student_id order by attendance_date desc limit 30) ar;

  select count(*) into v_available from public.lessons l join public.students st on st.id = p_student_id
  where l.is_published = true and exists (select 1 from public.learning_access_requests r
    join public.learning_programmes p on p.id = r.programme_id
    where r.user_id = st.user_id and r.status = 'approved' and p.class_id = l.class_id);

  select count(*) into v_completed from public.lesson_completions lc
  join public.lessons l on l.id = lc.lesson_id join public.students st on st.user_id = lc.user_id
  where st.id = p_student_id and l.is_published = true and exists (
    select 1 from public.learning_access_requests r join public.learning_programmes p on p.id = r.programme_id
    where r.user_id = st.user_id and r.status = 'approved' and p.class_id = l.class_id);

  select coalesce(jsonb_agg(jsonb_build_object('title', l.title, 'subject', su.name,
    'status', 'Completed', 'date', lc.completed_at) order by lc.completed_at desc), '[]'::jsonb)
  into v_lessons from public.lesson_completions lc join public.lessons l on l.id = lc.lesson_id
  left join public.subjects su on su.id = l.subject_id join public.students st on st.user_id = lc.user_id
  where st.id = p_student_id and l.is_published = true and exists (
    select 1 from public.learning_access_requests r join public.learning_programmes p on p.id = r.programme_id
    where r.user_id = st.user_id and r.status = 'approved' and p.class_id = l.class_id);

  select coalesce(jsonb_agg(jsonb_build_object('title', l.title, 'subject', su.name,
    'description', l.description, 'scheduled_at', l.scheduled_at, 'duration_minutes', l.duration_minutes,
    'live_class_url', case when l.live_class_url like 'https://%' then l.live_class_url else null end)
    order by l.scheduled_at asc nulls last), '[]'::jsonb)
  into v_upcoming_lessons from public.lessons l left join public.subjects su on su.id = l.subject_id
  join public.students st on st.id = p_student_id
  where l.is_published = true and (l.scheduled_at is null or l.scheduled_at >= now())
    and exists (select 1 from public.learning_access_requests r join public.learning_programmes p on p.id = r.programme_id
      where r.user_id = st.user_id and r.status = 'approved' and p.class_id = l.class_id);

  select coalesce(jsonb_agg(jsonb_build_object('title', lm.title, 'material_type', lm.material_type,
    'lesson_title', l.title, 'subject', su.name) order by lm.created_at desc), '[]'::jsonb)
  into v_materials from public.learning_materials lm
  join public.lessons l on l.id = lm.lesson_id and l.is_published = true
  left join public.subjects su on su.id = l.subject_id join public.students st on st.id = p_student_id
  where exists (select 1 from public.learning_access_requests r join public.learning_programmes p on p.id = r.programme_id
    where r.user_id = st.user_id and r.status = 'approved' and p.class_id = l.class_id);

  select coalesce(jsonb_agg(jsonb_build_object('title', a.title, 'subject', su.name,
    'assessment_type', a.assessment_type, 'starts_at', a.starts_at,
    'duration_minutes', a.duration_minutes, 'total_marks', a.total_marks)
    order by a.starts_at asc nulls last), '[]'::jsonb)
  into v_assessments from public.assessments a join public.subjects su on su.id = a.subject_id
  join public.students st on st.id = p_student_id
  where a.is_published = true and coalesce(a.is_past_question, false) = false
    and (a.starts_at is null or a.starts_at >= now())
    and exists (select 1 from public.learning_access_requests r join public.learning_programmes p on p.id = r.programme_id
      where r.user_id = st.user_id and r.status = 'approved' and p.class_id = a.class_id);

  select coalesce(jsonb_agg(jsonb_build_object(
    'title', cp.title, 'post_type', cp.post_type, 'body', cp.body,
    'media_path', cp.media_path, 'media_url', cp.media_url, 'created_at', cp.created_at
  ) order by cp.created_at desc), '[]'::jsonb)
  into v_classroom_board
  from public.classroom_posts cp
  join public.students st on st.id = p_student_id
  join public.learning_access_requests r on r.user_id = st.user_id and r.status = 'approved'
  join public.learning_programmes p on p.id = r.programme_id and p.class_id = cp.class_id
  where cp.is_published = true;

  return jsonb_build_object('child', coalesce(v_child, '{}'::jsonb),
    'assignments', v_assignments, 'results', v_results, 'attendance', v_attendance,
    'lesson_progress', jsonb_build_object('completed', v_completed, 'available', v_available,
      'items', coalesce(v_lessons, '[]'::jsonb)),
    'upcoming_lessons', v_upcoming_lessons, 'materials', v_materials, 'assessments', v_assessments,
    'classroom_board', v_classroom_board);
end;
$function$;

revoke all on function private.guardian_child_details(uuid) from public, anon;
grant execute on function private.guardian_child_details(uuid) to authenticated;
