create or replace function private.tutor_workspace_summary()
returns jsonb language plpgsql stable security definer set search_path = '' as $$
declare v_tutor_id uuid; v_result jsonb;
begin
  if auth.uid() is null then raise exception 'Authentication required'; end if;
  select t.id into v_tutor_id from public.tutors t
    where t.user_id=auth.uid() and t.status::text='active' limit 1;
  if v_tutor_id is null then raise exception 'No active tutor profile is linked to this account'; end if;
  select jsonb_build_object(
    'classes',coalesce((
      select jsonb_agg(jsonb_build_object('class_id',c.id,'class_name',c.name,'level',c.level,'subject_id',s.id,'subject_name',s.name) order by c.name,s.name)
      from public.class_tutors ct join public.classes c on c.id=ct.class_id join public.subjects s on s.id=ct.subject_id
      where ct.tutor_id=v_tutor_id
    ),'[]'::jsonb),
    'lessons',coalesce((
      select jsonb_agg(jsonb_build_object('id',l.id,'title',l.title,'description',l.description,'content',l.content,
        'live_class_url',l.live_class_url,'scheduled_at',l.scheduled_at,'duration_minutes',l.duration_minutes,
        'class_name',c.name,'subject_name',s.name) order by l.scheduled_at nulls last,l.created_at desc)
      from public.lessons l join public.class_tutors ct
        on ct.class_id=l.class_id and ct.subject_id=l.subject_id and ct.tutor_id=v_tutor_id
      join public.classes c on c.id=l.class_id join public.subjects s on s.id=l.subject_id
      where l.is_published=true
    ),'[]'::jsonb),
    'assignments',coalesce((
      select jsonb_agg(jsonb_build_object(
        'id',a.id,'title',a.title,'instructions',a.instructions,'due_at',a.due_at,
        'max_score',a.max_score,'published_at',a.published_at,'assignment_type',a.assignment_type,
        'class_name',c.name,'subject_name',s.name,
        'submission_count',(select count(*) from public.assignment_submissions ss where ss.assignment_id=a.id and ss.submitted_at is not null),
        'graded_count',(select count(*) from public.assignment_submissions ss where ss.assignment_id=a.id and ss.status::text='graded')
      ) order by a.created_at desc)
      from public.assignments a join public.class_tutors ct
        on ct.class_id=a.class_id and ct.subject_id=a.subject_id and ct.tutor_id=v_tutor_id
      join public.classes c on c.id=a.class_id join public.subjects s on s.id=a.subject_id
      where a.tutor_id=v_tutor_id
    ),'[]'::jsonb)
  ) into v_result;
  return v_result;
end; $$;