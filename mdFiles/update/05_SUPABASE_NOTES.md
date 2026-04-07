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
- Use the publishable / anon-style client key only on the client
- Keep service-role or secret-key usage out of the mobile app

## Migration rules
- Generate SQL clearly
- Explain every migration in plain English
- Prefer safe incremental migrations
- Do not rename or delete major structures casually

## Storage direction
Start simple:
- one primary photo per collectible first
- allow future support for multiple photos later

## Category note for database design
For MVP, the `collectibles.category` field and `wishlist_items.category` field can be stored as plain text.

Reason:
- the UI will offer curated default categories
- the user can also create a custom category if needed
- this avoids blocking the user with a rigid fixed enum too early

Recommended default categories for UI:
- Action Figures
- Statues
- Vinyl Figures
- Trading Cards
- Comics
- Memorabilia
- Die-cast
- Other

Important:
- do not store the literal value `New Category`
- if the user creates a custom category, store the actual custom category name
- keep backend flexible now, normalize later only if usage proves it is needed
