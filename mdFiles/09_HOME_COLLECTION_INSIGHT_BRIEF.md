# Collector App - Home Collection Insight Brief

## Purpose
The home screen should feel alive, personal, and collector-first.

This component gives the app a smart editorial layer by surfacing one meaningful fact about the user's collection at a time.

It should feel like:
- the app understands the collection
- the collection has a personality
- the home screen is more than stacked utility sections

It should not feel like:
- a random fact generator
- an analytics dashboard
- a noisy carousel
- a nagging productivity widget

## Recommended component name
Use:
- internal name: `HomeCollectionInsightCard`
- user-facing eyebrow: `Collection Insight`

Avoid overly clever names in the UI.
The component should feel premium and clear, not gimmicky.

## Placement
Place the component:
- below `Categories`
- above `Recently Added`

Why:
- it gives the home screen a stronger center of gravity
- it adds personality before the more functional shelves
- it works as a transition from category browse to item browse

## Presence rule
Show exactly one insight card on the non-empty home screen when there is enough meaningful data to support it.

Do not show:
- multiple insight cards stacked together
- a horizontally swipeable insight carousel
- auto-rotating facts while the user is on the screen

If there is no meaningful eligible insight, hide the component entirely.

The app should never show a weak or filler insight just to occupy space.

## Product role
This component should do three jobs at once:

1. Reinforce collector identity
2. Reward the user with a sense of progress or personality
3. Gently guide the user toward better collection quality when appropriate

The right tone is:
- observant
- confident
- warm
- premium
- lightly editorial

The wrong tone is:
- robotic
- corporate
- preachy
- judgmental
- overly gamified

## Data source rule
The component must be local-first.

It should derive its candidate insights from the same archive-facing local data that powers Home.

Primary source:
- `ArchiveHomeSummary`
- local collectible records
- local photo refs

It must not:
- block Home rendering on a fresh network call
- require a separate remote fetch just to calculate an insight
- depend on volatile signed image URLs or server-only enrichment

If local data exists, the insight should be computable offline.

## Stability rule
The displayed insight must be stable for the current app session.

Do not reshuffle or randomize the card:
- when the widget rebuilds
- when the user returns to the tab in the same session
- when a background sync completes without invalidating the current fact

Recommended behavior:
- pick one best eligible insight when Home is first assembled for the session
- persist a lightweight history of recently shown insights locally
- rotate to a new best candidate on the next cold open or next session

If the current insight becomes invalid because the user changed the underlying collection data, it may be replaced in-session with the next strongest eligible candidate.

## Rotation rule
Rotation should feel curated, not random.

Recommended rotation policy:
- one featured insight per app session
- avoid repeating the exact same insight on consecutive sessions unless it is still clearly the strongest by a large margin
- avoid repeating the same insight family too often
- prefer variety across recent sessions

Persist enough local history to avoid repetition, for example:
- last shown insight id
- last shown insight family
- last shown primary entity such as category or franchise
- last shown date

## Insight families
The system should support a real library of insight types, grouped into families.

Each family should have its own eligibility rules, copy patterns, and CTA behavior.

### 1. Identity insights
These tell the user what currently defines their collection.

Examples:
- dominant category
- dominant franchise
- dominant brand
- favorite concentration
- grail concentration

Good for:
- making the collection feel recognizable
- giving the home screen personality

### 2. Momentum insights
These highlight what the user has been adding lately.

Examples:
- fastest-growing category
- recent streak in one category
- recent franchise trend
- strong recent focus on favorites or grails

Good for:
- making Home feel fresh
- reflecting recent collector behavior

### 3. Curation quality insights
These celebrate how polished or complete the collection feels.

Examples:
- strong photo coverage
- strong metadata coverage
- improved organization
- clean favorite curation

Good for:
- rewarding user effort
- reinforcing presentation quality

### 4. Care and improvement insights
These point to opportunities without sounding negative.

Examples:
- missing photos
- items missing condition or box status
- duplicates clustered in one category
- trade-ready items accumulating

Good for:
- subtle guidance
- creating helpful next actions

### 5. Value and rarity insights
These should only appear when the data is strong enough.

Examples:
- value tracked on most of the collection
- one category holds most tracked value
- grails concentrated in a specific lane

Good for:
- making the collection feel special
- surfacing meaningful standout areas

### 6. Milestone insights
These help smaller or newer collections still feel personal.

Examples:
- first category taking shape
- first favorite added
- collection passed 5 items
- photos added to first few items

Good for:
- avoiding dead space in smaller collections
- making early progress feel intentional

## Eligibility rules
Every insight must pass all of these gates before it can be shown:

1. It is true based on current local data
2. It can be explained clearly in one short sentence
3. It is meaningful for the current collection size
4. It is not redundant with what the user can already see nearby
5. It has a natural CTA or a strong editorial payoff even without one

If any of those fail, skip the insight.

## Collection-size tiers
The insight engine should respect the size of the collection.

### 0 items
Show no insight card.
The empty state already owns the screen.

### 1 to 2 items
Allow only milestone or gentle identity insights.

