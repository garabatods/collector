import { createClient } from "npm:@supabase/supabase-js@2";

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

type LookupMode = "barcode" | "photo";
type LookupStatus = "matched" | "enriched" | "partial" | "not_found" | "failed";
type ProviderStage = "cache" | "upcitemdb" | "goupc" | "openai" | "comicvine";

interface CacheRow {
  normalized_result: JsonMap;
  status: LookupStatus;
  provider_stage: ProviderStage;
  raw_result: unknown;
  expires_at: string;
}

interface ComicContext {
  issue_number: string | null;
  volume_name: string | null;
  publisher: string | null;
}

interface NormalizedIdentificationResult {
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

interface OpenAiPhotoResult {
  result: NormalizedIdentificationResult;
  rawResult: unknown;
  isComicLike: boolean;
}

const upcItemDbEndpoint = "https://api.upcitemdb.com/prod/trial/lookup";
const goUpcEndpoint = "https://go-upc.com/api/v1/code";
const comicVineSearchEndpoint = "https://comicvine.gamespot.com/api/search/";
const openAiResponsesEndpoint = "https://api.openai.com/v1/responses";
const defaultOpenAiPhotoModel = "gpt-4o-mini";
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
    is_comic_like: { anyOf: [{ type: "boolean" }, { type: "null" }] },
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
    "is_comic_like",
    "comic_context",
  ],
} as const;

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

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
      global: { headers: { Authorization: authHeader } },
    });
    const {
      data: { user },
      error: userError,
    } = await authClient.auth.getUser();

    if (userError || !user) {
      return jsonResponse(
        { error: "Could not resolve the authenticated user." },
        401,
      );
    }

    const adminClient = createClient(supabaseUrl, supabaseServiceRoleKey, {
      auth: { persistSession: false, autoRefreshToken: false },
    });

    const payload = await req.json();
    const mode = asString(payload?.mode);
    if (mode !== "barcode" && mode !== "photo") {
      return jsonResponse(
        { error: "Expected mode to be either `barcode` or `photo`." },
        400,
      );
    }

    if (mode === "barcode") {
      const barcode = normalizeBarcode(asString(payload?.barcode));
      if (!barcode) {
        return jsonResponse(
          { error: "A valid barcode is required." },
          400,
        );
      }

      const cached = await fetchCache({
        adminClient,
        userId: user.id,
        lookupType: "barcode",
        lookupKey: barcode,
      });
      if (cached) {
        return jsonResponse(cacheHit(cached), 200);
      }

      const upcItemDbMatch = await lookupUpcItemDb(barcode);
      if (upcItemDbMatch) {
        await saveCache({
          adminClient,
          userId: user.id,
          lookupType: "barcode",
          lookupKey: barcode,
          ttlDays: 30,
          match: upcItemDbMatch,
        });
        return jsonResponse(upcItemDbMatch.result, 200);
      }

      const goUpcMatch = await lookupGoUpc(barcode);
      if (goUpcMatch) {
        await saveCache({
          adminClient,
          userId: user.id,
          lookupType: "barcode",
          lookupKey: barcode,
          ttlDays: 30,
          match: goUpcMatch,
        });
        return jsonResponse(goUpcMatch.result, 200);
      }

      const miss = buildNotFoundResult({
        providerStage: "goupc",
        barcode,
        sourceBadge: "No catalog match",
      });
      await saveCache({
        adminClient,
        userId: user.id,
        lookupType: "barcode",
        lookupKey: barcode,
        ttlDays: 30,
        match: {
          status: "not_found",
          providerStage: "goupc",
          result: miss,
          rawResult: {
            upcitemdb: null,
            goupc: null,
          },
        },
      });
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

    const imageFingerprint = await sha256Hex(decodeBase64(imageBase64));
    const cached = await fetchCache({
      adminClient,
      userId: user.id,
      lookupType: "photo",
      lookupKey: imageFingerprint,
    });
    if (cached) {
      return jsonResponse(cacheHit(cached), 200);
    }

    const barcodeHint = normalizeBarcode(asString(payload?.barcode));
    const openAiResult = await identifyPhotoWithOpenAi({
      imageBase64,
      mimeType,
      barcode: barcodeHint,
    });

    let finalMatch: ProviderMatch = {
      status: openAiResult.result.title.trim().length === 0 ? "partial" : "matched",
      providerStage: "openai",
      result: openAiResult.result,
      rawResult: openAiResult.rawResult,
    };

    const barcodeCatalogEnriched = await enrichPhotoWithBarcodeCatalog({
      barcode: barcodeHint,
      baseResult: finalMatch.result,
      openAiRawResult: openAiResult.rawResult,
    });
    if (barcodeCatalogEnriched) {
      finalMatch = barcodeCatalogEnriched;
    }

    if (openAiResult.isComicLike) {
      const comicEnriched = await enrichComicProviders(finalMatch.result);
      if (comicEnriched) {
        finalMatch = {
          status: comicEnriched.result.title.trim().length === 0
            ? "partial"
            : "enriched",
          providerStage: "comicvine",
          result: comicEnriched.result,
          rawResult: {
            upstream: finalMatch.rawResult,
            comicvine: comicEnriched.rawResult,
          },
        };
      }
    }

    await saveCache({
      adminClient,
      userId: user.id,
      lookupType: "photo",
      lookupKey: imageFingerprint,
      ttlDays: 14,
      match: finalMatch,
    });

    return jsonResponse(finalMatch.result, 200);
  } catch (error) {
    console.error("identify_collectible failed", error);
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

async function fetchCache({
  adminClient,
  userId,
  lookupType,
  lookupKey,
}: {
  adminClient: ReturnType<typeof createClient>;
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

  return data as CacheRow;
}

function cacheHit(cached: CacheRow): JsonMap {
  return {
    ...(cached.normalized_result ?? {}),
    status: cached.status,
    provider_stage: "cache",
    source_badge: `Saved • ${asString((cached.normalized_result ?? {})["source_badge"]) || "Catalog match"}`,
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
  adminClient: ReturnType<typeof createClient>;
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

async function lookupUpcItemDb(barcode: string): Promise<ProviderMatch | null> {
  const response = await fetch(`${upcItemDbEndpoint}?upc=${barcode}`, {
    headers: { Accept: "application/json" },
  });

  const payload = await safeJson(response);
  if (response.status === 404) {
    return null;
  }
  if (response.status === 429 || response.status >= 500) {
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

async function lookupGoUpc(barcode: string): Promise<ProviderMatch | null> {
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
  if (response.status === 404 || response.status === 429 || response.status >= 500) {
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
}: {
  imageBase64: string;
  mimeType: string;
  barcode: string | null;
}): Promise<OpenAiPhotoResult> {
  const apiKey = Deno.env.get("OPEN_AI_KEY") ?? mustGetEnv("OPENAI_API_KEY");
  const model = Deno.env.get("OPEN_AI_PHOTO_MODEL") ?? defaultOpenAiPhotoModel;
  const dataUrl = `data:${mimeType};base64,${imageBase64}`;

  const response = await fetch(openAiResponsesEndpoint, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${apiKey}`,
    },
    body: JSON.stringify({
      model,
      input: [
        {
          role: "developer",
          content: [
            {
              type: "input_text",
              text:
                "You identify collectible products from photos. Return only schema-valid JSON. Prefer specific collectible titles when possible. If unsure, keep title empty instead of inventing. suggested_category must be one of: Action Figures, Board Games, Comics, Memorabilia, Die-cast, Vinyl Figures, Statues, Trading Cards, Other.",
            },
          ],
        },
        {
          role: "user",
          content: [
            {
              type: "input_text",
              text:
                `Identify the collectible in this photo. Respond with JSON using exactly these keys: title, suggested_category, description, brand, franchise, series, character_or_subject, release_year, confidence, source_badge, is_comic_like, comic_context. comic_context must be either null or an object with issue_number, volume_name, publisher. Use null for unknown optional fields. Confidence should be between 0 and 1. Source badge should be a short premium-facing label like "AI identification". Barcode hint: ${barcode ?? "none"}.`,
            },
            {
              type: "input_image",
              image_url: dataUrl,
              detail: "high",
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
      temperature: 0.2,
      max_output_tokens: 900,
    }),
  });

  const payload = await safeJson(response);
  if (response.status >= 400) {
    const apiError = asRecord(payload?.error);
    const apiMessage = cleanString(apiError?.message) ??
      cleanString(payload?.message);
    throw new Error(
      apiMessage ??
        `OpenAI photo identification failed with status ${response.status}.`,
    );
  }

  const rawJson = extractResponsesOutputText(payload);
  if (!rawJson) {
    throw new Error("OpenAI did not return structured JSON.");
  }

  const parsed = JSON.parse(rawJson) as JsonMap;
  const comicContext = asRecord(parsed.comic_context);

  return {
    result: normalizeResult({
      status: "matched",
      providerStage: "openai",
      title: cleanString(parsed.title) ?? "",
      suggestedCategory: normalizeSuggestedCategory(parsed.suggested_category) ??
        "Other",
      imageUrl: null,
      description: cleanString(parsed.description),
      brand: cleanString(parsed.brand),
      franchise: cleanString(parsed.franchise),
      series: cleanString(parsed.series),
      characterOrSubject: cleanString(parsed.character_or_subject),
      releaseYear: asInteger(parsed.release_year),
      barcode,
      confidence: asNumber(parsed.confidence),
      sourceBadge: cleanString(parsed.source_badge) ?? "AI identification",
      comicContext: comicContext
          ? {
            issue_number: cleanString(comicContext.issue_number),
            volume_name: cleanString(comicContext.volume_name),
            publisher: cleanString(comicContext.publisher),
          }
          : null,
    }),
    rawResult: payload,
    isComicLike: Boolean(parsed.is_comic_like) ||
        normalizeSuggestedCategory(parsed.suggested_category) == "Comics",
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

  const providerMatch = await lookupUpcItemDb(barcode) ?? await lookupGoUpc(barcode);
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
    characterOrSubject:
      baseResult.character_or_subject ?? providerResult.character_or_subject,
    releaseYear: baseResult.release_year ?? providerResult.release_year,
    barcode: barcode,
    confidence: Math.max(baseResult.confidence ?? 0.6, providerResult.confidence ?? 0),
    sourceBadge: providerMatch.providerStage === "goupc"
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

async function enrichComicProviders(
  baseResult: NormalizedIdentificationResult,
): Promise<ProviderMatch | null> {
  const enrichers = [enrichWithComicVine];
  for (const enrich of enrichers) {
    const result = await enrich(baseResult);
    if (result) {
      return result;
    }
  }
  return null;
}

async function enrichWithComicVine(
  baseResult: NormalizedIdentificationResult,
): Promise<ProviderMatch | null> {
  const apiKey = Deno.env.get("COMICVINE_API");
  if (!apiKey) {
    return null;
  }

  const query = [baseResult.title, baseResult.series, baseResult.franchise]
    .concat([
      baseResult.comic_context?.issue_number,
      baseResult.comic_context?.volume_name,
      baseResult.comic_context?.publisher,
    ])
    .filter((value): value is string => Boolean(value && value.trim()))
    .join(" ");
  if (!query.trim()) {
    return null;
  }

  const url = new URL(comicVineSearchEndpoint);
  url.searchParams.set("api_key", apiKey);
  url.searchParams.set("format", "json");
  url.searchParams.set("resources", "issue,volume");
  url.searchParams.set("limit", "5");
  url.searchParams.set("query", query);

  const response = await fetch(url, {
    headers: {
      Accept: "application/json",
      "User-Agent": "collectorapp/1.0",
    },
  });
  if (response.status >= 400) {
    return null;
  }

  const payload = await safeJson(response);
  const results = asArray(payload?.results);
  if (!results.length) {
    return null;
  }

  const match = pickBestComicVineMatch(results, baseResult);
  if (!match) {
    return null;
  }

  const issueNumber = cleanString(match["issue_number"]);
  const volume = asRecord(match["volume"]);
  const publisher = asRecord(match["publisher"]) ||
    asRecord(volume ? volume["publisher"] : null);
  const image = asRecord(match["image"]);
  const imageUrl = cleanString(image ? image["super_url"] : null) ??
    cleanString(image ? image["original_url"] : null);
  const volumeName = cleanString(volume ? volume["name"] : null) ??
    cleanString(match["name"]);

  const result = normalizeResult({
    status: "enriched",
    providerStage: "comicvine",
    title: cleanString(match["name"]) ?? baseResult.title,
    suggestedCategory: "Comics",
    imageUrl: imageUrl ?? baseResult.image_url,
    description: cleanString(match["deck"]) ?? cleanString(match["description"]) ??
      baseResult.description,
    brand: baseResult.brand,
    franchise: baseResult.franchise ?? volumeName,
    series: volumeName ?? baseResult.series,
    characterOrSubject: baseResult.character_or_subject,
    releaseYear: inferYear(cleanString(match["cover_date"])) ??
      inferYear(cleanString(match["start_year"])) ??
      baseResult.release_year,
    barcode: baseResult.barcode,
    confidence: Math.max(baseResult.confidence ?? 0.65, 0.9),
    sourceBadge: "AI + Comic Vine",
    comicContext: {
      issue_number: issueNumber,
      volume_name: volumeName,
      publisher: cleanString(publisher ? publisher["name"] : null) ??
        baseResult.comic_context?.publisher ??
        null,
    },
  });

  return {
    status: "enriched",
    providerStage: "comicvine",
    result,
    rawResult: payload,
  };
}

function pickBestComicVineMatch(
  candidates: unknown[],
  baseResult: NormalizedIdentificationResult,
): JsonMap | null {
  const wanted = normalizeText(baseResult.title || baseResult.series || "");
  const wantedSeries = normalizeText(
    baseResult.comic_context?.volume_name ?? baseResult.series ?? "",
  );
  const wantedIssue = normalizeText(baseResult.comic_context?.issue_number ?? "");
  const wantedPublisher = normalizeText(baseResult.comic_context?.publisher ?? "");
  let bestScore = -1;
  let best: JsonMap | null = null;

  for (const candidate of candidates) {
    const row = asRecord(candidate);
    if (!row) {
      continue;
    }
    const name = normalizeText(cleanString(row["name"]) ?? "");
    const deck = normalizeText(cleanString(row["deck"]) ?? "");
    const issueNumber = normalizeText(cleanString(row["issue_number"]) ?? "");
    const volume = asRecord(row["volume"]);
    const volumeName = normalizeText(cleanString(volume ? volume["name"] : null) ?? "");
    const publisher = asRecord(row["publisher"]) ||
      asRecord(volume ? volume["publisher"] : null);
    const publisherName = normalizeText(
      cleanString(publisher ? publisher["name"] : null) ?? "",
    );
    let score = 0;
    if (wanted && name === wanted) {
      score += 10;
    } else if (wanted && name.includes(wanted)) {
      score += 7;
    } else if (wanted && deck.includes(wanted)) {
      score += 4;
    }
    if (wantedSeries && volumeName === wantedSeries) {
      score += 6;
    } else if (wantedSeries && volumeName.includes(wantedSeries)) {
      score += 4;
    }
    if (wantedIssue && issueNumber === wantedIssue) {
      score += 6;
    }
    if (wantedPublisher && publisherName === wantedPublisher) {
      score += 3;
    }
    if (cleanString(row["resource_type"]) === "issue") {
      score += 2;
    }
    if (score > bestScore) {
      bestScore = score;
      best = row;
    }
  }

  return bestScore <= 0 ? null : best;
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
    confidence: confidence == null ? null : Math.min(Math.max(confidence, 0), 1),
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
  return images.find((image) => image.startsWith("https://")) ?? images[0] ?? null;
}

function choosePreferredTitle(primary: string, fallback: string | null): string {
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

  if (matchesAny(haystack, [
    "trading card",
    "collectible card",
    "tcg",
    "pokemon card",
    "sports card",
    "cards",
  ])) {
    return "Trading Cards";
  }

  if (matchesAny(haystack, ["comic", "graphic novel", "manga", "issue"])) {
    return "Comics";
  }

  if (matchesAny(haystack, [
    "die-cast",
    "die cast",
    "hot wheels",
    "matchbox",
    "model car",
  ])) {
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

  if (matchesAny(haystack, [
    "memorabilia",
    "autograph",
    "signed",
    "prop replica",
    "poster",
  ])) {
    return "Memorabilia";
  }

  if (matchesAny(haystack, ["action figure", "figure", "toy", "doll", "playset"])) {
    return "Action Figures";
  }

  return "Other";
}

function inferFranchise(title: string | null, brand: string | null): string | null {
  const haystack = `${title ?? ""} ${brand ?? ""}`.toLowerCase();
  if (haystack.includes("star wars")) return "Star Wars";
  if (haystack.includes("tmnt") || haystack.includes("teenage mutant ninja turtles")) {
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
  const digest = await crypto.subtle.digest("SHA-256", bytes);
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
