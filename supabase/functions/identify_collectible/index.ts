import { createClient, type SupabaseClient } from "npm:@supabase/supabase-js@2";
import { identificationCacheTtlDays } from "../_shared/identification_cache_policy.ts";
import {
  photoIdentificationCacheKey,
  photoIdentificationEscalationReasons,
  photoIdentificationPipelineVersion,
} from "../_shared/photo_identification_routing.ts";
import {
  parseOpenAiStructuredOutput,
  shouldRetryOpenAiStructuredOutput,
} from "../_shared/openai_structured_output.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

const appCategories = [
  "Action Figures",
  "Board Games",
  "Comics",
  "Memorabilia",
  "Die-cast",
  "Vinyl Figures",
  "Statues",
  "Trading Cards",
  "Other",
] as const;

type JsonMap = Record<string, unknown>;
type UntypedSupabaseClient = SupabaseClient<any, "public", "public", any, any>;

type LookupMode = "barcode" | "photo";
type LookupStatus = "matched" | "enriched" | "partial" | "not_found" | "failed";
type ProviderStage = "cache" | "upcitemdb" | "goupc" | "metron" | "openai";
type CachedProviderStage = ProviderStage | "comicvine";

interface CacheRow {
  normalized_result: JsonMap;
  status: LookupStatus;
  provider_stage: CachedProviderStage;
  raw_result: unknown;
  expires_at: string;
}

interface ComicContext {
  issue_number: string | null;
  volume_name: string | null;
  publisher: string | null;
}

interface ComicBarcodeSupplement {
  barcode: string;
  issueNumber: number;
  variantNumber: number;
  printingNumber: number;
}

interface NormalizedIdentificationResult extends JsonMap {
  status: LookupStatus;
  provider_stage: ProviderStage;
  title: string;
  suggested_category: string | null;
  image_url: string | null;
  description: string | null;
  brand: string | null;
  franchise: string | null;
  series: string | null;
  character_or_subject: string | null;
  release_year: number | null;
  barcode: string | null;
  confidence: number | null;
  source_badge: string;
  comic_context: ComicContext | null;
}

interface ProviderMatch {
  status: LookupStatus;
  providerStage: ProviderStage;
  result: NormalizedIdentificationResult;
  rawResult: unknown;
}

interface UsageReservation {
  adminClient: UntypedSupabaseClient;
  userId: string;
  requestId: string;
  startedAt: number;
}

interface OpenAiPhotoResult {
  result: NormalizedIdentificationResult;
  rawResult: unknown;
  detectedBarcode: string | null;
  isConfidentMatch: boolean;
}

interface OpenAiPhotoAssessment {
  payload: JsonMap;
  parsed: JsonMap;
  result: NormalizedIdentificationResult;
  detectedBarcode: string | null;
  visibleText: string[];
  identifyingMarkers: string[];
  alternativeCandidates: string[];
  needsStrongerModel: boolean;
}

