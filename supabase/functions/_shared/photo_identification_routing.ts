export const photoIdentificationPipelineVersion = "luna-terra-v1";

export interface PhotoIdentificationSignals {
  title: string;
  confidence: number | null;
  barcode: string | null;
  visibleText: string[];
  identifyingMarkers: string[];
  alternativeCandidates: string[];
  needsStrongerModel: boolean;
}

export function photoIdentificationEscalationReasons(
  signals: PhotoIdentificationSignals,
): string[] {
  const reasons: string[] = [];
  if (!signals.title.trim()) {
    reasons.push("missing_title");
  }
  if ((signals.confidence ?? 0) < 0.82) {
    reasons.push("low_confidence");
  }
  if (signals.needsStrongerModel) {
    reasons.push("model_requested_verification");
  }
  if (signals.alternativeCandidates.length > 0) {
    reasons.push("multiple_candidates");
  }

  const hasVisibleText = signals.visibleText.some((value) =>
    value.trim().length >= 2
  );
  const hasEnoughVisualMarkers =
    signals.identifyingMarkers.filter((value) => value.trim().length >= 3)
      .length >= 2;
  if (!signals.barcode && !hasVisibleText && !hasEnoughVisualMarkers) {
    reasons.push("insufficient_visible_evidence");
  }

  return reasons;
}

export function shouldEscalatePhotoIdentification(
  signals: PhotoIdentificationSignals,
): boolean {
  return photoIdentificationEscalationReasons(signals).length > 0;
}

export function photoIdentificationCacheKey({
  imageFingerprint,
  primaryModel,
  fallbackModel,
}: {
  imageFingerprint: string;
  primaryModel: string;
  fallbackModel: string;
}): string {
  return [
    photoIdentificationPipelineVersion,
    primaryModel,
    fallbackModel,
    imageFingerprint,
  ].join(":");
}
