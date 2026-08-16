create type public.ownzith_plan as enum ('free', 'pro');
create type public.ownzith_entitlement_status as enum (
  'inactive',
  'active',
  'grace_period',
  'billing_issue',
  'expired',
  'refunded'
);
create type public.ownzith_usage_feature as enum ('photo_id', 'upc_lookup');
create type public.ownzith_usage_state as enum ('reserved', 'consumed', 'refunded');

create table public.user_entitlements (
  user_id uuid primary key references auth.users (id) on delete cascade,
  plan public.ownzith_plan not null default 'free',
  status public.ownzith_entitlement_status not null default 'inactive',
  source text not null default 'none',
  product_id text,
  original_transaction_id text,
  source_event_at timestamptz,
  current_period_end timestamptz,
  beta_access_until timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint user_entitlements_source_not_blank
    check (char_length(btrim(source)) > 0)
);

create table public.user_limit_overrides (
  user_id uuid primary key references auth.users (id) on delete cascade,
  item_limit integer,
  photo_monthly_limit integer,
  photo_daily_limit integer,
  upc_monthly_limit integer,
  upc_daily_limit integer,
  reason text not null,
  expires_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint user_limit_overrides_values_positive check (
    (item_limit is null or item_limit > 0)
    and (photo_monthly_limit is null or photo_monthly_limit > 0)
    and (photo_daily_limit is null or photo_daily_limit > 0)
    and (upc_monthly_limit is null or upc_monthly_limit > 0)
    and (upc_daily_limit is null or upc_daily_limit > 0)
  ),
  constraint user_limit_overrides_reason_not_blank
    check (char_length(btrim(reason)) > 0)
);

create table public.feature_usage_events (
  request_id uuid primary key,
  user_id uuid not null references auth.users (id) on delete cascade,
  feature public.ownzith_usage_feature not null,
  state public.ownzith_usage_state not null default 'reserved',
  provider text,
  model text,
  fallback_used boolean not null default false,
  input_tokens integer,
  output_tokens integer,
  cache_hit boolean not null default false,
  duration_ms integer,
  outcome text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  finalized_at timestamptz,
  constraint feature_usage_events_token_counts_non_negative check (
    (input_tokens is null or input_tokens >= 0)
    and (output_tokens is null or output_tokens >= 0)
    and (duration_ms is null or duration_ms >= 0)
  )
);

create table public.feature_usage_periods (
  user_id uuid not null references auth.users (id) on delete cascade,
  feature public.ownzith_usage_feature not null,
  period_kind text not null,
  period_start date not null,
  consumed_count integer not null default 0,
  updated_at timestamptz not null default now(),
  primary key (user_id, feature, period_kind, period_start),
  constraint feature_usage_periods_kind_check
    check (period_kind in ('lifetime', 'month', 'day')),
  constraint feature_usage_periods_count_non_negative
    check (consumed_count >= 0)
);

create table public.revenuecat_webhook_events (
  event_id text primary key,
  event_type text not null,
  app_user_id text,
  payload jsonb not null,
  processed_at timestamptz not null default now(),
  constraint revenuecat_webhook_event_id_not_blank
    check (char_length(btrim(event_id)) > 0)
);

create table public.ownzith_runtime_settings (
  singleton boolean primary key default true check (singleton),
  item_enforcement_enabled boolean not null default false,
  usage_enforcement_enabled boolean not null default false,
  public_launch_at timestamptz,
  updated_at timestamptz not null default now()
);

insert into public.ownzith_runtime_settings (singleton) values (true);

create index feature_usage_events_user_feature_created_idx
  on public.feature_usage_events (user_id, feature, created_at desc)
  where state in ('reserved', 'consumed');

create index feature_usage_events_stale_reservations_idx
  on public.feature_usage_events (created_at)
  where state = 'reserved';

alter table public.user_entitlements enable row level security;
alter table public.user_limit_overrides enable row level security;
alter table public.feature_usage_events enable row level security;
alter table public.feature_usage_periods enable row level security;
alter table public.revenuecat_webhook_events enable row level security;
alter table public.ownzith_runtime_settings enable row level security;

