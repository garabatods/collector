# Multi-Scan MVP Plan

## Goal
Add a V1 multi-scan mode for power users who want to scan several boxed items quickly, then review matches before saving them to the collection.

This should be treated as a future paid-perk candidate, but the first implementation should stay lean and reuse the current barcode identification flow.

## Product Decision
- Default scanner mode stays single-scan.
- Multi-scan is enabled with a visible toggle/chip inside the scanner.
- Multi-scan tray is capped at 5 unique barcodes for V1.
- Lookups run one-by-one through the existing backend flow, not as a true batch request.
- Users review the tray before creating collectibles.
- The feature should not auto-save catalog guesses without user review.

## Why 5 Items
- The current setup does not use a paid UPC API plan.
- UPC/free lookup limits can be tight, so 10+ items risks burning quota quickly.
- Five scans is enough to feel meaningfully faster than single scan.
- Five rows are still easy to review and correct on a phone.

## Existing Code To Reuse
- `lib/screens/scanner_flow_screen.dart`
  - Current camera scanner flow.
  - Current single barcode detection behavior.
  - Current scan result UI patterns.
- `lib/features/collection/data/repositories/collectible_identification_repository.dart`
  - Existing `identifyBarcode()` method.
  - Current session cache behavior.
- `supabase/functions/identify_collectible/index.ts`
  - Existing barcode lookup path: cache, UPCitemDB, GO-UPC, not found.
- `lib/features/collection/data/services/add_item_autofill_resolver.dart`
  - Converts identification results into form-prefill data.
- `lib/screens/manual_add_collectible_screen.dart`
  - Existing add/edit form and save behavior.

## Proposed UX
1. User opens scanner.
2. Scanner defaults to single-scan mode.
3. User taps `Multi-scan` toggle.
4. UI shows tray status: `0/5 scanned`.
5. Each unique barcode is added to the tray.
6. Duplicate barcodes are ignored with a small inline note.
7. Tray rows show states:
   - `Queued`
   - `Looking up`
   - `Found`
   - `No match`
   - `Needs retry`
8. Once there is at least one barcode, show `Review items`.
9. When the tray reaches 5, scanning pauses and prompts review.
10. Review flow lets the user confirm or edit each item before saving.

## V1 Implementation Steps
1. Add a multi-scan mode flag to `ScannerFlowScreen`.
2. Add a tray item model local to the scanner screen:
   - barcode
   - status
   - identification result
   - lookup message/error
   - optional autofill result
3. Change barcode detection behavior:
   - single mode keeps current pause-and-lookup behavior.
   - multi mode dedupes and appends barcodes without leaving the scanner.
4. Add a queue worker:
   - process one barcode at a time.
   - reuse `identifyBarcode()`.
   - add a small delay between lookups if needed.
   - never process more than one active lookup at once.
5. Add tray UI inside scanner:
   - mode toggle.
   - count `n/5`.
   - compact list of tray items.
   - `Review items` button.
   - `Clear tray` action.
6. Add review flow:
   - simplest V1 can review one item at a time by opening `ManualAddCollectibleScreen` with the scanned barcode, identification result, and autofill result.
   - after saving or skipping one item, return to the tray and continue.
7. Refresh library views when at least one item was created.
8. Add guardrails:
   - max 5 unique barcodes.
   - ignore empty/invalid raw values.
   - ignore duplicates.
   - show retry for failed lookups.
   - keep AI photo ID available for no-match items.

## Backend Plan
V1 does not need a new backend endpoint.

Use the current single-barcode call:
- app calls `CollectibleIdentificationRepository.identifyBarcode(barcode)`.
- repository invokes `identify_collectible` with `mode: "barcode"`.
- edge function handles cache, UPCitemDB, GO-UPC fallback, and not-found cache.

Future paid/performance upgrade:
- add `mode: "barcode_batch"`.
- accept `barcodes: string[]`.
- dedupe and cap server-side.
- check cache per barcode.
- query UPCitemDB in chunks if the paid plan supports useful batch limits.
- throttle GO-UPC fallback.
- return ordered per-barcode results.

## Open Questions For Build Time
- Should `Review items` open a new review screen or use a bottom sheet?
- Should saving one item remove it from the tray immediately?
- Should no-match items go straight to manual add with only barcode prefilled?
- Should the scanner remember last mode after app restart? V1 answer should probably be no.
- Should this feature be hidden behind a feature flag before paid gating exists?

## Recommended V1 Scope
Build it as a scanner-local feature first:
- no database schema changes.
- no new Supabase function.
- no paid-gating logic yet.
- no persistent queue after app restart.
- no true bulk create until the review UX is proven.

This keeps the feature useful without turning scanner, API quota handling, and save flows into a big refactor.
