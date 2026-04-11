insert into public.user_sync_state (user_id, updated_at)
select users.id, now()
from auth.users
where users.id is not null
on conflict (user_id) do nothing;

create or replace function public.get_current_user_sync_stamp()
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  current_user_id uuid := (select auth.uid());
  current_sync_stamp timestamptz;
begin
  if current_user_id is null then
    return null;
  end if;

  insert into public.user_sync_state (user_id, updated_at)
  values (current_user_id, now())
  on conflict (user_id) do nothing;

  select updated_at
    into current_sync_stamp
  from public.user_sync_state
  where user_id = current_user_id;

  return current_sync_stamp::text;
end;
$$;

grant execute on function public.get_current_user_sync_stamp() to authenticated;
