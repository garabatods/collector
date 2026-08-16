# Ownzith Pro Access and Usage

## Product limits

| Capability | Free | Pro |
|---|---:|---:|
| Collectible rows | 20 | 10,000 |
| PhotoID | 3 successful lifetime requests | 50 successful requests per UTC month, 10/day |
| UPC catalog lookup | Not included | 100 uncached attempts per UTC month, 25/day |

Quantity does not use extra slots. Deleting a collectible immediately frees one
slot. A downgrade preserves all collectibles and photos; viewing, editing,
deleting, and CSV export remain available, while new inserts are blocked until
the account is under the Free ceiling or Pro is restored.

## Billing identifiers

- RevenueCat entitlement: `pro`
- Monthly: `com.neoncartridgelabs.ownzith.pro.monthly`
- Annual: `com.neoncartridgelabs.ownzith.pro.annual`
- RevenueCat App User ID: authenticated Supabase user UUID
- App build configuration: `REVENUECAT_IOS_API_KEY` and, when Android ships,
  `REVENUECAT_ANDROID_API_KEY` as Dart defines

## Server ownership

The client reads only `get_account_access()`. Entitlements, administrative
overrides, reservations, usage outcomes, and RevenueCat webhook events are
server-owned. Feature reservations use a request UUID, an advisory transaction
lock, and one final `consumed` or `refunded` outcome. Cache hits are logged but
do not consume an allowance.

The `identify_collectible` function records provider, model, Luna-to-Terra
fallback, token counts, duration, cache state, and outcome. It does not store an
additional photo copy. Provider failures, malformed responses, timeouts, and
internal errors refund a reservation. Stale reservations are automatically
refunded after ten minutes.

## Safe rollout

The initial migration leaves `item_enforcement_enabled` and
`usage_enforcement_enabled` disabled in `ownzith_runtime_settings`. Do not enable
them until Apple products, RevenueCat offerings, webhook authorization, sandbox
purchases, downgrade behavior, and usage-meter accuracy have been verified in
TestFlight.

Immediately before deploying the removal migration:

1. Confirm `public.wishlist_items` still has zero rows.
2. Take a schema backup.
3. Apply the migrations and deploy both Edge Functions.
4. Set `REVENUECAT_WEBHOOK_SECRET` to the exact Authorization header configured
   in RevenueCat.
5. Configure the public-launch timestamp by replacing the prelaunch beta
   entitlement expiration.
6. Run counters in shadow mode, then enable usage enforcement and item
   enforcement separately after verification.

The removal migration stops instead of dropping the old remote table if any row
appears during the final pre-deploy check.
