-- Execute depois de receber os dois e-mails definitivos.
-- Os e-mails devem estar em letras minúsculas.

insert into public.authorized_users (email, display_name, role)
values
  ('primeiro.usuario@empresa.com', 'Primeiro usuário', 'admin'),
  ('segundo.usuario@empresa.com', 'Segundo usuário', 'rh')
on conflict (email) do update
set
  display_name = excluded.display_name,
  role = excluded.role,
  active = true,
  updated_at = now();
