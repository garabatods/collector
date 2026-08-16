import { createClient } from "npm:@supabase/supabase-js@2";

const headers = { "Content-Type": "application/json" };

Deno.serve(async (request) => {
  if (request.method !== "POST") {
    return new Response(JSON.stringify({ error: "Method not allowed" }), {
      status: 405,
      headers,
    });
  }

  const expectedAuthorization = Deno.env.get("REVENUECAT_WEBHOOK_SECRET") ?? "";
  const receivedAuthorization = request.headers.get("Authorization") ?? "";
  if (!expectedAuthorization || receivedAuthorization !== expectedAuthorization) {
    return new Response(JSON.stringify({ error: "Unauthorized" }), {
      status: 401,
      headers,
    });
  }

  try {
    const payload = await request.json();
    const client = createClient(
      requiredEnvironment("SUPABASE_URL"),
      requiredEnvironment("SUPABASE_SERVICE_ROLE_KEY"),
      { auth: { persistSession: false, autoRefreshToken: false } },
    );
    const { data, error } = await client.rpc("apply_revenuecat_event", {
      payload,
    });
    if (error) throw error;
    return new Response(JSON.stringify(data), { status: 200, headers });
  } catch (error) {
    console.error("RevenueCat webhook failed", error);
    return new Response(JSON.stringify({ error: "Webhook processing failed" }), {
      status: 500,
      headers,
    });
  }
});

function requiredEnvironment(name: string): string {
  const value = Deno.env.get(name)?.trim();
  if (!value) throw new Error(`Missing ${name}`);
  return value;
}
