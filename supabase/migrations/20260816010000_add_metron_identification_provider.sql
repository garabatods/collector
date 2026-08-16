-- Metron is a comic-specific catalog provider used by identify_collectible.
-- This changes only validation metadata for cached provider labels; no cached
-- results, collectibles, photos, or user records are rewritten.

alter table public.identification_cache
  drop constraint if exists identification_cache_provider_stage_check;

alter table public.identification_cache
  add constraint identification_cache_provider_stage_check
  check (provider_stage in ('cache', 'upcitemdb', 'goupc', 'metron', 'openai', 'comicvine'));

alter table public.barcode_catalog_cache
  drop constraint if exists barcode_catalog_cache_provider_stage_check;

alter table public.barcode_catalog_cache
  add constraint barcode_catalog_cache_provider_stage_check
  check (provider_stage in ('cache', 'upcitemdb', 'goupc', 'metron', 'openai', 'comicvine'));
