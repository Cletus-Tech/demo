-- Enforce server-side start and submission windows for CBT attempts.
create or replace function private.start_student_assessment(p_assessment_id uuid)
returns jsonb language plpgsql security definer set search_path = ''
as $$
declare v_student_id uuid; v_attempt_id uuid; v_duration integer; v_count integer;
begin
  if auth.uid() is null then raise exception 'Authentication required'; end if;
  select s.id into v_student_id from public.students s
  where s.user_id = auth.uid() and s.status = 'active' limit 1;
  if v_student_id is null then raise exception 'No active learner profile is linked to this account'; end if;
  select a.duration_minutes into v_duration
  from public.assessments a join public.enrolments e on e.class_id = a.class_id
  where a.id = p_assessment_id and a.is_published = true
    and e.student_id = v_student_id and e.status = 'active'
    and (a.starts_at is null or a.starts_at <= now()) limit 1;
  if not found then raise exception 'Assessment is unavailable for this learner'; end if;
  select count(*) into v_count from public.questions q where q.assessment_id = p_assessment_id;
  if v_count = 0 then raise exception 'This assessment has no questions yet'; end if;
  insert into public.assessment_attempts(assessment_id, student_id, answers, started_at)
  values(p_assessment_id, v_student_id, '{}'::jsonb, now()) returning id into v_attempt_id;
  return jsonb_build_object('attempt_id', v_attempt_id, 'duration_minutes', v_duration, 'question_count', v_count);
end;
$$;

drop function if exists public.student_assessment_questions(uuid);
drop function if exists private.student_assessment_questions(uuid);
create function private.student_assessment_questions(p_attempt_id uuid)
returns jsonb language plpgsql security definer set search_path = ''
as $$
declare v_student_id uuid; v_assessment_id uuid; v_started_at timestamptz; v_duration integer; v_questions jsonb;
begin
  if auth.uid() is null then raise exception 'Authentication required'; end if;
  select s.id into v_student_id from public.students s
  where s.user_id = auth.uid() and s.status = 'active' limit 1;
  select aa.assessment_id, aa.started_at, a.duration_minutes
  into v_assessment_id, v_started_at, v_duration
  from public.assessment_attempts aa join public.assessments a on a.id = aa.assessment_id
  where aa.id = p_attempt_id and aa.student_id = v_student_id
    and aa.submitted_at is null and a.is_published = true;
  if not found then raise exception 'Assessment attempt is unavailable'; end if;
  if v_duration is not null and v_duration > 0
     and now() > v_started_at + make_interval(mins => v_duration, secs => 30) then
    raise exception 'The assessment time limit has expired';
  end if;
  select coalesce(jsonb_agg(jsonb_build_object(
    'id', q.id, 'question_text', q.question_text, 'options', q.options,
    'marks', q.marks, 'position', q.position
  ) order by q.position, q.id), '[]'::jsonb)
  into v_questions from public.questions q where q.assessment_id = v_assessment_id;
  return v_questions;
end;
$$;

drop function if exists public.submit_student_assessment(uuid, jsonb);
drop function if exists private.submit_student_assessment(uuid, jsonb);
create function private.submit_student_assessment(p_attempt_id uuid, p_answers jsonb)
returns jsonb language plpgsql security definer set search_path = ''
as $$
declare
  v_student_id uuid; v_assessment_id uuid; v_started_at timestamptz; v_duration integer;
  v_total numeric; v_score numeric; v_count integer; v_answer_count integer;
begin
  if auth.uid() is null then raise exception 'Authentication required'; end if;
  if p_answers is null or jsonb_typeof(p_answers) <> 'object' then raise exception 'Answers must be submitted as an object'; end if;
  select s.id into v_student_id from public.students s
  where s.user_id = auth.uid() and s.status = 'active' limit 1;
  if v_student_id is null then raise exception 'No active learner profile is linked to this account'; end if;
  select aa.assessment_id, aa.started_at, a.duration_minutes
  into v_assessment_id, v_started_at, v_duration
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
  select count(*), coalesce(sum(q.marks), 0) into v_count, v_total
  from public.questions q where q.assessment_id = v_assessment_id;
  if v_count = 0 then raise exception 'This assessment has no questions yet'; end if;
  select count(*) into v_answer_count
  from jsonb_each(p_answers) a join public.questions q
    on q.id::text = a.key and q.assessment_id = v_assessment_id;
  if v_answer_count <> jsonb_object_length(p_answers) or v_answer_count > v_count then
    raise exception 'The submitted answers do not match this assessment';
  end if;
  select coalesce(sum(q.marks), 0) into v_score
  from jsonb_each(p_answers) a join public.questions q
    on q.id::text = a.key and q.assessment_id = v_assessment_id
  where q.correct_answer = a.value;
  update public.assessment_attempts set answers = p_answers, score = v_score, submitted_at = now()
  where id = p_attempt_id and student_id = v_student_id and submitted_at is null;
  return jsonb_build_object('attempt_id', p_attempt_id, 'score', v_score, 'total_marks', v_total,
    'percentage', round((v_score / nullif(v_total, 0)) * 100, 2),
    'answered', v_answer_count, 'question_count', v_count);
end;
$$;

create or replace function public.start_student_assessment(p_assessment_id uuid)
returns jsonb language sql security invoker set search_path = ''
as $$ select private.start_student_assessment(p_assessment_id); $$;
create or replace function public.student_assessment_questions(p_attempt_id uuid)
returns jsonb language sql security invoker set search_path = ''
as $$ select private.student_assessment_questions(p_attempt_id); $$;
create or replace function public.submit_student_assessment(p_attempt_id uuid, p_answers jsonb)
returns jsonb language sql security invoker set search_path = ''
as $$ select private.submit_student_assessment(p_attempt_id, p_answers); $$;

revoke all on function private.start_student_assessment(uuid) from public, anon;
revoke all on function private.student_assessment_questions(uuid) from public, anon;
revoke all on function private.submit_student_assessment(uuid, jsonb) from public, anon;
grant usage on schema private to authenticated;
grant execute on function private.start_student_assessment(uuid) to authenticated;
grant execute on function private.student_assessment_questions(uuid) to authenticated;
grant execute on function private.submit_student_assessment(uuid, jsonb) to authenticated;
revoke all on function public.start_student_assessment(uuid) from public, anon;
revoke all on function public.student_assessment_questions(uuid) from public, anon;
revoke all on function public.submit_student_assessment(uuid, jsonb) from public, anon;
grant execute on function public.start_student_assessment(uuid) to authenticated;
grant execute on function public.student_assessment_questions(uuid) to authenticated;
grant execute on function public.submit_student_assessment(uuid, jsonb) to authenticated;
