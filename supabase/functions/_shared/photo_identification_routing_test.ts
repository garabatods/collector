import { assertEquals, assertFalse } from "jsr:@std/assert@1";
import {
  photoIdentificationCacheKey,
  photoIdentificationEscalationReasons,
  shouldEscalatePhotoIdentification,
} from "./photo_identification_routing.ts";

const confidentSignals = {
  title: "Funko Pop! Marvel Spider-Man 03",
  confidence: 0.91,
  barcode: null,
  visibleText: ["Spider-Man", "03"],
  identifyingMarkers: ["red and blue suit", "Funko Pop box"],
  alternativeCandidates: [],
  needsStrongerModel: false,
};

Deno.test("accepts a high-confidence identification with visible evidence", () => {
  assertFalse(shouldEscalatePhotoIdentification(confidentSignals));
  assertEquals(photoIdentificationEscalationReasons(confidentSignals), []);
});

Deno.test("escalates a confident guess that lacks visible evidence", () => {
  const reasons = photoIdentificationEscalationReasons({
    ...confidentSignals,
    visibleText: [],
    identifyingMarkers: ["red figure"],
  });

  assertEquals(reasons, ["insufficient_visible_evidence"]);
});

Deno.test("escalates low confidence or competing candidates", () => {
  const reasons = photoIdentificationEscalationReasons({
    ...confidentSignals,
    confidence: 0.68,
    alternativeCandidates: ["Spider-Man 2099"],
  });

  assertEquals(reasons, ["low_confidence", "multiple_candidates"]);
});

Deno.test("versions cache entries by pipeline and model route", () => {
  const lunaTerra = photoIdentificationCacheKey({
    imageFingerprint: "abc123",
    primaryModel: "gpt-5.6-luna",
    fallbackModel: "gpt-5.6-terra",
  });
  const terraOnly = photoIdentificationCacheKey({
    imageFingerprint: "abc123",
    primaryModel: "gpt-5.6-terra",
    fallbackModel: "gpt-5.6-terra",
  });

  assertEquals(lunaTerra.includes("luna-terra-v1"), true);
  assertEquals(lunaTerra === terraOnly, false);
});
