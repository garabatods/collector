create table public.barcode_scan_diagnostics (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  build_number integer not null,
  scanner_version text not null,
  category text,
  base_barcode text not null,
  supplement text,
  source text not null,
  outcome text not null,
  observation_count integer not null default 0,
  duration_ms integer not null default 0,
  created_at timestamptz not null default now(),
  constraint barcode_scan_diagnostics_base_digits_check
    check (base_barcode ~ '^[0-9]{12,13}$'),
  constraint barcode_scan_diagnostics_supplement_digits_check
    check (supplement is null or supplement ~ '^[0-9]{5}$'),
  constraint barcode_scan_diagnostics_outcome_check
    check (outcome in ('confirmed', 'timeout', 'manual', 'series_only')),
  constraint barcode_scan_diagnostics_counts_check
    check (observation_count >= 0 and duration_ms >= 0)
);

create index barcode_scan_diagnostics_user_created_idx
  on public.barcode_scan_diagnostics (user_id, created_at desc);
create index barcode_scan_diagnostics_created_idx
  on public.barcode_scan_diagnostics (created_at);

alter table public.barcode_scan_diagnostics enable row level security;
alter table public.barcode_scan_diagnostics force row level security;

create policy barcode_scan_diagnostics_select_own
  on public.barcode_scan_diagnostics for select to authenticated
  using ((select auth.uid()) = user_id);

create policy barcode_scan_diagnostics_insert_own
  on public.barcode_scan_diagnostics for insert to authenticated
  with check ((select auth.uid()) = user_id);

revoke all on public.barcode_scan_diagnostics from public, anon, authenticated;
grant select, insert on public.barcode_scan_diagnostics to authenticated;

create schema if not exists private;
revoke all on schema private from public, anon, authenticated;

create or replace function private.cleanup_barcode_scan_diagnostics()
returns integer
language plpgsql
set search_path = ''
as $$
declare
  deleted_count integer;
begin
  delete from public.barcode_scan_diagnostics
  where created_at < now() - interval '30 days';
  get diagnostics deleted_count = row_count;
  return deleted_count;
end;
$$;

revoke all on function private.cleanup_barcode_scan_diagnostics()
  from public, anon, authenticated;

select cron.schedule(
  'cleanup-barcode-scan-diagnostics',
  '37 4 * * *',
  'select private.cleanup_barcode_scan_diagnostics()'
);
