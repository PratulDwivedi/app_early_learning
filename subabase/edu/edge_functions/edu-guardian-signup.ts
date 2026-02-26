import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type, content-profile, x-supabase-client-platform, x-supabase-client-platform-version, x-supabase-client-runtime, x-supabase-client-runtime-version",
};

// ─── Helper: always return JSON with CORS headers ───────────────────────────
function jsonResponse(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

serve(async (req) => {
  const requestId = crypto.randomUUID(); // tie all logs for one request together
  console.log(`[${requestId}] ▶ ${req.method} ${req.url}`);
  console.log(`[${requestId}] Headers:`, Object.fromEntries(req.headers.entries()));

  // ── CORS preflight ────────────────────────────────────────────────────────
  if (req.method === "OPTIONS") {
    console.log(`[${requestId}] ✅ OPTIONS preflight — returning 200`);
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    // ── Env vars ──────────────────────────────────────────────────────────
    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

    console.log(`[${requestId}] ENV check — SUPABASE_URL present: ${!!supabaseUrl}, SERVICE_ROLE_KEY present: ${!!serviceRoleKey}`);

    if (!supabaseUrl || !serviceRoleKey) {
      console.error(`[${requestId}] ❌ Missing env vars`);
      return jsonResponse({ error: "Server misconfiguration: missing env vars" }, 500);
    }

    // ── Parse body ────────────────────────────────────────────────────────
    let body: { user_name?: string; email?: string; password?: string };
    try {
      body = await req.json();
      console.log(`[${requestId}] Body parsed — keys: ${Object.keys(body).join(", ")}`);
    } catch (parseErr) {
      console.error(`[${requestId}] ❌ Body parse failed:`, parseErr);
      return jsonResponse({ error: "Invalid JSON body" }, 400);
    }

    const { user_name, email, password } = body;

    // ── Validation ────────────────────────────────────────────────────────
    if (!user_name || !email || !password) {
      console.warn(`[${requestId}] ⚠️ Validation failed — missing fields`, { user_name: !!user_name, email: !!email, password: !!password });
      return jsonResponse({ error: "Missing required fields: user_name, email, password" }, 400);
    }

    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email)) {
      console.warn(`[${requestId}] ⚠️ Invalid email format: ${email}`);
      return jsonResponse({ error: "Invalid email format" }, 400);
    }

    // ── Supabase client ───────────────────────────────────────────────────
    const supabaseAdmin = createClient(supabaseUrl, serviceRoleKey, {
      auth: { autoRefreshToken: false, persistSession: false },
    });

    // ── Step 1: Create auth user ──────────────────────────────────────────
    console.log(`[${requestId}] 🔑 Creating auth user for: ${email}`);
    const { data: authData, error: authError } = await supabaseAdmin.auth.admin.createUser({
      email,
      password,
      email_confirm: true,
      user_metadata: { user_name },
    });

    if (authError) {
      console.error(`[${requestId}] ❌ Auth createUser error:`, {
        message: authError.message,
        status: authError.status,
        name: authError.name,
      });
      return jsonResponse({ error: authError.message }, 400);
    }

    const userId = authData.user.id;
    console.log(`[${requestId}] ✅ Auth user created — userId: ${userId}`);

    // ── Step 2: Insert profile ────────────────────────────────────────────
    console.log(`[${requestId}] 📝 Inserting profile for userId: ${userId}`);
    const { data: profileData, error: profileError } = await supabaseAdmin
      .from("profiles")
      .insert({
        id: userId,
        email,
        full_name: user_name,
        user_name,
        data: {
          is_admin: false,
          date_format: "dd/mm/yyyy",
          datetime_format: "dd/mm/yyyy hh:mm:ss",
        },
        tenant_id: 5,
        is_active: true,
        created_by: 1,
        created_at: new Date().toISOString(),
      })
      .select()
      .single();

    if (profileError) {
      // ⚠️ Log but don't fail silently — auth user was created but profile failed
      console.error(`[${requestId}] ❌ Profile insert error:`, {
        message: profileError.message,
        code: profileError.code,
        details: profileError.details,
        hint: profileError.hint,
      });
    } else {
      console.log(`[${requestId}] ✅ Profile inserted successfully`);
    }

    // ── Success ───────────────────────────────────────────────────────────
    console.log(`[${requestId}] 🎉 Signup complete for userId: ${userId}`);
    return jsonResponse({
      is_success: true,
      message: "You have signed up successfully",
      error: profileError ?? null,
      profileData,
      data: [{ user_id: userId, email, user_name, tenant: { id: 5 } }],
    });

  } catch (error) {
    // This catch = something threw unexpectedly (not a Supabase error object)
    console.error(`[${requestId}] 💥 Unhandled exception:`, {
      message: error?.message,
      name: error?.name,
      stack: error?.stack,
    });
    return jsonResponse(
      { error: error?.message || "An unexpected error occurred" },
      500
    );
  }
});