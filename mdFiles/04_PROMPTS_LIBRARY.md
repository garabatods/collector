# Collector App — VS Code Agent Prompts

## Session 0.1 — Verify Flutter environment
```text
Help me verify my Flutter + VS Code environment for Android development first.

Tasks:
1. Check that Flutter is installed correctly.
2. Tell me which commands I should run to verify the setup.
3. Explain any missing dependencies in simple terms.
4. Do not create code yet.
5. At the end, give me a short checklist for:
   - Flutter SDK
   - Dart extension
   - Flutter extension
   - Android SDK / emulator
   - device testing
```

## Session 0.2 — Create project
```text
Create a new Flutter app for a collectibles tracking product.

Requirements:
- App name: collector_app
- Use a clean folder structure suitable for a production app
- Keep the default Flutter project as lean as possible
- Do not add state management libraries yet unless you explain why
- Add a very simple home screen with the title "Collector App"
- After creating the project, tell me the exact terminal commands to run it on Android
```

## Session 0.3 — Connect to Supabase
```text
I already created a Supabase project.

Help me connect this Flutter app to Supabase in a minimal and clean way.

Tasks:
1. Add the required Supabase Flutter dependencies.
2. Create an app initialization flow.
3. Read the Supabase URL and anon key from environment/config, not hardcoded in widgets.
4. Initialize Supabase in main.dart cleanly.
5. Keep this step limited to connection only. No auth yet.
6. Show me exactly where I must paste my Supabase project URL and anon key.
```

## Session 1.1 — App structure
```text
Set up a simple but scalable Flutter app structure for a collector app.

Requirements:
- Keep it easy to understand
- Organize by feature where it makes sense
- Create folders for:
  - core
  - features
  - shared
- Add basic app routing
- Add a theme file
- Add placeholder screens for:
  - Home
  - Collection
  - Wishlist
  - Profile
- Add a bottom navigation bar
- Do not implement business logic yet
- Explain the folder structure briefly after generating it
```

## Session 1.2 — Theme
```text
Create a modern mobile-first visual foundation for Collector App.

Requirements:
- Clean and premium look
- Dark-friendly collector vibe
- Good spacing and typography
- Reusable colors, text styles, spacing, and radius tokens
- No overdesigned gradients everywhere
- Add a basic card style that could work for collectible items
- Keep the code organized and reusable
```

## Session 2.1 — Basic auth
```text
Implement basic Supabase authentication for Flutter.

Requirements:
- Email and password sign up
- Email and password sign in
- Sign out
- Persist session
- Clean auth state handling
- Minimal but good-looking UI
- Screens needed:
  - Welcome / auth landing
  - Sign in
  - Sign up
- If a user is authenticated, route them to the main app
- If not authenticated, route them to auth
- Keep the code simple and production-friendly
```

## Session 2.2 — Session flow
```text
Refine the auth flow.

Tasks:
1. Add a session-aware app entry flow.
2. Show auth screens if there is no active session.
3. Show the main app shell if the session exists.
4. Handle loading and error states cleanly.
5. Do not add social login yet.
```

## Session 3.1 — Database schema
```text
Design the initial Supabase Postgres schema for a mobile collectibles tracking app.

Main product goal:
Users can catalog collectibles like action figures, memorabilia, statues, comics, or similar items.

For MVP, design these tables:
- profiles
- collectibles
- collectible_photos
- wishlist_items

Requirements:
- Every row must belong to the authenticated user where appropriate
- Include created_at and updated_at
- Keep the schema practical, not academic
- Include fields for:
  - item name
  - category
  - franchise
  - brand
  - line or series
  - character or subject
  - year
  - condition
  - box status
  - notes
  - quantity
  - is_favorite
  - is_grail
  - is_duplicate
  - open_to_trade
- Generate SQL migration
- Enable Row Level Security
- Add sensible RLS policies so users can only access their own data
- Explain the schema in plain English after the SQL
```

## Session 3.2 — Data layer
```text
Based on the current Supabase schema, generate the Flutter data layer.

Requirements:
- Create Dart models for the current tables
- Create mapping from Supabase/Postgres JSON to Dart objects
- Add repository classes for collectibles and wishlist items
- Keep the data layer separated from the UI
- Use clear names and avoid overengineering
- Do not build the screens yet
```

