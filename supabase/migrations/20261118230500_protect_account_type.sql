-- Prevent users from changing the account category through their own
-- profile update policy. The category is selected at registration and is
-- used only to route student vs parent experiences.

create or replace function private.prevent_account_type_change()
returns trigger language plpgsql set search_path = ''
as $$
begin
  if auth.uid() is not null and new.account_type is distinct from old.account_type then
    raise exception 'Account type cannot be changed from the profile editor. Contact the centre if it was selected incorrectly.';
  end if;
  return new;
end;
$$;

drop trigger if exists prevent_profile_account_type_change on public.profiles;
create trigger prevent_profile_account_type_change
before update of account_type on public.profiles
for each row execute function private.prevent_account_type_change();
