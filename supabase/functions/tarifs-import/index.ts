// Edge Function: tarifs-import
// Importe une grille tarifaire depuis un PDF du comparateur Énergie-Info
// (médiateur national de l'énergie) et met à jour la table tarifs_electricite.
//
// POURQUOI DE LA VISION ET PAS UN PARSEUR DE TEXTE : le nom du FOURNISSEUR
// n'existe pas dans la couche texte du PDF — il n'est porté que par le logo
// (image) et le numéro de téléphone. Or la règle de remplacement demandée est
// « même fournisseur ET même offre ». Un parseur textuel produirait des offres
// sans fournisseur, donc impossibles à rapprocher de l'existant.
//
// Règles appliquées (demande Greg) :
//   - même fournisseur + même nom d'offre  → l'ancienne grille est ARCHIVÉE
//     (actif=false, date_fin) et la nouvelle prend le relais (date_debut).
//     Les sites qui pointaient sur l'ancienne basculent sur la nouvelle.
//   - offre incomplète ou structure non gérée → NON importée, avec le motif.
//
// Admin uniquement. Body : { fichier_nom, pdf_base64 }
// Retour : { bilan: { importes[], remplaces[], rejetes[] }, cout }

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const MODEL = "claude-opus-4-8";
const PRICES: Record<string, { in: number; out: number }> = {
  "claude-opus-4-8": { in: 5, out: 25 },
};

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};
const json = (b: unknown, s = 200) =>
  new Response(JSON.stringify(b), { status: s, headers: { ...corsHeaders, "Content-Type": "application/json" } });

const nullable = (type: string) => ({ anyOf: [{ type }, { type: "null" }] });

const SCHEMA = {
  type: "object",
  additionalProperties: false,
  required: ["date_recherche", "puissance_kva", "offres"],
  properties: {
    date_recherche: nullable("string"),   // "Résultat de la recherche effectuée le JJ/MM/AAAA"
    puissance_kva: nullable("number"),    // profil du comparatif (ex. 9 kVA)
    offres: {
      type: "array",
      items: {
        type: "object",
        additionalProperties: false,
        required: ["fournisseur", "offre", "type_tarif", "abo_annuel_ttc", "prix_base_ttc", "prix_hp_ttc", "prix_hc_ttc", "confiance_fournisseur"],
        properties: {
          fournisseur:  nullable("string"),
          offre:        nullable("string"),
          type_tarif:   { anyOf: [{ type: "string", enum: ["base", "hp_hc", "autre"] }, { type: "null" }] },
          abo_annuel_ttc: nullable("number"),
          prix_base_ttc:  nullable("number"),
          prix_hp_ttc:    nullable("number"),
          prix_hc_ttc:    nullable("number"),
          confiance_fournisseur: { type: "number" },
        },
      },
    },
  },
};

const SYSTEM = `Tu lis un PDF du comparateur d'offres Énergie-Info (médiateur national de l'énergie) et tu en extrais la liste COMPLÈTE des offres d'électricité, page par page.

CONTEXTE INDISPENSABLE : le nom du fournisseur n'est PAS écrit en toutes lettres à côté de chaque offre. Il est porté par le LOGO affiché dans le bloc de l'offre, et parfois par le numéro de téléphone (ex : 3404 = EDF). Tu dois REGARDER le logo pour identifier le fournisseur. Si tu n'es pas sûr du fournisseur, renvoie null plutôt qu'un nom approximatif — une erreur de fournisseur ferait écraser la grille d'un concurrent.

Pour CHAQUE offre du document :
- fournisseur : le nom commercial du fournisseur, lu sur le logo (EDF, TotalEnergies, Engie, Octopus Energy, Mint Énergie, Primeo Energie, Alterna, Ekwateur, Ohm Énergie, La Bellenergie, Gaz de Bordeaux, Alpiq…).
- offre : le nom de l'offre tel qu'écrit en majuscules (ex : "ZEN FIXE", "VERT ÉLECTRIQUE", "OFFRE FIXE CONFORT+").
- type_tarif : "base" si un seul prix du kWh est donné ; "hp_hc" si le document donne un prix Heures Pleines ET un prix Heures Creuses ; "autre" dans TOUS les autres cas (offres week-end, "Heures Semaine / Heures Week-End / Heures 1 Jour", tempo, offres à paliers…).
- abo_annuel_ttc : le "Prix de l'abonnement" en euros TTC, tel qu'affiché. Le comparatif porte sur 12 mois : c'est donc un montant ANNUEL, ne le divise pas.
- prix_base_ttc : le prix du kWh en €/kWh TTC quand type_tarif = "base", sinon null.
- prix_hp_ttc / prix_hc_ttc : les prix Heures Pleines / Heures Creuses en €/kWh TTC quand type_tarif = "hp_hc", sinon null.
- confiance_fournisseur : de 0 à 1, à quel point tu es sûr d'avoir bien identifié le fournisseur d'après son logo. Sois SÉVÈRE : 1 seulement si le logo est parfaitement reconnaissable.

RÈGLES :
1) N'invente RIEN. Un champ que tu ne lis pas explicitement vaut null.
2) N'extrapole pas d'une offre à l'autre : chaque bloc a ses propres prix.
3) Ne convertis aucune unité. Les prix du kWh sont déjà en euros (ex : 0,1661).
4) Ignore l'encadré de profil en haut (commune, consommation, distributeur) : ce n'est pas une offre. Ignore aussi les totaux annuels estimés ("Total : 1 080 €") : ce ne sont pas des prix unitaires.
5) Renvoie TOUTES les offres du document, y compris celles de type "autre".`;

