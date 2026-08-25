// Edge Function: quiz-feedback
// Génère le retour personnalisé affiché À LA FIN de l'auto-évaluation d'accueil.
// L'IA dispose de :
//  - les réponses de l'utilisateur (bonnes/mauvaises + ce qu'il a coché),
//  - le CATALOGUE complet du module Comprendre (tous les thèmes → sujets →
//    questions), lu côté serveur via service_role, pour recommander des sujets
//    à creuser.
// - Tout utilisateur authentifié ; garde-fou anti-abus léger ; logge ai_usage_log.
// - Renvoie { text, usage, cost }

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const MODEL = "claude-opus-4-7";
const PRICES: Record<string, { in: number; out: number }> = {
  "claude-opus-4-7": { in: 5, out: 25 },
};
const USD_PER_EUR = 0.92;
const MAX_CALLS_PER_HOUR = 10;

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

  const authHeader = req.headers.get("Authorization") || "";
  const token = authHeader.replace(/^Bearer\s+/i, "");
  if (!token) return json({ error: "unauthorized" }, 401);

  const authClient = createClient(SUPABASE_URL, ANON_KEY, {
    global: { headers: { Authorization: `Bearer ${token}` } },
  });
  const { data: userData, error: userErr } = await authClient.auth.getUser(token);
  if (userErr || !userData?.user) return json({ error: "unauthorized" }, 401);
  const userEmail = userData.user.email || userData.user.id;

  if (!ANTHROPIC_API_KEY) return json({ error: "missing_key" }, 500);

  const db = createClient(SUPABASE_URL, SERVICE_KEY);

  // --- Garde-fou anti-abus ---
  try {
    const since = new Date(Date.now() - 3600_000).toISOString();
    const { count } = await db
      .from("ai_usage_log")
      .select("id", { count: "exact", head: true })
      .eq("feature", "quiz_feedback")
      .eq("user_email", userEmail)
      .gte("created_at", since);
    if ((count ?? 0) >= MAX_CALLS_PER_HOUR) return json({ error: "rate_limited" }, 429);
  } catch (_) { /* best-effort */ }

  // --- Réponses de l'utilisateur (fournies par le client) ---
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

  // --- Catalogue complet du module Comprendre (lu côté serveur) ---
  //     Structure compacte : thèmes → sujets → énoncés de questions.
  let catalogue: Array<{ theme: string; sujets: Array<{ sujet: string; questions: string[] }> }> = [];
  try {
    const [{ data: groups }, { data: subjects }, { data: questions }] = await Promise.all([
      db.from("learn_groups").select("id,title,ordre").order("ordre").limit(200),
      db.from("learn_subjects").select("id,title,group_id,ordre").order("ordre").limit(200),
      db.from("learn_questions").select("id,question,subject_id,ordre").order("ordre").limit(200),
    ]);
    const qBySubject: Record<string, string[]> = {};
    (questions || []).forEach((q: { question: string; subject_id: string }) => {
      (qBySubject[q.subject_id] ||= []).push(q.question);
    });
    const subjByGroup: Record<string, Array<{ sujet: string; questions: string[] }>> = {};
    (subjects || []).forEach((s: { id: string; title: string; group_id: string }) => {
      const qs = qBySubject[s.id] || [];
      if (qs.length === 0) return; // sujets sans quiz : hors catalogue
      (subjByGroup[s.group_id] ||= []).push({ sujet: s.title, questions: qs });
    });
    catalogue = (groups || [])
      .map((g: { id: string; title: string }) => ({ theme: g.title, sujets: subjByGroup[g.id] || [] }))
      .filter((t) => t.sujets.length > 0);
  } catch (_) { /* catalogue best-effort */ }

  // --- Prompt système (éditable via admin ai_prompts) ---
  const DEFAULT_SYSTEM_PROMPT =
    "Tu écris le retour personnalisé affiché à la fin de l'auto-évaluation d'accueil d'un nouvel utilisateur de Starvolt, " +
    "une application qui aide les foyers français à comprendre et réduire leur facture d'électricité. " +
    "On te donne : 1) le score et le DÉTAIL des réponses de l'utilisateur à un petit quiz (chaque question, ce qu'il a répondu, la/les bonne(s) réponse(s), et s'il a eu juste) ; " +
    "2) le CATALOGUE complet du module 'Comprendre' (thèmes → sujets → questions) pour l'orienter. " +
    "Tu rédiges en français, en TUTOIEMENT, ton chaleureux, encourageant et concret, 6 à 9 phrases courtes. " +
    "RÈGLES STRICTES : " +
    "1) Commence par féliciter/situer le résultat global sans le dramatiser (jamais culpabilisant, même si le score est faible). " +
    "2) Commente les BONNES réponses (valorise ce qui est acquis) ET les ERREURS (explique brièvement et gentiment la bonne notion, sans jargon). Regroupe, ne fais pas une liste question par question mécanique. " +
    "3) Recommande 1 à 3 SUJETS PRÉCIS à creuser dans le module Comprendre, en citant leurs titres EXACTS tels qu'ils apparaissent dans le catalogue, choisis en lien avec les erreurs ou les thèmes où l'utilisateur gagnerait à progresser. " +
    "4) N'invente AUCUN chiffre, fait ou sujet qui ne soit pas fourni. N'utilise que les titres de sujets présents dans le catalogue. " +
    "5) Aucun conseil d'investissement ni financier : tu expliques et tu orientes. " +
    "6) Termine par une phrase qui donne envie d'explorer le module Comprendre. " +
    "Pas de titre, pas de listes à puces, pas de markdown : un paragraphe fluide (tu peux nommer les sujets entre guillemets).";

  let systemPrompt = DEFAULT_SYSTEM_PROMPT;
  try {
    const { data: pr } = await db
      .from("ai_prompts").select("system_prompt").eq("feature", "quiz_feedback").maybeSingle();
    if (pr?.system_prompt) systemPrompt = pr.system_prompt;
  } catch (_) { /* fallback */ }

  // Données métier attachées au prompt (table ai_prompt_files, éditables dans l'admin).
  try {
    const { data: pfiles } = await db
      .from("ai_prompt_files").select("content").eq("feature", "quiz_feedback");
    const extra = (pfiles || []).map((f: { content: string }) => (f.content || "").trim()).filter(Boolean).join("\n\n");
    if (extra) systemPrompt += "\n\n=== DONNÉES MÉTIER DE RÉFÉRENCE (fournies par l'admin) ===\n" + extra;
  } catch (_) { /* best-effort */ }

  const userContent =
    "RÉPONSES DE L'UTILISATEUR (JSON) :\n" + JSON.stringify(facts) +
    "\n\nCATALOGUE DU MODULE COMPRENDRE (thèmes → sujets → questions, JSON) :\n" +
    JSON.stringify(catalogue) +
    "\n\nRédige son retour personnalisé.";

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
        max_tokens: 900,
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

  const inTok = aiJson.usage?.input_tokens ?? 0;
  const outTok = aiJson.usage?.output_tokens ?? 0;
  const price = PRICES[MODEL] || { in: 0, out: 0 };
  const costUsd = (inTok / 1e6) * price.in + (outTok / 1e6) * price.out;
  const costEur = costUsd / USD_PER_EUR;

  try {
    await db.from("ai_usage_log").insert({
      feature: "quiz_feedback",
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
