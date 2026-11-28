import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "https://mikustreet1313.github.io",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

function reply(status: number, body: Record<string, unknown>) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

Deno.serve(async (req: Request) => {
  const origin = req.headers.get("Origin");
  if (origin && origin !== "https://mikustreet1313.github.io") {
    return reply(403, { error: "Origin not allowed" });
  }

  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return reply(405, { error: "Method not allowed" });
  }

  const authorization = req.headers.get("Authorization");
  if (!authorization?.startsWith("Bearer ")) {
    return reply(401, { error: "Authentication required" });
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!supabaseUrl || !anonKey || !serviceRoleKey) {
    return reply(500, { error: "Server configuration is incomplete" });
  }

  const token = authorization.slice("Bearer ".length).trim();
  if (!token) return reply(401, { error: "Authentication required" });

  // Validate the caller's JWT with Auth; never trust a user ID supplied by the client.
  const userClient = createClient(supabaseUrl, anonKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });
  const { data: authData, error: authError } = await userClient.auth.getUser(token);
  const user = authData.user;
  if (authError || !user) return reply(401, { error: "Invalid or expired session" });

  // The service-role key exists only in this server-side Edge Function.
  const adminClient = createClient(supabaseUrl, serviceRoleKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });

  const { data: profile, error: profileError } = await adminClient
    .from("profiles")
    .select("id, role, account_status")
    .eq("id", user.id)
    .maybeSingle();

  if (profileError) {
    // A missing account_status column is expected until the reviewed migration is applied.
    return reply(409, {
      error: "Account-closure database setup is not ready. No account changes were made.",
    });
  }
  if (!profile) return reply(404, { error: "Profile not found" });
  if (String(profile.role).toUpperCase() !== "CREATOR") {
    return reply(403, { error: "This closure flow is only for creator accounts" });
  }
  if (profile.account_status === "CLOSED") {
    return reply(409, { error: "This creator account is already closed" });
  }
  if (profile.account_status !== "ACTIVE") {
    return reply(409, { error: "The creator account has an unsupported status" });
  }

  // Close the profile first. The separate RLS guard migration must be applied
  // so existing JWTs cannot continue writing while the Auth ban is being applied.
  const closedAt = new Date().toISOString();
  const { data: updated, error: updateError } = await adminClient
    .from("profiles")
    .update({ account_status: "CLOSED", closed_at: closedAt })
    .eq("id", user.id)
    .eq("account_status", "ACTIVE")
    .select("id")
    .maybeSingle();

  if (updateError || !updated) {
    return reply(409, { error: "The account could not be closed. No Auth ban was applied." });
  }

  // Ban login without deleting auth.users: foreign keys and public authorship remain intact.
  const { error: banError } = await adminClient.auth.admin.updateUserById(user.id, {
    ban_duration: "876000h",
  });

  if (banError) {
    // Best-effort rollback. If rollback fails, CLOSED remains the safer state:
    // RLS guards must block writes even if the user can still authenticate.
    const { error: rollbackError } = await adminClient
      .from("profiles")
      .update({ account_status: "ACTIVE", closed_at: null })
      .eq("id", user.id)
      .eq("account_status", "CLOSED");

    return reply(500, {
      error: rollbackError
        ? "The account was marked CLOSED but Auth blocking failed. Administrator review is required."
        : "Auth blocking failed; the profile closure was rolled back. Please try again later.",
    });
  }

  return reply(200, {
    success: true,
    message: "Creator account closed. Public creator name and existing publications are retained; selling and editing access are disabled.",
  });
});
