-- Keep trigger helpers internal and expose only the RPCs used by signed-in clients.
-- PostgreSQL grants EXECUTE on new functions to PUBLIC by default, so an explicit
-- authenticated grant is not sufficient unless the default grant is revoked.

revoke execute on function public.set_updated_at() from public, anon, authenticated;
revoke execute on function public.handle_new_user() from public, anon, authenticated;

revoke execute on function public.touch_user_sync_state(uuid) from public, anon, authenticated;
revoke execute on function public.touch_user_sync_state_from_profiles() from public, anon, authenticated;
revoke execute on function public.touch_user_sync_state_from_collectibles() from public, anon, authenticated;
revoke execute on function public.touch_user_sync_state_from_collectible_photos() from public, anon, authenticated;
revoke execute on function public.touch_user_sync_state_from_wishlist_items() from public, anon, authenticated;
revoke execute on function public.touch_user_sync_state_from_tags() from public, anon, authenticated;
revoke execute on function public.touch_user_sync_state_from_collectible_tags() from public, anon, authenticated;

revoke execute on function public.get_current_user_sync_stamp() from public, anon;
grant execute on function public.get_current_user_sync_stamp() to authenticated;

-- These functions either use only pg_catalog built-ins or schema-qualify every
-- database object they access. An empty search path prevents object shadowing.
alter function public.set_updated_at() set search_path = '';
alter function public.handle_new_user() set search_path = '';
alter function public.touch_user_sync_state(uuid) set search_path = '';
alter function public.get_current_user_sync_stamp() set search_path = '';
alter function public.touch_user_sync_state_from_profiles() set search_path = '';
alter function public.touch_user_sync_state_from_collectibles() set search_path = '';
alter function public.touch_user_sync_state_from_collectible_photos() set search_path = '';
alter function public.touch_user_sync_state_from_wishlist_items() set search_path = '';
alter function public.touch_user_sync_state_from_tags() set search_path = '';
alter function public.touch_user_sync_state_from_collectible_tags() set search_path = '';
