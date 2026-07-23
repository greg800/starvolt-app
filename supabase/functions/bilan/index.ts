// Edge Function: bilan
// Génère "Ton bilan en clair" : une synthèse personnalisée (français, tutoiement)
// à partir de chiffres DÉJÀ calculés côté client (l'IA ne calcule rien).
// - Tout utilisateur authentifié
// - Garde-fou anti-abus léger (max N appels / heure / utilisateur)
// - Logge le coût dans ai_usage_log (feature 'bilan')
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

// Fallback embarqué des données métier DPE si le fichier servi par l'app est injoignable.
// DOIT rester identique à /bilan-dpe-reference.md (source de vérité, éditable dans l'admin).
const DPE_REFERENCE_FALLBACK = `# Données métier — Estimation DPE (non contractuelle)

Périmètre : logements chauffés à l'électricité (maison individuelle ou appartement).

## Table de travail
La classe DPE estimée est la première dont le seuil haut est >= à la conso surfacique (kWh/m2/an).

| Classe | Seuil haut (kWh/m2/an) | Part chauffage | % maisons qui consomment moins | % appartements qui consomment moins |
|:---:|:---:|:---:|:---:|:---:|
| A | <= 22 | 30% | 0% | 0% |
| B | <= 39 | 40% | 2% | 4% |
| C | <= 63 | 50% | 10% | 18% |
| D | <= 93 | 60% | 30% | 45% |
| E | <= 126 | 65% | 58% | 71% |
| F | <= 163 | 70% | 80% | 87% |
| G | > 163 | 75% | 92% | 95% |

## Mode d'emploi
1. Conso surfacique = conso annuelle (kWh) / surface (m2). Surface inconnue : milieu de tranche (< 70 m2 -> 50 ; 70-150 m2 -> 110 ; > 150 m2 -> 180).
2. Classe DPE = première dont le seuil haut est >= conso surfacique.
3. Colonne selon habitat (maison / appartement).
4. "% qui consomment moins que vous" : lire la case (classe x habitat).
5. Toujours "estimation non contractuelle".

## Exemple
5 MWh, maison de 100 m2 -> 50 kWh/m2 -> classe C -> 10% des maisons consomment moins.
Phrase : "Vous consommez 50 kWh/m2 = notre estimation (non contractuelle) DPE C, 10% des maisons consomment moins que vous."

## Consignes
- Inclure la phrase seulement si surface (ou tranche) ET conso annuelle connues ; sinon ne pas l'inventer.
- Jamais présenté comme un DPE officiel ; rester bienveillant (potentiel d'amélioration).`;

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
      .eq("feature", "bilan")
      .eq("user_email", userEmail)
      .gte("created_at", since);
    if ((count ?? 0) >= MAX_CALLS_PER_HOUR) {
      return json({ error: "rate_limited" }, 429);
    }
  } catch (_) { /* garde-fou best-effort */ }

  // --- Facts pré-calculés fournis par le client ---
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
    "Tu écris 'Ton bilan en clair' pour un utilisateur de Starvolt, une app qui aide les foyers français à réduire leur facture d'électricité. " +
    "On te donne des CHIFFRES DÉJÀ CALCULÉS (JSON). Tu ne calcules RIEN, tu ne réinventes AUCUN chiffre. " +
    "Tu rédiges en français, en TUTOIEMENT, 5 à 7 phrases courtes, ton chaleureux et concret. " +
    "RÈGLES STRICTES : " +
    "1) Utilise UNIQUEMENT les chiffres fournis ; si une valeur est null/absente, ne la cite pas. " +
    "2) Ne donne JAMAIS de conseil d'investissement ni financier ; tu EXPLIQUES, tu ne recommandes pas d'investir. " +
    "3) Explique d'abord le profil de consommation (quand l'énergie est consommée, saisonnalité), puis la facture, " +
    "puis quel levier semble le plus prometteur POUR CET UTILISATEUR (leviers_classement = leviers triés du plus au moins prometteur ; le PREMIER est le plus pertinent). " +
    "Ne cite AUCUN montant d'économies en euros pour les leviers (ces chiffres ne te sont pas fournis) ; reste qualitatif et invite à utiliser le simulateur pour les chiffres précis. " +
    "4) Présente le levier gagnant comme une PISTE, pas un ordre : termine par une phrase qui rappelle que 'le choix te revient'. " +
    "5) La PREMIÈRE phrase doit être la plus percutante (seules les 4 premières lignes seront visibles par défaut). " +
    "Pas de titre, pas de listes à puces, pas de markdown : un paragraphe fluide.";

  let systemPrompt = DEFAULT_SYSTEM_PROMPT;
  try {
    const { data: pr } = await db
      .from("ai_prompts").select("system_prompt").eq("feature", "bilan").maybeSingle();
    if (pr?.system_prompt) systemPrompt = pr.system_prompt;
  } catch (_) { /* fallback sur le défaut */ }

  // --- Données métier DPE : appendues au prompt système (estimation non contractuelle). ---
  //     Source de vérité = le fichier servi par l'app (éditable + téléchargeable dans l'admin,
  //     carte du prompt « Ton bilan en clair »). Récupéré en direct ; fallback sur DPE_REFERENCE_FALLBACK
  //     si l'URL est injoignable. GARDER CES DEUX SOURCES SYNCHRONES.
  try {
    let refMd = "";
    try {
      const r = await fetch("https://app.starvolt.fr/bilan-dpe-reference.md", {
        signal: AbortSignal.timeout(3000),
      });
      if (r.ok) refMd = (await r.text()).trim();
    } catch (_) { /* on retombe sur le fallback embarqué */ }
    if (!refMd) refMd = DPE_REFERENCE_FALLBACK;
    if (refMd) {
      systemPrompt +=
        "\n\n=== DONNÉES MÉTIER DE RÉFÉRENCE (estimation DPE non contractuelle) ===\n" +
        "Utilise ces données pour, si la surface (ou sa tranche) et la consommation annuelle " +
        "sont connues, ajouter au bilan une phrase d'estimation DPE non contractuelle, " +
        "en suivant STRICTEMENT le mode d'emploi ci-dessous.\n\n" + refMd;
    }
  } catch (_) { /* best-effort : le bilan fonctionne sans la référence */ }

  const userContent =
    "Voici les chiffres de cet utilisateur (JSON). Rédige son bilan en clair.\n\n" +
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
      feature: "bilan",
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