// Normalisation utilisée pour rapprocher une offre importée d'une offre connue.
const norm = (s: string | null) =>
  (s || "").toLowerCase().normalize("NFD").replace(/[̀-ͯ]/g, "")
    .replace(/[^a-z0-9]+/g, " ").trim();

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return json({ error: "method_not_allowed" }, 405);

  const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
  const SERVICE_KEY  = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
  const ANON_KEY     = Deno.env.get("SUPABASE_ANON_KEY")!;
  const ANTHROPIC_API_KEY = Deno.env.get("ANTHROPIC_API_KEY");

  const token = (req.headers.get("Authorization") || "").replace(/^Bearer\s+/i, "");
  if (!token) return json({ error: "unauthorized" }, 401);
  const authClient = createClient(SUPABASE_URL, ANON_KEY, { global: { headers: { Authorization: `Bearer ${token}` } } });
  const { data: userData, error: userErr } = await authClient.auth.getUser(token);
  if (userErr || !userData?.user) return json({ error: "unauthorized" }, 401);

  const db = createClient(SUPABASE_URL, SERVICE_KEY);
  const { data: prof } = await db.from("profiles").select("role").eq("id", userData.user.id).maybeSingle();
  if (!prof || !["admin", "superadmin"].includes(prof.role)) return json({ error: "forbidden" }, 403);
  const adminEmail = userData.user.email || "admin";
  if (!ANTHROPIC_API_KEY) return json({ error: "missing_key" }, 500);

  let body: Record<string, any> = {};
  try { body = await req.json(); } catch (_) { return json({ error: "bad_request" }, 400); }
  const { fichier_nom = "pdf", pdf_base64 } = body;
  if (!pdf_base64) return json({ error: "bad_request", message: "pdf_base64 manquant" }, 400);

  // ── Lecture du document ────────────────────────────────────────────────────
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
        system: SYSTEM,
        thinking: { type: "adaptive" },
        output_config: { effort: "medium", format: { type: "json_schema", schema: SCHEMA } },
        messages: [{
          role: "user",
          content: [
            { type: "document", source: { type: "base64", media_type: "application/pdf", data: pdf_base64 } },
            { type: "text", text: "Extrais toutes les offres de ce comparatif." },
          ],
        }],
      }),
    });
  } catch (e) { return json({ error: "anthropic_fetch", detail: String(e) }, 502); }

  if (!aiResp.ok) return json({ error: "anthropic_error", status: aiResp.status, detail: await aiResp.text() }, 502);
  const aiJson = await aiResp.json();

  const inTok = aiJson.usage?.input_tokens ?? 0;
  const outTok = aiJson.usage?.output_tokens ?? 0;
  const price = PRICES[MODEL] || { in: 0, out: 0 };
  const costUsd = (inTok / 1e6) * price.in + (outTok / 1e6) * price.out;
  try {
    await db.from("ai_usage_log").insert({
      feature: "tarifs_import", model: MODEL, input_tokens: inTok, output_tokens: outTok,
      cost_usd: Number(costUsd.toFixed(6)), user_email: adminEmail,
    });
  } catch (_) { /* log non bloquant */ }

  if (aiJson.stop_reason === "refusal") return json({ error: "refus_modele" }, 422);
  const rawText = (aiJson.content || []).filter((c: any) => c.type === "text").map((c: any) => c.text).join("").trim();
  let lu: Record<string, any>;
  try { lu = JSON.parse(rawText); } catch (_) { return json({ error: "json_illisible" }, 502); }

  // Date de mise en service = date de la recherche sur le comparateur.
  const dateDebut = (() => {
    const m = String(lu.date_recherche || "").match(/(\d{2})\/(\d{2})\/(\d{4})/);
    return m ? `${m[3]}-${m[2]}-${m[1]}` : new Date().toISOString().slice(0, 10);
  })();
  const puissance = lu.puissance_kva ?? null;

  const { data: existants } = await db.from("tarifs_electricite")
    .select("id,nom,fournisseur,abo_annuel,prix_hp,prix_hc,type_tarif,actif")
    .eq("actif", true);

  const importes: any[] = [], remplaces: any[] = [], rejetes: any[] = [];

  for (const o of (lu.offres || [])) {
    const etiquette = `${o.fournisseur || '?'} — ${o.offre || '?'}`;
    const manques: string[] = [];

    // ── Garde-fous : on n'importe QUE ce qui est exploitable tel quel ────────
    if (!o.fournisseur) manques.push("fournisseur non identifié (logo illisible)");
    else if ((o.confiance_fournisseur ?? 0) < 0.7) manques.push(`fournisseur incertain (${Math.round((o.confiance_fournisseur ?? 0) * 100)} %)`);
    if (!o.offre) manques.push("nom de l'offre absent");
    if (o.type_tarif === "autre") manques.push("structure tarifaire non gérée par l'application (offre week-end, tempo ou à paliers)");
    if (o.abo_annuel_ttc == null) manques.push("abonnement annuel absent");
    if (o.type_tarif === "base" && o.prix_base_ttc == null) manques.push("prix du kWh absent");
    if (o.type_tarif === "hp_hc" && (o.prix_hp_ttc == null || o.prix_hc_ttc == null)) manques.push("prix HP ou HC absent");
    if (!o.type_tarif) manques.push("type de tarif indéterminé");

    // Plausibilité : un prix hors du domaine du marché français trahit une
    // mauvaise lecture (centimes pris pour des euros, total pris pour un prix).
    const prixKwh = [o.prix_base_ttc, o.prix_hp_ttc, o.prix_hc_ttc].filter((p) => p != null) as number[];
    if (prixKwh.some((p) => p < 0.05 || p > 0.6)) manques.push("prix du kWh hors fourchette plausible (0,05–0,60 €)");
    if (o.abo_annuel_ttc != null && (o.abo_annuel_ttc < 50 || o.abo_annuel_ttc > 1500)) manques.push("abonnement annuel hors fourchette plausible");

    if (manques.length) { rejetes.push({ offre: etiquette, motifs: manques }); continue; }

    const ligne = {
      nom: o.offre.trim(),
      fournisseur: o.fournisseur.trim(),
      abo_annuel: o.abo_annuel_ttc,
      prix_hp: o.type_tarif === "base" ? o.prix_base_ttc : o.prix_hp_ttc,
      prix_hc: o.type_tarif === "hp_hc" ? o.prix_hc_ttc : null,
      type_tarif: o.type_tarif === "hp_hc" ? "hchp" : "fixe",
      tarif_dynamique: false,
      puissance_kva: puissance,
      statut: "verifie",
      source: "ocr",
      actif: true,
      date_debut: dateDebut,
      import_source: `pdf:${fichier_nom}`,
      verifie_le: new Date().toISOString(),
      verifie_par: `import:${adminEmail}`,
      last_modified: new Date().toISOString(),
    };

    // ── Même fournisseur + même offre ⇒ remplacement ────────────────────────
    const ancien = (existants || []).find((t: any) =>
      norm(t.fournisseur) === norm(o.fournisseur) && norm(t.nom) === norm(o.offre));

    if (ancien) {
      // Grille inchangée : ne rien faire plutôt que d'empiler des doublons.
      const memePrix = Number(ancien.abo_annuel) === Number(ligne.abo_annuel)
        && Number(ancien.prix_hp) === Number(ligne.prix_hp)
        && Number(ancien.prix_hc ?? 0) === Number(ligne.prix_hc ?? 0);
      if (memePrix) { importes.push({ offre: etiquette, etat: "inchangé" }); continue; }

      const { data: nouveau, error: insErr } = await db.from("tarifs_electricite")
        .insert({ ...ligne, remplace_tarif_id: ancien.id }).select("id").single();
      if (insErr || !nouveau) { rejetes.push({ offre: etiquette, motifs: ["écriture en base refusée : " + insErr?.message] }); continue; }

      await db.from("tarifs_electricite")
        .update({ actif: false, date_fin: dateDebut }).eq("id", ancien.id);
      // Les sites abonnés à cette offre suivent la nouvelle grille : c'est la
      // même offre commerciale, seul son prix a changé.
      const { count } = await db.from("sites")
        .update({ tarif_id: nouveau.id }, { count: "exact" }).eq("tarif_id", ancien.id);
      remplaces.push({
        offre: etiquette,
        avant: { abo: ancien.abo_annuel, hp: ancien.prix_hp, hc: ancien.prix_hc },
        apres: { abo: ligne.abo_annuel, hp: ligne.prix_hp, hc: ligne.prix_hc },
        sites_bascules: count ?? 0,
      });
    } else {
      const { error: insErr } = await db.from("tarifs_electricite").insert(ligne);
      if (insErr) { rejetes.push({ offre: etiquette, motifs: ["écriture en base refusée : " + insErr.message] }); continue; }
      importes.push({ offre: etiquette, etat: "nouveau" });
    }
  }

  return json({
    fichier: fichier_nom,
    date_grille: dateDebut,
    puissance_kva: puissance,
    lues: (lu.offres || []).length,
    bilan: { importes, remplaces, rejetes },
    cout: { usd: Number(costUsd.toFixed(4)) },
  });
});
