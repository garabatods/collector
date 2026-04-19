# Ownzith - Insights Screen Brief

## Purpose
`Insights` replaces the low-value `Wishlist` tab.

This screen should help the user understand the shape of their collection in a way that feels premium, visual, and personal, not like a spreadsheet dashboard.

## Relationship to Home
- Home keeps the single featured `Collection Insight` card
- `Insights` becomes the deeper screen for collection signals
- Home is the teaser
- `Insights` is the full story

## Nav name
Use `Insights`

Reason:
- short enough for the nav bar
- broad enough for identity, momentum, and archive quality
- stronger than `Stats`

## Screen goal
Show a curated set of collection signals based on data the app already trusts:
- dominant category
- recent category momentum
- favorite concentration
- franchise leader
- brand leader
- photo coverage
- missing photos

## Layout
Recommended order:

1. Top summary hero
- one strongest insight
- slightly larger than the rest
- can reuse the visual language from the Home featured insight

2. Signal grid
- 2-column compact cards
- 4 to 6 cards total depending on how much strong data exists
- cards should be short and glanceable

3. Optional action row
- only if there are useful actions like `Open Library`, `View Category`, or `See Favorites`

## Empty-state rule
If the user has very little meaningful data:

- 0 items: do not show the `Insights` screen as an empty analytics page; use a soft onboarding-style empty state instead
- 1 to 2 items: show a lightweight version with 1 hero insight and no compact grid
- 3 to 4 items: show the hero plus up to 2 compact cards if they are genuinely meaningful
- 5 or more items: allow the full screen structure

The screen should never feel padded with weak facts just to fill space.

## Hero-card rule
The `Insights` hero card does not have to always match the featured Home insight.

Recommended behavior:
- allow it to match when the strongest insight is also the best top story for `Insights`
- allow it to differ when another signal creates a better overall screen composition
- avoid showing the exact same hero and then repeating that same fact again in the compact cards below

So the rule is:
- same source system
- not necessarily the same chosen card
- no redundant repetition on the `Insights` screen itself

## Compact-card count
Target:
- default to 4 compact cards
- allow 2 cards for smaller collections
- allow up to 6 only when the signals are clearly strong and non-redundant

Recommended max:
- 6 absolute max

Do not force the maximum.
It is better to show 3 strong cards than 6 weak ones.

## Card types
Use a mix of these, depending on what data is meaningful:

- Identity
  - `Action Figures lead your shelf`
  - `TMNT is shaping your archive`

- Momentum
  - `Comics are leading your recent adds`
  - `You have been on a Vinyl Figures run`

- Curation quality
  - `Most of your archive already has photos`
  - `A few pieces could use photos`

- Taste
  - `Favorites keep returning to Action Figures`
  - `One brand keeps showing up the most`

## Rules
- do not show weak filler cards
- do not show the same fact twice in different wording
- prefer variety across card types
- if there are fewer than 3 strong signals, show fewer cards
- if there is almost no meaningful data, keep only the hero and maybe 1 or 2 cards
- do not use carousel behavior
- do not auto-rotate cards on screen

## Tone
- collector-first
- smart
- warm
- premium
- not corporate
- not analytics-heavy

## Avoid
- duplicate, grail, or quantity-based insights
- dense percentages everywhere
- walls of tiny stat chips
- generic dashboard boxes
- making every card equally loud

## Implementation direction
- reuse the existing insight engine direction where possible
- keep one large hero insight at the top
- derive supporting cards from the next best non-redundant signals
- use local-first data only

## Final principle
The screen should feel like:
`Here is what your collection says about you`

Not:
`Here are some database statistics`
