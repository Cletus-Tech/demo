-- Only learner accounts with an active student profile can request
-- classroom access. Parent accounts use the guardian dashboard instead.

create or replace function private.create_learning_access_request(
  p_programme_id uuid,p_learner_name text,p_level text
) returns uuid
language plpgsql security definer set search_path = ''
as $$
declare v_programme public.learning_programmes%rowtype; v_id uuid;
begin
  if auth.uid() is null then raise exception 'Sign in is required'; end if;
  if not exists (
    select 1 from public.students st
    join public.profiles pr on pr.id=st.user_id
    where st.user_id=auth.uid() and st.status='active'
      and pr.account_type='student'
  ) then
    raise exception 'Only learner accounts can request classroom access. Parents should use the parent dashboard.';
  end if;
  if length(btrim(coalesce(p_learner_name,''))) < 2 then raise exception 'Enter the learner name'; end if;
  if length(btrim(coalesce(p_level,''))) < 2 then raise exception 'Choose a learning level'; end if;
  select * into v_programme from public.learning_programmes
    where id=p_programme_id and is_active=true;
  if not found then raise exception 'This learning programme is no longer available'; end if;
  if exists (
    select 1 from public.learning_access_requests r
    where r.user_id=auth.uid() and r.programme_id=p_programme_id
      and r.status in ('awaiting_payment','payment_submitted','approved')
  ) then
    raise exception 'You already have an active request for this programme';
  end if;
  insert into public.learning_access_requests(
    user_id,learner_name,level,programme_id,programme_title,amount_due,status
  ) values (
    auth.uid(),btrim(p_learner_name),btrim(p_level),v_programme.id,
    v_programme.title,v_programme.fee,'awaiting_payment'
  ) returning id into v_id;
  return v_id;
end;
$$;