const upcItemDbEndpoint = "https://api.upcitemdb.com/prod/trial/lookup";
const upcItemDbSearchEndpoint = "https://api.upcitemdb.com/prod/trial/search";
const goUpcEndpoint = "https://go-upc.com/api/v1/code";
const metronIssueEndpoint = "https://metron.cloud/api/issue/";
const metronNotFoundCacheRefreshVersion = "metron-not-found-v1";
const metronVariantCandidateLimit = 25;
const metronSupplementConflictCacheTtlDays = 7;
const openAiResponsesEndpoint = "https://api.openai.com/v1/responses";
const defaultOpenAiPhotoPrimaryModel = "gpt-5.6-luna";
const defaultOpenAiPhotoFallbackModel = "gpt-5.6-terra";
const acceptedImageMimeTypes = new Set([
  "image/jpeg",
  "image/png",
  "image/webp",
  "image/heic",
  "image/heif",
]);
const collectibleIdentificationSchema = {
  type: "object",
  additionalProperties: false,
  properties: {
    title: { type: "string" },
    suggested_category: {
      anyOf: [
        { type: "null" },
        {
          type: "string",
          enum: [...appCategories],
        },
      ],
    },
    description: { anyOf: [{ type: "string" }, { type: "null" }] },
    brand: { anyOf: [{ type: "string" }, { type: "null" }] },
    franchise: { anyOf: [{ type: "string" }, { type: "null" }] },
    series: { anyOf: [{ type: "string" }, { type: "null" }] },
    character_or_subject: { anyOf: [{ type: "string" }, { type: "null" }] },
    release_year: { anyOf: [{ type: "integer" }, { type: "null" }] },
    confidence: { anyOf: [{ type: "number" }, { type: "null" }] },
    source_badge: { anyOf: [{ type: "string" }, { type: "null" }] },
    barcode_candidate: { anyOf: [{ type: "string" }, { type: "null" }] },
    is_comic_like: { anyOf: [{ type: "boolean" }, { type: "null" }] },
    visible_text: {
      type: "array",
      items: { type: "string" },
      maxItems: 12,
    },
    identifying_markers: {
      type: "array",
      items: { type: "string" },
      maxItems: 12,
    },
    alternative_candidates: {
      type: "array",
      items: { type: "string" },
      maxItems: 3,
    },
    needs_stronger_model: { type: "boolean" },
    ambiguity_reason: { anyOf: [{ type: "string" }, { type: "null" }] },
    comic_context: {
      anyOf: [
        { type: "null" },
        {
          type: "object",
          additionalProperties: false,
          properties: {
            issue_number: { anyOf: [{ type: "string" }, { type: "null" }] },
            volume_name: { anyOf: [{ type: "string" }, { type: "null" }] },
            publisher: { anyOf: [{ type: "string" }, { type: "null" }] },
          },
          required: ["issue_number", "volume_name", "publisher"],
        },
      ],
    },
  },
  required: [
    "title",
    "suggested_category",
    "description",
    "brand",
    "franchise",
    "series",
    "character_or_subject",
    "release_year",
    "confidence",
    "source_badge",
    "barcode_candidate",
    "is_comic_like",
    "visible_text",
    "identifying_markers",
    "alternative_candidates",
    "needs_stronger_model",
    "ambiguity_reason",
    "comic_context",
  ],
} as const;

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  let reservedUsage: UsageReservation | null = null;

  try {
    const supabaseUrl = mustGetEnv("SUPABASE_URL");
    const supabaseAnonKey = mustGetEnv("SUPABASE_ANON_KEY");
    const supabaseServiceRoleKey = mustGetEnv("SUPABASE_SERVICE_ROLE_KEY");
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return jsonResponse(
        { error: "Missing authorization header." },
        401,
      );
    }

    const authClient = createClient(supabaseUrl, supabaseAnonKey, {
      auth: { persistSession: false, autoRefreshToken: false },
    });
    const token = authHeader.replace(/^Bearer\s+/i, "").trim();
    const {
      data: claimsData,
      error: claimsError,
    } = await authClient.auth.getClaims(token);
    const userId = asString(claimsData?.claims?.sub);

    if (claimsError || !userId) {
      return jsonResponse(
        { error: "Could not resolve the authenticated user." },
        401,
      );
    }

    const adminClient = createClient(supabaseUrl, supabaseServiceRoleKey, {
      auth: { persistSession: false, autoRefreshToken: false },
    });

    const payload = await req.json();
    const mode = asString(payload?.mode) as LookupMode | null;
    const suppliedRequestId = asString(payload?.request_id);
    const requestId = suppliedRequestId == null
      ? crypto.randomUUID()
      : normalizeRequestId(suppliedRequestId);
    if (mode !== "barcode" && mode !== "photo") {
      return jsonResponse(
        { error: "Expected mode to be either `barcode` or `photo`." },
        400,
      );
    }
    if (!requestId) {
      return jsonResponse({ error: "A valid request_id is required." }, 400);
    }

    if (mode === "barcode") {
      const access = await fetchAccountAccess(adminClient, userId);
      if (
        !asBoolean(access.is_pro) &&
        asBoolean(access.usage_enforcement_enabled)
      ) {
        return jsonResponse(
          {
            error: "Barcode catalog lookup is included with Ownzith Pro.",
            code: "pro_required",
          },
          402,
        );
      }
      const barcode = normalizeBarcode(asString(payload?.barcode));
      if (!barcode) {
        return jsonResponse(
          { error: "A valid barcode is required." },
          400,
        );
      }

      const sharedCached = await fetchSharedBarcodeCache({
        adminClient,
        barcode,
      });
      if (sharedCached) {
        const sanitizedMetronPartial = rebuildCachedMetronPartial(
          sharedCached,
          barcode,
        );
        if (sanitizedMetronPartial) {
          await saveSharedBarcodeMatch({
            adminClient,
            barcode,
            ttlDays: barcodeCacheTtlDays(sanitizedMetronPartial),
            match: sanitizedMetronPartial,
          });
          await recordCacheHit(adminClient, userId, requestId, "upc_lookup");
          return jsonResponse(sanitizedMetronPartial.result, 200);
        }
        const refreshLegacyNotFound = shouldRefreshCachedNotFoundWithMetron(
          sharedCached,
        );
        const metronMatch = await refreshCachedComicWithMetron(
          sharedCached,
          barcode,
        );
        if (metronMatch) {
          await saveSharedBarcodeMatch({
            adminClient,
            barcode,
            ttlDays: barcodeCacheTtlDays(metronMatch),
            match: metronMatch,
          });
          return jsonResponse(metronMatch.result, 200);
        }
        if (refreshLegacyNotFound) {
          await saveSharedBarcodeCache({
            adminClient,
            barcode,
            cached: markMetronNotFoundRefresh(sharedCached),
          });
        }
        await recordCacheHit(adminClient, userId, requestId, "upc_lookup");
        return jsonResponse(cacheHit(sharedCached), 200);
      }

      const cached = await fetchCache({
        adminClient,
        userId,
        lookupType: "barcode",
        lookupKey: barcode,
      });
      if (cached) {
        const sanitizedMetronPartial = rebuildCachedMetronPartial(
          cached,
          barcode,
        );
        if (sanitizedMetronPartial) {
          const ttlDays = barcodeCacheTtlDays(sanitizedMetronPartial);
          await Promise.all([
            saveCache({
              adminClient,
              userId,
              lookupType: "barcode",
              lookupKey: barcode,
              ttlDays,
              match: sanitizedMetronPartial,
            }),
            saveSharedBarcodeMatch({
              adminClient,
              barcode,
              ttlDays,
              match: sanitizedMetronPartial,
            }),
          ]);
          await recordCacheHit(adminClient, userId, requestId, "upc_lookup");
          return jsonResponse(sanitizedMetronPartial.result, 200);
        }
        const refreshLegacyNotFound = shouldRefreshCachedNotFoundWithMetron(
          cached,
        );
        const metronMatch = await refreshCachedComicWithMetron(cached, barcode);
        if (metronMatch) {
          const ttlDays = barcodeCacheTtlDays(metronMatch);
          await Promise.all([
            saveCache({
              adminClient,
              userId,
              lookupType: "barcode",
              lookupKey: barcode,
              ttlDays,
              match: metronMatch,
            }),
            saveSharedBarcodeMatch({
              adminClient,
              barcode,
              ttlDays,
              match: metronMatch,
            }),
          ]);
          return jsonResponse(metronMatch.result, 200);
        }
        if (refreshLegacyNotFound) {
          await markIdentificationCacheMetronRefresh({
            adminClient,
            userId,
            lookupType: "barcode",
            lookupKey: barcode,
            cached,
          });
        }
        await saveSharedBarcodeCache({
          adminClient,
          barcode,
          cached,
        });
        await recordCacheHit(adminClient, userId, requestId, "upc_lookup");
        return jsonResponse(cacheHit(cached), 200);
      }

      const reservation = await reserveUsage({
        adminClient,
        userId,
        requestId,
        feature: "upc_lookup",
      });
      if (!reservation.allowed) {
        return usageLimitResponse(reservation.reason);
      }
      reservedUsage = { adminClient, userId, requestId, startedAt: Date.now() };

      const catalogMatch = await lookupBarcodeCatalog(barcode);
      if (catalogMatch) {
        const ttlDays = barcodeCacheTtlDays(catalogMatch);
        await Promise.all([
          saveCache({
            adminClient,
            userId,
            lookupType: "barcode",
            lookupKey: barcode,
            ttlDays,
            match: catalogMatch,
          }),
          saveSharedBarcodeMatch({
            adminClient,
            barcode,
            ttlDays,
            match: catalogMatch,
          }),
        ]);
        await finalizeReservedUsage(reservedUsage, true, {
          provider: catalogMatch.providerStage,
          outcome: catalogMatch.status,
        });
        reservedUsage = null;
        return jsonResponse(catalogMatch.result, 200);
      }

      const miss = buildNotFoundResult({
        providerStage: "goupc",
        barcode,
        sourceBadge: "No catalog match",
      });
      const missMatch: ProviderMatch = {
        status: "not_found",
        providerStage: "goupc",
        result: miss,
        rawResult: {
          upcitemdb: null,
          goupc: null,
        },
      };
      const ttlDays = barcodeCacheTtlDays(missMatch);
      await Promise.all([
        saveCache({
          adminClient,
          userId,
          lookupType: "barcode",
          lookupKey: barcode,
          ttlDays,
          match: missMatch,
        }),
        saveSharedBarcodeMatch({
          adminClient,
          barcode,
          ttlDays,
          match: missMatch,
        }),
      ]);
      await finalizeReservedUsage(reservedUsage, true, {
        provider: "goupc",
        outcome: "not_found",
      });
      reservedUsage = null;
      return jsonResponse(miss, 200);
    }

    const imageBase64 = stripDataUrlPrefix(asString(payload?.image_base64));
    const mimeType = normalizeMimeType(asString(payload?.mime_type));
    if (!imageBase64 || !mimeType) {
      return jsonResponse(
        { error: "Photo mode requires image_base64 and mime_type." },
        400,
      );
    }
    if (!acceptedImageMimeTypes.has(mimeType)) {
      return jsonResponse(
        { error: "Use a JPEG, PNG, WebP, HEIC, or HEIF image." },
        400,
      );
    }
    if (decodedBase64ByteLength(imageBase64) > 8 * 1024 * 1024) {
      return jsonResponse(
        { error: "The selected photo must be 8 MB or smaller." },
        413,
      );
    }

    const primaryModel = Deno.env.get("OPEN_AI_PHOTO_PRIMARY_MODEL") ??
      defaultOpenAiPhotoPrimaryModel;
    const fallbackModel = Deno.env.get("OPEN_AI_PHOTO_FALLBACK_MODEL") ??
      defaultOpenAiPhotoFallbackModel;
    const imageFingerprint = await sha256Hex(decodeBase64(imageBase64));
    const photoLookupKey = photoIdentificationCacheKey({
      imageFingerprint,
      primaryModel,
      fallbackModel,
    });
    const cached = await fetchCache({
      adminClient,
      userId,
      lookupType: "photo",
      lookupKey: photoLookupKey,
    });
    if (cached) {
      await recordCacheHit(adminClient, userId, requestId, "photo_id");
      return jsonResponse(cacheHit(cached), 200);
    }

    const reservation = await reserveUsage({
      adminClient,
      userId,
      requestId,
      feature: "photo_id",
    });
    if (!reservation.allowed) {
      return usageLimitResponse(reservation.reason);
    }
    reservedUsage = { adminClient, userId, requestId, startedAt: Date.now() };

    const barcodeHint = normalizeBarcode(asString(payload?.barcode));
    const openAiResult = await identifyPhotoWithOpenAi({
      imageBase64,
      mimeType,
      barcode: barcodeHint,
      primaryModel,
      fallbackModel,
    });
    const resolvedBarcode = barcodeHint ?? openAiResult.detectedBarcode;

    let finalMatch: ProviderMatch = {
      status: openAiResult.isConfidentMatch ? "matched" : "partial",
      providerStage: "openai",
      result: openAiResult.result,
      rawResult: openAiResult.rawResult,
    };

    const barcodeCatalogEnriched = await enrichPhotoWithBarcodeCatalog({
      barcode: resolvedBarcode,
      baseResult: finalMatch.result,
      openAiRawResult: openAiResult.rawResult,
    });
    if (barcodeCatalogEnriched) {
      finalMatch = barcodeCatalogEnriched;
    } else if (finalMatch.status !== "partial") {
      const textSearchEnriched = await enrichPhotoWithUpcItemDbSearch({
        baseResult: finalMatch.result,
        openAiRawResult: openAiResult.rawResult,
      });
      if (textSearchEnriched) {
        finalMatch = textSearchEnriched;
      }
    }

    await saveCache({
      adminClient,
      userId,
      lookupType: "photo",
      lookupKey: photoLookupKey,
      ttlDays: finalMatch.providerStage === "openai"
        ? Math.min(30, identificationCacheTtlDays("photo", finalMatch.status))
        : identificationCacheTtlDays("photo", finalMatch.status),
      match: finalMatch,
    });

    const usage = collectOpenAiUsage(openAiResult.rawResult);
    await finalizeReservedUsage(reservedUsage, true, {
      provider: "openai",
      model: usage.model,
      fallback_used: usage.fallbackUsed,
      input_tokens: usage.inputTokens,
      output_tokens: usage.outputTokens,
      outcome: finalMatch.status,
      metadata: { provider_stage: finalMatch.providerStage },
    });
    reservedUsage = null;

    return jsonResponse(finalMatch.result, 200);
  } catch (error) {
    console.error("identify_collectible failed", error);
    if (reservedUsage) {
      await finalizeReservedUsage(reservedUsage, false, {
        outcome: "provider_or_internal_error",
      });
    }
    return jsonResponse(
      {
        status: "failed",
        provider_stage: "openai",
        error: error instanceof Error
          ? error.message
          : "Identification is unavailable right now.",
      },
      500,
    );
  }
});

function normalizeRequestId(value: string | null): string | null {
  const normalized = value?.trim().toLowerCase() ?? "";
  return /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/
      .test(
        normalized,
      )
    ? normalized
    : null;
}

function decodedBase64ByteLength(value: string): number {
  const padding = value.endsWith("==") ? 2 : value.endsWith("=") ? 1 : 0;
  return Math.floor(value.length * 3 / 4) - padding;
}

async function fetchAccountAccess(
  adminClient: UntypedSupabaseClient,
  userId: string,
): Promise<JsonMap> {
  const { data, error } = await adminClient.rpc("get_account_access_for_user", {
    target_user_id: userId,
  });
  if (error) throw error;
  return asRecord(data) ?? {};
}

