# Collector App — Supabase Notes

## Intended Supabase usage
- Auth for user accounts and sessions
- Postgres for structured collection data
- Storage for collectible photos

## Initial tables
- profiles
- collectibles
- collectible_photos
- wishlist_items

## Security direction
- Enable Row Level Security on app tables
- Scope data access to the authenticated user
- Keep storage access aligned with ownership rules

## Configuration rules
- Do not hardcode project keys into widgets
- Load Supabase URL and anon key from config or environment
- Use the anon key only on the client
- Keep service-role usage out of the mobile app

## Migration rules
- Generate SQL clearly
- Explain every migration in plain English
- Prefer safe incremental migrations
- Do not rename or delete major structures casually

## Storage direction
Start simple:
- one primary photo per collectible first
- allow future support for multiple photos later
