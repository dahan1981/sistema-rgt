insert into storage.buckets (id, name, public)
values ('app-updates', 'app-updates', true)
on conflict (id) do update
set public = excluded.public;

drop policy if exists "Public can read app updates"
on storage.objects;
drop policy if exists "Authenticated users can upload app updates"
on storage.objects;
drop policy if exists "Authenticated users can update app updates"
on storage.objects;
drop policy if exists "Authenticated users can delete app updates"
on storage.objects;

create policy "Public can read app updates"
on storage.objects for select
to public
using (bucket_id = 'app-updates');

create policy "Authenticated users can upload app updates"
on storage.objects for insert
to authenticated
with check (bucket_id = 'app-updates');

create policy "Authenticated users can update app updates"
on storage.objects for update
to authenticated
using (bucket_id = 'app-updates')
with check (bucket_id = 'app-updates');

create policy "Authenticated users can delete app updates"
on storage.objects for delete
to authenticated
using (bucket_id = 'app-updates');
