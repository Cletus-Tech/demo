-- Permit the classroom directory and lesson policies to inspect only
-- the redemption state required for access decisions. Never expose pin_hash.
grant select (request_id, user_id, redeemed_at, revoked_at)
on public.classroom_access_passes to authenticated;

drop policy if exists classroom_access_passes_read_redemption_state
on public.classroom_access_passes;

create policy classroom_access_passes_read_redemption_state
on public.classroom_access_passes
for select
to authenticated
using (
  user_id = (select auth.uid())
  or private.has_permission('students.manage')
  or private.has_permission('academics.manage')
  or private.has_permission('staff.manage')
);

comment on policy classroom_access_passes_read_redemption_state
on public.classroom_access_passes is
'Allows learners and authorised centre managers to read redemption state only; PIN hashes and attempt metadata remain inaccessible.';
