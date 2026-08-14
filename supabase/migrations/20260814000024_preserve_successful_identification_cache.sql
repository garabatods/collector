create or replace function private.cleanup_expired_identification_caches(
  p_batch_size integer default 5000
)
returns table (
  identification_rows_deleted integer,
  barcode_rows_deleted integer
)
language plpgsql
set search_path = ''
as $$
begin
  with expired as (
    select cache.id
    from public.identification_cache cache
    where cache.status in ('not_found', 'failed')
      and cache.expires_at < now() - interval '1 day'
    order by cache.expires_at
    limit greatest(p_batch_size, 0)
  )
  delete from public.identification_cache cache
  using expired
  where cache.id = expired.id
    and cache.status in ('not_found', 'failed')
    and cache.expires_at < now() - interval '1 day';
  get diagnostics identification_rows_deleted = row_count;

  with expired as (
    select cache.barcode
    from public.barcode_catalog_cache cache
    where cache.status in ('not_found', 'failed')
      and cache.expires_at < now() - interval '1 day'
    order by cache.expires_at
    limit greatest(p_batch_size, 0)
  )
  delete from public.barcode_catalog_cache cache
  using expired
  where cache.barcode = expired.barcode
    and cache.status in ('not_found', 'failed')
    and cache.expires_at < now() - interval '1 day';
  get diagnostics barcode_rows_deleted = row_count;

  return next;
end;
$$;

revoke all on function private.cleanup_expired_identification_caches(integer)
  from public, anon, authenticated;
