-- Achievement ownership belongs to the collector account, not to an individual
-- device. The only client-readable data is the caller's own award history.
create table public.collector_badge_awards (
  user_id uuid not null references auth.users (id) on delete cascade,
  badge_id text not null,
  earned_at timestamptz not null default now(),
  award_origin text not null,
  primary key (user_id, badge_id),
  constraint collector_badge_awards_origin_check
    check (award_origin in ('action', 'backfill'))
);

create index collector_badge_awards_user_earned_idx
  on public.collector_badge_awards (user_id, earned_at desc);

alter table public.collector_badge_awards enable row level security;

create policy collector_badge_awards_select_own
  on public.collector_badge_awards for select to authenticated
  using ((select auth.uid()) = user_id);

revoke all on public.collector_badge_awards from public, anon, authenticated;
grant select on public.collector_badge_awards to authenticated;

-- These functions deliberately validate the finite set of app badge ids and
-- use the account from the authenticated JWT. A unique primary key makes both
-- backfills and concurrent devices idempotent.
create or replace function public.backfill_collector_badges(p_badge_ids text[])
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if (select auth.uid()) is null then
    raise exception 'authentication required' using errcode = '42501';
  end if;

  insert into public.collector_badge_awards (user_id, badge_id, award_origin)
  select (select auth.uid()), candidate.badge_id, 'backfill'
  from (
    select distinct btrim(badge_id) as badge_id
    from unnest(coalesce(p_badge_ids, '{}'::text[])) as badge_id
  ) as candidate
  where candidate.badge_id = any (array[
    'firstShelf',
    'archiveStarter',
    'shelfExpander',
    'deepArchive',
    'centuryShelf',
    'photoReady',
    'photoKeeper',
    'fullyFramed',
    'favoriteFinder',
    'curatedEye',
    'categoryBuilder',
    'focusedCollector',
    'universeBuilder'
  ])
  on conflict (user_id, badge_id) do nothing;
end;
$$;

create or replace function public.claim_collector_badges(p_badge_ids text[])
returns table (badge_id text, earned_at timestamptz)
language plpgsql
security definer
set search_path = ''
as $$
begin
  if (select auth.uid()) is null then
    raise exception 'authentication required' using errcode = '42501';
  end if;

  return query
  insert into public.collector_badge_awards (user_id, badge_id, award_origin)
  select (select auth.uid()), candidate.badge_id, 'action'
  from (
    select distinct btrim(input_badge_id) as badge_id
    from unnest(coalesce(p_badge_ids, '{}'::text[])) as input_badge_id
  ) as candidate
  where candidate.badge_id = any (array[
    'firstShelf',
    'archiveStarter',
    'shelfExpander',
    'deepArchive',
    'centuryShelf',
    'photoReady',
    'photoKeeper',
    'fullyFramed',
    'favoriteFinder',
    'curatedEye',
    'categoryBuilder',
    'focusedCollector',
    'universeBuilder'
  ])
  on conflict (user_id, badge_id) do nothing
  returning collector_badge_awards.badge_id, collector_badge_awards.earned_at;
end;
$$;

revoke execute on function public.backfill_collector_badges(text[]) from public, anon;
revoke execute on function public.claim_collector_badges(text[]) from public, anon;
grant execute on function public.backfill_collector_badges(text[]) to authenticated;
grant execute on function public.claim_collector_badges(text[]) to authenticated;