alter table public.user_entitlements force row level security;
alter table public.user_limit_overrides force row level security;
alter table public.feature_usage_events force row level security;
alter table public.feature_usage_periods force row level security;
alter table public.revenuecat_webhook_events force row level security;
alter table public.ownzith_runtime_settings force row level security;

create policy user_entitlements_select_own
  on public.user_entitlements for select to authenticated
  using ((select auth.uid()) = user_id);

create policy feature_usage_events_select_own
  on public.feature_usage_events for select to authenticated
  using ((select auth.uid()) = user_id);

create policy feature_usage_periods_select_own
  on public.feature_usage_periods for select to authenticated
  using ((select auth.uid()) = user_id);

revoke all on public.user_entitlements from public, anon, authenticated;
revoke all on public.user_limit_overrides from public, anon, authenticated;
revoke all on public.feature_usage_events from public, anon, authenticated;
revoke all on public.feature_usage_periods from public, anon, authenticated;
revoke all on public.revenuecat_webhook_events from public, anon, authenticated;
revoke all on public.ownzith_runtime_settings from public, anon, authenticated;
grant select on public.user_entitlements to authenticated;
grant select on public.feature_usage_events to authenticated;
grant select on public.feature_usage_periods to authenticated;

create trigger set_user_entitlements_updated_at
  before update on public.user_entitlements
  for each row execute function public.set_updated_at();

create trigger set_user_limit_overrides_updated_at
  before update on public.user_limit_overrides
  for each row execute function public.set_updated_at();

-- Accounts present when this migration is deployed receive beta Pro. Set
-- beta_access_until to the public-launch timestamp before enabling enforcement.
insert into public.user_entitlements (
  user_id,
  plan,
  status,
  source,
  beta_access_until
)
select id, 'pro', 'active', 'prelaunch_beta', 'infinity'::timestamptz
from auth.users
on conflict (user_id) do nothing;

create or replace function public.grant_prelaunch_pro_access()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  launch_at timestamptz;
begin
  select public_launch_at into launch_at
  from public.ownzith_runtime_settings
  where singleton;
  if launch_at is null or now() < launch_at then
    insert into public.user_entitlements (
      user_id, plan, status, source, beta_access_until
    ) values (
      new.id, 'pro', 'active', 'prelaunch_beta', coalesce(launch_at, 'infinity'::timestamptz)
    ) on conflict (user_id) do nothing;
  end if;
  return new;
end;
$$;

create trigger grant_prelaunch_pro_access_on_signup
  after insert on auth.users
  for each row execute function public.grant_prelaunch_pro_access();

create or replace function public.configure_ownzith_public_launch(target_launch_at timestamptz)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if (select auth.role()) <> 'service_role' then
    raise exception 'service role required' using errcode = '42501';
  end if;
  if target_launch_at is null then
    raise exception 'public launch timestamp is required' using errcode = '22023';
  end if;
  update public.ownzith_runtime_settings
  set public_launch_at = target_launch_at, updated_at = now()
  where singleton;
  update public.user_entitlements
  set beta_access_until = target_launch_at, updated_at = now()
  where source = 'prelaunch_beta'
    and (beta_access_until is null or beta_access_until = 'infinity'::timestamptz);
end;
$$;

