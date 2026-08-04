// Edge Function: facture-ocr
// Lit une facture d'électricité (PDF ou image) déposée par le client et en tire
// l'offre + la grille de prix. Décision Greg : UNE SEULE grille (tarifs_electricite),
// alimentée par l'OCR seulement après validation admin OU corroboration par
// 2 factures concordantes.
//
// - Tout utilisateur authentifié (garde-fou 5 appels / heure / utilisateur)
// - Modèle vision + schéma STRICT (structured outputs) : la sortie ne peut pas
//   être du JSON malformé, on n'a donc à valider que la PLAUSIBILITÉ des valeurs.
// - Logge le coût dans ai_usage_log (feature 'facture_ocr') comme les autres services IA.
//
// Body  : { facture_id }
// Retour: { statut, tarif_id?, offre_nom?, provisoire, confiance, extraction_id }

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const MODEL = "claude-opus-4-8";
const PRICES: Record<string, { in: number; out: number }> = {
  "claude-opus-4-8": { in: 5, out: 25 },
};
const MAX_CALLS_PER_HOUR = 5;

// Seuil de confiance sur les PRIX au-dessus duquel on calcule la facture du
// client sur les chiffres lus (spec §4). En dessous : repli + tâche admin.
const SEUIL_PRIX = 0.7;

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

// Champ nullable : structured outputs accepte anyOf, pas les types union.
const nullable = (type: string) => ({ anyOf: [{ type }, { type: "null" }] });

const SCHEMA = {
  type: "object",
  additionalProperties: false,
  required: ["fournisseur", "offre_nom", "type_tarif", "pdl", "puissance_kva", "conso", "prix", "confiance"],
  properties: {
    fournisseur: nullable("string"),
    offre_nom:   nullable("string"),
    type_tarif:  { anyOf: [{ type: "string", enum: ["base", "hp_hc", "tempo", "dynamique", "fixe"] }, { type: "null" }] },
    pdl:         nullable("string"),
    puissance_kva: nullable("number"),
    conso: {
      type: "object", additionalProperties: false,
      required: ["hp_kwh", "hc_kwh", "total_kwh"],
      properties: { hp_kwh: nullable("number"), hc_kwh: nullable("number"), total_kwh: nullable("number") },
    },
    prix: {
      type: "object", additionalProperties: false,
      required: ["abo_mensuel", "base", "hp", "hc"],
      properties: { abo_mensuel: nullable("number"), base: nullable("number"), hp: nullable("number"), hc: nullable("number") },
    },
    confiance: {
      type: "object", additionalProperties: false,
      required: ["offre_nom", "prix", "pdl"],
      properties: { offre_nom: { type: "number" }, prix: { type: "number" }, pdl: { type: "number" } },
    },
  },
};

const DEFAULT_SYSTEM_PROMPT =
  "Tu lis une facture d'électricité française et tu en extrais les données de contrat. " +
  "Tu ne DÉDUIS RIEN : si une information n'est pas lisible sur le document, tu renvoies null pour ce champ. " +
  "Ne convertis pas les unités toi-même au-delà de ce qui est demandé ci-dessous. " +
  "RÈGLES : " +
  "1) Les prix du kWh sont en EUROS par kWh (ex : 0.2016). Si la facture les donne en centimes, divise par 100. " +
  "2) L'abonnement est le montant MENSUEL TTC en euros. Si la facture donne un montant annuel, divise par 12. " +
  "3) Le PDL (ou PRM) fait exactement 14 chiffres. Si tu n'en vois pas un de 14 chiffres, renvoie null. " +
  "4) type_tarif : 'base' = prix unique ; 'hp_hc' = heures pleines / heures creuses ; 'tempo' = jours bleu/blanc/rouge ; " +
  "'dynamique' = prix indexé sur le marché heure par heure ; 'fixe' = prix bloqué sur la durée du contrat. " +
  "5) offre_nom = le nom COMMERCIAL de l'offre (ex : 'Tarif Bleu', 'Classique', 'Online & Green'), pas le nom du fournisseur. " +
  "6) Les champs de confiance vont de 0 à 1 et disent à quel point tu es sûr de ce que tu as lu : " +
  "1 = la valeur est écrite noir sur blanc, 0.5 = tu l'as reconstituée, 0 = tu n'as rien trouvé. " +
  "Sois SÉVÈRE sur 'prix' : ne mets au-dessus de 0.7 que si tu as lu la grille tarifaire explicitement.";

