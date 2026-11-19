alter table public.notifications
  add column if not exists target_type text,
  add column if not exists target_id uuid;

create index if not exists notifications_target_lookup_idx
  on public.notifications(target_type, target_id)
  where target_type is not null and target_id is not null;

create or replace function private.sync_notification_announcement_target()
returns trigger
language plpgsql
set search_path to ''
as $function$
begin
  if new.announcement_id is not null then
    new.target_type := 'announcement';
    new.target_id := new.announcement_id;
  end if;
  return new;
end;
$function$;

drop trigger if exists notifications_sync_announcement_target on public.notifications;
create trigger notifications_sync_announcement_target
before insert or update of announcement_id on public.notifications
for each row execute function private.sync_notification_announcement_target();

update public.notifications
set target_type='announcement', target_id=announcement_id
where announcement_id is not null
  and (target_type is distinct from 'announcement' or target_id is distinct from announcement_id);

create or replace function private.issue_classroom_access_pin(p_request_id uuid)
returns text
language plpgsql
security definer
set search_path to ''
as $function$
declare v_user_id uuid; v_programme_id uuid; v_pin text;
begin
  if auth.uid() is null then raise exception 'Sign in is required'; end if;
  if not (private.has_permission('finance.manage') or private.has_permission('students.manage')) then
    raise exception 'You are not authorised to issue classroom passes';
  end if;
  select user_id, programme_id into v_user_id, v_programme_id
  from public.learning_access_requests
  where id = p_request_id and status = 'approved';
  if not found then raise exception 'Only an approved learning request can receive a classroom pass'; end if;
  v_pin := upper(encode(extensions.gen_random_bytes(5), 'hex'));
  insert into public.classroom_access_passes(request_id,user_id,programme_id,pin_hash,issued_by,issued_at,failed_attempts,redeemed_at,revoked_at)
  values (p_request_id,v_user_id,v_programme_id,encode(extensions.digest(convert_to(v_pin,'UTF8'),'sha256'),'hex'),auth.uid(),now(),0,null,null)
  on conflict (request_id) do update set
    pin_hash=excluded.pin_hash, issued_by=excluded.issued_by, issued_at=now(),
    failed_attempts=0, redeemed_at=null, revoked_at=null;
  insert into public.notifications(user_id,title,body,target_type,target_id)
  values (v_user_id,'Your classroom pass is ready','Your learning payment has been approved. Ask the centre administrator for your unique classroom PIN to unlock your learning programme.','learning_access',p_request_id);
  return v_pin;
end;
$function$;

create or replace function private.publish_announcement(_title text, _body text, _notify_students boolean default true)
returns integer
language plpgsql
security definer
set search_path to ''
as $function$
declare sent_count integer := 0; new_announcement_id uuid;
begin
  if auth.uid() is null or not private.has_permission('communications.send') then
    raise exception 'You do not have permission to publish centre communications';
  end if;
  if length(trim(coalesce(_title,''))) = 0 or length(trim(coalesce(_body,''))) = 0 then
    raise exception 'A title and message are required';
  end if;
  insert into public.announcements(title, body, audience, published_at, created_by)
  values (trim(_title), trim(_body), null, now(), auth.uid())
  returning id into new_announcement_id;

  if coalesce(_notify_students, true) then
    insert into public.notifications(user_id, title, body, announcement_id, target_type, target_id)
    select distinct s.user_id, trim(_title), trim(_body), new_announcement_id, 'announcement', new_announcement_id
    from public.students s
    where s.user_id is not null;
    get diagnostics sent_count = row_count;
  end if;

  insert into public.audit_logs(actor_id, action, entity_type, details)
  values (auth.uid(), 'centre_announcement_published', 'announcement',
          jsonb_build_object('announcement_id',new_announcement_id,'title', trim(_title), 'student_notifications_sent', sent_count));
  return sent_count;
end;
$function$;

create or replace function private.release_result_period(_period_id uuid)
returns integer
language plpgsql
security definer
set search_path to ''
as $function$
declare
  affected integer:=0;
  was_published boolean:=false;
