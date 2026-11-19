-- RLS policies do not grant SQL table privileges by themselves.
-- Authenticated users may read countdowns; RLS still restricts writes
-- to users with communications.send through dashboard_countdowns_manage.
grant select, insert, update, delete on table public.dashboard_countdowns to authenticated;
