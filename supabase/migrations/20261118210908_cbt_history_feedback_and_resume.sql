-- Improve CBT resumption, feedback and learner result history.
alter table public.questions add column if not exists explanation text;

create or replace function private.start_student_assessment(p_assessment_id uuid)
returns jsonb language plpgsql security definer set search_path = ''
as $$
declare
  v_student_id uuid;
  v_attempt_id uuid;
  v_started_at timestamptz;
  v_duration integer;
  v_count integer;
  v_remaining integer;
begin
  if auth.uid() is null then raise exception 'Authentication required'; end if;
  select s.id into v_student_id from public.students s
  where s.user_id = auth.uid() and s.status = 'active' limit 1;
  if v_student_id is null then raise exception 'No active learner profile is linked to this account'; end if;

  select a.duration_minutes into v_duration
  from public.assessments a
  join public.enrolments e on e.class_id = a.class_id
  where a.id = p_assessment_id and a.is_published = true
    and e.student_id = v_student_id and e.status = 'active'
    and (a.starts_at is null or a.starts_at <= now())
  limit 1;
  if not found then raise exception 'Assessment is unavailable for this learner'; end if;

  select count(*) into v_count from public.questions q where q.assessment_id = p_assessment_id;
  if v_count = 0 then raise exception 'This assessment has no questions yet'; end if;

  select aa.id, aa.started_at into v_attempt_id, v_started_at
  from public.assessment_attempts aa
  where aa.assessment_id = p_assessment_id
    and aa.student_id = v_student_id
    and aa.submitted_at is null
  order by aa.started_at desc
  limit 1
  for update;

  if found then
    if v_duration is null or v_duration <= 0 then
      return jsonb_build_object('attempt_id',v_attempt_id,'duration_minutes',0,
        'remaining_seconds',0,'question_count',v_count,'resumed',true);
    end if;
    v_remaining := greatest(0, floor(extract(epoch from (v_started_at + make_interval(mins => v_duration) - now())))::integer);
    if v_remaining > 0 then
      return jsonb_build_object('attempt_id',v_attempt_id,'duration_minutes',v_duration,
        'remaining_seconds',v_remaining,'question_count',v_count,'resumed',true);
    end if;
    update public.assessment_attempts
      set answers = coalesce(answers,'{}'::jsonb), score = 0, submitted_at = now()
      where id = v_attempt_id and student_id = v_student_id and submitted_at is null;
  end if;

  insert into public.assessment_attempts(assessment_id,student_id,answers,started_at)
  values(p_assessment_id,v_student_id,'{}'::jsonb,now())
  returning id, started_at into v_attempt_id, v_started_at;

  v_remaining := case when v_duration is null or v_duration <= 0 then 0 else v_duration * 60 end;
  return jsonb_build_object('attempt_id',v_attempt_id,'duration_minutes',coalesce(v_duration,0),
    'remaining_seconds',v_remaining,'question_count',v_count,'resumed',false);
end;
$$;

create or replace function private.submit_student_assessment(p_attempt_id uuid,p_answers jsonb)
returns jsonb language plpgsql security definer set search_path = ''
as $$
declare
  v_student_id uuid;
  v_assessment_id uuid;
  v_started_at timestamptz;
  v_duration integer;
  v_total numeric;
  v_score numeric;
  v_count integer;
  v_answer_count integer;
  v_review jsonb;