Good examples:
- `Your shelf is taking shape.`
- `Action Figures are leading your collection already.`

Avoid:
- trend language
- percentage-heavy copy
- improvement prompts that sound premature

### 3 to 5 items
Allow:
- identity
- simple momentum
- simple curation quality
- early care prompts

Keep copy simple and concrete.

### 6 or more items
Unlock the full insight library.

## Ranking rule
The engine should generate all eligible insights, score them, then choose one winner.

Recommended scoring dimensions:
- significance: how meaningful the fact is
- confidence: how strongly the data supports the conclusion
- freshness: whether it reflects recent behavior
- actionability: whether it leads to a useful next step
- novelty: whether the user has not seen something too similar recently
- emotional value: whether it feels rewarding or interesting

Recommended tie-break order:
1. significance
2. novelty
3. actionability
4. freshness

## Anti-repetition rules
The card should not feel stuck or repetitive.

Do not show:
- the same exact template in back-to-back sessions
- the same category-driven insight more than twice in a short window unless the collection is overwhelmingly centered there
- multiple sessions in a row from the same family when other strong candidates exist

If repetition is unavoidable because the collection is still very small, prefer changing the copy template even if the core fact is similar.

## Copy rules
Copy should be short, readable, and premium.

Recommended structure:
- eyebrow
- headline
- one supporting line
- optional CTA

Headline rules:
- 3 to 8 words ideal
- specific beats generic
- avoid jargon
- avoid sounding machine-generated

Supporting line rules:
- one sentence
- one fact only
- include numbers when they strengthen clarity
- do not overload with percentages unless they truly help

Tone rules:
- celebrate before you critique
- guide without scolding
- sound observant, not analytical
- avoid exclamation overload

Avoid copy like:
- `You only added 2 photos.`
- `Most of your items are incomplete.`
- `Your collection is poorly organized.`

Prefer copy like:
- `Your shelf is becoming more visual.`
- `More of your collection now has photos.`
- `A few items could use photos to complete the archive.`

## CTA rules
The component may include a CTA when there is a clear action worth taking.

The CTA must be:
- directly relevant to the insight
- achievable in one tap
- optional, not required

Good CTA examples:
- `Open Library`
- `View Action Figures`
- `See Favorites`
- `Add Photos`
- `Review Trade Items`

Bad CTA examples:
- vague exploration prompts
- anything unrelated to the insight
- multiple competing actions in the same card

One card should have:
- zero or one CTA
- never two buttons

If there is no strong action, the card can remain informational only.

## Interaction rules
The card should feel tappable only when it actually does something useful.

Recommended interaction pattern:
- make the whole card tappable when it has a single clear destination
- otherwise keep only the explicit CTA tappable

Do not add:
- swipe interactions
- flip states
- expandable accordion behavior
- multiple action chips

This card should feel calm and intentional.

## Visual direction
The component should look editorial and premium, not like a stats widget.

Recommended structure:
- eyebrow at top
- strong headline
- one supporting line
- optional badge or small accent
- optional CTA aligned to the bottom

Recommended visual behavior:
- one consistent card shape
- subtle family-based accent color
- soft glow or gradient only if restrained
- enough visual weight to feel important, but not louder than the welcome area

Avoid:
- pie-chart energy
- raw analytics tiles
- multiple tiny pills competing for attention
- visual clutter from too many metrics

## Family-based visual accents
Use restrained visual variation by insight family.

Examples:
- Identity: violet or indigo accent
- Momentum: azure or cyan accent
- Curation quality: emerald accent
- Care and improvement: amber accent
- Value and rarity: rose or coral accent
- Milestone: warm neutral or mixed premium accent

The frame and spacing should stay consistent.
Only the accent treatment should vary.

## Example insight templates
These are examples of the tone and structure to follow.

### Identity
- Headline: `Action Figures lead your shelf`
- Support: `They make up the biggest part of your collection right now.`
- CTA: `View Action Figures`

- Headline: `TMNT is shaping your archive`
- Support: `More of your collectibles point back to that franchise than any other.`
- CTA: `Open Library`

### Momentum
- Headline: `Your comic shelf is growing fast`
- Support: `Comics have led your recent adds more than any other category.`
- CTA: `View Comics`

- Headline: `You have been on a vinyl run`
- Support: `Several of your latest additions landed in Vinyl Figures.`
- CTA: `View Vinyl Figures`

### Curation quality
- Headline: `Your collection is becoming more visual`
- Support: `A strong share of your items already has photos.`
- CTA: `Open Library`

- Headline: `Favorites are taking shape`
- Support: `You have started carving out a clear set of collector picks.`
- CTA: `See Favorites`

### Care and improvement
- Headline: `A few pieces could use photos`
- Support: `Adding images would make more of your archive easier to enjoy at a glance.`
- CTA: `Open Library`

- Headline: `Trade-ready items are building up`
- Support: `You already have several items marked as open to trade.`
- CTA: `Review Trade Items`

### Value and rarity
- Headline: `Your grails lean in one direction`
- Support: `Most of your grail-marked pieces sit in the same lane of the collection.`
- CTA: `Open Library`