begin
  if auth.uid() is null or not private.has_permission('students.manage') then
    raise exception 'You do not have permission to release student results';
  end if;
  select (status='published') into was_published
  from public.result_periods where id=_period_id;
  if not found then raise exception 'Result period not found'; end if;

  update public.result_periods
  set status='published',published_at=coalesce(published_at,now())
  where id=_period_id;
  update public.results
  set published_at=coalesce(published_at,now())
  where period_id=_period_id;

  if not coalesce(was_published,false) then
    insert into public.notifications(user_id,title,body,target_type,target_id)
    select distinct s.user_id,'Your results are ready',
      'Your '||p.title||' '||coalesce(p.academic_year,'')||' results have been released. Open your learning dashboard to view them.',
      'result_period',_period_id
    from public.result_periods p
    join public.results r on r.period_id=p.id
    join public.students s on s.id=r.student_id
    where p.id=_period_id and s.user_id is not null;
    get diagnostics affected=row_count;
  end if;
  return affected;
end;
$function$;

create or replace function private.review_guardian_link_request(p_request_id uuid, p_decision text, p_admin_note text default null)
returns void
language plpgsql
security definer
set search_path to ''
as $function$
declare
  v_guardian_id uuid; v_student_id uuid; v_guardian_user uuid;
  v_student_name text; v_relationship text;
begin
  if auth.uid() is null or not private.has_permission('students.manage') then
    raise exception 'You are not authorised to review parent link requests';
  end if;
  if p_decision not in ('approved','rejected') then raise exception 'Choose approve or reject'; end if;
  select q.guardian_id,q.student_id,q.guardian_user_id,sp.full_name,q.relationship
  into v_guardian_id,v_student_id,v_guardian_user,v_student_name,v_relationship
  from public.guardian_link_requests q
  left join public.students st on st.id=q.student_id
  left join public.profiles sp on sp.id=st.user_id
  where q.id=p_request_id and q.status='pending'
  for update of q;
  if not found then raise exception 'This parent link request is no longer pending'; end if;
  if p_decision='approved' then
    if v_student_id is null then raise exception 'No matching active learner account was found for this email. Ask the parent to check the email and submit again.'; end if;
    insert into public.student_guardians(student_id,guardian_id,relationship)
    values(v_student_id,v_guardian_id,v_relationship)
    on conflict(student_id,guardian_id) do update set relationship=excluded.relationship;
  end if;
  update public.guardian_link_requests
  set status=p_decision,admin_note=nullif(btrim(coalesce(p_admin_note,'')),''),
      reviewed_by=auth.uid(),reviewed_at=now()
  where id=p_request_id;
  insert into public.notifications(user_id,title,body,target_type,target_id)
  values(
    v_guardian_user,
    case when p_decision='approved' then 'Child account linked' else 'Parent link request reviewed' end,
    case when p_decision='approved'
      then coalesce(v_student_name,'The learner') || ' has been linked to your parent dashboard.'
      else 'Your parent link request was not approved. Please check the learner email or contact the centre.'
    end || case when nullif(btrim(coalesce(p_admin_note,'')),'') is null then '' else ' Note: ' || btrim(p_admin_note) end,
    'parent_link',p_request_id
  );
end;
$function$;

create or replace function private.review_learning_access_request(p_request_id uuid, p_decision text, p_admin_note text default null)
returns void
language plpgsql
security definer
set search_path to ''
as $function$
declare v_user_id uuid; v_title text;
begin
  if auth.uid() is null then raise exception 'Sign in is required'; end if;
  if not (private.has_permission('finance.manage') or private.has_permission('students.manage')) then
    raise exception 'You are not authorised to review learning requests';
  end if;
  if p_decision not in ('approved','rejected') then raise exception 'Choose approve or reject'; end if;
  update public.learning_access_requests
  set status=p_decision,admin_note=nullif(btrim(coalesce(p_admin_note,'')), ''),
      reviewed_by=auth.uid(),reviewed_at=now(),updated_at=now()
  where id=p_request_id and status='payment_submitted'
    and (p_decision='rejected' or payment_amount >= amount_due)
  returning user_id,programme_title into v_user_id,v_title;
  if not found then
    raise exception 'The request is unavailable, or the reported payment is below the programme fee and cannot be approved. You can reject it and ask the learner to resubmit.';
  end if;
  insert into public.notifications(user_id,title,body,target_type,target_id)
  values (
    v_user_id,
    case when p_decision='approved' then 'Learning access approved' else 'Payment needs attention' end,
    case when p_decision='approved'
      then 'Your payment for ' || v_title || ' has been verified. Your classroom access is now approved.'
      else 'Your payment for ' || v_title || ' was not approved. Please review the note and resubmit your payment details.'
    end || case when nullif(btrim(coalesce(p_admin_note,'')),'') is null then '' else ' Admin note: ' || btrim(p_admin_note) end,
    'learning_access',p_request_id
  );
