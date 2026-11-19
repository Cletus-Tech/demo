create or replace function private.tutor_workspace_summary()
returns jsonb language plpgsql stable security definer set search_path = ''
as $$
declare v_tutor_id uuid; v_result jsonb;
begin
  if auth.uid() is null then raise exception 'Authentication required'; end if;
  select t.id into v_tutor_id from public.tutors t
  where t.user_id=auth.uid() and t.status::text='active' limit 1;
  if v_tutor_id is null then raise exception 'No active tutor profile is linked to this account'; end if;
  select jsonb_build_object(
    'classes',coalesce((select jsonb_agg(jsonb_build_object(
      'class_id',c.id,'class_name',c.name,'level',c.level,
      'subject_id',s.id,'subject_name',s.name
    ) order by c.name,s.name)
    from public.class_tutors ct join public.classes c on c.id=ct.class_id
    join public.subjects s on s.id=ct.subject_id where ct.tutor_id=v_tutor_id),'[]'::jsonb),
    'lessons',coalesce((select jsonb_agg(jsonb_build_object(
      'id',l.id,'title',l.title,'description',l.description,'content',l.content,
      'live_class_url',l.live_class_url,'scheduled_at',l.scheduled_at,
      'duration_minutes',l.duration_minutes,'class_name',c.name,'subject_name',s.name
    ) order by l.scheduled_at nulls last,l.created_at desc)
    from public.lessons l join public.class_tutors ct
      on ct.class_id=l.class_id and ct.subject_id=l.subject_id and ct.tutor_id=v_tutor_id
    join public.classes c on c.id=l.class_id join public.subjects s on s.id=l.subject_id
    where l.is_published=true),'[]'::jsonb),
    'assignments',coalesce((select jsonb_agg(jsonb_build_object(
      'id',a.id,'title',a.title,'instructions',a.instructions,'due_at',a.due_at,
      'max_score',a.max_score,'published_at',a.published_at,
      'class_name',c.name,'subject_name',s.name,
      'submission_count',(select count(*) from public.assignment_submissions ss where ss.assignment_id=a.id and ss.submitted_at is not null),
      'graded_count',(select count(*) from public.assignment_submissions ss where ss.assignment_id=a.id and ss.status::text='graded')
    ) order by a.created_at desc)
    from public.assignments a join public.class_tutors ct
      on ct.class_id=a.class_id and ct.subject_id=a.subject_id and ct.tutor_id=v_tutor_id
    join public.classes c on c.id=a.class_id join public.subjects s on s.id=a.subject_id
    where a.tutor_id=v_tutor_id),'[]'::jsonb)
  ) into v_result;
  return v_result;
end;
$$;

create or replace function private.tutor_assignment_submissions(p_assignment_id uuid)
returns jsonb language plpgsql stable security definer set search_path = ''
as $$
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
  ) then raise exception 'This assignment is not assigned to your tutor account'; end if;
  select coalesce(jsonb_agg(jsonb_build_object(
    'id',ss.id,'student_id',ss.student_id,'student_name',p.full_name,
    'student_level',st.level,'answer_text',ss.answer_text,'status',ss.status,
    'score',ss.score,'tutor_feedback',ss.tutor_feedback,
    'submitted_at',ss.submitted_at,'graded_at',ss.graded_at
  ) order by ss.submitted_at desc nulls last),'[]'::jsonb)
  into v_rows from public.assignment_submissions ss
  join public.students st on st.id=ss.student_id
  left join public.profiles p on p.id=st.user_id
  where ss.assignment_id=p_assignment_id;
  return v_rows;
end;
$$;

create or replace function private.tutor_grade_assignment_submission(
  p_submission_id uuid,p_score numeric,p_feedback text default null
)
returns jsonb language plpgsql security definer set search_path = ''
as $$
declare v_tutor_id uuid; v_max_score numeric; v_assignment_id uuid;
begin
  if auth.uid() is null then raise exception 'Authentication required'; end if;
  select t.id into v_tutor_id from public.tutors t
  where t.user_id=auth.uid() and t.status::text='active' limit 1;
  if v_tutor_id is null then raise exception 'No active tutor profile is linked to this account'; end if;
  if p_score is null or p_score<0 then raise exception 'Enter a valid score'; end if;
  if length(coalesce(p_feedback,''))>5000 then raise exception 'Feedback is too long'; end if;
  select a.id,a.max_score into v_assignment_id,v_max_score
  from public.assignment_submissions ss join public.assignments a on a.id=ss.assignment_id
  join public.class_tutors ct on ct.class_id=a.class_id and ct.subject_id=a.subject_id
  where ss.id=p_submission_id and a.tutor_id=v_tutor_id and ct.tutor_id=v_tutor_id
    and ss.submitted_at is not null limit 1;
  if v_assignment_id is null then raise exception 'This submission is not assigned to your tutor account'; end if;
  if p_score>v_max_score then raise exception 'Score cannot be greater than the assignment maximum of %',v_max_score; end if;
  update public.assignment_submissions set score=p_score,
    tutor_feedback=nullif(btrim(coalesce(p_feedback,'')),''),
    status='graded',graded_at=now() where id=p_submission_id;
  return jsonb_build_object('submission_id',p_submission_id,'score',p_score,'status','graded');
end;
$$;

revoke all on function private.tutor_workspace_summary() from public,anon;
revoke all on function private.tutor_assignment_submissions(uuid) from public,anon;
revoke all on function private.tutor_grade_assignment_submission(uuid,numeric,text) from public,anon;
grant execute on function private.tutor_workspace_summary() to authenticated;
grant execute on function private.tutor_assignment_submissions(uuid) to authenticated;
grant execute on function private.tutor_grade_assignment_submission(uuid,numeric,text) to authenticated;

create or replace function public.tutor_workspace_summary()
returns jsonb language sql security invoker set search_path=''
as $$ select private.tutor_workspace_summary(); $$;
create or replace function public.tutor_assignment_submissions(p_assignment_id uuid)
returns jsonb language sql security invoker set search_path=''
as $$ select private.tutor_assignment_submissions(p_assignment_id); $$;
create or replace function public.tutor_grade_assignment_submission(p_submission_id uuid,p_score numeric,p_feedback text default null)
returns jsonb language sql security invoker set search_path=''
as $$ select private.tutor_grade_assignment_submission(p_submission_id,p_score,p_feedback); $$;
revoke all on function public.tutor_workspace_summary() from public,anon;
revoke all on function public.tutor_assignment_submissions(uuid) from public,anon;
revoke all on function public.tutor_grade_assignment_submission(uuid,numeric,text) from public,anon;
grant execute on function public.tutor_workspace_summary() to authenticated;
grant execute on function public.tutor_assignment_submissions(uuid) to authenticated;
grant execute on function public.tutor_grade_assignment_submission(uuid,numeric,text) to authenticated;
