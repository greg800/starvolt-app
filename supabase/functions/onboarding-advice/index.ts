// Edge Function: onboarding-advice
// Génère le message d'accueil personnalisé affiché JUSTE APRÈS le questionnaire
// d'inscription, AVANT de connaître la consommation ENEDIS (collecte encore en cours).
// - Ne dispose QUE de la description du foyer (champs flex_*), aucun chiffre de conso.
// - Explique aussi à quoi sert Starvolt.
// - Tout utilisateur authentifié ; garde-fou anti-abus léger ; logge le coût dans ai_usage_log.
// - Renvoie { text, usage, cost }

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const MODEL = "claude-opus-4-7";
const PRICES: Record<string, { in: number; out: number }> = {
  "claude-opus-4-7": { in: 5, out: 25 },
};
const USD_PER_EUR = 0.92;
const MAX_CALLS_PER_HOUR = 10; // garde-fou par utilisateur

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

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return json({ error: "method_not_allowed" }, 405);

  const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
  const SERVICE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
  const ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY")!;
  const ANTHROPIC_API_KEY = Deno.env.get("ANTHROPIC_API_KEY");

  // --- Auth: tout utilisateur authentifié ---
  const authHeader = req.headers.get("Authorization") || "";
  const token = authHeader.replace(/^Bearer\s+/i, "");
  if (!token) return json({ error: "unauthorized" }, 401);

  const authClient = createClient(SUPABASE_URL, ANON_KEY, {
    global: { headers: { Authorization: `Bearer ${token}` } },
  });
  const { data: userData, error: userErr } = await authClient.auth.getUser(token);
  if (userErr || !userData?.user) return json({ error: "unauthorized" }, 401);
  const userEmail = userData.user.email || userData.user.id;

  if (!ANTHROPIC_API_KEY) {
    return json({ error: "missing_key" }, 500);
  }

  const db = createClient(SUPABASE_URL, SERVICE_KEY);

  // --- Garde-fou anti-abus : max N appels / heure pour cet utilisateur ---
  try {
    const since = new Date(Date.now() - 3600_000).toISOString();
    const { count } = await db
      .from("ai_usage_log")
      .select("id", { count: "exact", head: true })
      .eq("feature", "onboarding_advice")
      .eq("user_email", userEmail)
      .gte("created_at", since);
    if ((count ?? 0) >= MAX_CALLS_PER_HOUR) {
      return json({ error: "rate_limited" }, 429);
    }
  } catch (_) { /* garde-fou best-effort */ }

  // --- Description du foyer fournie par le client (aucun chiffre de conso) ---
  let facts: Record<string, unknown> = {};
  try {
    const body = await req.json();
    facts = body?.facts || {};
  } catch (_) {
    return json({ error: "bad_request", message: "facts manquants" }, 400);
  }
  if (!facts || Object.keys(facts).length === 0) {
    return json({ error: "bad_request", message: "facts vides" }, 400);
  }

  // Prompt système : éditable depuis le menu admin (table ai_prompts), fallback sur le défaut codé.
  const DEFAULT_SYSTEM_PROMPT =
    "Tu écris le tout premier message d'accueil personnalisé d'un nouvel utilisateur de Starvolt, " +
    "une application qui aide les foyers français à comprendre et réduire leur facture d'électricité " +
    "(optimisation du tarif, autoconsommation collective entre voisins, pilotage de la flexibilité, solaire). " +
    "Ce message s'affiche JUSTE APRÈS l'inscription : on récupère en ce moment même, en tâche de fond, " +
    "les données de consommation ENEDIS de l'utilisateur — tu ne les as donc PAS encore. " +
    "Tu ne disposes QUE de la description de son foyer (JSON ci-dessous, réponses au questionnaire d'inscription). " +
    "Tu rédiges en français, en TUTOIEMENT, ton chaleureux, accueillant et concret, 5 à 7 phrases courtes. " +
    "RÈGLES STRICTES : " +
    "1) Utilise UNIQUEMENT les informations fournies ; si une valeur est null/absente, ne l'invente pas et ne la cite pas. " +
    "2) N'invente AUCUN chiffre d'euros, de kWh ou de pourcentage : tu ne connais pas encore sa consommation. Reste qualitatif. " +
    "3) Accueille l'utilisateur, montre que tu as compris son foyer (chauffage, eau chaude, surface, maison/appartement, statut, équipements déjà là), " +
    "et donne 1 ou 2 premières pistes GÉNÉRALES adaptées à ce profil (ex : un chauffage électrique = fort levier de flexibilité ; un locataire en appartement = plutôt tarif + autoconso collective ; un propriétaire de maison = solaire possible). " +
    "4) Explique en 1 ou 2 phrases à quoi sert Starvolt et ce que l'app va lui apporter une fois sa consommation analysée. " +
    "5) Présente tout comme des PISTES, jamais un conseil d'investissement ni financier. " +
    "6) Termine par une phrase qui invite à continuer (tester ses connaissances ou explorer, sa consommation arrive bientôt). " +
    "7) La PREMIÈRE phrase doit être accueillante et percutante. " +
    "Pas de titre, pas de listes à puces, pas de markdown : un paragraphe fluide.";

  let systemPrompt = DEFAULT_SYSTEM_PROMPT;
  try {
    const { data: pr } = await db
      .from("ai_prompts").select("system_prompt").eq("feature", "onboarding_advice").maybeSingle();
    if (pr?.system_prompt) systemPrompt = pr.system_prompt;
  } catch (_) { /* fallback sur le défaut */ }

  // Données métier attachées au prompt (table ai_prompt_files, éditables dans l'admin).
  try {
    const { data: pfiles } = await db
      .from("ai_prompt_files").select("content").eq("feature", "onboarding_advice");
    const extra = (pfiles || []).map((f: { content: string }) => (f.content || "").trim()).filter(Boolean).join("\n\n");
    if (extra) systemPrompt += "\n\n=== DONNÉES MÉTIER DE RÉFÉRENCE (fournies par l'admin) ===\n" + extra;
  } catch (_) { /* best-effort */ }

  const userContent =
    "Voici la description du foyer de ce nouvel utilisateur (JSON). Rédige son message d'accueil.\n\n" +
    JSON.stringify(facts);

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
        max_tokens: 700,
        system: systemPrompt,
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
  const text = (aiJson.content || [])
    .filter((c: { type: string }) => c.type === "text")
    .map((c: { text: string }) => c.text)
    .join("")
    .trim();

  if (!text) return json({ error: "empty_response" }, 502);

  // --- Coût réel ---
  const inTok = aiJson.usage?.input_tokens ?? 0;
  const outTok = aiJson.usage?.output_tokens ?? 0;
  const price = PRICES[MODEL] || { in: 0, out: 0 };
  const costUsd = (inTok / 1e6) * price.in + (outTok / 1e6) * price.out;
  const costEur = costUsd / USD_PER_EUR;

  try {
    await db.from("ai_usage_log").insert({
      feature: "onboarding_advice",
      model: MODEL,
      input_tokens: inTok,
      output_tokens: outTok,
      cost_usd: Number(costUsd.toFixed(6)),
      user_email: userEmail,
    });
  } catch (_) { /* log non bloquant */ }

  return json({
    text,
    usage: { input_tokens: inTok, output_tokens: outTok },
    cost: { usd: Number(costUsd.toFixed(6)), eur: Number(costEur.toFixed(6)) },
  });
});
