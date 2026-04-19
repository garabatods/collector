# Ownzith - Collector Goals and Badges Brief

## Purpose
Add light gamification that helps users stay active without making the app feel childish or noisy.

This feature should feel like collector momentum, not like a game layered on top of the product.

## Core model
- `Collector Goals` = what the user can do next
- `Badges` = what the user has earned over time

## Placement

### Home
Add a compact `Collector Goals` component on Home.

Recommended placement:
- below `Categories`
- above the featured `Collection Insight`

Reason:
- this is the best place to guide the next action
- it creates momentum early in the session
- it keeps the feature visible without overwhelming the screen

### Profile
Add a `Badges` section to Profile.

Reason:
- badges are identity-driven
- Profile is the right place to show earned progress
- Home should motivate, Profile should showcase

## Home component rules
Show:
- 1 primary goal
- up to 2 secondary goals

Do not show more than 3 total goals at once.

The component should be:
- slim
- easy to scan
- clearly actionable
- visually quieter than the main Home hero

Each goal can include:
- short title
- one short helper line
- progress if useful
- reward preview when relevant

Example:
- `Add a photo to 1 item`
- `Earns: Photo Ready`

## Goal types
Use only goals based on real collection data the app already trusts.

Good goal types:
- add first item
- add a photo
- add a new favorite
- complete missing titles or core fields
- improve photo coverage
- add a recent pickup
- reach a small category milestone
- finish a first-week or this-week collector prompt

Avoid:
- daily pressure mechanics
- arbitrary points
- fake currency
- streak loss punishment
- tasks that feel like chores

## Goal generation rules
- prefer goals that are easy to complete in one short session
- prefer goals that improve collection quality
- prefer goals that match the user’s current collection state
- avoid repeating the exact same goal too often
- do not show goals that are already completed
- if there are not 3 strong goals, show fewer
- if there is not 1 meaningful goal, hide the component

## Badge rules
Badges should feel tasteful and premium.

Do not make them cartoonish.

Badges should be awarded for:
- meaningful first steps
- collection growth
- archive quality improvements
- consistency over time

## Recommended first badge set
- `First Shelf`
  - awarded after the first item is added
- `Archive Starter`
  - awarded at 10 items
- `Photo Ready`
  - awarded when photo coverage reaches a meaningful threshold
- `Favorite Finder`
  - awarded after the first favorite or a small favorite milestone
- `Category Builder`
  - awarded after collecting across multiple categories
- `Consistent Collector`
  - awarded for repeated activity across multiple weeks

## Badge display rules
Profile should show:
- earned badges first
- compact visual treatment
- no giant trophy wall

Optional:
- locked badges can appear only if they motivate rather than frustrate

If locked badges are shown:
- keep them subtle
- do not let them dominate the section

## Empty-state behavior
- brand-new users should not see badges or goals that feel irrelevant
- if the user has no collection yet, show one simple starter goal
- if the user has very little data, show only the most obvious goal
- if there are no meaningful goals, hide the goals component entirely

## Tone
- premium
- encouraging
- collector-first
- satisfying
- never childish
- never manipulative

## UX guardrails
- do not interrupt the user with achievement popups too often
- do not bury Home content under gamification
- do not let goals compete visually with the main Home story
- do not create pressure to return every day
- do not use red urgency or countdown-style framing

## Success criteria
The feature should make the app feel:
- more alive
- more rewarding
- more personal
- easier to re-enter with a clear next step

It should not make the app feel:
- noisy
- gimmicky
- arcade-like
- artificially addictive
