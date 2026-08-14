export type IdentificationCacheMode = "barcode" | "photo";
export type IdentificationCacheStatus =
  | "matched"
  | "enriched"
  | "partial"
  | "not_found"
  | "failed";

const successfulBarcodeTtlDays = 5 * 365;
const successfulPhotoTtlDays = 2 * 365;
const partialResultTtlDays = 90;
const disposableResultTtlDays = 7;

export function identificationCacheTtlDays(
  mode: IdentificationCacheMode,
  status: IdentificationCacheStatus,
): number {
  switch (status) {
    case "matched":
    case "enriched":
      return mode === "barcode"
        ? successfulBarcodeTtlDays
        : successfulPhotoTtlDays;
    case "partial":
      return partialResultTtlDays;
    case "not_found":
    case "failed":
      return disposableResultTtlDays;
  }
}
