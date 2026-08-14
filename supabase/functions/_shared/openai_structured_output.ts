export type JsonObject = Record<string, unknown>;

export type StructuredOutputParseResult =
  | { ok: true; value: JsonObject }
  | { ok: false; reason: string };

export function parseOpenAiStructuredOutput(
  payload: JsonObject,
  outputText: string | null,
): StructuredOutputParseResult {
  if (payload.status === "incomplete") {
    const incompleteDetails = asObject(payload.incomplete_details);
    return {
      ok: false,
      reason: asString(incompleteDetails?.reason) ?? "incomplete",
    };
  }

  if (!outputText?.trim()) {
    return { ok: false, reason: "missing_output" };
  }

  try {
    const parsed = JSON.parse(outputText);
    const value = asObject(parsed);
    return value
      ? { ok: true, value }
      : { ok: false, reason: "non_object_json" };
  } catch {
    return { ok: false, reason: "invalid_json" };
  }
}

export function shouldRetryOpenAiStructuredOutput(reason: string): boolean {
  return reason === "max_output_tokens" ||
    reason === "max_tokens" ||
    reason === "incomplete" ||
    reason === "missing_output" ||
    reason === "invalid_json";
}

function asObject(value: unknown): JsonObject | null {
  if (!value || typeof value !== "object" || Array.isArray(value)) {
    return null;
  }
  return value as JsonObject;
}

function asString(value: unknown): string | null {
  return typeof value === "string" && value.trim() ? value.trim() : null;
}