async function reserveUsage({
  adminClient,
  userId,
  requestId,
  feature,
}: {
  adminClient: UntypedSupabaseClient;
  userId: string;
  requestId: string;
  feature: "photo_id" | "upc_lookup";
}): Promise<{ allowed: boolean; reason: string | null }> {
  const { data, error } = await adminClient.rpc("reserve_feature_usage", {
    target_user_id: userId,
    target_feature: feature,
    target_request_id: requestId,
  });
  if (error) throw error;
  const result = asRecord(data) ?? {};
  return {
    allowed: asBoolean(result.allowed),
    reason: asString(result.reason),
  };
}

async function recordCacheHit(
  adminClient: UntypedSupabaseClient,
  userId: string,
  requestId: string,
  feature: "photo_id" | "upc_lookup",
) {
  const { error } = await adminClient.rpc("record_free_feature_event", {
    target_user_id: userId,
    target_feature: feature,
    target_request_id: requestId,
    details: { provider: "cache", outcome: "cache_hit", duration_ms: 0 },
  });
  if (error) console.error("Could not record cache hit", error);
}

function usageLimitResponse(reason: string | null): Response {
  const messages: Record<string, string> = {
    pro_required: "This feature is included with Ownzith Pro.",
    monthly_limit: "You have reached this month's usage limit.",
    daily_limit: "You have reached today's usage limit. Try again tomorrow.",
    rate_limit:
      "Too many requests at once. Please wait a minute and try again.",
  };
  return jsonResponse(
    {
      error: messages[reason ?? ""] ??
        "This request is not available right now.",
      code: reason,
    },
    reason === "rate_limit" ? 429 : 402,
  );
}

async function finalizeReservedUsage(
  reservation: UsageReservation,
  consume: boolean,
  details: JsonMap,
) {
  const { error } = await reservation.adminClient.rpc(
    "finalize_feature_usage",
    {
      target_user_id: reservation.userId,
      target_request_id: reservation.requestId,
      consume,
      details: {
        ...details,
        duration_ms: Date.now() - reservation.startedAt,
      },
    },
  );
  if (error) console.error("Could not finalize feature usage", error);
}

function collectOpenAiUsage(rawResult: unknown): {
  model: string | null;
  fallbackUsed: boolean;
  inputTokens: number;
  outputTokens: number;
} {
  const raw = asRecord(rawResult) ?? {};
  const primary = asRecord(raw.primary);
  const verification = asRecord(raw.verification);
  const primaryUsage = asRecord(primary?.usage);
  const verificationUsage = asRecord(verification?.usage);
  return {
    model: cleanString(raw.fallback_model) ?? cleanString(raw.primary_model),
    fallbackUsed: verification != null,
    inputTokens: (asNumber(primaryUsage?.input_tokens) ?? 0) +
      (asNumber(verificationUsage?.input_tokens) ?? 0),
    outputTokens: (asNumber(primaryUsage?.output_tokens) ?? 0) +
      (asNumber(verificationUsage?.output_tokens) ?? 0),
  };
}

async function fetchCache({
  adminClient,
  userId,
  lookupType,
  lookupKey,
}: {
  adminClient: UntypedSupabaseClient;
  userId: string;
  lookupType: LookupMode;
  lookupKey: string;
}): Promise<CacheRow | null> {
  const nowIso = new Date().toISOString();
  const { data, error } = await adminClient
    .from("identification_cache")
    .select("normalized_result, status, provider_stage, raw_result, expires_at")
    .eq("user_id", userId)
    .eq("lookup_type", lookupType)
    .eq("lookup_key", lookupKey)
    .gt("expires_at", nowIso)
    .maybeSingle();

  if (error || !data) {
    return null;
  }

  const cached = data as CacheRow;
  // Comic Vine was removed from the AI flow. Ignore its old cache entries so
  // a prior enrichment cannot continue to override the current AI result.
  return cached.provider_stage === "comicvine" ? null : cached;
}

async function fetchSharedBarcodeCache({
  adminClient,
  barcode,
}: {
  adminClient: UntypedSupabaseClient;
  barcode: string;
}): Promise<CacheRow | null> {
  const nowIso = new Date().toISOString();
  const { data, error } = await adminClient
    .from("barcode_catalog_cache")
    .select("normalized_result, status, provider_stage, raw_result, expires_at")
    .eq("barcode", barcode)
    .gt("expires_at", nowIso)
    .maybeSingle();

  if (error || !data) {
    return null;
  }

  const cached = data as CacheRow;
  return cached.provider_stage === "comicvine" ? null : cached;
}

function cacheHit(cached: CacheRow): JsonMap {
  return {
    ...(cached.normalized_result ?? {}),
    status: cached.status,
    provider_stage: "cache",
    source_badge: `Saved • ${
      asString((cached.normalized_result ?? {})["source_badge"]) ||
      "Catalog match"
    }`,
  };
}

async function saveCache({
  adminClient,
  userId,
  lookupType,
  lookupKey,
  ttlDays,
  match,
}: {
  adminClient: UntypedSupabaseClient;
  userId: string;
  lookupType: LookupMode;
  lookupKey: string;
  ttlDays: number;
  match: ProviderMatch;
}) {
  const expiresAt = new Date(Date.now() + ttlDays * 24 * 60 * 60 * 1000)
    .toISOString();

  const { error } = await adminClient.from("identification_cache").upsert(
    {
      user_id: userId,
      lookup_type: lookupType,
      lookup_key: lookupKey,
      status: match.status,
      provider_stage: match.providerStage,
      normalized_result: match.result,
      raw_result: match.rawResult,
      expires_at: expiresAt,
    },
    { onConflict: "user_id,lookup_type,lookup_key" },
  );

  if (error) {
    console.error("Could not save identification cache", error);
  }
}

async function saveSharedBarcodeMatch({
  adminClient,
  barcode,
  ttlDays,
  match,
}: {
  adminClient: UntypedSupabaseClient;
  barcode: string;
  ttlDays: number;
  match: ProviderMatch;
}) {
  const expiresAt = new Date(Date.now() + ttlDays * 24 * 60 * 60 * 1000)
    .toISOString();
  await saveSharedBarcodeCacheRow({
    adminClient,
    barcode,
    cached: {
      normalized_result: match.result,
      status: match.status,
      provider_stage: match.providerStage,
      raw_result: match.rawResult,
      expires_at: expiresAt,
    },
  });
}

async function saveSharedBarcodeCache({
  adminClient,
  barcode,
  cached,
}: {
  adminClient: UntypedSupabaseClient;
  barcode: string;
  cached: CacheRow;
}) {
  await saveSharedBarcodeCacheRow({
    adminClient,
    barcode,
    cached,
  });
}

async function markIdentificationCacheMetronRefresh({
  adminClient,
  userId,
  lookupType,
  lookupKey,
  cached,
}: {
  adminClient: UntypedSupabaseClient;
  userId: string;
  lookupType: LookupMode;
  lookupKey: string;
  cached: CacheRow;
}) {
  const { error } = await adminClient
    .from("identification_cache")
    .update({ raw_result: markMetronNotFoundRefresh(cached).raw_result })
    .eq("user_id", userId)
    .eq("lookup_type", lookupType)
    .eq("lookup_key", lookupKey);
  if (error) {
    console.error("Could not mark the legacy barcode cache refresh", error);
  }
}

async function saveSharedBarcodeCacheRow({
  adminClient,
  barcode,
  cached,
}: {
  adminClient: UntypedSupabaseClient;
  barcode: string;
  cached: CacheRow;
}) {
  const { error } = await adminClient.from("barcode_catalog_cache").upsert(
    {
      barcode,
      status: cached.status,
      provider_stage: cached.provider_stage,
      normalized_result: cached.normalized_result,
      raw_result: cached.raw_result,
      expires_at: cached.expires_at,
    },
    { onConflict: "barcode" },
  );

  if (error) {
    console.error("Could not save shared barcode cache", error);
  }
}

async function lookupUpcItemDb(
  barcode: string,
  { throwOnUnavailable = false }: { throwOnUnavailable?: boolean } = {},
): Promise<ProviderMatch | null> {
  const response = await fetch(`${upcItemDbEndpoint}?upc=${barcode}`, {
    headers: { Accept: "application/json" },
  });

  const payload = await safeJson(response);
  if (response.status === 404) {
    return null;
  }
  if (response.status === 429 || response.status >= 500) {
    if (throwOnUnavailable) {
      throw new Error("The barcode catalog is temporarily unavailable.");
    }
    return null;
  }
  if (response.status >= 400) {
    return null;
  }

  const items = asArray(payload?.items);
  if (!items.length) {
    return null;
  }

  const item = asRecord(items[0]);
  if (!item) {
    return null;
  }

  const title = cleanString(item["title"]);
  if (!title) {
    return null;
  }

  const rawCategory = cleanString(item["category"]);
  const brand = cleanString(item["brand"]);
  const imageUrl = preferredImageUrl(item["images"]);
  const result = normalizeResult({
    status: "matched",
    providerStage: "upcitemdb",
    title,
    suggestedCategory: suggestCollectorCategory(rawCategory, title),
    imageUrl,
    description: cleanString(item["description"]),
    brand,
    franchise: inferFranchise(title, brand),
    series: cleanString(item["model"]) ?? cleanString(item["mpn"]),
    characterOrSubject: inferCharacterOrSubject(title),
    releaseYear: inferYear(cleanString(item["description"])),
    barcode,
    confidence: 0.88,
    sourceBadge: "Catalog match",
    comicContext: rawCategory && rawCategory.toLowerCase().includes("comic")
      ? { issue_number: null, volume_name: null, publisher: brand }
      : null,
  });

  return {
    status: "matched",
    providerStage: "upcitemdb",
    result,
    rawResult: payload,
  };
}

