import { identificationCacheTtlDays } from "./identification_cache_policy.ts";

Deno.test("keeps successful barcode matches for five years", () => {
  if (identificationCacheTtlDays("barcode", "matched") !== 1825) {
    throw new Error("Unexpected successful barcode retention");
  }
});

Deno.test("keeps successful photo matches for two years", () => {
  if (identificationCacheTtlDays("photo", "enriched") !== 730) {
    throw new Error("Unexpected successful photo retention");
  }
});

Deno.test("keeps partial results for ninety days", () => {
  if (identificationCacheTtlDays("photo", "partial") !== 90) {
    throw new Error("Unexpected partial-result retention");
  }
});

Deno.test("expires failed and missing results after seven days", () => {
  if (identificationCacheTtlDays("barcode", "not_found") !== 7) {
    throw new Error("Unexpected not-found retention");
  }
  if (identificationCacheTtlDays("photo", "failed") !== 7) {
    throw new Error("Unexpected failed-result retention");
  }
});
