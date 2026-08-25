// admin-impersonate edge function
// Vérifie que l'appelant est admin, génère une session (access+refresh) pour
// l'utilisateur cible via magiclink, et renvoie les tokens.
const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SERVICE_ROLE = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

const cors = {
  "Access-Control-Allow-Origin": "https://app.starvolt.fr",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

function jsonResp(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...cors, "Content-Type": "application/json" },
  });
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  if (req.method !== "POST") return jsonResp({ error: "method" }, 405);

  try {
    // 1) Identifier l'appelant via son JWT
    const authHeader = req.headers.get("Authorization") || "";
    const token = authHeader.replace(/^Bearer\s+/i, "");
    if (!token) return jsonResp({ error: "no_token" }, 401);

    const meRes = await fetch(`${SUPABASE_URL}/auth/v1/user`, {
      headers: { Authorization: `Bearer ${token}`, apikey: SERVICE_ROLE },
    });
    if (!meRes.ok) {
      // On remonte le pourquoi (jeton expiré → 401 ; signature invalide → 403…)
      // pour que le journal des erreurs le montre au lieu d'un « bad_token » nu.
      const authBody = await meRes.text().catch(() => "");
      return jsonResp({ error: "bad_token", auth_status: meRes.status, auth_body: authBody.slice(0, 200) }, 401);
    }
    const me = await meRes.json();
    const callerId = me?.id;
    if (!callerId) return jsonResp({ error: "no_caller" }, 401);

    // 2) Vérifier que l'appelant est admin
    const profRes = await fetch(
      `${SUPABASE_URL}/rest/v1/profiles?id=eq.${callerId}&select=role`,
      { headers: { apikey: SERVICE_ROLE, Authorization: `Bearer ${SERVICE_ROLE}` } },
    );
    const profArr = await profRes.json();
    const role = Array.isArray(profArr) && profArr[0]?.role;
    if (role !== "admin" && role !== "superadmin") {
      return jsonResp({ error: "forbidden" }, 403);
    }

    // 3) Récupérer l'email de l'utilisateur cible
    const body = await req.json().catch(() => ({}));
    const targetUserId = body?.target_user_id;
    if (!targetUserId) return jsonResp({ error: "no_target" }, 400);

    const targetRes = await fetch(
      `${SUPABASE_URL}/auth/v1/admin/users/${targetUserId}`,
      { headers: { apikey: SERVICE_ROLE, Authorization: `Bearer ${SERVICE_ROLE}` } },
    );
    if (!targetRes.ok) return jsonResp({ error: "target_not_found" }, 404);
    const target = await targetRes.json();
    const email = target?.email;
    if (!email) return jsonResp({ error: "no_email" }, 400);

    // 4) Générer un magiclink (hashed_token) sans envoyer d'email
    const genRes = await fetch(`${SUPABASE_URL}/auth/v1/admin/generate_link`, {
      method: "POST",
      headers: {
        apikey: SERVICE_ROLE,
        Authorization: `Bearer ${SERVICE_ROLE}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({ type: "magiclink", email }),
    });
    if (!genRes.ok) {
      const t = await genRes.text();
      return jsonResp({ error: "gen_failed", detail: t }, 500);
    }
    const gen = await genRes.json();
    const hashed = gen?.hashed_token;
    if (!hashed) return jsonResp({ error: "no_hashed" }, 500);

    // 5) Vérifier le token SANS suivre la redirection → fragment avec les tokens
    const verifyUrl =
      `${SUPABASE_URL}/auth/v1/verify?token=${hashed}&type=magiclink&redirect_to=${encodeURIComponent("http://localhost")}`;
    const vRes = await fetch(verifyUrl, {
      method: "GET",
      redirect: "manual",
      headers: { apikey: SERVICE_ROLE },
    });
    const loc = vRes.headers.get("Location") || vRes.headers.get("location") || "";
    const frag = loc.includes("#") ? loc.split("#")[1] : "";
    const params = new URLSearchParams(frag);
    const access_token = params.get("access_token");
    const refresh_token = params.get("refresh_token");
    if (!access_token || !refresh_token) {
      return jsonResp({ error: "no_session", loc }, 500);
    }

    return jsonResp({
      access_token,
      refresh_token,
      email,
      user_id: targetUserId,
    });
  } catch (e) {
    return jsonResp({ error: "exception", detail: String(e) }, 500);
  }
});