async function lookupBarcodeCatalog(
  barcode: string,
): Promise<ProviderMatch | null> {
  for (const lookupCode of barcodeLookupCodes(barcode)) {
    // Metron only returns comic issues, so a miss must quietly continue to the
    // broad catalog providers. That keeps ordinary barcode scans unchanged.
    const match = await lookupMetronIssueByUpc(lookupCode) ??
      await lookupUpcItemDb(lookupCode, {
        throwOnUnavailable: true,
      }) ?? await lookupGoUpc(lookupCode, {
        throwOnUnavailable: true,
      });
    if (!match) {
      continue;
    }

    return lookupCode == barcode
      ? match
      : requireSupplementConfirmation(match, barcode);
  }

  return null;
}

async function lookupMetronIssueByUpc(
  barcode: string,
): Promise<ProviderMatch | null> {
  const apiToken = Deno.env.get("METRON_API_TOKEN")?.trim();
  if (!apiToken) {
    return null;
  }

  for (const exactCode of metronExactBarcodeCandidates(barcode)) {
    const payload = await fetchMetronIssuePayload({
      apiToken,
      filterName: "upc",
      filterValue: exactCode,
    });
    if (payload) {
      const issue = pickMetronIssue(payload, exactCode);
      if (issue) {
        const variantMatch = await resolveMetronVariantMatch({
          apiToken,
          issue,
          searchPayload: payload,
          barcode,
        });
        if (variantMatch) {
          return variantMatch;
        }
        return metronIssueMatch({
          issue,
          payload,
          barcode,
          isPartial: false,
        });
      }
    }
  }

  // Mobile cameras can decode only the main UPC-A/EAN-13 portion of a comic
  // barcode and miss its two- or five-digit supplement. Metron provides this
  // exact prefix filter for that situation. A prefix result is never treated
  // as an exact cover match because several variants can share the base UPC.
  const prefix = metronUpcPrefix(barcode);
  if (!prefix) {
    return null;
  }
  const payload = await fetchMetronIssuePayload({
    apiToken,
    filterName: "upc_starts_with",
    filterValue: prefix,
  });
  if (!payload) {
    return null;
  }

  const issues = metronIssueRecords(payload);
  if (!issues.length) {
    return null;
  }

  // Variant UPCs are deliberately not indexed by Metron's issue list
  // filters. A full comic barcode therefore needs to check the detail
  // records of the relevant prefix candidates, not just the first list row.
  if (metronFullVariantBarcode(barcode)) {
    for (const issue of issues.slice(0, metronVariantCandidateLimit)) {
      const variantMatch = await resolveMetronVariantMatch({
        apiToken,
        issue,
        searchPayload: payload,
        barcode,
      });
      if (variantMatch) {
        return variantMatch;
      }
    }
  }

  return metronIssueMatch({
    issue: issues[0],
    payload,
    barcode,
    isPartial: true,
  });
}

async function fetchMetronIssuePayload({
  apiToken,
  filterName,
  filterValue,
}: {
  apiToken: string;
  filterName: "upc" | "upc_starts_with";
  filterValue: string;
}): Promise<JsonMap | null> {
  const url = new URL(metronIssueEndpoint);
  url.searchParams.set(filterName, filterValue);
  return await fetchMetronPayload(url, apiToken);
}

async function fetchMetronIssueDetail({
  apiToken,
  issue,
}: {
  apiToken: string;
  issue: JsonMap;
}): Promise<JsonMap | null> {
  const issueId = metronIssueId(issue);
  if (!issueId) {
    return null;
  }
  return await fetchMetronPayload(
    new URL(`${metronIssueEndpoint}${issueId}/`),
    apiToken,
  );
}

async function fetchMetronPayload(
  url: URL,
  apiToken: string,
): Promise<JsonMap | null> {
  let response: Response;
  try {
    response = await fetch(url, {
      headers: {
        Accept: "application/json",
        Authorization: `Bearer ${apiToken}`,
      },
    });
  } catch {
    // Metron is optional. A network problem must not prevent the established
    // broad catalog providers from handling the scan.
    return null;
  }

  if (response.status >= 400) {
    return null;
  }
  return await safeJson(response);
}

async function resolveMetronVariantMatch({
  apiToken,
  issue,
  searchPayload,
  barcode,
}: {
  apiToken: string;
  issue: JsonMap;
  searchPayload: JsonMap;
  barcode: string;
}): Promise<ProviderMatch | null> {
  const variantBarcode = metronFullVariantBarcode(barcode);
  if (!variantBarcode) {
    return null;
  }

  // Variants are returned by Metron's issue-detail endpoint, but are not
  // indexed by the issue UPC filters. Fetch one detail record only after a
  // comic issue candidate is found, then compare the full scanned barcode.
  const detail = await fetchMetronIssueDetail({ apiToken, issue });
  if (!detail) {
    return null;
  }
  const variant = pickMetronVariant(detail, variantBarcode);
  if (!variant) {
    return null;
  }

  return metronIssueMatch({
    issue: detail,
    payload: { search: searchPayload, detail },
    barcode,
    isPartial: false,
    variant,
  });
}

function metronIssueId(issue: JsonMap): string | null {
  const id = issue["id"];
  const value = typeof id === "number" ? String(id) : cleanString(id);
  return value && /^[1-9]\d*$/.test(value) ? value : null;
}

function metronFullVariantBarcode(barcode: string): string | null {
  const canonical = metronExactBarcodeCandidates(barcode)[0] ?? barcode;
  return canonical.length === 17 ? canonical : null;
}

// Direct-market comics commonly encode the issue, cover/variant, and printing
// in the five digits after the base UPC. This is publisher-defined GS1 data,
// so it is used only as a safeguard: a numeric disagreement prevents an
// automatic exact match, but an unrecognised format remains usable.
function decodeComicBarcodeSupplement(
  barcode: string,
): ComicBarcodeSupplement | null {
  const canonical = metronFullVariantBarcode(barcode);
  if (!canonical) {
    return null;
  }

  const supplement = canonical.slice(-5);
  if (!/^\d{5}$/.test(supplement)) {
    return null;
  }

  return {
    barcode: canonical,
    issueNumber: Number(supplement.slice(0, 3)),
    variantNumber: Number(supplement.slice(3, 4)),
    printingNumber: Number(supplement.slice(4, 5)),
  };
}

function metronSupplementConflict({
  barcode,
  issueNumber,
}: {
  barcode: string;
  issueNumber: string | null;
}): JsonMap | null {
  const decoded = decodeComicBarcodeSupplement(barcode);
  if (!decoded || !issueNumber || !/^\d+$/.test(issueNumber)) {
    return null;
  }

  const metronIssueNumber = Number(issueNumber);
  if (
    !Number.isSafeInteger(metronIssueNumber) ||
    metronIssueNumber === decoded.issueNumber
  ) {
    return null;
  }

  return {
    reason: "comic_barcode_issue_mismatch",
    barcode: decoded.barcode,
    expected_issue_number: String(decoded.issueNumber),
    expected_variant_number: String(decoded.variantNumber),
    expected_printing_number: String(decoded.printingNumber),
    metron_issue_number: issueNumber,
  };
}

function metronExactBarcodeCandidates(barcode: string): string[] {
  if (barcode.length === 18 && barcode.startsWith("0")) {
    // Vision can represent a UPC-A + supplement as an EAN-13 composite.
    // Metron stores the UPC-A representation, without the leading EAN zero.
    return [barcode.slice(1)];
  }
  return [barcode];
}

function metronUpcPrefix(barcode: string): string | null {
  if (barcode.length === 12) {
    return barcode;
  }
  if (barcode.length === 13 && barcode.startsWith("0")) {
    return barcode.slice(1);
  }
  if (barcode.length === 17) {
    return barcode.slice(0, 12);
  }
  if (barcode.length === 18 && barcode.startsWith("0")) {
    return barcode.slice(1, 13);
  }
  return null;
}

function metronIssueRecords(payload: JsonMap): JsonMap[] {
  return asArray(payload["results"] ?? payload["issues"] ?? payload)
    .map((issue) => asRecord(issue))
    .filter((issue): issue is JsonMap => Boolean(issue));
}

