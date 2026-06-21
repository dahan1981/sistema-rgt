create table if not exists public.units (
  id text primary key,
  label text not null unique,
  display_order integer not null default 0,
  active boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.collaborators (
  id text primary key,
  full_name text not null,
  base_unit_id text not null references public.units(id),
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.unit_assignments (
  id uuid primary key default gen_random_uuid(),
  collaborator_id text not null references public.collaborators(id) on delete cascade,
  assigned_date date not null,
  unit_id text not null references public.units(id),
  created_at timestamptz not null default now(),
  unique (collaborator_id, assigned_date)
);

create table if not exists public.monthly_statements (
  id uuid primary key default gen_random_uuid(),
  collaborator_id text not null references public.collaborators(id) on delete cascade,
  reference_month date not null,
  salary_forecast numeric(12, 2) not null default 0,
  vouchers numeric(12, 2) not null default 0,
  attendance_score integer not null default 0 check (attendance_score >= 0),
  incentive_score integer check (incentive_score between 1 and 3),
  incentive_amount numeric(12, 2) not null default 0,
  balance_bonus numeric(12, 2) not null default 0,
  launch_balance_bonus_as_revenue boolean not null default false,
  launch_negative_cash_as_expense boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (collaborator_id, reference_month)
);

create table if not exists public.absence_entries (
  id uuid primary key default gen_random_uuid(),
  monthly_statement_id uuid not null references public.monthly_statements(id) on delete cascade,
  absence_date date not null,
  as_expense boolean not null default true,
  created_at timestamptz not null default now(),
  unique (monthly_statement_id, absence_date)
);

create table if not exists public.negative_cash_entries (
  id uuid primary key default gen_random_uuid(),
  monthly_statement_id uuid not null references public.monthly_statements(id) on delete cascade,
  entry_date date not null,
  description text not null,
  amount numeric(12, 2) not null check (amount > 0),
  created_at timestamptz not null default now()
);

create table if not exists public.cash_closings (
  id uuid primary key default gen_random_uuid(),
  entry_date date not null,
  unit_id text not null references public.units(id),
  collaborator_id text not null references public.collaborators(id),
  kind text not null check (kind in ('positive', 'negative')),
  amount numeric(12, 2) not null check (amount > 0),
  description text not null,
  deduct_from_payroll boolean not null default false,
  created_at timestamptz not null default now(),
  check (
    kind = 'negative'
    or deduct_from_payroll = false
  )
);

create index if not exists unit_assignments_lookup_idx
on public.unit_assignments (collaborator_id, assigned_date);

create index if not exists collaborators_base_unit_idx
on public.collaborators (base_unit_id);

create index if not exists monthly_statements_lookup_idx
on public.monthly_statements (reference_month, collaborator_id);

create index if not exists monthly_statements_collaborator_idx
on public.monthly_statements (collaborator_id);

create index if not exists absence_entries_statement_idx
on public.absence_entries (monthly_statement_id, absence_date);

create index if not exists negative_cash_entries_statement_idx
on public.negative_cash_entries (monthly_statement_id, entry_date);

create index if not exists cash_closings_month_lookup_idx
on public.cash_closings (entry_date, unit_id, collaborator_id);

create index if not exists cash_closings_collaborator_idx
on public.cash_closings (collaborator_id);

create index if not exists cash_closings_unit_idx
on public.cash_closings (unit_id);

create table if not exists public.audit_log (
  id bigserial primary key,
  table_name text not null,
  record_id text not null,
  action text not null check (action in ('INSERT', 'UPDATE', 'DELETE')),
  old_data jsonb,
  new_data jsonb,
  actor_user_id uuid,
  actor_email text,
  occurred_at timestamptz not null default now()
);

alter table public.units
  add column if not exists updated_at timestamptz not null default now(),
  add column if not exists created_by uuid references auth.users(id),
  add column if not exists updated_by uuid references auth.users(id);

alter table public.collaborators
  add column if not exists created_by uuid references auth.users(id),
  add column if not exists updated_by uuid references auth.users(id);

alter table public.unit_assignments
  add column if not exists updated_at timestamptz not null default now(),
  add column if not exists created_by uuid references auth.users(id),
  add column if not exists updated_by uuid references auth.users(id);

alter table public.monthly_statements
  add column if not exists created_by uuid references auth.users(id),
  add column if not exists updated_by uuid references auth.users(id);

alter table public.absence_entries
  add column if not exists updated_at timestamptz not null default now(),
  add column if not exists created_by uuid references auth.users(id),
  add column if not exists updated_by uuid references auth.users(id);

alter table public.negative_cash_entries
  add column if not exists updated_at timestamptz not null default now(),
  add column if not exists created_by uuid references auth.users(id),
  add column if not exists updated_by uuid references auth.users(id);

alter table public.cash_closings
  add column if not exists updated_at timestamptz not null default now(),
  add column if not exists created_by uuid references auth.users(id),
  add column if not exists updated_by uuid references auth.users(id);

alter table public.monthly_statements
  alter column incentive_score drop not null,
  alter column incentive_score drop default;

create index if not exists audit_log_table_record_idx
on public.audit_log (table_name, record_id, occurred_at desc);

create index if not exists audit_log_actor_idx
on public.audit_log (actor_user_id, occurred_at desc);

create or replace function public.set_audit_fields()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if tg_op = 'INSERT' then
    new.created_at = coalesce(new.created_at, now());
    new.updated_at = coalesce(new.updated_at, now());
    new.created_by = coalesce(new.created_by, auth.uid());
    new.updated_by = coalesce(new.updated_by, auth.uid());
    return new;
  end if;

  if tg_op = 'UPDATE' then
    new.created_at = old.created_at;
    new.created_by = old.created_by;
    new.updated_at = now();
    new.updated_by = auth.uid();
    return new;
  end if;

  return new;
end;
$$;

create or replace function public.write_audit_log()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.audit_log (
    table_name,
    record_id,
    action,
    old_data,
    new_data,
    actor_user_id,
    actor_email
  )
  values (
    tg_table_name,
    case when tg_op = 'DELETE' then old.id::text else new.id::text end,
    tg_op,
    case when tg_op in ('UPDATE', 'DELETE') then to_jsonb(old) else null end,
    case when tg_op in ('INSERT', 'UPDATE') then to_jsonb(new) else null end,
    auth.uid(),
    auth.jwt() ->> 'email'
  );

  if tg_op = 'DELETE' then
    return old;
  end if;

  return new;
end;
$$;

drop trigger if exists units_set_audit_fields on public.units;
create trigger units_set_audit_fields
before insert or update on public.units
for each row execute function public.set_audit_fields();

drop trigger if exists units_audit_log on public.units;
create trigger units_audit_log
after insert or update or delete on public.units
for each row execute function public.write_audit_log();

drop trigger if exists collaborators_set_audit_fields on public.collaborators;
create trigger collaborators_set_audit_fields
before insert or update on public.collaborators
for each row execute function public.set_audit_fields();

drop trigger if exists collaborators_audit_log on public.collaborators;
create trigger collaborators_audit_log
after insert or update or delete on public.collaborators
for each row execute function public.write_audit_log();

drop trigger if exists unit_assignments_set_audit_fields on public.unit_assignments;
create trigger unit_assignments_set_audit_fields
before insert or update on public.unit_assignments
for each row execute function public.set_audit_fields();

drop trigger if exists unit_assignments_audit_log on public.unit_assignments;
create trigger unit_assignments_audit_log
after insert or update or delete on public.unit_assignments
for each row execute function public.write_audit_log();

drop trigger if exists monthly_statements_set_audit_fields on public.monthly_statements;
create trigger monthly_statements_set_audit_fields
before insert or update on public.monthly_statements
for each row execute function public.set_audit_fields();

drop trigger if exists monthly_statements_audit_log on public.monthly_statements;
create trigger monthly_statements_audit_log
after insert or update or delete on public.monthly_statements
for each row execute function public.write_audit_log();

drop trigger if exists absence_entries_set_audit_fields on public.absence_entries;
create trigger absence_entries_set_audit_fields
before insert or update on public.absence_entries
for each row execute function public.set_audit_fields();

drop trigger if exists absence_entries_audit_log on public.absence_entries;
create trigger absence_entries_audit_log
after insert or update or delete on public.absence_entries
for each row execute function public.write_audit_log();

drop trigger if exists negative_cash_entries_set_audit_fields on public.negative_cash_entries;
create trigger negative_cash_entries_set_audit_fields
before insert or update on public.negative_cash_entries
for each row execute function public.set_audit_fields();

drop trigger if exists negative_cash_entries_audit_log on public.negative_cash_entries;
create trigger negative_cash_entries_audit_log
after insert or update or delete on public.negative_cash_entries
for each row execute function public.write_audit_log();

drop trigger if exists cash_closings_set_audit_fields on public.cash_closings;
create trigger cash_closings_set_audit_fields
before insert or update on public.cash_closings
for each row execute function public.set_audit_fields();

drop trigger if exists cash_closings_audit_log on public.cash_closings;
create trigger cash_closings_audit_log
after insert or update or delete on public.cash_closings
for each row execute function public.write_audit_log();

create or replace function public.save_monthly_statement(
  p_collaborator_id text,
  p_reference_month date,
  p_salary_forecast numeric,
  p_vouchers numeric,
  p_attendance_score integer,
  p_incentive_score integer,
  p_balance_bonus numeric,
  p_launch_balance_bonus_as_revenue boolean,
  p_launch_negative_cash_as_expense boolean,
  p_absences jsonb,
  p_negative_cash_entries jsonb
)
returns uuid
language plpgsql
security invoker
set search_path = public
as $$
declare
  target_statement_id uuid;
begin
  if p_reference_month <> date_trunc('month', p_reference_month)::date then
    raise exception 'A competência deve ser o primeiro dia do mês.';
  end if;

  if p_incentive_score is not null and p_incentive_score not between 1 and 3 then
    raise exception 'A pontuação de incentivo deve estar entre 1 e 3.';
  end if;

  insert into public.monthly_statements (
    collaborator_id,
    reference_month,
    salary_forecast,
    vouchers,
    attendance_score,
    incentive_score,
    incentive_amount,
    balance_bonus,
    launch_balance_bonus_as_revenue,
    launch_negative_cash_as_expense
  )
  values (
    p_collaborator_id,
    p_reference_month,
    p_salary_forecast,
    p_vouchers,
    p_attendance_score,
    p_incentive_score,
    case p_incentive_score
      when 1 then 50
      when 2 then 100
      when 3 then 150
      else 0
    end,
    p_balance_bonus,
    p_launch_balance_bonus_as_revenue,
    p_launch_negative_cash_as_expense
  )
  on conflict (collaborator_id, reference_month) do update
  set
    salary_forecast = excluded.salary_forecast,
    vouchers = excluded.vouchers,
    attendance_score = excluded.attendance_score,
    incentive_score = excluded.incentive_score,
    incentive_amount = excluded.incentive_amount,
    balance_bonus = excluded.balance_bonus,
    launch_balance_bonus_as_revenue = excluded.launch_balance_bonus_as_revenue,
    launch_negative_cash_as_expense = excluded.launch_negative_cash_as_expense
  returning id into target_statement_id;

  delete from public.absence_entries
  where monthly_statement_id = target_statement_id;

  insert into public.absence_entries (
    monthly_statement_id,
    absence_date,
    as_expense
  )
  select
    target_statement_id,
    item.absence_date,
    item.as_expense
  from jsonb_to_recordset(coalesce(p_absences, '[]'::jsonb))
    as item(absence_date date, as_expense boolean);

  delete from public.negative_cash_entries
  where monthly_statement_id = target_statement_id;

  insert into public.negative_cash_entries (
    monthly_statement_id,
    entry_date,
    description,
    amount
  )
  select
    target_statement_id,
    item.entry_date,
    trim(item.description),
    item.amount
  from jsonb_to_recordset(coalesce(p_negative_cash_entries, '[]'::jsonb))
    as item(entry_date date, description text, amount numeric)
  where item.amount > 0 and trim(item.description) <> '';

  return target_statement_id;
end;
$$;

revoke all on function public.save_monthly_statement(
  text, date, numeric, numeric, integer, integer, numeric,
  boolean, boolean, jsonb, jsonb
) from public;
grant execute on function public.save_monthly_statement(
  text, date, numeric, numeric, integer, integer, numeric,
  boolean, boolean, jsonb, jsonb
) to authenticated;

create or replace function public.effective_unit_for_collaborator(
  target_collaborator_id text,
  target_date date
)
returns text
language sql
stable
as $$
  select coalesce(
    (
      select ua.unit_id
      from public.unit_assignments ua
      where ua.collaborator_id = target_collaborator_id
        and ua.assigned_date = target_date
      limit 1
    ),
    (
      select c.base_unit_id
      from public.collaborators c
      where c.id = target_collaborator_id
    )
  );
$$;

create or replace function public.calculate_cash_closing_month(
  target_unit_id text,
  target_collaborator_id text,
  target_date date default current_date
)
returns table (
  positive numeric,
  negative numeric,
  payroll_deductions numeric,
  balance numeric
)
language sql
stable
as $$
  select
    coalesce(sum(amount) filter (where kind = 'positive'), 0) as positive,
    coalesce(sum(amount) filter (where kind = 'negative'), 0) as negative,
    coalesce(sum(amount) filter (
      where kind = 'negative' and deduct_from_payroll
    ), 0) as payroll_deductions,
    coalesce(sum(case when kind = 'positive' then amount else -amount end), 0) as balance
  from public.cash_closings
  where unit_id = target_unit_id
    and collaborator_id = target_collaborator_id
    and entry_date >= date_trunc('month', target_date)::date
    and entry_date <= target_date;
$$;

create or replace function public.calculate_statement_total(statement_id uuid)
returns table (
  revenues numeric,
  expenses numeric,
  absence_discount numeric,
  negative_cash numeric,
  partial_cash_closing numeric,
  payroll_cash_discount numeric,
  final_liability numeric
)
language sql
stable
as $$
  with base as (
    select *
    from public.monthly_statements
    where id = statement_id
  ),
  absences as (
    select count(*)::numeric as expense_absence_count
    from public.absence_entries
    where monthly_statement_id = statement_id
      and as_expense
  ),
  negative_cash as (
    select coalesce(sum(amount), 0) as total
    from public.negative_cash_entries
    where monthly_statement_id = statement_id
  ),
  closings as (
    select
      coalesce(sum(amount) filter (where cc.kind = 'positive'), 0) as closing_positive,
      coalesce(sum(amount) filter (where cc.kind = 'negative'), 0) as closing_negative,
      coalesce(sum(amount) filter (
        where cc.kind = 'negative' and cc.deduct_from_payroll
      ), 0) as payroll_cash_discount
    from public.cash_closings cc
    cross join base b
    where cc.collaborator_id = b.collaborator_id
      and cc.unit_id = public.effective_unit_for_collaborator(
        b.collaborator_id,
        cc.entry_date
      )
      and cc.entry_date >= b.reference_month
      and cc.entry_date < (b.reference_month + interval '1 month')::date
  )
  select
    (
      b.incentive_amount +
      case when b.launch_balance_bonus_as_revenue then b.balance_bonus else 0 end +
      cl.closing_positive
    ) as revenues,
    (
      b.vouchers +
      (b.salary_forecast / 30 * a.expense_absence_count) +
      case when b.launch_negative_cash_as_expense then nc.total else 0 end +
      cl.payroll_cash_discount
    ) as expenses,
    b.salary_forecast / 30 * a.expense_absence_count as absence_discount,
    nc.total as negative_cash,
    cl.closing_positive - cl.closing_negative as partial_cash_closing,
    cl.payroll_cash_discount,
    (
      b.salary_forecast +
      b.incentive_amount +
      case when b.launch_balance_bonus_as_revenue then b.balance_bonus else 0 end +
      cl.closing_positive -
      b.vouchers -
      (b.salary_forecast / 30 * a.expense_absence_count) -
      case when b.launch_negative_cash_as_expense then nc.total else 0 end -
      cl.payroll_cash_discount
    ) as final_liability
  from base b
  cross join absences a
  cross join negative_cash nc
  cross join closings cl;
$$;

alter table public.units enable row level security;
alter table public.collaborators enable row level security;
alter table public.unit_assignments enable row level security;
alter table public.monthly_statements enable row level security;
alter table public.absence_entries enable row level security;
alter table public.negative_cash_entries enable row level security;
alter table public.cash_closings enable row level security;
alter table public.audit_log enable row level security;

drop policy if exists "Authenticated users can manage units"
on public.units;
drop policy if exists "Authenticated users can manage collaborators"
on public.collaborators;
drop policy if exists "Authenticated users can manage unit assignments"
on public.unit_assignments;
drop policy if exists "Authenticated users can manage monthly statements"
on public.monthly_statements;
drop policy if exists "Authenticated users can manage absence entries"
on public.absence_entries;
drop policy if exists "Authenticated users can manage negative cash entries"
on public.negative_cash_entries;
drop policy if exists "Authenticated users can manage cash closings"
on public.cash_closings;
drop policy if exists "Authenticated users can read audit log"
on public.audit_log;

create policy "Authenticated users can manage units"
on public.units for all
to authenticated
using (true)
with check (true);

create policy "Authenticated users can manage collaborators"
on public.collaborators for all
to authenticated
using (true)
with check (true);

create policy "Authenticated users can manage unit assignments"
on public.unit_assignments for all
to authenticated
using (true)
with check (true);

create policy "Authenticated users can manage monthly statements"
on public.monthly_statements for all
to authenticated
using (true)
with check (true);

create policy "Authenticated users can manage absence entries"
on public.absence_entries for all
to authenticated
using (true)
with check (true);

create policy "Authenticated users can manage negative cash entries"
on public.negative_cash_entries for all
to authenticated
using (true)
with check (true);

create policy "Authenticated users can manage cash closings"
on public.cash_closings for all
to authenticated
using (true)
with check (true);

create policy "Authenticated users can read audit log"
on public.audit_log for select
to authenticated
using (true);

insert into public.units (id, label, display_order)
values
  ('adm', 'ADM', 10),
  ('geral', 'Geral', 20),
  ('largo_do_machado', 'Largo', 30),
  ('laranj', 'Laranjeiras', 40),
  ('ktt1', 'KTT1', 50),
  ('ktt2', 'KTT2', 60),
  ('ktt3', 'KTT3', 70),
  ('ktt4', 'KTT4', 80)
on conflict (id) do update
set
  label = excluded.label,
  display_order = excluded.display_order;

insert into public.collaborators (id, full_name, base_unit_id)
values
  ('lar-1', 'Daniele', 'laranj'),
  ('lar-2', 'Kethelyn', 'laranj'),
  ('lar-3', 'Priscila', 'largo_do_machado'),
  ('lar-4', 'Flávia', 'largo_do_machado'),
  ('ger-1', 'Denis', 'geral'),
  ('ktt1-1', 'Anna', 'ktt1'),
  ('ktt1-2', 'Rafaela', 'ktt1'),
  ('ktt2-1', 'Patrick', 'ktt2'),
  ('ktt2-2', 'Breno', 'ktt2'),
  ('ktt2-3', 'Danilo', 'ktt2'),
  ('ktt3-1', 'Cainã', 'ktt3'),
  ('ktt3-2', 'Gabriela', 'ktt3'),
  ('ktt4-1', 'Brenda', 'ktt4'),
  ('ktt4-2', 'Dimas', 'ktt4'),
  ('ktt4-3', 'Brendel', 'ktt4'),
  ('adm-1', 'Luiz', 'adm'),
  ('adm-2', 'Fabiana', 'adm'),
  ('adm-3', 'Wesley', 'adm'),
  ('adm-4', 'Jean', 'adm'),
  ('adm-5', 'João', 'adm'),
  ('adm-6', 'Nise', 'adm'),
  ('adm-7', 'Thais', 'adm')
on conflict (id) do update
set
  full_name = excluded.full_name,
  base_unit_id = excluded.base_unit_id,
  updated_at = now();