## Session 4.1 — Collection screen
```text
Build the Collection screen for Collector App.

Requirements:
- Fetch the authenticated user's collectibles from Supabase
- Show them in a clean visual grid
- Each card should show:
  - primary image placeholder
  - item name
  - franchise or line if available
  - favorite/grail indicators if present
- Add empty state UI for when the user has no collectibles yet
- Add loading and error states
- Tapping an item should open the item detail screen
```

## Session 4.2 — Add collectible
```text
Build the Add Collectible flow.

Requirements:
- Create a form screen to add a collectible
- Fields:
  - item name (required)
  - category
  - franchise
  - brand
  - line or series
  - character or subject
  - year
  - condition
  - box status
  - quantity
  - notes
  - favorite toggle
  - grail toggle
  - duplicate toggle
  - open to trade toggle
- Validate only what really needs validation
- Save to Supabase
- After save, return to the collection screen and refresh the list
- Keep the UX mobile-first and simple
```

## Session 4.3 — Detail and edit
```text
Build the collectible detail and edit flow.

Requirements:
- Create a detail screen for a collectible
- Show the collectible information in a visually nice way
- Add an Edit action
- Create an Edit screen prefilled with the current values
- Save updates back to Supabase
- Add a delete action with confirmation
- Keep all logic scoped to this feature
```

## Session 5.1 — Storage strategy
```text
Help me add collectible photo upload using Supabase Storage.

Requirements:
- Assume we will store item photos in Supabase Storage
- Propose a clean bucket strategy
- Generate any SQL or policy setup needed
- Explain security considerations simply
- Each user should only be able to manage their own collectible photos
- Do not change unrelated app code yet
```

## Session 5.2 — Photo upload
```text
Implement collectible photo upload in Flutter.

Requirements:
- Let the user pick an image from the device
- Upload it to Supabase Storage
- Save the uploaded file reference in the database
- Show the image on the collectible detail screen
- Keep image handling simple and clean
- If multiple photos are too much for this step, start with one primary photo only
```

## Session 6.1 — Wishlist
```text
Build the Wishlist feature for Collector App.

Requirements:
- Create a Wishlist screen
- Allow users to add wishlist items
- Fields:
  - item name
  - category
  - franchise
  - brand
  - line or series
  - notes
  - priority
- Save wishlist items to Supabase
- Show them in a clean list or grid
- Allow moving a wishlist item into the owned collection later, but for now just design the structure cleanly
```

## Session 6.2 — Search and filters
```text
Add basic search and filters to the collection screen.

Requirements:
- Search by item name
- Filter by category
- Filter by franchise
- Filter by favorites
- Filter by grails
- Filter by duplicates
- Keep the UX simple and mobile-friendly
- Do not overcomplicate the state management
```

## Session 6.3 — Dashboard
```text
Create a simple Home dashboard for Collector App.

Requirements:
- Show total collectibles count
- Show favorites count
- Show grails count
- Show duplicates count
- Show wishlist count
- Add a section for recently added items
- The design should feel modern and not like a spreadsheet
```

## Session 7.1 — Polish
```text
Review the app and improve UX polish.

Tasks:
- Standardize loading states
- Standardize error messages
- Improve empty states
- Avoid raw technical messages in the UI
- Make sure all async operations have clean user feedback
- Do not redesign the whole app
```

## Session 7.2 — QA checklist
```text
Create a QA checklist for this Flutter + Supabase collector app MVP.

Include:
- auth flows
- session persistence
- create collectible
- edit collectible
- delete collectible
- upload photo
- wishlist
- search and filters
- loading states
- empty states
- offline/error behavior
```

## Session 7.3 — Release readiness
```text
Prepare this Flutter app for release readiness.

Tasks:
- Review Android app configuration that should be customized later
- Review iOS app configuration that should be customized later
- List icons, app name, bundle identifiers, and environment config that still need manual setup
- Do not publish anything
- Give me a release-readiness checklist
```
