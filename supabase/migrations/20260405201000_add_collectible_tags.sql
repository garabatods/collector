create table public.tags (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  name text not null,
  created_at timestamptz not null default now(),
  constraint tags_name_not_blank_check
    check (char_length(btrim(name)) > 0)
);

create unique index tags_user_id_lower_name_unique_idx
  on public.tags (user_id, lower(name));

create index tags_user_id_created_at_idx
  on public.tags (user_id, created_at desc);

create table public.collectible_tags (
  collectible_id uuid not null references public.collectibles (id) on delete cascade,
  tag_id uuid not null references public.tags (id) on delete cascade,
  created_at timestamptz not null default now(),
  constraint collectible_tags_pkey primary key (collectible_id, tag_id)
);

create index collectible_tags_tag_id_idx
  on public.collectible_tags (tag_id);

create index collectible_tags_collectible_id_created_at_idx
  on public.collectible_tags (collectible_id, created_at asc);

alter table public.tags enable row level security;
alter table public.collectible_tags enable row level security;

alter table public.tags force row level security;
alter table public.collectible_tags force row level security;

create policy "tags_select_own"
  on public.tags
  for select
  to authenticated
  using ((select auth.uid()) = user_id);

create policy "tags_insert_own"
  on public.tags
  for insert
  to authenticated
  with check ((select auth.uid()) = user_id);

create policy "tags_update_own"
  on public.tags
  for update
  to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

create policy "tags_delete_own"
  on public.tags
  for delete
  to authenticated
  using ((select auth.uid()) = user_id);

create policy "collectible_tags_select_own"
  on public.collectible_tags
  for select
  to authenticated
  using (
    exists (
      select 1
      from public.collectibles
      where collectibles.id = collectible_tags.collectible_id
        and collectibles.user_id = (select auth.uid())
    )
    and exists (
      select 1
      from public.tags
      where tags.id = collectible_tags.tag_id
        and tags.user_id = (select auth.uid())
    )
  );

create policy "collectible_tags_insert_own"
  on public.collectible_tags
  for insert
  to authenticated
  with check (
    exists (
      select 1
      from public.collectibles
      where collectibles.id = collectible_tags.collectible_id
        and collectibles.user_id = (select auth.uid())
    )
    and exists (
      select 1
      from public.tags
      where tags.id = collectible_tags.tag_id
        and tags.user_id = (select auth.uid())
    )
  );

create policy "collectible_tags_update_own"
  on public.collectible_tags
  for update
  to authenticated
  using (
    exists (
      select 1
      from public.collectibles
      where collectibles.id = collectible_tags.collectible_id
        and collectibles.user_id = (select auth.uid())
    )
    and exists (
      select 1
      from public.tags
      where tags.id = collectible_tags.tag_id
        and tags.user_id = (select auth.uid())
    )
  )
  with check (
    exists (
      select 1
      from public.collectibles
      where collectibles.id = collectible_tags.collectible_id
        and collectibles.user_id = (select auth.uid())
    )
    and exists (
      select 1
      from public.tags
      where tags.id = collectible_tags.tag_id
        and tags.user_id = (select auth.uid())
    )
  );

create policy "collectible_tags_delete_own"
  on public.collectible_tags
  for delete
  to authenticated
  using (
    exists (
      select 1
      from public.collectibles
      where collectibles.id = collectible_tags.collectible_id
        and collectibles.user_id = (select auth.uid())
    )
    and exists (
      select 1
      from public.tags
      where tags.id = collectible_tags.tag_id
        and tags.user_id = (select auth.uid())
    )
  );
