create table if not exists public.user_sync_state (
  user_id uuid primary key references auth.users (id) on delete cascade,
  updated_at timestamptz not null default now()
);

alter table public.user_sync_state enable row level security;
alter table public.user_sync_state force row level security;

create policy "user_sync_state_select_own"
  on public.user_sync_state
  for select
  to authenticated
  using ((select auth.uid()) = user_id);

create or replace function public.touch_user_sync_state(p_user_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if p_user_id is null then
    return;
  end if;

  insert into public.user_sync_state (user_id, updated_at)
  values (p_user_id, now())
  on conflict (user_id)
  do update set updated_at = excluded.updated_at;
end;
$$;

create or replace function public.get_current_user_sync_stamp()
returns text
language sql
security definer
set search_path = public
as $$
  select updated_at::text
  from public.user_sync_state
  where user_id = (select auth.uid());
$$;

grant execute on function public.get_current_user_sync_stamp() to authenticated;

create or replace function public.touch_user_sync_state_from_profiles()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  perform public.touch_user_sync_state(coalesce(new.id, old.id));
  return coalesce(new, old);
end;
$$;

create or replace function public.touch_user_sync_state_from_collectibles()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  perform public.touch_user_sync_state(coalesce(new.user_id, old.user_id));
  return coalesce(new, old);
end;
$$;

create or replace function public.touch_user_sync_state_from_collectible_photos()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  target_collectible_id uuid;
  target_user_id uuid;
begin
  target_collectible_id := coalesce(new.collectible_id, old.collectible_id);

  select c.user_id
    into target_user_id
  from public.collectibles c
  where c.id = target_collectible_id;

  perform public.touch_user_sync_state(target_user_id);
  return coalesce(new, old);
end;
$$;

create or replace function public.touch_user_sync_state_from_wishlist_items()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  perform public.touch_user_sync_state(coalesce(new.user_id, old.user_id));
  return coalesce(new, old);
end;
$$;

create or replace function public.touch_user_sync_state_from_tags()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  perform public.touch_user_sync_state(coalesce(new.user_id, old.user_id));
  return coalesce(new, old);
end;
$$;

create or replace function public.touch_user_sync_state_from_collectible_tags()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  target_collectible_id uuid;
  target_user_id uuid;
begin
  target_collectible_id := coalesce(new.collectible_id, old.collectible_id);

  select c.user_id
    into target_user_id
  from public.collectibles c
  where c.id = target_collectible_id;

  perform public.touch_user_sync_state(target_user_id);
  return coalesce(new, old);
end;
$$;

drop trigger if exists touch_user_sync_state_profiles on public.profiles;
create trigger touch_user_sync_state_profiles
  after insert or update or delete
  on public.profiles
  for each row
  execute function public.touch_user_sync_state_from_profiles();

drop trigger if exists touch_user_sync_state_collectibles on public.collectibles;
create trigger touch_user_sync_state_collectibles
  after insert or update or delete
  on public.collectibles
  for each row
  execute function public.touch_user_sync_state_from_collectibles();

drop trigger if exists touch_user_sync_state_collectible_photos on public.collectible_photos;
create trigger touch_user_sync_state_collectible_photos
  after insert or update or delete
  on public.collectible_photos
  for each row
  execute function public.touch_user_sync_state_from_collectible_photos();

drop trigger if exists touch_user_sync_state_wishlist_items on public.wishlist_items;
create trigger touch_user_sync_state_wishlist_items
  after insert or update or delete
  on public.wishlist_items
  for each row
  execute function public.touch_user_sync_state_from_wishlist_items();

drop trigger if exists touch_user_sync_state_tags on public.tags;
create trigger touch_user_sync_state_tags
  after insert or update or delete
  on public.tags
  for each row
  execute function public.touch_user_sync_state_from_tags();

drop trigger if exists touch_user_sync_state_collectible_tags on public.collectible_tags;
create trigger touch_user_sync_state_collectible_tags
  after insert or update or delete
  on public.collectible_tags
  for each row
  execute function public.touch_user_sync_state_from_collectible_tags();
