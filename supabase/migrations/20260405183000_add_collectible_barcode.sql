alter table public.collectibles
  add column if not exists barcode text;

create index if not exists collectibles_user_barcode_idx
  on public.collectibles (user_id, barcode)
  where barcode is not null;
