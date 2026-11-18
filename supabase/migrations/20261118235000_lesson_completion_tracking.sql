create table if not exists public.lesson_completions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  lesson_id uuid not null references public.lessons(id) on delete cascade,
  completed_at timestamptz not null default now(),
  unique(user_id,lesson_id)
);
alter table public.lesson_completions enable row level security;
drop policy if exists lesson_completions_read_own on public.lesson_completions;
create policy lesson_completions_read_own on public.lesson_completions
  for select to authenticated using ((select auth.uid())=user_id);
revoke all on public.lesson_completions from anon;
revoke insert,update,delete on public.lesson_completions from authenticated;
grant select on public.lesson_completions to authenticated;

create or replace function private.mark_lesson_completed(p_lesson_id uuid)
returns jsonb language plpgsql security definer set search_path=''
as $$
declare v_student_id uuid; v_completion_id uuid;
begin
  if auth.uid() is null then raise exception 'Authentication required'; end if;
  select s.id into v_student_id from public.students s
  where s.user_id=auth.uid() and s.status::text='active' limit 1;
  if v_student_id is null then raise exception 'An active learner profile is required'; end if;
  if not exists (
    select 1 from public.lessons l
    join public.learning_access_requests r on r.user_id=auth.uid() and r.status='approved'
    join public.learning_programmes p on p.id=r.programme_id and p.class_id=l.class_id
    where l.id=p_lesson_id and l.is_published=true
  ) then raise exception 'This lesson is not available in your approved programme'; end if;
  insert into public.lesson_completions(user_id,lesson_id)
  values(auth.uid(),p_lesson_id)
  on conflict(user_id,lesson_id) do update set completed_at=public.lesson_completions.completed_at
  returning id into v_completion_id;
  return jsonb_build_object('completion_id',v_completion_id,'completed',true);
end;
$$;
revoke all on function private.mark_lesson_completed(uuid) from public,anon;
grant execute on function private.mark_lesson_completed(uuid) to authenticated;
create or replace function public.mark_lesson_completed(p_lesson_id uuid)
returns jsonb language sql security invoker set search_path=''
as $$ select private.mark_lesson_completed(p_lesson_id); $$;
revoke all on function public.mark_lesson_completed(uuid) from public,anon;
grant execute on function public.mark_lesson_completed(uuid) to authenticated;
