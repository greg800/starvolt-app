// Edge Function : security-check
// Lance un audit de sécurité de la BASE (security_audit RPC), fait interpréter les
// faits par Claude avec le prompt éditable (ai_prompts feature='cyber_security'),
// enregistre le résultat dans security_checks et logge le coût dans ai_usage_log.
//
// Deux voies d'accès :
//   - manuel  : un admin/superadmin connecté (JWT user) clique « lancer un check ».
//   - cron    : appel serveur mensuel portant l'en-tête x-cron-secret = CRON_SECRET.
//
// ⚠️ Ce check n'inspecte QUE la base de données. Le code client, le serveur Node et
// le code des edge functions ne sont pas accessibles ici : ils restent à auditer
// manuellement (le prompt le rappelle et l'IA le remonte dans « à surveiller »).

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SERVICE_ROLE = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY")!;
const ANTHROPIC_API_KEY = Deno.env.get("ANTHROPIC_API_KEY");
const CRON_SECRET = Deno.env.get("CRON_SECRET"); // partagé avec le cron pg_cron

const MODEL = "claude-opus-4-7";
const USD_PER_EUR = 0.92;
const PRICES: Record<string, { in: number; out: number }> = {
  "claude-opus-4-7": { in: 5, out: 25 },
};

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type, x-cron-secret",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { ...cors, "Content-Type": "application/json" },
  });

const DEFAULT_SYSTEM_PROMPT =
  "Tu es l'auditeur sécurité de l'application Starvolt. On te fournit le résultat " +
  "factuel d'un audit automatique de la base de données. Interprète ces faits, du " +
  "plus grave au moins grave, en français, sans rien inventer. Une table sans RLS = " +
  "critique. Distingue ce qui est vérifié automatiquement (base) de ce qui reste " +
  "manuel (code client, serveur Node, edge functions, dépendances). Appelle l'outil " +
  "report_security.";

