# Collector App - Profile Screen Brief

## Purpose
The profile screen should feel like the collector's personal control room, not a generic account page.

It should help the user:
- understand their collector identity
- access account settings quickly
- see collection-level highlights
- reach wishlist, favorites, and trade-related areas faster

## Product tone
- premium
- personal
- visual
- clean
- not corporate
- not admin-dashboard heavy

## Core idea
This screen is a mix of:
- collector identity
- collection summary
- shortcuts to important areas
- app/account settings

## Suggested screen structure

### 1. Profile header
Top section should include:
- avatar or profile image
- display name
- username if available
- short collector tagline or empty-state prompt

Optional supporting info:
- member since
- city/country if the app supports it later

### 2. Collector summary strip
Use a compact summary row or card with stats such as:
- total items
- categories
- favorites
- wishlist items

Optional later:
- grails
- duplicates
- items open to trade

## 3. Identity or showcase section
This is what makes the profile screen feel less boring.

Possible content:
- favorite category
- latest added item
- grail count
- featured collectible photo
- collector level or collector style label

This should be visually stronger than plain settings rows.

### 4. Quick actions
Use clear shortcut tiles or list items for:
- favorites
- wishlist
- categories
- trade items
- recently added

These should feel like navigation shortcuts, not form fields.

### 5. Account and app settings
Keep this section cleaner and more utility-focused.

Suggested rows:
- edit profile
- notifications
- appearance or theme
- connected account
- help / support
- sign out

## Good first-version content
If we want a practical MVP profile screen, use:
- avatar
- name
- username
- total items
- category count
- favorites count
- wishlist count
- quick links to favorites and wishlist
- edit profile
- sign out

## Data ideas
Likely data sources:
- `profiles`
  - display name
  - username
  - avatar url if added later
- `collectibles`
  - total items
  - favorite count
  - grail count
  - duplicate count
  - category count
- `wishlist_items`
  - wishlist total

## Empty-state guidance
If the user has little data:
- do not make the screen feel broken
- still show profile basics
- replace missing collector stats with soft prompts

Examples:
- "Add a profile photo"
- "Start building your shelf"
- "Pick your first favorite"

## UI guidance
- avoid large walls of settings rows at the top
- avoid making the whole screen look like a generic account page
- use 1 strong top identity area
- use 1 compact stats area
- use 1 showcase or shortcut section
- keep settings lower on the screen

## Visual direction
- rich but controlled
- use cards with hierarchy, not too many nested boxes
- title hierarchy should be clean and smaller than the item detail hero
- stat numbers can be bold, but labels should stay secondary
- avoid repeating the same information in multiple sections

## Interaction suggestions
- tap avatar to edit photo later
- tap stat cards only if they lead somewhere useful
- favorites and wishlist should be direct shortcuts
- sign out should be visually separated from the rest

## Do not do
- do not make it a plain settings list only
- do not repeat the same counts in multiple cards
- do not overuse explanatory text
- do not make every section equally loud
- do not patch random tiles in without a clear hierarchy

## Recommended first implementation
Build the screen in this order:
1. profile header
2. compact collection stats
3. quick actions for favorites and wishlist
4. settings section
5. one premium visual touch such as a featured collectible card or favorite category block

## Handoff note for another agent
If implementing this screen, prefer a real profile-screen composition rather than patching existing placeholder widgets. Keep hierarchy clear and make the top of the screen feel personal first, utility second.
