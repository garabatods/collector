create table if not exists public.barcode_catalog_cache (
  barcode text primary key,
  status text not null,
  provider_stage text not null,
  normalized_result jsonb not null default '{}'::jsonb,
  raw_result jsonb,
  expires_at timestamptz not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint barcode_catalog_cache_barcode_not_blank_check
    check (char_length(btrim(barcode)) > 0),
  constraint barcode_catalog_cache_status_check
    check (status in ('matched', 'enriched', 'partial', 'not_found', 'failed')),
  constraint barcode_catalog_cache_provider_stage_check
    check (provider_stage in ('cache', 'upcitemdb', 'goupc', 'openai', 'comicvine')),
  constraint barcode_catalog_cache_normalized_result_object_check
    check (jsonb_typeof(normalized_result) = 'object')
);

create index if not exists barcode_catalog_cache_expires_idx
  on public.barcode_catalog_cache (expires_at desc);

alter table public.barcode_catalog_cache enable row level security;
alter table public.barcode_catalog_cache force row level security;

drop trigger if exists set_barcode_catalog_cache_updated_at on public.barcode_catalog_cache;
create trigger set_barcode_catalog_cache_updated_at
  before update on public.barcode_catalog_cache
  for each row execute function public.set_updated_at();