create or replace function public.ownzith_access_for_user(target_user_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  entitlement public.user_entitlements%rowtype;
  override_row public.user_limit_overrides%rowtype;
  pro_active boolean := false;
  item_count integer := 0;
  item_limit integer;
  photo_monthly_limit integer;
  photo_daily_limit integer;
  upc_monthly_limit integer;
  upc_daily_limit integer;
  photo_monthly_used integer := 0;
  photo_daily_used integer := 0;
  photo_lifetime_used integer := 0;
  upc_monthly_used integer := 0;
  upc_daily_used integer := 0;
  month_start timestamptz := date_trunc('month', now() at time zone 'UTC') at time zone 'UTC';
  day_start timestamptz := date_trunc('day', now() at time zone 'UTC') at time zone 'UTC';
begin
  select * into entitlement
  from public.user_entitlements
  where user_id = target_user_id;

  pro_active := entitlement.user_id is not null
    and entitlement.plan = 'pro'
    and entitlement.status in ('active', 'grace_period', 'billing_issue')
    and (
      (entitlement.source = 'prelaunch_beta'
        and entitlement.beta_access_until is not null
        and entitlement.beta_access_until > now())
      or (entitlement.source <> 'prelaunch_beta'
        and (entitlement.current_period_end is null or entitlement.current_period_end > now()))
    );

  select * into override_row
  from public.user_limit_overrides
  where user_id = target_user_id
    and (expires_at is null or expires_at > now());

  item_limit := coalesce(override_row.item_limit, case when pro_active then 10000 else 20 end);
  photo_monthly_limit := coalesce(override_row.photo_monthly_limit, case when pro_active then 50 else 3 end);
  photo_daily_limit := coalesce(override_row.photo_daily_limit, case when pro_active then 10 else 3 end);
  upc_monthly_limit := coalesce(override_row.upc_monthly_limit, case when pro_active then 100 else 0 end);
  upc_daily_limit := coalesce(override_row.upc_daily_limit, case when pro_active then 25 else 0 end);

  select count(*)::integer into item_count
  from public.collectibles
  where user_id = target_user_id;

  select coalesce(max(consumed_count), 0)::integer into photo_lifetime_used
  from public.feature_usage_periods
  where user_id = target_user_id and feature = 'photo_id'
    and period_kind = 'lifetime';
  select coalesce(max(consumed_count), 0)::integer into photo_monthly_used
  from public.feature_usage_periods
  where user_id = target_user_id and feature = 'photo_id'
    and period_kind = 'month' and period_start = month_start::date;
  select coalesce(max(consumed_count), 0)::integer into photo_daily_used
  from public.feature_usage_periods
  where user_id = target_user_id and feature = 'photo_id'
    and period_kind = 'day' and period_start = day_start::date;
  select coalesce(max(consumed_count), 0)::integer into upc_monthly_used
  from public.feature_usage_periods
  where user_id = target_user_id and feature = 'upc_lookup'
    and period_kind = 'month' and period_start = month_start::date;
  select coalesce(max(consumed_count), 0)::integer into upc_daily_used
  from public.feature_usage_periods
  where user_id = target_user_id and feature = 'upc_lookup'
    and period_kind = 'day' and period_start = day_start::date;

  return jsonb_build_object(
    'plan', case when pro_active then 'pro' else 'free' end,
    'is_pro', pro_active,
    'status', coalesce(entitlement.status::text, 'inactive'),
    'item_enforcement_enabled', (select item_enforcement_enabled from public.ownzith_runtime_settings where singleton),
    'usage_enforcement_enabled', (select usage_enforcement_enabled from public.ownzith_runtime_settings where singleton),
    'expiration', case
      when entitlement.beta_access_until is not null and entitlement.beta_access_until > now()
        then entitlement.beta_access_until
      else entitlement.current_period_end
    end,
    'item_count', item_count,
    'item_limit', item_limit,
    'photo_id_used', case when pro_active then photo_monthly_used else photo_lifetime_used end,
    'photo_id_limit', photo_monthly_limit,
    'photo_id_daily_limit', photo_daily_limit,
    'photo_id_remaining', greatest(photo_monthly_limit - case when pro_active then photo_monthly_used else photo_lifetime_used end, 0),
    'photo_id_daily_remaining', greatest(photo_daily_limit - photo_daily_used, 0),
    'photo_id_reset_at', case when pro_active then month_start + interval '1 month' else null end,
    'upc_used', upc_monthly_used,
    'upc_limit', upc_monthly_limit,
    'upc_daily_limit', upc_daily_limit,
    'upc_remaining', greatest(upc_monthly_limit - upc_monthly_used, 0),
    'upc_daily_remaining', greatest(upc_daily_limit - upc_daily_used, 0),
    'upc_reset_at', case when pro_active then month_start + interval '1 month' else null end
  );
end;
$$;

create or replace function public.get_account_access()
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  select public.ownzith_access_for_user((select auth.uid()));
$$;

create or replace function public.get_account_access_for_user(target_user_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
begin
  if (select auth.role()) <> 'service_role' then
    raise exception 'service role required' using errcode = '42501';
  end if;
  return public.ownzith_access_for_user(target_user_id);
end;
$$;

create or replace function public.reserve_feature_usage(
  target_user_id uuid,
  target_feature public.ownzith_usage_feature,
  target_request_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  access jsonb;
  existing public.feature_usage_events%rowtype;
  month_start timestamptz := date_trunc('month', now() at time zone 'UTC') at time zone 'UTC';
  day_start timestamptz := date_trunc('day', now() at time zone 'UTC') at time zone 'UTC';
  minute_start timestamptz := date_trunc('minute', now());
  monthly_used integer;
  daily_used integer;
  minute_used integer;
  monthly_limit integer;
  daily_limit integer;
begin
  if (select auth.role()) <> 'service_role' then
    raise exception 'service role required' using errcode = '42501';
  end if;

  perform pg_advisory_xact_lock(hashtextextended(target_user_id::text || ':' || target_feature::text, 0));

  select * into existing from public.feature_usage_events where request_id = target_request_id;
  if existing.request_id is not null then
    if existing.user_id <> target_user_id or existing.feature <> target_feature then
      return jsonb_build_object('allowed', false, 'reason', 'request_id_conflict');
    end if;
    return jsonb_build_object('allowed', existing.state in ('reserved', 'consumed'), 'idempotent', true, 'state', existing.state);
  end if;

  -- Reservations older than ten minutes are safe to refund. The originating
  -- request can no longer reasonably be in flight and its request UUID remains
  -- idempotent if a delayed retry arrives.
  update public.feature_usage_events
  set state = 'refunded', finalized_at = now(), outcome = 'reservation_timeout'
  where user_id = target_user_id
    and feature = target_feature
    and state = 'reserved'
    and created_at < now() - interval '10 minutes';

  access := public.ownzith_access_for_user(target_user_id);
  if target_feature = 'upc_lookup'
    and not coalesce((access ->> 'is_pro')::boolean, false)
    and (select usage_enforcement_enabled from public.ownzith_runtime_settings where singleton)
  then
    return jsonb_build_object('allowed', false, 'reason', 'pro_required');
  end if;

  if target_feature = 'photo_id' then
    monthly_limit := (access ->> 'photo_id_limit')::integer;
    daily_limit := (access ->> 'photo_id_daily_limit')::integer;
  else
    monthly_limit := (access ->> 'upc_limit')::integer;
    daily_limit := (access ->> 'upc_daily_limit')::integer;
  end if;

  select
    count(*) filter (where created_at >= month_start)::integer,
    count(*) filter (where created_at >= day_start)::integer,
    count(*) filter (where created_at >= minute_start)::integer
  into monthly_used, daily_used, minute_used
  from public.feature_usage_events
  where user_id = target_user_id
    and feature = target_feature
    and state in ('reserved', 'consumed');

  if target_feature = 'photo_id' and not coalesce((access ->> 'is_pro')::boolean, false) then
    select count(*)::integer into monthly_used
    from public.feature_usage_events
    where user_id = target_user_id
      and feature = target_feature
      and state in ('reserved', 'consumed');
  end if;

  if monthly_used >= monthly_limit
    and (select usage_enforcement_enabled from public.ownzith_runtime_settings where singleton)
  then
    return jsonb_build_object('allowed', false, 'reason', 'monthly_limit');
  end if;
  if daily_used >= daily_limit
    and (select usage_enforcement_enabled from public.ownzith_runtime_settings where singleton)
  then
    return jsonb_build_object('allowed', false, 'reason', 'daily_limit');
  end if;
  if minute_used >= (case when target_feature = 'photo_id' then 5 else 15 end)
    and (select usage_enforcement_enabled from public.ownzith_runtime_settings where singleton)
  then
    return jsonb_build_object('allowed', false, 'reason', 'rate_limit');
  end if;

  insert into public.feature_usage_events (request_id, user_id, feature)
  values (target_request_id, target_user_id, target_feature);
  return jsonb_build_object('allowed', true, 'idempotent', false, 'state', 'reserved');
end;
$$;

create or replace function public.finalize_feature_usage(
  target_user_id uuid,
  target_request_id uuid,
  consume boolean,
  details jsonb default '{}'::jsonb
)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
declare
  finalized_feature public.ownzith_usage_feature;
  month_date date := (date_trunc('month', now() at time zone 'UTC'))::date;
  day_date date := (now() at time zone 'UTC')::date;
begin
  if (select auth.role()) <> 'service_role' then
    raise exception 'service role required' using errcode = '42501';
  end if;

  update public.feature_usage_events
  set state = case when consume then 'consumed' else 'refunded' end,
      provider = nullif(details ->> 'provider', ''),
      model = nullif(details ->> 'model', ''),
      fallback_used = coalesce((details ->> 'fallback_used')::boolean, false),
      input_tokens = nullif(details ->> 'input_tokens', '')::integer,
      output_tokens = nullif(details ->> 'output_tokens', '')::integer,
      cache_hit = coalesce((details ->> 'cache_hit')::boolean, false),
      duration_ms = nullif(details ->> 'duration_ms', '')::integer,
      outcome = nullif(details ->> 'outcome', ''),
      metadata = coalesce(details -> 'metadata', '{}'::jsonb),
      finalized_at = now()
  where request_id = target_request_id
    and user_id = target_user_id
    and state = 'reserved'
  returning feature into finalized_feature;
  if not found then
    return false;
  end if;

  if consume then
    insert into public.feature_usage_periods (
      user_id, feature, period_kind, period_start, consumed_count
    ) values (target_user_id, finalized_feature, 'month', month_date, 1)
    on conflict (user_id, feature, period_kind, period_start)
    do update set consumed_count = public.feature_usage_periods.consumed_count + 1,
                  updated_at = now();

    insert into public.feature_usage_periods (
      user_id, feature, period_kind, period_start, consumed_count
    ) values (target_user_id, finalized_feature, 'day', day_date, 1)
    on conflict (user_id, feature, period_kind, period_start)
    do update set consumed_count = public.feature_usage_periods.consumed_count + 1,
                  updated_at = now();

    if finalized_feature = 'photo_id' then
      insert into public.feature_usage_periods (
        user_id, feature, period_kind, period_start, consumed_count
      ) values (target_user_id, finalized_feature, 'lifetime', date '1970-01-01', 1)
      on conflict (user_id, feature, period_kind, period_start)
      do update set consumed_count = public.feature_usage_periods.consumed_count + 1,
                    updated_at = now();
    end if;
  end if;
  return true;
end;
$$;

create or replace function public.record_free_feature_event(
  target_user_id uuid,
  target_feature public.ownzith_usage_feature,
  target_request_id uuid,
  details jsonb default '{}'::jsonb
)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
begin
  if (select auth.role()) <> 'service_role' then
    raise exception 'service role required' using errcode = '42501';
  end if;
  insert into public.feature_usage_events (
    request_id, user_id, feature, state, provider, cache_hit, duration_ms,
    outcome, metadata, finalized_at
  ) values (
    target_request_id, target_user_id, target_feature, 'refunded',
    nullif(details ->> 'provider', ''), true,
    nullif(details ->> 'duration_ms', '')::integer,
    coalesce(nullif(details ->> 'outcome', ''), 'cache_hit'),
    coalesce(details -> 'metadata', '{}'::jsonb), now()
  ) on conflict (request_id) do nothing;
  return found;
end;
$$;

create or replace function public.enforce_collectible_item_limit()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  access jsonb;
begin
  if not (select item_enforcement_enabled from public.ownzith_runtime_settings where singleton) then
    return new;
  end if;
  perform pg_advisory_xact_lock(hashtextextended(new.user_id::text || ':items', 0));
  access := public.ownzith_access_for_user(new.user_id);
  if (access ->> 'item_count')::integer >= (access ->> 'item_limit')::integer then
    raise exception 'OWNZITH_ITEM_LIMIT_REACHED'
      using errcode = 'P0001',
            hint = 'Upgrade to Pro or delete items before adding another collectible.';
  end if;
  return new;
end;
$$;

create trigger enforce_collectible_item_limit_before_insert
  before insert on public.collectibles
  for each row execute function public.enforce_collectible_item_limit();

create or replace function public.apply_revenuecat_event(payload jsonb)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  event jsonb := payload -> 'event';
  event_id text := event ->> 'id';
  event_type text := upper(coalesce(event ->> 'type', ''));
  app_user_id text := event ->> 'app_user_id';
  target_user_id uuid;
  product_id text := coalesce(event ->> 'new_product_id', event ->> 'product_id');
  expiration_at timestamptz;
  event_occurred_at timestamptz;
  transfer_from_user_id uuid;
  transfer_to_user_id uuid;
  transfer_entitlement public.user_entitlements%rowtype;
  next_status public.ownzith_entitlement_status;
  inserted integer;
begin
  if (select auth.role()) <> 'service_role' then
    raise exception 'service role required' using errcode = '42501';
  end if;
  if event_id is null or event_type = '' then
    raise exception 'RevenueCat event id and type are required' using errcode = '22023';
  end if;

  insert into public.revenuecat_webhook_events (
    event_id, event_type, app_user_id, payload
  ) values (event_id, event_type, app_user_id, payload)
  on conflict (event_id) do nothing;
  get diagnostics inserted = row_count;
  if inserted = 0 then
    return jsonb_build_object('applied', false, 'reason', 'duplicate');
  end if;

  event_occurred_at := case
    when event ->> 'event_timestamp_ms' ~ '^[0-9]+$'
      then to_timestamp((event ->> 'event_timestamp_ms')::double precision / 1000)
    else now()
  end;

  if event_type = 'TRANSFER' then
    select candidate::uuid into transfer_from_user_id
    from jsonb_array_elements_text(
      coalesce(event -> 'transferred_from', '[]'::jsonb)
    ) as candidates(candidate)
    where candidate ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$'
      and exists (select 1 from auth.users where id = candidate::uuid)
    limit 1;
    select candidate::uuid into transfer_to_user_id
    from jsonb_array_elements_text(
      coalesce(event -> 'transferred_to', '[]'::jsonb)
    ) as candidates(candidate)
    where candidate ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$'
      and exists (select 1 from auth.users where id = candidate::uuid)
    limit 1;

    if transfer_from_user_id is null or transfer_to_user_id is null then
      return jsonb_build_object('applied', false, 'reason', 'transfer_user_not_resolved');
    end if;
    select * into transfer_entitlement
    from public.user_entitlements
    where user_id = transfer_from_user_id and source = 'revenuecat';
    if transfer_entitlement.user_id is null then
      return jsonb_build_object('applied', false, 'reason', 'transfer_source_has_no_entitlement');
    end if;

    insert into public.user_entitlements (
      user_id, plan, status, source, product_id, original_transaction_id,
      current_period_end, beta_access_until, source_event_at
    ) values (
      transfer_to_user_id, transfer_entitlement.plan,
      transfer_entitlement.status, 'revenuecat', transfer_entitlement.product_id,
      transfer_entitlement.original_transaction_id,
      transfer_entitlement.current_period_end, null, event_occurred_at
    ) on conflict (user_id) do update set
      plan = excluded.plan,
      status = excluded.status,
      source = excluded.source,
      product_id = excluded.product_id,
      original_transaction_id = excluded.original_transaction_id,
      current_period_end = excluded.current_period_end,
      beta_access_until = null,
      source_event_at = excluded.source_event_at,
      updated_at = now()
    where public.user_entitlements.source_event_at is null
      or public.user_entitlements.source_event_at <= excluded.source_event_at;

    update public.user_entitlements
    set status = 'inactive', current_period_end = now(),
        source_event_at = event_occurred_at, updated_at = now()
    where user_id = transfer_from_user_id
      and (source_event_at is null or source_event_at <= event_occurred_at);
    return jsonb_build_object(
      'applied', true,
      'transferred_from', transfer_from_user_id,
      'transferred_to', transfer_to_user_id
    );
  end if;

  if app_user_id is null or app_user_id !~* '^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$' then
    return jsonb_build_object('applied', false, 'reason', 'non_uuid_app_user_id');
  end if;
  target_user_id := app_user_id::uuid;
  if not exists (select 1 from auth.users where id = target_user_id) then
    return jsonb_build_object('applied', false, 'reason', 'unknown_user');
  end if;

  if product_id not in (
    'com.neoncartridgelabs.ownzith.pro.monthly',
    'com.neoncartridgelabs.ownzith.pro.annual'
  ) then
    return jsonb_build_object('applied', false, 'reason', 'unrecognized_product');
  end if;

  expiration_at := case
    when event ->> 'grace_period_expiration_at_ms' ~ '^[0-9]+$'
      then to_timestamp((event ->> 'grace_period_expiration_at_ms')::double precision / 1000)
    when event ->> 'expiration_at_ms' ~ '^[0-9]+$'
      then to_timestamp((event ->> 'expiration_at_ms')::double precision / 1000)
    else null
  end;
  next_status := case event_type
    when 'EXPIRATION' then 'expired'::public.ownzith_entitlement_status
    when 'REFUND' then 'refunded'::public.ownzith_entitlement_status
    when 'BILLING_ISSUE' then 'billing_issue'::public.ownzith_entitlement_status
    when 'SUBSCRIPTION_PAUSED' then 'inactive'::public.ownzith_entitlement_status
    else 'active'::public.ownzith_entitlement_status
  end;

  insert into public.user_entitlements (
    user_id, plan, status, source, product_id, original_transaction_id,
    current_period_end, beta_access_until, source_event_at
  ) values (
    target_user_id, 'pro', next_status, 'revenuecat', product_id,
    event ->> 'original_transaction_id', expiration_at, null, event_occurred_at
  )
  on conflict (user_id) do update set
    plan = 'pro',
    status = excluded.status,
    source = 'revenuecat',
    product_id = excluded.product_id,
    original_transaction_id = coalesce(
      excluded.original_transaction_id,
      public.user_entitlements.original_transaction_id
    ),
    current_period_end = excluded.current_period_end,
    beta_access_until = null,
    source_event_at = excluded.source_event_at,
    updated_at = now()
  where public.user_entitlements.source_event_at is null
    or public.user_entitlements.source_event_at <= excluded.source_event_at;

  return jsonb_build_object('applied', true, 'user_id', target_user_id);
end;
$$;

revoke execute on function public.ownzith_access_for_user(uuid) from public, anon, authenticated;
revoke execute on function public.grant_prelaunch_pro_access() from public, anon, authenticated;
revoke execute on function public.configure_ownzith_public_launch(timestamptz) from public, anon, authenticated;
revoke execute on function public.get_account_access() from public, anon;
revoke execute on function public.get_account_access_for_user(uuid) from public, anon, authenticated;
revoke execute on function public.reserve_feature_usage(uuid, public.ownzith_usage_feature, uuid) from public, anon, authenticated;
revoke execute on function public.finalize_feature_usage(uuid, uuid, boolean, jsonb) from public, anon, authenticated;
revoke execute on function public.record_free_feature_event(uuid, public.ownzith_usage_feature, uuid, jsonb) from public, anon, authenticated;
revoke execute on function public.enforce_collectible_item_limit() from public, anon, authenticated;
revoke execute on function public.apply_revenuecat_event(jsonb) from public, anon, authenticated;
grant execute on function public.get_account_access() to authenticated;
grant execute on function public.get_account_access_for_user(uuid) to service_role;
grant execute on function public.reserve_feature_usage(uuid, public.ownzith_usage_feature, uuid) to service_role;
grant execute on function public.finalize_feature_usage(uuid, uuid, boolean, jsonb) to service_role;
grant execute on function public.record_free_feature_event(uuid, public.ownzith_usage_feature, uuid, jsonb) to service_role;
grant execute on function public.apply_revenuecat_event(jsonb) to service_role;
grant execute on function public.configure_ownzith_public_launch(timestamptz) to service_role;
