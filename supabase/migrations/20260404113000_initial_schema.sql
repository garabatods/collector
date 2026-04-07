create extension if not exists pgcrypto with schema extensions;

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  username text,
  display_name text,
  avatar_url text,
  bio text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint profiles_username_format_check
    check (
      username is null
      or username ~ '^[a-z0-9_]{3,24}$'
    ),
  constraint profiles_display_name_not_blank_check
    check (
      display_name is null
      or char_length(btrim(display_name)) > 0
    )
);

create unique index profiles_username_lower_unique_idx
  on public.profiles (lower(username))
  where username is not null;

create table public.collectibles (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  title text not null,
  category text not null,
  description text,
  brand text,
  series text,
  item_number text,
  item_condition text,
  quantity integer not null default 1,
  purchase_price numeric(12, 2),
  estimated_value numeric(12, 2),
  acquired_on date,
  notes text,
  is_favorite boolean not null default false,
  is_grail boolean not null default false,
  open_to_trade boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint collectibles_title_not_blank_check
    check (char_length(btrim(title)) > 0),
  constraint collectibles_category_not_blank_check
    check (char_length(btrim(category)) > 0),
  constraint collectibles_category_not_new_category_check
    check (lower(btrim(category)) <> 'new category'),
  constraint collectibles_quantity_positive_check
    check (quantity > 0),
  constraint collectibles_purchase_price_non_negative_check
    check (purchase_price is null or purchase_price >= 0),
  constraint collectibles_estimated_value_non_negative_check
    check (estimated_value is null or estimated_value >= 0)
);

create index collectibles_user_id_created_at_idx
  on public.collectibles (user_id, created_at desc);

create index collectibles_user_id_category_idx
  on public.collectibles (user_id, category);

create index collectibles_user_id_favorites_idx
  on public.collectibles (user_id, created_at desc)
  where is_favorite;

create index collectibles_user_id_grails_idx
  on public.collectibles (user_id, created_at desc)
  where is_grail;

create index collectibles_user_id_trade_idx
  on public.collectibles (user_id, created_at desc)
  where open_to_trade;

create table public.collectible_photos (
  id uuid primary key default gen_random_uuid(),
  collectible_id uuid not null references public.collectibles (id) on delete cascade,
  storage_bucket text not null default 'collectible-photos',
  storage_path text not null,
  caption text,
  is_primary boolean not null default false,
  display_order integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint collectible_photos_bucket_check
    check (storage_bucket = 'collectible-photos'),
  constraint collectible_photos_storage_path_not_blank_check
    check (char_length(btrim(storage_path)) > 0),
  constraint collectible_photos_display_order_non_negative_check
    check (display_order >= 0),
  constraint collectible_photos_storage_path_unique
    unique (storage_bucket, storage_path)
);

create index collectible_photos_collectible_id_idx
  on public.collectible_photos (collectible_id);

create index collectible_photos_collectible_sort_idx
  on public.collectible_photos (collectible_id, is_primary desc, display_order asc, created_at asc);

create unique index collectible_photos_one_primary_per_collectible_idx
  on public.collectible_photos (collectible_id)
  where is_primary;

create table public.wishlist_items (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  title text not null,
  category text not null,
  description text,
  brand text,
  series text,
  priority text not null default 'medium',
  target_price numeric(12, 2),
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint wishlist_items_title_not_blank_check
    check (char_length(btrim(title)) > 0),
  constraint wishlist_items_category_not_blank_check
    check (char_length(btrim(category)) > 0),
  constraint wishlist_items_category_not_new_category_check
    check (lower(btrim(category)) <> 'new category'),
  constraint wishlist_items_priority_check
    check (priority in ('low', 'medium', 'high')),
  constraint wishlist_items_target_price_non_negative_check
    check (target_price is null or target_price >= 0)
);

create index wishlist_items_user_id_created_at_idx
  on public.wishlist_items (user_id, created_at desc);

create index wishlist_items_user_id_priority_idx
  on public.wishlist_items (user_id, priority, created_at desc);

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, display_name)
  values (
    new.id,
    nullif(
      coalesce(
        new.raw_user_meta_data ->> 'display_name',
        split_part(coalesce(new.email, ''), '@', 1)
      ),
      ''
    )
  )
  on conflict (id) do nothing;

  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

create trigger set_profiles_updated_at
  before update on public.profiles
  for each row execute function public.set_updated_at();