- Headline: `Your value tracking is getting stronger`
- Support: `Enough items now have value data to start revealing patterns.`
- CTA: `Open Library`

### Milestone
- Headline: `Your shelf has started`
- Support: `The first few items already give your collection a clear identity.`

- Headline: `One category is already standing out`
- Support: `Even with a small collection, one lane is beginning to define your archive.`

## Concrete release-ready insight rules
These are the best release-quality insight rules to support.

### Dominant category
Show when:
- total items >= 3
- top category count >= 3
- top category leads second place by at least 1 item

Prefer when:
- the top category is at least 35 percent of the collection

CTA:
- `View <Category>`

### Dominant franchise
Show when:
- at least 3 items have a non-empty franchise
- top franchise count >= 3
- top franchise leads second place by at least 1

CTA:
- `Open Library`

### Favorite concentration
Show when:
- favorite count >= 3
- at least 2 favorites share the same category or franchise

CTA:
- `See Favorites`

### Grail concentration
Show when:
- grail count >= 2
- one category or franchise contains most grails

CTA:
- `Open Library`

### Recent category momentum
Show when:
- at least 4 recent dated items exist
- one category clearly leads within the latest recent slice

Recommended recent slice:
- latest 5 to 8 items, whichever is available and meaningful

CTA:
- `View <Category>`

### Photo coverage strength
Show when:
- total items >= 5
- at least 70 percent of items have photos

CTA:
- optional

### Photo coverage opportunity
Show when:
- total items >= 5
- at least 3 items do not have photos
- no stronger celebratory insight clearly wins

CTA:
- `Open Library`

### Duplicate cluster
Show when:
- duplicate count >= 2
- duplicates meaningfully cluster in one category or franchise

CTA:
- `Open Library`

### Open-to-trade cluster
Show when:
- open-to-trade count >= 2

CTA:
- `Review Trade Items`

### Value coverage strength
Show when:
- total items >= 6
- at least 60 percent of items have estimated value

CTA:
- `Open Library`

### Collection milestone
Show when:
- total items hits a meaningful threshold

Recommended thresholds:
- 3
- 5
- 10
- 25
- 50
- 100

Milestones should be used sparingly.
Do not let them drown out richer identity or momentum insights once the collection has matured.

## Priority rule
When multiple candidates are valid, prefer this general priority:

1. Strong identity insight
2. Strong momentum insight
3. Strong curation quality insight
4. Strong care and improvement insight
5. Value and rarity insight
6. Milestone insight

This keeps the card feeling like part of the collector experience first, and only secondarily like a maintenance prompt.

## Suppression rules
Suppress an insight when it would feel awkward or misleading.

Examples:
- do not show a franchise insight if franchise coverage is too sparse
- do not show a value insight if only a small handful of items have values
- do not show a momentum insight if recent items are too few or too mixed
- do not show a care prompt immediately after the user fixed the underlying issue unless it still remains materially true
- do not show a milestone and a care prompt fighting for the same moment; the winner should be whichever better fits the current stage

## Mutation and refresh rules
If the user edits the collection during the session:
- recompute candidate eligibility in the background
- keep the current displayed insight if it is still valid
- replace it only if it becomes invalid or materially stale

Examples:
- if a photo-opportunity insight is shown and the user adds photos, replace it if the threshold no longer holds
- if a category-dominance insight remains true after one item edit, leave it stable

## Offline rule
Once local archive data exists, the card should remain functional offline.

This includes:
- the displayed copy
- its CTA destination
- its ability to render without a network fetch

If an action would eventually require connectivity, do not route through that action from this card unless the surrounding surface already supports it gracefully.

## Performance rule
The card should be cheap to compute.

Recommended implementation direction:
- derive a normalized summary snapshot once
- generate candidate insights from that snapshot
- score candidates
- pick a winner

Avoid:
- expensive repeated scans on every tiny rebuild
- remote lookups
- image-heavy rendering requirements

## Accessibility rule
The component should be easy to read and easy to act on.

Requirements:
- headline and support text must preserve contrast against all accent treatments
- the CTA must remain obvious at larger text sizes
- the card should not depend on color alone to convey meaning
- semantics should read as one coherent insight, not a pile of disconnected labels

## Analytics rule
Track enough to learn whether the component is working.

Useful events:
- insight shown
- insight family shown
- CTA tapped
- destination opened
- collection size at show time

Do not over-instrument with noisy view events on every rebuild.

## Recommended implementation shape
When this is built, use a clean separation:

1. `HomeCollectionInsightEngine`
   - generates and ranks candidate insights
2. `HomeCollectionInsight`
   - normalized data model for a chosen insight
3. `HomeCollectionInsightHistoryStore`
   - lightweight local persistence for anti-repetition
4. `HomeCollectionInsightCard`
   - UI component only

This keeps logic, persistence, and presentation separated.

## Final design principle
This component should make the user feel:
- seen
- proud
- gently guided

If a candidate insight is technically true but emotionally flat, repetitive, or awkward, it should not ship.

The standard is not just correctness.
The standard is whether the card makes Home feel more like a collector's space.
