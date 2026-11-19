create or replace function private.review_tutor_application(
  p_application_id uuid,
  p_status text,
  p_review_note text default null,
  p_interview_at timestamptz default null
)
returns jsonb language plpgsql security definer set search_path = ''
as $$
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
  select * into v_app from public.tutor_applications where id=p_application_id for update;
  if not found then raise exception 'Application not found'; end if;

  update public.tutor_applications set
    status=p_status,
    review_note=nullif(trim(coalesce(p_review_note,'')),''),
    interview_at=case when p_status='interview_scheduled' then p_interview_at else interview_at end,
    reviewed_by=auth.uid(), reviewed_at=now(), updated_at=now()
  where id=p_application_id;

  if p_status='approved' then
    insert into public.tutors(user_id,qualification,status)
    values(v_app.user_id,v_app.qualification,'active')
    on conflict(user_id) do update set qualification=excluded.qualification,status='active'
    returning id into v_tutor_id;
    insert into public.user_roles(user_id,role) values(v_app.user_id,'tutor')
    on conflict(user_id,role) do nothing;

    select count(*) into v_class_count from public.classes c
    where c.status='active' and exists (
      select 1 from unnest(v_app.class_levels) selected(name)
      where lower(trim(selected.name))=lower(trim(c.name))
    );
    select count(*) into v_subject_count from public.subjects s
    where s.status='active' and exists (
      select 1 from unnest(v_app.subjects) selected(name)
      where lower(trim(selected.name))=lower(trim(s.name))
    );

    insert into public.class_tutors(tutor_id,class_id,subject_id)
    select v_tutor_id,c.id,s.id
    from public.classes c cross join public.subjects s
    where c.status='active' and s.status='active'
      and exists (select 1 from unnest(v_app.class_levels) selected(name)
        where lower(trim(selected.name))=lower(trim(c.name)))
      and exists (select 1 from unnest(v_app.subjects) selected(name)
        where lower(trim(selected.name))=lower(trim(s.name)))
    on conflict(class_id,tutor_id,subject_id) do nothing;
    get diagnostics v_assignment_count=row_count;
  elsif v_app.status='approved' then
    update public.tutors set status='inactive' where user_id=v_app.user_id;
    delete from public.user_roles where user_id=v_app.user_id and role='tutor';
  end if;

  insert into public.notifications(user_id,title,body)
  values(v_app.user_id,
    case p_status when 'approved' then 'Tutor application approved'
      when 'rejected' then 'Tutor application update'
      when 'interview_scheduled' then 'Tutor interview scheduled'
      else 'Tutor application update' end,
    case p_status
      when 'approved' then 'Your tutor application has been approved. Your tutor workspace is now activated. The centre will contact you with any further onboarding steps.'
      when 'rejected' then coalesce(nullif(trim(coalesce(p_review_note,'')),''),'Thank you for applying. The centre has updated your application status.')
      when 'interview_scheduled' then 'Your interview is scheduled for '||p_interview_at::text
      else 'Your tutor application status is now '||replace(p_status,'_',' ')||'.' end);
  return jsonb_build_object('success',true,'status',p_status,'user_id',v_app.user_id,
    'assigned_classes',v_class_count,'matched_subjects',v_subject_count,
    'new_class_subject_assignments',v_assignment_count);
end;
$$;