create trigger set_collectibles_updated_at
  before update on public.collectibles
  for each row execute function public.set_updated_at();

create trigger set_collectible_photos_updated_at
  before update on public.collectible_photos
  for each row execute function public.set_updated_at();

create trigger set_wishlist_items_updated_at
  before update on public.wishlist_items
  for each row execute function public.set_updated_at();

alter table public.profiles enable row level security;
alter table public.collectibles enable row level security;
alter table public.collectible_photos enable row level security;
alter table public.wishlist_items enable row level security;

alter table public.profiles force row level security;
alter table public.collectibles force row level security;
alter table public.collectible_photos force row level security;
alter table public.wishlist_items force row level security;

create policy "profiles_select_own"
  on public.profiles
  for select
  to authenticated
  using ((select auth.uid()) = id);

create policy "profiles_insert_own"
  on public.profiles
  for insert
  to authenticated
  with check ((select auth.uid()) = id);

create policy "profiles_update_own"
  on public.profiles
  for update
  to authenticated
  using ((select auth.uid()) = id)
  with check ((select auth.uid()) = id);

create policy "collectibles_select_own"
  on public.collectibles
  for select
  to authenticated
  using ((select auth.uid()) = user_id);

create policy "collectibles_insert_own"
  on public.collectibles
  for insert
  to authenticated
  with check ((select auth.uid()) = user_id);

create policy "collectibles_update_own"
  on public.collectibles
  for update
  to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

create policy "collectibles_delete_own"
  on public.collectibles
  for delete
  to authenticated
  using ((select auth.uid()) = user_id);

create policy "collectible_photos_select_own"
  on public.collectible_photos
  for select
  to authenticated
  using (
    exists (
      select 1
      from public.collectibles
      where collectibles.id = collectible_photos.collectible_id
        and collectibles.user_id = (select auth.uid())
    )
  );

create policy "collectible_photos_insert_own"
  on public.collectible_photos
  for insert
  to authenticated
  with check (
    exists (
      select 1
      from public.collectibles
      where collectibles.id = collectible_photos.collectible_id
        and collectibles.user_id = (select auth.uid())
    )
  );

create policy "collectible_photos_update_own"
  on public.collectible_photos
  for update
  to authenticated
  using (
    exists (
      select 1
      from public.collectibles
      where collectibles.id = collectible_photos.collectible_id
        and collectibles.user_id = (select auth.uid())
    )
  )
  with check (
    exists (
      select 1
      from public.collectibles
      where collectibles.id = collectible_photos.collectible_id
        and collectibles.user_id = (select auth.uid())
    )
  );

create policy "collectible_photos_delete_own"
  on public.collectible_photos
  for delete
  to authenticated
  using (
    exists (
      select 1
      from public.collectibles
      where collectibles.id = collectible_photos.collectible_id
        and collectibles.user_id = (select auth.uid())
    )
  );

create policy "wishlist_items_select_own"
  on public.wishlist_items
  for select
  to authenticated
  using ((select auth.uid()) = user_id);

create policy "wishlist_items_insert_own"
  on public.wishlist_items
  for insert
  to authenticated
  with check ((select auth.uid()) = user_id);

create policy "wishlist_items_update_own"
  on public.wishlist_items
  for update
  to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

create policy "wishlist_items_delete_own"
  on public.wishlist_items
  for delete
  to authenticated
  using ((select auth.uid()) = user_id);

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'collectible-photos',
  'collectible-photos',
  false,
  52428800,
  array['image/jpeg', 'image/png', 'image/webp', 'image/heic', 'image/heif']
)
on conflict (id) do update
set public = excluded.public,
    file_size_limit = excluded.file_size_limit,
    allowed_mime_types = excluded.allowed_mime_types;

create policy "collectible_photo_objects_select_own"
  on storage.objects
  for select
  to authenticated
  using (
    bucket_id = 'collectible-photos'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

create policy "collectible_photo_objects_insert_own"
  on storage.objects
  for insert
  to authenticated
  with check (
    bucket_id = 'collectible-photos'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

create policy "collectible_photo_objects_update_own"
  on storage.objects
  for update
  to authenticated
  using (
    bucket_id = 'collectible-photos'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  )
  with check (
    bucket_id = 'collectible-photos'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

create policy "collectible_photo_objects_delete_own"
  on storage.objects
  for delete
  to authenticated
  using (
    bucket_id = 'collectible-photos'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );
