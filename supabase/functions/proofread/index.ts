// Edge Function: proofread
// Corrige orthographe + grammaire du contenu "Comprendre" (Starvolt).
// - Admin-only (rôle profiles.role ∈ {admin, superadmin})
// - Lit le contenu via service_role
// - Appelle Claude pour proposer des corrections (ne PAS auto-appliquer)
// - Renvoie { corrections: [{table, id, field, label, before, after, reason}] }

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const MODEL = "claude-opus-4-7";
// Tarifs Anthropic $ / million de tokens (mettre à jour si les prix changent)
const PRICES: Record<string, { in: number; out: number }> = {
  "claude-opus-4-7": { in: 5, out: 25 },
};
const USD_PER_EUR = 0.92; // approximatif, pour affichage

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

// Champs texte à relire
const SOURCES: { table: string; fields: string[] }[] = [
  { table: "learn_groups", fields: ["title", "description"] },
  { table: "learn_subjects", fields: ["title", "content"] },
  { table: "learn_questions", fields: ["question"] },
  { table: "learn_choices", fields: ["text"] },
];

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return json({ error: "method_not_allowed" }, 405);

  const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
  const SERVICE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
  const ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY")!;
  const ANTHROPIC_API_KEY = Deno.env.get("ANTHROPIC_API_KEY");

  // --- Auth: vérifier que l'appelant a un rôle admin (AVANT toute autre logique) ---
  const authHeader = req.headers.get("Authorization") || "";
  const token = authHeader.replace(/^Bearer\s+/i, "");
  if (!token) return json({ error: "unauthorized" }, 401);

  const authClient = createClient(SUPABASE_URL, ANON_KEY, {
    global: { headers: { Authorization: `Bearer ${token}` } },
  });
  const { data: userData, error: userErr } = await authClient.auth.getUser(token);
  if (userErr || !userData?.user) {
    return json({ error: "unauthorized" }, 401);
  }
  // Rôle basé sur profiles (lecture de SA PROPRE ligne, autorisée par RLS auth.uid()=id)
  const { data: prof } = await authClient
    .from("profiles").select("role").eq("id", userData.user.id).maybeSingle();
  if (!prof || !["admin", "superadmin"].includes(prof.role)) {
    return json({ error: "forbidden" }, 403);
  }

  if (!ANTHROPIC_API_KEY) {
    return json(
      { error: "missing_key", message: "ANTHROPIC_API_KEY non configurée dans les secrets de la fonction." },
      500,
    );
  }

  // --- Lecture du contenu (service role, bypass RLS) ---
  const db = createClient(SUPABASE_URL, SERVICE_KEY);
  const items: { key: string; table: string; id: string; field: string; text: string }[] = [];
  for (const src of SOURCES) {
    const cols = ["id", ...src.fields].join(",");
    const { data, error } = await db.from(src.table).select(cols);
    if (error) return json({ error: "db_read", detail: error.message, table: src.table }, 500);
    for (const row of (data || []) as Record<string, unknown>[]) {
      for (const f of src.fields) {
        const v = row[f];
        if (typeof v === "string" && v.trim().length > 0) {
          items.push({
            key: `${src.table}|${row.id}|${f}`,
            table: src.table,
            id: String(row.id),
            field: f,
            text: v,
          });
        }
      }
    }
  }

  if (items.length === 0) return json({ corrections: [], scanned: 0 });

  // --- Appel Claude (proofreading strict, structuré) ---
  const payloadItems = items.map((it) => ({ key: it.key, text: it.text }));

  // Prompt système : éditable depuis le menu admin (table ai_prompts), fallback sur le défaut codé.
  const DEFAULT_SYSTEM_PROMPT =
    "Tu es correcteur orthographique et grammatical de français. " +
    "On te donne une liste d'items {key, text} provenant d'une application pédagogique sur l'énergie. " +
    "Pour CHAQUE item, corrige UNIQUEMENT les fautes d'orthographe, de grammaire, d'accord, de conjugaison, " +
    "d'apostrophes/tirets/typographie évidente. " +
    "RÈGLES STRICTES : " +
    "1) Ne reformule JAMAIS, ne change pas le style ni le sens ni l'ordre des phrases. " +
    "2) Ne touche pas aux termes techniques, marques (Starvolt, TotalEnergies...), unités, chiffres. " +
    "3) Conserve la ponctuation et la mise en forme (retours à la ligne, listes) sauf faute évidente. " +
    "4) Si un texte est déjà correct, ne le renvoie PAS dans corrections. " +
    "Renvoie uniquement les items modifiés, avec le texte corrigé complet dans 'after'.";

  let systemPrompt = DEFAULT_SYSTEM_PROMPT;
  try {
    const { data: pr } = await db
      .from("ai_prompts").select("system_prompt").eq("feature", "proofread").maybeSingle();
    if (pr?.system_prompt) systemPrompt = pr.system_prompt;
  } catch (_) { /* fallback sur le défaut */ }

  const tool = {
    name: "report_corrections",
    description: "Renvoie la liste des corrections orthographiques/grammaticales.",
    input_schema: {
      type: "object",
      properties: {
        corrections: {
          type: "array",
          items: {
            type: "object",
            properties: {
              key: { type: "string" },
              after: { type: "string" },
              reason: { type: "string", description: "Brève raison (ex: accord, conjugaison, apostrophe)." },
            },
            required: ["key", "after"],
            additionalProperties: false,
          },
        },
      },
      required: ["corrections"],
      additionalProperties: false,
    },
  };

  const userContent =
    "Voici les items à relire (JSON). Corrige et appelle l'outil report_corrections.\n\n" +
    JSON.stringify(payloadItems);

  let aiResp: Response;
  try {
    aiResp = await fetch("https://api.anthropic.com/v1/messages", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "x-api-key": ANTHROPIC_API_KEY,
        "anthropic-version": "2023-06-01",
      },
      body: JSON.stringify({
        model: MODEL,
        max_tokens: 16000,
        system: systemPrompt,
        tools: [tool],
        tool_choice: { type: "tool", name: "report_corrections" },
        messages: [{ role: "user", content: userContent }],
      }),
    });
  } catch (e) {
    return json({ error: "anthropic_fetch", detail: String(e) }, 502);
  }

  if (!aiResp.ok) {
    const t = await aiResp.text();
    return json({ error: "anthropic_error", status: aiResp.status, detail: t }, 502);
  }

  const aiJson = await aiResp.json();
  const toolUse = (aiJson.content || []).find((c: { type: string }) => c.type === "tool_use");
  const rawCorrections: { key: string; after: string; reason?: string }[] =
    toolUse?.input?.corrections || [];

  // --- Coût réel à partir du usage renvoyé par Anthropic ---
  const inTok = aiJson.usage?.input_tokens ?? 0;
  const outTok = aiJson.usage?.output_tokens ?? 0;
  const price = PRICES[MODEL] || { in: 0, out: 0 };
  const costUsd = (inTok / 1e6) * price.in + (outTok / 1e6) * price.out;
  const costEur = costUsd / USD_PER_EUR;

  // Journaliser (service role, bypass RLS). Best-effort : ne bloque pas la réponse.
  try {
    await db.from("ai_usage_log").insert({
      feature: "proofread",
      model: MODEL,
      input_tokens: inTok,
      output_tokens: outTok,
      cost_usd: Number(costUsd.toFixed(6)),
      user_email: userData.user.email,
    });
  } catch (_) { /* log non bloquant */ }

  // --- Reconstruire avant/après, filtrer les non-changements ---
  const byKey = new Map(items.map((it) => [it.key, it]));
  const corrections = [];
  for (const c of rawCorrections) {
    const it = byKey.get(c.key);
    if (!it) continue;
    if (typeof c.after !== "string") continue;
    if (c.after === it.text) continue; // pas de vrai changement
    corrections.push({
      table: it.table,
      id: it.id,
      field: it.field,
      label: it.text.slice(0, 60),
      before: it.text,
      after: c.after,
      reason: c.reason || "",
    });
  }

  return json({
    corrections,
    scanned: items.length,
    usage: { input_tokens: inTok, output_tokens: outTok },
    cost: { usd: Number(costUsd.toFixed(6)), eur: Number(costEur.toFixed(6)) },
  });
});
