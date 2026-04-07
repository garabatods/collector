alter table public.collectibles
  add column if not exists franchise text,
  add column if not exists line_or_series text,
  add column if not exists character_or_subject text,
  add column if not exists release_year integer,
  add column if not exists box_status text,
  add column if not exists is_duplicate boolean not null default false;

alter table public.wishlist_items
  add column if not exists franchise text,
  add column if not exists line_or_series text,
  add column if not exists character_or_subject text,
  add column if not exists release_year integer,
  add column if not exists box_status text;

update public.collectibles
set line_or_series = series
where line_or_series is null
  and series is not null;

update public.wishlist_items
set line_or_series = series
where line_or_series is null
  and series is not null;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'collectibles_release_year_reasonable_check'
      and conrelid = 'public.collectibles'::regclass
  ) then
    alter table public.collectibles
      add constraint collectibles_release_year_reasonable_check
      check (
        release_year is null
        or release_year between 1900 and extract(year from now())::integer + 1
      );
  end if;
end
$$;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'wishlist_items_release_year_reasonable_check'
      and conrelid = 'public.wishlist_items'::regclass
  ) then
    alter table public.wishlist_items
      add constraint wishlist_items_release_year_reasonable_check
      check (
        release_year is null
        or release_year between 1900 and extract(year from now())::integer + 1
      );
  end if;
end
$$;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'collectibles_box_status_check'
      and conrelid = 'public.collectibles'::regclass
  ) then
    alter table public.collectibles
      add constraint collectibles_box_status_check
      check (
        box_status is null
        or box_status in ('sealed', 'boxed', 'partial_box', 'loose')
      );
  end if;
end
$$;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'wishlist_items_box_status_check'
      and conrelid = 'public.wishlist_items'::regclass
  ) then
    alter table public.wishlist_items
      add constraint wishlist_items_box_status_check
      check (
        box_status is null
        or box_status in ('sealed', 'boxed', 'partial_box', 'loose')
      );
  end if;
end
$$;

create index if not exists collectibles_user_id_franchise_idx
  on public.collectibles (user_id, franchise);

create index if not exists collectibles_user_id_duplicate_idx
  on public.collectibles (user_id, created_at desc)
  where is_duplicate;