begin
  if auth.uid() is null then raise exception 'Authentication required'; end if;
  if p_answers is null or jsonb_typeof(p_answers) <> 'object' then
    raise exception 'Answers must be submitted as an object';
  end if;
  select s.id into v_student_id from public.students s
  where s.user_id = auth.uid() and s.status = 'active' limit 1;
  if v_student_id is null then raise exception 'No active learner profile is linked to this account'; end if;

  select aa.assessment_id,aa.started_at,a.duration_minutes
  into v_assessment_id,v_started_at,v_duration
  from public.assessment_attempts aa
  join public.assessments a on a.id = aa.assessment_id
  join public.enrolments e on e.class_id = a.class_id
  where aa.id = p_attempt_id and aa.student_id = v_student_id
    and aa.submitted_at is null and a.is_published = true
    and e.student_id = v_student_id and e.status = 'active'
  for update of aa;
  if not found then raise exception 'Assessment attempt is unavailable or already submitted'; end if;
  if v_duration is not null and v_duration > 0
    and now() > v_started_at + make_interval(mins => v_duration, secs => 30) then
    raise exception 'The assessment time limit has expired';
  end if;

  select count(*),coalesce(sum(q.marks),0) into v_count,v_total
  from public.questions q where q.assessment_id = v_assessment_id;
  if v_count = 0 then raise exception 'This assessment has no questions yet'; end if;

  select count(*) into v_answer_count
  from jsonb_each(p_answers) a
  join public.questions q on q.id::text = a.key and q.assessment_id = v_assessment_id;
  if v_answer_count <> jsonb_object_length(p_answers) or v_answer_count > v_count then
    raise exception 'The submitted answers do not match this assessment';
  end if;

  select coalesce(sum(q.marks),0) into v_score
  from public.questions q
  where q.assessment_id = v_assessment_id
    and p_answers ? q.id::text
    and q.correct_answer = (p_answers -> q.id::text);

  select coalesce(jsonb_agg(jsonb_build_object(
    'question_id',q.id,
    'question_text',q.question_text,
    'options',q.options,
    'selected_answer',p_answers -> q.id::text,
    'correct_answer',q.correct_answer,
    'is_correct',coalesce((p_answers -> q.id::text) = q.correct_answer,false),
    'explanation',q.explanation,
    'marks',q.marks
  ) order by q.position,q.id),'[]'::jsonb)
  into v_review
  from public.questions q where q.assessment_id = v_assessment_id;

  update public.assessment_attempts
  set answers = p_answers,score = v_score,submitted_at = now()
  where id = p_attempt_id and student_id = v_student_id and submitted_at is null;

  return jsonb_build_object(
    'attempt_id',p_attempt_id,'score',v_score,'total_marks',v_total,
    'percentage',round((v_score/nullif(v_total,0))*100,2),
    'answered',v_answer_count,'question_count',v_count,'review',v_review
  );
end;
$$;

create or replace function private.student_assessment_history()
returns jsonb language plpgsql security definer set search_path = ''
as $$
declare v_student_id uuid; v_history jsonb;
begin
  if auth.uid() is null then raise exception 'Authentication required'; end if;
  select s.id into v_student_id from public.students s
  where s.user_id = auth.uid() and s.status = 'active' limit 1;
  if v_student_id is null then return '[]'::jsonb; end if;

  select coalesce(jsonb_agg(jsonb_build_object(
    'attempt_id',aa.id,
    'assessment_id',a.id,
    'assessment_title',a.title,
    'assessment_type',a.assessment_type,
    'subject_name',sub.name,
    'class_name',c.name,
    'score',coalesce(aa.score,0),
    'total_marks',(select coalesce(sum(q.marks),0) from public.questions q where q.assessment_id = a.id),
    'percentage',round((coalesce(aa.score,0)/nullif((select sum(q.marks) from public.questions q where q.assessment_id = a.id),0))*100,2),
    'started_at',aa.started_at,
    'submitted_at',aa.submitted_at
  ) order by aa.submitted_at desc),'[]'::jsonb)
  into v_history
  from public.assessment_attempts aa
  join public.assessments a on a.id = aa.assessment_id
  join public.subjects sub on sub.id = a.subject_id
  join public.classes c on c.id = a.class_id
  where aa.student_id = v_student_id and aa.submitted_at is not null;
  return v_history;
end;
$$;

create or replace function public.student_assessment_history()
returns jsonb language sql security invoker set search_path = ''
as $$ select private.student_assessment_history(); $$;

revoke all on function private.start_student_assessment(uuid) from public,anon;
revoke all on function private.student_assessment_questions(uuid) from public,anon;
revoke all on function private.submit_student_assessment(uuid,jsonb) from public,anon;
revoke all on function private.student_assessment_history() from public,anon;
grant usage on schema private to authenticated;
grant execute on function private.start_student_assessment(uuid) to authenticated;
grant execute on function private.student_assessment_questions(uuid) to authenticated;
grant execute on function private.submit_student_assessment(uuid,jsonb) to authenticated;
grant execute on function private.student_assessment_history() to authenticated;

revoke all on function public.start_student_assessment(uuid) from public,anon;
revoke all on function public.student_assessment_questions(uuid) from public,anon;
revoke all on function public.submit_student_assessment(uuid,jsonb) from public,anon;
revoke all on function public.student_assessment_history() from public,anon;
grant execute on function public.start_student_assessment(uuid) to authenticated;
grant execute on function public.student_assessment_questions(uuid) to authenticated;
grant execute on function public.submit_student_assessment(uuid,jsonb) to authenticated;
grant execute on function public.student_assessment_history() to authenticated;