function metronIssueMatch({
  issue,
  payload,
  barcode,
  isPartial,
  variant = null,
}: {
  issue: JsonMap;
  payload: JsonMap;
  barcode: string;
  isPartial: boolean;
  variant?: JsonMap | null;
}): ProviderMatch | null {
  const series = asRecord(issue["series"]);
  const publisher = asRecord(issue["publisher"]);
  const seriesName = cleanString(series?.["name"]);
  const publisherName = cleanString(publisher?.["name"]);
  const issueNumber = cleanString(issue["number"]);
  const issueName = cleanString(issue["issue_name"]);
  const collectionTitle = cleanString(issue["collection_title"]);
  const supplementConflict = isPartial
    ? null
    : metronSupplementConflict({ barcode, issueNumber });
  const needsConfirmation = isPartial || supplementConflict !== null;
  const issueTitle = metronIssueTitle({
    seriesName,
    issueNumber,
    issueName,
    collectionTitle,
  });
  const variantName = cleanString(variant?.["name"]);
  const title = needsConfirmation
    ? seriesName ?? collectionTitle ?? issueTitle
    : metronVariantTitle(issueTitle, variantName);
  if (!title) {
    return null;
  }

  const result = normalizeResult({
    status: needsConfirmation ? "partial" : "matched",
    providerStage: "metron",
    title,
    suggestedCategory: "Comics",
    imageUrl: needsConfirmation
      ? null
      : metronImageUrl(variant) ?? metronImageUrl(issue),
    description: needsConfirmation ? null : metronDescription(issue),
    brand: publisherName,
    franchise: inferFranchise(title, publisherName),
    series: seriesName,
    characterOrSubject: needsConfirmation
      ? inferCharacterOrSubject(title)
      : metronCharacterNames(issue) ?? inferCharacterOrSubject(title),
    releaseYear: needsConfirmation ? null : inferYear(
      cleanString(issue["store_date"]) ?? cleanString(issue["cover_date"]),
    ),
    barcode,
    confidence: needsConfirmation ? 0.65 : 0.98,
    sourceBadge: supplementConflict
      ? "Metron catalog conflict • cover needs confirmation"
      : isPartial
      ? "Metron comic series match • cover needs confirmation"
      : variant
      ? "Metron comic variant match"
      : "Metron comic match",
    comicContext: {
      issue_number: needsConfirmation ? null : issueNumber,
      volume_name: seriesName,
      publisher: publisherName,
    },
  });

  return {
    status: needsConfirmation ? "partial" : "matched",
    providerStage: "metron",
    result,
    rawResult: supplementConflict
      ? { ...payload, metron_supplement_conflict: supplementConflict }
      : payload,
  };
}

function barcodeCacheTtlDays(match: ProviderMatch): number {
  const rawResult = asRecord(match.rawResult);
  if (
    match.providerStage === "metron" &&
    asRecord(rawResult?.["metron_supplement_conflict"])
  ) {
    return metronSupplementConflictCacheTtlDays;
  }
  return identificationCacheTtlDays("barcode", match.status);
}

async function refreshCachedComicWithMetron(
  cached: CacheRow,
  barcode: string,
): Promise<ProviderMatch | null> {
  if (shouldRefreshCachedNotFoundWithMetron(cached)) {
    return await lookupMetronIssueByUpc(barcode);
  }
  if (!isComicBarcodeCache(cached)) {
    return null;
  }
  return await lookupMetronIssueByUpc(barcode);
}

function shouldRefreshCachedNotFoundWithMetron(cached: CacheRow): boolean {
  if (cached.status !== "not_found" || cached.provider_stage === "metron") {
    return false;
  }
  const rawResult = asRecord(cached.raw_result);
  return asString(rawResult?.["metron_cache_refresh"]) !==
    metronNotFoundCacheRefreshVersion;
}

function markMetronNotFoundRefresh(cached: CacheRow): CacheRow {
  const rawResult = asRecord(cached.raw_result);
  return {
    ...cached,
    raw_result: {
      ...(rawResult ?? { upstream: cached.raw_result }),
      metron_cache_refresh: metronNotFoundCacheRefreshVersion,
    },
  };
}

