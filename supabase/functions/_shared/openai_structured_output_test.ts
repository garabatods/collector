import { assertEquals } from "jsr:@std/assert@1";
import {
  parseOpenAiStructuredOutput,
  shouldRetryOpenAiStructuredOutput,
} from "./openai_structured_output.ts";

Deno.test("parses a completed structured response", () => {
  assertEquals(
    parseOpenAiStructuredOutput(
      { status: "completed" },
      '{"title":"Funko Pop"}',
    ),
    { ok: true, value: { title: "Funko Pop" } },
  );
});

Deno.test("recognizes a response truncated by the output-token limit", () => {
  assertEquals(
    parseOpenAiStructuredOutput(
      {
        status: "incomplete",
        incomplete_details: { reason: "max_output_tokens" },
      },
      '{"title":"unfinished',
    ),
    { ok: false, reason: "max_output_tokens" },
  );
});

Deno.test("recognizes malformed JSON even when status is completed", () => {
  assertEquals(
    parseOpenAiStructuredOutput(
      { status: "completed" },
      '{"title":"unfinished',
    ),
    { ok: false, reason: "invalid_json" },
  );
  assertEquals(shouldRetryOpenAiStructuredOutput("invalid_json"), true);
});
