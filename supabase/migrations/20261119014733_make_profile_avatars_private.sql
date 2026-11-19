-- Profile photos may belong to children. Keep them private and expose them only through
-- short-lived signed URLs generated for the authenticated owner.
update storage.buckets
set public = false,
    file_size_limit = 5242880,
    allowed_mime_types = array['image/jpeg','image/png','image/webp']::text[]
where id = 'profile-avatars';

do $$
begin
  if not exists (select 1 from storage.buckets where id='profile-avatars' and public=false) then
    raise exception 'The profile-avatars storage bucket is missing or could not be made private';
  end if;
end $$;

drop policy if exists profile_avatars_read_own on storage.objects;
create policy profile_avatars_read_own
on storage.objects for select to authenticated
using (
  bucket_id = 'profile-avatars'
  and (storage.foldername(name))[1] = (select auth.uid())::text
);

drop policy if exists profile_avatars_upload_own on storage.objects;
create policy profile_avatars_upload_own
on storage.objects for insert to authenticated
with check (
  bucket_id = 'profile-avatars'
  and (storage.foldername(name))[1] = (select auth.uid())::text
);

drop policy if exists profile_avatars_update_own on storage.objects;
create policy profile_avatars_update_own
on storage.objects for update to authenticated
using (
  bucket_id = 'profile-avatars'
  and (storage.foldername(name))[1] = (select auth.uid())::text
)
with check (
  bucket_id = 'profile-avatars'
  and (storage.foldername(name))[1] = (select auth.uid())::text
);

drop policy if exists profile_avatars_delete_own on storage.objects;
create policy profile_avatars_delete_own
on storage.objects for delete to authenticated
using (
  bucket_id = 'profile-avatars'
  and (storage.foldername(name))[1] = (select auth.uid())::text
);
