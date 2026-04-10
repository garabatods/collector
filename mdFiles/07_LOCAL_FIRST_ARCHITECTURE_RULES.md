# Collector App — Local-First Architecture Rules

## Purpose
Collector must default to a **local-first** mobile architecture for all collection-facing read experiences.

The goal is to make the app feel fast, resilient, and usable even when connectivity is weak or unavailable.

This is now the default rule for future screens and features unless there is a strong reason to opt out.

## Core principle
For reads, the app should:

1. Load from on-device storage first.
2. Sync with Supabase in the background.
3. Refresh local state after remote changes.
4. Avoid blocking normal browsing on network requests.

For writes in v1, the app should:

1. Stay online-first.
2. Write successful server responses back into the local database immediately.
3. Show a clear message when a write needs connectivity.

## Default rule for new work
Any new archive-related screen, tab, widget, or feature that shows user collection data should follow this pattern by default:

- Read from the local archive layer.
- Use watch/query-based UI updates.
- Sync in the background.
- Support offline browsing after the first successful sync.

Do not build new collection read screens as remote-first `FutureBuilder` flows unless explicitly approved.

## Required architecture pattern
New features should use:

- `LocalArchiveDatabase` for persistent on-device state
- `ArchiveRepository` for local-first read access
- `ArchiveSyncCoordinator` for sync behavior
- `PhotoCacheStore` for cached primary archive images

UI should prefer:

- streams, watchers, or reactive local queries
- narrow rebuild scopes
- inline refresh indicators instead of blocking overlays

UI should avoid:

- fetching full datasets on every screen open
- re-signing image URLs during every screen bootstrap
- full-screen loaders for already-cached archive data
- rebuilding an entire screen because one small subsection changed

## Offline support rule
After the first successful sync, these experiences should remain usable offline:

- Home
- Library
- Search
- Category views
- Collectible detail reads
- Profile summary
- Wishlist
- Cached primary photos

If there is no local copy yet and the device is offline, show an explicit bootstrap/offline state instead of an empty screen.

## Loading-state rule
Full-screen loading is allowed only when:

- the app is doing the first-ever archive download on a device
- there is no usable local copy yet

After local data exists, normal refreshes should use:

- subtle sync banners
- inline loading indicators
- optimistic local updates where appropriate

Empty states must only represent true empty data, not “sync has not finished yet.”

## Mutation rule
For v1:

- create, edit, delete, and upload actions remain online-only
- when a write succeeds, the local archive must be updated immediately
- do not force a full-screen refetch to show a successful mutation

If offline writes are added later, they should be introduced intentionally as a separate architecture upgrade, not mixed in casually.

## Photo rule
Archive images should prefer:

1. local cached file
2. remote URL if needed
3. placeholder only if neither is available

Do not rely on short-lived signed URLs as the only source of truth for already-cached archive images.

## Performance rule
When adding or reviewing a screen, ask:

- Does it read from local state first?
- Does it avoid bootstrapping from the network on every open?
- Does it avoid whole-screen rebuild pressure?
- Does it avoid full-screen loaders for small refreshes?
- Does it update from local writes instead of re-fetching everything?

If the answer is no, the implementation should be reconsidered before shipping.

## Review checklist
Before merging a new archive-facing screen or feature, verify:

- local-first reads are used
- offline browse behavior is preserved after first sync
- loading states are proportional
- local cache updates after successful writes
- primary images follow the cache-first rule
- no unnecessary remote bootstrap was added

## Current scope note
This rule applies most strongly to collection/archive surfaces.

Some flows may still be intentionally online-first, such as:

- authentication
- first account bootstrap
- barcode/photo identification calls
- remote mutation workflows
- admin or diagnostics tools

But even in those flows, avoid adding unnecessary repeated loading or fetch behavior if local state can safely support the UX.
