create table if not exists public.identification_cache (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  lookup_type text not null,
  lookup_key text not null,
  status text not null,
  provider_stage text not null,
  normalized_result jsonb not null default '{}'::jsonb,
  raw_result jsonb,
  expires_at timestamptz not null,
  created_at timestamptz not null default now(),
  constraint identification_cache_lookup_type_check
    check (lookup_type in ('barcode', 'photo')),
  constraint identification_cache_status_check
    check (status in ('matched', 'enriched', 'partial', 'not_found', 'failed')),
  constraint identification_cache_provider_stage_check
    check (provider_stage in ('cache', 'upcitemdb', 'goupc', 'openai', 'comicvine')),
  constraint identification_cache_lookup_key_not_blank_check
    check (char_length(btrim(lookup_key)) > 0),
  constraint identification_cache_normalized_result_object_check
    check (jsonb_typeof(normalized_result) = 'object')
);

create unique index if not exists identification_cache_user_lookup_idx
  on public.identification_cache (user_id, lookup_type, lookup_key);

create index if not exists identification_cache_user_expires_idx
  on public.identification_cache (user_id, expires_at desc);

create index if not exists identification_cache_expiry_idx
  on public.identification_cache (expires_at);

alter table public.identification_cache enable row level security;
alter table public.identification_cache force row level security;

create policy "identification_cache_select_own"
  on public.identification_cache
  for select
  to authenticated
  using ((select auth.uid()) = user_id);

create policy "identification_cache_insert_own"
  on public.identification_cache
  for insert
  to authenticated
  with check ((select auth.uid()) = user_id);

create policy "identification_cache_update_own"
  on public.identification_cache
  for update
  to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

create policy "identification_cache_delete_own"
  on public.identification_cache
  for delete
  to authenticated
  using ((select auth.uid()) = user_id);