// ── Validations de plausibilité (spec §4) ───────────────────────────────────
// Le schéma garantit la FORME ; ces règles jugent le CONTENU et abaissent la
// confiance quand une valeur est hors du domaine physique du marché français.
function valider(ext: Record<string, any>) {
  const alertes: string[] = [];
  const conf = { ...ext.confiance };

  // PDL : exactement 14 chiffres.
  const pdlBrut = ext.pdl;
  const pdl = (pdlBrut || "").replace(/\D/g, "");
  if (pdl.length !== 14) {
    ext.pdl = null; conf.pdl = 0;
    if (pdlBrut) alertes.push("pdl_invalide"); // quelque chose a été lu, mais ce n'est pas un PDL
  } else ext.pdl = pdl;

  // Prix €/kWh dans une fourchette plausible. Fourchette large (0,05–0,60) :
  // trop serrée, on rejetterait des offres réelles (heures creuses très basses,
  // pointes mobiles très hautes).
  const prixKwh = [ext.prix?.base, ext.prix?.hp, ext.prix?.hc].filter((p) => p != null);
  if (prixKwh.length === 0) { conf.prix = 0; alertes.push("aucun_prix"); }
  else if (prixKwh.some((p: number) => p < 0.05 || p > 0.6)) {
    conf.prix = Math.min(conf.prix, 0.3); alertes.push("prix_hors_fourchette");
  }

  // Abonnement mensuel cohérent avec la puissance souscrite (3 à 36 kVA → ~8 à 60 €).
  const abo = ext.prix?.abo_mensuel;
  if (abo != null && (abo < 3 || abo > 120)) {
    conf.prix = Math.min(conf.prix, 0.4); alertes.push("abo_hors_fourchette");
  }

  // Somme HP+HC cohérente avec le total annoncé (tolérance 5 %).
  const { hp_kwh: hp, hc_kwh: hc, total_kwh: tot } = ext.conso || {};
  if (hp != null && hc != null && tot != null && tot > 0) {
    if (Math.abs(hp + hc - tot) / tot > 0.05) alertes.push("conso_incoherente");
  }

  // Un tarif HP/HC sans prix HC (ou l'inverse) est incomplet : on ne s'y fie pas.
  if (ext.type_tarif === "hp_hc" && (ext.prix?.hp == null || ext.prix?.hc == null)) {
    conf.prix = Math.min(conf.prix, 0.4); alertes.push("hp_hc_incomplet");
  }
  if (ext.type_tarif === "base" && ext.prix?.base == null) {
    conf.prix = Math.min(conf.prix, 0.4); alertes.push("base_sans_prix");
  }

  ext.confiance = conf;
  return alertes;
}

// Clé de corroboration : deux clients qui déposent la même offre doivent
// produire la MÊME chaîne. D'où la normalisation (accents, casse, ponctuation).
function normaliser(s: string | null): string {
  return (s || "").toLowerCase().normalize("NFD").replace(/[\u0300-\u036f]/g, "")
    .replace(/[^a-z0-9]+/g, " ").trim();
}