end;
$function$;

create or replace function private.review_tutor_application(p_application_id uuid, p_status text, p_review_note text default null, p_interview_at timestamp with time zone default null)
returns jsonb
language plpgsql
security definer
set search_path to ''
as $function$
declare
  v_app public.tutor_applications%rowtype;
  v_tutor_id uuid;
  v_class_count integer := 0;
  v_subject_count integer := 0;
  v_assignment_count integer := 0;
begin
  if auth.uid() is null or not private.has_permission('staff.manage') then
    raise exception 'You are not authorised to review tutor applications';
  end if;
  if p_status not in ('reviewing','shortlisted','interview_scheduled','approved','rejected') then
    raise exception 'Invalid application status';
  end if;
  if p_status = 'interview_scheduled' and p_interview_at is null then
    raise exception 'Choose an interview date and time';
  end if;

  select * into v_app
  from public.tutor_applications
  where id = p_application_id
  for update;
  if not found then raise exception 'Application not found'; end if;

  update public.tutor_applications set
    status = p_status,
    review_note = nullif(trim(coalesce(p_review_note,'')),''),
    interview_at = case when p_status = 'interview_scheduled' then p_interview_at else interview_at end,
    reviewed_by = auth.uid(),
    reviewed_at = now(),
    updated_at = now()
  where id = p_application_id;

  if p_status = 'approved' then
    insert into public.tutors(user_id,qualification,status)
    values(v_app.user_id,v_app.qualification,'active')
    on conflict(user_id) do update
      set qualification = excluded.qualification, status = 'active'
    returning id into v_tutor_id;

    insert into public.user_roles(user_id,role)
    values(v_app.user_id,'tutor')
    on conflict(user_id,role) do nothing;

    select count(*) into v_class_count
    from public.classes c
    where c.status = 'active'
      and exists (
        select 1 from unnest(v_app.class_levels) selected(name)
        where lower(trim(selected.name)) = lower(trim(c.name))
      );

    select count(*) into v_subject_count
    from public.subjects s
    where s.status = 'active'
      and exists (
        select 1 from unnest(v_app.subjects) selected(name)
        where lower(trim(selected.name)) = lower(trim(s.name))
      );

    insert into public.class_tutors(tutor_id,class_id,subject_id)
    select v_tutor_id,c.id,s.id
    from public.classes c
    cross join public.subjects s
    where c.status = 'active'
      and s.status = 'active'
      and exists (
        select 1 from unnest(v_app.class_levels) selected(name)
        where lower(trim(selected.name)) = lower(trim(c.name))
      )
      and exists (
        select 1 from unnest(v_app.subjects) selected(name)
        where lower(trim(selected.name)) = lower(trim(s.name))
      )
    on conflict(class_id,tutor_id,subject_id) do nothing;

    get diagnostics v_assignment_count = row_count;
  elsif v_app.status = 'approved' then
    update public.tutors set status = 'inactive'
    where user_id = v_app.user_id;
    delete from public.user_roles
    where user_id = v_app.user_id and role = 'tutor';
  end if;

  insert into public.notifications(user_id,title,body,target_type,target_id)
  values(
    v_app.user_id,
    case p_status
      when 'approved' then 'Tutor application approved'
      when 'rejected' then 'Tutor application update'
      when 'interview_scheduled' then 'Tutor interview scheduled'
      else 'Tutor application update'
    end,
    case p_status
      when 'approved' then
        'Your tutor application has been approved. Your tutor workspace is now activated. The centre will contact you with any further onboarding steps.'
      when 'rejected' then
        coalesce(nullif(trim(coalesce(p_review_note,'')),''),'Thank you for applying. The centre has updated your application status.')
      when 'interview_scheduled' then
        'Your interview is scheduled for ' || p_interview_at::text
      else
        'Your tutor application status is now ' || replace(p_status,'_',' ') || '.'
    end,
    'tutor_application',p_application_id
  );

  return jsonb_build_object(
    'success',true,
    'status',p_status,
    'user_id',v_app.user_id,
    'assigned_classes',v_class_count,
    'matched_subjects',v_subject_count,
    'new_class_subject_assignments',v_assignment_count
  );
end;
$function$;
