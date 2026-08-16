-- Production had zero wishlist rows when the removal was planned. Deployment
-- must recheck that invariant and take a schema backup immediately beforehand.
do $$
begin
  if exists (select 1 from public.wishlist_items limit 1) then
    raise exception 'Wishlist removal stopped: public.wishlist_items is not empty.';
  end if;
end;
$$;

drop trigger if exists touch_user_sync_state_wishlist_items on public.wishlist_items;
drop trigger if exists set_wishlist_items_updated_at on public.wishlist_items;
drop function if exists public.touch_user_sync_state_from_wishlist_items();
drop table public.wishlist_items;
