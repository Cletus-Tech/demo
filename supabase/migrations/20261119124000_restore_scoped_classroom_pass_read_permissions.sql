revoke select on table public.classroom_access_passes from authenticated;
grant select (request_id, user_id, redeemed_at, revoked_at)
on table public.classroom_access_passes to authenticated;
