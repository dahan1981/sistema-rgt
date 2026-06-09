create table if not exists public.units (
  id text primary key,
  label text not null unique
);

create table if not exists public.employees (
  id uuid primary key default gen_random_uuid(),
  full_name text not null,
  unit_id text not null references public.units(id),
  active boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.monthly_statements (
  id uuid primary key default gen_random_uuid(),
  employee_id uuid not null references public.employees(id),
  reference_month date not null,
  salary_forecast numeric(12, 2) not null default 0,
  vouchers numeric(12, 2) not null default 0,
  absences integer not null default 0,
  discount_absences_as_expense boolean not null default true,
  attendance_score integer not null default 0,
  incentive_amount numeric(12, 2) not null default 0,
  sunday_compensation numeric(12, 2) not null default 0,
  launch_sunday_as_revenue boolean not null default false,
  double_shift numeric(12, 2) not null default 0,
  launch_double_shift_as_revenue boolean not null default false,
  balance_bonus numeric(12, 2) not null default 0,
  launch_balance_bonus_as_revenue boolean not null default false,
  launch_negative_cash_as_expense boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (employee_id, reference_month)
);

create table if not exists public.cash_entries (
  id uuid primary key default gen_random_uuid(),
  monthly_statement_id uuid not null references public.monthly_statements(id) on delete cascade,
  entry_date date not null,
  description text not null,
  amount numeric(12, 2) not null,
  kind text not null check (kind in ('positive', 'negative')),
  created_at timestamptz not null default now()
);

create table if not exists public.cash_closings (
  id uuid primary key default gen_random_uuid(),
  entry_date date not null,
  unit_id text not null references public.units(id),
  employee_id uuid not null references public.employees(id),
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

create index if not exists cash_closings_month_lookup_idx
on public.cash_closings (entry_date, unit_id, employee_id);

create or replace function public.calculate_cash_closing_month(
  target_unit_id text,
  target_employee_id uuid,
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
    and employee_id = target_employee_id
    and entry_date >= date_trunc('month', target_date)::date
    and entry_date <= target_date;
$$;

create or replace function public.calculate_statement_total(statement_id uuid)
returns table (
  revenues numeric,
  expenses numeric,
  absence_discount numeric,
  positive_cash numeric,
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
  cash as (
    select
      coalesce(sum(amount) filter (where kind = 'positive'), 0) as positive_cash,
      coalesce(sum(amount) filter (where kind = 'negative'), 0) as negative_cash
    from public.cash_entries
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
    join public.employees e on e.id = b.employee_id
    where cc.employee_id = b.employee_id
      and cc.unit_id = e.unit_id
      and cc.entry_date >= date_trunc('month', current_date)::date
      and cc.entry_date <= current_date
  )
  select
    (
      b.incentive_amount +
      case when b.launch_sunday_as_revenue then b.sunday_compensation else 0 end +
      case when b.launch_double_shift_as_revenue then b.double_shift else 0 end +
      case when b.launch_balance_bonus_as_revenue then b.balance_bonus else 0 end +
      c.positive_cash +
      cl.closing_positive
    ) as revenues,
    (
      b.vouchers +
      case when b.discount_absences_as_expense then b.salary_forecast / 30 * b.absences else 0 end +
      case when b.launch_negative_cash_as_expense then c.negative_cash else 0 end +
      cl.payroll_cash_discount
    ) as expenses,
    case when b.discount_absences_as_expense then b.salary_forecast / 30 * b.absences else 0 end as absence_discount,
    c.positive_cash,
    c.negative_cash,
    cl.closing_positive - cl.closing_negative as partial_cash_closing,
    cl.payroll_cash_discount,
    (
      b.salary_forecast +
      b.incentive_amount +
      case when b.launch_sunday_as_revenue then b.sunday_compensation else 0 end +
      case when b.launch_double_shift_as_revenue then b.double_shift else 0 end +
      case when b.launch_balance_bonus_as_revenue then b.balance_bonus else 0 end +
      cl.closing_positive +
      c.positive_cash -
      b.vouchers -
      case when b.discount_absences_as_expense then b.salary_forecast / 30 * b.absences else 0 end -
      case when b.launch_negative_cash_as_expense then c.negative_cash else 0 end -
      cl.payroll_cash_discount
    ) as final_liability
  from base b
  cross join cash c
  cross join closings cl;
$$;

insert into public.units (id, label)
values
  ('adm', 'ADM'),
  ('geral', 'GERAL'),
  ('largo_do_machado', 'LARGO DO MACHADO'),
  ('laranj', 'LARANJ'),
  ('ktt1', 'KTT1'),
  ('ktt2', 'KTT2'),
  ('ktt3', 'KTT3'),
  ('ktt4', 'KTT4')
on conflict (id) do update set label = excluded.label;