function isComicBarcodeCache(cached: CacheRow): boolean {
  if (cached.provider_stage === "metron" || cached.status !== "matched") {
    return false;
  }

  const result = cached.normalized_result ?? {};
  if (normalizeSuggestedCategory(result["suggested_category"]) === "Comics") {
    return true;
  }

  const title = asString(result["title"]) ?? "";
  const brand = asString(result["brand"]) ?? "";
  const description = asString(result["description"]) ?? "";
  const text = `${title} ${brand} ${description}`;
  return /\b(comic|comics|graphic novel|idw|marvel|dc)\b/i.test(text) ||
    (/\bcover\b/i.test(text) && /#\s*\d+/i.test(text));
}

function rebuildCachedMetronPartial(
  cached: CacheRow,
  barcode: string,
): ProviderMatch | null {
  if (cached.provider_stage !== "metron" || cached.status !== "partial") {
    return null;
  }
  const comicContext = asRecord(cached.normalized_result?.["comic_context"]);
  const alreadySeriesOnly = !cleanString(comicContext?.["issue_number"]) &&
    !cleanString(cached.normalized_result?.["image_url"]);
  if (alreadySeriesOnly) {
    return null;
  }

  const payload = asRecord(cached.raw_result);
  if (!payload) {
    return null;
  }
  const prefix = metronUpcPrefix(barcode) ?? barcode;
  const issue = pickMetronIssue(payload, prefix);
  return issue
    ? metronIssueMatch({ issue, payload, barcode, isPartial: true })
    : null;
}

function pickMetronIssue(payload: JsonMap, barcode: string): JsonMap | null {
  const records = metronIssueRecords(payload);
  if (!records.length) {
    return null;
  }

  return records.find((issue) =>
    normalizeBarcode(cleanString(issue["upc"])) === barcode
  ) ?? records[0];
}

function pickMetronVariant(
  issue: JsonMap,
  barcode: string,
): JsonMap | null {
  const variants = asArray(issue["variants"])
    .map((variant) => asRecord(variant))
    .filter((variant): variant is JsonMap => Boolean(variant));
  return variants.find((variant) =>
    normalizeBarcode(cleanString(variant["upc"])) === barcode
  ) ?? null;
}

function metronIssueTitle({
  seriesName,
  issueNumber,
  issueName,
  collectionTitle,
}: {
  seriesName: string | null;
  issueNumber: string | null;
  issueName: string | null;
  collectionTitle: string | null;
}): string | null {
  const numberedSeries = seriesName
    ? `${seriesName}${issueNumber ? ` #${issueNumber}` : ""}`
    : null;
  if (!numberedSeries) {
    return collectionTitle ?? issueName;
  }
  if (
    !issueName ||
    normalizeText(numberedSeries).includes(normalizeText(issueName))
  ) {
    return numberedSeries;
  }
  return `${numberedSeries}: ${issueName}`;
}

function metronVariantTitle(
  issueTitle: string | null,
  variantName: string | null,
): string | null {
  if (!issueTitle) {
    return variantName;
  }
  if (
    !variantName ||
    normalizeText(issueTitle).includes(normalizeText(variantName))
  ) {
    return issueTitle;
  }
  return `${issueTitle} — ${variantName}`;
}

function metronImageUrl(issue: JsonMap | null): string | null {
  if (!issue) {
    return null;
  }
  const image = issue["image"] ?? issue["image_url"];
  return cleanString(image) ?? cleanString(asRecord(image)?.["url"]);
}

function metronDescription(issue: JsonMap): string | null {
  const description = cleanString(issue["desc"]) ??
    cleanString(issue["description"]);
  return description?.replaceAll(/<[^>]*>/g, " ").replaceAll(/\s+/g, " ")
    .trim() || null;
}

function metronCharacterNames(issue: JsonMap): string | null {
  const names = asArray(issue["characters"])
    .map((character) => cleanString(asRecord(character)?.["name"]))
    .filter((name): name is string => Boolean(name));
  return names.length ? names.join(", ") : null;
}

function barcodeLookupCodes(barcode: string): string[] {
  const baseCode = barcode.length == 17
    ? barcode.slice(0, 12)
    : barcode.length == 18
    ? barcode.slice(0, 13)
    : null;
  return baseCode ? [barcode, baseCode] : [barcode];
}

function requireSupplementConfirmation(
  match: ProviderMatch,
  scannedBarcode: string,
): ProviderMatch {
  return {
    ...match,
    status: "partial",
    result: {
      ...match.result,
      status: "partial",
      barcode: scannedBarcode,
      confidence: Math.min(match.result.confidence ?? 0.65, 0.65),
      source_badge: "Catalog series match • cover needs confirmation",
    },
  };
}

async function searchUpcItemDbByText(
  baseResult: NormalizedIdentificationResult,
): Promise<ProviderMatch | null> {
  const searchQuery = buildUpcItemDbSearchQuery(baseResult);
  if (!searchQuery) {
    return null;
  }

  const url = new URL(upcItemDbSearchEndpoint);
  url.searchParams.set("s", searchQuery);

  const response = await fetch(url, {
    headers: { Accept: "application/json" },
  });
  const payload = await safeJson(response);
  if (
    response.status === 404 || response.status === 429 || response.status >= 500
  ) {
    return null;
  }
  if (response.status >= 400) {
    return null;
  }

  const items = asArray(payload?.items);
  if (!items.length) {
    return null;
  }

  const bestItem = pickBestUpcItemDbSearchResult(items, baseResult);
  if (!bestItem) {
    return null;
  }

  const title = cleanString(bestItem["title"]);
  if (!title) {
    return null;
  }

  const rawCategory = cleanString(bestItem["category"]);
  const bestBrand = cleanString(bestItem["brand"]);
  const result = normalizeResult({
    status: "matched",
    providerStage: "upcitemdb",
    title,
    suggestedCategory: suggestCollectorCategory(rawCategory, title),
    imageUrl: preferredImageUrl(bestItem["images"]),
    description: cleanString(bestItem["description"]),
    brand: bestBrand,
    franchise: inferFranchise(title, bestBrand),
    series: cleanString(bestItem["model"]) ?? cleanString(bestItem["mpn"]),
    characterOrSubject: inferCharacterOrSubject(title),
    releaseYear: inferYear(cleanString(bestItem["description"])),
    barcode: normalizeBarcode(cleanString(bestItem["upc"])) ??
      normalizeBarcode(cleanString(bestItem["ean"])) ??
      baseResult.barcode,
    confidence: 0.76,
    sourceBadge: "Matched via UPCItemDB search",
    comicContext: rawCategory && rawCategory.toLowerCase().includes("comic")
      ? { issue_number: null, volume_name: null, publisher: bestBrand }
      : null,
  });

  return {
    status: "matched",
    providerStage: "upcitemdb",
    result,
    rawResult: payload,
  };
}

async function lookupGoUpc(
  barcode: string,
  { throwOnUnavailable = false }: { throwOnUnavailable?: boolean } = {},
): Promise<ProviderMatch | null> {
  const apiKey = Deno.env.get("GOUPC_API_KEY");
  if (!apiKey) {
    return null;
  }

  const response = await fetch(`${goUpcEndpoint}/${barcode}`, {
    headers: {
      Accept: "application/json",
      Authorization: `Bearer ${apiKey}`,
    },
  });
  if (response.status === 404) {
    return null;
  }
  if (response.status === 429 || response.status >= 500) {
    if (throwOnUnavailable) {
      throw new Error("The barcode catalog is temporarily unavailable.");
    }
    return null;
  }
  if (response.status >= 400) {
    return null;
  }

  const payload = await safeJson(response);
  const product = asRecord(payload?.product);
  if (!product) {
    return null;
  }

  const title = cleanString(product["name"]);
  if (!title) {
    return null;
  }

  const category = cleanString(product["category"]) ??
    cleanString(
      asArray(product["categoryPath"]).map((entry) => `${entry}`).join(" "),
    );

  const result = normalizeResult({
    status: "matched",
    providerStage: "goupc",
    title,
    suggestedCategory: suggestCollectorCategory(category, title),
    imageUrl: cleanString(product["imageUrl"]),
    description: cleanString(product["description"]),
    brand: cleanString(product["brand"]),
    franchise: inferFranchise(title, cleanString(product["brand"])),
    series: cleanString(product["model"]),
    characterOrSubject: inferCharacterOrSubject(title),
    releaseYear: inferYear(cleanString(product["description"])),
    barcode,
    confidence: asBoolean(payload?.inferred) ? 0.7 : 0.84,
    sourceBadge: "Matched via GO-UPC",
    comicContext: category && category.toLowerCase().includes("comic")
      ? {
        issue_number: null,
        volume_name: null,
        publisher: cleanString(product["brand"]),
      }
      : null,
  });

  return {
    status: "matched",
    providerStage: "goupc",
    result,
    rawResult: payload,
  };
}

async function identifyPhotoWithOpenAi({
  imageBase64,
  mimeType,
  barcode,
  primaryModel,
  fallbackModel,
}: {
  imageBase64: string;
  mimeType: string;
  barcode: string | null;
  primaryModel: string;
  fallbackModel: string;
}): Promise<OpenAiPhotoResult> {
  const apiKey = Deno.env.get("OPEN_AI_KEY") ?? mustGetEnv("OPENAI_API_KEY");
  const primary = await requestOpenAiPhotoAssessment({
    apiKey,
    model: primaryModel,
    reasoningEffort: "low",
    imageBase64,
    mimeType,
    barcode,
    verificationContext: null,
  });
  const escalationReasons = photoIdentificationEscalationReasons({
    title: primary.result.title,
    confidence: primary.result.confidence,
    barcode: primary.detectedBarcode,
    visibleText: primary.visibleText,
    identifyingMarkers: primary.identifyingMarkers,
    alternativeCandidates: primary.alternativeCandidates,
    needsStrongerModel: primary.needsStrongerModel,
  });
  const shouldUseFallback = escalationReasons.length > 0 &&
    fallbackModel !== primaryModel;
  const verification = shouldUseFallback
    ? await requestOpenAiPhotoAssessment({
      apiKey,
      model: fallbackModel,
      reasoningEffort: "medium",
      imageBase64,
      mimeType,
      barcode: barcode ?? primary.detectedBarcode,
      verificationContext: primary.parsed,
    })
    : null;
  const selected = verification ?? primary;
  const selectedConfidence = selected.result.confidence ?? 0;
  const isConfidentMatch = selected.result.title.trim().length > 0 &&
    selectedConfidence >= (verification ? 0.72 : 0.82) &&
    !selected.needsStrongerModel;

  return {
    result: {
      ...selected.result,
      status: isConfidentMatch ? "matched" : "partial",
      source_badge: verification ? "AI verified" : "AI identification",
    },
    rawResult: {
      pipeline_version: photoIdentificationPipelineVersion,
      primary_model: primaryModel,
      fallback_model: verification ? fallbackModel : null,
      escalation_reasons: escalationReasons,
      primary: primary.payload,
      verification: verification?.payload ?? null,
    },
    detectedBarcode: barcode ?? selected.detectedBarcode,
    isConfidentMatch,
  };
}

async function requestOpenAiPhotoAssessment({
  apiKey,
  model,
  reasoningEffort,
  imageBase64,
  mimeType,
  barcode,
  verificationContext,
}: {
  apiKey: string;
  model: string;
  reasoningEffort: "low" | "medium";
  imageBase64: string;
  mimeType: string;
  barcode: string | null;
  verificationContext: JsonMap | null;
}): Promise<OpenAiPhotoAssessment> {
  const dataUrl = `data:${mimeType};base64,${imageBase64}`;
  const isVerification = verificationContext != null;
  const developerPrompt = isVerification
    ? "You verify exact collectible-product identities from photos. Re-examine the photo independently. Treat the earlier assessment only as a candidate, correct it when the visible evidence disagrees, and return uncertainty instead of inventing an edition or product number."
    : "You identify exact collectible products from photos. Ground every identification in visible evidence such as packaging text, logos, product numbers, edition markings, colors, accessories, and character design. Do not infer an exact release or edition from the character alone. Return uncertainty instead of inventing details.";
  const previousAssessment = verificationContext
    ? ` Earlier assessment to verify: ${JSON.stringify(verificationContext)}.`
    : "";
  const userPrompt =
    `Identify the exact collectible shown. Record only text and markings that are genuinely visible. Set needs_stronger_model to true when the exact product or edition is not supported by the photo, confidence is below 0.82, or more than one reasonable candidate remains. Put competing identities in alternative_candidates. Leave title empty when even the product identity is unsafe to claim. Barcode hint: ${
      barcode ?? "none"
    }.${previousAssessment}`;

  const initialOutputTokenBudget = reasoningEffort === "medium" ? 10000 : 6000;
  let payload: JsonMap = {};
  let parsed: JsonMap | null = null;

  for (let attempt = 0; attempt < 2; attempt++) {
    const maxOutputTokens = initialOutputTokenBudget * (attempt + 1);
    const response = await fetch(openAiResponsesEndpoint, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${apiKey}`,
      },
      body: JSON.stringify({
        model,
        store: false,
        reasoning: { effort: reasoningEffort },
        input: [
          {
            role: "developer",
            content: [
              {
                type: "input_text",
                text: developerPrompt,
              },
            ],
          },
          {
            role: "user",
            content: [
              {
                type: "input_text",
                text: userPrompt,
              },
              {
                type: "input_image",
                image_url: dataUrl,
                detail: "original",
              },
            ],
          },
        ],
        text: {
          format: {
            type: "json_schema",
            name: "collectible_identification",
            strict: true,
            schema: collectibleIdentificationSchema,
          },
        },
        max_output_tokens: maxOutputTokens,
      }),
    });

    payload = await safeJson(response);
    if (response.status >= 400) {
      const apiError = asRecord(payload?.error);
      const apiMessage = cleanString(apiError?.message) ??
        cleanString(payload?.message);
      throw new Error(
        apiMessage ??
          `OpenAI photo identification failed with status ${response.status}.`,
      );
    }

    const parseResult = parseOpenAiStructuredOutput(
      payload,
      extractResponsesOutputText(payload),
    );
    if (parseResult.ok) {
      parsed = parseResult.value;
      break;
    }
    if (
      attempt === 0 && shouldRetryOpenAiStructuredOutput(parseResult.reason)
    ) {
      continue;
    }
    throw new Error(
      "The AI response was incomplete. Please try the photo again.",
    );
  }

  if (!parsed) {
    throw new Error(
      "The AI response was incomplete. Please try the photo again.",
    );
  }
  const comicContext = asRecord(parsed.comic_context);
  const resolvedBarcode = barcode ??
    normalizeBarcode(asString(parsed.barcode_candidate));
  const visibleText = stringArray(parsed.visible_text);
  const identifyingMarkers = stringArray(parsed.identifying_markers);
  const alternativeCandidates = stringArray(parsed.alternative_candidates);

  return {
    result: normalizeResult({
      status: "matched",
      providerStage: "openai",
      title: cleanString(parsed.title) ?? "",
      suggestedCategory: normalizeSuggestedCategory(parsed.suggested_category),
      imageUrl: null,
      description: cleanString(parsed.description),
      brand: cleanString(parsed.brand),
      franchise: cleanString(parsed.franchise),
      series: cleanString(parsed.series),
      characterOrSubject: cleanString(parsed.character_or_subject),
      releaseYear: asInteger(parsed.release_year),
      barcode: resolvedBarcode,
      confidence: asNumber(parsed.confidence),
      sourceBadge: isVerification ? "AI verified" : "AI identification",
      comicContext: comicContext
        ? {
          issue_number: cleanString(comicContext.issue_number),
          volume_name: cleanString(comicContext.volume_name),
          publisher: cleanString(comicContext.publisher),
        }
        : null,
    }),
    payload,
    parsed,
    detectedBarcode: resolvedBarcode,
    visibleText,
    identifyingMarkers,
    alternativeCandidates,
    needsStrongerModel: asBoolean(parsed.needs_stronger_model),
  };
}

async function enrichPhotoWithBarcodeCatalog({
  barcode,
  baseResult,
  openAiRawResult,
}: {
  barcode: string | null;
  baseResult: NormalizedIdentificationResult;
  openAiRawResult: unknown;
}): Promise<ProviderMatch | null> {
  if (!barcode) {
    return null;
  }

  const providerMatch = await lookupMetronIssueByUpc(barcode) ??
    await lookupUpcItemDb(barcode) ??
    await lookupGoUpc(barcode);
  if (!providerMatch) {
    return null;
  }

  const providerResult = providerMatch.result;
  const mergedResult = normalizeResult({
    status: baseResult.title.trim().length === 0 &&
        providerResult.title.trim().length === 0
      ? "partial"
      : "enriched",
    providerStage: providerMatch.providerStage,
    title: choosePreferredTitle(baseResult.title, providerResult.title),
    suggestedCategory:
      normalizeSuggestedCategory(baseResult.suggested_category) ??
        normalizeSuggestedCategory(providerResult.suggested_category),
    imageUrl: providerResult.image_url ?? baseResult.image_url,
    description: providerResult.description ?? baseResult.description,
    brand: providerResult.brand ?? baseResult.brand,
    franchise: baseResult.franchise ?? providerResult.franchise,
    series: baseResult.series ?? providerResult.series,
    characterOrSubject: baseResult.character_or_subject ??
      providerResult.character_or_subject,
    releaseYear: baseResult.release_year ?? providerResult.release_year,
    barcode: barcode,
    confidence: Math.max(
      baseResult.confidence ?? 0.6,
      providerResult.confidence ?? 0,
    ),
    sourceBadge: providerMatch.providerStage === "metron"
      ? "AI + Metron comic match"
      : providerMatch.providerStage === "goupc"
      ? "AI + GO-UPC image"
      : "AI + Catalog image",
    comicContext: baseResult.comic_context ?? providerResult.comic_context,
  });

  return {
    status: mergedResult.title.trim().length === 0 ? "partial" : "enriched",
    providerStage: providerMatch.providerStage,
    result: mergedResult,
    rawResult: {
      openai: openAiRawResult,
      [providerMatch.providerStage]: providerMatch.rawResult,
    },
  };
}

async function enrichPhotoWithUpcItemDbSearch({
  baseResult,
  openAiRawResult,
}: {
  baseResult: NormalizedIdentificationResult;
  openAiRawResult: unknown;
}): Promise<ProviderMatch | null> {
  if (!shouldTryUpcItemDbTextSearch(baseResult)) {
    return null;
  }

  const providerMatch = await searchUpcItemDbByText(baseResult);
  if (!providerMatch) {
    return null;
  }

  const providerResult = providerMatch.result;
  const mergedResult = normalizeResult({
    status: baseResult.title.trim().length === 0 &&
        providerResult.title.trim().length === 0
      ? "partial"
      : "enriched",
    providerStage: "upcitemdb",
    title: choosePreferredTitle(baseResult.title, providerResult.title),
    suggestedCategory:
      normalizeSuggestedCategory(baseResult.suggested_category) ??
        normalizeSuggestedCategory(providerResult.suggested_category),
    imageUrl: providerResult.image_url ?? baseResult.image_url,
    description: providerResult.description ?? baseResult.description,
    brand: baseResult.brand ?? providerResult.brand,
    franchise: baseResult.franchise ?? providerResult.franchise,
    series: baseResult.series ?? providerResult.series,
    characterOrSubject: baseResult.character_or_subject ??
      providerResult.character_or_subject,
    releaseYear: baseResult.release_year ?? providerResult.release_year,
    barcode: providerResult.barcode ?? baseResult.barcode,
    confidence: Math.max(
      baseResult.confidence ?? 0.55,
      providerResult.confidence ?? 0,
    ),
    sourceBadge: "AI + UPCItemDB",
    comicContext: baseResult.comic_context ?? providerResult.comic_context,
  });

  return {
    status: mergedResult.title.trim().length === 0 ? "partial" : "enriched",
    providerStage: "upcitemdb",
    result: mergedResult,
    rawResult: {
      openai: openAiRawResult,
      upcitemdb_search: providerMatch.rawResult,
    },
  };
}

function normalizeResult({
  status,
  providerStage,
  title,
  suggestedCategory,
  imageUrl,
  description,
  brand,
  franchise,
  series,
  characterOrSubject,
  releaseYear,
  barcode,
  confidence,
  sourceBadge,
  comicContext,
}: {
  status: LookupStatus;
  providerStage: ProviderStage;
  title: string;
  suggestedCategory: string | null;
  imageUrl: string | null;
  description: string | null;
  brand: string | null;
  franchise: string | null;
  series: string | null;
  characterOrSubject: string | null;
  releaseYear: number | null;
  barcode: string | null;
  confidence: number | null;
  sourceBadge: string;
  comicContext: ComicContext | null;
}): NormalizedIdentificationResult {
  return {
    status,
    provider_stage: providerStage,
    title: title.trim(),
    suggested_category: cleanString(suggestedCategory),
    image_url: cleanString(imageUrl),
    description: cleanString(description),
    brand: cleanString(brand),
    franchise: cleanString(franchise),
    series: cleanString(series),
    character_or_subject: cleanString(characterOrSubject),
    release_year: releaseYear ?? null,
    barcode: cleanString(barcode),
    confidence: confidence == null
      ? null
      : Math.min(Math.max(confidence, 0), 1),
    source_badge: cleanString(sourceBadge) ?? "Catalog match",
    comic_context: comicContext &&
        [
          comicContext.issue_number,
          comicContext.volume_name,
          comicContext.publisher,
        ].some(Boolean)
      ? {
        issue_number: cleanString(comicContext.issue_number),
        volume_name: cleanString(comicContext.volume_name),
        publisher: cleanString(comicContext.publisher),
      }
      : null,
  };
}

function buildNotFoundResult({
  providerStage,
  barcode,
  sourceBadge,
}: {
  providerStage: ProviderStage;
  barcode: string | null;
  sourceBadge: string;
}): NormalizedIdentificationResult {
  return normalizeResult({
    status: "not_found",
    providerStage,
    title: "",
    suggestedCategory: null,
    imageUrl: null,
    description: null,
    brand: null,
    franchise: null,
    series: null,
    characterOrSubject: null,
    releaseYear: null,
    barcode,
    confidence: 0,
    sourceBadge,
    comicContext: null,
  });
}

function preferredImageUrl(rawImages: unknown): string | null {
  const images = asArray(rawImages)
    .map((image) => cleanString(image))
    .filter((image): image is string => Boolean(image));
  if (!images.length) {
    return null;
  }

  images.sort((left, right) => scoreImageUrl(right) - scoreImageUrl(left));
  return images[0];
}

function scoreImageUrl(url: string): number {
  let score = 0;
  if (url.startsWith("https://")) {
    score += 20;
  } else if (url.startsWith("http://")) {
    score += 5;
  }

  const hostname = (() => {
    try {
      return new URL(url).hostname.toLowerCase();
    } catch {
      return "";
    }
  })();

  if (!hostname) {
    return score;
  }

  if (hostname.includes("walmartimages.com")) score += 12;
  if (hostname.includes("bbystatic.com")) score += 11;
  if (hostname.includes("tfaw.com")) score += 9;
  if (hostname.includes("fun.com")) score += 8;
  if (hostname.includes("booksamillion.com")) score -= 20;
  if (hostname.includes("entertainmentearth.com")) score -= 20;

  return score;
}

function choosePreferredTitle(
  primary: string,
  fallback: string | null,
): string {
  const normalizedPrimary = cleanString(primary) ?? "";
  const normalizedFallback = cleanString(fallback);
  if (!normalizedPrimary) {
    return normalizedFallback ?? "";
  }
  if (!normalizedFallback) {
    return normalizedPrimary;
  }
  const primaryText = normalizeText(normalizedPrimary);
  const fallbackText = normalizeText(normalizedFallback);
  if (primaryText === fallbackText) {
    return normalizedFallback.length > normalizedPrimary.length
      ? normalizedFallback
      : normalizedPrimary;
  }
  if (fallbackText.includes(primaryText)) {
    return normalizedFallback;
  }
  return normalizedPrimary;
}

function shouldTryUpcItemDbTextSearch(
  baseResult: NormalizedIdentificationResult,
): boolean {
  if (baseResult.barcode) {
    return false;
  }

  if (normalizeSuggestedCategory(baseResult.suggested_category) === "Comics") {
    return false;
  }

  const title = cleanString(baseResult.title);
  if (!title || title.length < 6) {
    return false;
  }

  return (baseResult.confidence ?? 0) >= 0.45;
}

function buildUpcItemDbSearchQuery(
  baseResult: NormalizedIdentificationResult,
): string | null {
  const title = cleanString(baseResult.title);
  if (!title) {
    return null;
  }

  if (title.length >= 8) {
    return title;
  }

  const supporting = [
    cleanString(baseResult.series),
    cleanString(baseResult.franchise),
    cleanString(baseResult.brand),
  ].filter((value): value is string => Boolean(value));
  const query = [title, ...supporting].join(" ");
  return cleanString(query);
}

function pickBestUpcItemDbSearchResult(
  candidates: unknown[],
  baseResult: NormalizedIdentificationResult,
): JsonMap | null {
  const wantedTitle = normalizeText(baseResult.title);
  const wantedBrand = normalizeText(baseResult.brand ?? "");
  const wantedSeries = normalizeText(baseResult.series ?? "");
  const wantedFranchise = normalizeText(baseResult.franchise ?? "");
  const wantedCategory = normalizeSuggestedCategory(
    baseResult.suggested_category,
  );
  let bestScore = -1;
  let best: JsonMap | null = null;

  for (const candidate of candidates) {
    const item = asRecord(candidate);
    if (!item) {
      continue;
    }

    const title = normalizeText(cleanString(item["title"]) ?? "");
    const brand = normalizeText(cleanString(item["brand"]) ?? "");
    const model = normalizeText(cleanString(item["model"]) ?? "");
    const category = cleanString(item["category"]);
    const suggestedCategory = suggestCollectorCategory(
      category,
      cleanString(item["title"]),
    );
    let score = 0;

    if (wantedTitle && title === wantedTitle) {
      score += 14;
    } else if (wantedTitle && title.includes(wantedTitle)) {
      score += 10;
    } else if (
      wantedTitle && wantedTitle.includes(title) && title.length >= 8
    ) {
      score += 8;
    } else {
      score += overlappingWordScore(wantedTitle, title);
    }

    if (wantedBrand && brand === wantedBrand) {
      score += 5;
    } else if (wantedBrand && brand && wantedBrand.includes(brand)) {
      score += 3;
    }

    if (
      wantedSeries && model &&
      (model === wantedSeries || wantedSeries.includes(model))
    ) {
      score += 2;
    }

    if (wantedFranchise && title.includes(wantedFranchise)) {
      score += 4;
    }

    if (wantedCategory && suggestedCategory === wantedCategory) {
      score += 2;
    }

    if (preferredImageUrl(item["images"])) {
      score += 4;
    }

    if (score > bestScore) {
      bestScore = score;
      best = item;
    }
  }

  return bestScore >= 5 ? best : null;
}

function overlappingWordScore(left: string, right: string): number {
  if (!left || !right) {
    return 0;
  }

  const leftWords = new Set(left.split(" ").filter((word) => word.length >= 3));
  const rightWords = new Set(
    right.split(" ").filter((word) => word.length >= 3),
  );
  let score = 0;
  for (const word of leftWords) {
    if (rightWords.has(word)) {
      score += 2;
    }
  }
  return score;
}

function normalizeSuggestedCategory(value: unknown): string | null {
  const category = cleanString(value);
  if (!category) {
    return null;
  }
  return appCategories.includes(category as (typeof appCategories)[number])
    ? category
    : null;
}

function suggestCollectorCategory(
  rawCategory: string | null,
  title: string | null,
): string {
  const haystack = `${rawCategory ?? ""} ${title ?? ""}`.toLowerCase();

  if (
    matchesAny(haystack, [
      "trading card",
      "collectible card",
      "tcg",
      "pokemon card",
      "sports card",
      "cards",
    ])
  ) {
    return "Trading Cards";
  }

  if (matchesAny(haystack, ["comic", "graphic novel", "manga", "issue"])) {
    return "Comics";
  }

  if (
    matchesAny(haystack, [
      "die-cast",
      "die cast",
      "hot wheels",
      "matchbox",
      "model car",
    ])
  ) {
    return "Die-cast";
  }

  if (matchesAny(haystack, ["vinyl figure", "funko", "pop!"])) {
    return "Vinyl Figures";
  }

  if (matchesAny(haystack, ["board game", "card game", "tabletop"])) {
    return "Board Games";
  }

  if (matchesAny(haystack, ["statue", "bust", "figurine", "sculpture"])) {
    return "Statues";
  }

  if (
    matchesAny(haystack, [
      "memorabilia",
      "autograph",
      "signed",
      "prop replica",
      "poster",
    ])
  ) {
    return "Memorabilia";
  }

  if (
    matchesAny(haystack, ["action figure", "figure", "toy", "doll", "playset"])
  ) {
    return "Action Figures";
  }

  return "Other";
}

function inferFranchise(
  title: string | null,
  brand: string | null,
): string | null {
  const haystack = `${title ?? ""} ${brand ?? ""}`.toLowerCase();
  if (haystack.includes("star wars")) return "Star Wars";
  if (
    haystack.includes("tmnt") ||
    haystack.includes("teenage mutant ninja turtles")
  ) {
    return "Teenage Mutant Ninja Turtles";
  }
  if (haystack.includes("marvel")) return "Marvel";
  if (haystack.includes("dc")) return "DC";
  if (haystack.includes("dune")) return "Dune";
  return null;
}

function inferCharacterOrSubject(title: string | null): string | null {
  const normalized = cleanString(title);
  if (!normalized) {
    return null;
  }
  const separators = [" - ", ":", " | "];
  for (const separator of separators) {
    if (normalized.includes(separator)) {
      return cleanString(normalized.split(separator).slice(-1)[0]);
    }
  }
  return null;
}

function inferYear(value: string | null): number | null {
  const text = cleanString(value);
  if (!text) {
    return null;
  }
  const match = text.match(/\b(19|20)\d{2}\b/);
  if (!match) {
    return null;
  }
  return Number.parseInt(match[0], 10);
}

function matchesAny(haystack: string, needles: string[]): boolean {
  return needles.some((needle) => haystack.includes(needle));
}

async function safeJson(response: Response): Promise<JsonMap> {
  const text = await response.text();
  if (!text.trim()) {
    return {};
  }
  try {
    const parsed = JSON.parse(text);
    return asRecord(parsed) ?? {};
  } catch {
    return {};
  }
}

function asRecord(value: unknown): JsonMap | null {
  if (!value || typeof value !== "object" || Array.isArray(value)) {
    return null;
  }
  return value as JsonMap;
}

function asArray(value: unknown): unknown[] {
  return Array.isArray(value) ? value : [];
}

function stringArray(value: unknown): string[] {
  return asArray(value)
    .map((item) => cleanString(item))
    .filter((item): item is string => Boolean(item));
}

function asString(value: unknown): string | null {
  if (typeof value === "string") {
    const trimmed = value.trim();
    return trimmed.length ? trimmed : null;
  }
  return null;
}

function asNumber(value: unknown): number | null {
  if (typeof value === "number" && Number.isFinite(value)) {
    return value;
  }
  if (typeof value === "string") {
    const parsed = Number(value);
    return Number.isFinite(parsed) ? parsed : null;
  }
  return null;
}

function asInteger(value: unknown): number | null {
  const parsed = asNumber(value);
  return parsed == null ? null : Math.round(parsed);
}

function asBoolean(value: unknown): boolean {
  return value === true || value === "true" || value === 1 || value === "1";
}

function cleanString(value: unknown): string | null {
  if (typeof value !== "string") {
    return null;
  }
  const trimmed = value.replaceAll(/\s+/g, " ").trim();
  return trimmed.length ? trimmed : null;
}

function normalizeText(value: string): string {
  return value.toLowerCase().replaceAll(/[^a-z0-9]+/g, " ").trim();
}

function extractResponsesOutputText(payload: JsonMap): string | null {
  const directText = cleanString(payload.output_text);
  if (directText) {
    return directText;
  }

  for (const outputItem of asArray(payload.output)) {
    const outputRecord = asRecord(outputItem);
    if (!outputRecord) {
      continue;
    }
    for (const contentItem of asArray(outputRecord.content)) {
      const contentRecord = asRecord(contentItem);
      if (!contentRecord) {
        continue;
      }
      if (cleanString(contentRecord.type) !== "output_text") {
        continue;
      }
      const text = cleanString(contentRecord.text);
      if (text) {
        return text;
      }
    }
  }

  return null;
}

function normalizeBarcode(value: string | null): string | null {
  if (!value) {
    return null;
  }
  const normalized = value.replaceAll(/[^0-9xX]/g, "");
  return normalized.length ? normalized : null;
}

function normalizeMimeType(value: string | null): string | null {
  if (!value) {
    return null;
  }
  const normalized = value.trim().toLowerCase();
  return normalized.startsWith("image/") ? normalized : null;
}

function stripDataUrlPrefix(base64: string | null): string | null {
  if (!base64) {
    return null;
  }
  const marker = ";base64,";
  const markerIndex = base64.indexOf(marker);
  if (markerIndex == -1) {
    return base64.trim();
  }
  return base64.slice(markerIndex + marker.length).trim();
}

function decodeBase64(base64: string): Uint8Array {
  const binary = atob(base64);
  const bytes = new Uint8Array(binary.length);
  for (let index = 0; index < binary.length; index += 1) {
    bytes[index] = binary.charCodeAt(index);
  }
  return bytes;
}

async function sha256Hex(bytes: Uint8Array): Promise<string> {
  const digest = await crypto.subtle.digest(
    "SHA-256",
    bytes.slice().buffer as ArrayBuffer,
  );
  return [...new Uint8Array(digest)]
    .map((byte) => byte.toString(16).padStart(2, "0"))
    .join("");
}

function mustGetEnv(name: string): string {
  const value = Deno.env.get(name);
  if (!value) {
    throw new Error(`Missing required environment variable: ${name}`);
  }
  return value;
}

function jsonResponse(body: JsonMap, status: number) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      ...corsHeaders,
      "Content-Type": "application/json",
    },
  });
}