// Appel à Supabase REST / RPC via service_role
async function rpc(name: string, args: unknown = {}): Promise<any> {
  const res = await fetch(`${SUPABASE_URL}/rest/v1/rpc/${name}`, {
    method: "POST",
    headers: {
      apikey: SERVICE_ROLE,
      Authorization: `Bearer ${SERVICE_ROLE}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify(args),
  });
  if (!res.ok) throw new Error(`rpc ${name}: ${res.status} ${await res.text()}`);
  return await res.json();
}

async function dbSelect(path: string): Promise<any> {
  const res = await fetch(`${SUPABASE_URL}/rest/v1/${path}`, {
    headers: { apikey: SERVICE_ROLE, Authorization: `Bearer ${SERVICE_ROLE}` },
  });
  if (!res.ok) return null;
  return await res.json();
}

// Résout l'appelant : renvoie { mode:'cron' } ou { mode:'user', email } admin, ou null.
async function resolveCaller(req: Request): Promise<{ mode: string; email?: string } | null> {
  // Voie cron : en-tête partagé
  const cronHdr = req.headers.get("x-cron-secret");
  if (CRON_SECRET && cronHdr && cronHdr === CRON_SECRET) return { mode: "cron" };

  // Voie utilisateur : JWT → /auth/v1/user → profil admin/superadmin
  const jwt = (req.headers.get("Authorization") || "").replace(/^Bearer\s+/i, "");
  if (!jwt) return null;
  const uRes = await fetch(`${SUPABASE_URL}/auth/v1/user`, {
    headers: { Authorization: `Bearer ${jwt}`, apikey: ANON_KEY },
  });
  if (!uRes.ok) return null;
  const u = await uRes.json();
  if (!u?.id) return null;
  const prof = await dbSelect(`profiles?id=eq.${u.id}&select=role`);
  const role = Array.isArray(prof) ? prof[0]?.role : null;
  if (role !== "admin" && role !== "superadmin") return null;
  return { mode: "user", email: u.email };
}

const tool = {
  name: "report_security",
  description: "Renvoie la synthèse de l'audit de sécurité.",
  input_schema: {
    type: "object",
    properties: {
      severity: { type: "string", enum: ["ok", "info", "warn", "critical"] },
      found: { type: "string", description: "Ce qui a été trouvé, du plus grave au moins grave." },
      fixed: { type: "string", description: "Ce qui a été corrigé (en général rien : audit lecture seule)." },
      watch_next: { type: "string", description: "À surveiller au prochain passage, incluant les angles morts manuels." },
      report_md: { type: "string", description: "Rapport lisible complet (markdown léger)." },
    },
    required: ["severity", "found", "fixed", "watch_next", "report_md"],
  },
};

async function handle(req: Request): Promise<Response> {
  const caller = await resolveCaller(req);
  if (!caller) return json({ error: "forbidden", message: "Accès réservé aux administrateurs." }, 403);

  let body: any = {};
  try { body = await req.json(); } catch { /* vide ok */ }
  const triggerType = caller.mode === "cron" ? "cron"
    : (body?.trigger_type === "cron" ? "cron" : "manual");
  const triggeredBy = caller.mode === "cron" ? "cron" : (caller.email || "admin");

  if (!ANTHROPIC_API_KEY) return json({ error: "missing_key", message: "ANTHROPIC_API_KEY non configurée." }, 500);

  // 1) Audit factuel de la base
  let audit: any;
  try {
    audit = await rpc("security_audit");
  } catch (e) {
    return json({ error: "audit_failed", message: String((e as any)?.message || e) }, 500);
  }

  // 2) Prompt système éditable
  let systemPrompt = DEFAULT_SYSTEM_PROMPT;
  try {
    const pr = await dbSelect("ai_prompts?feature=eq.cyber_security&select=system_prompt");
    const sp = Array.isArray(pr) ? pr[0]?.system_prompt : null;
    if (sp && sp.trim()) systemPrompt = sp.trim();
  } catch { /* fallback */ }

  // 3) Interprétation par Claude
  const userContent =
    "Résultat de l'audit automatique de la base de données Starvolt (JSON factuel) :\n\n" +
    "```json\n" + JSON.stringify(audit, null, 2) + "\n```\n\n" +
    "Interprète ces faits et appelle report_security.";

  const aiRes = await fetch("https://api.anthropic.com/v1/messages", {
    method: "POST",
    headers: {
      "x-api-key": ANTHROPIC_API_KEY,
      "anthropic-version": "2023-06-01",
      "content-type": "application/json",
    },
    body: JSON.stringify({
      model: MODEL,
      max_tokens: 2500,
      thinking: { type: "adaptive" },
      system: systemPrompt,
      tools: [tool],
      tool_choice: { type: "auto" },
      messages: [{ role: "user", content: userContent }],
    }),
  });
  const aiJson = await aiRes.json();
  if (!aiRes.ok) {
    return json({ error: "ai_error", message: aiJson?.error?.message || "Erreur Claude." }, 502);
  }
  const block = (aiJson?.content || []).find(
    (x: any) => x.type === "tool_use" && x.name === "report_security"
  );
  const out = block?.input || {};
  const severity = ["ok", "info", "warn", "critical"].includes(out.severity) ? out.severity : "info";

  // 4) Coût
  const usage = {
    input_tokens: aiJson?.usage?.input_tokens || 0,
    output_tokens: aiJson?.usage?.output_tokens || 0,
  };
  const price = PRICES[MODEL] || { in: 0, out: 0 };
  const costUsd = (usage.input_tokens / 1e6) * price.in + (usage.output_tokens / 1e6) * price.out;
  const costEur = costUsd / USD_PER_EUR;

  // 5) Enregistrer le check
  const row = {
    trigger_type: triggerType,
    status: "done",
    severity,
    found: out.found || "",
    fixed: out.fixed || "",
    watch_next: out.watch_next || "",
    report_md: out.report_md || "",
    audit_json: audit,
    triggered_by: triggeredBy,
    cost_eur: Number(costEur.toFixed(4)),
  };
  let inserted: any = null;
  try {
    const insRes = await fetch(`${SUPABASE_URL}/rest/v1/security_checks`, {
      method: "POST",
      headers: {
        apikey: SERVICE_ROLE,
        Authorization: `Bearer ${SERVICE_ROLE}`,
        "Content-Type": "application/json",
        Prefer: "return=representation",
      },
      body: JSON.stringify(row),
    });
    const arr = await insRes.json();
    inserted = Array.isArray(arr) ? arr[0] : arr;
  } catch (e) {
    return json({ error: "insert_failed", message: String((e as any)?.message || e) }, 500);
  }

  // 6) Log coût (best-effort)
  try {
    await fetch(`${SUPABASE_URL}/rest/v1/ai_usage_log`, {
      method: "POST",
      headers: {
        apikey: SERVICE_ROLE,
        Authorization: `Bearer ${SERVICE_ROLE}`,
        "Content-Type": "application/json",
        Prefer: "return=minimal",
      },
      body: JSON.stringify({
        feature: "security_check",
        model: MODEL,
        input_tokens: usage.input_tokens,
        output_tokens: usage.output_tokens,
        cost_usd: Number(costUsd.toFixed(6)),
        user_email: triggeredBy,
      }),
    });
  } catch { /* best-effort */ }

  return json({ check: inserted, usage, cost: { usd: costUsd, eur: costEur } });
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  if (req.method !== "POST") return json({ error: "method_not_allowed" }, 405);
  try {
    return await handle(req);
  } catch (e) {
    console.error("security-check unhandled error:", e);
    return json({ error: "unhandled", message: String((e as any)?.message || e) }, 500);
  }
});
