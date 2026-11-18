-- Student CBT assessment access.
-- Questions and answer keys remain behind private SECURITY DEFINER functions.
-- Public RPC wrappers are SECURITY INVOKER and expose only learner-scoped data.

create or replace function private.student_available_assessments()
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_student_id uuid;
  v_items jsonb;
begin
  if auth.uid() is null then raise exception 'Authentication required'; end if;
  select s.id into v_student_id from public.students s
  where s.user_id = auth.uid() and s.status = 'active' limit 1;
  if v_student_id is null then return '[]'::jsonb; end if;

  select coalesce(jsonb_agg(jsonb_build_object(
    'id', a.id, 'title', a.title, 'assessment_type', a.assessment_type,
    'starts_at', a.starts_at, 'duration_minutes', a.duration_minutes,
    'total_marks', a.total_marks, 'subject_name', sub.name,
    'class_name', c.name,
    'question_count', (select count(*) from public.questions q where q.assessment_id = a.id)
  ) order by a.starts_at nulls last, a.created_at desc), '[]'::jsonb)
  into v_items
  from public.assessments a
  join public.classes c on c.id = a.class_id
  join public.subjects sub on sub.id = a.subject_id
  where a.is_published = true and exists (
    select 1 from public.enrolments e
    where e.student_id = v_student_id and e.class_id = a.class_id and e.status = 'active'
  );
  return v_items;
end;
$$;

create or replace function private.student_assessment_questions(p_assessment_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_student_id uuid;
  v_questions jsonb;
begin
  if auth.uid() is null then raise exception 'Authentication required'; end if;
  select s.id into v_student_id from public.students s
  where s.user_id = auth.uid() and s.status = 'active' limit 1;

  if v_student_id is null or not exists (
    select 1 from public.assessments a
    join public.enrolments e on e.class_id = a.class_id
    where a.id = p_assessment_id and a.is_published = true
      and e.student_id = v_student_id and e.status = 'active'
      and (a.starts_at is null or a.starts_at <= now())
  ) then raise exception 'Assessment is unavailable for this learner'; end if;

  select coalesce(jsonb_agg(jsonb_build_object(
    'id', q.id, 'question_text', q.question_text, 'options', q.options,
    'marks', q.marks, 'position', q.position
  ) order by q.position, q.id), '[]'::jsonb)
  into v_questions from public.questions q where q.assessment_id = p_assessment_id;
  return v_questions;
end;
$$;

create or replace function private.submit_student_assessment(p_assessment_id uuid, p_answers jsonb)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_student_id uuid;
  v_total numeric;
  v_score numeric;
  v_count integer;
  v_answer_count integer;
  v_attempt_id uuid;
begin
  if auth.uid() is null then raise exception 'Authentication required'; end if;
  if p_answers is null or jsonb_typeof(p_answers) <> 'object' then
    raise exception 'Answers must be submitted as an object';
  end if;
  select s.id into v_student_id from public.students s
  where s.user_id = auth.uid() and s.status = 'active' limit 1;
  if v_student_id is null then raise exception 'No active learner profile is linked to this account'; end if;

  perform 1 from public.assessments a
  join public.enrolments e on e.class_id = a.class_id
  where a.id = p_assessment_id and a.is_published = true
    and e.student_id = v_student_id and e.status = 'active'
    and (a.starts_at is null or a.starts_at <= now())
  for share of a;
  if not found then raise exception 'Assessment is unavailable for this learner'; end if;

  select count(*), coalesce(sum(q.marks), 0) into v_count, v_total
  from public.questions q where q.assessment_id = p_assessment_id;
  if v_count = 0 then raise exception 'This assessment has no questions yet'; end if;

  select count(*) into v_answer_count
  from jsonb_each(p_answers) a
  join public.questions q on q.id::text = a.key and q.assessment_id = p_assessment_id;
  if v_answer_count <> jsonb_object_length(p_answers) or v_answer_count > v_count then
    raise exception 'The submitted answers do not match this assessment';
  end if;

  select coalesce(sum(q.marks), 0) into v_score
  from jsonb_each(p_answers) a
  join public.questions q on q.id::text = a.key and q.assessment_id = p_assessment_id
  where q.correct_answer = a.value;

  insert into public.assessment_attempts
    (assessment_id, student_id, answers, score, submitted_at)
  values (p_assessment_id, v_student_id, p_answers, v_score, now())
  returning id into v_attempt_id;

  return jsonb_build_object(
    'attempt_id', v_attempt_id, 'score', v_score, 'total_marks', v_total,
    'percentage', round((v_score / nullif(v_total, 0)) * 100, 2),
    'answered', v_answer_count, 'question_count', v_count
  );
end;
$$;

revoke all on function private.student_available_assessments() from public, anon;
revoke all on function private.student_assessment_questions(uuid) from public, anon;
revoke all on function private.submit_student_assessment(uuid, jsonb) from public, anon;
grant usage on schema private to authenticated;
grant execute on function private.student_available_assessments() to authenticated;
grant execute on function private.student_assessment_questions(uuid) to authenticated;
grant execute on function private.submit_student_assessment(uuid, jsonb) to authenticated;

create or replace function public.student_available_assessments()
returns jsonb language sql security invoker set search_path = ''
as $$ select private.student_available_assessments(); $$;
create or replace function public.student_assessment_questions(p_assessment_id uuid)
returns jsonb language sql security invoker set search_path = ''
as $$ select private.student_assessment_questions(p_assessment_id); $$;
create or replace function public.submit_student_assessment(p_assessment_id uuid, p_answers jsonb)
returns jsonb language sql security invoker set search_path = ''
as $$ select private.submit_student_assessment(p_assessment_id, p_answers); $$;

revoke all on function public.student_available_assessments() from public, anon;
revoke all on function public.student_assessment_questions(uuid) from public, anon;
revoke all on function public.submit_student_assessment(uuid, jsonb) from public, anon;
grant execute on function public.student_available_assessments() to authenticated;
grant execute on function public.student_assessment_questions(uuid) to authenticated;
grant execute on function public.submit_student_assessment(uuid, jsonb) to authenticated;