// Deux grilles sont concordantes si chaque prix commun est à moins de 5 %.
function prixConcordants(a: Record<string, any>, b: Record<string, any>): boolean {
  const paires: [number | null, number | null][] = [
    [a.prix_base, b.prix_base], [a.prix_hp, b.prix_hp],
    [a.prix_hc, b.prix_hc], [a.abo_mensuel, b.abo_mensuel],
  ];
  let compares = 0;
  for (const [x, y] of paires) {
    if (x == null || y == null) continue;
    compares++;
    const ref = Math.max(Math.abs(x), Math.abs(y));
    if (ref > 0 && Math.abs(x - y) / ref > 0.05) return false;
  }
  return compares > 0;
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return json({ error: "method_not_allowed" }, 405);

  const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
  const SERVICE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
  const ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY")!;
  const ANTHROPIC_API_KEY = Deno.env.get("ANTHROPIC_API_KEY");

  // --- Auth : tout utilisateur authentifié ---
  const token = (req.headers.get("Authorization") || "").replace(/^Bearer\s+/i, "");
  if (!token) return json({ error: "unauthorized" }, 401);
  const authClient = createClient(SUPABASE_URL, ANON_KEY, {
    global: { headers: { Authorization: `Bearer ${token}` } },
  });
  const { data: userData, error: userErr } = await authClient.auth.getUser(token);
  if (userErr || !userData?.user) return json({ error: "unauthorized" }, 401);
  const userId = userData.user.id;
  const userEmail = userData.user.email || userId;

  if (!ANTHROPIC_API_KEY) return json({ error: "missing_key" }, 500);

  const db = createClient(SUPABASE_URL, SERVICE_KEY);

  // --- Garde-fou anti-abus ---
  try {
    const since = new Date(Date.now() - 3600_000).toISOString();
    const { count } = await db.from("ai_usage_log")
      .select("id", { count: "exact", head: true })
      .eq("feature", "facture_ocr").eq("user_email", userEmail).gte("created_at", since);
    if ((count ?? 0) >= MAX_CALLS_PER_HOUR) return json({ error: "rate_limited" }, 429);
  } catch (_) { /* best-effort */ }

  let facture_id = "";
  try { facture_id = (await req.json())?.facture_id || ""; } catch (_) { /* traité juste après */ }
  if (!facture_id) return json({ error: "bad_request", message: "facture_id manquant" }, 400);

  // --- La facture doit appartenir à l'appelant (le service_role bypasse la RLS,
  //     donc on vérifie explicitement plutôt que de s'y fier). ---
  const { data: facture } = await db.from("factures").select("*").eq("id", facture_id).maybeSingle();
  if (!facture) return json({ error: "not_found" }, 404);
  if (facture.user_id !== userId) return json({ error: "forbidden" }, 403);
  if (facture.ocr_statut === "ok") return json({ error: "deja_traitee" }, 409);

  // --- Téléchargement du fichier depuis le bucket privé ---
  const { data: blob, error: dlErr } = await db.storage.from("factures").download(facture.storage_key);
  if (dlErr || !blob) {
    await db.from("factures").update({ ocr_statut: "echec", ocr_erreur: "download: " + (dlErr?.message || "vide") }).eq("id", facture_id);
    return json({ error: "download_failed" }, 502);
  }
  const bytes = new Uint8Array(await blob.arrayBuffer());
  // Encodage base64 par tranches : un spread de 10 Mo ferait sauter la pile.
  let bin = "";
  for (let i = 0; i < bytes.length; i += 0x8000) bin += String.fromCharCode(...bytes.subarray(i, i + 0x8000));
  const b64 = btoa(bin);

  const mime = facture.mime || "application/pdf";
  const docBlock = mime === "application/pdf"
    ? { type: "document", source: { type: "base64", media_type: "application/pdf", data: b64 } }
    : { type: "image",    source: { type: "base64", media_type: mime, data: b64 } };

  // Prompt système éditable depuis l'admin (même pattern que bilan/onboarding-advice).
  let systemPrompt = DEFAULT_SYSTEM_PROMPT;
  try {
    const { data: pr } = await db.from("ai_prompts").select("system_prompt").eq("feature", "facture_ocr").maybeSingle();
    if (pr?.system_prompt) systemPrompt = pr.system_prompt;
  } catch (_) { /* fallback sur le défaut */ }

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
        max_tokens: 4000,
        system: systemPrompt,
        thinking: { type: "adaptive" },
        output_config: { effort: "medium", format: { type: "json_schema", schema: SCHEMA } },
        messages: [{
          role: "user",
          content: [docBlock, { type: "text", text: "Extrais les données de contrat de cette facture." }],
        }],
      }),
    });
  } catch (e) {
    await db.from("factures").update({ ocr_statut: "echec", ocr_erreur: String(e) }).eq("id", facture_id);
    return json({ error: "anthropic_fetch", detail: String(e) }, 502);
  }

  if (!aiResp.ok) {
    const t = await aiResp.text();
    await db.from("factures").update({ ocr_statut: "echec", ocr_erreur: t.slice(0, 500) }).eq("id", facture_id);
    return json({ error: "anthropic_error", status: aiResp.status, detail: t }, 502);
  }

  const aiJson = await aiResp.json();

  // --- Coût réel, loggé comme tous les autres services IA ---
  const inTok = aiJson.usage?.input_tokens ?? 0;
  const outTok = aiJson.usage?.output_tokens ?? 0;
  const price = PRICES[MODEL] || { in: 0, out: 0 };
  const costUsd = (inTok / 1e6) * price.in + (outTok / 1e6) * price.out;
  try {
    await db.from("ai_usage_log").insert({
      feature: "facture_ocr", model: MODEL, input_tokens: inTok, output_tokens: outTok,
      cost_usd: Number(costUsd.toFixed(6)), user_email: userEmail,
    });
  } catch (_) { /* log non bloquant */ }

  // Le modèle peut refuser (classifieurs de sécurité) : content vide, à traiter
  // comme un échec de lecture et non comme un crash.
  if (aiJson.stop_reason === "refusal") {
    await db.from("factures").update({ ocr_statut: "echec", ocr_erreur: "refus_modele" }).eq("id", facture_id);
    return json({ error: "refus_modele" }, 422);
  }

  const rawText = (aiJson.content || [])
    .filter((c: { type: string }) => c.type === "text")
    .map((c: { text: string }) => c.text).join("").trim();
  let ext: Record<string, any>;
  try { ext = JSON.parse(rawText); } catch (_) {
    await db.from("factures").update({ ocr_statut: "echec", ocr_erreur: "json_illisible" }).eq("id", facture_id);
    return json({ error: "json_illisible" }, 502);
  }

  const alertes = valider(ext);
  const confPrix = ext.confiance?.prix ?? 0;
  const cleOffre = normaliser(ext.fournisseur) + "|" + normaliser(ext.offre_nom);

  // --- 1. L'offre est-elle DÉJÀ au catalogue vérifié ? ─────────────────────
  const { data: catalogue } = await db.from("tarifs_electricite")
    .select("id,nom,fournisseur,statut").eq("statut", "verifie");
  const cible = normaliser(`${ext.fournisseur || ""} ${ext.offre_nom || ""}`);
  const matched = (catalogue || []).find((t: Record<string, any>) => {
    const n = normaliser(`${t.fournisseur || ""} ${t.nom || ""}`);
    // Rapprochement conservateur : inclusion stricte dans un sens ou l'autre.
    return n.length > 3 && cible.length > 3 && (n.includes(cible) || cible.includes(n));
  });

  const extractionRow: Record<string, any> = {
    facture_id, user_id: userId, site_id: facture.site_id,
    fournisseur: ext.fournisseur, offre_nom: ext.offre_nom, type_tarif: ext.type_tarif,
    pdl: ext.pdl, puissance_kva: ext.puissance_kva,
    conso_hp_kwh: ext.conso?.hp_kwh, conso_hc_kwh: ext.conso?.hc_kwh, conso_totale_kwh: ext.conso?.total_kwh,
    abo_mensuel: ext.prix?.abo_mensuel, prix_base: ext.prix?.base,
    prix_hp: ext.prix?.hp, prix_hc: ext.prix?.hc,
    confiance: { ...ext.confiance, alertes },
    cle_offre: cleOffre,
  };

  if (matched) {
    // Offre reconnue → on rattache le site au tarif VÉRIFIÉ. {eco} fiable, fin.
    extractionRow.tarif_id = matched.id;
    extractionRow.statut = "promu";
    const { data: exRow } = await db.from("factures_extractions").insert(extractionRow).select("id").single();
    if (facture.site_id) await db.from("sites").update({ tarif_id: matched.id }).eq("id", facture.site_id);
    await db.from("factures").update({ ocr_statut: "ok" }).eq("id", facture_id);
    return json({
      statut: "catalogue", tarif_id: matched.id, offre_nom: matched.nom,
      provisoire: false, confiance: ext.confiance, extraction_id: exRow?.id, alertes,
    });
  }

  // --- 2. Offre inconnue ────────────────────────────────────────────────────
  // Prix lus avec confiance → on crée un BROUILLON de tarif (hors catalogue
  // public) et on y rattache le site : sa facture est calculée sur ses vrais
  // chiffres, marquée provisoire, en attendant validation ou corroboration.
  let tarifId: string | null = null;
  let provisoire = true;

  if (confPrix >= SEUIL_PRIX) {
    const prixHp = ext.prix?.hp ?? ext.prix?.base ?? null;
    const { data: brouillon } = await db.from("tarifs_electricite").insert({
      nom: (ext.offre_nom || "Offre lue sur facture").slice(0, 120),
      fournisseur: ext.fournisseur,
      abo_annuel: ext.prix?.abo_mensuel != null ? Number((ext.prix.abo_mensuel * 12).toFixed(2)) : null,
      prix_hp: prixHp,
      prix_hc: ext.prix?.hc ?? null,
      type_tarif: ext.type_tarif || "fixe",
      puissance_kva: ext.puissance_kva ?? null,
      statut: "brouillon",
      source: "ocr",
    }).select("id").single();
    tarifId = brouillon?.id ?? null;
    extractionRow.tarif_id = tarifId;
    if (tarifId && facture.site_id) await db.from("sites").update({ tarif_id: tarifId }).eq("id", facture.site_id);
  }

  const { data: exRow } = await db.from("factures_extractions").insert(extractionRow).select("id").single();
  await db.from("factures").update({ ocr_statut: "ok" }).eq("id", facture_id);

  // --- 3. Corroboration : 2 extractions concordantes de clients DIFFÉRENTS ──
  // Les doublons ne sont pas un bug, ils sont le mécanisme d'auto-validation.
  let promue = false;
  if (tarifId && confPrix >= SEUIL_PRIX) {
    const { data: jumelles } = await db.from("factures_extractions")
      .select("id,user_id,tarif_id,abo_mensuel,prix_base,prix_hp,prix_hc")
      .eq("cle_offre", cleOffre).eq("statut", "brouillon").neq("user_id", userId);
    const concordante = (jumelles || []).find((j: Record<string, any>) => prixConcordants(j, extractionRow));
    if (concordante) {
      await db.from("tarifs_electricite").update({
        statut: "verifie", verifie_le: new Date().toISOString(), verifie_par: "system:corroboration",
      }).eq("id", tarifId);
      // Les deux extractions sont résolues, et le brouillon de la première est
      // retiré : les deux sites pointent désormais sur le tarif vérifié.
      await db.from("factures_extractions").update({
        statut: "promu", resolu_le: new Date().toISOString(), resolu_par: "system:corroboration",
      }).in("id", [exRow?.id, concordante.id].filter(Boolean));
      if (concordante.tarif_id && concordante.tarif_id !== tarifId) {
        await db.from("sites").update({ tarif_id: tarifId }).eq("tarif_id", concordante.tarif_id);
        await db.from("tarifs_electricite").delete().eq("id", concordante.tarif_id).eq("statut", "brouillon");
      }
      provisoire = false;
      promue = true;
    }
  }

  return json({
    statut: tarifId ? (promue ? "corrobore" : "brouillon") : "illisible",
    tarif_id: tarifId, offre_nom: ext.offre_nom, fournisseur: ext.fournisseur,
    provisoire, confiance: ext.confiance, extraction_id: exRow?.id, alertes,
  });
});
