create or replace function private.admin_centre_reports()
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_report jsonb;
begin
  if auth.uid() is null or not (
    private.has_permission('reports.view')
    or private.has_permission('students.manage')
    or private.has_permission('finance.manage')
  ) then
    raise exception 'You are not authorised to view centre reports';
  end if;

  select jsonb_build_object(
    'overview', jsonb_build_object(
      'registered_accounts', (select count(*) from public.profiles),
      'student_accounts', (select count(*) from public.profiles where account_type = 'student'),
      'parent_accounts', (select count(*) from public.profiles where account_type = 'parent'),
      'active_tutors', (select count(*) from public.tutors where status::text = 'active'),
      'active_programmes', (select count(*) from public.learning_programmes where is_active = true),
      'approved_learners', (select count(distinct user_id) from public.learning_access_requests where status = 'approved')
    ),
    'requests', jsonb_build_object(
      'awaiting_payment', (select count(*) from public.learning_access_requests where status = 'awaiting_payment'),
      'payment_submitted', (select count(*) from public.learning_access_requests where status = 'payment_submitted'),
      'approved', (select count(*) from public.learning_access_requests where status = 'approved'),
      'rejected', (select count(*) from public.learning_access_requests where status = 'rejected')
    ),
    'finance', jsonb_build_object(
      'awaiting_verification', coalesce((select sum(payment_amount) from public.learning_access_requests where status = 'payment_submitted'),0),
      'verified_payments', coalesce((select sum(payment_amount) from public.learning_access_requests where status = 'approved'),0),
      'approved_programme_value', coalesce((select sum(amount_due) from public.learning_access_requests where status = 'approved'),0)
    ),
    'attendance', jsonb_build_object(
      'total_records', (select count(*) from public.attendance_records),
      'present', (select count(*) from public.attendance_records where status::text = 'present'),
      'late', (select count(*) from public.attendance_records where status::text = 'late'),
      'absent', (select count(*) from public.attendance_records where status::text = 'absent'),
      'excused', (select count(*) from public.attendance_records where status::text = 'excused')
    ),
    'assignments', jsonb_build_object(
      'published', (select count(*) from public.assignments where published_at is not null),
      'submissions', (select count(*) from public.assignment_submissions where submitted_at is not null),
      'graded', (select count(*) from public.assignment_submissions where status::text = 'graded'),
      'awaiting_review', (select count(*) from public.assignment_submissions where submitted_at is not null and status::text <> 'graded')
    ),
    'assessments', jsonb_build_object(
      'published', (select count(*) from public.assessments where is_published = true and coalesce(is_past_question,false) = false),
      'past_question_sets', (select count(*) from public.assessments where is_published = true and is_past_question = true),
      'completed_attempts', (select count(*) from public.assessment_attempts where submitted_at is not null),
      'average_percentage', (
        select round(avg((aa.score / nullif(a.total_marks,0)) * 100),1)
        from public.assessment_attempts aa
        join public.assessments a on a.id = aa.assessment_id
        where aa.submitted_at is not null and a.total_marks > 0
      )
    ),
    'class_summary', coalesce((
      select jsonb_agg(jsonb_build_object(
        'class_name', c.name, 'level', lp.level, 'stage', lp.stage,
        'active', lp.is_active,
        'approved_learners', (
          select count(distinct r.user_id)
          from public.learning_access_requests r
          where r.programme_id = lp.id and r.status = 'approved'
        )
      ) order by c.name, lp.title)
      from public.learning_programmes lp
      join public.classes c on c.id = lp.class_id
    ), '[]'::jsonb),
    'recent_requests', coalesce((
      select jsonb_agg(jsonb_build_object(
        'learner_name', r.learner_name, 'level', r.level,
        'programme_title', r.programme_title, 'amount_due', r.amount_due,
        'payment_amount', r.payment_amount, 'status', r.status,
        'created_at', r.created_at
      ) order by r.created_at desc)
      from (select * from public.learning_access_requests order by created_at desc limit 8) r
    ), '[]'::jsonb)
  ) into v_report;
  return v_report;
end;
$$;

revoke all on function private.admin_centre_reports() from public, anon;
grant execute on function private.admin_centre_reports() to authenticated;

create or replace function public.admin_centre_reports()
returns jsonb
language sql
security invoker
set search_path = ''
as $$ select private.admin_centre_reports(); $$;
revoke all on function public.admin_centre_reports() from public, anon;
grant execute on function public.admin_centre_reports() to authenticated;
