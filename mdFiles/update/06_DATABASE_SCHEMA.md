# Collector App — Database Schema

## Purpose
This file documents the initial Supabase/Postgres schema for the Collector App MVP.

It is the database counterpart to:
- `01_PRODUCT_CONTEXT.md`
- `02_TECH_ARCHITECTURE.md`
- `05_SUPABASE_NOTES.md`

This schema stays intentionally flexible for MVP while still enforcing ownership, RLS, and safe data constraints.

## Migration file
Initial schema migration:
- `supabase/migrations/20260404113000_initial_schema.sql`

Collector-focused incremental migration:
- `supabase/migrations/20260404121500_add_collector_friendly_fields.sql`

Barcode persistence migration:
- `supabase/migrations/20260405183000_add_collectible_barcode.sql`

Tagging migration:
- `supabase/migrations/20260405201000_add_collectible_tags.sql`

## Core design decisions
- Use Supabase Auth `auth.users` as the identity source
- Keep `category` as plain text on `collectibles` and `wishlist_items`
- Reject the literal value `New Category` at the database layer
- Use Row Level Security on all app tables
- Create profiles automatically when new auth users are inserted
- Keep storage private and scoped by authenticated user ownership
- Support one primary collectible photo now while leaving room for multiple photos later
- Add collector-specific metadata with simple nullable columns instead of new lookup tables
- Keep the original `series` column for compatibility, but move forward with `line_or_series`
- Keep `barcode` optional on collectibles so scanning stays a convenience, not a requirement
- Use relational per-user tags instead of JSON/array shortcuts

## Incremental collector-friendly update
The second migration makes the schema feel less like generic inventory and more like a real collector database.

What changed:
- `collectibles` now supports `franchise`, `line_or_series`, `character_or_subject`, `release_year`, `box_status`, and `is_duplicate`
- `wishlist_items` now supports `franchise`, `line_or_series`, `character_or_subject`, `release_year`, and `box_status`
- existing `series` data is backfilled into `line_or_series`
- `release_year` is lightly validated to a practical range
- `box_status` is limited to a small collector-friendly set:
  - `sealed`
  - `boxed`
  - `partial_box`
  - `loose`

Why this shape:
- it adds collector context without introducing extra tables or enums
- it preserves the older `series` field so existing code does not break immediately
- it gives the app cleaner vocabulary for figures, statues, cards, comics, and memorabilia

## Incremental barcode update
The third migration adds lightweight barcode persistence for scanner-assisted adds.

What changed:
- `collectibles` now supports nullable `barcode`
- a partial index on `(user_id, barcode)` supports future duplicate checks and quick barcode lookups

Why this shape:
- barcode stays optional because many collectibles are loose, vintage, custom, or barcode-less
- the scanner flow can now keep the scanned code with the saved collectible when one exists
- this adds scan support without changing the collector-first manual add direction

## Incremental tags update
The fourth migration adds reusable per-user collectible tags.

What changed:
- `tags` stores user-owned tag records
- `collectible_tags` links many tags to many collectibles
- tag names are unique per user, case-insensitively

Why this shape:
- tags are reusable and belong to a user, not to a single item
- the relational structure matches the rest of the schema and RLS style
- it keeps filtering, deduping, and future tag management clean

## Tables

### `profiles`
Purpose:
- store profile basics for each authenticated user

Columns:
- `id uuid primary key` referencing `auth.users(id)`
- `username text` optional, lowercase/underscore format enforced
- `display_name text` optional
- `avatar_url text` optional
- `bio text` optional
- `created_at timestamptz`
- `updated_at timestamptz`

Notes:
- profile rows are auto-created by the `handle_new_user()` trigger
- username uniqueness is enforced case-insensitively

### `collectibles`
Purpose:
- store the user’s owned collection items

Columns:
- `id uuid primary key`
- `user_id uuid` owner, references `auth.users(id)`
- `title text` required
- `category text` required
- `barcode text` optional
- `description text` optional
- `brand text` optional
- `series text` optional
- `franchise text` optional
- `line_or_series text` optional
- `character_or_subject text` optional
- `release_year integer` optional
- `box_status text` optional
- `item_number text` optional
- `item_condition text` optional
- `quantity integer` default `1`
- `purchase_price numeric(12,2)` optional
- `estimated_value numeric(12,2)` optional
- `acquired_on date` optional
- `notes text` optional
- `is_favorite boolean` default `false`
- `is_grail boolean` default `false`
- `is_duplicate boolean` default `false`
- `open_to_trade boolean` default `false`
- `created_at timestamptz`
- `updated_at timestamptz`

Rules:
- `title` cannot be blank
- `category` cannot be blank
- `category` cannot be `New Category`
- `barcode` is optional and may be null for non-scannable collectibles
- `quantity` must be greater than `0`
- price fields cannot be negative
- `release_year` must be between `1900` and next calendar year when provided
- `box_status`, when provided, must be one of `sealed | boxed | partial_box | loose`

Collector note:
- `series` remains in place for backward compatibility
- `line_or_series` is the preferred field for new app code
- `is_duplicate` gives direct support for duplicate tracking instead of inferring from quantity

