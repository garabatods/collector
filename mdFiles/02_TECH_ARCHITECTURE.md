# Collector App — Technical Architecture

## Stack
- Flutter for the mobile app
- Supabase for backend services
  - Auth
  - Postgres database
  - Storage

## Platform priority
- Android first
- iOS second
- Shared Flutter codebase

## App structure direction
Use a simple feature-oriented structure.

Suggested top-level folders:
- lib/core
- lib/features
- lib/shared

Suggested feature areas:
- auth
- app_shell
- collection
- collectible_detail
- add_collectible
- wishlist
- profile
- dashboard

## Data model direction
Initial tables:
- profiles
- collectibles
- collectible_photos
- wishlist_items

## Important implementation principles
- Keep business logic separated from UI
- Keep models and repositories clean
- Avoid overengineering state management too early
- Add routing cleanly
- Prefer small, testable steps
- Use environment/config for Supabase keys
- Apply Row Level Security in Supabase