### `collectible_photos`
Purpose:
- store metadata for collectible images kept in Supabase Storage

Columns:
- `id uuid primary key`
- `collectible_id uuid` references `collectibles(id)`
- `storage_bucket text` fixed to `collectible-photos`
- `storage_path text` required
- `caption text` optional
- `is_primary boolean` default `false`
- `display_order integer` default `0`
- `created_at timestamptz`
- `updated_at timestamptz`

Rules:
- one collectible can have multiple photo rows later
- only one row may be marked `is_primary = true` per collectible
- `(storage_bucket, storage_path)` is unique

### `tags`
Purpose:
- store reusable tags created by each user

Columns:
- `id uuid primary key`
- `user_id uuid` owner, references `auth.users(id)`
- `name text` required
- `created_at timestamptz`

Rules:
- `name` cannot be blank
- tag names must be unique per user, case-insensitively

### `collectible_tags`
Purpose:
- attach multiple reusable tags to a collectible

Columns:
- `collectible_id uuid` references `collectibles(id)`
- `tag_id uuid` references `tags(id)`
- `created_at timestamptz`

Rules:
- one collectible can have many tags
- one tag can be reused across many collectibles
- duplicate collectible/tag pairs are prevented by the composite primary key

### `wishlist_items`
Purpose:
- store items the user wants to acquire later

Columns:
- `id uuid primary key`
- `user_id uuid` owner, references `auth.users(id)`
- `title text` required
- `category text` required
- `description text` optional
- `brand text` optional
- `series text` optional
- `franchise text` optional
- `line_or_series text` optional
- `character_or_subject text` optional
- `release_year integer` optional
- `box_status text` optional
- `priority text` default `medium`
- `target_price numeric(12,2)` optional
- `notes text` optional
- `created_at timestamptz`
- `updated_at timestamptz`

Rules:
- `priority` is limited to `low | medium | high`
- `category` remains text for MVP
- `category` cannot be `New Category`
- `release_year` must be between `1900` and next calendar year when provided
- `box_status`, when provided, must be one of `sealed | boxed | partial_box | loose`

Collector note:
- wishlist items intentionally do not get `is_duplicate`
- `line_or_series` is preferred over `series` for future reads and writes

## Triggers and helper functions

### `set_updated_at()`
Used on:
- `profiles`
- `collectibles`
- `collectible_photos`
- `wishlist_items`

Behavior:
- updates `updated_at` automatically before row updates

### `handle_new_user()`
Behavior:
- creates a matching `profiles` row whenever a new `auth.users` row is created
- uses `display_name` from auth metadata when available
- falls back to the email local-part when metadata is absent

## Row Level Security
RLS is enabled and forced on:
- `profiles`
- `collectibles`
- `collectible_photos`
- `wishlist_items`
- `tags`
- `collectible_tags`

Policy behavior:
- users can only read and mutate their own `profiles` row
- users can only read and mutate their own `collectibles`
- users can only read and mutate `collectible_photos` attached to their own collectibles
- users can only read and mutate their own `wishlist_items`
- users can only read and mutate their own `tags`
- users can only read and mutate `collectible_tags` rows when both the collectible and tag belong to them

Performance notes:
- ownership columns and filter paths used by RLS are indexed where appropriate
- policy checks use `(select auth.uid())` patterns to align with Supabase RLS guidance

## Storage
Bucket created:
- `collectible-photos`

Bucket rules:
- private bucket
- 50 MB file size limit
- allowed MIME types:
  - `image/jpeg`
  - `image/png`
  - `image/webp`
  - `image/heic`
  - `image/heif`

Expected object path pattern:
- `{auth.uid()}/{collectible_id}/{filename}`

Storage policies:
- authenticated users can only read, insert, update, and delete files in their own folder namespace

## Indexes
Important indexes included:
- case-insensitive unique username index on `profiles`
- owner/date and owner/category indexes on `collectibles`
- owner/franchise and duplicate-filter indexes on `collectibles`
- partial indexes for favorite, grail, and trade filters
- foreign key/index support for `collectible_photos.collectible_id`
- owner/date and owner/priority indexes on `wishlist_items`
- case-insensitive unique tag-name index on `(user_id, lower(name))`
- foreign key/index support for `collectible_tags.collectible_id` and `collectible_tags.tag_id`

## What this schema intentionally does not do yet
- no normalized categories table
- no marketplace or social schema
- no multi-photo workflow rules beyond one primary photo marker
- no pricing history tables
- no audit log tables
- no advanced search vectors yet

## Next implementation expectations
- Flutter repositories should always pass `user_id = auth.currentUser.id` on inserts
- photo uploads should use the authenticated user id as the first storage path segment
- the UI should present curated default categories, but persist real custom text values
- the UI must never send the literal value `New Category`
- new forms should write to `line_or_series` rather than `series`
- collector-facing forms should expose `box_status` using the four supported values
- scanner-assisted adds may prefill title, category, and image from UPCitemdb, but must still allow the user to adjust the final record before save
- collectible forms can attach multiple reusable user tags through `tags` + `collectible_tags`
